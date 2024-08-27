
-- define some functions for bot workflow
local function fmt(...) -- write to log formatted string
	print(string.format(...))
end

fmt("bot version: %s, builton: %s", buildvers, buildtime)
fmt("binary dir: %s", bindir)
fmt("script dir: %s", scrdir)
fmt("temporary dir: %s", tmpdir)

local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" -- base62 charset

math.randomseed(27) -- produce equal sequences of passwords on each run

local function makepass(n)
	local t = {}
	for i = 1, n do
		local p = math.random(#charset)
		t[i] = string.sub(charset, p, p)
	end
	return table.concat(t)
end

-- load games set
local games, gamenum = dofile(scrdir.."/lib/games.lua")

local exit = channel.make()
local signctx = channel.make() -- signin context
local usrnum = 500 -- number of players to run
local options = { -- shared options for each player
	lt = {
		warn = true,
		info = true,
		sign = true,
		cash = true,
		gset = false,
		spin = false,
		spec = false,
	},
	addr = "http://localhost:8080",
	cid = 1,
	jobtime = 5*60, -- 5m
	speed = 1, -- make it less than 1 to run faster
	signctx = signctx,
}

-- prepare users table before anything to keep passwords sequences
local users = {}
for i = 1, usrnum do
	users[i] = {
		name = string.format("player%04d", i),
		email = string.format("player%04d@example.org", i),
		secret = makepass(6),
	}
end

-- load API-calls
dofile(scrdir.."/lib/api.lua")

-- login admin to add money to wallet
local admin, status = signin(options.addr, "admin@example.org", "0YBoaT")
if status >= 400 then
	fmt("can not login admin account, status: %d, code: %d, message: %s", status, admin.code, admin.what)
	return
end
options.admtoken = admin.access
fmt("signed in admin account with uid=%d, token expires: %s", admin.uid, admin.expire)

local function tcopy(src)
	local dst = {}
	for k, v in pairs(src) do
		dst[k] = v
	end
	return dst
end

-- generate players each of which at own thread
for i = 1, usrnum do
	-- prepare games set for each player
	local n = gamenum[math.random(#gamenum)]
	local gameset = {}
	for j = 1, n do
		gameset[j] = tcopy(games[j])
	end
	-- start thread
	thread(
		users[i], options, {gameset = gameset}, exit,
		scrdir.."/lib/api.lua", scrdir.."/lib/play.lua"
	)
	signctx:receive()
end
signctx:close()

-- wait until all threads complete
for _ = 1, usrnum do
	local ok, err = exit:receive()
	if not ok then
		fmt("unexpected channel closure")
		return
	end
	if err then
		fmt(err)
		exit:close()
		return
	end
end

fmt("all %d threads complete.", usrnum)
exit:close()
