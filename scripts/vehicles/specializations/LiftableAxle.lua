LiftableAxle = {}
source("dataS/scripts/vehicles/specializations/events/LiftableAxleEvent.lua")

function LiftableAxle.prerequisitesPresent(specializations)
	return true
end
function LiftableAxle.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("liftableAxle", g_i18n:getText("shop_configuration"), "liftableAxle", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("LiftableAxle")
	LiftableAxle.registerXMLPaths(v1_, "vehicle.liftableAxle")
	LiftableAxle.registerXMLPaths(v1_, "vehicle.liftableAxle.liftableAxleConfigurations.liftableAxleConfiguration(?)")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).liftableAxle#state", "Liftable axle state", false)
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).liftableAxle#height", "Current height of the liftable axle")
end

function LiftableAxle.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#inputAction", "Input action name if manual control is allowed")
	schema:register(XMLValueType.STRING, basePath .. "#animationName", "Name of the animation")
	schema:register(XMLValueType.FLOAT, basePath .. "#animationSpeed", "Speed of animation", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#defaultState", "Default state of the animation [0-1]", 0)
	schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Index of fill unit to check")
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelThreshold", "Fill level at which the lift axle is toggled [0-1]", 0)
	schema:register(XMLValueType.NODE_INDICES, basePath .. ".dependentAttacherJoint(?)#nodes", "List of attacher joint nodes to adjust height based on attacher joint height")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentAttacherJoint(?)#minJointHeight", "Joint height from ground when axle is lowered", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentAttacherJoint(?)#maxJointHeight", "Joint height from ground when axle is lifted", 1.5)
	schema:register(XMLValueType.NODE_INDICES, basePath .. ".dependentInputAttacherJoint(?)#nodes", "List of input attacher joint nodes to adjust height based on the parent attacher joint height or the height of the parent vehicle chassis")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentInputAttacherJoint(?)#minJointHeight", "Joint height from ground when axle is lowered", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentInputAttacherJoint(?)#maxJointHeight", "Joint height from ground when axle is lifted", 1.5)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".texts#lift", "Text for lifting", "$l10n_action_liftableAxleLift")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".texts#lower", "Text for lowering", "$l10n_action_liftableAxleLower")
end

function LiftableAxle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setLiftableAxleState", LiftableAxle.setLiftableAxleState)
	SpecializationUtil.registerFunction(vehicleType, "getLiftableAxleAttacherJointHeight", LiftableAxle.getLiftableAxleAttacherJointHeight)
end

function LiftableAxle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSmoothAttachUpdateAllowed", LiftableAxle.getIsSmoothAttachUpdateAllowed)
end

function LiftableAxle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", LiftableAxle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", LiftableAxle)
end

