#!/usr/bin/env bash

set -e

mix deps.get
mix clean compile
mix run --no-halt
