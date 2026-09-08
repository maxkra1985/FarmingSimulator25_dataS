-- Local values: HelperManager_mt
HelperManager = {}
g_xmlManager:addCreateSchemaFunction(function()
	HelperManager.xmlSchema = XMLSchema.new("aiHelper")
end)
g_xmlManager:addInitSchemaFunction(function()
	Mission00.xmlSchema:register(XMLValueType.STRING, "map.helpers#filename", "Filename of the npcs available on the map")
	local v1_ = HelperManager.xmlSchema
	v1_:register(XMLValueType.STRING, "map.helpers.helper(?)#name", "Name identifier of helper", nil, true)
	v1_:register(XMLValueType.L10N_STRING, "map.helpers.helper(?)#title", "Name identifier of helper", nil, false)
	v1_:register(XMLValueType.VECTOR_3, "map.helpers.helper(?)#color", "Color of helper", nil, true)
	PlayerStyle.registerSavegameXMLPaths(v1_, "map.helpers.helper(?).playerStyle")
end)
local HelperManager_mt = Class(HelperManager, AbstractManager)

-- Upvalues: HelperManager_mt
-- Local values: self
function HelperManager.new(customMt)
	-- upvalues: (copy) HelperManager_mt
	return AbstractManager.new(customMt or HelperManager_mt)
end

function HelperManager:initDataStructures()
	self.numHelpers = 0
	self.helpers = {}
	self.nameToIndex = {}
	self.indexToHelper = {}
	self.availableHelpers = {}
end

-- Local values: xmlFile
function HelperManager:loadDefaultTypes(missionInfo, baseDirectory)
	local v8_ = loadXMLFile("helpers", "data/maps/maps_helpers.xml")
	self:loadHelpers(v8_, missionInfo, baseDirectory, true, nil)
	delete(v8_)
end

function HelperManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	HelperManager:superClass().loadMapData(self)
	self:loadDefaultTypes()
	return XMLUtil.loadDataFromMapXML(xmlFile, "helpers", baseDirectory, self, self.loadHelpers, missionInfo, baseDirectory, false, missionInfo.customEnvironment)
end

-- Local values: xmlFile, _, key, name, title, color, playerStyle
function HelperManager:loadHelpers(xmlFileHandle, missionInfo, baseDirectory, isBaseType, customEnvironment)
	local v18_ = XMLFile.wrap(xmlFileHandle, HelperManager.xmlSchema)
	if v18_ == nil then
		return false
	end
	for _, v19_ in v18_:iterator("map.helpers.helper") do
		local v20_ = v18_:getValue(v19_ .. "#name")
		local v21_ = v18_:getValue(v19_ .. "#title", nil, customEnvironment, false)
		local v22_ = v18_:getValue(v19_ .. "#color", { 1, 1, 1 })
		local v23_ = PlayerStyle.new()
		v23_:loadFromXMLFile(v18_, v19_ .. ".playerStyle")
		self:addHelper(v20_, v21_, v22_, v23_, baseDirectory, isBaseType)
	end
	v18_:delete()
	return true
end

-- Local values: helper
function HelperManager:addHelper(name, title, color, playerStyle, baseDir, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a helper. Ignoring helper!")
		return nil
	end
	local v30_ = string.upper(name)
	if isBaseType and self.nameToIndex[v30_] ~= nil then
		printWarning("Warning: Helper \'" .. tostring(v30_) .. "\' already exists. Ignoring helper!")
		return nil
	end
	local v31_ = self.helpers[v30_]
	if v31_ ~= nil then
		if title ~= nil then
			v31_.title = g_i18n:convertText(title)
		end
		if playerStyle ~= nil then
			v31_.playerStyle = playerStyle
		end
		return v31_
	end
	self.numHelpers = self.numHelpers + 1
	local v32_ = {
		["name"] = v30_,
		["index"] = self.numHelpers,
		["color"] = color,
		["title"] = v30_
	}
	if title ~= nil then
		v32_.title = title
	end
	v32_.playerStyle = playerStyle
	self.helpers[v30_] = v32_
	self.nameToIndex[v30_] = self.numHelpers
	self.indexToHelper[self.numHelpers] = v32_
	local v33_ = self.availableHelpers
	table.insert(v33_, v32_)
	return v32_
end

function HelperManager:getRandomHelper()
	return self.availableHelpers[math.random(1, #self.availableHelpers)]
end

function HelperManager:getRandomHelperStyle()
	return self.indexToHelper[math.random(1, self.numHelpers)].playerStyle
end

function HelperManager:getRandomIndex()
	return math.random(1, self.numHelpers)
end

function HelperManager:getHelperByIndex(index)
	if index == nil then
		return nil
	else
		return self.indexToHelper[index]
	end
end

function HelperManager:getHelperByName(name)
	if name == nil then
		return nil
	end
	local v41_ = string.upper(name)
	return self.helpers[v41_]
end

-- Local values: k, h
function HelperManager:useHelper(helper)
	for v44_, v45_ in pairs(self.availableHelpers) do
		if v45_ == helper then
			table.remove(self.availableHelpers, v44_)
			return true
		end
	end
	return false
end

function HelperManager:releaseHelper(helper)
	local v48_ = self.availableHelpers
	table.insert(v48_, helper)
end

function HelperManager:getNumOfHelpers()
	return self.numHelpers
end
g_helperManager = HelperManager.new()
