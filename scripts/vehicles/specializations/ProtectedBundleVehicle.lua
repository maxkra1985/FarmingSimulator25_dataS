ProtectedBundleVehicle = {}

function ProtectedBundleVehicle.prerequisitesPresent(specializations)
	return true
end
function ProtectedBundleVehicle.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ProtectedBundleVehicle")
	v1_:register(XMLValueType.BOOL, "vehicle.protectedBundleVehicle#isBundleRoot", "Vehicle acts are bundle root vehicle (the only vehicle to be selectable, shown in overview, sellable, resetable)", false)
	v1_:register(XMLValueType.BOOL, "vehicle.protectedBundleVehicle#isBundleChild", "Vehicle acts as bundle child vehicle (can not be selected, not shown in map overview, reset and sold with attacher vehicle)", false)
	v1_:register(XMLValueType.STRING, "vehicle.protectedBundleVehicle#bundleFilename", "Path to bundle xml file (required for reset of the vehicle to spawn the bundle instead of the single vehicle)")
	v1_:setXMLSpecializationType()
end

function ProtectedBundleVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getReloadXML", ProtectedBundleVehicle.getReloadXML)
end

function ProtectedBundleVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ProtectedBundleVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", ProtectedBundleVehicle)
end

-- Local values: spec
function ProtectedBundleVehicle:onLoad(savegame)
	local v5_ = self.spec_protectedBundleVehicle
	v5_.isBundleRoot = self.xmlFile:getValue("vehicle.protectedBundleVehicle#isBundleRoot", false)
	v5_.isBundleChild = self.xmlFile:getValue("vehicle.protectedBundleVehicle#isBundleChild", false)
	v5_.bundleFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.protectedBundleVehicle#bundleFilename"), self.baseDirectory)
	if v5_.bundleFilename ~= nil and g_storeManager:getItemByXMLFilename(v5_.bundleFilename) == nil then
		Logging.xmlWarning(self.xmlFile, "Missing bundle vehicle store item for \'%s\'", v5_.bundleFilename)
	end
	if v5_.isBundleChild then
		self.canBeReset = false
		self.showInVehicleOverview = false
		self.allowSelection = false
	end
	if not (self.isServer and v5_.isBundleChild) then
		SpecializationUtil.removeEventListener(self, "onPostDetach", ProtectedBundleVehicle)
	end
end

function ProtectedBundleVehicle:onPostDetach()
	if not (g_currentMission.vehicleSystem.isReloadRunning or (g_currentMission.isTeleporting or (self.isDeleted or self.isDeleting))) then
		self:delete()
	end
end

-- Local values: spec, vehicleXMLFile
function ProtectedBundleVehicle:getReloadXML(superFunc)
	local v9_ = self.spec_protectedBundleVehicle
	if not v9_.isBundleRoot or v9_.bundleFilename == nil then
		return superFunc(self)
	end
	local v10_ = superFunc(self)
	if v10_ ~= nil then
		v10_:setValue("vehicles.vehicle(0)#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(v9_.bundleFilename)))
	end
	return v10_
end
