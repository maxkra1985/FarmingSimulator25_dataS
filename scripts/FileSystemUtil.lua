FileSystemUtil = {}

-- Local values: items, callbackTarget
function FileSystemUtil.getItems(directoryPath, asAbsPath)
	local v_u_3_ = {}
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local v8_ = {
		["FileSystemUtilystemItemCallback"] = function(_, p4_, p5_)
			-- upvalues: (copy) asAbsPath, (ref) directoryPath, (copy) v_u_3_
			local v6_ = {}
			if asAbsPath then
				p4_ = directoryPath .. p4_ or p4_
			end
			v6_.filename = p4_
			v6_.isDirectory = p5_
			local v7_ = v_u_3_
			table.insert(v7_, v6_)
		end
	}
	getFiles(directoryPath, "FileSystemUtilystemItemCallback", v8_)
	return v_u_3_
end

-- Local values: files, callbackTarget
function FileSystemUtil.getFiles(directoryPath, asAbsPath, pattern, recursive)
	local v_u_13_ = {}
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local v19_ = {
		["FileSystemUtilystemItemCallback"] = function(_, p14_, p15_)
			-- upvalues: (copy) recursive, (ref) directoryPath, (copy) asAbsPath, (copy) pattern, (copy) v_u_13_
			if p15_ then
				if recursive then
					for _, v16_ in ipairs(FileSystemUtil.getFiles(directoryPath .. p14_, asAbsPath, pattern, recursive)) do
						local v17_ = v_u_13_
						table.insert(v17_, v16_)
					end
				end
				return
			elseif pattern == nil or string.match(p14_, pattern) then
				if asAbsPath then
					p14_ = directoryPath .. p14_ or p14_
				end
				local v18_ = v_u_13_
				table.insert(v18_, p14_)
			end
		end
	}
	getFiles(directoryPath, "FileSystemUtilystemItemCallback", v19_)
	return v_u_13_
end

-- Local values: directories, callbackTarget
function FileSystemUtil.getDirectories(directoryPath, asAbsPath, pattern)
	local v_u_23_ = {}
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local v27_ = {
		["FileSystemUtilystemItemCallback"] = function(_, p24_, p25_)
			-- upvalues: (copy) pattern, (copy) asAbsPath, (ref) directoryPath, (copy) v_u_23_
			if p25_ then
				if pattern == nil or string.match(p24_, pattern) then
					if asAbsPath then
						p24_ = directoryPath .. p24_ or p24_
					end
					local v26_ = v_u_23_
					table.insert(v26_, p24_)
				end
			else
				return
			end
		end
	}
	getFiles(directoryPath, "FileSystemUtilystemItemCallback", v27_)
	return v_u_23_
end
