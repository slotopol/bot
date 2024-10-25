
----- input data begin -----
local usrnum = 5000 -- number of players to run
slotopolhost = "http://localhost:8080"
----- input data final -----

local function printf(...) -- write to log formatted string
	print(string.format(...))
end

printf("bot version: %s, builton: %s", buildvers, buildtime)
printf("binary dir: %s", bindir)
printf("script dir: %s", scrdir)
printf("temporary dir: %s", tmpdir)

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
local admin = checkbody(signin, "admin@example.org", "0YBoaT")
local admtoken = admin.access
printf("signed in admin account with uid=%d, token expires: %s", admin.uid, admin.expire)

-- generate players
local n = 0
for _, user in ipairs(users) do
	local uid = checkbody(signis, user.email).uid
	if uid == 0 then
		uid = checkbody(admsignup, admtoken, user.email, user.secret, user.name).uid
		printf("#%d (%s): registered", uid, user.email)
		n = n + 1
	else
		printf("#%d (%s): exist", uid, user.email)
	end
end
printf("total %d accounts, created %d accounts, elapsed %s, job complete.", usrnum, n, sec2dur(os.clock()))
