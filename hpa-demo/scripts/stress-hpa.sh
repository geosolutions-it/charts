#!/usr/bin/env bash
set -euo pipefail

GS_NAMESPACE="${GS_NAMESPACE:-geoserver}"
MON_NAMESPACE="${MON_NAMESPACE:-monitoring}"
GS_RELEASE="${GS_RELEASE:-geoserver}"
HPA_NAME="${HPA_NAME:-geoserver}"
SERVICEMONITOR_NAME="${SERVICEMONITOR_NAME:-geoserver}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
ADMIN_SECRET="${ADMIN_SECRET:-geoserver}"
TARGET_URL="${TARGET_URL:-http://geoserver.${GS_NAMESPACE}.svc.cluster.local/geoserver/wms?service=WMS&request=GetCapabilities}"
LOAD_IMAGE="${LOAD_IMAGE:-curlimages/curl:8.7.1}"
WORKERS="${WORKERS:-10}"
DURATION_SECONDS="${DURATION_SECONDS:-240}"

LOAD_POD="geoserver-hpa-stress-$(date +%s)"

log() {
  printf '[INFO] %s\n' "$*"
}

pass() {
  printf '[PASS] %s\n' "$*"
}

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

cleanup() {
  kubectl delete pod -n "${GS_NAMESPACE}" "${LOAD_POD}" --ignore-not-found >/dev/null 2>&1 || true
}

trap cleanup EXIT

require_cmd kubectl
require_cmd helm
require_cmd base64

log "Checking GeoServer monitoring prerequisites"
kubectl get ns "${GS_NAMESPACE}" >/dev/null
kubectl get ns "${MON_NAMESPACE}" >/dev/null
helm status "${GS_RELEASE}" -n "${GS_NAMESPACE}" >/dev/null
kubectl get servicemonitor -n "${MON_NAMESPACE}" "${SERVICEMONITOR_NAME}" >/dev/null
kubectl get hpa -n "${GS_NAMESPACE}" "${HPA_NAME}" >/dev/null
pass "release, ServiceMonitor, and HPA exist"

if [ -z "${ADMIN_PASSWORD}" ]; then
  log "Reading GeoServer admin password from secret ${GS_NAMESPACE}/${ADMIN_SECRET}"
  ADMIN_PASSWORD="$(kubectl get secret -n "${GS_NAMESPACE}" "${ADMIN_SECRET}" -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 --decode)"
  [ -n "${ADMIN_PASSWORD}" ] || fail "unable to read ADMIN_PASSWORD from secret ${GS_NAMESPACE}/${ADMIN_SECRET}"
fi

log "Observe autoscaling live in another terminal"
printf '  kubectl get hpa -n %s %s -w\n' "${GS_NAMESPACE}" "${HPA_NAME}"
printf '  kubectl get pods -n %s -w\n' "${GS_NAMESPACE}"
printf '  kubectl top pods -n %s\n' "${GS_NAMESPACE}"
printf '  kubectl describe hpa -n %s %s\n' "${GS_NAMESPACE}" "${HPA_NAME}"

log "Creating in-cluster load pod ${LOAD_POD}"
kubectl run "${LOAD_POD}" \
  -n "${GS_NAMESPACE}" \
  --image="${LOAD_IMAGE}" \
  --restart=Never \
  --labels="app=geoserver-hpa-stress,app.kubernetes.io/instance=${GS_RELEASE}" \
  --env="TARGET_URL=${TARGET_URL}" \
  --env="ADMIN_USER=${ADMIN_USER}" \
  --env="ADMIN_PASSWORD=${ADMIN_PASSWORD}" \
  --env="WORKERS=${WORKERS}" \
  --env="DURATION_SECONDS=${DURATION_SECONDS}" \
  --command -- sh -lc '
worker() {
  local end
  end=$(( $(date +%s) + DURATION_SECONDS ))
  while [ "$(date +%s)" -lt "${end}" ]; do
    curl -sS -o /dev/null -u "${ADMIN_USER}:${ADMIN_PASSWORD}" "${TARGET_URL}" || true
  done
}

i=1
while [ "${i}" -le "${WORKERS}" ]; do
  worker &
  i=$((i + 1))
done
wait
' >/dev/null

kubectl wait --for=condition=Ready "pod/${LOAD_POD}" -n "${GS_NAMESPACE}" --timeout=120s >/dev/null
pass "load pod is running"

log "Generating load for ${DURATION_SECONDS}s with ${WORKERS} workers"
kubectl wait --for=condition=Ready "pod/${LOAD_POD}" -n "${GS_NAMESPACE}" --timeout=$((DURATION_SECONDS + 120))s >/dev/null 2>&1 || true
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded "pod/${LOAD_POD}" -n "${GS_NAMESPACE}" --timeout=$((DURATION_SECONDS + 180))s >/dev/null 2>&1 || true
pass "load generation completed"

pass "stress test completed"