-- Local values: spec, configurationId, configKey, inputActionName, _, key, data, _, key, data
function LiftableAxle:onLoad(savegame)
	local v9_ = self.spec_liftableAxle
	local v10_ = Utils.getNoNil(self.configurations.liftableAxle, 1)
	local v11_ = string.format("vehicle.liftableAxle.liftableAxleConfigurations.liftableAxleConfiguration(%d)", v10_ - 1)
	local v12_ = not self.xmlFile:hasProperty(v11_) and "vehicle.liftableAxle" or v11_
	v9_.animationName = self.xmlFile:getValue(v12_ .. "#animationName")
	if v9_.animationName == nil then
		SpecializationUtil.removeEventListener(self, "onPostLoad", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onReadStream", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onWriteStream", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onPreAttachImplement", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onPreDetachImplement", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onPreAttach", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onPreDetach", LiftableAxle)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", LiftableAxle)
	else
		local v13_ = self.xmlFile:getValue(v12_ .. "#inputAction")
		v9_.inputAction = InputAction[v13_]
		v9_.animationSpeed = self.xmlFile:getValue(v12_ .. "#animationSpeed", 1)
		v9_.defaultState = self.xmlFile:getValue(v12_ .. "#defaultState")
		v9_.fillUnitIndex = self.xmlFile:getValue(v12_ .. "#fillUnitIndex")
		v9_.fillLevelThreshold = self.xmlFile:getValue(v12_ .. "#fillLevelThreshold", 0)
		v9_.attacherJointData = {}
		for _, v14_ in self.xmlFile:iterator(v12_ .. ".dependentAttacherJoint") do
			local v15_ = {
				["nodes"] = self.xmlFile:getValue(v14_ .. "#nodes", nil, self.components, self.i3dMappings, true)
			}
			if v15_.nodes ~= nil and #v15_.nodes > 0 then
				v15_.minJointHeight = self.xmlFile:getValue(v14_ .. "#minJointHeight", 1)
				v15_.maxJointHeight = self.xmlFile:getValue(v14_ .. "#maxJointHeight", 1.5)
				v15_.isActive = false
				v15_.currentHeight = v15_.minJointHeight
				local v16_ = v9_.attacherJointData
				table.insert(v16_, v15_)
			end
		end
		v9_.inputAttacherJointData = {}
		for _, v17_ in self.xmlFile:iterator(v12_ .. ".dependentInputAttacherJoint") do
			local v18_ = {
				["nodes"] = self.xmlFile:getValue(v17_ .. "#nodes", nil, self.components, self.i3dMappings, true)
			}
			if v18_.nodes ~= nil and #v18_.nodes > 0 then
				v18_.minJointHeight = self.xmlFile:getValue(v17_ .. "#minJointHeight", 1)
				v18_.maxJointHeight = self.xmlFile:getValue(v17_ .. "#maxJointHeight", 1.5)
				v18_.isActive = false
				v18_.currentHeight = v18_.minJointHeight
				local v19_ = v9_.inputAttacherJointData
				table.insert(v19_, v18_)
			end
		end
		v9_.texts = {}
		v9_.texts.lift = self.xmlFile:getValue(v12_ .. ".texts#lift", "action_liftableAxleLift", self.customEnvironment)
		v9_.texts.lower = self.xmlFile:getValue(v12_ .. ".texts#lower", "action_liftableAxleLower", self.customEnvironment)
		v9_.state = false
		v9_.fixedHeight = nil
		if v9_.defaultState == 0 or v9_.defaultState == 1 then
			v9_.state = v9_.defaultState == 1
		else
			v9_.fixedHeight = v9_.defaultState
		end
		if not self.isServer or v9_.fillUnitIndex == nil then
			SpecializationUtil.removeEventListener(self, "onFillUnitFillLevelChanged", LiftableAxle)
		end
		if not self.isServer or #v9_.attacherJointData == 0 then
			SpecializationUtil.removeEventListener(self, "onPreAttachImplement", LiftableAxle)
			SpecializationUtil.removeEventListener(self, "onPreDetachImplement", LiftableAxle)
		end
		if not self.isServer or #v9_.inputAttacherJointData == 0 then
			SpecializationUtil.removeEventListener(self, "onPreAttach", LiftableAxle)
			SpecializationUtil.removeEventListener(self, "onPreDetach", LiftableAxle)
		end
		if not self.isClient or v9_.inputAction == nil then
			SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", LiftableAxle)
			return
		end
	end
end

-- Local values: spec, state, height
function LiftableAxle:onPostLoad(savegame)
	local v22_ = self.spec_liftableAxle
	local v23_ = v22_.state
	local v24_ = v22_.fixedHeight
	if savegame ~= nil and not savegame.resetVehicles then
		v23_ = savegame.xmlFile:getValue(savegame.key .. ".liftableAxle#state", v23_)
		v24_ = savegame.xmlFile:getValue(savegame.key .. ".liftableAxle#height")
	end
	v22_.state = nil
	self:setLiftableAxleState(v23_, v24_, true, true)
end

-- Local values: spec
function LiftableAxle:saveToXMLFile(xmlFile, key, usedModNames)
	local v28_ = self.spec_liftableAxle
	if v28_.animationName ~= nil then
		xmlFile:setValue(key .. "#state", v28_.state)
		if v28_.fixedHeight ~= nil then
			xmlFile:setValue(key .. "#height", v28_.fixedHeight)
		end
	end
end

-- Local values: state, fixedHeight
function LiftableAxle:onReadStream(streamId, connection)
	local v31_ = streamReadBool(streamId)
	local v32_
	if streamReadBool(streamId) then
		v32_ = streamReadFloat32(streamId)
	else
		v32_ = nil
	end
	self:setLiftableAxleState(v31_, v32_, true, true)
end

-- Local values: spec
function LiftableAxle:onWriteStream(streamId, connection)
	local v35_ = self.spec_liftableAxle
	streamWriteBool(streamId, v35_.state)
	if streamWriteBool(streamId, v35_.fixedHeight ~= nil) then
		streamWriteFloat32(streamId, v35_.fixedHeight or 0)
	end
