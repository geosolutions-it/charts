# Notes to contribute to the charts

## Version bump

Each merge request should include a version bump.

Example:

The MR brings a small fix. `main` is at `0.2.0`.  
Then it should include a change that bumps the version number in `Chart.yaml` to
`0.2.1`.

## Changelog

Each merge request should include a changelog.  
For examples, have a look at the existing `CHANGELOG.md` files.

The suggested format is the following.

```
## x.y.z

**Changes**

List notable changes here...

**Migration notes**

List migration steps here...
Omit if unnecessary.

**Commits**

$(git shortlog main..)
```
