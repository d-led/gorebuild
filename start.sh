#!/usr/bin/env bash

set -e

mix compile
mix run --no-halt
