#!/usr/bin/env bash

set -e

export MIX_ENV=dev

mix compile
mix run --no-halt
