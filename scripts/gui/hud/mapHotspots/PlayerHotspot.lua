-- Local values: PlayerHotspot_mt
PlayerHotspot = {}
local PlayerHotspot_mt = Class(PlayerHotspot, MapHotspot)

-- Upvalues: PlayerHotspot_mt
-- Local values: self
function PlayerHotspot.new(customMt)
	-- upvalues: (copy) PlayerHotspot_mt
	local v3_ = MapHotspot.new(customMt or PlayerHotspot_mt)
	if Platform.isMobile then
		local v4_, v5_ = getNormalizedScreenValues(120, 120)
		v3_.width = v4_
		v3_.height = v5_
	else
		local v6_, v7_ = getNormalizedScreenValues(60, 60)
		v3_.width = v6_
		v3_.height = v7_
	end
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.playerPosition", 0, 0, v3_.width, v3_.height)
	local v8_ = v3_.icon
	local v9_ = v3_.color
	v8_:setColor(unpack(v9_))
	v3_.vehicle = nil
	v3_.player = nil
	v3_.isBlinking = not Platform.isMobile
	if Platform.isMobile then
		v3_.clickArea = MapHotspot.getClickCircle(0.5)
		return v3_
	else
		v3_.clickArea = MapHotspot.getClickArea({
			32,
			40,
			36,
			46
		}, { 100, 100 }, 0)
		return v3_
	end
end

function PlayerHotspot:delete()
	PlayerHotspot:superClass().delete(self)
	self.vehicle = nil
	self.player = nil
end

function PlayerHotspot:getRenderLast()
	return true
end

function PlayerHotspot:getCategory()
	return MapHotspot.CATEGORY_PLAYER
end

-- Local values: x, _, z
function PlayerHotspot:getWorldPosition()
	local v12_ = nil
	local v13_ = nil
	if self.vehicle == nil or self.vehicle:getIsBeingDeleted() then
		if self.player ~= nil then
			local v14_
			v12_, v14_, v13_ = self.player:getPosition()
		end
	else
		local v15_
		v12_, v15_, v13_ = getWorldTranslation(self.vehicle.rootNode)
	end
	return v12_, v13_
end

function PlayerHotspot:getWorldRotation()
	if self.vehicle == nil or self.vehicle:getIsBeingDeleted() then
		return self.player == nil and 0 or MathUtil.getValidLimit(3.141592653589793 + self.player:getYaw())
	else
		return self.vehicle:getMapHotspotRotation(true)
	end
end

function PlayerHotspot:setVehicle(vehicle)
	self.vehicle = vehicle
end

function PlayerHotspot:getVehicle()
	return self.vehicle
end

function PlayerHotspot:setPlayer(player)
	self.player = player
end

function PlayerHotspot:getPlayer()
	return self.player
end

-- Local values: farm, color
function PlayerHotspot:setOwnerFarmId(farmId)
	MapHotspot.setOwnerFarmId(self, farmId)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		local v25_ = g_farmManager:getFarmById(self.ownerFarmId)
		if v25_ ~= nil then
			local v26_ = Farm.COLORS[v25_.color]
			self:setColor(v26_[1], v26_[2], v26_[3])
			return
		end
		self:setColor(1, 1, 1)
	end
end

function PlayerHotspot:getCanBlink()
	local v28_ = self.lastScreenLayout:getBlinkPlayerArrow()
	if v28_ then
		v28_ = self.player == g_localPlayer and true or self.vehicle ~= nil
	end
	return v28_
end
PlayerHotspot.render = MapHotspot.render
PlayerHotspot.setScale = MapHotspot.setScale
PlayerHotspot.getColor = MapHotspot.getColor
