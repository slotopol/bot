package main

import (
	"sync"

	lua "github.com/yuin/gopher-lua"
)

var (
	intmap = map[string]int64{}
	intmux sync.Mutex
	nummap = map[string]float64{}
	nummux sync.Mutex
)

// RegAtom is the module loader function.
func RegAtom(ls *lua.LState) {
	var mod = ls.RegisterModule("atom", atomfuncs).(*lua.LTable)
	_ = mod
}

var atomfuncs = map[string]lua.LGFunction{
	"intinc": atomintinc,
	"intdec": atomintdec,
	"intadd": atomintadd,
	"intand": atomintand,
	"intor":  atomintor,
	"intxor": atomintxor,
	"intget": atomintget,
	"intset": atomintset,
	"numinc": atomnuminc,
	"numdec": atomnumdec,
	"numadd": atomnumadd,
	"numget": atomnumget,
	"numset": atomnumset,
}

func atomintinc(ls *lua.LState) int {
	var name = ls.CheckString(1)

	intmux.Lock()
	intmap[name]++
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintdec(ls *lua.LState) int {
	var name = ls.CheckString(1)

	intmux.Lock()
	intmap[name]--
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintadd(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckInt64(2)

	intmux.Lock()
	intmap[name] += arg
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintand(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckInt64(2)

	intmux.Lock()
	intmap[name] &= arg
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintor(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckInt64(2)

	intmux.Lock()
	intmap[name] |= arg
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintxor(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckInt64(2)

	intmux.Lock()
	intmap[name] ^= arg
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintget(ls *lua.LState) int {
	var name = ls.CheckString(1)

	intmux.Lock()
	var v = intmap[name]
	intmux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomintset(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckInt64(2)

	intmux.Lock()
	intmap[name] = arg
	intmux.Unlock()

	return 0
}

func atomnuminc(ls *lua.LState) int {
	var name = ls.CheckString(1)

	nummux.Lock()
	nummap[name]++
	var v = nummap[name]
	nummux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomnumdec(ls *lua.LState) int {
	var name = ls.CheckString(1)

	nummux.Lock()
	nummap[name]--
	var v = nummap[name]
	nummux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomnumadd(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckNumber(2)

	nummux.Lock()
	nummap[name] += float64(arg)
	var v = nummap[name]
	nummux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomnumget(ls *lua.LState) int {
	var name = ls.CheckString(1)

	nummux.Lock()
	var v = nummap[name]
	nummux.Unlock()

	ls.Push(lua.LNumber(v))
	return 1
}

func atomnumset(ls *lua.LState) int {
	var name = ls.CheckString(1)
	var arg = ls.CheckInt64(2)

	nummux.Lock()
	nummap[name] = float64(arg)
	nummux.Unlock()

	return 0
}
