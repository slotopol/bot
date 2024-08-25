
-- define some functions for bot workflow
local function fmt(...) -- write to log formatted string
	print(string.format(...))
end

fmt("bot version: %s, builton: %s", buildvers, buildtime)
fmt("binary dir: %s", bindir)
fmt("script dir: %s", scrdir)
fmt("temporary dir: %s", tmpdir)

lt = {
	warn = true,
	info = true,
	sign = true,
	cash = true,
	gset = true,
	spin = true,
	spec = true,
}
addr = "http://localhost:8080"
cid = 1
jobtime = 15*60 -- 15m
speed = 1

-- load games set
local games, gamenum = dofile(scrdir.."/games.lua")
local n = gamenum[math.random(#gamenum)]
gameset = {}
for j = 1, n do
	gameset[j] = games[j]
end

-- load API-calls
dofile(scrdir.."/api.lua")

-- login admin to add money to wallet
local admin, status = signin(addr, "admin@example.org", "0YBoaT")
if status >= 400 then
	fmt("can not login admin account, status: %d, code: %d, message: %s", status, admin.code, admin.what)
	return
end
admtoken = admin.access
fmt("signed in admin account with uid=%d, token expires: %s", admin.uid, admin.expire)

-- execute single thread
fmt("start %d games", n)
dofile(scrdir.."/play.lua")
