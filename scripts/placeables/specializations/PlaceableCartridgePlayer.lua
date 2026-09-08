-- Local values: PlaceableCartridgePlayerActivatable_mt
PlaceableCartridgePlayer = {}

function PlaceableCartridgePlayer.prerequisitesPresent(specializations)
	return true
end

function PlaceableCartridgePlayer.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "cartridgePlayerTriggerCallback", PlaceableCartridgePlayer.cartridgePlayerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "activatePlayer", PlaceableCartridgePlayer.activatePlayer)
end

function PlaceableCartridgePlayer.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableCartridgePlayer)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableCartridgePlayer)
end

function PlaceableCartridgePlayer.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("CartridgePlayer")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#itemsNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#monitorNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#monitorLightNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#connectorNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#triggerNode", "")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".cartridgePlayer.sounds", "play")
	schema:setXMLSpecializationType()
end

-- Local values: spec, baseKey
function PlaceableCartridgePlayer:onLoad(savegame)
	local v6_ = self.spec_cartridgePlayer
	v6_.itemsNode = self.xmlFile:getValue("placeable.cartridgePlayer#itemsNode", nil, self.components, self.i3dMappings)
	v6_.monitorNode = self.xmlFile:getValue("placeable.cartridgePlayer#monitorNode", nil, self.components, self.i3dMappings)
	v6_.monitorLightNode = self.xmlFile:getValue("placeable.cartridgePlayer#monitorLightNode", nil, self.components, self.i3dMappings)
	v6_.connectorNode = self.xmlFile:getValue("placeable.cartridgePlayer#connectorNode", nil, self.components, self.i3dMappings)
	v6_.triggerNode = self.xmlFile:getValue("placeable.cartridgePlayer#triggerNode", nil, self.components, self.i3dMappings)
	if v6_.triggerNode ~= nil then
		if not CollisionFlag.getHasMaskFlagSet(v6_.triggerNode, CollisionFlag.PLAYER) then
			Logging.error("Missing collision mask bit \'%d\'. Please add this bit to computer trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(v6_.triggerNode))
			return nil
		end
		addTrigger(v6_.triggerNode, "cartridgePlayerTriggerCallback", self)
		v6_.activatable = PlaceableCartridgePlayerActivatable.new(self)
	end
	v6_.currentItem = 0
	if self.isClient then
		v6_.samples = {}
		v6_.samples.play = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.cartridgePlayer.sounds", "play", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
	end
	return self
end

-- Local values: spec
function PlaceableCartridgePlayer:onDelete()
	local v8_ = self.spec_cartridgePlayer
	g_currentMission.activatableObjectsSystem:removeActivatable(v8_.activatable)
	if v8_.triggerNode ~= nil then
		removeTrigger(v8_.triggerNode)
	end
	if self.isClient then
		g_soundManager:deleteSamples(v8_.samples)
	end
end

-- Local values: spec
function PlaceableCartridgePlayer:cartridgePlayerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		local v13_ = self.spec_cartridgePlayer
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(v13_.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(v13_.activatable)
	end
end

-- Local values: spec, firstVisibleIndex, nextVisibleIndex, i, isVisible, currentVisible
function PlaceableCartridgePlayer:activatePlayer()
	local v15_ = self.spec_cartridgePlayer
	if v15_.currentItem ~= 0 then
		link(getChildAt(v15_.itemsNode, v15_.currentItem - 1), getChildAt(v15_.connectorNode, 0))
		setVisibility(v15_.monitorLightNode, false)
		setVisibility(getChildAt(v15_.monitorNode, v15_.currentItem - 1), false)
	end
	local v16_ = 0
	local v17_ = 0
	for v18_ = 1, getNumOfChildren(v15_.itemsNode) do
		if getVisibility(getChildAt(v15_.itemsNode, v18_ - 1)) then
			if v16_ == 0 then
				v16_ = v18_
			end
			if v17_ == 0 and v15_.currentItem < v18_ then
				v17_ = v18_
			end
		end
	end
	local v19_ = v15_.currentItem
	if v17_ == 0 then
		if v16_ == 0 then
			if v15_.currentItem == 0 then
				g_currentMission.hud:showInGameMessage(g_i18n:getText("ui_gameComputer"), g_i18n:getText("ui_gameComputerNoCartridges"), -1)
			else
				v15_.currentItem = 0
			end
		else
			v15_.currentItem = v16_
		end
	else
		v15_.currentItem = v17_
	end
	if v15_.currentItem ~= 0 then
		link(v15_.connectorNode, getChildAt(getChildAt(v15_.itemsNode, v15_.currentItem - 1), 0))
		setVisibility(v15_.monitorLightNode, true)
		setVisibility(getChildAt(v15_.monitorNode, v15_.currentItem - 1), true)
	end
	if v19_ ~= v15_.currentItem and self.isClient then
		g_soundManager:playSample(v15_.samples.play, 1)
	end
end
PlaceableCartridgePlayerActivatable = {}
local v_u_20_ = Class(PlaceableCartridgePlayerActivatable)

-- Upvalues: PlaceableCartridgePlayerActivatable_mt
-- Local values: self
function PlaceableCartridgePlayerActivatable.new(placeable)
	-- upvalues: (copy) v_u_20_
	local v22_ = v_u_20_
	local v23_ = setmetatable({}, v22_)
	v23_.placeable = placeable
	v23_.activateText = g_i18n:getText("action_gameComputerChangeCartridge")
	return v23_
end

function PlaceableCartridgePlayerActivatable:run()
	self.placeable:activatePlayer()
end
