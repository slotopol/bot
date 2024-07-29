
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

if not addr then
	addr = "http://localhost:8080"
end
if not cid then
	cid = 1
end
if not email then
	email, secret, name = "player@example.org", "Et7oAm", "player"
end
if not jobtime then
	jobtime = 15*60 -- 15m
end
if not speed then
	speed = 1
end

local spincount = 0

local betset = {0.1, 0.2, 0.5, 1, 2, 5, 10}
local bet = 1

-- login admin to add money to wallet
local admin = signin(addr, "admin@example.org", "pGjkSD")
fmt("[signin] uid: %d, expire: %s", admin.uid, admin.expire)

-- login and create registration if it needed
if not signis(addr, email) then
	local uid = signup(addr, email, secret, name)
	fmt("created new registration with uid=%d", uid)
end
local user = signin(addr, email, secret)
fmt("[signin] uid: %d, expire: %s", user.uid, user.expire)
sleep(speed*400) -- after login

-- check money at wallet
if propwalletget(addr, user.access, cid, user.uid) < bet*20 then
	local wallet = propwalletadd(addr, admin.access, cid, user.uid, 1000)
	fmt("[walletadd] cid: %d, uid: %d, wallet: %.7g", cid, user.uid, wallet)
	sleep(speed*3000)
end

-- join game
local game = gamejoin(addr, user.access, cid, user.uid, "dolphinspearl")
fmt("[join] cid: %d, uid: %d, gid: %d", cid, user.uid, game.gid)
sleep(speed*400) -- after game join

-- change bet value
gamebetset(addr, user.access, game.gid, bet)
fmt("[betset] gid: %d, bet: %.7g", game.gid, bet)
sleep(speed*400) -- after bet value
-- change bet lines, set 5 lines
gamesblset(addr, user.access, game.gid, makebitnum(5))
fmt("[sblset] gid: %d, sbl: 5", game.gid)
sleep(speed*400) -- after bet lines

-- make some spins in the loop
while os.clock () < jobtime do
	-- make spin
	sleep(speed*1400) -- reels rotation timeout
	local res = gamespin(addr, user.access, game.gid)
	fmt("[spin] gid: %d, sid: %d, wallet: %.7g, gain: %.7g", game.gid, res.sid, res.wallet, res.game.gain or 0)
	spincount = spincount + 1
	for _, wi in ipairs(res.wins or {}) do
		fmt("sym: %dx%d, pay: %.7gx%d", wi.sym, wi.num, wi.pay or 0, wi.mult or 0)
		if wi.free then
			sleep(speed*3000) -- free spins starts
		elseif (wi.pay or 0)*(wi.mult or 0) > 100*res.game.bet then
			sleep(speed*1200) -- big win
		else
			sleep(speed*500) -- normal win
		end
	end

	-- make doubleup sometimes
	if res.game.fs == 0 and res.game.gain and math.random() < 0.25 then
		local dbl
		repeat
			dbl = gamedoubleup(addr, user.access, game.gid, 2)
			fmt("[doubleup] gid: %d, sid: %d, gain: %.7g", game.gid, dbl.sid, dbl.gain)
			sleep(speed*1200) -- doubleup step
		until dbl.gain == 0 or math.random() > 0.40
		if dbl.gain > 0 then
			gamecollect(addr, user.access, game.gid)
			fmt("[collect] gid: %d", game.gid)
			sleep(speed*600) -- doubleup end
		end
	end

	-- check money at wallet
	if res.wallet < bet then
		local wallet = propwalletadd(addr, admin.access, cid, user.uid, 1000)
		fmt("[walletadd] cid: %d, uid: %d, wallet: %.7g", cid, user.uid, wallet)
		sleep(speed*5000)
	end

	-- change bet value sometimes
	if res.game.fs == 0 and math.random() < 1/50 then
		bet = betset[math.random(#betset)]
		gamebetset(addr, user.access, game.gid, bet)
		fmt("[betset] gid: %d, bet: %.7g", game.gid, bet)
		sleep(speed*600) -- after bet value
	end

	-- change selected bet lines sometimes
	if res.game.fs == 0 and math.random() < 1/50 then
		local num = math.random(3, 10)
		gamesblset(addr, user.access, game.gid, makebitnum(num))
		fmt("[sblset] gid: %d, sbl: %d", game.gid, num)
		sleep(speed*600) -- after bet lines
	end

	-- pause sometimes
	if res.game.fs == 0 and math.random() < 1/100 then
		local d = math.random(3, 15)
		fmt("uid: %d, let's pause %d seconds", user.uid, d)
		sleep(speed*d*1000)
	end

	-- check quit
	local exit = false
	channel.select(
		{"|<-", quit, function()
			fmt"quit by break"
			exit = true
		end},
		{"default", function()
		end}
	)
	if exit then
		break
	end
end

-- part game
gamepart(addr, user.access, game.gid)
fmt("[part] cid: %d, uid: %d, gid: %d", cid, user.uid, game.gid)

fmt("uid: %d, job complete, %d spins done.", user.uid, spincount)
