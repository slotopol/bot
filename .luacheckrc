
-- configuration for `luacheck`
-- see: https://luacheck.readthedocs.io/en/stable/index.html
-- see: https://github.com/lunarmodules/luacheck

globals = {
	-- variables
	"signctx", "admtoken",
	"lt", "slotopolhost", "cid", "email", "secret", "name", "jobtime", "speed", "gameset",
	-- functions
	"getbitnum", "makebitnum", "shuffle", "kenospots",
	"servinfo", "memusage", "gamelist",
	"signis", "signup", "admsignup", "signin", "refresh",
	"gamejoin", "gamepart", "gameinfo", "gamertpget",
	"slotbetget", "slotbetset", "slotselget", "slotselset",
	"slotspin", "slotdoubleup", "slotcollect",
	"kenobetget", "kenobetset", "kenoselget", "kenoselset",
	"kenoselgetslice", "kenoselsetslice", "kenospin",
	"propwalletget", "propwalletadd", "propaccessget", "propaccessset", "proprtpget", "proprtpset",
}

read_globals = {
	-- modules
	"path", "atom",
	-- variables
	"quit",
	"buildvers", "buildtime", "bindir", "scrdir", "tmpdir",
	-- functions
	"log", "checkfile", "bin2hex", "hex2bin", "milli2time", "time2milli", "sec2dur",
	"after", "tick", "sleep", "thread",
}

std = { -- Lua 5.1 & GopherLua
	read_globals = {
		-- basic functions
		"assert", "collectgarbage", "dofile", "error", "_G", "getfenv",
		"getmetatable", "ipairs", "load", "loadfile", "loadstring",
		"next", "pairs", "pcall", "print",
		"rawequal", "rawget", "rawset", "select", "setfenv", "setmetatable",
		"tonumber", "tostring", "type", "unpack", "_VERSION", "xpcall",
		"module", "require",
		"goto", -- GopherLua
		-- basic libraries
		"coroutine", "debug", "io", "math", "os", "package", "string", "table",
		"channel" -- GopherLua
	}
}
