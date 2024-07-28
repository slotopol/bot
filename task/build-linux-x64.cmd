@echo off
rem This script compiles project for Linux amd64.
set wd=%~dp0..

xcopy %wd%\script %GOPATH%\bin\config\bot /f /d /i /e /k /y

for /F "tokens=*" %%g in ('git describe --tags') do (set buildvers=%%g)
for /F "tokens=*" %%g in ('go run %~dp0/timenow.go') do (set buildtime=%%g)

go env -w GOOS=linux GOARCH=amd64 CGO_ENABLED=1
go build -o %GOPATH%/bin/bot_linux_x64 -v -ldflags="-X 'main.BuildVers=%buildvers%' -X 'main.BuildTime=%buildtime%'" %wd%
