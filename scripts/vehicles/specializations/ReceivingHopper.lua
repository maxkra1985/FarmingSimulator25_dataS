source("dataS/scripts/vehicles/specializations/events/ReceivingHopperSetCreateBoxesEvent.lua")
ReceivingHopper = {}
ReceivingHopper.BOX_SPAWN_OVERLAP_MASK = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER

function ReceivingHopper.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end
	return v2_
end
function ReceivingHopper.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("ReceivingHopper")
	v3_:register(XMLValueType.INT, "vehicle.receivingHopper#fillUnitIndex", "Fill unit index", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.receivingHopper.boxes#spawnPlaceNode", "Spawn place node")
	v3_:register(XMLValueType.STRING, "vehicle.receivingHopper.boxes.box(?)#fillType", "Fill type name")
	v3_:register(XMLValueType.STRING, "vehicle.receivingHopper.boxes.box(?)#filename", "Box filename")
	v3_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).receivingHopper#createBoxes", "Create boxes")
end

function ReceivingHopper.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setCreateBoxes", ReceivingHopper.setCreateBoxes)
	SpecializationUtil.registerFunction(vehicleType, "getCanSpawnNextBox", ReceivingHopper.getCanSpawnNextBox)
	SpecializationUtil.registerFunction(vehicleType, "collisionTestCallback", ReceivingHopper.collisionTestCallback)
	SpecializationUtil.registerFunction(vehicleType, "createBox", ReceivingHopper.createBox)
	SpecializationUtil.registerFunction(vehicleType, "onCreateBoxFinished", ReceivingHopper.onCreateBoxFinished)
end

function ReceivingHopper.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", ReceivingHopper.handleDischargeRaycast)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", ReceivingHopper.getCanBeSelected)
end

function ReceivingHopper.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ReceivingHopper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ReceivingHopper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ReceivingHopper)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ReceivingHopper)
end

