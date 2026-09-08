-- Local values: RollercoasterStateRiding_mt
RollercoasterStateRiding = {}
local RollercoasterStateRiding_mt = Class(RollercoasterStateRiding, ConstructibleState)

-- Upvalues: RollercoasterStateRiding_mt
-- Local values: self
function RollercoasterStateRiding.new(constructible, dirtyFlag, customMt)
	-- upvalues: (copy) RollercoasterStateRiding_mt
	local v5_ = ConstructibleState.new(constructible, dirtyFlag, customMt or RollercoasterStateRiding_mt)
	v5_.lastSentTime = -1
	v5_.infoBoxRideUnderway = {
		["title"] = g_i18n:getText("infohud_rideUnderway"),
		["accentuate"] = true
	}
	return v5_
end

-- Local values: maxValue
function RollercoasterStateRiding:init()
	self.animation = self.constructible:getAnimation()
	self.animationTimeNetworkPrecision = 0.05
	self.animationTimeNetworkPrecisionFactor = 1000 * self.animationTimeNetworkPrecision
	local v7_ = self.animation.clipDuration / self.animationTimeNetworkPrecisionFactor
	local v8_ = math.ceil(v7_)
	self.animationTimeNetworkNumBits = MathUtil.getNumRequiredBits(v8_)
	self.animationInterpolator = self.constructible.spec_rollercoaster.animationInterpolator
	self.animationTimeInterpolator = self.constructible.spec_rollercoaster.animationTimeInterpolator
end

function RollercoasterStateRiding:isDone()
	local v10_
	if self.animation.clipCharacterSet == nil then
		v10_ = false
	else
		v10_ = getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex) >= self.animation.clipDuration
	end
	return v10_
end

function RollercoasterStateRiding:raiseActive()
	return true
end

function RollercoasterStateRiding:activate()
	RollercoasterStateRiding:superClass().activate(self)
	if self.constructible.isClient and not self.constructible.isServer then
		g_currentMission:addUpdateable(self)
	end
	self.constructible:startRide()
end

function RollercoasterStateRiding:deactivate()
	RollercoasterStateRiding:superClass().activate(self)
	if self.constructible.isClient and not self.constructible.isServer then
		g_currentMission:removeUpdateable(self)
	end
	self.constructible:endRide()
end

-- Local values: interpolationAlpha, animationTime
function RollercoasterStateRiding:update(dt)
	if self.constructible.isClient then
		self.constructible:updateFxModifierValues(dt)
	end
	if self.constructible.isServer then
		if self.lastSentTime ~= MathUtil.round(getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex) / self.animationTimeNetworkPrecisionFactor) then
			self.constructible:raiseDirtyFlags(self.dirtyFlag)
			return
		end
	else
		self.animationTimeInterpolator:update(dt)
		local v15_ = self.animationTimeInterpolator:getAlpha()
		local v16_ = self.animationInterpolator:getInterpolatedValue(v15_)
		self.constructible:setAnimationTime(v16_)
	end
end

-- Local values: animationTime
function RollercoasterStateRiding:onReadStream(streamId, connection)
	local v19_ = streamReadUInt16(streamId)
	self.animationInterpolator:setValue(v19_)
	self.animationTimeInterpolator:reset()
end

function RollercoasterStateRiding:onWriteStream(streamId, connection)
	streamWriteUInt16(streamId, getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex))
end

-- Local values: animationTime
function RollercoasterStateRiding:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v25_ = streamReadUIntN(streamId, self.animationTimeNetworkNumBits) * self.animationTimeNetworkPrecisionFactor
		self.animationTimeInterpolator:startNewPhaseNetwork()
		self.animationInterpolator:setTargetValue(v25_)
	end
end

-- Local values: animationTimeCompacted
function RollercoasterStateRiding:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v29_ = MathUtil.round(getAnimTrackTime(self.animation.clipCharacterSet, self.animation.clipIndex) / self.animationTimeNetworkPrecisionFactor)
		self.lastSentTime = v29_
		streamWriteUIntN(streamId, v29_, self.animationTimeNetworkNumBits)
	end
end

function RollercoasterStateRiding:updateInfo(infoTable)
	local v32_ = self.infoBoxRideUnderway
	table.insert(infoTable, v32_)
end

function RollercoasterStateRiding:getIsConstructibleState()
	return false
end
