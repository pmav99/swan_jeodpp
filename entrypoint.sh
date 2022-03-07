#!/usr/bin/env bash
#

set -xeuo pipefail

export DISPLAY=:99.0
export PYVISTA_OFF_SCREEN=true
export PYVISTA_USE_IPYVTK=true
export XDG_RUNTIME_DIR="${HOME}"

# Test that xvfb is installed
which Xvfb

# Create X framebuffer
Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &

sleep 3


exec tini -g -- "$@"
