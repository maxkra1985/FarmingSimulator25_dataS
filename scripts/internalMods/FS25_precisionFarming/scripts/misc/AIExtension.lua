-- Local values: AIExtension_mt
AIExtension = {}
AIExtension.MOD_NAME = g_currentModName
local AIExtension_mt = Class(AIExtension)

-- Upvalues: AIExtension_mt
-- Local values: self
function AIExtension.new(customMt)
	-- upvalues: (copy) AIExtension_mt
	local v3_ = customMt or AIExtension_mt
	local v4_ = setmetatable({}, v3_)
	v4_.rtkStations = {}
	v4_.preciseModeActive = false
	return v4_
end

function AIExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return true
end

function AIExtension:delete()
	self:setPreciseModeActive(false)
end

function AIExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(AIJob, "updateCost", function(p7_, p8_, p9_)
		if p8_:isa(AIJobFieldWork) then
			local v10_ = p8_.vehicleParameter:getVehicle()
			if v10_ ~= nil and v10_.updatePFStatistic ~= nil then
				local v11_ = p8_:getPricePerMs()
				if v11_ > 0 then
					v10_:updatePFStatistic("helperCosts", v11_ * p9_ * EconomyManager.getCostMultiplier())
				end
			end
		end
		return p7_(p8_, p9_)
	end)
end

function AIExtension:setPreciseModeActive(state)
	self.preciseModeActive = state
end

function AIExtension:registerRTKStation(station)
	self.rtkStations[station] = station
	self:setPreciseModeActive(true)
end

function AIExtension:unregisterRTKStation(station)
	self.rtkStations[station] = nil
	self:setPreciseModeActive(next(self.rtkStations) ~= nil)
end
