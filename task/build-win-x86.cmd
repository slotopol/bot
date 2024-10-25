@echo off
rem This script compiles project for Windows x86.

set wd=%~dp0..
xcopy %wd%\script %GOPATH%\bin\script /f /d /i /e /k /y

for /F "tokens=*" %%g in ('git describe --tags') do (set buildvers=%%g)
for /f "tokens=2 delims==" %%g in ('wmic os get localdatetime /value') do set dt=%%g
set buildtime=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%T%dt:~8,2%:%dt:~10,2%:%dt:~12,2%.%dt:~15,3%Z

go env -w GOOS=windows GOARCH=386 CGO_ENABLED=1
go build -o %GOPATH%/bin/bot_win_x86.exe -v -ldflags="-X 'main.BuildVers=%buildvers%' -X 'main.BuildTime=%buildtime%'" %wd%
