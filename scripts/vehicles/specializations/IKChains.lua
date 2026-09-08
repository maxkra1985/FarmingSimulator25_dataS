IKChains = {}

function IKChains.prerequisitesPresent(specializations)
	return true
end
function IKChains.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("IKChains")
	IKUtil.registerIKChainXMLPaths(v1_, "vehicle.ikChains.ikChain(?)")
	v1_:setXMLSpecializationType()
end

function IKChains.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", IKChains)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", IKChains)
end

-- Local values: spec, i, key
function IKChains:onLoad(savegame)
	local v4_ = self.spec_ikChains
	v4_.chains = {}
	local v5_ = 0
	while true do
		local v6_ = string.format("vehicle.ikChains.ikChain(%d)", v5_)
		if not self.xmlFile:hasProperty(v6_) then
			break
		end
		IKUtil.loadIKChain(self.xmlFile, v6_, self.components, self.components, v4_.chains)
		v5_ = v5_ + 1
	end
	if next(v4_.chains) == nil then
		SpecializationUtil.removeEventListener(self, "onUpdate", IKChains)
	end
end

function IKChains:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	IKUtil.updateIKChains(self.spec_ikChains.chains)
end
