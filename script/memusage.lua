
----- input data begin -----
slotopolhost = "http://localhost:8080"
----- input data final -----

local function printf(...) -- write to log formatted string
	print(string.format(...))
end

-- load API-calls
dofile(scrdir.."/lib/api.lua")

local mem, status = memusage()
if status >= 400 then
	printf("failure to get memory info, status: %d, code: %d, message: %s", status, mem.code, mem.what)
	return
end

printf("running tume: %s", mem.running)
printf("bytes of allocated heap objects: %d", mem.heapalloc)
printf("bytes of heap memory obtained from the OS: %d", mem.heapsys)
printf("total bytes allocated, even if freed: %d", mem.totalalloc)
printf("target heap size of the next GC cycle: %d", mem.nextgc)
printf("number of garbage collection cycles: %d", mem.numgc)
printf("cumulative nanoseconds in GC stop-the-world pauses: %d", mem.pausetotalns)
printf("fraction of this program's available CPU time used by the GC: %.6g", mem.gccpufraction)
