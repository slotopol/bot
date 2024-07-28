
-- configuration for `luacheck`
-- see: https://luacheck.readthedocs.io/en/stable/index.html
-- see: https://github.com/lunarmodules/luacheck

globals = {
	"makebitnum",
	"servinfo", "memusage", "gamelist",
	"signis", "signup", "signin", "refresh",
	"gamejoin", "gamepart", "gamestate",
	"gamebetget", "gamebetset", "gamesblget", "gamesblset", "gamereelsget", "gamereelsset",
	"gamespin", "gamedoubleup", "gamecollect",
	"propwalletget", "propwalletadd",
}

read_globals = {
	"buildvers", "buildtime", "bindir", "scrdir", "tmpdir",
	"log", "checkfile", "bin2hex", "hex2bin", "milli2time", "time2milli", "sleep",
}