end

-- Local values: spec, fillLevel, state
function LiftableAxle:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if self:getIsSynchronized() then
		local v39_ = self.spec_liftableAxle
		if fillUnitIndex == v39_.fillUnitIndex and fillLevelDelta ~= 0 then
			local v40_ = self:getFillUnitFillLevelPercentage(v39_.fillUnitIndex) > v39_.fillLevelThreshold
			if v40_ ~= v39_.state then
				self:setLiftableAxleState(v40_)
			end
		end
	end
end

-- Local values: spec, jointDesc, _, data, isActive, _, node, inputAttacherJoint, alpha
function LiftableAxle:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v45_ = self.spec_liftableAxle
	local v46_ = self:getAttacherJointByJointDescIndex(jointDescIndex)
	for _, v47_ in ipairs(v45_.attacherJointData) do
		local v48_ = false
		for _, v49_ in ipairs(v47_.nodes) do
			if v49_ == v46_.jointTransform then
				v48_ = true
				break
			end
		end
		if v48_ ~= v47_.isActive then
			v47_.isActive = v48_
			if v48_ then
				local v50_ = object:getInputAttacherJointByJointDescIndex(inputJointDescIndex)
				local v51_ = 1 - MathUtil.inverseLerp(v47_.minJointHeight, v47_.maxJointHeight, v50_.attacherHeight or (v47_.minJointHeight + v47_.maxJointHeight) * 0.5)
				v47_.currentHeight = MathUtil.lerp(v47_.minJointHeight, v47_.maxJointHeight, 1 - v51_)
				self:setLiftableAxleState(v45_.state, v51_)
			end
		end
	end
end

-- Local values: spec, jointDesc, _, data, _, node, isAnyAttacherJointActive, _, data
function LiftableAxle:onPreDetachImplement(implement)
	local v54_ = self.spec_liftableAxle
	local v55_ = self:getAttacherJointByJointDescIndex(implement.jointDescIndex)
	for _, v56_ in ipairs(v54_.attacherJointData) do
		for _, v57_ in ipairs(v56_.nodes) do
			if v57_ == v55_.jointTransform and v56_.isActive then
				v56_.isActive = false
				self:setLiftableAxleState(v54_.state, nil)
			end
		end
	end
	if v54_.defaultState == nil then
		self:setLiftableAxleState(v54_.state, nil)
	else
		local v58_ = false
		for _, v59_ in ipairs(v54_.attacherJointData) do
			if v59_.isActive then
				v58_ = true
				break
			end
		end
		if not v58_ then
			if v54_.defaultState == 0 or v54_.defaultState == 1 then
				self:setLiftableAxleState(v54_.defaultState == 1, nil)
			else
				self:setLiftableAxleState(v54_.state, v54_.defaultState)
			end
		end
	end
end

-- Local values: spec, inputAttacherJoint, _, data, isActive, _, node, height, attacherJoint, alpha
function LiftableAxle:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v64_ = self.spec_liftableAxle
	local v65_ = self:getInputAttacherJointByJointDescIndex(inputJointDescIndex)
	for _, v66_ in ipairs(v64_.inputAttacherJointData) do
		local v67_ = false
		for _, v68_ in ipairs(v66_.nodes) do
			if v68_ == v65_.node then
				v67_ = true
				break
			end
		end
		if v67_ ~= v66_.isActive then
			v66_.isActive = v67_
			if v67_ then
				local v69_
				if attacherVehicle.getLiftableAxleAttacherJointHeight == nil then
					v69_ = nil
				else
					v69_ = attacherVehicle:getLiftableAxleAttacherJointHeight(jointDescIndex)
				end
				if v69_ == nil then
					local v70_ = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
					if v70_ ~= nil then
						v69_ = (v70_.upperDistanceToGround + v70_.lowerDistanceToGround) * 0.5
					end
				end
				if v69_ ~= nil then
					local v71_ = 1 - MathUtil.inverseLerp(v66_.minJointHeight, v66_.maxJointHeight, v69_)
					v66_.currentHeight = MathUtil.lerp(v66_.minJointHeight, v66_.maxJointHeight, v71_)
					self:setLiftableAxleState(v64_.state, v71_)
				end
			end
		end
	end
end

