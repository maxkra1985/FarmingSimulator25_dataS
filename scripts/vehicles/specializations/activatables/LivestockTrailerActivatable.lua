LivestockTrailerActivatable = {}
local LivestockTrailerActivatable_mt = Class(LivestockTrailerActivatable)
function LivestockTrailerActivatable.new(livestockTrailer)
	local self = setmetatable({}, LivestockTrailerActivatable_mt)
	self.livestockTrailer = livestockTrailer
	self.activateText = g_i18n:getText("action_openLivestockTrailerMenu")
	return self
end
function LivestockTrailerActivatable:getIsActivatable()
	if self.livestockTrailer:getLoadingTrigger() ~= nil then
		return false
	else
		local rideables = self.livestockTrailer:getRideablesInTrigger()
		if 0 < #rideables or 0 < self.livestockTrailer:getNumOfAnimals() then
			if self.livestockTrailer:getIsActiveForInput(true) then
				return true
			end
			for _, rideable in ipairs(rideables) do
				if rideable:getIsActiveForInput(true) then
					return true
				end
			end
		end
		return false
	end
end
function LivestockTrailerActivatable:run()
	g_animalScreen:setController(nil, self.livestockTrailer, false)
	g_gui:showGui("AnimalScreen")
end
