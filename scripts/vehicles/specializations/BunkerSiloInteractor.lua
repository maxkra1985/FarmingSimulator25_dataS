BunkerSiloInteractor = {}

function BunkerSiloInteractor.prerequisitesPresent(specializations)
	return true
end

function BunkerSiloInteractor.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setBunkerSiloInteractorCallback", BunkerSiloInteractor.setBunkerSiloInteractorCallback)
	SpecializationUtil.registerFunction(vehicleType, "notifiyBunkerSilo", BunkerSiloInteractor.notifiyBunkerSilo)
end

function BunkerSiloInteractor.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BunkerSiloInteractor)
end

-- Local values: spec
function BunkerSiloInteractor:onLoad(savegame)
	local v4_ = self.spec_bunkerSiloInteractor
	v4_.callback = nil
	v4_.callbackTarget = nil
end

-- Local values: spec
function BunkerSiloInteractor:setBunkerSiloInteractorCallback(callback, callbackTarget)
	local v8_ = self.spec_bunkerSiloInteractor
	v8_.callback = callback
	v8_.callbackTarget = callbackTarget
end

-- Local values: spec
function BunkerSiloInteractor:notifiyBunkerSilo(changedFillLevel, fillType, x, y, z)
	local v15_ = self.spec_bunkerSiloInteractor
	if v15_.callback ~= nil then
		v15_.callback(v15_.callbackTarget, self, changedFillLevel, fillType, x, y, z)
	end
end
