
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

local backlog = "No connection could be made because the target machine actively refused it"
local function checkbody(f, ...)
	local ok, res, status
	repeat
		ok, res, status = pcall(f, ...)
		if not ok then
			if res:match(backlog) then
				sleep(0)
			else
				error(res) -- throw it again
			end
		end
	until ok
	if status >= 400 then
		print(string.format("status: %d, code: %d, message: %s",
			status, res.code, res.what), debug.traceback())
		os.exit(1)
	end
	return res
end

local usrnum = 5 -- number of players to run

-- prepare users table before anything to keep passwords sequences
local users = {}
for i = 1, usrnum do
	users[i] = {
		name = string.format("player%04d", i),
		email = string.format("player%04d@example.org", i),
		secret = makepass(6),
	}
end

slotopolhost = "http://localhost:8080"

-- load API-calls
dofile(scrdir.."/lib/api.lua")

-- login admin to add money to wallet
local admin = checkbody(signin, "admin@example.org", "0YBoaT")
local admtoken = admin.access
fmt("signed in admin account with uid=%d, token expires: %s", admin.uid, admin.expire)

-- generate players
local n = 0
for _, user in ipairs(users) do
	local uid = checkbody(signis, user.email).uid
	if uid == 0 then
		uid = checkbody(admsignup, admtoken, user.email, user.secret, user.name).uid
		fmt("#%d (%s): registered", uid, user.email)
		n = n + 1
	else
		fmt("#%d (%s): exist", uid, user.email)
	end
end
fmt("total %d accounts, created %d accounts, job complete.", usrnum, n)
