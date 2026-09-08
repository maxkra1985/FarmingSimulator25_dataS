-- Local values: RainSettings_mt
RainSettings = {}
local RainSettings_mt = Class(RainSettings)

-- Upvalues: RainSettings_mt
-- Local values: self
function RainSettings.new(customMt)
	-- upvalues: (copy) RainSettings_mt
	local v3_ = customMt or RainSettings_mt
	local v4_ = setmetatable({}, v3_)
	v4_.typeId = nil
	v4_.presetId = nil
	v4_.dropsMultiplier = 1
	v4_.maxDropsMultiplier = 1
	v4_.turbulence = 1
	v4_.turbulenceTimeScale = 0.5
	v4_.turbulencePulseDuration = 2
	v4_.spawnVelocityX = 0
	v4_.spawnVelocityY = -8
	v4_.spawnVelocityZ = 0
	v4_.mostConcentratedDistance = 5
	v4_.distributionPower = 3.2
	v4_.turbulenceFrequency = 1
	v4_.rainfallScale = 0
	v4_.snowfallScale = 0
	v4_.hailfallScale = 0
	v4_.maxBounces = 0
	v4_.bounceRandomFactor = 1
	v4_.bounceRestitution = 0.25
	return v4_
end

-- Local values: spawnVelocityStr, velocityVector
function RainSettings:load(xmlFile, key)
	self.maxDropsMultiplier = xmlFile:getFloat(key .. ".general#maxDropsMultiplier", self.maxDropsMultiplier)
	if self.maxDropsMultiplier > 1 then
		Logging.xmlWarning(xmlFile, "Valid range for maxDropsMultiplier is 0-1. Set value to 1 for \'%s\'", key)
		self.maxDropsMultiplier = 1
	end
	local v8_ = xmlFile:getString(key .. ".general#spawnVelocity", nil)
	local v9_ = string.getVector(v8_)
	if #v9_ == 1 then
		self.spawnVelocityX = 0
		self.spawnVelocityY = v9_[1]
		self.spawnVelocityZ = 0
	elseif #v9_ == 3 then
		self.spawnVelocityX = v9_[1]
		self.spawnVelocityY = v9_[2]
		self.spawnVelocityZ = v9_[3]
	end
	self.mostConcentratedDistance = xmlFile:getFloat(key .. ".general#mostConcentratedDistance", self.mostConcentratedDistance)
	self.distributionPower = xmlFile:getFloat(key .. ".general#distributionPower", self.distributionPower)
	self.turbulence = xmlFile:getFloat(key .. ".turbulence#value", self.turbulence)
	self.turbulenceTimeScale = xmlFile:getFloat(key .. ".turbulence#timeScale", self.turbulenceTimeScale)
	self.turbulencePulseDuration = xmlFile:getFloat(key .. ".turbulence#pulseDuration", self.turbulencePulseDuration)
	self.turbulenceFrequency = xmlFile:getFloat(key .. ".turbulence#frequency", self.turbulenceFrequency)
	self.rainfallScale = xmlFile:getFloat(key .. "#rainfallScale", self.rainfallScale)
	self.hailfallScale = xmlFile:getFloat(key .. "#hailfallScale", self.hailfallScale)
	self.snowfallScale = xmlFile:getFloat(key .. "#snowfallScale", self.snowfallScale)
	self.maxBounces = xmlFile:getUInt(key .. ".general#maxBounces", self.maxBounces)
	self.bounceRandomFactor = xmlFile:getFloat(key .. ".general#bounceRandomFactor", self.bounceRandomFactor)
	self.bounceRestitution = xmlFile:getFloat(key .. ".general#bounceRestitution", self.bounceRestitution)
	return true
end

function RainSettings:save(xmlFile, key)
	xmlFile:setFloat(key .. ".general#maxDropsMultiplier", self.maxDropsMultiplier)
	local v13_ = key .. ".general#spawnVelocity"
	local v14_ = self.spawnVelocityX
	local v15_ = tostring(v14_)
	local v16_ = self.spawnVelocityY
	local v17_ = tostring(v16_)
	local v18_ = self.spawnVelocityZ
	xmlFile:setString(v13_, v15_ .. " " .. v17_ .. " " .. tostring(v18_))
	xmlFile:setFloat(key .. ".general#mostConcentratedDistance", self.mostConcentratedDistance)
	xmlFile:setFloat(key .. ".general#distributionPower", self.distributionPower)
	xmlFile:setUInt(key .. ".general#maxBounces", self.maxBounces)
	xmlFile:setFloat(key .. ".general#bounceRandomFactor", self.bounceRandomFactor)
	xmlFile:setFloat(key .. ".general#bounceRestitution", self.bounceRestitution)
	xmlFile:setFloat(key .. ".turbulence#value", self.turbulence)
	xmlFile:setFloat(key .. ".turbulence#timeScale", self.turbulenceTimeScale)
	xmlFile:setFloat(key .. ".turbulence#pulseDuration", self.turbulencePulseDuration)
	xmlFile:setFloat(key .. ".turbulence#frequency", self.turbulenceFrequency)
	return true
end

-- Local values: ret
function RainSettings:clone()
	local v20_ = self.new()
	v20_:copyAttributes(self)
	return v20_
end

function RainSettings:copyAttributes(src)
	self.presetId = src.presetId
	self.typeId = src.typeId
	self.dropsMultiplier = src.dropsMultiplier
	self.maxDropsMultiplier = src.maxDropsMultiplier
	self.turbulence = src.turbulence
	self.turbulenceTimeScale = src.turbulenceTimeScale
	self.turbulencePulseDuration = src.turbulencePulseDuration
	self.spawnVelocityX = src.spawnVelocityX
	self.spawnVelocityY = src.spawnVelocityY
	self.spawnVelocityZ = src.spawnVelocityZ
	self.mostConcentratedDistance = src.mostConcentratedDistance
	self.distributionPower = src.distributionPower
	self.turbulenceFrequency = src.turbulenceFrequency
	self.rainfallScale = src.rainfallScale
	self.snowfallScale = src.snowfallScale
	self.hailfallScale = src.hailfallScale
	self.maxBounces = src.maxBounces
	self.bounceRandomFactor = src.bounceRandomFactor
	self.bounceRestitution = src.bounceRestitution
end
