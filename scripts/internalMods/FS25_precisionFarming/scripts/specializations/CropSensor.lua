CropSensor = {}
CropSensor.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".cropSensor"
CropSensor.MAX_UPDATES_PER_FRAME = 1
CropSensor.MIN_SENSOR_RADIUS = 5
CropSensor.PATTERN_OCTAGON = {
	{
		0.33,
		0,
		-1,
		-0.33,
		0,
		-1,
		-0.33,
		0,
		-0.33
	},
	{
		1,
		0,
		0.33,
		1,
		0,
		-0.33,
		0.33,
		0,
		-0.33
	},
	{
		-0.33,
		0,
		1,
		0.33,
		0,
		1,
		0.33,
		0,
		0.33
	},
	{
		-1,
		0,
		-0.33,
		-1,
		0,
		0.33,
		-0.33,
		0,
		0.33
	},
	{
		-0.33,
		0,
		1,
		-0.33,
		0,
		-0.33,
		0.33,
		0,
		0.33
	},
	{
		1,
		0,
		0.33,
		-0.33,
		0,
		0.33,
		0.33,
		0,
		-0.33
	}
}
CropSensor.PATTERN_CORNER_LEFT = {
	{
		0,
		0,
		0,
		-0.15,
		0,
		0.33,
		1,
		0,
		0
	},
	{
		0.33,
		0,
		0.33,
		0,
		0,
		0.66,
		0.85,
		0,
		0.33
	},
	{
		-0.15,
		0,
		0.33,
		-0.15,
		0,
		0.66,
		0.33,
		0,
		0.33
	}
}
CropSensor.PATTERN_CORNER_RIGHT = {
	{
		0,
		0,
		0,
		0.15,
		0,
		0.33,
		-1,
		0,
		0
	},
	{
		-0.33,
		0,
		0.33,
		0,
		0,
		0.66,
		-0.85,
		0,
		0.33
	},
	{
		0.15,
		0,
		0.33,
		0.15,
		0,
		0.66,
		-0.33,
		0,
		0.33
	}
}

function CropSensor.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function CropSensor.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("cropSensor", g_i18n:getText("configuration_cropSensor"), "cropSensor", VehicleConfigurationItem)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("CropSensor")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.cropSensor.sensorNode(?)#node", "Sensor Node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.cropSensor.sensorNode(?)#lightNode", "Real light source node")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.cropSensor.sensorNode(?)#staticLight", "Static light shape")
	v2_:register(XMLValueType.FLOAT, "vehicle.cropSensor.sensorNode(?)#radius", "Sensor radius", 18)
	v2_:register(XMLValueType.BOOL, "vehicle.cropSensor.sensorNode(?)#requiresDaylight", "Sensor requires daylight to work", false)
	v2_:register(XMLValueType.STRING, "vehicle.cropSensor.sensorNode(?)#shape", "Sensor shape (CIRCLE | HALF_CIRCLE_LEFT | HALF_CIRCLE_RIGHT)", "CIRCLE")
	CropSensor.registerSensorLinkNodePaths(v2_, "vehicle.cropSensor.cropSensorConfigurations.cropSensorConfiguration(?).sensorLinkNode(?)")
	v2_:setXMLSpecializationType()
end

function CropSensor.registerSensorLinkNodePaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Sensor Node")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Type of node to link (SENSOR_LEFT | SENSOR_RIGHT | SENSOR_TOP)", "SENSOR_LEFT")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Translation offset", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation offset", "0 0 0")
	schema:register(XMLValueType.BOOL, basePath .. ".rotationNode(?)#autoRotate", "Rotation will be automatically adjusted to the vehicle orientation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".rotationNode(?)#rotation", "Rotation of rotation node", "0 0 0")
end

function CropSensor.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setCropSensorActive", CropSensor.setCropSensorActive)
	SpecializationUtil.registerFunction(vehicleType, "updateCropSensorWorkingWidth", CropSensor.updateCropSensorWorkingWidth)
	SpecializationUtil.registerFunction(vehicleType, "updateSensorRadius", CropSensor.updateSensorRadius)
	SpecializationUtil.registerFunction(vehicleType, "updateSensorNode", CropSensor.updateSensorNode)
	SpecializationUtil.registerFunction(vehicleType, "linkCropSensor", CropSensor.linkCropSensor)
end

function CropSensor.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", CropSensor.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseTurnedOnSchema", CropSensor.getUseTurnedOnSchema)
end

function CropSensor.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CropSensor)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", CropSensor)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", CropSensor)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CropSensor)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", CropSensor)
end

