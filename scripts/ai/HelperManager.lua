HelperManager = {}
g_xmlManager:addCreateSchemaFunction(function()
	HelperManager.xmlSchema = XMLSchema.new("aiHelper")
end)
g_xmlManager:addInitSchemaFunction(function()
	local missionXMLSchema = Mission00.xmlSchema
	missionXMLSchema:register(XMLValueType.STRING, "map.helpers#filename", "Filename of the npcs available on the map")
	local schema = HelperManager.xmlSchema
	schema:register(XMLValueType.STRING, "map.helpers.helper(?)#name", "Name identifier of helper", nil, true)
	schema:register(XMLValueType.L10N_STRING, "map.helpers.helper(?)#title", "Name identifier of helper", nil, false)
	schema:register(XMLValueType.VECTOR_3, "map.helpers.helper(?)#color", "Color of helper", nil, true)
	PlayerStyle.registerSavegameXMLPaths(schema, "map.helpers.helper(?).playerStyle")
end)
local HelperManager_mt = Class(HelperManager, AbstractManager)
function HelperManager.new(customMt)
	local self = AbstractManager.new(customMt or HelperManager_mt)
	return self
end
function HelperManager:initDataStructures()
	self.numHelpers = 0
	self.helpers = {}
	self.nameToIndex = {}
	self.indexToHelper = {}
	self.availableHelpers = {}
end
function HelperManager:loadDefaultTypes(missionInfo, baseDirectory)
	local xmlFile = loadXMLFile("helpers", "data/maps/maps_helpers.xml")
	self:loadHelpers(xmlFile, missionInfo, baseDirectory, true, nil)
	delete(xmlFile)
end
function HelperManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	HelperManager:superClass().loadMapData(self)
	self:loadDefaultTypes()
	return XMLUtil.loadDataFromMapXML(xmlFile, "helpers", baseDirectory, self, self.loadHelpers, missionInfo, baseDirectory, false, missionInfo.customEnvironment)
end
function HelperManager:loadHelpers(xmlFileHandle, missionInfo, baseDirectory, isBaseType, customEnvironment)
	local xmlFile = XMLFile.wrap(xmlFileHandle, HelperManager.xmlSchema)
	if xmlFile == nil then
		return false
	else
		for _, key in xmlFile:iterator("map.helpers.helper") do
			local name = xmlFile:getValue(key .. "#name")
			local title = xmlFile:getValue(key .. "#title", nil, customEnvironment, false)
			local color = xmlFile:getValue(key .. "#color", { 1, 1, 1 })
			local playerStyle = PlayerStyle.new()
			playerStyle:loadFromXMLFile(xmlFile, key .. ".playerStyle")
			self:addHelper(name, title, color, playerStyle, baseDirectory, isBaseType)
		end
		xmlFile:delete()
		return true
	end
end
function HelperManager:addHelper(name, title, color, playerStyle, baseDir, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a helper. Ignoring helper!")
		return nil
	end
	name = string.upper(name)
	if isBaseType and self.nameToIndex[name] ~= nil then
		printWarning("Warning: Helper '" .. tostring(name) .. "' already exists. Ignoring helper!")
		return nil
	end
	local helper = self.helpers[name]
	if helper == nil then
		self.numHelpers = self.numHelpers + 1
		helper = {}
		helper.name = name
		helper.index = self.numHelpers
		helper.color = color
		helper.title = name
		if title ~= nil then
			helper.title = title
		end
		helper.playerStyle = playerStyle
		self.helpers[name] = helper
		self.nameToIndex[name] = self.numHelpers
		self.indexToHelper[self.numHelpers] = helper
		table.insert(self.availableHelpers, helper)
		return helper
	else
		if title ~= nil then
			helper.title = g_i18n:convertText(title)
		end
		if playerStyle ~= nil then
			helper.playerStyle = playerStyle
		end
		return helper
	end
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
	if index ~= nil then
		return self.indexToHelper[index]
	else
		return nil
	end
end
function HelperManager:getHelperByName(name)
	if name ~= nil then
		name = string.upper(name)
		return self.helpers[name]
	else
		return nil
	end
end
function HelperManager:useHelper(helper)
	for k, h in pairs(self.availableHelpers) do
		if h == helper then
			table.remove(self.availableHelpers, k)
			return true
		end
	end
	return false
end
function HelperManager:releaseHelper(helper)
	table.insert(self.availableHelpers, helper)
end
function HelperManager:getNumOfHelpers()
	return self.numHelpers
end
g_helperManager = HelperManager.new()
