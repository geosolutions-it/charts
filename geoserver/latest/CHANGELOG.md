# Changelog

## 0.2.5

**Changes**

Logs-pruning CronJob:
- Prevent multiple jobs to run concurrently.
- Set the starting deadline to 600 s.

**Commits**

Francesco Camuffo (1):
      gs: update logs pruning CronJob spec

## 0.2.4

**Changes**

Add a CronJob to prune old logs daily.

**Commits**

Francesco Camuffo (1):
      gs: add CronJob to prune old logs

## 0.2.3

**Changes**

Prefix Tomcat log files with Pod hostname.

**Commits**

Francesco Camuffo (1):
      gs: prefix Tomcat log files with Pod hostname

## 0.2.1

**Changes**

Support the optional creation of a GWC cache directory dedicated volume.

**Commits**

Francesco Camuffo (1):
      gs: add optional gwccache PVC

