
-- define some functions for bot workflow
local function fmt(show, ...) -- write to log formatted string
	if show then
		print(string.format(...))
	end
end
local random = math.random

if not lt then
	lt = {
		warn = true,
		info = true,
		sign = true,
		cash = true,
		gset = true,
		spin = true,
		spec = true,
	}
end
if not addr then
	addr = "http://localhost:8080"
end
if not cid then
	cid = 1
end
if not email then
	email, secret, name = "player@example.org", "Et7oAm", "player"
	fmt(lt.warn, "work with default user '%s'", name)
end
if not jobtime then
	jobtime = 15*60 -- 15m
end
if not speed then
	speed = 1
end

local spincount = 0

local betset = {0.1, 0.2, 0.5, 1, 2, 5, 10}
local bet, sbl = 1, 5

sleep(speed*random(0, 600)) -- before start

-- login admin to add money to wallet
local admin = signin(addr, "admin@example.org", "pGjkSD")
fmt(lt.sign, "[signin-admin] user: %s, expire: %s", name, admin.expire)

-- login and create registration if it needed
if signis(addr, email) == 0 then
	local uid = signup(addr, email, secret, name)
	fmt(lt.info, "created new registration with uid=%d", uid)
end
local user = signin(addr, email, secret)
fmt(lt.sign, "[signin] uid: %d, expire: %s", user.uid, user.expire)
sleep(speed*random(400, 600)) -- after login

-- check money at wallet
if propwalletget(addr, user.access, cid, user.uid) < bet*sbl then
	local wallet = propwalletadd(addr, admin.access, cid, user.uid, 1000)
	fmt(lt.cash, "[walletadd] cid: %d, uid: %d, wallet: %.7g", cid, user.uid, wallet)
	sleep(speed*random(2000, 5000))
end

-- join game
local game = gamejoin(addr, user.access, cid, user.uid, "dolphinspearl")
fmt(lt.gset, "[join] cid: %d, uid: %d, gid: %d", cid, user.uid, game.gid)
sleep(speed*random(300, 600)) -- after game join

-- change bet value
gamebetset(addr, user.access, game.gid, bet)
fmt(lt.gset, "[betset] gid: %d, bet: %.7g", game.gid, bet)
sleep(speed*400) -- after bet value
-- change bet lines, set 5 lines
gamesblset(addr, user.access, game.gid, makebitnum(sbl))
fmt(lt.gset, "[sblset] gid: %d, sbl: %d", game.gid, sbl)
sleep(speed*400) -- after bet lines

-- make some spins in the loop
while os.clock () < jobtime do
	-- make spin
	sleep(speed*random(1200, 1400)) -- reels rotation timeout
	local res = gamespin(addr, user.access, game.gid)
	fmt(lt.spin, "[spin] gid: %d, sid: %d, wallet: %.7g, gain: %.7g", game.gid, res.sid, res.wallet, res.game.gain or 0)
	spincount = spincount + 1
	for _, wi in ipairs(res.wins or {}) do
		fmt(lt.spec, "sym: %dx%d, pay: %.7gx%d", wi.sym, wi.num, wi.pay or 0, wi.mult or 0)
		if wi.free then
			sleep(speed*3000) -- free spins starts
		elseif (wi.pay or 0)*(wi.mult or 0) > 100*res.game.bet then
			sleep(speed*1200) -- big win
		else
			sleep(speed*100*random(4, 6)) -- normal win
		end
	end

	-- make doubleup sometimes
	if res.game.fs == 0 and res.game.gain and random() < 0.25 then
		local dbl
		repeat
			dbl = gamedoubleup(addr, user.access, game.gid, 2)
			fmt(lt.spin, "[doubleup] gid: %d, sid: %d, gain: %.7g", game.gid, dbl.sid, dbl.gain)
			sleep(speed*random(1000, 1200)) -- doubleup step
		until dbl.gain == 0 or random() > 0.40
		if dbl.gain > 0 then
			gamecollect(addr, user.access, game.gid)
			fmt(lt.spin, "[collect] gid: %d", game.gid)
			sleep(speed*random(600, 800)) -- doubleup end
		end
	end

	-- change bet value sometimes
	if res.game.fs == 0 and random() < 1/50 then
		bet = betset[random(#betset)]
		gamebetset(addr, user.access, game.gid, bet)
		fmt(lt.gset, "[betset] gid: %d, bet: %.7g", game.gid, bet)
		sleep(speed*600) -- after bet value
	end

	-- change selected bet lines sometimes
	if res.game.fs == 0 and random() < 1/50 then
		sbl = random(3, 10)
		gamesblset(addr, user.access, game.gid, makebitnum(sbl))
		fmt(lt.gset, "[sblset] gid: %d, sbl: %d", game.gid, sbl)
		sleep(speed*600) -- after bet lines
	end

	-- check money at wallet
	if res.wallet < bet*sbl then
		local wallet = propwalletadd(addr, admin.access, cid, user.uid, 1000)
		fmt(lt.cash, "[walletadd] cid: %d, uid: %d, wallet: %.7g", cid, user.uid, wallet)
		sleep(speed*random(2000, 5000))
	end

	-- pause sometimes
	if res.game.fs == 0 and random() < 1/100 then
		local d = random(3, 15)
		fmt(lt.info, "uid: %d, let's pause %d seconds", user.uid, d)
		sleep(speed*d*1000)
	end

	-- check quit
	local exit = false
	channel.select(
		{"|<-", quit, function()
			fmt(lt.info, "quit by break")
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
fmt(lt.gset, "[part] cid: %d, uid: %d, gid: %d", cid, user.uid, game.gid)

fmt(lt.info, "uid: %d, job complete, %d spins done.", user.uid, spincount)
