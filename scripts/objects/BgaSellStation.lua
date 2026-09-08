-- Local values: BgaSellStation_mt
BgaSellStation = {}
local BgaSellStation_mt = Class(BgaSellStation, UnloadingStation)
InitStaticObjectClass(BgaSellStation, "BgaSellStation")

-- Upvalues: BgaSellStation_mt
-- Local values: self
function BgaSellStation.new(isServer, isClient, bga, customMt)
	-- upvalues: (copy) BgaSellStation_mt
	local v6_ = UnloadingStation.new(isServer, isClient, customMt or BgaSellStation_mt)
	v6_.bga = bga
	return v6_
end

function BgaSellStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	if not BgaSellStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings, rootNode) then
		return false
	end
	self.appearsOnStats = xmlFile:getValue(key .. "#appearsOnStats", false)
	return true
end

function BgaSellStation:getEffectiveFillTypePrice(fillTypeIndex)
	return self.bga:getFillTypeLiterPrice(fillTypeIndex) * EconomyManager.getPriceMultiplier()
end

function BgaSellStation:getSupportsGreatDemand(fillType)
	return false
end

function BgaSellStation:getCurrentPricingTrend(fillType)
	return 0
end

function BgaSellStation:getAppearsOnStats()
	if g_currentMission:getFarmId() == self:getOwnerFarmId() then
		return self.appearsOnStats
	else
		return false
	end
end

function BgaSellStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#appearsOnStats", "Appears on stats page", false)
	UnloadingStation.registerXMLPaths(schema, basePath)
end
