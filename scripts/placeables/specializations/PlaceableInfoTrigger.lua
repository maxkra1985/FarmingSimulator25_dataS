PlaceableInfoTrigger = {}

function PlaceableInfoTrigger.prerequisitesPresent(specializations)
	return true
end

function PlaceableInfoTrigger.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onInfoTriggerEnter")
	SpecializationUtil.registerEvent(placeableType, "onInfoTriggerLeave")
end

function PlaceableInfoTrigger.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableInfoTrigger)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableInfoTrigger)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableInfoTrigger)
	SpecializationUtil.registerEventListener(placeableType, "onDraw", PlaceableInfoTrigger)
end

function PlaceableInfoTrigger.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateInfo", PlaceableInfoTrigger.updateInfo)
	SpecializationUtil.registerFunction(placeableType, "onInfoTriggerCallback", PlaceableInfoTrigger.onInfoTriggerCallback)
end

function PlaceableInfoTrigger.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("InfoTrigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".infoTrigger#triggerNode", "Info trigger", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. ".infoTrigger#showAllPlayers", "Show info to all players", false, false)
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableInfoTrigger:onLoad(savegame)
	local v7_ = self.spec_infoTrigger
	v7_.info = {}
	v7_.showInfo = false
	v7_.showAllPlayers = self.xmlFile:getValue("placeable.infoTrigger#showAllPlayers", false)
	v7_.infoTriggerNode = self.xmlFile:getValue("placeable.infoTrigger#triggerNode", nil, self.components, self.i3dMappings)
	if v7_.infoTriggerNode ~= nil and not CollisionFlag.getHasMaskFlagSet(v7_.infoTriggerNode, CollisionFlag.PLAYER) then
		Logging.xmlWarning(self.xmlFile, "Info trigger collision mask is missing bit \'TRIGGER_PLAYER\' (%d)", CollisionFlag.getBit(CollisionFlag.PLAYER))
	end
	if Platform.playerInfo.showPlaceableInfo then
		v7_.hudBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBox)
	end
end

-- Local values: spec
function PlaceableInfoTrigger:onDelete()
	local v9_ = self.spec_infoTrigger
	if v9_.infoTriggerNode ~= nil then
		removeTrigger(v9_.infoTriggerNode)
		v9_.infoTriggerNode = nil
	end
	v9_.showInfo = false
	g_currentMission:removeDrawable(self)
	if v9_.hudBox ~= nil and g_currentMission.hud ~= nil then
		g_currentMission.hud.infoDisplay:destroyBox(v9_.hudBox)
	end
end

-- Local values: spec
function PlaceableInfoTrigger:onFinalizePlacement()
	local v11_ = self.spec_infoTrigger
	if v11_.infoTriggerNode ~= nil then
		addTrigger(v11_.infoTriggerNode, "onInfoTriggerCallback", self)
	end
end

-- Local values: spec, box, i, element
function PlaceableInfoTrigger:onDraw()
	local v13_ = self.spec_infoTrigger
	if v13_.showInfo and (v13_.showAllPlayers or self:getOwnerFarmId() == g_currentMission:getFarmId()) then
		self:updateInfo(v13_.info)
		if #v13_.info > 0 then
			local v14_ = v13_.hudBox
			if v14_ ~= nil then
				v14_:clear()
				v14_:setTitle(self:getName())
				for v15_ = 1, #v13_.info do
					local v16_ = v13_.info[v15_]
					v14_:addLine(v16_.title, v16_.text, v16_.accentuate)
					v13_.info[v15_] = nil
				end
				v14_:showNextFrame()
			end
		end
	end
end

-- Local values: spec
function PlaceableInfoTrigger:onInfoTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v20_ = self.spec_infoTrigger
	if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
		if onEnter then
			v20_.showInfo = true
			g_currentMission:addDrawable(self)
			SpecializationUtil.raiseEvent(self, "onInfoTriggerEnter", otherId)
			return
		end
		v20_.showInfo = false
		g_currentMission:removeDrawable(self)
		SpecializationUtil.raiseEvent(self, "onInfoTriggerLeave", otherId)
	end
end

function PlaceableInfoTrigger:updateInfo(info) end
