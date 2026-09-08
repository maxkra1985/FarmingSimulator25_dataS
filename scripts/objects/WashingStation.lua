-- Local values: WashingStation_mt, WashingStationActivatable_mt
WashingStation = {}
local WashingStation_mt = Class(WashingStation, Object)
InitStaticObjectClass(WashingStation, "WashingStation")

function WashingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trigger#node", "Vehicle trigger node")
	schema:register(XMLValueType.FLOAT, basePath .. "#washDuration", "Wash duration")
	schema:register(XMLValueType.INT, basePath .. "#pricePerWash", "Price per wash")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effects")
end

-- Upvalues: WashingStation_mt
-- Local values: self
function WashingStation.new(isServer, isClient, customMt)
	-- upvalues: (copy) WashingStation_mt
	return Object.new(isServer, isClient, customMt or WashingStation_mt)
end

-- Local values: trigger, _, baseDirectory
function WashingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	local v13_ = xmlFile:getValue(key .. ".trigger#node", rootNode, components, i3dMappings)
	if v13_ == nil then
		return false
	end
	self.trigger = v13_
	addTrigger(v13_, "onTriggerCallback", self)
	self.isEnabled = true
	self.vehicleNodesInRange = {}
	self.vehiclesToWash = {}
	self.pricePerWash = xmlFile:getValue(key .. "#pricePerWash", 1)
	self.washDuration = xmlFile:getValue(key .. "#washDuration", 1) * 1000
	if self.isClient then
		local _, v14_ = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
		self.samples = {
			["active"] = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", v14_, components, 0, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		}
		self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", components, self, i3dMappings)
		self.fxActive = false
	end
	self.activatable = WashingStationActivatable.new(self, self.trigger)
	self.dirtyFlag = self:getNextDirtyFlag()
	return true
end

function WashingStation:delete()
	if self.trigger ~= nil then
		removeTrigger(self.trigger)
	end
	if self.isClient then
		g_soundManager:stopSamples(self.samples)
		g_soundManager:deleteSamples(self.samples)
		g_effectManager:deleteEffects(self.effects)
	end
	self.vehicleNodesInRange = {}
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

-- Local values: isActive
function WashingStation:readUpdateStream(streamId, timestamp, connection)
	WashingStation:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			self:onStartWashing()
			return
		end
		self:onStopWashing()
	end
end

function WashingStation:writeUpdateStream(streamId, connection, dirtyMask)
	WashingStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.endTime ~= nil)
	end
end

-- Local values: i, vehicle, dirtAmount
function WashingStation:update(dt)
	if self.isServer and self.endTime ~= nil then
		if self.endTime > g_time then
			for v26_ = #self.vehiclesToWash, 1, -1 do
				local v27_ = self.vehiclesToWash[v26_]
				if v27_:getDirtAmount() > 0.01 then
					v27_:cleanVehicle(1 / self.washDuration * dt)
				else
					table.remove(self.vehiclesToWash, v26_)
				end
			end
			self:raiseActive()
			return
		end
		self:onStopWashing()
	end
end

-- Local values: isWashing, washedVehicles, costs, node, _, vehicle, dirtAmount
function WashingStation:startWashing(farmId)
	if self.isServer then
		local v30_ = {}
		local v31_ = 0
		local v32_ = false
		for v33_, _ in pairs(self.vehicleNodesInRange) do
			if entityExists(v33_) then
				local v34_ = g_currentMission:getNodeObject(v33_)
				if v30_[v34_] == nil then
					local v35_ = v34_:getDirtAmount()
					if v35_ > 0.01 then
						local v36_ = self.vehiclesToWash
						table.insert(v36_, v34_)
						v31_ = v31_ + v35_ * self.pricePerWash
						v32_ = true
					end
					v30_[v34_] = true
				end
			else
				self.vehicleNodesInRange[v33_] = nil
			end
		end
		if v32_ then
			if v31_ >= 1 then
				g_currentMission:addMoney(-v31_, farmId, MoneyType.VEHICLE_REPAIR, true, true)
			end
			self:onStartWashing()
		end
	end
end

function WashingStation:onStartWashing()
	if self.isServer then
		self.endTime = g_time + self.washDuration
		self:raiseActive()
		self:raiseDirtyFlags(self.dirtyFlag)
	end
	if self.isClient and not self.fxActive then
		g_soundManager:playSample(self.samples.active)
		g_effectManager:setEffectTypeInfo(self.effects, FillType.WATER)
		g_effectManager:startEffects(self.effects)
		self.fxActive = true
	end
end

-- Local values: i
function WashingStation:onStopWashing()
	if self.isServer then
		for v39_ = #self.vehiclesToWash, 1, -1 do
			self.vehiclesToWash[v39_] = nil
		end
		self:raiseDirtyFlags(self.dirtyFlag)
	end
	if self.isClient and self.fxActive then
		g_soundManager:stopSample(self.samples.active)
		g_effectManager:stopEffects(self.effects)
		self.fxActive = false
	end
end

-- Local values: canBeActivated, node, _, vehicle
function WashingStation:updateVehicleState()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	if self.isEnabled then
		local v41_ = self.isPlayerInRange
		if not v41_ then
			for v42_, _ in pairs(self.vehicleNodesInRange) do
				if entityExists(v42_) then
					local v43_ = g_currentMission:getNodeObject(v42_)
					if v43_ ~= nil and v43_ == g_localPlayer:getCurrentVehicle() then
						v41_ = true
					end
				else
					self.vehicleNodesInRange[v42_] = nil
				end
			end
		end
		if v41_ then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		end
	end
end

-- Local values: changed, object
function WashingStation:onTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		local v48_ = nil
		if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
			local v49_ = g_currentMission:getNodeObject(otherId)
			if v49_ ~= nil and (v49_:isa(Vehicle) and (v49_.getAllowsWashingByType ~= nil and v49_:getAllowsWashingByType(Washable.WASHTYPE_TRIGGER))) then
				if onEnter then
					self.vehicleNodesInRange[otherId] = true
					v48_ = true
				else
					self.vehicleNodesInRange[otherId] = nil
					v48_ = true
				end
			end
		elseif onEnter then
			self.isPlayerInRange = true
			v48_ = true
		else
			self.isPlayerInRange = false
			v48_ = true
		end
		if v48_ then
			self:updateVehicleState()
		end
	end
end
WashingStationActivatable = {}
local v_u_50_ = Class(WashingStationActivatable)
function WashingStationActivatable.new(p51_, p52_)
	-- upvalues: (copy) v_u_50_
	local v53_ = v_u_50_
	local v54_ = setmetatable({}, v53_)
	v54_.washingStation = p51_
	v54_.triggerNode = p52_
	v54_.activateText = g_i18n:getText("action_startWashing")
	return v54_
end

function WashingStationActivatable:getIsActivatable()
	return g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), self.washingStation)
end

function WashingStationActivatable:run()
	g_client:getServerConnection():sendEvent(WashingStationEvent.new(self.washingStation))
end

-- Local values: tx, ty, tz
function WashingStationActivatable:getDistance(x, y, z)
	local v61_, v62_, v63_ = getWorldTranslation(self.triggerNode)
	return MathUtil.vector3Length(x - v61_, y - v62_, z - v63_)
end
