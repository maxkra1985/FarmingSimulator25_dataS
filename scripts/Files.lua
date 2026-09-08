-- Local values: Files_mt
Files = {}
local Files_mt = Class(Files)

-- Upvalues: Files_mt
-- Local values: self
function Files.new(path)
	-- upvalues: (copy) Files_mt
	local v3_ = Files_mt
	local v4_ = setmetatable({}, v3_)
	v4_.path = path
	v4_.files = {}
	getFiles(path, "fileCallbackFunction", v4_)
	return v4_
end

-- Local values: file
function Files:fileCallbackFunction(filename, isDirectory)
	local v8_ = {
		["path"] = self.path .. "/" .. filename,
		["filename"] = filename,
		["isDirectory"] = isDirectory
	}
	local v9_ = self.files
	table.insert(v9_, v8_)
end

-- Local values: files, i, file, subFiles, _, subFile
function Files.getFilesRecursive(path)
	local v11_ = Files.new(path).files
	for v12_ = #v11_, 1, -1 do
		local v13_ = v11_[v12_]
		if v13_.isDirectory then
			local v14_ = Files.getFilesRecursive(v13_.path)
			for _, v15_ in ipairs(v14_) do
				table.insert(v11_, v15_)
			end
		end
	end
	return v11_
end
