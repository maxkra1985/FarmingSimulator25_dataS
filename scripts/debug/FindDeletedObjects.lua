FindDeletedObjects = {}
FindDeletedObjects.UPDATE_INTERVAL = 1800000
FindDeletedObjects.NEXT_UPDATE_TIME = 600000
FindDeletedObjects.AUTOMATED_CHECK_ENABLED = StartParams.getIsSet("findDeletedObjectsAutoCheck")
FindDeletedObjects.DEBUG_KEY = "deletedObject_isDeleted"
FindDeletedObjects.DEBUG_TRACE_KEY = "deletedObject_trace"
function FindDeletedObjects.init() end
function FindDeletedObjects.run() end

function FindDeletedObjects.update(object) end

function FindDeletedObjects.add(object) end

-- Local values: name, specificName, realPath, itemDepth, item, pathItems, k, item, currentClassName, currentClass, completePath, checks, k, v, k, v
function FindDeletedObjects.find(parent, key, value, path, checked, depth)
	FindDeletedObjects.numCheckedValues = FindDeletedObjects.numCheckedValues + 1
	if value == FindDeletedObjects then
		return 1
	end
	if checked[value] ~= nil then
		return 1
	end
	if type(value) ~= "table" then
		return 1
	end
	if value[FindDeletedObjects.DEBUG_KEY] ~= true then
		if value ~= nil and not MathUtil.isNan(value) then
			checked[value] = true
		end
		path[depth] = {
			["parent"] = parent,
			["key"] = key,
			["value"] = value
		}
		local v7_ = 1
		for v8_, v9_ in pairs(value) do
			v7_ = v7_ + FindDeletedObjects.find(value, v8_, v9_, path, checked, depth + 1)
		end
		for v10_, v11_ in pairs(value) do
			v7_ = v7_ + FindDeletedObjects.find(value, v11_, v10_, path, checked, depth + 1)
		end
		path[depth] = nil
		return v7_
	end
	local v12_ = value.__CLASSNAME or ""
	local v13_ = value.configFileNameClean or (value.getName == nil and "" or (value:getName() or ""))
	if v13_ ~= "" then
		v12_ = v12_ .. " - " .. v13_
	end
	local v14_ = {}
	for v15_, v16_ in ipairs(path) do
		if v16_.key ~= nil and v15_ <= depth then
			local v17_ = {
				["depth"] = v15_,
				["parent"] = v16_.parent,
				["key"] = v16_.key,
				["value"] = v16_.value
			}
			table.insert(v14_, v17_)
		end
	end
	table.sort(v14_, function(p18_, p19_)
		return p18_.depth < p19_.depth
	end)
	local v20_ = {}
	for _, v21_ in ipairs(v14_) do
		local v22_ = v21_.value
		local v23_
		if type(v22_) == "table" then
			local v24_ = ClassUtil.getClassNameByObject(v21_.parent)
			v23_ = v24_ and tostring(v24_) .. "." or ""
		else
			v23_ = ""
		end
		local v25_ = v21_.key
		local v26_ = v23_ .. tostring(v25_)
		table.insert(v20_, v26_)
	end
	local v27_ = tostring(key)
	table.insert(v20_, v27_)
	local v28_ = table.concat(v20_, " | ")
	Logging.warning("(" .. tostring(value) .. ") " .. tostring(v12_))
	Logging.warning("   " .. v28_)
	if value.__CREATION ~= nil then
		Logging.warning("   Creation Trace:\n" .. value.__CREATION)
	end
	print("")
	FindDeletedObjects.numFoundIssues = FindDeletedObjects.numFoundIssues + 1
	return 1
end
