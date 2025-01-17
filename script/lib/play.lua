
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
if not slotopolhost then
	slotopolhost = "http://localhost:8080"
end
if not cid then
	cid = 1
end
if not email then
	email, secret, name = "player@example.org", "iVI05M", "player"
	fmt(lt.warn, "work with default user '%s'", name)
end
if not jobtime then
	jobtime = 15*60 -- 15m
end
if not speed then
	speed = 1
end
if not gameset then
	gameset = {
		{
			class = "slot",
			alias = "novomatic/dolphinspearl",
			gid = 0,
			changesbl = true,
			bet = 1, sln = 5,
			fsr = 0, gain = 0,
		},
	}
end

local spincount = 0

local betset = {0.1, 0.2, 0.5, 1, 2, 5, 10}
local sumset = { -- set of sums to add to wallet
	50, 50, 50, 50,
	100, 100, 100, 100, 100, 100,
	200, 200, 200, 200,
	250, 250, 250, 250, 250, 250,
	300, 300,
	500, 500, 500, 500, 500, 500, 500, 500,
	600,
	700,
	800,
	1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
	1500, 1500,
	2000, 2000,
	5000, 5000,
	10000,
}
local uid, wallet = 0, 0
local usrtoken

local game = {} -- game settings from gameset array
local errmsg = [[status: %d, code: %d, message: %s,
alias: %s, uid: %d, gid: %d, wallet: %.7g, bet: %.7g, sln: %d,
spincount: %d
]]
local backlog = "No connection could be made because the target machine actively refused it"
local function checkres(f, ...)
	local ok, res, status
	repeat
		ok, res, status = pcall(f, ...)
		if not ok then
			if res:match(backlog) then
				atom.intint"backlog"
				sleep(10)
			else
				error(res) -- throw it again
			end
		end
	until ok
	if status >= 400 then
		res = res or {}
		print(string.format(errmsg,
			status, res.code, res.what,
			game.alias, uid, game.gid, wallet, game.bet, game.sln,
			spincount), debug.traceback())
		os.exit(1)
	end
	return res
end
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
	if not res then
		print(string.format(errmsg,
			status, 0, "get nil body response",
			game.alias, uid, game.gid, wallet, game.bet, game.sln,
			spincount), debug.traceback())
		os.exit(1)
	elseif status >= 400 then
		print(string.format(errmsg,
			status, res.code, res.what,
			game.alias, uid, game.gid, wallet, game.bet, game.sln,
			spincount), debug.traceback())
		os.exit(1)
	end
	return res
end

local res -- result of query

-- login and create registration if it needed
uid = checkbody(signis, email).uid
if uid == 0 then
	uid = checkbody(admsignup, admtoken, email, secret, name).uid
	fmt(lt.info, "created new registration with uid=%d", uid)
end
res = checkbody(signin, email, secret)
uid, usrtoken = res.uid, res.access
fmt(lt.sign, "[signin] uid: %d, secret: %s", uid, secret)
if signctx then
	signctx:send(uid)
end
sleep(speed*random(400, 600)) -- after login

for _, v in pairs(gameset) do
	game = v
	-- create game
	res = checkbody(gamenew, usrtoken, cid, uid, game.alias)
	game.gid, wallet = res.gid, res.wallet
	fmt(lt.gset, "[new] cid: %d, uid: %d, gid: %d, alias: %s", cid, uid, game.gid, game.alias)
	sleep(speed*random(300, 600)) -- after game creation

	if game.class == "slot" then
		-- change bet value before spins
		checkres(slotbetset, usrtoken, game.gid, game.bet)
		fmt(lt.gset, "[betset] gid: %d, bet: %.7g", game.gid, game.bet)
		sleep(speed*400) -- after bet value
		-- change bet lines before spins
		if game.sln > 0 then
			checkres(slotselset, usrtoken, game.gid, game.sln)
			fmt(lt.gset, "[selset] gid: %d, sln: %d", game.gid, game.sln)
			sleep(speed*400) -- after bet lines
		else
			game.sln = checkres(slotselget, usrtoken, game.gid).sel
		end
	elseif game.class == "keno" then
		-- change bet value before spins
		checkres(kenobetset, usrtoken, game.gid, game.bet)
		fmt(lt.gset, "[betset] gid: %d, bet: %.7g", game.gid, game.bet)
		sleep(speed*400) -- after bet value
		-- change selected spots before spins
		checkres(kenoselsetslice, usrtoken, game.gid, kenospots(game.ssn))
		fmt(lt.gset, "[selset] gid: %d, ssn: %d", game.gid, game.ssn)
		sleep(speed*400) -- after spots
	else
		fmt(lt.warn, "uid: %d, alias is %s, game class not recognized", uid, game.alias)
		os.exit(1)
	end
end

sleep(speed*random(0, 800)) -- pause before spins

