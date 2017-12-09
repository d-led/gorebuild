# GoRebuild

Service for triggering GoCD pipelines on demand

contributions & other problem fixes welcome!

## Problem

- GoCD garbage collection can remove artifacts to not overfill the artifacts repository.
- When pipelines with high frequency or runs depend on those with lower frequency, the upstream
dependency might get garbage collected, and the downstream one fails when trying to fetch an artifact:

![](docs/img/vsm.png)

![](docs/img/failure.png)

## Solution

Polling for the presence of pre-defined artifacts, and triggering pipelines when the artifact that should not have
been deleted has been deleted nonetheless.

The pipeline is not triggered for previously failed or currently running pipelines

![](docs/img/triggering.png)

## Configuration

- see [apps/rebuildremoved/config/config.exs](apps/rebuildremoved/config/config.exs)

## TODO

- authentication

## Commentary

While the solution is not a systematically optimal one (if keeping N last artifacts is a viable feature, it should be part of GoCD), currently, it is a most pragmatic one.

### Links to Problem Descriptions

- gocd/gocd/#4022
- gocd/gocd/#410
- gocd/gocd/#1207
- https://groups.google.com/forum/m/#!topic/go-cd/QArd6yLwhl4
