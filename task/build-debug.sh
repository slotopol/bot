#!/bin/bash -u
# This script compiles project for default platform with debug information.

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}
need go
need git

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

go env -w CGO_ENABLED=1
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  appext=".exe"
else
  appext=""
fi
go build -o "${GOPATH}/bin/bot_debug${appext}" -v \
  -buildvcs=false \
  -ldflags="-X 'main.BuildVers=$BUILDVERS' -X 'main.BuildTime=$BUILDTIME'" \
  $wd
