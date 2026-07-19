#!/bin/sh

set -eu

cd "$(dirname "$0")/.."

xcrun swift-format lint --strict \
  App/*.swift \
  Domain/*.swift \
  Persistence/*.swift \
  DesignSystem/*.swift \
  Features/*.swift \
  LedgerlyV1Tests/*.swift \
  LedgerlyV1UITests/*.swift
