#!/bin/bash -u
# This script compiles project for Linux amd64.

wd=$(realpath -s "$(dirname "$0")/..")
mkdir -p "$GOPATH/bin/script"
cp -ruv "$wd/script/"* "$GOPATH/bin/script"

buildvers=$(git describe --tags)
# See https://tc39.es/ecma262/#sec-date-time-string-format
# time format acceptable for Date constructors.
buildtime=$(date +'%FT%T.%3NZ')

go env -w GOOS=linux GOARCH=amd64 CGO_ENABLED=1
go build -o "$GOPATH/bin/bot_linux_x64" -v -ldflags="-X 'main.BuildVers=$buildvers' -X 'main.BuildTime=$buildtime'" $wd
