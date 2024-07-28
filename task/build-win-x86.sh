#!/bin/bash -u
# This script compiles project for Windows x86.

wd=$(realpath -s "$(dirname "$0")/..")

cp -ruv "$wd/script/"* "$GOPATH/bin/config/bot"

buildvers=$(git describe --tags)
buildtime=$(go run "$wd/task/timenow.go") # $(date -u +'%FT%TZ')

go env -w GOOS=windows GOARCH=386 CGO_ENABLED=1
go build -o "$GOPATH/bin/bot_win_x86.exe" -v -ldflags="-X 'main.BuildVers=$buildvers' -X 'main.BuildTime=$buildtime'" $wd
