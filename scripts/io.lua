-- Local values: io_mt
io = {}
local io_mt = Class(io)

-- Upvalues: io_mt
-- Local values: fileId, self
function io.open(filename, options)
	-- upvalues: (copy) io_mt
	if options ~= "w" then
		printWarning("Warning: io.open, only write mode (\'w\') is allowed")
	end
	local v4_ = createFile(filename, FileAccess.WRITE)
	if v4_ == 0 then
		return nil
	end
	local v5_ = io_mt
	local v6_ = setmetatable({}, v5_)
	v6_.fileId = v4_
	return v6_
end

function io:close()
	delete(self.fileId)
	self.fileId = 0
end
function io.write(p8_, ...)
	for v9_ = 1, select("#", ...) do
		local v10_ = fileWrite
		local v11_ = p8_.fileId
		local v12_ = select
		v10_(v11_, (tostring(v12_(v9_, ...))))
	end
end

function io:flush() end
