io = {}
local io_mt = Class(io)
function io.open(filename, options)
	if options ~= "w" then
		printWarning("Warning: io.open, only write mode ('w') is allowed")
	end
	local fileId = createFile(filename, FileAccess.WRITE)
	if fileId ~= 0 then
		local self = setmetatable({}, io_mt)
		self.fileId = fileId
		return self
	else
		return nil
	end
end
function io:close()
	delete(self.fileId)
	self.fileId = 0
end
function io:write(...)
	for i = 1, select("#", ...) do
		fileWrite(self.fileId, tostring(select(i, ...)))
	end
end
function io:flush() end
