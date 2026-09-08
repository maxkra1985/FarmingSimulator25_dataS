WorkArea = {}
WorkArea.WORK_AREA_XML_KEY = "vehicle.workAreas.workArea(?)"
WorkArea.WORK_AREA_XML_CONFIG_KEY = "vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(?).workArea(?)"
function WorkArea.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("default", false, false, false)
	g_workAreaTypeManager:addWorkAreaType("auxiliary", false, false, false)
	g_vehicleConfigurationManager:addConfigurationType("workArea", g_i18n:getText("configuration_workArea"), "workAreas", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("WorkArea")
	WorkArea.registerWorkAreaXMLPaths(v1_, WorkArea.WORK_AREA_XML_KEY)
	WorkArea.registerWorkAreaXMLPaths(v1_, WorkArea.WORK_AREA_XML_CONFIG_KEY)
	v1_:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#workAreaIndex", "Work area index")
	v1_:setXMLSpecializationType()
end

function WorkArea.registerWorkAreaXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Work area type", "DEFAULT")
	schema:register(XMLValueType.BOOL, basePath .. "#requiresGroundContact", "Requires ground contact to work", true)
	schema:register(XMLValueType.BOOL, basePath .. "#disableBackwards", "Area is disabled while driving backwards", true)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresOwnedFarmland", "Requires owned farmland", true)
	schema:register(XMLValueType.STRING, basePath .. "#functionName", "Work area script function")
	schema:register(XMLValueType.STRING, basePath .. "#preprocessFunctionName", "Pre process work area script function")
	schema:register(XMLValueType.STRING, basePath .. "#postprocessFunctionName", "Post process work area script function")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Height node")
	schema:register(XMLValueType.INT, basePath .. ".groundReferenceNode#index", "Ground reference node index")
	schema:register(XMLValueType.BOOL, basePath .. ".onlyActiveWhenLowered#value", "Work area is only active when lowered", false)
end

function WorkArea.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(GroundReference, specializations)
end

function WorkArea.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartWorkAreaProcessing")
	SpecializationUtil.registerEvent(vehicleType, "onEndWorkAreaProcessing")
end

function WorkArea.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWorkAreaFromXML", WorkArea.loadWorkAreaFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getWorkAreaByIndex", WorkArea.getWorkAreaByIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaActive", WorkArea.getIsWorkAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "updateWorkAreaWidth", WorkArea.updateWorkAreaWidth)
	SpecializationUtil.registerFunction(vehicleType, "getWorkAreaWidth", WorkArea.getWorkAreaWidth)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaProcessing", WorkArea.getIsWorkAreaProcessing)
	SpecializationUtil.registerFunction(vehicleType, "getTypedNetworkAreas", WorkArea.getTypedNetworkAreas)
	SpecializationUtil.registerFunction(vehicleType, "getTypedWorkAreas", WorkArea.getTypedWorkAreas)
	SpecializationUtil.registerFunction(vehicleType, "getIsTypedWorkAreaActive", WorkArea.getIsTypedWorkAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsFarmlandNotOwnedWarningShown", WorkArea.getIsFarmlandNotOwnedWarningShown)
	SpecializationUtil.registerFunction(vehicleType, "getLastTouchedFarmlandFarmId", WorkArea.getLastTouchedFarmlandFarmId)
	SpecializationUtil.registerFunction(vehicleType, "getIsAccessibleAtWorldPosition", WorkArea.getIsAccessibleAtWorldPosition)
	SpecializationUtil.registerFunction(vehicleType, "updateLastWorkedArea", WorkArea.updateLastWorkedArea)
	SpecializationUtil.registerFunction(vehicleType, "getMissionByWorkArea", WorkArea.getMissionByWorkArea)
	SpecializationUtil.registerFunction(vehicleType, "getAIWorkAreaWidth", WorkArea.getAIWorkAreaWidth)
end

function WorkArea.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", WorkArea.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", WorkArea.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "checkMovingPartDirtyUpdateNode", WorkArea.checkMovingPartDirtyUpdateNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getImplementAllowAutomaticSteering", WorkArea.getImplementAllowAutomaticSteering)
end

function WorkArea.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkArea)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkArea)
end

