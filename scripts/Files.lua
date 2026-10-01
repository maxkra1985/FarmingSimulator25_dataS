Files = {}
local Files_mt = Class(Files)
function Files.new(path)
	local self = setmetatable({}, Files_mt)
	self.path = path
	self.files = {}
	getFiles(path, "fileCallbackFunction", self)
	return self
end
function Files:fileCallbackFunction(filename, isDirectory)
	local file = {}
	file.path = self.path .. "/" .. filename
	file.filename = filename
	file.isDirectory = isDirectory
	table.insert(self.files, file)
end
function Files.getFilesRecursive(path)
	local files = Files.new(path).files
	for i = #files, 1, -1 do
		local file = files[i]
		if file.isDirectory then
			local subFiles = Files.getFilesRecursive(file.path)
			for _, subFile in ipairs(subFiles) do
				table.insert(files, subFile)
			end
		end
	end
	return files
end
