FindDeletedObjects = {}
FindDeletedObjects.UPDATE_INTERVAL = 1800000
FindDeletedObjects.NEXT_UPDATE_TIME = 600000
FindDeletedObjects.AUTOMATED_CHECK_ENABLED = StartParams.getIsSet("findDeletedObjectsAutoCheck")
FindDeletedObjects.DEBUG_KEY = "deletedObject_isDeleted"
FindDeletedObjects.DEBUG_TRACE_KEY = "deletedObject_trace"
function FindDeletedObjects.init() end
function FindDeletedObjects.run() end
function FindDeletedObjects.update(dt) end
function FindDeletedObjects.add(object) end
function FindDeletedObjects.find(parent, key, value, path, checked, depth)
	FindDeletedObjects.numCheckedValues = FindDeletedObjects.numCheckedValues + 1
	if value == FindDeletedObjects then
		return 1
	elseif checked[value] ~= nil then
		return 1
	elseif type(value) ~= "table" then
		return 1
	elseif value[FindDeletedObjects.DEBUG_KEY] == true then
		local name = value.__CLASSNAME or ""
		if not value.configFileNameClean then
			local specificName = value.getName ~= nil and value:getName() or ""
		end
		if specificName ~= "" then
			name = name .. " - " .. specificName
		end
		local realPath = {}
		for itemDepth, item in ipairs(path) do
			if item.key == nil then
				continue
			end
			if itemDepth <= depth then
				table.insert(realPath, { depth = itemDepth, parent = item.parent, key = item.key, value = item.value })
			end
		end
		table.sort(realPath, function(a, b)
			return a.depth < b.depth
		end)
		local pathItems = {}
		for k, item in ipairs(realPath) do
			local currentClassName = ""
			if type(item.value) == "table" then
				currentClassName = ClassUtil.getClassNameByObject(item.parent) and tostring(currentClass) .. "." or ""
			end
			table.insert(pathItems, currentClassName .. tostring(item.key))
		end
		table.insert(pathItems, tostring(key))
		local completePath = table.concat(pathItems, " | ")
		Logging.warning("(" .. tostring(value) .. ") " .. tostring(name))
		Logging.warning("   " .. completePath)
		if value.__CREATION ~= nil then
			Logging.warning("   Creation Trace:\n" .. value.__CREATION)
		end
		print("")
		FindDeletedObjects.numFoundIssues = FindDeletedObjects.numFoundIssues + 1
		return 1
	else
		if value ~= nil and not MathUtil.isNan(value) then
			checked[value] = true
		end
		path[depth] = { parent = parent, key = key, value = value }
		local checks = 1
		for k, v in pairs(value) do
			checks = checks + FindDeletedObjects.find(value, k, v, path, checked, depth + 1)
		end
		for k, v in pairs(value) do
			checks = checks + FindDeletedObjects.find(value, v, k, path, checked, depth + 1)
		end
		path[depth] = nil
		return checks
	end
end
