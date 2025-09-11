package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/slotopol/bot/util"
)

const helpmsg = `version: %s, builton: %s
usage: bot [script.lua ...]
  -h, --help, /?    show this help message
  script.lua        lua script file to run
`

func main() {
	go WaitQuit()
	for _, fpath := range os.Args[1:] {
		if arg := util.ToLower(fpath); arg == "-h" || arg == "--help" || arg == "/?" {
			fmt.Printf(helpmsg, BuildVers, BuildTime)
		} else if util.ToLower(filepath.Ext(fpath)) == ".lua" {
			if err := RunLuaVM(util.Envfmt(fpath, nil)); err != nil {
				println(err.Error())
				return
			}
		}
	}
}