-- Local values: spec, inputAttacherJoint, _, data, _, node, isAnyAttacherJointActive, _, data
function LiftableAxle:onPreDetach(attacherVehicle, implement)
	local v74_ = self.spec_liftableAxle
	local v75_ = self:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
	for _, v76_ in ipairs(v74_.inputAttacherJointData) do
		for _, v77_ in ipairs(v76_.nodes) do
			if v77_ == v75_.node and v76_.isActive then
				v76_.isActive = false
				self:setLiftableAxleState(v74_.state, nil)
			end
		end
	end
	if v74_.defaultState == nil then
		self:setLiftableAxleState(v74_.state, nil)
	else
		local v78_ = false
		for _, v79_ in ipairs(v74_.inputAttacherJointData) do
			if v79_.isActive then
				v78_ = true
				break
			end
		end
		if not v78_ then
			if v74_.defaultState == 0 or v74_.defaultState == 1 then
				self:setLiftableAxleState(v74_.defaultState == 1, nil)
			else
				self:setLiftableAxleState(v74_.state, v74_.defaultState)
			end
		end
	end
end

-- Local values: spec, _, actionEventId
function LiftableAxle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local v82_ = self.spec_liftableAxle
	self:clearActionEventsTable(v82_.actionEvents)
	if isActiveForInputIgnoreSelection then
		local _, v83_ = self:addPoweredActionEvent(v82_.actionEvents, v82_.inputAction, self, LiftableAxle.actionEvent, true, false, false, true, nil)
		g_inputBinding:setActionEventTextPriority(v83_, GS_PRIO_HIGH)
		LiftableAxle.updateActionEvents(self)
	end
end

-- Local values: spec
function LiftableAxle:actionEvent(actionName, inputValue, callbackState, isAnalog)
	self:setLiftableAxleState(not self.spec_liftableAxle.state)
end

-- Local values: spec, actionEvent
function LiftableAxle:updateActionEvents()
	local v86_ = self.spec_liftableAxle
	local v87_ = v86_.actionEvents[v86_.inputAction]
	if v87_ ~= nil then
		g_inputBinding:setActionEventText(v87_.actionEventId, v86_.state and v86_.texts.lift or v86_.texts.lower)
	end
end

-- Local values: spec, currentTime, direction, direction
function LiftableAxle:setLiftableAxleState(state, fixedHeight, skipAnimation, noEventSend)
	local v93_ = self.spec_liftableAxle
	if v93_.state ~= state or v93_.fixedHeight ~= fixedHeight then
		if fixedHeight ~= nil then
			state = fixedHeight >= 0.5
		end
		v93_.state = state
		v93_.fixedHeight = fixedHeight
		local v94_ = self:getAnimationTime(v93_.animationName)
		if fixedHeight == nil then
			self:stopAnimation(v93_.animationName, true)
			self:playAnimation(v93_.animationName, (state and 1 or -1) * v93_.animationSpeed, v94_, true)
		else
			local v95_ = fixedHeight - v94_
			local v96_ = math.sign(v95_)
			self:playAnimation(v93_.animationName, v96_ * v93_.animationSpeed, v94_, true)
			self:setAnimationStopTime(v93_.animationName, fixedHeight)
		end
		if skipAnimation then
			AnimatedVehicle.updateAnimationByName(self, v93_.animationName, 9999999, true)
		end
		if self.isClient and v93_.inputAction ~= nil then
			LiftableAxle.updateActionEvents(self)
		end
	end
	LiftableAxleEvent.sendEvent(self, v93_.state, v93_.fixedHeight, noEventSend)
end

-- Local values: spec, jointDesc, _, data, _, node
function LiftableAxle:getLiftableAxleAttacherJointHeight(attacherJointIndex)
	local v99_ = self.spec_liftableAxle
	if v99_.animationName ~= nil then
		local v100_ = self:getAttacherJointByJointDescIndex(attacherJointIndex)
		for _, v101_ in ipairs(v99_.attacherJointData) do
			for _, v102_ in ipairs(v101_.nodes) do
				if v102_ == v100_.jointTransform and v101_.isActive then
					return v101_.currentHeight
				end
			end
		end
	end
	return nil
end

-- Local values: spec
function LiftableAxle:getIsSmoothAttachUpdateAllowed(superFunc, implement)
	if not superFunc(self, implement) then
		return false
	end
	local v106_ = self.spec_liftableAxle
	return (v106_.animationName == nil or not self:getIsAnimationPlaying(v106_.animationName)) and true or false
end
