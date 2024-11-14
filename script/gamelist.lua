
----- input data begin -----
slotopolhost = "http://localhost:8080"
----- input data final -----

local function printf(...) -- write to log formatted string
	print(string.format(...))
end

-- load API-calls
dofile(scrdir.."/lib/api.lua")

local gl, status = gamelist()
if status >= 400 then
	printf("failure to get games list, status: %d, code: %d, message: %s", status, gl.code, gl.what)
	return
end

local list, num, prov, alg = {}, 0, {}, 0
for _, gi in ipairs(gl) do
	alg = alg + 1
	for _, ga in ipairs(gi.aliases) do
		prov[ga.prov] = (prov[ga.prov] or 0) + 1
		num = num + 1
		if gi.ln and gi.ln > 100 then
			list[num] = string.format("'%s' %s %dx%d videoslot, %d ways", ga.name, gi.provider, gi.sx, gi.sy, gi.ln)
		elseif gi.sy and gi.sy > 0 then
			list[num] = string.format("'%s' %s %dx%d videoslot, %d lines", ga.name, gi.provider, gi.sx, gi.sy, gi.ln)
		else
			list[num] = string.format("'%s' %s %d spots lottery", ga.name, gi.provider, gi.sx)
		end
	end
end
table.sort(list)

print ""
for _, s in ipairs(list) do
	print(s)
end

list = {}
local pn = 0
for p, n in pairs(prov) do
	pn = pn + 1
	list[pn] = string.format("%s: %d games", p, n)
end
table.sort(list)

print ""
printf("total: %d games, %d algorithms, %d providers", num, alg, pn)
for _, s in ipairs(list) do
	print(s)
end
