
----- input data begin -----
slotopolhost = "http://localhost:8080"
----- input data final -----

local function printf(...) -- write to log formatted string
	print(string.format(...))
end

-- load API-calls
dofile(scrdir.."/lib/api.lua")

local info, status = servinfo()
if status >= 400 then
	printf("failure to get server info, status: %d, code: %d, message: %s", status, info.code, info.what)
	return
end

printf("server build version: %s", info.buildvers)
printf("server build time: %s", info.buildtime)
printf("server start time: %s", info.started)
printf("golang version: %s", info.govers)
printf("operation system: %s", info.os)
printf("number of available CPU: %d", info.numcpu)
printf("maximum number of CPU: %d", info.maxprocs)
printf("executable path: %s", info.exepath)
printf("configuration path: %s", info.cfgpath)
printf("SQLite-files path: %s", info.sqlpath)
