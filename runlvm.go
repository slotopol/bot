package main

import (
	"bufio"
	"encoding/hex"
	"errors"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path"
	"syscall"
	"time"

	"github.com/slotopol/bot/util"

	lua "github.com/yuin/gopher-lua"
	"github.com/yuin/gopher-lua/ast"
	"github.com/yuin/gopher-lua/parse"

	"github.com/cjoudrey/gluahttp"
	json "github.com/layeh/gopher-json"
	crypto "github.com/tengattack/gluacrypto/crypto"
)

var (
	// compiled binary version, sets by compiler with command
	//    go build -ldflags="-X 'main.BuildVers=%buildvers%'"
	BuildVers string

	// compiled binary build date, sets by compiler with command
	//    go build -ldflags="-X 'main.BuildTime=%buildtime%'"
	BuildTime string
)

var quit = make(chan lua.LValue)

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

func luasec2dur(ls *lua.LState) int {
	var sec = float64(ls.CheckNumber(1))
	var gran = float64(ls.OptNumber(2, 1))

	var dur = time.Duration(sec * float64(time.Second))
	var dg = time.Duration(gran * float64(time.Second))
	dur = dur.Round(dg)
	ls.Push(lua.LString(dur.String()))
	return 1
}

func luaafter(ls *lua.LState) int {
	var milli = ls.CheckInt64(1)
	var ch = ls.CheckChannel(2)

	go func() {
		<-time.After(time.Duration(milli) * time.Millisecond)
		<-ch
	}()
	return 0
}

func luatick(ls *lua.LState) int {
	var milli = ls.CheckInt64(1)
	var ch = ls.CheckChannel(2)

	go func() {
		var c = time.Tick(time.Duration(milli) * time.Millisecond)
		for range c {
			if _, ok := <-ch; !ok {
				break
			}
		}
	}()
	return 0
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

var protocache = map[string]*lua.FunctionProto{}

func luathread(ls *lua.LState) int {
	var err error
	var exit chan lua.LValue
	var body []*lua.FunctionProto
	var args = map[string]lua.LValue{}
	var n = ls.GetTop()
	for i := 1; i <= n; i++ {
		var arg = ls.Get(i)
		switch v := arg.(type) {
		case *lua.LTable:
			v.ForEach(func(key lua.LValue, val lua.LValue) {
				if _, ok := key.(lua.LString); ok {
					args[key.String()] = val
				}
			})
		case lua.LChannel:
			exit = v
		case lua.LString:
			var fpath = v.String()
			var proto *lua.FunctionProto
			var ok bool
			if proto, ok = protocache[fpath]; !ok { // check cache
				if func() {
					var file, err = os.Open(fpath)
					defer file.Close()
					if err != nil {
						return
					}
					var reader = bufio.NewReader(file)
					var chunk []ast.Stmt
					if chunk, err = parse.Parse(reader, fpath); err != nil {
						return
					}
					if proto, err = lua.Compile(chunk, fpath); err != nil {
						return
					}
					protocache[fpath] = proto // put to cache
				}(); err != nil {
					ls.RaiseError(err.Error())
					return 0
				}
			}
			body = append(body, proto)
		default:
			ls.RaiseError("expected functions or exit channel, got %s", v.Type())
			return 0
		}
	}

	var tls = lua.NewState() // thread Lua state
	go func() {
		defer tls.Close()
		InitLuaVM(tls)

		for key, val := range args {
			tls.SetGlobal(key, val)
		}

		var count int
		for _, proto := range body {
			var lfunc = tls.NewFunctionFromProto(proto)
			tls.Push(lfunc)
			if err = tls.PCall(0, lua.MultRet, nil); err != nil {
				break
			}
			count++
		}

		if exit != nil {
			if err != nil {
				exit <- lua.LString(err.Error())
			} else {
				exit <- lua.LNil
			}
		}
	}()
	return 0
}

func WaitQuit() {
	var sigint = make(chan os.Signal, 1)
	var sigterm = make(chan os.Signal, 1)
	// We'll accept graceful shutdowns when quit via SIGINT (Ctrl+C) or SIGTERM (Ctrl+/)
	// SIGKILL, SIGQUIT will not be caught.
	signal.Notify(sigint, syscall.SIGINT)
	signal.Notify(sigterm, syscall.SIGTERM)
	// Block until we receive our signal.
	var ok = true
	select {
	case _, ok = <-quit:
	case <-sigint:
	case <-sigterm:
	}
	if ok {
		close(quit)
	}
	signal.Stop(sigint)
	signal.Stop(sigterm)
}

// InitLuaVM performs initial registrations.
func InitLuaVM(ls *lua.LState) {
	// set modules
	RegPath(ls)
	RegAtom(ls)
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

	// global variables
	ls.SetGlobal("quit", lua.LChannel(quit))
	ls.SetGlobal("buildvers", lua.LString(BuildVers))
	ls.SetGlobal("buildtime", lua.LString(BuildTime))
	ls.SetGlobal("bindir", lua.LString(bindir))
	ls.SetGlobal("tmpdir", lua.LString(util.ToSlash(os.TempDir())))
	// global functions
	ls.SetGlobal("log", ls.NewFunction(lualog))
	ls.SetGlobal("checkfile", ls.NewFunction(luacheckfile))
	ls.SetGlobal("bin2hex", ls.NewFunction(luabin2hex))
	ls.SetGlobal("hex2bin", ls.NewFunction(luahex2bin))
	ls.SetGlobal("milli2time", ls.NewFunction(luamilli2time))
	ls.SetGlobal("time2milli", ls.NewFunction(luatime2milli))
	ls.SetGlobal("sec2dur", ls.NewFunction(luasec2dur))
	ls.SetGlobal("after", ls.NewFunction(luaafter))
	ls.SetGlobal("tick", ls.NewFunction(luatick))
	ls.SetGlobal("sleep", ls.NewFunction(luasleep))
	ls.SetGlobal("thread", ls.NewFunction(luathread))
}

// RunLuaVM runs specified Lua-script with Lua Bot API.
func RunLuaVM(fpath string) (err error) {
	var ls = lua.NewState()
	defer ls.Close()
	InitLuaVM(ls)

	var scrdir = path.Dir(util.ToSlash(fpath))
	ls.SetGlobal("scrdir", lua.LString(scrdir))

	if err = ls.DoFile(fpath); err != nil {
		return
	}
	return
}
