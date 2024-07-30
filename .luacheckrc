
-- configuration for `luacheck`
-- see: https://luacheck.readthedocs.io/en/stable/index.html
-- see: https://github.com/lunarmodules/luacheck

globals = {
	-- variables
	"admin",
	"lt", "addr", "cid", "email", "secret", "name", "jobtime", "speed",
	-- functions
	"makebitnum",
	"servinfo", "memusage", "gamelist",
	"signis", "signup", "signin", "refresh",
	"gamejoin", "gamepart", "gamestate",
	"gamebetget", "gamebetset", "gamesblget", "gamesblset", "gamereelsget", "gamereelsset",
	"gamespin", "gamedoubleup", "gamecollect",
	"propwalletget", "propwalletadd",
}

read_globals = {
	-- variables
	"quit",
	"buildvers", "buildtime", "bindir", "scrdir", "tmpdir",
	-- functions
	"log", "checkfile", "bin2hex", "hex2bin", "milli2time", "time2milli",
	"sleep", "thread",
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
