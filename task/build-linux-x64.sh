#!/bin/bash -u
# This script compiles project for Linux amd64.

wd=$(realpath -s "$(dirname "$0")/..")

cp -ruv "$wd/script/"* "$GOPATH/bin/script"

buildvers=$(git describe --tags)
buildtime=$(go run "$wd/task/timenow.go") # $(date -u +'%FT%TZ')

go env -w GOOS=linux GOARCH=amd64 CGO_ENABLED=1
go build -o "$GOPATH/bin/bot_linux_x64" -v -ldflags="-X 'main.BuildVers=$buildvers' -X 'main.BuildTime=$buildtime'" $wd
