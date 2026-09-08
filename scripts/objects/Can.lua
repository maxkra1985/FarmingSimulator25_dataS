-- Local values: Can_mt, CanActivatable_mt
Can = {}
local Can_mt = Class(Can)

function Can:onCreate(can)
	g_currentMission:addUpdateable(Can.new(can))
end

-- Upvalues: Can_mt
-- Local values: self, pickupName
-- Upvalues: CanActivatable_mt
-- Local values: self

function Can.new(can)
	-- upvalues: (copy) Can_mt
	local v4_ = Can_mt
	local v5_ = setmetatable({}, v4_)
	v5_.customEnvironment = g_currentMission.loadingMapModName
	v5_.can = can
	v5_.time = 0
	v5_.xpGain = 1
	v5_.pickupName = "Unknown"
	local v6_ = getUserAttribute(can, "pickupName")
	if v6_ ~= nil then
		v5_.pickupName = g_i18n:getText(v6_, v5_.customEnvironment)
	end
	v5_.drinkSound = createSample("SoftDrink")
	loadSample(v5_.drinkSound, "data/maps/sounds/softDrink.wav", false)
	v5_.triggerId = getChildAt(v5_.can, 0)
	if v5_.triggerId ~= 0 then
		addTrigger(v5_.triggerId, "onCanPickupTrigger", v5_)
	end
	v5_.deleteTimer = 0
	v5_.activatable = CanActivatable.new(v5_)
	return v5_
end

function Can:delete()
	if self.triggerId ~= 0 then
		removeTrigger(self.triggerId)
		self.triggerId = 0
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	delete(self.can)
	self.can = 0
	delete(self.drinkSound)
	self.drinkSound = 0
	g_currentMission:removeUpdateable(self)
end

function Can:update(dt)
	self.time = self.time + dt
	if self.deleteTimer ~= 0 and self.deleteTimer < self.time then
		self:delete()
	end
end

function Can:pickup()
	playSample(self.drinkSound, 1, 1, 0, 0, 0)
	setVisibility(self.can, false)
	self.deleteTimer = self.time + getSampleDuration(self.drinkSound) + 200
	if self.triggerId ~= 0 then
		removeTrigger(self.triggerId)
		self.triggerId = 0
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

-- Local values: localPlayer
function Can:onCanPickupTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		local v15_ = g_localPlayer
		if v15_ == nil or (v15_:getIsInVehicle() or otherId ~= v15_.rootNode) then
			return
		elseif onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	else
		return
	end
end
CanActivatable = {}
local v_u_16_ = Class(CanActivatable)
function CanActivatable.new(p17_)
	-- upvalues: (copy) v_u_16_
	local v18_ = v_u_16_
	local v19_ = setmetatable({}, v18_)
	v19_.can = p17_
	v19_.activateText = g_i18n:getText("action_pickupSodaCan", p17_.customEnvironment)
	return v19_
end

function CanActivatable:run()
	self.can:pickup()
end
