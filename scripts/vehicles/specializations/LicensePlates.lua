LicensePlates = {}

function LicensePlates.prerequisitesPresent(specializations)
	return true
end
function LicensePlates.initSpecialization()
	g_storeManager:addSpecType("licensePlate", "shopListAttributeIconLicensePlate", LicensePlates.loadSpecValuePlateText, LicensePlates.getSpecValuePlateText, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("LicensePlates")
	v1_:register(XMLValueType.STRING, "vehicle.licensePlates#defaultPlacement", "Defines the default placement index independent of map setting (NONE|BOTH|BACK_ONLY)", false)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.licensePlates.licensePlate(?)#node", "License plate node")
	v1_:register(XMLValueType.STRING, "vehicle.licensePlates.licensePlate(?)#preferedType", "Prefered license plate type to be placed if available")
	v1_:register(XMLValueType.STRING, "vehicle.licensePlates.licensePlate(?)#placementArea", "Defines the available area around the node (top, right, bottom, left) (\'-\' means unlimited)")
	v1_:register(XMLValueType.STRING, "vehicle.licensePlates.licensePlate(?)#position", "Position of license plate (\'FRONT\' or \'BACK\')", "ANY")
	v1_:register(XMLValueType.BOOL, "vehicle.licensePlates.licensePlate(?)#frame", "License plate with frame of without frame", true)
	ObjectChangeUtil.registerObjectChangeXMLPaths(v1_, "vehicle.licensePlates.licensePlate(?)")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).licensePlates#variation", "License plate variation", 1)
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).licensePlates#characters", "Characters string")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).licensePlates#colorIndex", "Selected color index", 1)
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).licensePlates#placementIndex", "Selected placement index", 1)
end

function LicensePlates.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setLicensePlatesData", LicensePlates.setLicensePlatesData)
	SpecializationUtil.registerFunction(vehicleType, "getLicensePlatesData", LicensePlates.getLicensePlatesData)
	SpecializationUtil.registerFunction(vehicleType, "getLicensePlatesDataIsEqual", LicensePlates.getLicensePlatesDataIsEqual)
	SpecializationUtil.registerFunction(vehicleType, "getHasLicensePlates", LicensePlates.getHasLicensePlates)
	SpecializationUtil.registerFunction(vehicleType, "getLicensePlateDialogSettings", LicensePlates.getLicensePlateDialogSettings)
end

function LicensePlates.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LicensePlates)
end