-- Local values: spec, configurationId, configKey, i, key, workArea, _, area
function WorkArea:onLoad(savegame)
	local v10_ = self.spec_workArea
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#startIndex", "vehicle.workAreas.workArea(0).area#startIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#widthIndex", "vehicle.workAreas.workArea(0).area#widthIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#heightIndex", "vehicle.workAreas.workArea(0).area#heightIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#foldMinLimit", "vehicle.workAreas.workArea(0).folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#foldMaxLimit", "vehicle.workAreas.workArea(0).folding#maxLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#refNodeIndex", "vehicle.workAreas.workArea(0).groundReferenceNode#index")
	local v11_ = Utils.getNoNil(self.configurations.workArea, 1)
	local v12_ = string.format("vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(%d)", v11_ - 1)
	local v13_ = not self.xmlFile:hasProperty(v12_) and "vehicle.workAreas" or v12_
	v10_.workAreas = {}
	local v14_ = 0
	while true do
		local v15_ = string.format("%s.workArea(%d)", v13_, v14_)
		if not self.xmlFile:hasProperty(v15_) then
			break
		end
		local v16_ = {}
		if self:loadWorkAreaFromXML(v16_, self.xmlFile, v15_) then
			local v17_ = v10_.workAreas
			table.insert(v17_, v16_)
			v16_.index = #v10_.workAreas
			self:updateWorkAreaWidth(v16_.index)
		end
		v14_ = v14_ + 1
	end
	v10_.workAreaByType = {}
	for _, v18_ in pairs(v10_.workAreas) do
		if v10_.workAreaByType[v18_.type] == nil then
			v10_.workAreaByType[v18_.type] = {}
		end
		local v19_ = v10_.workAreaByType[v18_.type]
		table.insert(v19_, v18_)
	end
	v10_.lastAccessedFarmlandOwner = 0
	v10_.lastWorkedArea = -1
	v10_.showFarmlandNotOwnedWarning = false
	v10_.warningCantUseMissionVehiclesOnOtherLand = g_i18n:getText("warning_cantUseMissionVehiclesOnOtherLand")
	v10_.warningYouDontHaveAccessToThisLand = g_i18n:getText("warning_youDontHaveAccessToThisLand")
end

-- Local values: farmlandId, landOwner, accessible
function WorkArea:getIsAccessibleAtWorldPosition(farmId, x, z, workAreaType)
	if self.propertyState == VehiclePropertyState.MISSION then
		return g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, self), farmId, true
	end
	local v25_ = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
	if v25_ == nil then
		return false, nil, false
	end
	if v25_ == FarmlandManager.NOT_BUYABLE_FARM_ID then
		return false, FarmlandManager.NO_OWNER_FARM_ID, false
	end
	local v26_ = g_farmlandManager:getFarmlandOwner(v25_)
	return v26_ ~= 0 and g_currentMission.accessHandler:canFarmAccessOtherId(farmId, v26_) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, self), v26_, true
end

-- Local values: spec
function WorkArea:updateLastWorkedArea(area)
	local v29_ = self.spec_workArea
	local v30_ = v29_.lastWorkedArea
	v29_.lastWorkedArea = math.max(area, v30_)
end

-- Local values: spec
function WorkArea:getLastTouchedFarmlandFarmId()
	local v32_ = self.spec_workArea
	return v32_.lastAccessedFarmlandOwner == 0 and 0 or v32_.lastAccessedFarmlandOwner
end

