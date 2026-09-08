-- Local values: RollercoasterStateRideWaiting_mt
RollercoasterStateRideWaiting = {}
local RollercoasterStateRideWaiting_mt = Class(RollercoasterStateRideWaiting, ConstructibleState)

-- Upvalues: RollercoasterStateRideWaiting_mt
-- Local values: self
function RollercoasterStateRideWaiting.new(constructible, dirtyFlag, customMt)
	-- upvalues: (copy) RollercoasterStateRideWaiting_mt
	local v5_ = ConstructibleState.new(constructible, dirtyFlag, customMt or RollercoasterStateRideWaiting_mt)
	v5_.infoBoxRideWaiting = {
		["title"] = g_i18n:getText("infohud_rideWaiting"),
		["accentuate"] = true
	}
	v5_.infoBoxRideStartingIn = {
		["title"] = ""
	}
	v5_.textStartingIn = g_i18n:getText("infohud_rideStartingIn")
	v5_.hudBoxData = {}
	v5_.hudBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBox)
	return v5_
end

function RollercoasterStateRideWaiting:load(xmlFile, key)
	RollercoasterStateRideWaiting:superClass().load(self, xmlFile, key)
	self.waitingDuration = 2500
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		self.waitingDuration = 25000
	end
end

function RollercoasterStateRideWaiting:delete()
	if self.hudBox ~= nil then
		g_currentMission.hud.infoDisplay:destroyBox(self.hudBox)
	end
	RollercoasterStateRideWaiting:superClass().delete(self)
end

function RollercoasterStateRideWaiting:isDone()
	if self.startTime == nil then
		return false
	end
	local v11_
	if g_time > self.startTime then
		v11_ = self.constructible:getCanStart()
	else
		v11_ = false
	end
	return v11_
end

function RollercoasterStateRideWaiting:raiseActive()
	return self.constructible:getCanStart()
end

function RollercoasterStateRideWaiting:activate()
	RollercoasterStateRideWaiting:superClass().activate(self)
	self.constructible:setPlayerTriggerState(true)
	self.constructible:registerRidersChangedListener(self, function(p14_, p15_, p16_)
		-- upvalues: (copy) self
		if self.constructible:getIsSynchronized() and (p14_ == 1 and p15_ == 1) then
			self.startTime = g_time + self.waitingDuration
		end
		if p16_ == g_localPlayer then
			if p15_ == 1 then
				g_currentMission:addDrawable(self)
			else
				g_currentMission:removeDrawable(self)
			end
		end
		if p14_ > 0 then
			self.constructible:raiseActive()
		end
	end)
end

function RollercoasterStateRideWaiting:deactivate()
	RollercoasterStateRideWaiting:superClass().deactivate(self)
	self.constructible:unregisterRidersChangedListener(self)
	self.startTime = nil
	g_currentMission:removeDrawable(self)
	self.constructible:setPlayerTriggerState(false)
end

-- Local values: timeLeft
function RollercoasterStateRideWaiting:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local v20_ = streamReadUInt8(streamId)
		self.startTime = g_time + v20_ * 1000
	end
end

-- Local values: timeLeft
function RollercoasterStateRideWaiting:onWriteStream(streamId, connection)
	if streamWriteBool(streamId, self.startTime ~= nil) then
		local v23_ = MathUtil.round((self.startTime - g_time) / 1000)
		streamWriteUInt8(streamId, v23_)
	end
end

-- Local values: box, i, element
function RollercoasterStateRideWaiting:draw()
	if self.startTime and not self.constructible.spec_infoTrigger.showInfo then
		local v25_ = self.hudBox
		v25_:clear()
		v25_:setTitle(self.constructible:getName())
		self:updateInfo(self.hudBoxData)
		if #self.hudBoxData > 0 then
			for v26_ = 1, #self.hudBoxData do
				local v27_ = self.hudBoxData[v26_]
				v25_:addLine(v27_.title, v27_.text, v27_.accentuate)
				self.hudBoxData[v26_] = nil
			end
			v25_:showNextFrame()
		end
	end
end

function RollercoasterStateRideWaiting:updateInfo(infoTable)
	local v30_ = self.infoBoxRideWaiting
	table.insert(infoTable, v30_)
	if self.startTime ~= nil and self.startTime > g_time then
		self.infoBoxRideStartingIn.title = string.format(self.textStartingIn, (self.startTime - g_time) / 1000)
		local v31_ = self.infoBoxRideStartingIn
		table.insert(infoTable, v31_)
	end
end

function RollercoasterStateRideWaiting:getIsConstructibleState()
	return false
end
