@echo off

for /F "tokens=*" %%g in ('git describe --tags') do (set buildvers=%%g)
for /F "tokens=*" %%g in ('go run %~dp0/timenow.go') do (set buildtime=%%g)

set wd=%~dp0..
go build -o %GOPATH%/bin/bot_win_x64.exe -v -ldflags="-X 'github.com/slotopol/bot.BuildVers=%buildvers%' -X 'github.com/slotopol/bot.BuildTime=%buildtime%'" %wd%
