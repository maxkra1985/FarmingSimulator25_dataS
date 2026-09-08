BalerStationary = {}
source("dataS/scripts/gui/hud/extensions/BalerStationaryHUDExtension.lua")

function BalerStationary.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Baler, specializations) and SpecializationUtil.hasSpecialization(BaleWrapper, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(FoldableSteps, specializations)
	end
	return v2_
end

function BalerStationary.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BalerStationary)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BalerStationary)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BalerStationary)
end

-- Local values: spec
function BalerStationary:onLoad()
	self.spec_balerStationary.hudExtension = BalerStationaryHUDExtension.new(self)
end

-- Local values: spec
function BalerStationary:onDelete()
	local v6_ = self.spec_balerStationary
	if v6_.hudExtension ~= nil then
		g_currentMission.hud:removeInfoExtension(v6_.hudExtension)
		v6_.hudExtension:delete()
	end
end

-- Local values: spec
function BalerStationary:onDraw()
	local v8_ = self.spec_balerStationary
	if v8_.hudExtension ~= nil then
		g_currentMission.hud:addInfoExtension(v8_.hudExtension)
	end
end
