
----- input data begin -----
local exit = channel.make()
local signctx = channel.make() -- signin context
local usrnum = 500 -- number of players to run
local options = { -- shared options for each player
	lt = {
		warn = true,
		info = true,
		sign = false,
		cash = false,
		gset = false,
		spin = false,
		spec = false,
	},
	slotopolhost = "http://localhost:8080",
	cid = 1,
	jobtime = 5*60, -- 5m
	speed = 1, -- make it less than 1 to run faster
	signctx = signctx,
}
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

-- load games set
local games, gamenum = dofile(scrdir.."/lib/games.lua")

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
local admin, status = signin("admin@example.org", "0YBoaT")
if status >= 400 then
	printf("can not login admin account, status: %d, code: %d, message: %s", status, admin.code, admin.what)
	return
end
options.admtoken = admin.access
printf("signed in admin account with uid=%d, token expires: %s", admin.uid, admin.expire)

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
printf("signed in all %d users", usrnum)

-- wait until all threads complete
local ud = 0
local stat = channel.make()
tick(5000, stat)
repeat
	local done = false
	channel.select(
		{"|<-", exit, function(ok, err)
			if not ok then
				printf("unexpected channel closure")
				done = true
				return
			end
			if err then
				printf(err)
				exit:close()
				done = true
				return
			end
			ud = ud + 1
			if ud >= usrnum then
				done = true
				return
			end
		end},
		{"<-|", stat, nil, function()
			printf("%d backlog fails, %d spins done, %d tops up on sum %g, elapsed %s",
				atom.intget"backlog", atom.intget"spin", atom.intget"topup", atom.numget"topup", sec2dur(os.clock()))
		end},
		{"default", function()
		end}
	)
until done
stat:close()

printf("all %d threads complete, %d backlog fails, %d spins done, %d tops up on sum %g, elapsed %s.",
	usrnum, atom.intget"backlog", atom.intget"spin", atom.intget"topup", atom.numget"topup", sec2dur(os.clock()))
exit:close()
