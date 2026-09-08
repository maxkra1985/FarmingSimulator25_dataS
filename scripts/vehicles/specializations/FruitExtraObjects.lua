FruitExtraObjects = {}

function FruitExtraObjects.prerequisitesPresent(self)
	return true
end
function FruitExtraObjects.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("FruitExtraObjects")
	FruitExtraObjects.registerXMLPaths(v1_, "vehicle.cutter.fruitExtraObjects")
	FruitExtraObjects.registerXMLPaths(v1_, "vehicle.mower.fruitExtraObjects")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).fruitExtraObjects#lastFruitType", "Name of last fruit type")
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).fruitExtraObjects#lastFillType", "Name of last fill type")
end

function FruitExtraObjects.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fruitExtraObject(?)#node", "Name of fruit type converter")
	schema:register(XMLValueType.STRING, basePath .. ".fruitExtraObject(?)#animationName", "Change animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".fruitExtraObject(?)#animationSpeed", "Speed of the animation", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".fruitExtraObject(?)#isDefault", "Is default active", false)
	schema:register(XMLValueType.STRING, basePath .. ".fruitExtraObject(?)#fruitType", "Name of fruit type")
	schema:register(XMLValueType.STRING, basePath .. ".fruitExtraObject(?)#fillType", "Name of fill type")
	schema:register(XMLValueType.BOOL, basePath .. "#hideOnDetach", "Hide extra objects on detach", false)
	schema:register(XMLValueType.BOOL, basePath .. "#hideOnMount", "Hide extra objects when mounted to a header trailer", false)
end

function FruitExtraObjects.registerFunctions(self)
	SpecializationUtil.registerFunction(vehicleType, "loadFruitExtraObjectFromXML", FruitExtraObjects.loadFruitExtraObjectFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getFruitExtraObjectTypeData", FruitExtraObjects.getFruitExtraObjectTypeData)
	SpecializationUtil.registerFunction(vehicleType, "updateFruitExtraObjects", FruitExtraObjects.updateFruitExtraObjects)
end

function FruitExtraObjects.registerOverwrittenFunctions(self) end

function FruitExtraObjects.registerEventListeners(self)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FruitExtraObjects)
	SpecializationUtil.registerEventListener(vehicleType, "onDynamicMountTypeChanged", FruitExtraObjects)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", FruitExtraObjects)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", FruitExtraObjects)
end

-- Local values: spec, _, key, extraObject, _, key, extraObject, lastFruitTypeName, lastFillTypeName
function FruitExtraObjects:onPostLoad(savegame)
	local v9_ = self.spec_fruitExtraObjects
	if self.isClient then
		v9_.defaultExtraObject = nil
		v9_.extraObjects = {}
		for _, v10_ in self.xmlFile:iterator("vehicle.cutter.fruitExtraObjects.fruitExtraObject") do
			local v11_ = {}
			if self:loadFruitExtraObjectFromXML(self.xmlFile, v10_, v11_) then
				if v11_.isDefault then
					v9_.defaultExtraObject = v11_
					v11_.index = 0
				else
					local v12_ = v9_.extraObjects
					table.insert(v12_, v11_)
					v11_.index = #v9_.extraObjects
				end
			end
		end
		for _, v13_ in self.xmlFile:iterator("vehicle.mower.fruitExtraObjects.fruitExtraObject") do
			local v14_ = {}
			if self:loadFruitExtraObjectFromXML(self.xmlFile, v13_, v14_) then
				if v14_.isDefault then
					v9_.defaultExtraObject = v14_
					v14_.index = 0
				else
					local v15_ = v9_.extraObjects
					table.insert(v15_, v14_)
					v14_.index = #v9_.extraObjects
				end
			end
		end
		v9_.hideExtraObjectsOnDetach = self.xmlFile:getValue("vehicle.cutter.fruitExtraObjects#hideOnDetach", self.xmlFile:getValue("vehicle.mower.fruitExtraObjects#hideOnDetach", false))
		v9_.hideExtraObjectsOnMount = self.xmlFile:getValue("vehicle.cutter.fruitExtraObjects#hideOnMount", self.xmlFile:getValue("vehicle.mower.fruitExtraObjects#hideOnMount", false))
		v9_.currentExtraObject = nil
		v9_.lastFruitType = nil
		v9_.lastFillType = nil
		if savegame ~= nil and not savegame.resetVehicles then
			local v16_ = savegame.xmlFile:getValue(savegame.key .. ".fruitExtraObjects#lastFruitType")
			if v16_ ~= nil then
				v9_.lastFruitType = g_fruitTypeManager:getFruitTypeIndexByName(v16_)
			end
			local v17_ = savegame.xmlFile:getValue(savegame.key .. ".fruitExtraObjects#lastFillType")
			if v17_ ~= nil then
				v9_.lastFillType = g_fillTypeManager:getFillTypeIndexByName(v17_)
			end
		end
		self:updateFruitExtraObjects()
	end
	if not self.isClient or #v9_.extraObjects == 0 and v9_.defaultExtraObject == nil then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", FruitExtraObjects)
		SpecializationUtil.removeEventListener(self, "onDynamicMountTypeChanged", FruitExtraObjects)
		SpecializationUtil.removeEventListener(self, "onPreAttach", FruitExtraObjects)
		SpecializationUtil.removeEventListener(self, "onPostDetach", FruitExtraObjects)
	end
