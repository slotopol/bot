package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/slotopol/bot/util"
)

func main() {
	go WaitQuit()
	for _, fpath := range os.Args[1:] {
		if arg := util.ToLower(fpath); arg == "-h" || arg == "--help" || arg == "/?" {
			fmt.Printf("version: %s, builton: %s\n", BuildVers, BuildTime)
			fmt.Println("usage: bot [script.lua ...]")
			fmt.Println("  -h, --help, /?    show this help message")
			fmt.Println("  script.lua        lua script file to run")
		} else if util.ToLower(filepath.Ext(fpath)) == ".lua" {
			if err := RunLuaVM(util.Envfmt(fpath, nil)); err != nil {
				println(err.Error())
				return
			}
		}
	}
}
