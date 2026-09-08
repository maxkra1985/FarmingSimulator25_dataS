ClassUtil = {}

function ClassUtil.getIsValidClassName(className)
	return className:find("[^%w_.]") == nil
end

function ClassUtil.getIsValidIndexName(indexName)
	if type(indexName) ~= "string" then
		printError(string.format("Error: ClassUtil.getIsValidIndexName: string expected, got %s", (type(indexName))))
		printCallstack()
	end
	return indexName ~= nil and (indexName ~= "" and not indexName:find("[^%w_.]")) and true or false
end

-- Local values: parts, currentTable, i
function ClassUtil.getClassObject(className)
	local v4_ = string.split(className, ".")
	local v5_ = _G[v4_[1]]
	if type(v5_) ~= "table" then
		return nil
	end
	for v6_ = 2, #v4_ do
		v5_ = v5_[v4_[v6_]]
		if type(v5_) ~= "table" then
			return nil
		end
	end
	return v5_
end

-- Local values: className
function ClassUtil.getClassObjectByObject(object)
	local v8_ = ClassUtil.getClassNameByObject(object)
	if v8_ == nil then
		return nil
	else
		return ClassUtil.getClassObject(v8_)
	end
end

-- Local values: k, v, customEnv, _, k, v
function ClassUtil.getClassName(classObject)
	for v10_, v11_ in pairs(_G) do
		if v11_ == classObject then
			return v10_
		end
	end
	for v12_, _ in pairs(g_modIsLoaded) do
		for v13_, v14_ in pairs(_G[v12_]) do
			if v14_ == classObject then
				return v12_ .. "." .. v13_
			end
		end
	end
	return nil
end

-- Local values: classObject
function ClassUtil.getClassNameByObject(object)
	if object == nil or object.class == nil then
		return nil
	end
	local v16_ = object:class()
	return ClassUtil.getClassName(v16_)
end

-- Local values: parts
function ClassUtil.getClassModName(className)
	local v18_ = string.split(className, ".")
	if #v18_ > 1 then
		return v18_[1]
	else
		return nil
	end
end

-- Local values: parts, numParts, currentTable, i
function ClassUtil.getFunction(functionName)
	local v20_ = string.split(functionName, ".")
	local v21_ = #v20_
	local v22_ = _G[v20_[1]]
	if v21_ > 1 then
		if type(v22_) ~= "table" then
			return nil
		end
		for v23_ = 2, v21_ do
			v22_ = v22_[v20_[v23_]]
			if v23_ ~= v21_ and type(v22_) ~= "table" then
				return nil
			end
		end
	end
	if type(v22_) == "function" then
		return v22_
	else
		return nil
	end
end
