PlaceableWardrobe = {}
source("dataS/scripts/placeables/specializations/activatables/WardrobeActivatable.lua")

function PlaceableWardrobe.prerequisitesPresent(specializations)
	return true
end

function PlaceableWardrobe.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "wardrobeTriggerCallback", PlaceableWardrobe.wardrobeTriggerCallback)
end

function PlaceableWardrobe.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWardrobe)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWardrobe)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWardrobe)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWardrobe)
end

function PlaceableWardrobe.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Wardrobe")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wardrobe#triggerNode", "Wardrobe trigger node for player")
	schema:register(XMLValueType.BOOL, basePath .. ".wardrobe#isFreeForAll", "Allow any farm not just the owner to access the wardrobe", "false if owned by a specific farm, true otherwise")
	schema:setXMLSpecializationType()
end

function PlaceableWardrobe.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Wardrobe")
	schema:register(XMLValueType.BOOL, basePath .. "#isFreeForAll", "Allow any farm not just the owner to access the wardrobe")
	schema:setXMLSpecializationType()
end

-- Local values: spec, wardrobeTriggerKey
function PlaceableWardrobe:onLoad(savegame)
	local v8_ = self.spec_wardrobe
	v8_.activatable = WardrobeActivatable.new(self)
	v8_.wardrobeTrigger = self.xmlFile:getValue("placeable.wardrobe#triggerNode", nil, self.components, self.i3dMappings)
	if v8_.wardrobeTrigger ~= nil then
		if not CollisionFlag.getHasMaskFlagSet(v8_.wardrobeTrigger, CollisionFlag.PLAYER) then
			Logging.warning("%s wardrobe trigger \'%s\' does not have \'TRIGGER_PLAYER\' bit (%s) set", self.configFileName, "placeable.wardrobe#triggerNode", CollisionFlag.getBit(CollisionFlag.PLAYER))
		end
		addTrigger(v8_.wardrobeTrigger, "wardrobeTriggerCallback", self)
	end
	v8_.isFreeForAll = self.xmlFile:getValue("placeable.wardrobe#isFreeForAll", false)
end

-- Local values: spec, isFreeForAll
function PlaceableWardrobe:loadFromXMLFile(xmlFile, key)
	local v12_ = self.spec_wardrobe
	local v13_ = xmlFile:getValue(key .. "#isFreeForAll")
	if v13_ ~= nil then
		v12_.isFreeForAll = v13_
	end
end

function PlaceableWardrobe:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#isFreeForAll", self.spec_wardrobe.isFreeForAll)
end

-- Local values: spec
function PlaceableWardrobe:onDelete()
	local v18_ = self.spec_wardrobe
	g_currentMission.activatableObjectsSystem:removeActivatable(v18_.activatable)
	if v18_.wardrobeTrigger ~= nil then
		removeTrigger(v18_.wardrobeTrigger)
	end
end

-- Local values: spec
function PlaceableWardrobe:onReadStream(streamId, connection)
	self.spec_wardrobe.isFreeForAll = streamReadBool(streamId)
end

-- Local values: spec
function PlaceableWardrobe:onWriteStream(streamId, connection)
	local v23_ = self.spec_wardrobe
	streamWriteBool(streamId, v23_.isFreeForAll)
end

-- Local values: spec
function PlaceableWardrobe:wardrobeTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		local v28_ = self.spec_wardrobe
		if v28_.isFreeForAll or self:getOwnerFarmId() == g_localPlayer.farmId then
			if onEnter then
				g_currentMission.activatableObjectsSystem:addActivatable(v28_.activatable)
				return
			end
			g_currentMission.activatableObjectsSystem:removeActivatable(v28_.activatable)
		end
	end
end
