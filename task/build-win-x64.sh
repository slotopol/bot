#!/bin/bash -u
# This script compiles project for Windows amd64.

wd=$(realpath -s "$(dirname "$0")/..")
cp -ruv "$wd/script/"* "$GOPATH/bin/script"

buildvers=$(git describe --tags)
# See https://tc39.es/ecma262/#sec-date-time-string-format
# time format acceptable for Date constructors.
buildtime=$(date +'%FT%T.%3NZ')

go env -w GOOS=windows GOARCH=amd64 CGO_ENABLED=1
go build -o "$GOPATH/bin/bot_win_x64.exe" -v -ldflags="-X 'main.BuildVers=$buildvers' -X 'main.BuildTime=$buildtime'" $wd
