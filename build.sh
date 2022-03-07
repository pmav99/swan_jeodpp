#!/usr/bin/env bash
#

set -xeuo pipefail

export DOCKER_BUILDKIT=1


docker build -t swan_jeodpp:latest ./
