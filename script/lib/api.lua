
local http = require("http") -- see: https://github.com/cjoudrey/gluahttp
local json = require("json") -- see: https://github.com/layeh/gopher-json
local crypto = require('crypto') -- see: https://github.com/tengattack/gluacrypto

local function lshift(a, b)
	for _ = 1, b do
		a = a*2
	end
	return a
end

function getbitnum(v)
	local b, n = 1, 0
	repeat
	  if v % (b*2) > 0 then
		v, n = v-b, n+1
	  end
	  b = b * 2
	until b > v
	return n
end

function makebitnum(num)
	return lshift(lshift(1, num) - 1, 1)
end

function servinfo(addr)
	local res, err = http.get(addr.."/servinfo")
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function memusage(addr)
	local res, err = http.get(addr.."/memusage")
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamelist(addr)
	local res, err = http.get(addr.."/gamelist")
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function signis(addr, email)
	local res, err = http.get(addr.."/signis", {query="email="..email})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.uid, res.status_code
end

function signup(addr, email, secret, name)
	local res, err = http.post(addr.."/signup", {
		headers={["Content-Type"]="application/json"},
		body=json.encode({email=email, secret=secret, name=name}),
	})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.uid, res.status_code
end

function signin(addr, email, secret)
	local sigtime = os.date('%Y-%m-%dT%H:%M:%SZ')
	local hs256 = crypto.hmac("sha256", secret, sigtime)
	local res, err = http.post(addr.."/signin", {
		headers={["Content-Type"]="application/json"},
		body=json.encode({email=email, hs256=hs256, sigtime=sigtime})
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function refresh(addr, token)
	local res, err = http.get(addr.."/signin", {
		headers={
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer "..token,
		},
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamejoin(addr, token, cid, uid, alias)
	local res, err = http.post(addr.."/game/join", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({cid=cid, uid=uid, alias=alias})
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamepart(addr, token, gid)
	local res, err = http.post(addr.."/game/part", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	return nil, res.status_code
end

function gameinfo(addr, token, gid)
	local res, err = http.post(addr.."/game/info", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamebetget(addr, token, gid)
	local res, err = http.post(addr.."/game/bet/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.bet, res.status_code
end

function gamebetset(addr, token, gid, bet)
	local res, err = http.post(addr.."/game/bet/set", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, bet=bet})
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamesblget(addr, token, gid)
	local res, err = http.post(addr.."/game/sbl/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.sbl, res.status_code
end

function gamesblset(addr, token, gid, sbl)
	local res, err = http.post(addr.."/game/sbl/set", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, sbl=sbl})
	})
	if err ~= nil then
		error(err)
	end
	return nil, res.status_code
end

function gamereelsget(addr, token, gid)
	local res, err = http.post(addr.."/game/reels/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.rtp, res.status_code
end

function gamereelsset(addr, token, gid, rtp)
	local res, err = http.post(addr.."/game/reels/set", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, rtp=rtp})
	})
	if err ~= nil then
		error(err)
	end
	return nil, res.status_code
end

function gamespin(addr, token, gid)
	local res, err = http.post(addr.."/game/spin", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamedoubleup(addr, token, gid, mult)
	local res, err = http.post(addr.."/game/doubleup", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid, mult=mult or 2})
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function gamecollect(addr, token, gid)
	local res, err = http.post(addr.."/game/collect", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({gid=gid})
	})
	if err ~= nil then
		error(err)
	end
	return nil, res.status_code
end

function propwalletget(addr, token, cid, uid)
	local res, err = http.post(addr.."/prop/wallet/get", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({cid=cid, uid=uid})
	})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.wallet, res.status_code
end

function propwalletadd(addr, token, cid, uid, sum)
	local res, err = http.post(addr.."/prop/wallet/add", {
		headers={
			["Content-Type"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode({cid=cid, uid=uid, sum=sum})
	})
	if err ~= nil then
		error(err)
	end
	local t = json.decode(res.body)
	return t.wallet, res.status_code
end
