
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

---@class auth
---Structure with authorizarion data.
---@field uid integer user identifier
---@field email string user email
---@field access string access token, used for calls with authorization required
---@field refrsh string refresh token, used only to get new tokens pair
---@field expire string time of access token expiration
---@field period string period until new tokens pair can be get
---@field expireunix integer unix-time of access token expiration
---@field periodunix integer unix-time period until new tokens pair can be get

---@param path string URI of the endpoint
---@param query string? formatted parameters
---@return table data structure with endpoubt call result
---@return integer status HTTP status code
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

---@param path string URI of the endpoint
---@param body table? structure with the data
---@return table data structure with endpoubt call result
---@return integer status HTTP status code
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

---@param path string URI of the endpoint
---@param auth auth authorization table, should contain user ID, email, `access` and `refresh` tokens, expiration time.
---@param body table? structure with the data
---@return table data structure with endpoubt call result
---@return integer status HTTP status code
local function authpost(path, auth, body)
	if os.time() > auth.expireunix-15 then
		local status
		auth, status = refresh(auth)
		if status ~= 200 then
			error("can not refresh token")
		end
	end
	local res, err = http.post(addr..path, {
		headers={
			["Content-Type"]="application/json",
			["Accept"]="application/json",
			["Authorization"] = "Bearer "..auth.access,
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

function gamealgs()
	return httpget("/game/algs", nil)
end

function gamelist()
	return httpget("/game/list", nil)
end

function signis(email)
	return httpget("/signis", "email="..email)
end

function signup(email, secret, name)
	return httppost("/signup", {email=email, secret=secret, name=name})
end

function admsignup(auth, email, secret, name)
	return authpost("/signup", auth, {email=email, secret=secret, name=name})
end

function signin(email, secret)
	local sigtime = os.date('%Y-%m-%dT%H:%M:%SZ')
	local hs256 = crypto.hmac("sha256", secret, sigtime)
	local auth, status = httppost("/signin", {email=email, hs256=hs256, sigtime=sigtime})
	if status == 200 then
		auth.expireunix = time2milli(auth.expire, "2006-01-02T15:04:05Z07:00")/1000
		auth.periodunix = time2milli(auth.period, "2006-01-02T15:04:05Z07:00")/1000
	end
	return auth, status
end

function refresh(oldauth)
	local auth, status = httppost("/token", {refrsh=oldauth.refrsh})
	if status == 200 then
		auth.expireunix = time2milli(auth.expire, "2006-01-02T15:04:05Z07:00")/1000
		auth.periodunix = time2milli(auth.period, "2006-01-02T15:04:05Z07:00")/1000
	end
	return auth, status
end

function gamenew(auth, cid, uid, alias)
	return authpost("/game/new", auth, {cid=cid, uid=uid, alias=alias})
end

function gamejoin(auth, cid, uid, gid)
	return authpost("/game/join", auth, {cid=cid, uid=uid, gid=gid})
end

function gameinfo(auth, gid)
	return authpost("/game/info", auth, {gid=gid})
end

function gamertpget(auth, gid)
	return authpost("/game/rtp/get", auth, {gid=gid})
end

function slotbetget(auth, gid)
	return authpost("/slot/bet/get", auth, {gid=gid})
end

function slotbetset(auth, gid, bet)
	return authpost("/slot/bet/set", auth, {gid=gid, bet=bet})
end

function slotselget(auth, gid)
	return authpost("/slot/sel/get", auth, {gid=gid})
end

function slotselset(auth, gid, sel)
	return authpost("/slot/sel/set", auth, {gid=gid, sel=sel})
end

function slotspin(auth, gid)
	atom.intinc"spin"
	return authpost("/slot/spin", auth, {gid=gid})
end

function slotdoubleup(auth, gid, mult)
	return authpost("/slot/doubleup", auth, {gid=gid, mult=mult or 2})
end

function slotcollect(auth, gid)
	return authpost("/slot/collect", auth, {gid=gid})
end

function kenobetget(auth, gid)
	return authpost("/keno/bet/get", auth, {gid=gid})
end

function kenobetset(auth, gid, bet)
	return authpost("/keno/bet/set", auth, {gid=gid, bet=bet})
end

function kenoselget(auth, gid)
	return authpost("/keno/sel/get", auth, {gid=gid})
end

function kenoselset(auth, gid, sel)
	return authpost("/keno/sel/set", auth, {gid=gid, sel=sel})
end

function kenoselgetslice(auth, gid)
	return authpost("/keno/sel/getslice", auth, {gid=gid})
end

function kenoselsetslice(auth, gid, idx)
	return authpost("/keno/sel/setslice", auth, {gid=gid, sel=idx})
end

function kenospin(auth, gid)
	atom.intinc"spin"
	return authpost("/keno/spin", auth, {gid=gid})
end

function propget(auth, cid, uid)
	return authpost("/prop/get", auth, {cid=cid, uid=uid})
end

function propwalletget(auth, cid, uid)
	return authpost("/prop/wallet/get", auth, {cid=cid, uid=uid})
end

function propwalletadd(auth, cid, uid, sum)
	atom.intinc"topup"
	atom.numadd("topup", sum)
	return authpost("/prop/wallet/add", auth, {cid=cid, uid=uid, sum=sum})
end

function propaccessget(auth, cid, uid, all)
	return authpost("/prop/al/get", auth, {cid=cid, uid=uid, all=all or false})
end

function propaccessset(auth, cid, uid, al)
	return authpost("/prop/wallet/add", auth, {cid=cid, uid=uid, access=al})
end

function proprtpget(auth, cid, uid, all)
	return authpost("/prop/al/get", auth, {cid=cid, uid=uid, all=all or false})
end

function proprtpset(auth, cid, uid, mrtp)
	return authpost("/prop/wallet/add", auth, {cid=cid, uid=uid, mrtp=mrtp})
end