-- Local values: spec, defaultPlacementName, i, plateKey, licensePlate, preferedTypeStr, placementAreaString, placementArea, j, numberValue, positionStr, includeFrame, widthPos, widthNeg, heightPos, heightNeg, scaleFactorWidth, scaleFactorHeight, minFactor, moveX, moveY
function LicensePlates:onLoad(savegame)
	local v6_ = self.spec_licensePlates
	v6_.licensePlates = {}
	local v7_ = self.xmlFile:getValue("vehicle.licensePlates#defaultPlacement")
	if v7_ ~= nil then
		v6_.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION[string.upper(v7_)]
		if v6_.defaultPlacementIndex == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown defaultPlacement \'%s\' in \'vehicle.licensePlates#defaultPlacement", v7_)
		end
	end
	if g_licensePlateManager:getAreLicensePlatesAvailable() then
		local v8_ = 0
		while true do
			local v9_ = string.format("vehicle.licensePlates.licensePlate(%d)", v8_)
			if not self.xmlFile:hasProperty(v9_) then
				break
			end
			local v10_ = {
				["node"] = self.xmlFile:getValue(v9_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v10_.node ~= nil then
				local v11_ = self.xmlFile:getValue(v9_ .. "#preferedType", "ELONGATED")
				v10_.preferedType = LicensePlateManager.PLATE_TYPE[v11_]
				if v10_.preferedType == nil then
					Logging.xmlError(self.xmlFile, "Unknown preferedType \'%s\' for license plate \'%s\'", v11_, v9_)
				else
					v10_.placementArea = {
						1,
						1,
						1,
						1
					}
					local v12_ = self.xmlFile:getString(v9_ .. "#placementArea")
					if v12_ ~= nil then
						local v13_ = string.split(v12_, " ")
						if #v13_ == 4 then
							for v14_ = 1, 4 do
								if v13_[v14_] ~= "-" then
									local v15_ = v13_[v14_]
									local v16_ = tonumber(v15_)
									if v16_ == nil then
										Logging.xmlWarning(self.xmlFile, "Invalid 4-vector \'%s\' for \'%s\'. \'%s\' is not a number!", v12_, v9_ .. "#placementArea", v13_[v14_])
									else
										v10_.placementArea[v14_] = v16_
									end
								end
							end
						else
							Logging.xmlWarning(self.xmlFile, "Invalid 4-vector \'%s\' for \'%s\' ", v12_, v9_ .. "#placementArea")
						end
					end
					local v17_ = self.xmlFile:getValue(v9_ .. "#position", "ANY")
					v10_.position = LicensePlateManager.PLATE_POSITION[v17_] or LicensePlateManager.PLATE_POSITION.ANY
					local v18_ = self.xmlFile:getValue(v9_ .. "#frame", true)
					v10_.data = g_licensePlateManager:getLicensePlate(v10_.preferedType, v18_)
					if v10_.data ~= nil then
						link(v10_.node, v10_.data.node)
						setTranslation(v10_.data.node, 0, 0, 0)
						setRotation(v10_.data.node, 0, 0, 0)
						setVisibility(v10_.data.node, false)
						local v19_ = v10_.data.rawWidth * 0.5 + v10_.data.widthOffsetLeft
						local v20_ = v10_.data.rawWidth * 0.5 + v10_.data.widthOffsetRight
						local v21_ = v10_.data.rawHeight * 0.5 + v10_.data.heightOffsetTop
						local v22_ = v10_.data.rawHeight * 0.5 + v10_.data.heightOffsetBot
						local v23_ = (v10_.placementArea[2] + v10_.placementArea[4]) / (v19_ + v20_)
						local v24_ = (v10_.placementArea[1] + v10_.placementArea[3]) / (v21_ + v22_)
						local v25_ = math.min(v23_, v24_)
						local v26_ = math.clamp(v25_, 0, 1)
						if v26_ < 1 then
							setScale(v10_.data.node, v26_, v26_, v26_)
							v19_ = v19_ * v26_
							v20_ = v20_ * v26_
							v21_ = v21_ * v26_
							v22_ = v22_ * v26_
						end
						local v27_ = v19_ - v10_.placementArea[2]
						local v28_ = 0 - math.max(v27_, 0)
						local v29_ = v20_ - v10_.placementArea[4]
						local v30_ = v28_ + math.max(v29_, 0)
						local v31_ = v21_ - v10_.placementArea[1]
						local v32_ = 0 - math.max(v31_, 0)
						local v33_ = v22_ - v10_.placementArea[3]
						local v34_ = v32_ + math.max(v33_, 0)
						setTranslation(v10_.data.node, v30_, v34_, 0)
						v10_.changeObjects = {}
						ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, v9_, v10_.changeObjects, self.components, self)
						local v35_ = v6_.licensePlates
						table.insert(v35_, v10_)
					end
				end
			end
			v8_ = v8_ + 1
		end
		if self:getHasLicensePlates() then
			v6_.licensePlateData = {
				["variation"] = 1,
				["characters"] = nil,
				["colorIndex"] = nil
			}
			return
		end
	else
		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.licensePlates.licensePlate", -1, self.components, self)
	end
end

-- Local values: spec, i, variation, characters, colorIndex, placementIndex, characterTbl, characterLength, i
function LicensePlates:onPostLoad(savegame)
	local v38_ = self.spec_licensePlates
	for v39_ = 1, #v38_.licensePlates do
		ObjectChangeUtil.setObjectChanges(v38_.licensePlates[v39_].changeObjects, false, self, self.setMovingToolDirty)
	end
	if savegame ~= nil and self:getHasLicensePlates() then
		local v40_ = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#variation", 1)
		local v41_ = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#characters")
		local v42_ = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#colorIndex", 1)
		local v43_ = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#placementIndex", 1)
		if v40_ ~= nil and (v41_ ~= nil and (v42_ ~= nil and v43_ ~= nil)) then
			local v44_ = {}
			for v45_ = 1, v41_:len() do
				table.insert(v44_, v41_:sub(v45_, v45_))
			end
			v38_.licensePlateData = {
				["variation"] = v40_,
				["characters"] = v44_,
				["colorIndex"] = v42_,
				["placementIndex"] = v43_
			}
			self:setLicensePlatesData(v38_.licensePlateData)
		end
	end
end

-- Local values: spec
function LicensePlates:onDelete(savegame)
	self.spec_licensePlates.licensePlates = {}
end

-- Local values: spec
function LicensePlates:saveToXMLFile(xmlFile, key, usedModNames)
	local v50_ = self.spec_licensePlates
	if self:getHasLicensePlates() and (v50_.licensePlateData and (v50_.licensePlateData.placementIndex ~= LicensePlateManager.PLACEMENT_OPTION.NONE and (v50_.licensePlateData.variation ~= nil and (v50_.licensePlateData.characters ~= nil and v50_.licensePlateData.colorIndex ~= nil)))) then
		xmlFile:setValue(key .. "#variation", v50_.licensePlateData.variation)
		xmlFile:setValue(key .. "#characters", table.concat(v50_.licensePlateData.characters, ""))
		xmlFile:setValue(key .. "#colorIndex", v50_.licensePlateData.colorIndex)
		xmlFile:setValue(key .. "#placementIndex", v50_.licensePlateData.placementIndex)
	end
end

-- Local values: spec
function LicensePlates:onReadStream(streamId, connection)
	local v54_ = self.spec_licensePlates
	v54_.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)
	self:setLicensePlatesData(v54_.licensePlateData)
