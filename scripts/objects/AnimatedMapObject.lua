AnimatedMapObject = {}
local AnimatedMapObject_mt = Class(AnimatedMapObject, AnimatedObject)
InitStaticObjectClass(AnimatedMapObject, "AnimatedMapObject")
g_xmlManager:addCreateSchemaFunction(function()
	AnimatedMapObject.xmlSchema = XMLSchema.new("animatedObjects")
end)
g_xmlManager:addInitSchemaFunction(function()
	AnimatedObject.registerXMLPaths(AnimatedMapObject.xmlSchema, "animatedObjects")
	AnimatedObject.registerSavegameXMLPaths(OnCreateObjectSystem.xmlSchemaSavegame, "onCreateLoadedObjects.object(?)")
end)
function AnimatedMapObject:onCreate(id)
	local object = AnimatedMapObject.new(g_server ~= nil, g_client ~= nil)
	if object:load(id) then
		g_currentMission.onCreateObjectSystem:add(object, true)
		object:register(true)
	else
		object:delete()
	end
end
function AnimatedMapObject.new(isServer, isClient, customMt)
	return AnimatedObject.new(isServer, isClient, customMt or AnimatedMapObject_mt)
end
function AnimatedMapObject:delete()
	g_currentMission.onCreateObjectSystem:remove(self)
	AnimatedMapObject:superClass().delete(self)
end
function AnimatedMapObject:load(nodeId)
	local xmlFilename = getUserAttribute(nodeId, "xmlFilename")
	if xmlFilename == nil then
		Logging.error("Missing 'xmlFilename' user attribute for AnimatedMapObject node '%s'!", getName(nodeId))
		return false
	end
	local baseDir = g_currentMission.loadingMapBaseDirectory
	if baseDir == "" then
		baseDir = Utils.getNoNil(self.baseDirectory, baseDir)
	end
	xmlFilename = Utils.getFilename(xmlFilename, baseDir)
	local saveId = getUserAttribute(nodeId, "saveId") or getUserAttribute(nodeId, "index")
	if saveId == nil then
		Logging.error("Missing 'saveId' user attribute for AnimatedMapObject node '%s'!", getName(nodeId))
		return false
	end
	local xmlFile = XMLFile.load("AnimatedObject", xmlFilename, AnimatedMapObject.xmlSchema)
	if xmlFile == nil then
		return false
	end
	local key = nil
	xmlFile:iterate("animatedObjects.animatedObject", function(_, objectKey)
		local configSaveId = xmlFile:getString(objectKey .. "#saveId") or xmlFile:getString(objectKey .. "#index")
		if configSaveId == saveId then
			key = objectKey
			return true
		else
			return
		end
	end)
	if key == nil then
		Logging.error("saveId '%s' not found in AnimatedObject xml '%s'!", saveId, xmlFilename)
		return false
	else
		local result = AnimatedMapObject:superClass().load(self, nodeId, xmlFile, key, xmlFilename)
		xmlFile:delete()
		return result
	end
end
