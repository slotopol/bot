#!/bin/bash -u
# This script compiles project for Windows amd64.

wd=$(realpath -s "$(dirname "$0")/..")

cp -ruv "$wd/script/"* "$GOPATH/bin/config/bot"

buildvers=$(git describe --tags)
buildtime=$(go run "$wd/task/timenow.go") # $(date -u +'%FT%TZ')

go env -w GOOS=windows GOARCH=amd64 CGO_ENABLED=1
go build -o "$GOPATH/bin/bot_win_x64.exe" -v -ldflags="-X 'main.BuildVers=$buildvers' -X 'main.BuildTime=$buildtime'" $wd
