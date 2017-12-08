#!/usr/bin/env bash

set -e

mix clean compile
mix run --no-halt
