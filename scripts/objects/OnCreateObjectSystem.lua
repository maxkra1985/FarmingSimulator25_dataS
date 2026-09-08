-- Local values: OnCreateObjectSystem_mt
OnCreateObjectSystem = {}
local OnCreateObjectSystem_mt = Class(OnCreateObjectSystem)
g_xmlManager:addCreateSchemaFunction(function()
	OnCreateObjectSystem.xmlSchemaSavegame = XMLSchema.new("onCreateObjects")
end)
g_xmlManager:addInitSchemaFunction(function()
	OnCreateObjectSystem.xmlSchemaSavegame:register(XMLValueType.STRING, "onCreateLoadedObjects.object(?)#saveId", "SaveID of the object")
end)

-- Upvalues: OnCreateObjectSystem_mt
-- Local values: self
function OnCreateObjectSystem.new(mission, customMt)
	-- upvalues: (copy) OnCreateObjectSystem_mt
	local v4_ = customMt or OnCreateObjectSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.objects = {}
	v5_.objectsToSave = {}
	return v5_
end

function OnCreateObjectSystem:delete() end

-- Local values: xmlFile
function OnCreateObjectSystem:save(xmlFilename, usedModNames)
	local v_u_9_ = XMLFile.create("onCreateObjectsXMLFile", xmlFilename, "onCreateLoadedObjects", OnCreateObjectSystem.xmlSchemaSavegame)
	v_u_9_:setTable("onCreateLoadedObjects.object", self.objectsToSave, function(p10_, p11_, p12_)
		-- upvalues: (copy) v_u_9_, (copy) usedModNames
		v_u_9_:setValue(p10_ .. "#saveId", p12_)
		p11_:saveToXMLFile(v_u_9_, p10_, usedModNames)
	end)
	v_u_9_:save()
	v_u_9_:delete()
end

-- Local values: xmlFile, i, key, saveId, object
function OnCreateObjectSystem:load(xmlFilename)
	local v15_ = XMLFile.load("onCreateLoadedObjectsXML", xmlFilename, OnCreateObjectSystem.xmlSchemaSavegame)
	for v16_, v17_ in v15_:iterator("onCreateLoadedObjects.object") do
		local v18_ = v15_:getValue(v17_ .. "#saveId")
		if v18_ ~= nil then
			local v19_ = self.objectsToSave[v18_]
			if v19_ == nil then
				Logging.error("Corrupt savegame, onCreateLoadedObject %d has invalid saveId \'%s\'", v16_, v18_)
			elseif v19_.loadFromXMLFile == nil or not v19_:loadFromXMLFile(v15_, v17_) then
				Logging.warning("Corrupt savegame, onCreateLoadedObject %d with saveId %s could not be loaded", v16_, v18_)
			end
		end
	end
	v15_:delete()
end

-- Local values: prevObject
function OnCreateObjectSystem:add(object, saved)
	if self.mission.isLoaded then
		Logging.error("OnCreateObjectSystem:add(): only allowed to add objects while loading maps")
		printCallstack()
		return
	elseif self.mission.userManager:getNumberOfUsers() > 1 then
		Logging.error("OnCreateObjectSystem:add() is only allowed during map loading when no client is connected")
		printCallstack()
	else
		if saved then
			if object.saveToXMLFile == nil then
				Logging.error("Adding onCreate loaded object so save which does not have a saveToXMLFile function")
				return
			end
			if object.saveId == nil then
				Logging.error("Adding onCreate loaded object with invalid saveId")
				return
			end
			local v23_ = self.objectsToSave[object.saveId]
			if v23_ == object then
				return
			end
			if v23_ ~= nil then
				Logging.error("Adding onCreate loaded object with duplicate saveId %s", object.saveId)
				return
			end
			self.objectsToSave[object.saveId] = object
		end
		local v24_ = self.objects
		table.insert(v24_, object)
	end
end

-- Local values: prevObject
function OnCreateObjectSystem:remove(object)
	table.removeElement(self.objects, object)
	if object.saveId ~= nil and self.objectsToSave[object.saveId] == object then
		self.objectsToSave[object.saveId] = nil
	end
end

function OnCreateObjectSystem:getNumObjects()
	return #self.objects
end

function OnCreateObjectSystem:get(index)
	return self.objects[index]
end
