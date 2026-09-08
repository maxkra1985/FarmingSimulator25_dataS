-- Local values: IgnitionLockManager_mt
IgnitionLockManager = {}
IgnitionLockManager.DEVICE_NAME = "Ignition Lock"
IgnitionLockManager.DEBUG_ENABLED = false
local IgnitionLockManager_mt = Class(IgnitionLockManager, AbstractManager)

-- Upvalues: IgnitionLockManager_mt
-- Local values: self
function IgnitionLockManager.new(customMt)
	-- upvalues: (copy) IgnitionLockManager_mt
	local v3_ = customMt or IgnitionLockManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_:reset()
	addConsoleCommand("gsIgnitionLockDebug", "Toggles the iginition lock debug view", "consoleCommandToggleDebug", v4_, nil, false)
	v4_.state = IgnitionLockState.UNKNOWN
	v4_.initialized = false
	return v4_
end

function IgnitionLockManager:reset()
	self.ignitionLocks = {}
	self.initialized = false
end

-- Local values: ignitionLock
function IgnitionLockManager:tryToAddDevice(internalId, engineDeviceId, deviceName)
	if deviceName ~= IgnitionLockManager.DEVICE_NAME then
		return false
	end
	setGamepadDeadzone(0, internalId, 0)
	local v10_ = self.ignitionLocks
	table.insert(v10_, {
		["internalId"] = internalId,
		["engineDeviceId"] = engineDeviceId
	})
	return true
end

-- Local values: ignitionLock, axisValue, sign
function IgnitionLockManager:initializeState()
	local v12_ = self.ignitionLocks[1]
	setGamepadDeadzone(0, v12_.internalId, 0)
	local v13_ = getInputAxis(0, v12_.internalId)
	local v14_ = math.sign(v13_)
	if v14_ ~= 0 and v13_ <= 0.1 then
		if v14_ <= 0 then
			self:setState(IgnitionLockState.OFF)
		elseif v13_ < 0.01 then
			self:setState(IgnitionLockState.IGNITION)
		elseif v13_ >= 0.01 and v13_ < 0.1 then
			self:setState(IgnitionLockState.START)
		end
		self.initialized = true
	end
end

-- Local values: ignitionLock, offToIgnition, ignitionToOff, ignitionToStart, startToIgnition
function IgnitionLockManager:update(dt)
	local v16_ = self.ignitionLocks[1]
	if v16_ ~= nil then
		if not self.initialized then
			self:initializeState()
		end
		local v17_ = getInputButton(0, v16_.internalId) > 0
		local v18_ = getInputButton(1, v16_.internalId) > 0
		local v19_ = getInputButton(2, v16_.internalId) > 0
		if v17_ or getInputButton(3, v16_.internalId) > 0 then
			self:setState(IgnitionLockState.IGNITION)
			return
		end
		if v18_ then
			self:setState(IgnitionLockState.OFF)
			return
		end
		if v19_ then
			self:setState(IgnitionLockState.START)
		end
	end
end

function IgnitionLockManager:setState(state)
	if state ~= self.state then
		self.state = state
	end
end

function IgnitionLockManager:getState()
	return self.state
end

function IgnitionLockManager:getIsAvailable()
	return #self.ignitionLocks > 0
end

-- Local values: renderButton, posY, k, ignitionLock
function IgnitionLockManager:drawDebug()
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(true)
	renderText(0.025, 0.93, 0.015, string.format("Ignition Lock - Global State: %s", IgnitionLockState.getName(self.state)))
	setTextBold(false)
	local v25_ = 0.91
	local function v36_(p26_, p27_, p28_, p29_, p30_)
		local v31_ = getInputButton(p30_, p29_)
		local v32_ = getGamepadButtonPhysicalName(p30_, p29_)
		local v33_ = renderText
		local v34_ = string.format
		local v35_ = v31_ > 0
		v33_(p26_, p27_, p28_, v34_("Button %d: %s | %s", p30_, v32_, (tostring(v35_))))
	end
	for _, v37_ in ipairs(self.ignitionLocks) do
		renderText(0.025, v25_ - 0, 0.012, string.format("Ignition Lock %s", v37_.engineDeviceId))
		v36_(0.03, v25_ - 0.016, 0.012, v37_.internalId, 0)
		v36_(0.03, v25_ - 0.032, 0.012, v37_.internalId, 1)
		v36_(0.03, v25_ - 0.048, 0.012, v37_.internalId, 2)
		v36_(0.03, v25_ - 0.064, 0.012, v37_.internalId, 3)
		renderText(0.03, v25_ - 0.08 - 0.002, 0.012, string.format("Axis 0: %1.4f", getInputAxis(0, v37_.internalId)))
		v25_ = v25_ - 0.12
	end
end

function IgnitionLockManager:consoleCommandToggleDebug()
	IgnitionLockManager.DEBUG_ENABLED = not IgnitionLockManager.DEBUG_ENABLED
	if IgnitionLockManager.DEBUG_ENABLED then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
end
g_ignitionLockManager = IgnitionLockManager.new()
