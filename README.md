
# Bot

[![GitHub release](https://img.shields.io/github/v/release/slotopol/bot.svg)](https://github.com/slotopol/bot/releases/latest)
[![Hits-of-Code](https://hitsofcode.com/github/slotopol/bot?branch=main)](https://hitsofcode.com/github/slotopol/bot/view?branch=main)

Client emulator for slots server, scripted by Lua.

Serves to run scenarios that emulate the natural work of users, allows you to test the service API, determine the load on the database during normal workflow, and peak loads.

# How it working

Bot have host engine with provided Lua-API and scripts running over this engine. Engine provides API for [http-calls](github.com/cjoudrey/gluahttp), [JSON parser](github.com/layeh/gopher-json), [crypto](github.com/tengattack/gluacrypto) algorithms, path-functions, and some top-level API functions, see `runlvm.go`. Including two main functions to build scripts workflow: `thread` function, and `sleep` function.

Because the Lua virtual machine can only run in one system thread, `thread` functions creates new Lua virtual machine with all API registrations, that can be run at another goroutine. Function receives list of tables and strings in any order. Any given table spreads and all it's items sets to global scope to new created VM. So all items of table must have string keys, to get access in this VM. Values can be strings, numbers, booleans, tables without metatable. Any given string to `thread` function assumed as path to script that will be executed in new VM. Also to `thread` function can be given channel that assumed as exit channel. When job will be complete nil value will be sent to exit channel on success, or error message if error occurs.

# How to build from sources

1. Install [Golang](https://go.dev/dl/) of last version.
2. Clone project and download dependencies.
3. Build project with script at `task` directory.

For Windows command prompt:

```cmd
git clone https://github.com/slotopol/bot.git
cd bot
go mod download && go mod verify
task\build-win-x64.cmd
```

or for Linux shell or git bash:

```sh
git clone https://github.com/slotopol/bot.git
cd bot
go mod download && go mod verify
sudo chmod +x ./task/*.sh
./task/build-linux-x64.sh
```

Start [`slotopol server`](https://github.com/slotopol/server), and then bot can be run together with some script:

```cmd
bot_win_x64 script/servinfo.lua
```

You can get the list of all provided games by command:

```cmd
bot_win_x64 script/gamelist.lua
```

# How to test server

To start single player emulation run followed script:

```cmd
bot_win_x64 script/single.lua
```

To start group of players emulation run followed script:

```cmd
bot_win_x64 script/group.lua
```

---
(c) schwarzlichtbezirk, 2024.
