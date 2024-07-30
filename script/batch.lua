
-- define some functions for bot workflow
local function fmt(...) -- write to log formatted string
	print(string.format(...))
end

fmt("bot version: %s, builton: %s", buildvers, buildtime)
fmt("binary dir: %s", bindir)
fmt("script dir: %s", scrdir)
fmt("temporary dir: %s", tmpdir)

local exit = channel.make()
local users = dofile(scrdir.."/userlist.lua")
local usrnum = 10
local options = {
	lt = {
		warn = true,
		info = true,
		sign = true,
		cash = true,
		gset = false,
		spin = false,
		spec = false,
	},
	addr = "http://localhost:8080",
	cid = 1,
	jobtime = 15*60, -- 2m
	speed = 1,
}

for i = 1, usrnum do
	thread(
		users[i], options, exit,
		scrdir.."/api.lua", scrdir.."/play.lua"
	)
end

for _ = 1, usrnum do
	local ok, err = exit:receive()
	if not ok then
		fmt("unexpected channel closure")
		return
	end
	if err then
		fmt(err)
		exit:close()
		return
	end
end

fmt("all threads complete.")
exit:close()