-- Local values: spec, i, baseName, fillTypeStr, filename, fillTypeIndex
function ReceivingHopper:onLoad(savegame)
	local v9_ = self.spec_receivingHopper
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper#unloadingDelay", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper#unloadInfoIndex", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper#dischargeInfoIndex", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.tipTrigger#index", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger#index", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.fillScrollerNodes.fillScrollerNode", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.fillEffect", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.fillEffect", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger#litersPerMinute", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.raycastNode#index", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.raycastNode#raycastLength", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger#boxSpawnPlaceIndex", "vehicle.receivingHopper.boxes#spawnPlaceNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger.box(0)", "vehicle.receivingHopper.boxes.box(0)")
	v9_.fillUnitIndex = self.xmlFile:getValue("vehicle.receivingHopper#fillUnitIndex", 1)
	v9_.spawnPlace = self.xmlFile:getValue("vehicle.receivingHopper.boxes#spawnPlaceNode", nil, self.components, self.i3dMappings)
	v9_.boxes = {}
	local v10_ = 0
	while true do
		local v11_ = string.format("vehicle.receivingHopper.boxes.box(%d)", v10_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = self.xmlFile:getValue(v11_ .. "#fillType")
		local v13_ = self.xmlFile:getValue(v11_ .. "#filename")
		local v14_ = g_fillTypeManager:getFillTypeIndexByName(v12_)
		if v14_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid fillType \'%s\'", v12_)
		else
			v9_.boxes[v14_] = v13_
		end
		v10_ = v10_ + 1
	end
	v9_.createBoxes = false
	v9_.lastBox = nil
	v9_.creatingBox = false
	if savegame ~= nil then
		v9_.createBoxes = savegame.xmlFile:getValue(savegame.key .. ".receivingHopper#createBoxes", v9_.createBoxes)
	end
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", ReceivingHopper)
	end
end

-- Local values: spec
function ReceivingHopper:saveToXMLFile(xmlFile, key, usedModNames)
	local v18_ = self.spec_receivingHopper
	xmlFile:setValue(key .. "#createBoxes", v18_.createBoxes)
end

-- Local values: spec
function ReceivingHopper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.spec_receivingHopper.createBoxes and (self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OFF and self:getCanSpawnNextBox()) then
		self:createBox()
	end
end

-- Local values: spec
function ReceivingHopper:setCreateBoxes(state, noEventSend)
	local v23_ = self.spec_receivingHopper
	if state ~= v23_.createBoxes then
		ReceivingHopperSetCreateBoxesEvent.sendEvent(self, state, noEventSend)
		v23_.createBoxes = state
		ReceivingHopper.updateActionEvents(self)
		v23_.lastBox = nil
	end
end

-- Local values: spec, fillType, xmlFilename, size, x, y, z, rx, ry, rz
function ReceivingHopper:getCanSpawnNextBox()
	local v25_ = self.spec_receivingHopper
	if v25_.creatingBox then
		return false
	end
	local v26_ = self:getFillUnitFillType(v25_.fillUnitIndex)
	if v25_.boxes[v26_] == nil then
		return false
	end
	if v25_.lastBox ~= nil and v25_.lastBox:getFillUnitFreeCapacity(1) > 0 then
		return false
	end
	local v27_ = Utils.getFilename(v25_.boxes[v26_], self.baseDirectory)
	local v28_ = StoreItemUtil.getSizeValues(v27_, "vehicle", 0)
	local v29_, v30_, v31_ = getWorldTranslation(v25_.spawnPlace)
	local v32_, v33_, v34_ = getWorldRotation(v25_.spawnPlace)
	v25_.foundObjectAtSpawnPlace = false
	overlapBox(v29_, v30_, v31_, v32_, v33_, v34_, v28_.width * 0.5, 2, v28_.length * 0.5, "collisionTestCallback", self, ReceivingHopper.BOX_SPAWN_OVERLAP_MASK)
	return not v25_.foundObjectAtSpawnPlace
end

-- Local values: spec
function ReceivingHopper:collisionTestCallback(transformId)
	if (g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil) and g_currentMission.nodeToObject[transformId] ~= self then
		self.spec_receivingHopper.foundObjectAtSpawnPlace = true
	end
end

-- Local values: spec, fillType, x, y, z, rx, ry, rz, xmlFilename, data
function ReceivingHopper:createBox()
	local v38_ = self.spec_receivingHopper
	if self.isServer and v38_.createBoxes then
		local v39_ = self:getFillUnitFillType(v38_.fillUnitIndex)
		if v38_.boxes[v39_] ~= nil then
			local v40_, v41_, v42_ = getWorldTranslation(v38_.spawnPlace)
			local v43_, v44_, v45_ = getWorldRotation(v38_.spawnPlace)
			local v46_ = Utils.getFilename(v38_.boxes[v39_], self.baseDirectory)
			v38_.creatingBox = true
			local v47_ = VehicleLoadingData.new()
			v47_:setFilename(v46_)
			v47_:setPosition(v40_, v41_, v42_)
			v47_:setRotation(v43_, v44_, v45_)
			v47_:setPropertyState(VehiclePropertyState.OWNED)
			v47_:setOwnerFarmId(self:getOwnerFarmId())
			v47_:load(self.onCreateBoxFinished, self, nil)
		end
	end
end

-- Local values: spec
function ReceivingHopper:onCreateBoxFinished(vehicles, vehicleLoadState, arguments)
	local v51_ = self.spec_receivingHopper
	v51_.creatingBox = false
	if vehicleLoadState == VehicleLoadingState.OK then
		v51_.lastBox = vehicles[1]
	end
end

-- Local values: stopDischarge, fillType, allowFillType
function ReceivingHopper:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local v56_ = false
	if hitObject == nil or (not hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, (self:getDischargeFillType(dischargeNode))) or hitObject:getFillUnitFreeCapacity(hitFillUnitIndex) <= 0) then
		v56_ = true
	else
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
	end
	if v56_ and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

function ReceivingHopper:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec, _, actionEventId
function ReceivingHopper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v59_ = self.spec_receivingHopper
		self:clearActionEventsTable(v59_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v60_ = self:addActionEvent(v59_.actionEvents, InputAction.IMPLEMENT_EXTRA, self, ReceivingHopper.actionEventToggleBoxCreation, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v60_, GS_PRIO_NORMAL)
			ReceivingHopper.updateActionEvents(self)
		end
	end
end

function ReceivingHopper:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if self:getFillUnitFillLevel(fillUnitIndex) > 0 then
		self:raiseActive()
	end
end

-- Local values: spec
function ReceivingHopper:actionEventToggleBoxCreation(actionName, inputValue, callbackState, isAnalog)
	self:setCreateBoxes(not self.spec_receivingHopper.createBoxes)
end

-- Local values: spec, actionEvent
function ReceivingHopper:updateActionEvents()
	local v65_ = self.spec_receivingHopper
	local v66_ = v65_.actionEvents[InputAction.IMPLEMENT_EXTRA]
	if v66_ ~= nil then
		if v65_.createBoxes then
			g_inputBinding:setActionEventText(v66_.actionEventId, g_i18n:getText("action_disablePalletSpawning"))
			return
		end
		g_inputBinding:setActionEventText(v66_.actionEventId, g_i18n:getText("action_enablePalletSpawning"))
	end
end
