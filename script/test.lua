
-- define some functions for bot workflow
local function fmt(...) -- write to log formatted string
	print(string.format(...))
end

fmt("bot version: %s, builton: %s", buildvers, buildtime)
fmt("binary dir: %s", bindir)
fmt("script dir: %s", scrdir)
fmt("temporary dir: %s", tmpdir)

-- load API-calls
dofile "script/api.lua"

local addr = "http://localhost:8080"
local cid = 1
local email, secret, name = "player@example.org", "Et7oAm", "player"

-- login and create registration if it needed
if not signis(addr, email) then
	local uid = signup(addr, email, secret, name)
	fmt("created new registration with uid=%d", uid)
end
local user = signin(addr, "player@example.org", "Et7oAm")
fmt("[signin] uid: %d, expire: %s", user.uid, user.expire)

-- join game
local game = gamejoin(addr, user.access, cid, user.uid, "dolphinspearl")
fmt("[join] cid: %d, uid: %d, gid: %d", cid, user.uid, game.gid)

-- change bet lines, set 5 lines
gamesblset(addr, user.access, game.gid, 62)

-- make some spins
for _ = 1,10 do
	local res = gamespin(addr, user.access, game.gid)
	fmt("[spin] gid: %d, sid: %d, gain: %d", game.gid, res.sid, res.game.gain or 0)
end

-- part game
gamepart(addr, user.access, game.gid)
fmt("[part] cid: %d, uid: %d, gid: %d", cid, user.uid, game.gid)

print "job complete."