end

-- Local values: spec
function LicensePlates:onWriteStream(streamId, connection)
	local v58_ = self.spec_licensePlates
	LicensePlateManager.writeLicensePlateData(streamId, connection, v58_.licensePlateData)
end

-- Local values: spec, i, licensePlate, allowLicensePlate, i
function LicensePlates:setLicensePlatesData(licensePlateData)
	local v61_ = self.spec_licensePlates
	if licensePlateData == nil or (licensePlateData.variation == nil or (licensePlateData.characters == nil or (licensePlateData.colorIndex == nil or licensePlateData.placementIndex == nil))) then
		for v62_ = 1, #v61_.licensePlates do
			setVisibility(v61_.licensePlates[v62_].data.node, false)
		end
	else
		for v63_ = 1, #v61_.licensePlates do
			local v64_ = v61_.licensePlates[v63_]
			local v65_ = true
			if licensePlateData.placementIndex == LicensePlateManager.PLACEMENT_OPTION.NONE then
				v65_ = false
			elseif licensePlateData.placementIndex == LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY and v64_.position == LicensePlateManager.PLATE_POSITION.FRONT then
				v65_ = false
			end
			if v65_ then
				v64_.data:updateData(licensePlateData.variation, v64_.position, table.concat(licensePlateData.characters, ""), true)
				v64_.data:setColorIndex(licensePlateData.colorIndex)
				setVisibility(v64_.data.node, true)
			else
				setVisibility(v64_.data.node, false)
			end
			ObjectChangeUtil.setObjectChanges(v64_.changeObjects, v65_, self, self.setMovingToolDirty)
		end
		v61_.licensePlateData = licensePlateData
	end
end

function LicensePlates:getLicensePlatesData()
	return self.spec_licensePlates.licensePlateData
end

-- Local values: ownData, i
function LicensePlates:getLicensePlatesDataIsEqual(data)
	if data == nil or self.spec_licensePlates.licensePlateData == nil then
		return true
	end
	local v69_ = self.spec_licensePlates.licensePlateData
	if data.variation ~= v69_.variation or (data.colorIndex ~= v69_.colorIndex or data.placementIndex ~= v69_.placementIndex) then
		return false
	end
	if data.characters ~= nil and v69_.characters ~= nil then
		if #data.characters ~= #v69_.characters then
			return false
		end
		for v70_ = 1, #data.characters do
			if data.characters[v70_] ~= v69_.characters[v70_] then
				return false
			end
		end
	end
	return true
end

function LicensePlates:getHasLicensePlates()
	return #self.spec_licensePlates.licensePlates > 0
end

-- Local values: spec, hasFrontPlate, i, licensePlate
function LicensePlates:getLicensePlateDialogSettings()
	local v73_ = self.spec_licensePlates
	local v74_ = false
	for v75_ = 1, #v73_.licensePlates do
		if v73_.licensePlates[v75_].position == LicensePlateManager.PLATE_POSITION.FRONT then
			v74_ = true
			break
		end
	end
	return v73_.defaultPlacementIndex, v74_
end

function LicensePlates.loadSpecValuePlateText(xmlFile, customEnvironment, baseDir)
	return nil
end

-- Local values: spec, i, licensePlate
function LicensePlates.getSpecValuePlateText(storeItem, realItem)
	if realItem == nil then
		return nil
	end
	if realItem.getHasLicensePlates == nil or not realItem:getHasLicensePlates() then
		return nil
	end
	local v77_ = realItem.spec_licensePlates
	for v78_ = 1, #v77_.licensePlates do
		local v79_ = v77_.licensePlates[v78_]
		if v79_.position == LicensePlateManager.PLATE_POSITION.BACK or v78_ == #v77_.licensePlates then
			return v79_.data:getFormattedString()
		end
	end
	return nil
end