end

-- Local values: spec
function FruitExtraObjects:saveToXMLFile(xmlFile, key, usedModNames)
	local v21_ = self.spec_fruitExtraObjects
	if v21_.lastFruitType ~= nil then
		xmlFile:setValue(key .. "#lastFruitType", g_fruitTypeManager:getFruitTypeNameByIndex(v21_.lastFruitType))
	end
	if v21_.lastFillType ~= nil then
		xmlFile:setValue(key .. "#lastFillType", g_fillTypeManager:getFillTypeNameByIndex(v21_.lastFillType))
	end
end

function FruitExtraObjects:onDynamicMountTypeChanged(dynamicMountType, mountObject)
	self:updateFruitExtraObjects()
end

function FruitExtraObjects:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:updateFruitExtraObjects()
end

function FruitExtraObjects:onPostDetach(attacherVehicle, implement)
	self:updateFruitExtraObjects()
end

-- Local values: fruitTypeName, fruitTypeIndex, fillTypeName, fillTypeIndex
function FruitExtraObjects:loadFruitExtraObjectFromXML(xmlFile, key, extraObject)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#anim", key .. "#animationName")
	extraObject.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if extraObject.node ~= nil then
		setVisibility(extraObject.node, false)
	end
	extraObject.animationName = xmlFile:getValue(key .. "#animationName")
	if extraObject.node ~= nil or extraObject.animationName ~= nil then
		extraObject.isDefault = xmlFile:getValue(key .. "#isDefault", false)
		extraObject.animationSpeed = xmlFile:getValue(key .. "#animationSpeed", 1)
		local v29_ = self.xmlFile:getValue(key .. "#fruitType")
		if v29_ ~= nil then
			local v30_ = g_fruitTypeManager:getFruitTypeIndexByName(string.upper(v29_))
			if v30_ ~= nil then
				extraObject.fruitType = v30_
			end
		end
		local v31_ = self.xmlFile:getValue(key .. "#fillType")
		if v31_ ~= nil then
			local v32_ = g_fillTypeManager:getFillTypeIndexByName(string.upper(v31_))
			if v32_ ~= nil then
				extraObject.fillType = v32_
			end
		end
		if extraObject.fruitType == nil and (extraObject.fillType == nil and not extraObject.isDefault) then
			Logging.xmlWarning(xmlFile, "Missing fruitType/fillType or isDefault attribute for \'%s\'", key)
			return false
		end
		if (extraObject.fruitType ~= nil or extraObject.fillType ~= nil) and extraObject.isDefault then
			Logging.xmlWarning(xmlFile, "FruitType/fillType and isDefault attribute are defined for \'%s\'. Only one is allowed!", key)
			return false
		end
	end
	return true
end

function FruitExtraObjects.getFruitExtraObjectTypeData(self)
	return nil, nil
end

-- Local values: spec, extraObject, fruitType, fillType, _, _extraObject
function FruitExtraObjects:updateFruitExtraObjects()
	local v34_ = self.spec_fruitExtraObjects
	local _ = v34_.currentExtraObject
	local v35_, v36_ = self:getFruitExtraObjectTypeData()
	if (v35_ == nil or v35_ == FruitType.UNKNOWN) and v34_.lastFruitType ~= nil then
		v35_ = v34_.lastFruitType
	end
	v34_.lastFruitType = v35_
	if (v36_ == nil or v36_ == FillType.UNKNOWN) and v34_.lastFillType ~= nil then
		v36_ = v34_.lastFillType
	end
	v34_.lastFillType = v36_
	local v37_ = v34_.defaultExtraObject
	for _, v38_ in ipairs(v34_.extraObjects) do
		if v35_ ~= nil and v38_.fruitType == v35_ or v36_ ~= nil and v38_.fillType == v36_ then
			v37_ = v38_
			break
		end
	end
	if v34_.hideExtraObjectsOnDetach and (self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil) then
		v37_ = nil
	end
	if v34_.hideExtraObjectsOnMount and self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
		v37_ = nil
	end
	if v37_ ~= v34_.currentExtraObject then
		if v34_.currentExtraObject ~= nil then
			if v34_.currentExtraObject.node ~= nil then
				setVisibility(v34_.currentExtraObject.node, false)
			end
			if v34_.currentExtraObject.animationName ~= nil and self.playAnimation ~= nil then
				self:playAnimation(v34_.currentExtraObject.animationName, -v34_.currentExtraObject.animationSpeed, self:getAnimationTime(v34_.currentExtraObject.animationName), true)
			end
			v34_.currentExtraObject = nil
		end
		if v37_ ~= nil then
			if v37_.node ~= nil then
				setVisibility(v37_.node, true)
			end
			if v37_.animationName ~= nil and self.playAnimation ~= nil then
				self:playAnimation(v37_.animationName, v37_.animationSpeed, self:getAnimationTime(v37_.animationName), true)
				if not self.finishedLoading then
					AnimatedVehicle.updateAnimationByName(self, v37_.animationName, 9999999, true)
				end
			end
			v34_.currentExtraObject = v37_
		end
	end
end
