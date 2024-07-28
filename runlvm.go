package main

import (
	"encoding/hex"
	"errors"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path"
	"time"

	"github.com/cjoudrey/gluahttp"
	json "github.com/layeh/gopher-json"
	"github.com/slotopol/bot/util"
	crypto "github.com/tengattack/gluacrypto/crypto"
	lua "github.com/yuin/gopher-lua"
)

var (
	// compiled binary version, sets by compiler with command
	//    go build -ldflags="-X 'main.BuildVers=%buildvers%'"
	BuildVers string

	// compiled binary build date, sets by compiler with command
	//    go build -ldflags="-X 'main.BuildTime=%buildtime%'"
	BuildTime string
)

func lualog(ls *lua.LState) int {
	var s = ls.CheckString(1)

	log.Println(s)
	return 0
}

func luacheckfile(ls *lua.LState) int {
	var fpath = ls.CheckString(1)

	var err error
	var fi os.FileInfo
	if fi, err = os.Stat(fpath); err == nil {
		ls.Push(lua.LBool(true))
		ls.Push(lua.LBool(!fi.IsDir()))
		return 2
	}
	if errors.Is(err, fs.ErrNotExist) {
		ls.Push(lua.LBool(false))
		return 1
	}
	ls.Push(lua.LBool(false))
	ls.Push(lua.LString(err.Error()))
	return 2
}

func luabin2hex(ls *lua.LState) int {
	var arg = ls.CheckString(1)
	ls.Push(lua.LString(hex.EncodeToString(util.S2B(arg))))
	return 1
}

func luahex2bin(ls *lua.LState) int {
	var err error
	defer func() {
		if err != nil {
			ls.RaiseError(err.Error())
		}
	}()
	var arg = ls.CheckString(1)
	var b []byte
	if b, err = hex.DecodeString(arg); err != nil {
		return 0
	}
	ls.Push(lua.LString(util.B2S(b)))
	return 1
}

const ISO8601 = "2006-01-02T15:04:05.999Z07:00"

func luamilli2time(ls *lua.LState) int {
	var milli = ls.CheckInt64(1)
	var layout = ls.OptString(2, ISO8601)

	var t = time.Unix(milli/1000, (milli%1000)*1000000)
	ls.Push(lua.LString(t.Format(layout)))
	return 1
}

func luatime2milli(ls *lua.LState) int {
	var err error
	defer func() {
		if err != nil {
			ls.RaiseError(err.Error())
		}
	}()
	var arg = ls.CheckString(1)
	var layout = ls.OptString(2, ISO8601)

	var t time.Time
	if t, err = time.Parse(layout, string(arg)); err != nil {
		return 0
	}
	ls.Push(lua.LNumber(t.UnixMilli()))
	return 1
}

func luasleep(ls *lua.LState) int {
	var err error
	defer func() {
		if err != nil {
			ls.RaiseError(err.Error())
		}
	}()
	var arg = ls.CheckAny(1)

	var d time.Duration
	switch v := arg.(type) {
	case lua.LNumber:
		d = time.Duration(v) * time.Millisecond
	case lua.LString:
		if d, err = time.ParseDuration(string(v)); err != nil {
			return 0
		}
	default:
		ls.RaiseError("expected number as duration in milliseconds or string with formatted duration")
	}
	time.Sleep(d)

	return 0
}

// RunLuaVM runs specified Lua-script with Lua Bot API.
func RunLuaVM(fpath string) (err error) {
	var ls = lua.NewState()
	defer ls.Close()

	ls.PreloadModule("path", LoadPath)
	ls.PreloadModule("http", gluahttp.NewHttpModule(&http.Client{}).Loader)
	ls.PreloadModule("json", json.Loader)
	ls.PreloadModule("crypto", crypto.Loader)

	var bindir = func() string {
		if str, err := os.Executable(); err == nil {
			return path.Dir(util.ToSlash(str))
		} else {
			return path.Dir(util.ToSlash(os.Args[0]))
		}
	}()
	var scrdir = path.Dir(util.ToSlash(fpath))

	// global variables
	ls.SetGlobal("buildvers", lua.LString(BuildVers))
	ls.SetGlobal("buildtime", lua.LString(BuildTime))
	ls.SetGlobal("bindir", lua.LString(bindir))
	ls.SetGlobal("scrdir", lua.LString(scrdir))
	ls.SetGlobal("tmpdir", lua.LString(util.ToSlash(os.TempDir())))
	// global functions
	ls.SetGlobal("log", ls.NewFunction(lualog))
	ls.SetGlobal("checkfile", ls.NewFunction(luacheckfile))
	ls.SetGlobal("bin2hex", ls.NewFunction(luabin2hex))
	ls.SetGlobal("hex2bin", ls.NewFunction(luahex2bin))
	ls.SetGlobal("milli2time", ls.NewFunction(luamilli2time))
	ls.SetGlobal("time2milli", ls.NewFunction(luatime2milli))
	ls.SetGlobal("sleep", ls.NewFunction(luasleep))

	if err = ls.DoFile(fpath); err != nil {
		return
	}
	return
}
