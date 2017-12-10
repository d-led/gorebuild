#!/usr/bin/env bash

set -e

export MIX_ENV=${MIX_ENV:-dev}

echo "Environment: $MIX_ENV"

mix compile
mix run --no-halt
