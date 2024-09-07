
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

function slotjoin(token, cid, uid, alias)
	return authpost("/slot/join", token, {cid=cid, uid=uid, alias=alias})
end

function slotpart(token, gid)
	return authpost("/slot/part", token, {gid=gid})
end

function slotinfo(token, gid)
	return authpost("/slot/info", token, {gid=gid})
end

function slotbetget(token, gid)
	return authpost("/slot/bet/get", token, {gid=gid})
end

function slotbetset(token, gid, bet)
	return authpost("/slot/bet/set", token, {gid=gid, bet=bet})
end

function slotsblget(token, gid)
	return authpost("/slot/sbl/get", token, {gid=gid})
end

function slotsblset(token, gid, sbl)
	return authpost("/slot/sbl/set", token, {gid=gid, sbl=sbl})
end

function slotrtpget(token, gid)
	return authpost("/slot/rtp/get", token, {gid=gid})
end

function slotspin(token, gid)
	return authpost("/slot/spin", token, {gid=gid})
end

function slotdoubleup(token, gid, mult)
	return authpost("/slot/doubleup", token, {gid=gid, mult=mult or 2})
end

function slotcollect(token, gid)
	return authpost("/slot/collect", token, {gid=gid})
end

function propwalletget(token, cid, uid)
	return authpost("/prop/wallet/get", token, {cid=cid, uid=uid})
end

function propwalletadd(token, cid, uid, sum)
	return authpost("/prop/wallet/add", token, {cid=cid, uid=uid, sum=sum})
end

function propaccessget(token, cid, uid)
	return authpost("/prop/al/get", token, {cid=cid, uid=uid})
end

function propaccessset(token, cid, uid, al)
	return authpost("/prop/wallet/add", token, {cid=cid, uid=uid, access=al})
end

function proprtpget(token, cid, uid)
	return authpost("/prop/al/get", token, {cid=cid, uid=uid})
end

function proprtpset(token, cid, uid, mrtp)
	return authpost("/prop/wallet/add", token, {cid=cid, uid=uid, mrtp=mrtp})
end
