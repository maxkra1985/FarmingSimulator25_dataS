GreatDemandSpecs = {}
local GreatDemandSpecs_mt = Class(GreatDemandSpecs)
function GreatDemandSpecs.new(customMt)
	local self = setmetatable({}, customMt or GreatDemandSpecs_mt)
	self.sellStation = nil
	self.fillTypeIndex = 0
	self.demandMultiplier = 1
	self.demandStart = { day = 0, hour = 0 }
	self.demandDuration = 0
	self.isRunning = false
	self.isValid = false
	return self
end
function GreatDemandSpecs:getIsDateEarlier(day1, hour1, day2, hour2)
	return day1 < day2 or day1 ~= day2 or hour1 < hour2
end
function GreatDemandSpecs:setUpRandomDemand(weighted, greatDemands, mission)
	self.isRunning = false
	self.isValid = false
	self.fillTypeIndex = 0
	self.demandMultiplier = math.random(11, 14) / 10
	self.demandStart.day = mission.environment.currentMonotonicDay + math.random(2, 5)
	self.demandStart.hour = math.random(7, 18)
	self.demandDuration = math.random(1, 4) * 6
	local blockedTipTrigger = {}
	for _, greatDemand in pairs(greatDemands) do
		if greatDemand == self then
			continue
		end
		if greatDemand.isValid then
			blockedTipTrigger[greatDemand.sellStation] = true
		end
	end
	local validUnloadingStations = {}
	for _, station in pairs(mission.storageSystem:getUnloadingStations()) do
		if station.supportsGreatDemand then
			if station.getSupportsGreatDemand == nil or station.isGreatDemandActive then
				continue
			end
			if blockedTipTrigger[station] == nil then
				table.insert(validUnloadingStations, station)
			end
		end
	end
	if 0 < #validUnloadingStations then
		local tipTrigger = validUnloadingStations[math.random(1, #validUnloadingStations)]
		self.sellStation = tipTrigger
		local start = self.demandStart
		local endDayOffset, endHour = math.modf((start.hour + self.demandDuration) / 24)
		endHour = endHour * 24
		local endDay = start.day + endDayOffset
		local conflictingFillTypes = {}
		if greatDemands ~= nil then
			for _, greatDemand in pairs(greatDemands) do
				local otherStart = greatDemand.demandStart
				if greatDemand == self then
					continue
				end
				if greatDemand.isValid and self.sellStation == greatDemand.sellStation then
					local otherEndDayOffset, otherEndHour = math.modf((otherStart.hour + greatDemand.demandDuration) / 24)
					otherEndHour = otherEndHour * 24
					local otherEndDay = otherStart.day + otherEndDayOffset
					if self:getIsDateEarlier(endDay, endHour, otherStart.day, otherStart.hour) or self:getIsDateEarlier(otherEndDay, otherEndHour, start.day, start.hour) then
						continue
					end
					conflictingFillTypes[greatDemand.fillTypeIndex] = true
				end
			end
		end
		local validFillTypes = {}
		for fillType, enabled in pairs(tipTrigger.acceptedFillTypes) do
			if enabled and (conflictingFillTypes[fillType] == nil and tipTrigger.fillTypeSupportsGreatDemand[fillType]) then
				table.insert(validFillTypes, fillType)
			end
		end
		if 0 < #validFillTypes then
			if weighted then
				local amountUberTotal = 0
				for _, fillTypeIndex in pairs(validFillTypes) do
					local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
					amountUberTotal = amountUberTotal + fillType.totalAmount
				end
				if 0 < amountUberTotal then
					local inverseRatioTotal = 0
					local inverseRatioTable = {}
					for _, fillTypeIndex in pairs(validFillTypes) do
						local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
						local amountRatio = math.max(fillType.totalAmount / amountUberTotal, 0.000001)
						local inverseRatio = 1 / amountRatio
						inverseRatioTotal = inverseRatioTotal + inverseRatio
						local inverseRatioEntry = { fillTypeIndex = fillTypeIndex, inverseRatio = inverseRatio }
						table.insert(inverseRatioTable, inverseRatioEntry)
					end
					local randomNumber = math.random()
					for _, inverseRatioEntry in pairs(inverseRatioTable) do
						randomNumber = randomNumber - inverseRatioEntry.inverseRatio / inverseRatioTotal
						if randomNumber <= 0.0001 then
							self.fillTypeIndex = inverseRatioEntry.fillTypeIndex
							if self.fillTypeIndex ~= 0 then
								self.isValid = true
							end
							return
						end
					end
				end
			else
				self.fillTypeIndex = validFillTypes[math.random(1, #validFillTypes)]
			end
		end
	end
end
