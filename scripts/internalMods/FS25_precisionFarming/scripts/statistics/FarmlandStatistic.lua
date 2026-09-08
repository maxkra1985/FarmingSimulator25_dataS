-- Local values: FarmlandStatistic_mt
FarmlandStatistic = {}
local FarmlandStatistic_mt = Class(FarmlandStatistic)

-- Upvalues: FarmlandStatistic_mt
-- Local values: self
function FarmlandStatistic.new(farmlandId, customMt)
	-- upvalues: (copy) FarmlandStatistic_mt
	local v4_ = customMt or FarmlandStatistic_mt
	local v5_ = setmetatable({}, v4_)
	v5_.farmlandId = farmlandId
	v5_.hasChanged = false
	v5_.periodCounter = FarmlandStatisticCounter.new()
	v5_.totalCounter = FarmlandStatisticCounter.new()
	return v5_
end

function FarmlandStatistic:loadFromItemsXML(xmlFile, key)
	if xmlFile:getInt(key .. "#farmlandId") == self.farmlandId then
		self.periodCounter:loadFromItemsXML(xmlFile, key .. ".periodCounter")
		self.totalCounter:loadFromItemsXML(xmlFile, key .. ".totalCounter")
	else
		Logging.warning("Failed to load FarmlandStatistic from items xml (%s)", key)
	end
end

function FarmlandStatistic:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setInt(key .. "#farmlandId", self.farmlandId)
	self.periodCounter:saveToXMLFile(xmlFile, key .. ".periodCounter", usedModNames)
	self.totalCounter:saveToXMLFile(xmlFile, key .. ".totalCounter", usedModNames)
end

function FarmlandStatistic:onReadStream(streamId, connection)
	self.periodCounter:onReadStream(streamId, connection)
	self.totalCounter:onReadStream(streamId, connection)
end

function FarmlandStatistic:onWriteStream(streamId, connection)
	self.periodCounter:onWriteStream(streamId, connection)
	self.totalCounter:onWriteStream(streamId, connection)
end

function FarmlandStatistic:reset(clearTotal)
	self.periodCounter:reset()
	if clearTotal then
		self.totalCounter:reset()
	end
end

-- Local values: counter
function FarmlandStatistic:getValue(total, name)
	local v24_ = self.periodCounter
	if total then
		v24_ = self.totalCounter
	end
	return v24_[name] == nil and 0 or v24_[name]
end

function FarmlandStatistic:updateStatistic(name, value)
	if self.periodCounter[name] ~= nil then
		self.periodCounter[name] = self.periodCounter[name] + value
	end
	if self.totalCounter[name] ~= nil then
		self.totalCounter[name] = self.totalCounter[name] + value
	end
	self.hasChanged = true
end
