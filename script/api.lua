
local http = require("http") -- see: https://github.com/cjoudrey/gluahttp
local json = require("json") -- see: https://github.com/layeh/gopher-json
local crypto = require('crypto') -- see: https://github.com/tengattack/gluacrypto

local function checkres(res, err)
	if err ~= nil then
		error(err)
	end
	if res.status_code ~= 200 then
		local t = json.decode(res.body)
		error(string.format("status: %d, code: %d, message: %s", res.status_code, t.code, t.what))
	end
end

local function lshift(a, b)
	for _ = 1, b do
		a = a*2
	end
	return a
end

function makebitnum(num)
	return lshift(lshift(1, num) - 1, 1)
end

function servinfo(addr)
	local res, err = http.get(addr.."/servinfo")
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body)
end

function memusage(addr)
	local res, err = http.get(addr.."/memusage")
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body)
end

function gamelist(addr)
	local res, err = http.get(addr.."/gamelist")
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body)
end

function signis(addr, email)
	local res, err = http.get(addr.."/signis", {query="email="..email})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.uid
end

function signup(addr, email, secret, name)
	local res, err = http.post(addr.."/signup", {
		headers={["Content-Type"]="application/json"},
		body=json.encode({email=email, secret=secret, name=name}),
	})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.uid
end

function signin(addr, email, secret)
	local sigtime = os.date('%Y-%m-%dT%H:%M:%SZ')
	local hs256 = crypto.hmac("sha256", secret, sigtime)
	local res, err = http.post(addr.."/signin", {
		headers={["Content-Type"]="application/json"},
		body=json.encode({email=email, hs256=hs256, sigtime=sigtime})
	})
	checkres(res, err)
	return json.decode(res.body)
end

function refresh(addr, token)
	local res, err = http.get(addr.."/signin", {
		headers={
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer "..token,
		},
	})
	checkres(res, err)
	return json.decode(res.body)
end

function gamejoin(addr, token, cid, uid, alias)
	local res, err = http.post(addr.."/game/join", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({cid=cid, uid=uid, alias=alias})
	})
	checkres(res, err)
	return json.decode(res.body)
end

function gamepart(addr, token, gid)
	local res, err = http.post(addr.."/game/part", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
end

function gamestate(addr, token, gid)
	local res, err = http.post(addr.."/game/state", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
	return json.decode(res.body)
end

function gamebetget(addr, token, gid)
	local res, err = http.post(addr.."/game/bet/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.bet
end

function gamebetset(addr, token, gid, bet)
	local res, err = http.post(addr.."/game/bet/set", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, bet=bet})
	})
	checkres(res, err)
end

function gamesblget(addr, token, gid)
	local res, err = http.post(addr.."/game/sbl/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.sbl
end

function gamesblset(addr, token, gid, sbl)
	local res, err = http.post(addr.."/game/sbl/set", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, sbl=sbl})
	})
	checkres(res, err)
end

function gamereelsget(addr, token, gid)
	local res, err = http.post(addr.."/game/reels/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.rd
end

function gamereelsset(addr, token, gid, rd)
	local res, err = http.post(addr.."/game/reels/set", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, rd=rd})
	})
	checkres(res, err)
end

function gamespin(addr, token, gid)
	local res, err = http.post(addr.."/game/spin", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
	return json.decode(res.body)
end

function gamedoubleup(addr, token, gid, mult)
	local res, err = http.post(addr.."/game/doubleup", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, mult=mult or 2})
	})
	checkres(res, err)
	return json.decode(res.body)
end

function gamecollect(addr, token, gid)
	local res, err = http.post(addr.."/game/collect", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	checkres(res, err)
end

function propwalletget(addr, token, cid, uid)
	local res, err = http.post(addr.."/prop/wallet/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({cid=cid, uid=uid})
	})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.wallet
end

function propwalletadd(addr, token, cid, uid, sum)
	local res, err = http.post(addr.."/prop/wallet/add", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({cid=cid, uid=uid, sum=sum})
	})
	checkres(res, err)
	local t = json.decode(res.body)
	return t.wallet
end
