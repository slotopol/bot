#!/bin/bash -u
# This script compiles project for Linux amd64.

wd=$(realpath -s "$(dirname "$0")/..")
mkdir -p "$GOPATH/bin/script"
cp -ruv "$wd/script/"* "$GOPATH/bin/script"

if [[ -z "${BUILDVERS:-}" ]]; then
  BUILDVERS=$(git describe --tags --always)
fi
# See https://tc39.es/ecma262/#sec-date-time-string-format
# time format acceptable for Date constructors.
if [[ -z "${BUILDTIME:-}" ]]; then
  BUILDTIME=$(date +'%FT%T.%3NZ')
fi

go env -w GOOS=linux GOARCH=amd64 CGO_ENABLED=1
go build -o "$GOPATH/bin/bot_linux_x64" -v \
  -buildvcs=false \
  -ldflags="-w -s -X 'main.BuildVers=$BUILDVERS' -X 'main.BuildTime=$BUILDTIME'" \
  $wd
