
----- input data begin -----
lt = {
	warn = true,
	info = true,
	sign = true,
	cash = true,
	gset = true,
	spin = true,
	spec = true,
}
slotopolhost = "http://localhost:8080"
cid = 1
jobtime = 15*60 -- 15m
speed = 1
----- input data final -----

local function printf(...) -- write to log formatted string
	print(string.format(...))
end

printf("bot version: %s, builton: %s", buildvers, buildtime)
printf("binary dir: %s", bindir)
printf("script dir: %s", scrdir)
printf("temporary dir: %s", tmpdir)

-- load games set
local games, gamenum = dofile(scrdir.."/lib/games.lua")
local n = gamenum[math.random(#gamenum)]
gameset = {}
for j = 1, n do
	gameset[j] = games[j]
end

-- load API-calls
dofile(scrdir.."/lib/api.lua")

-- login admin to add money to wallet
local admin, status = signin("admin@example.org", "0YBoaT")
if status >= 400 then
	printf("can not login admin account, status: %d, code: %d, message: %s", status, admin.code, admin.what)
	return
end
admtoken = admin.access
printf("signed in admin account with uid=%d, token expires: %s", admin.uid, admin.expire)

-- execute single thread
printf("start %d games", #gameset)
dofile(scrdir.."/lib/play.lua")