-- Local values: spec, hasProcessed, farmId, isOwned, isBuyable, allowWarning, i, workArea, isAreaActive, xs, _, zs, isAccessible, farmlandOwner, buyable, xw, _, zw, xh, _, zh, x, z, realArea, _, statsFarmId, ha
function WorkArea:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v36_ = self.spec_workArea
	SpecializationUtil.raiseEvent(self, "onStartWorkAreaProcessing", dt, v36_.workAreas)
	v36_.showFarmlandNotOwnedWarning = false
	local v37_ = false
	local v38_ = self:getActiveFarm()
	if v38_ == nil then
		v38_ = AccessHandler.EVERYONE
	end
	local v39_ = false
	local v40_ = false
	local v41_ = false
	for v42_ = 1, #v36_.workAreas do
		local v43_ = v36_.workAreas[v42_]
		if v43_.type ~= WorkAreaType.AUXILIARY then
			v43_.lastWorkedHectares = 0
			local v44_ = self:getIsWorkAreaActive(v43_)
			if v44_ and v43_.requiresOwnedFarmland then
				local v45_, _, v46_ = getWorldTranslation(v43_.start)
				local v47_, v48_, v49_ = self:getIsAccessibleAtWorldPosition(v38_, v45_, v46_, v43_.type)
				v39_ = v39_ or v49_
				if v47_ then
					if v48_ == nil then
						v40_ = true
					else
						v36_.lastAccessedFarmlandOwner = v48_
						v40_ = true
					end
				else
					local v50_, _, v51_ = getWorldTranslation(v43_.width)
					local v52_, _, v53_ = self:getIsAccessibleAtWorldPosition(v38_, v50_, v51_, v43_.type)
					v39_ = v39_ or v53_
					if v52_ then
						v40_ = true
					else
						local v54_, _, v55_ = getWorldTranslation(v43_.height)
						local v56_, _, v57_ = self:getIsAccessibleAtWorldPosition(v38_, v54_, v55_, v43_.type)
						v39_ = v39_ or v57_
						if v56_ then
							v40_ = true
						else
							local v58_, _, v59_ = self:getIsAccessibleAtWorldPosition(v38_, v50_ + (v54_ - v45_), v51_ + (v55_ - v46_), v43_.type)
							v39_ = v39_ or v59_
							if v58_ then
								v40_ = true
							end
						end
					end
				end
				if not v40_ then
					v44_ = false
				end
				v41_ = v39_
			end
			if v44_ then
				if v43_.preprocessingFunction ~= nil then
					v43_.preprocessingFunction(self, v43_, dt)
				end
				if v43_.processingFunction ~= nil then
					local v60_, _ = v43_.processingFunction(self, v43_, dt)
					if v60_ > 0 then
						v43_.lastWorkedHectares = MathUtil.areaToHa(v60_, g_currentMission:getFruitPixelsToSqm())
						v43_.lastProcessingTime = g_currentMission.time
					else
						v43_.lastWorkedHectares = 0
					end
				end
				if v43_.postprocessingFunction ~= nil then
					v43_.postprocessingFunction(self, v43_, dt)
				end
				v37_ = true
			end
		end
	end
	if v41_ and (not v40_ and isActiveForInput) then
		v36_.showFarmlandNotOwnedWarning = true
		if self.propertyState == VehiclePropertyState.MISSION then
			g_currentMission:showBlinkingWarning(v36_.warningCantUseMissionVehiclesOnOtherLand)
		else
			g_currentMission:showBlinkingWarning(v36_.warningYouDontHaveAccessToThisLand)
		end
	end
	SpecializationUtil.raiseEvent(self, "onEndWorkAreaProcessing", dt, v37_)
	if v36_.lastWorkedArea >= 0 then
		local v61_ = self:getLastTouchedFarmlandFarmId()
		local v62_ = MathUtil.areaToHa(v36_.lastWorkedArea, g_currentMission:getFruitPixelsToSqm())
		g_farmManager:updateFarmStats(v61_, "workedHectares", v62_)
		g_farmManager:updateFarmStats(v61_, "workedTime", dt / 60000)
		v36_.lastWorkedArea = -1
	end
end

