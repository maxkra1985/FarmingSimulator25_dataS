ClassUtil = {}
function ClassUtil.getIsValidClassName(className)
	if className:find("[^%w_.]") ~= nil then
		return false
	else
		return true
	end
end
function ClassUtil.getIsValidIndexName(indexName)
	if type(indexName) ~= "string" then
		printError(string.format("Error: ClassUtil.getIsValidIndexName: string expected, got %s", type(indexName)))
		printCallstack()
	end
	if indexName == nil or indexName == "" or indexName:find("[^%w_.]") then
		return false
	end
	return true
end
function ClassUtil.getClassObject(className)
	local parts = string.split(className, ".")
	local currentTable = _G[parts[1]]
	if type(currentTable) ~= "table" then
		return nil
	else
		for i = 2, #parts do
			currentTable = currentTable[parts[i]]
			if type(currentTable) == "table" then
				continue
			end
			return nil
		end
		return currentTable
	end
end
function ClassUtil.getClassObjectByObject(object)
	local className = ClassUtil.getClassNameByObject(object)
	if className == nil then
		return nil
	else
		return ClassUtil.getClassObject(className)
	end
end
function ClassUtil.getClassName(classObject)
	for k, v in pairs(_G) do
		if v == classObject then
			return k
		end
	end
	for customEnv, _ in pairs(g_modIsLoaded) do
		for k, v in pairs(_G[customEnv]) do
			if v == classObject then
				return customEnv .. "." .. k
			end
		end
	end
	return nil
end
function ClassUtil.getClassNameByObject(object)
	if object ~= nil and object.class ~= nil then
		local classObject = object:class()
		return ClassUtil.getClassName(classObject)
	end
	return nil
end
function ClassUtil.getClassModName(className)
	local parts = string.split(className, ".")
	if 1 < #parts then
		return parts[1]
	else
		return nil
	end
end
function ClassUtil.getFunction(functionName)
	local parts = string.split(functionName, ".")
	local numParts = #parts
	local currentTable = _G[parts[1]]
	if 1 < numParts then
		if type(currentTable) ~= "table" then
			return nil
		end
		for i = 2, numParts do
			currentTable = currentTable[parts[i]]
			if i == numParts or type(currentTable) == "table" then
				continue
			end
			return nil
		end
	end
	if type(currentTable) ~= "function" then
		return nil
	else
		return currentTable
	end
end
