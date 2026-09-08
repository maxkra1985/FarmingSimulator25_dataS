-- Local values: Collectible_mt
Collectible = {}
local Collectible_mt = Class(Collectible)

function Collectible:onCreate(node)
	g_currentMission:addNonUpdateable(Collectible.new(node))
end

-- Upvalues: Collectible_mt
-- Local values: self, triggerIndex
function Collectible.new(node)
	-- upvalues: (copy) Collectible_mt
	local v4_ = Collectible_mt
	local v5_ = setmetatable({}, v4_)
	v5_.node = node
	v5_.name = getUserAttribute(node, "name")
	if v5_.name == nil then
		Logging.error("Collectible has no \'name\' defined")
		return nil
	end
	local v6_ = getUserAttribute(node, "triggerIndex")
	if v6_ == nil then
		v5_.triggerNode = node
	else
		v5_.triggerNode = getChildAt(node, v6_)
		if v5_.triggerNode == 0 then
			Logging.error("Collectible has wrong \'triggerIndex\' defined, node does not exist.")
			return nil
		end
	end
	if not CollisionFlag.getHasMaskFlagSet(v5_.triggerNode, CollisionFlag.PLAYER) then
		Logging.warning("Missing collision mask bit \'%d\'. Please add this bit to collectible trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(v5_.triggerNode))
	end
	v5_.activatable = CollectibleActivatable.new(v5_)
	v5_.isActive = false
	v5_.mapHotspotVisible = false
	g_currentMission.collectiblesSystem:addCollectible(v5_)
	return v5_
end

function Collectible:delete()
	self:deactivate()
	g_currentMission.collectiblesSystem:removeCollectible(self)
end

function Collectible:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and (otherId == g_localPlayer.rootNode and g_localPlayer.farmId ~= FarmManager.SPECTATOR_FARM_ID)) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

function Collectible:activate()
	if not self.isActive then
		setVisibility(self.node, true)
		addTrigger(self.triggerNode, "triggerCallback", self)
		self.mapHotspot = CollectibleHotspot.new(self)
		self.mapHotspot:setVisible(self.mapHotspotVisible)
		g_currentMission:addMapHotspot(self.mapHotspot)
		self.isActive = true
	end
end

function Collectible:deactivate()
	if self.isActive then
		setVisibility(self.node, false)
		removeTrigger(self.triggerNode)
		delete(self.node)
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
		self.mapHotspot = nil
		self.isActive = false
	end
end

function Collectible:setHotspotVisible(visible)
	self.mapHotspotVisible = visible
	if self.mapHotspot ~= nil then
		self.mapHotspot:setVisible(visible)
	end
end