-- Local values: start, width, height, areaTypeStr, groundReferenceNodeIndex, groundReferenceNode
function WorkArea:loadWorkAreaFromXML(workArea, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#startIndex", key .. ".area#startNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#widthIndex", key .. ".area#widthNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#heightIndex", key .. ".area#heightNode")
	local v67_ = xmlFile:getValue(key .. ".area#startNode", workArea.start, self.components, self.i3dMappings)
	local v68_ = xmlFile:getValue(key .. ".area#widthNode", workArea.width, self.components, self.i3dMappings)
	local v69_ = xmlFile:getValue(key .. ".area#heightNode", workArea.height, self.components, self.i3dMappings)
	if v67_ == nil or (v68_ == nil or v69_ == nil) then
		return false
	end
	if calcDistanceFrom(v67_, v68_) < 0.001 then
		Logging.xmlError(xmlFile, "\'start\' and \'width\' have the same position for \'%s\'!", key)
		return false
	end
	if calcDistanceFrom(v68_, v69_) < 0.001 then
		Logging.xmlError(xmlFile, "\'width\' and \'height\' have the same position for \'%s\'!", key)
		return false
	end
	local v70_ = xmlFile:getValue(key .. "#type")
	workArea.type = g_workAreaTypeManager:getWorkAreaTypeIndexByName(v70_) or WorkAreaType.DEFAULT
	if workArea.type == nil then
		Logging.xmlWarning(xmlFile, "Invalid workArea type \'%s\' for workArea \'%s\'!", v70_, key)
		return false
	end
	workArea.requiresGroundContact = xmlFile:getValue(key .. "#requiresGroundContact", true)
	if workArea.type ~= WorkAreaType.AUXILIARY then
		if workArea.requiresGroundContact then
			XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#refNodeIndex", key .. ".groundReferenceNode#index")
			local v71_ = xmlFile:getValue(key .. ".groundReferenceNode#index")
			if v71_ == nil then
				Logging.xmlWarning(xmlFile, "Missing groundReference \'groundReferenceNode#index\' for workArea \'%s\'. Add requiresGroundContact=\"false\" if groundContact is not required!", key)
				return false
			end
			local v72_ = self:getGroundReferenceNodeFromIndex(v71_)
			if v72_ == nil then
				Logging.xmlWarning(xmlFile, "Invalid groundReferenceNode-index for workArea \'%s\'!", key)
				return false
			end
			workArea.groundReferenceNode = v72_
		end
		workArea.disableBackwards = xmlFile:getValue(key .. "#disableBackwards", true)
		workArea.onlyActiveWhenLowered = xmlFile:getValue(key .. ".onlyActiveWhenLowered#value", false)
		workArea.functionName = xmlFile:getValue(key .. "#functionName")
		if workArea.functionName == nil then
			Logging.xmlWarning(xmlFile, "Missing \'functionName\' for workArea \'%s\'!", key)
			return false
		end
		if self[workArea.functionName] == nil then
			local v73_ = Logging.xmlWarning
			local v74_ = workArea.functionName
			v73_(xmlFile, "Given functionName \'%s\' not defined. Please add missing function or specialization!", (tostring(v74_)))
			return false
		end
		workArea.processingFunction = self[workArea.functionName]
		if g_isDevelopmentVersion and (not SpecializationUtil.hasSpecialization(Cutter, self.specializations) and (not SpecializationUtil.hasSpecialization(Pickup, self.specializations) and (not SpecializationUtil.hasSpecialization(Drivable, self.specializations) and xmlFile:getString(key .. ".onlyActiveWhenLowered#value") == nil))) then
			Logging.xmlDevWarning(xmlFile, "Work area has no \'onlyActiveWhenLowered\' attribute set! \'%s\'", key)
		end
		workArea.preprocessFunctionName = xmlFile:getValue(key .. "#preprocessFunctionName")
		if workArea.preprocessFunctionName ~= nil then
			if self[workArea.preprocessFunctionName] == nil then
				local v75_ = Logging.xmlWarning
				local v76_ = workArea.preprocessFunctionName
				v75_(xmlFile, "Given preprocessFunctionName \'%s\' not defined. Please add missing function or specialization!", (tostring(v76_)))
				return false
			end
			workArea.preprocessingFunction = self[workArea.preprocessFunctionName]
		end
		workArea.postprocessFunctionName = xmlFile:getValue(key .. "#postprocessFunctionName")
		if workArea.postprocessFunctionName ~= nil then
			if self[workArea.postprocessFunctionName] == nil then
				local v77_ = Logging.xmlWarning
				local v78_ = workArea.postprocessFunctionName
				v77_(xmlFile, "Given postprocessFunctionName \'%s\' not defined. Please add missing function or specialization!", (tostring(v78_)))
				return false
			end
			workArea.postprocessingFunction = self[workArea.postprocessFunctionName]
		end
		workArea.requiresOwnedFarmland = xmlFile:getValue(key .. "#requiresOwnedFarmland", true)
	end
	workArea.lastProcessingTime = 0
	workArea.start = v67_
	workArea.width = v68_
	workArea.height = v69_
	workArea.workWidth = -1
	return true
end

-- Local values: spec
function WorkArea:getWorkAreaByIndex(workAreaIndex)
	return self.spec_workArea.workAreas[workAreaIndex]
end

function WorkArea:getIsWorkAreaActive(workArea)
	if workArea.requiresGroundContact == true and (workArea.groundReferenceNode ~= nil and not self:getIsGroundReferenceNodeActive(workArea.groundReferenceNode)) then
		return false
	elseif workArea.disableBackwards and self.movingDirection <= 0 then
		return false
	else
		return (not workArea.onlyActiveWhenLowered or (self.getIsLowered == nil or self:getIsLowered(false))) and true or false
	end
end

-- Local values: spec, workArea, x1, _, _, x2, _, _, x3, _, _
function WorkArea:updateWorkAreaWidth(workAreaIndex)
	local v85_ = self.spec_workArea.workAreas[workAreaIndex]
	if v85_ ~= nil then
		local v86_, _, _ = localToLocal(self.components[1].node, v85_.start, 0, 0, 0)
		local v87_, _, _ = localToLocal(self.components[1].node, v85_.width, 0, 0, 0)
		local v88_, _, _ = localToLocal(self.components[1].node, v85_.height, 0, 0, 0)
		v85_.workWidth = math.max(v86_, v87_, v88_) - math.min(v86_, v87_, v88_)
	end
end

-- Local values: spec
function WorkArea:getWorkAreaWidth(workAreaIndex)
	return self.spec_workArea.workAreas[workAreaIndex].workWidth
end

function WorkArea:getIsWorkAreaProcessing(workArea)
	return workArea.lastProcessingTime + 200 >= g_currentMission.time
end

-- Local values: workAreasSend, area, typedWorkAreas, showFarmlandNotOwnedWarning, _, workArea, x, _, z, isAccessible, farmId, x1, _, z1, x2, _, z2
function WorkArea:getTypedNetworkAreas(areaType, needsFieldProperty)
	local v95_ = self:getTypedWorkAreas(areaType)
	local v96_ = 0
	local v97_ = {}
	local v98_ = false
	for _, v99_ in pairs(v95_) do
		if self:getIsWorkAreaActive(v99_) then
			local v100_, _, v101_ = getWorldTranslation(v99_.start)
			local v102_
			if needsFieldProperty then
				local v103_ = g_currentMission:getFarmId()
				v102_ = g_currentMission.accessHandler:canFarmAccessLand(v103_, v100_, v101_) or g_missionManager:getIsMissionWorkAllowed(v103_, v100_, v101_, areaType, self)
			else
				v102_ = not needsFieldProperty
			end
			if v102_ then
				local v104_, _, v105_ = getWorldTranslation(v99_.width)
				local v106_, _, v107_ = getWorldTranslation(v99_.height)
				local v108_ = (v105_ - v101_) * (v106_ - v100_) - (v104_ - v100_) * (v107_ - v101_)
				v96_ = v96_ + math.abs(v108_)
				table.insert(v97_, {
					v100_,
					v101_,
					v104_,
					v105_,
					v106_,
					v107_
				})
			else
				v98_ = true
			end
		end
	end
	return v97_, v98_, v96_
end

-- Local values: spec, workAreas
function WorkArea:getTypedWorkAreas(areaType)
	local v111_ = self.spec_workArea.workAreaByType[areaType]
	return v111_ == nil and {} or v111_
end

-- Local values: isActive, typedWorkAreas, _, workArea
function WorkArea:getIsTypedWorkAreaActive(areaType)
	local v114_ = self:getTypedWorkAreas(areaType)
	local v115_ = false
	for _, v116_ in pairs(v114_) do
		if self:getIsWorkAreaActive(v116_) then
			return true, v114_
		end
	end
	return v115_, v114_
end

-- Local values: x, _, z, mission
function WorkArea:getMissionByWorkArea(workArea)
	if workArea == nil then
		return nil
	else
		local v118_, _, v119_ = getWorldTranslation(workArea.start)
		local v120_ = g_missionManager:getMissionAtWorldPosition(v118_, v119_)
		if v120_ == nil then
			local v121_, _, v122_ = getWorldTranslation(workArea.width)
			local v123_ = g_missionManager:getMissionAtWorldPosition(v121_, v122_)
			if v123_ == nil then
				local v124_, _, v125_ = getWorldTranslation(workArea.height)
				local v126_ = g_missionManager:getMissionAtWorldPosition(v124_, v125_)
				if v126_ == nil then
					return nil
				else
					return v126_
				end
			else
				return v123_
			end
		else
			return v120_
		end
	end
end

-- Local values: workingWidth, _, workArea
function WorkArea:getAIWorkAreaWidth()
	local v128_ = 0
	for _, v129_ in pairs(self.spec_workArea.workAreas) do
		if g_workAreaTypeManager:getWorkAreaTypeIsAIArea(v129_.type) then
			local v130_ = v129_.workWidth
			v128_ = math.max(v130_, v128_)
		end
	end
	return v128_
end

function WorkArea:getIsFarmlandNotOwnedWarningShown()
	return self.spec_workArea.showFarmlandNotOwnedWarning
end

function WorkArea:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")
	return true
end

-- Local values: spec, workArea
function WorkArea:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.workAreaIndex ~= nil then
		local v140_ = self.spec_workArea
		if v140_.workAreas[speedRotatingPart.workAreaIndex] == nil then
			speedRotatingPart.workAreaIndex = nil
			local v141_ = Logging.xmlWarning
			local v142_ = self.xmlFile
			local v143_ = speedRotatingPart.workAreaIndex
			v141_(v142_, "Invalid workAreaIndex \'%s\'. Indexing starts with 1!", (tostring(v143_)))
			return true
		end
		if not self:getIsWorkAreaProcessing(v140_.workAreas[speedRotatingPart.workAreaIndex]) then
			return false
		end
	end
	return superFunc(self, speedRotatingPart)
end

-- Local values: spec, i, workArea
function WorkArea:checkMovingPartDirtyUpdateNode(superFunc, node, movingPart)
	superFunc(self, node, movingPart)
	local v148_ = self.spec_workArea
	for v149_ = 1, #v148_.workAreas do
		local v150_ = v148_.workAreas[v149_]
		if node == v150_.start or (node == v150_.width or node == v150_.height) then
			Logging.xmlError(self.xmlFile, "Found work area node \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
		end
		if v150_.groundReferenceNode ~= nil and node == v150_.groundReferenceNode.node then
			Logging.xmlError(self.xmlFile, "Found ground reference node \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
		end
	end
end

-- Local values: spec, _, workArea
function WorkArea:getImplementAllowAutomaticSteering(superFunc)
	local v153_ = self.spec_workArea
	for _, v154_ in ipairs(v153_.workAreas) do
		if g_workAreaTypeManager:getWorkAreaTypeIsSteeringAssistArea(v154_.type) then
			return true
		end
	end
	return superFunc(self)
end
