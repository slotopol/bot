
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

function shuffle(n, f)
	for i = n, 1, -1 do
		f(i, math.random(i))
	end
end

function kenospots(n)
	local t = {}
	for i = 1, 80 do
		t[i] = i
	end
	shuffle(80, function(i, j)
		t[i], t[j] = t[j], t[i]
	end)
	local ret = {}
	for i = 1, n do
		ret[i] = t[i]
	end
	return ret
end

local addr = slotopolhost

local function httpget(path, query)
	local res, err = http.get(addr..path, {
		headers={
			["Accept"]="application/json",
		},
		query=query
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

local function httppost(path, body)
	local res, err = http.post(addr..path, {
		headers={
			["Content-Type"]="application/json",
			["Accept"]="application/json",
		},
		body=json.encode(body)
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

local function authpost(path, token, body)
	local res, err = http.post(addr..path, {
		headers={
			["Content-Type"]="application/json",
			["Accept"]="application/json",
			["Authorization"] = "Bearer "..token,
		},
		body=json.encode(body)
	})
	if err ~= nil then
		error(err)
	end
	return json.decode(res.body), res.status_code
end

function servinfo()
	return httpget("/servinfo", nil)
end

function memusage()
	return httpget("/memusage", nil)
end

function gamelist()
	return httpget("/gamelist", nil)
end

function signis(email)
	return httpget("/signis", "email="..email)
end

function signup(email, secret, name)
	return httppost("/signup", {email=email, secret=secret, name=name})
end

function admsignup(token, email, secret, name)
	return authpost("/signup", token, {email=email, secret=secret, name=name})
end

function signin(email, secret)
	local sigtime = os.date('%Y-%m-%dT%H:%M:%SZ')
	local hs256 = crypto.hmac("sha256", secret, sigtime)
	return httppost("/signin", {email=email, hs256=hs256, sigtime=sigtime})
end

function refresh(token)
	return authpost("/refresh", token, nil)
end

function gamenew(token, cid, uid, alias)
	return authpost("/game/new", token, {cid=cid, uid=uid, alias=alias})
end

function gamejoin(token, cid, uid, gid)
	return authpost("/game/join", token, {cid=cid, uid=uid, gid=gid})
end

function gameinfo(token, gid)
	return authpost("/game/info", token, {gid=gid})
end

function gamertpget(token, gid)
	return authpost("/game/rtp/get", token, {gid=gid})
end

function slotbetget(token, gid)
	return authpost("/slot/bet/get", token, {gid=gid})
end

function slotbetset(token, gid, bet)
	return authpost("/slot/bet/set", token, {gid=gid, bet=bet})
end

function slotselget(token, gid)
	return authpost("/slot/sel/get", token, {gid=gid})
end

function slotselset(token, gid, sel)
	return authpost("/slot/sel/set", token, {gid=gid, sel=sel})
end

function slotspin(token, gid)
	atom.intinc"spin"
	return authpost("/slot/spin", token, {gid=gid})
end

function slotdoubleup(token, gid, mult)
	return authpost("/slot/doubleup", token, {gid=gid, mult=mult or 2})
end

function slotcollect(token, gid)
	return authpost("/slot/collect", token, {gid=gid})
end

function kenobetget(token, gid)
	return authpost("/keno/bet/get", token, {gid=gid})
end

function kenobetset(token, gid, bet)
	return authpost("/keno/bet/set", token, {gid=gid, bet=bet})
end

function kenoselget(token, gid)
	return authpost("/keno/sel/get", token, {gid=gid})
end

function kenoselset(token, gid, sel)
	return authpost("/keno/sel/set", token, {gid=gid, sel=sel})
end

function kenoselgetslice(token, gid)
	return authpost("/keno/sel/getslice", token, {gid=gid})
end

function kenoselsetslice(token, gid, idx)
	return authpost("/keno/sel/setslice", token, {gid=gid, sel=idx})
end

function kenospin(token, gid)
	atom.intinc"spin"
	return authpost("/keno/spin", token, {gid=gid})
end

function propget(token, cid, uid)
	return authpost("/prop/get", token, {cid=cid, uid=uid})
end

function propwalletget(token, cid, uid)
	return authpost("/prop/wallet/get", token, {cid=cid, uid=uid})
end

function propwalletadd(token, cid, uid, sum)
	atom.intinc"topup"
	atom.numadd("topup", sum)
	return authpost("/prop/wallet/add", token, {cid=cid, uid=uid, sum=sum})
end

function propaccessget(token, cid, uid, all)
	return authpost("/prop/al/get", token, {cid=cid, uid=uid, all=all or false})
end

function propaccessset(token, cid, uid, al)
	return authpost("/prop/wallet/add", token, {cid=cid, uid=uid, access=al})
end

function proprtpget(token, cid, uid, all)
	return authpost("/prop/al/get", token, {cid=cid, uid=uid, all=all or false})
end

function proprtpset(token, cid, uid, mrtp)
	return authpost("/prop/wallet/add", token, {cid=cid, uid=uid, mrtp=mrtp})
end