-- Local values: spec, baseName, configIndex, configKey, linkData
function CropSensor:onLoad(savegame)
	local v_u_9_ = self[CropSensor.SPEC_TABLE_NAME]
	v_u_9_.sensorNodes = {}
	self.xmlFile:iterate("vehicle.cropSensor.sensorNode", function(_, p10_)
		-- upvalues: (copy) self, (copy) v_u_9_
		local v11_ = {
			["node"] = self.xmlFile:getValue(p10_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v11_.node ~= nil then
			v11_.radius = self.xmlFile:getValue(p10_ .. "#radius", 20)
			v11_.origRadius = v11_.radius
			v11_.requiresDaylight = self.xmlFile:getValue(p10_ .. "#requiresDaylight", false)
			local v12_ = string.upper(self.xmlFile:getValue(p10_ .. "#shape", "CIRCLE"))
			if v12_ == "CIRCLE" then
				v11_.shape = DensityMapCircle.createCircle(0, 0, v11_.radius, 8)
			elseif v12_ == "HALF_CIRCLE_LEFT" then
				v11_.shape = DensityMapPolygon.new()
				for v13_ = -0.5235987755982988, 1.9198621771937625, 0.5235987755982988 do
					v11_.shape:addPolygonPoint(math.cos(v13_), (math.sin(v13_)))
				end
			elseif v12_ == "HALF_CIRCLE_RIGHT" then
				v11_.shape = DensityMapPolygon.new()
				for v14_ = 0.5235987755982988, -1.9198621771937625, -0.5235987755982988 do
					v11_.shape:addPolygonPoint(math.cos(v14_), (math.sin(v14_)))
				end
			end
			if v11_.shape ~= nil then
				v11_.lightNode = self.xmlFile:getValue(p10_ .. "#lightNode", nil, self.components, self.i3dMappings)
				if v11_.lightNode ~= nil then
					setVisibility(v11_.lightNode, false)
				end
				v11_.staticLight = self.xmlFile:getValue(p10_ .. "#staticLight", nil, self.components, self.i3dMappings)
				if v11_.staticLight ~= nil then
					setShaderParameter(v11_.staticLight, "lightIds0", 0, 0, 0, 0, false)
				end
				v11_.index = 1
				local v15_ = v_u_9_.sensorNodes
				table.insert(v15_, v11_)
				return
			end
			Logging.xmlWarning(self.xmlFile, "Invalid sensor shape \'%s\' in \'%s\'", v12_, p10_)
		end
	end)
	v_u_9_.isStandaloneSensor = #v_u_9_.sensorNodes > 0
	v_u_9_.inputActionToggle = InputAction.PRECISIONFARMING_TOGGLE_CROP_SENSOR
	local v16_ = self.configurations.cropSensor
	if v16_ ~= nil then
		local v17_ = string.format("vehicle.cropSensor.cropSensorConfigurations.cropSensorConfiguration(%d)", v16_ - 1)
		v_u_9_.sensorLinkNodeData = {}
		v_u_9_.sensorLinkNodeData.linkNodes = {}
		self.xmlFile:iterate(v17_ .. ".sensorLinkNode", function(_, p18_)
			-- upvalues: (copy) self, (copy) v_u_9_
			local v_u_19_ = {
				["node"] = self.xmlFile:getValue(p18_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v_u_19_.node ~= nil then
				v_u_19_.typeName = string.upper(self.xmlFile:getValue(p18_ .. "#type", "SENSOR_LEFT"))
				v_u_19_.translation = self.xmlFile:getValue(p18_ .. "#translation", "0 0 0", true)
				v_u_19_.rotation = self.xmlFile:getValue(p18_ .. "#rotation", "0 0 0", true)
				v_u_19_.rotationNodes = {}
				self.xmlFile:iterate(p18_ .. ".rotationNode", function(_, p20_)
					-- upvalues: (ref) self, (copy) v_u_19_
					local v21_ = {
						["autoRotate"] = self.xmlFile:getValue(p20_ .. "#autoRotate"),
						["rotation"] = self.xmlFile:getValue(p20_ .. "#rotation", nil, true)
					}
					local v22_ = v_u_19_.rotationNodes
					table.insert(v22_, v21_)
				end)
				local v23_ = v_u_9_.sensorLinkNodeData.linkNodes
				table.insert(v23_, v_u_19_)
			end
		end)
		if #v_u_9_.sensorLinkNodeData.linkNodes > 0 then
			self:linkCropSensor(v_u_9_.sensorLinkNodeData)
		end
		if v16_ > 1 and g_precisionFarming ~= nil then
			local v24_ = g_precisionFarming:getCropSensorLinkageData(self.configFileName)
			if v24_ ~= nil then
				self:linkCropSensor(v24_)
			end
		end
	end
	v_u_9_.isAvailable = #v_u_9_.sensorNodes > 0
	v_u_9_.isActive = false
	v_u_9_.workingWidth = 0
	if v_u_9_.isAvailable then
		v_u_9_.texts = {}
		v_u_9_.texts.toggleCropSensorPos = g_i18n:getText("action_toggleCropSensorPos", self.customEnvironment)
		v_u_9_.texts.toggleCropSensorNeg = g_i18n:getText("action_toggleCropSensorNeg", self.customEnvironment)
		v_u_9_.texts.warningSensorDaylight = g_i18n:getText("warning_sensorRequiresDaylight", self.customEnvironment)
		if g_precisionFarming ~= nil then
			v_u_9_.soilMap = g_precisionFarming.soilMap
			v_u_9_.coverMap = g_precisionFarming.coverMap
			v_u_9_.nitrogenMap = g_precisionFarming.nitrogenMap
			v_u_9_.farmlandStatistics = g_precisionFarming.farmlandStatistics
		end
	end
end

-- Local values: spec, i, sensorNode
function CropSensor:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v26_ = self[CropSensor.SPEC_TABLE_NAME]
		if v26_.isAvailable and v26_.isActive then
			for v27_ = 1, #v26_.sensorNodes do
				local v28_ = v26_.sensorNodes[v27_]
				if not v28_.requiresDaylight or g_currentMission.environment.isSunOn then
					self:updateSensorNode(v28_)
				end
			end
		end
	end
end

-- Local values: spec, i, sensorNode
function CropSensor:onDraw()
	if self.isClient and not self:getIsAIActive() then
		local v30_ = self[CropSensor.SPEC_TABLE_NAME]
		if v30_.isAvailable and v30_.isActive then
			for v31_ = 1, #v30_.sensorNodes do
				if v30_.sensorNodes[v31_].requiresDaylight and not g_currentMission.environment.isSunOn then
					g_currentMission:showBlinkingWarning(v30_.texts.warningSensorDaylight, 1000)
				end
			end
		end
	end
end

-- Local values: spec, _, actionEventId
function CropSensor:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v34_ = self[CropSensor.SPEC_TABLE_NAME]
		if v34_.isAvailable then
			self:clearActionEventsTable(v34_.actionEvents)
			if isActiveForInputIgnoreSelection then
				local _, v35_ = self:addActionEvent(v34_.actionEvents, v34_.inputActionToggle, self, CropSensor.actionEventToggle, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v35_, GS_PRIO_HIGH)
				CropSensor.updateActionEventTexts(self)
			end
		end
	end
end

-- Local values: spec, actionController
function CropSensor:onRootVehicleChanged(rootVehicle)
	if self.isServer then
		local v_u_38_ = self[CropSensor.SPEC_TABLE_NAME]
		if v_u_38_.isAvailable then
			local v39_ = rootVehicle.actionController
			if v39_ ~= nil then
				if v_u_38_.controlledAction == nil then
					v_u_38_.controlledAction = v39_:registerAction("cropSensorTurnOn", nil, 1)
					v_u_38_.controlledAction:setCallback(self, CropSensor.actionControllerToggleEvent)
					v_u_38_.controlledAction:setFinishedFunctions(self, function()
						-- upvalues: (copy) v_u_38_
						return v_u_38_.isActive
					end, true, false)
					v_u_38_.controlledAction:setIsSaved(true)
					v_u_38_.controlledAction:addAIEventListener(self, "onAIFieldWorkerStart", 1)
					v_u_38_.controlledAction:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
					v_u_38_.controlledAction:addAIEventListener(self, "onAIImplementStart", 1)
					v_u_38_.controlledAction:addAIEventListener(self, "onAIImplementEnd", -1)
				else
					v_u_38_.controlledAction:updateParent(v39_)
				end
			end
			if v_u_38_.controlledAction ~= nil then
				v_u_38_.controlledAction:remove()
			end
		end
	end
end

function CropSensor:actionEventToggle(actionName, inputValue, callbackState, isAnalog)
	self:setCropSensorActive()
end

-- Local values: spec, actionEvent
function CropSensor:updateActionEventTexts()
	local v42_ = self[CropSensor.SPEC_TABLE_NAME]
	local v43_ = v42_.actionEvents[v42_.inputActionToggle]
	if v43_ ~= nil then
		g_inputBinding:setActionEventText(v43_.actionEventId, v42_.isActive and v42_.texts.toggleCropSensorNeg or v42_.texts.toggleCropSensorPos)
	end
end

function CropSensor:actionControllerToggleEvent(direction)
	self:setCropSensorActive(direction >= 0)
	return true
end

-- Local values: spec
function CropSensor:doCheckSpeedLimit(superFunc)
	local v48_ = self[CropSensor.SPEC_TABLE_NAME]
	local v49_ = not superFunc(self) and (v48_ ~= nil and v48_.isStandaloneSensor)
	if v49_ then
		v49_ = v48_.isActive
	end
	return v49_
end

-- Local values: spec
function CropSensor:getUseTurnedOnSchema(superFunc)
	local v52_ = self[CropSensor.SPEC_TABLE_NAME]
	local v53_ = not superFunc(self) and (v52_ ~= nil and v52_.isStandaloneSensor)
	if v53_ then
		v53_ = v52_.isActive
	end
	return v53_
end

-- Local values: spec, i, sensorNode
function CropSensor:setCropSensorActive(state, noEventSend)
	local v57_ = self[CropSensor.SPEC_TABLE_NAME]
	if state == nil then
		state = not v57_.isActive
	end
	if state ~= v57_.isActive then
		if self.isClient then
			for v58_ = 1, #v57_.sensorNodes do
				local v59_ = v57_.sensorNodes[v58_]
				if v59_.lightNode ~= nil then
					setVisibility(v59_.lightNode, state)
				end
				if v59_.staticLight ~= nil then
					setShaderParameter(v59_.staticLight, "lightIds0", state and 0.2 or 0, 0, 0, 0, false)
				end
			end
		end
		if state then
			self:updateCropSensorWorkingWidth()
		end
		v57_.isActive = state
		CropSensor.updateActionEventTexts(self)
		CropSensorStateEvent.sendEvent(self, state, noEventSend)
	end
end

-- Local values: spec, i, sensorNode
function CropSensor:updateCropSensorWorkingWidth()
	local v61_ = self[CropSensor.SPEC_TABLE_NAME]
	v61_.workingWidth = CropSensor.getMaxWorkingWidth(self)
	for v62_ = 1, #v61_.sensorNodes do
		self:updateSensorRadius(v61_.sensorNodes[v62_], v61_.workingWidth)
	end
end

-- Local values: xOffset, _, _
function CropSensor:updateSensorRadius(sensorNode, workingWidth)
	if workingWidth > 0 then
		local v66_, _, _ = localToLocal(sensorNode.node, self.rootNode, 0, 0, 0)
		local v67_ = workingWidth * 1.1 / 2 - math.abs(v66_)
		local v68_ = CropSensor.MIN_SENSOR_RADIUS
		sensorNode.radius = math.max(v67_, v68_)
	else
		sensorNode.radius = sensorNode.origRadius
	end
end

-- Local values: spec, x, _, z, x, _, z, dirX, _, dirZ
function CropSensor:updateSensorNode(sensorNode)
	local v71_ = self[CropSensor.SPEC_TABLE_NAME]
	if sensorNode.shape:isa(DensityMapCircle) then
		local v72_, _, v73_ = getWorldTranslation(sensorNode.node)
		sensorNode.shape:updateFromWorldPosition(v72_, v73_, sensorNode.radius, 8)
	elseif sensorNode.shape:isa(DensityMapPolygon) then
		local v74_, _, v75_ = getWorldTranslation(sensorNode.node)
		local v76_, _, v77_ = localDirectionToWorld(sensorNode.node, 0, 0, 1)
		local v78_, v79_ = MathUtil.vector2Normalize(v76_, v77_)
		sensorNode.shape:updateOrigin(v74_, v75_, v78_, v79_)
		sensorNode.shape:updateScale(sensorNode.radius, sensorNode.radius)
	end
	v71_.nitrogenMap:updateCropSensorArea(sensorNode.shape)
end

-- Local values: i, linkNodeData, linkNode, sensorData, j, rotationNode, autoRotate, vRotationNode, rx, ry, rz, sensorNode, i, i
function CropSensor:linkCropSensor(linkData)
	for v82_ = 1, #linkData.linkNodes do
		local v83_ = linkData.linkNodes[v82_]
		local v84_ = v83_.node
		if v84_ == nil and (v83_.nodeName ~= nil and self.i3dMappings[v83_.nodeName] ~= nil) then
			v84_ = self.i3dMappings[v83_.nodeName].nodeId
		end
		if v84_ ~= nil then
			local v85_ = g_precisionFarming:getClonedCropSensorNode(v83_.typeName)
			if v85_ ~= nil then
				link(v84_, v85_.node)
				setTranslation(v85_.node, v83_.translation[1], v83_.translation[2], v83_.translation[3])
				setRotation(v85_.node, v83_.rotation[1], v83_.rotation[2], v83_.rotation[3])
				for v86_ = 1, #v85_.rotationNodes do
					local v87_ = v85_.rotationNodes[v86_]
					local v88_ = false
					if v83_.rotationNodes[v86_] == nil then
						v88_ = v87_.autoRotate
					else
						local v89_ = v83_.rotationNodes[v86_]
						if v87_.autoRotate and (v89_.autoRotate ~= false and v89_.rotation == nil) then
							v88_ = true
						elseif v89_.rotation ~= nil then
							setRotation(v87_.node, v89_.rotation[1], v89_.rotation[2], v89_.rotation[3])
						end
					end
					if v88_ then
						local v90_, v91_, v92_ = localRotationToLocal(self:getParentComponent(v85_.node), getParent(v87_.node), 0, 0, 0)
						setRotation(v87_.node, v90_, v91_, v92_)
					end
				end
				if v85_.measurementNode ~= nil then
					local v93_ = {
						["node"] = v85_.measurementNode,
						["radius"] = 10
					}
					v93_.origRadius = v93_.radius
					if v83_.typeName == "SENSOR_LEFT" then
						v93_.shape = DensityMapPolygon.new()
						v93_.shape:addPolygonPoint(0, 0)
						for v94_ = 1.9198621771937625, -0.5235987755982988, -0.5235987755982988 do
							v93_.shape:addPolygonPoint(math.cos(v94_), (math.sin(v94_)))
						end
					elseif v83_.typeName == "SENSOR_RIGHT" then
						v93_.shape = DensityMapPolygon.new()
						v93_.shape:addPolygonPoint(0, 0)
						for v95_ = 1.0471975511965976, 3.490658503988659, 0.5235987755982988 do
							v93_.shape:addPolygonPoint(math.cos(v95_), (math.sin(v95_)))
						end
					end
					v93_.requiresDaylight = v85_.requiresDaylight
					v93_.index = 1
					local v96_ = self[CropSensor.SPEC_TABLE_NAME].sensorNodes
					table.insert(v96_, v93_)
				end
			end
		end
	end
end

-- Local values: childVehicles, maxWidth, i, childVehicle, workAreas, j, workArea, width, x1, _, _, x2, _, _, leftMarker, rightMarker, _, _, width, x1, _, _, x2, _, _
function CropSensor.getMaxWorkingWidth(sensorVehicle)
	local v98_ = sensorVehicle.rootVehicle.childVehicles
	local v99_ = 0
	for v100_ = 1, #v98_ do
		local v101_ = v98_[v100_]
		if SpecializationUtil.hasSpecialization(ExtendedSprayer, v101_.specializations) then
			if v101_.getWorkAreaByIndex ~= nil then
				local v102_ = v101_.spec_workArea.workAreas
				for v103_ = 1, #v102_ do
					local v104_ = v102_[v103_]
					if v104_.start ~= nil and v104_.width ~= nil then
						local v105_ = calcDistanceFrom(v104_.start, v104_.width)
						local v106_ = math.max(v99_, v105_)
						local v107_, _, _ = localToLocal(v104_.start, sensorVehicle.rootNode, 0, 0, 0)
						local v108_, _, _ = localToLocal(v104_.width, sensorVehicle.rootNode, 0, 0, 0)
						local v109_ = math.abs(v107_) * 2
						local v110_ = math.abs(v108_) * 2
						v99_ = math.max(v106_, v109_, v110_)
					end
				end
			end
			if v101_.getAIMarkers ~= nil then
				local v111_, v112_, _, _ = v101_:getAIMarkers()
				if v111_ ~= nil and v112_ ~= nil then
					local v113_ = calcDistanceFrom(v111_, v112_)
					local v114_ = math.max(v99_, v113_)
					local v115_, _, _ = localToLocal(v111_, sensorVehicle.rootNode, 0, 0, 0)
					local v116_, _, _ = localToLocal(v112_, sensorVehicle.rootNode, 0, 0, 0)
					local v117_ = math.abs(v115_) * 2
					local v118_ = math.abs(v116_) * 2
					v99_ = math.max(v114_, v117_, v118_)
				end
			end
		end
	end
	return v99_
end
