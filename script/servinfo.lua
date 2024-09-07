
-- define some functions for bot workflow
local function fmt(...) -- write to log formatted string
	print(string.format(...))
end

slotopolhost = "http://localhost:8080"

-- load API-calls
dofile(scrdir.."/lib/api.lua")

local info, status = servinfo()
if status >= 400 then
	fmt("failure to get server info, status: %d, code: %d, message: %s", status, info.code, info.what)
	return
end

fmt("server build version: %s", info.buildvers)
fmt("server build time: %s", info.buildtime)
fmt("server start time: %s", info.started)
fmt("golang version: %s", info.govers)
fmt("operation system: %s", info.os)
fmt("number of available CPU: %d", info.numcpu)
fmt("maximum number of CPU: %d", info.maxprocs)
fmt("executable path: %s", info.exepath)
fmt("configuration path: %s", info.cfgpath)
fmt("SQLite-files path: %s", info.sqlpath)
