package main

import (
	"log"
	"os"
	"path/filepath"

	"github.com/slotopol/bot/util"
)

func main() {
	for _, fpath := range os.Args[1:] {
		if util.ToLower(filepath.Ext(fpath)) == ".lua" {
			if err := RunLuaVM(util.Envfmt(fpath, nil)); err != nil {
				log.Println(err.Error())
				return
			}
		}
	}
}
