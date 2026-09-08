-- Local values: LivestockTrailerActivatable_mt
LivestockTrailerActivatable = {}
local LivestockTrailerActivatable_mt = Class(LivestockTrailerActivatable)

-- Upvalues: LivestockTrailerActivatable_mt
-- Local values: self
function LivestockTrailerActivatable.new(livestockTrailer)
	-- upvalues: (copy) LivestockTrailerActivatable_mt
	local v3_ = LivestockTrailerActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.livestockTrailer = livestockTrailer
	v4_.activateText = g_i18n:getText("action_openLivestockTrailerMenu")
	return v4_
end

-- Local values: rideables, _, rideable
function LivestockTrailerActivatable:getIsActivatable()
	if self.livestockTrailer:getLoadingTrigger() ~= nil then
		return false
	end
	local v6_ = self.livestockTrailer:getRideablesInTrigger()
	if #v6_ > 0 or self.livestockTrailer:getNumOfAnimals() > 0 then
		if self.livestockTrailer:getIsActiveForInput(true) then
			return true
		end
		for _, v7_ in ipairs(v6_) do
			if v7_:getIsActiveForInput(true) then
				return true
			end
		end
	end
	return false
end

function LivestockTrailerActivatable:run()
	g_animalScreen:setController(nil, self.livestockTrailer, false)
	g_gui:showGui("AnimalScreen")
end