local function slotloop()
	-- check money at wallet
	if wallet < game.bet*game.sln then
		local sum
		repeat
			sum = sumset[random(#sumset)]
		until wallet + sum >= game.bet*game.sln
		wallet = checkbody(propwalletadd, admtoken, cid, uid, sum).wallet
		fmt(lt.cash, "[walletadd] cid: %d, uid: %d, bet: %.7g, sln: %d, wallet: %.7g, sum: %.7g",
			cid, uid, game.bet, game.sln, wallet, sum)
		sleep(speed*random(2000, 5000))
	end

	-- make spin
	sleep(speed*random(1200, 1400)) -- reels rotation timeout
	res = checkbody(slotspin, usrtoken, game.gid)
	wallet, game.gain, game.bet, game.sln, game.fsr =
		res.wallet, res.game.gain or 0, res.game.bet, res.game.sel, res.game.fsr or 0
	fmt(lt.spin, "[spin] gid: %d, sid: %d, fsr: %d, wallet: %.7g, gain: %.7g",
		game.gid, res.sid, game.fsr, wallet, game.gain)
	spincount = spincount + 1
	for _, wi in ipairs(res.wins or {}) do
		fmt(lt.spec, "sym: %dx%d, pay: %.7gx%d", wi.sym, wi.num, wi.pay or 0, wi.mult or 0)
		if wi.free then
			sleep(speed*3000) -- free spins starts
		elseif (wi.pay or 0)*(wi.mult or 0) > 100*game.bet then
			sleep(speed*1200) -- big win
		else
			sleep(speed*100*random(4, 6)) -- normal win
		end
	end

	-- make doubleup sometimes
	if game.fsr == 0 and game.gain > 0 and random() < 0.25 then
		repeat
			res = checkbody(slotdoubleup, usrtoken, game.gid, 2)
			wallet = res.wallet
			fmt(lt.spin, "[doubleup] gid: %d, id: %d, gain: %.7g", game.gid, res.id, res.gain)
			sleep(speed*random(1000, 1200)) -- doubleup step
		until res.gain == 0 or random() > 0.40
		if res.gain > 0 then
			checkres(slotcollect, usrtoken, game.gid)
			fmt(lt.spin, "[collect] gid: %d", game.gid)
			sleep(speed*random(600, 800)) -- doubleup end
		end
	end

	-- change bet value sometimes
	if game.fsr == 0 and random() < 1/50 then
		game.bet = betset[random(#betset)]
		checkres(slotbetset, usrtoken, game.gid, game.bet)
		fmt(lt.gset, "[betset] gid: %d, bet: %.7g", game.gid, game.bet)
		sleep(speed*600) -- after bet value
	end

	-- change selected bet lines sometimes
	if game.changesbl and game.fsr == 0 and random() < 1/50 then
		game.sln = random(3, 10)
		checkres(slotselset, usrtoken, game.gid, game.sln)
		fmt(lt.gset, "[selset] gid: %d, sln: %d", game.gid, game.sln)
		sleep(speed*600) -- after bet lines
	end
end

local function kenoloop()
	-- check money at wallet
	if wallet < game.bet then
		local sum
		repeat
			sum = sumset[random(#sumset)]
		until wallet + sum >= game.bet
		wallet = checkbody(propwalletadd, admtoken, cid, uid, sum).wallet
		fmt(lt.cash, "[walletadd] cid: %d, uid: %d, bet: %.7g, ssn: %d, wallet: %.7g, sum: %.7g",
			cid, uid, game.bet, game.ssn, wallet, sum)
		sleep(speed*random(2000, 5000))
	end

	-- make spin
	sleep(speed*random(1200, 1400)) -- reels rotation timeout
	res = checkbody(kenospin, usrtoken, game.gid)
	wallet, game.gain = res.wallet, res.wins.pay
	fmt(lt.spin, "[spin] gid: %d, sid: %d, ssn: %d, wallet: %.7g, num: %d, pay: %.7g",
		game.gid, res.sid, game.ssn, wallet, res.wins.num, res.wins.pay)
	spincount = spincount + 1
	if res.wins.pay > 100*game.bet then
		fmt(lt.spec, "big win!")
		sleep(speed*1200) -- big win
	else
		sleep(speed*100*random(4, 6)) -- normal win
	end

	-- change bet value sometimes
	if random() < 1/50 then
		game.bet = betset[random(#betset)]
		checkres(kenobetset, usrtoken, game.gid, game.bet)
		fmt(lt.gset, "[betset] gid: %d, bet: %.7g", game.gid, game.bet)
		sleep(speed*600) -- after bet value
	end

	-- change selected spots sometimes
	if random() < 1/50 then
		game.ssn = random(2, 10)
		checkres(kenoselsetslice, usrtoken, game.gid, kenospots(game.ssn))
		fmt(lt.gset, "[selset] gid: %d, ssn: %d", game.gid, game.ssn)
		sleep(speed*600) -- after bet lines
	end
end

-- make some spins in the loop
while os.clock () < jobtime do
	game = gameset[random(#gameset)]
	if game.class == "slot" then
		slotloop()
	elseif game.class == "keno" then
		kenoloop()
	end

	-- pause sometimes
	if game.fsr == 0 and random() < 1/100 then
		local d = random(3, 15)
		fmt(lt.gset, "uid: %d, let's pause %d seconds", uid, d)
		sleep(speed*d*1000)
	end

	-- check quit
	local exit = false
	channel.select(
		{"|<-", quit, function()
			fmt(lt.gset, "uid: %d, quit by break", uid)
			exit = true
		end},
		{"default", function()
		end}
	)
	if exit then
		break
	end
end

fmt(lt.info, "uid: %d, job complete, %d spins done.", uid, spincount)
