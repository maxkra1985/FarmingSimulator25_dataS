FileSystemUtil = {}
function FileSystemUtil.getItems(directoryPath, asAbsPath)
	local items = {}
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local callbackTarget = {}
	function callbackTarget.FileSystemUtilystemItemCallback(_, filename, isDirectory)
		local file = { isDirectory = isDirectory }
		file.filename = asAbsPath and directoryPath .. filename or filename
		table.insert(items, file)
	end
	getFiles(directoryPath, "FileSystemUtilystemItemCallback", callbackTarget)
	return items
end
function FileSystemUtil.getFiles(directoryPath, asAbsPath, pattern, recursive)
	local files = {}
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local callbackTarget = {}
	function callbackTarget.FileSystemUtilystemItemCallback(_, filename, isDirectory)
		if isDirectory then
			if recursive then
				for _, file in ipairs(FileSystemUtil.getFiles(directoryPath .. filename, asAbsPath, pattern, recursive)) do
					table.insert(files, file)
				end
			end
		else
			if pattern ~= nil and not string.match(filename, pattern) then
				return
			end
			local file = asAbsPath and directoryPath .. filename or filename
			table.insert(files, file)
		end
	end
	getFiles(directoryPath, "FileSystemUtilystemItemCallback", callbackTarget)
	return files
end
function FileSystemUtil.getDirectories(directoryPath, asAbsPath, pattern)
	local directories = {}
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local callbackTarget = {}
	function callbackTarget.FileSystemUtilystemItemCallback(_, filename, isDirectory)
		if not isDirectory then
			return
		elseif not (pattern ~= nil and not string.match(filename, pattern)) then
			local directory = asAbsPath and directoryPath .. filename or filename
			table.insert(directories, directory)
		end
	end
	getFiles(directoryPath, "FileSystemUtilystemItemCallback", callbackTarget)
	return directories
end
