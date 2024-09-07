
-- define some functions for bot workflow
local function fmt(...) -- write to log formatted string
	print(string.format(...))
end

slotopolhost = "http://localhost:8080"

-- load API-calls
dofile(scrdir.."/lib/api.lua")

local gl, status = gamelist()
if status >= 400 then
	fmt("failure to get games list, status: %d, code: %d, message: %s", status, gl.code, gl.what)
	return
end

local list, prov, num, alg = {}, {}, 0, 0
for _, gi in ipairs(gl) do
	prov[gi.provider] = (prov[gi.provider] or 0) + #gi.aliases
	alg = alg + 1
	for _, ga in ipairs(gi.aliases) do
		num = num + 1
		list[num] = string.format("'%s' %s %dx%d videoslot", ga.name, gi.provider, gi.scrnx, gi.scrny)
	end
end
table.sort(list)

print ""
for _, s in ipairs(list) do
	print(s)
end

local pn = 0
for _, _ in pairs(prov) do
	pn = pn + 1
end

print ""
fmt("total: %d games, %d algorithms, %d providers", num, alg, pn)
for p, n in pairs(prov) do
	fmt("%s: %d games", p, n)
end
