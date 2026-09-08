PowerTakeOffs = {}
PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE = 40
PowerTakeOffs.xmlSchema = nil

function PowerTakeOffs.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function PowerTakeOffs.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("PowerTakeOffs")
	PowerTakeOffs.registerXMLPaths(v2_, "vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(?)")
	PowerTakeOffs.registerXMLPaths(v2_, "vehicle.powerTakeOffs")
	v2_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p3_, p4_)
		p3_:register(XMLValueType.VECTOR_N, p4_ .. ".powerTakeOffs#indices", "PTOs to update")
		p3_:register(XMLValueType.VECTOR_N, p4_ .. ".powerTakeOffs#localIndices", "Local PTOs to update")
	end)
	v2_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p5_, p6_)
		p5_:register(XMLValueType.VECTOR_N, p6_ .. ".powerTakeOffs#indices", "PTOs to update")
		p5_:register(XMLValueType.VECTOR_N, p6_ .. ".powerTakeOffs#localIndices", "Local PTOs to update")
	end)
	v2_:register(XMLValueType.BOOL, "vehicle.powerTakeOffs#ignoreInvalidJointIndices", "Do not display warning if attacher joint index could not be found. Can be useful if attacher joints change due to configurations", false)
	v2_:register(XMLValueType.FLOAT, "vehicle.powerTakeOffs#maxUpdateDistance", "Max. distance to vehicle root to update power take offs", PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE)
	Dashboard.addDelayedRegistrationFunc(v2_, function(p7_, p8_)
		p7_:register(XMLValueType.INT, p8_ .. "#powerTakeOffIndex", "Index of power take off in xml to use")
	end)
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.powerTakeOffs.sounds", "turnedOn(?)")
	v2_:setXMLSpecializationType()
	local v9_ = XMLSchema.new("powerTakeOff")
	PowerTakeOffs.xmlSchema = v9_
	v9_:register(XMLValueType.STRING, "powerTakeOff#filename", "Path to i3d file")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.startNode#node", "Start node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.linkNode#node", "Link node")
	v9_:register(XMLValueType.FLOAT, "powerTakeOff#size", "Height of pto", 0.19)
	v9_:register(XMLValueType.FLOAT, "powerTakeOff#minLength", "Minimum length of pto", 0.6)
	v9_:register(XMLValueType.ANGLE, "powerTakeOff#maxAngle", "Max. angle between start and end", 45)
	v9_:register(XMLValueType.FLOAT, "powerTakeOff#zOffset", "Z axis offset of end node", 0)
	v9_:register(XMLValueType.STRING, "powerTakeOff#colorMaterialName", "Color material name", "powerTakeOff_main_mat")
	v9_:register(XMLValueType.STRING, "powerTakeOff#decalColorMaterialName", "Decal color material name", "powerTakeOff_decal_mat")
	AnimationManager.registerAnimationNodesXMLPaths(v9_, "powerTakeOff.animationNodes")
	v9_:register(XMLValueType.BOOL, "powerTakeOff#isSingleJoint", "Is single joint PTO", false)
	v9_:register(XMLValueType.BOOL, "powerTakeOff#isDoubleJoint", "Is double joint PTO", false)
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint#node", "(Single Joint) Start joint node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint#node", "(Single Joint) End joint node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.scalePart#node", "(Single|Double Joint) Scale part node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.scalePart#referenceNode", "(Single|Double Joint) Scale part reference node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart#node", "(Single|Double Joint) translation part node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart#referenceNode", "(Single|Double Joint) translation part reference node")
	v9_:register(XMLValueType.FLOAT, "powerTakeOff.translationPart#length", "(Single|Double Joint) translation part length", 0.4)
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart.decal#node", "(Single|Double Joint) translation part decal node")
	v9_:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#size", "(Single|Double Joint) translation part decal size", 0.1)
	v9_:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#offset", "(Single|Double Joint) translation part decal offset", 0.05)
	v9_:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#minOffset", "(Single|Double Joint) translation part decal minOffset", 0.01)
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint1#node", "(Double Joint) Start joint 1")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint2#node", "(Double Joint) Start joint 2")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint1#node", "(Double Joint) End joint 1")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint1#referenceNode", "(Double Joint) End joint 1 reference node")
	v9_:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint2#node", "(Double Joint) End joint 2")
	I3DUtil.registerI3dMappingXMLPaths(v9_, "powerTakeOff")
end

function PowerTakeOffs.registerXMLPaths(schema, basePath)
	PowerTakeOffs.registerOutputXMLPaths(schema, basePath .. ".output(?)")
	PowerTakeOffs.registerInputXMLPaths(schema, basePath .. ".input(?)")
	PowerTakeOffs.registerLocalXMLPaths(schema, basePath .. ".local(?)")
end

function PowerTakeOffs.registerOutputXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#skipToInputAttacherIndex", "Skip to input attacher joint index")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#outputNode", "Output node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Corresponding attacher joint(s) (List of indices)")
	schema:register(XMLValueType.NODE_INDICES, basePath .. "#attacherJointNodes", "Corresponding attacher joint(s) (List of attacherJoint nodes)")
	schema:register(XMLValueType.STRING, basePath .. "#ptoName", "Output name", "DEFAULT_PTO")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
	Dashboard.registerDashboardXMLPaths(schema, basePath, { "state" })
end

function PowerTakeOffs.registerInputXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#inputNode", "Input node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Corresponding Input attacher joint(s) (List of indices)")
	schema:register(XMLValueType.NODE_INDICES, basePath .. "#inputAttacherJointNodes", "Corresponding Input attacher joint(s) (List of attacherJoint nodes)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#detachNode", "Detach node")
	schema:register(XMLValueType.BOOL, basePath .. "#aboveAttacher", "Above attacher", true)
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#materialTemplateName", "Name of shared material to apply to the main pto")
	schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#decalMaterialTemplateName", "Name of shared material to apply to the decals")
	schema:registerAutoCompletionDataSource(basePath .. "#decalMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.FLOAT, basePath .. "#length", "Predefined length of the PTO (Otherwise calculated from the distance between startNode and endNode, while loading. Can be useful if the tool is loaded in different states to always get the same length.)")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pto xml file", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
	schema:register(XMLValueType.STRING, basePath .. "#ptoName", "Pto name", "DEFAULT_PTO")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function PowerTakeOffs.registerLocalXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#endNode", "End node")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#materialTemplateName", "Name of shared material to apply to the main pto")
	schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#decalMaterialTemplateName", "Name of shared material to apply to the decals")
	schema:registerAutoCompletionDataSource(basePath .. "#decalMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.FLOAT, basePath .. "#length", "Predefined length of the PTO (Otherwise calculated from the distance between startNode and endNode, while loading. Can be useful if the tool is loaded in different states to always get the same length.)")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pto xml file", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
end

function PowerTakeOffs.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getPowerTakeOffConfigIndex", PowerTakeOffs.getPowerTakeOffConfigIndex)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffsFromXML", PowerTakeOffs.loadPowerTakeOffsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadOutputPowerTakeOff", PowerTakeOffs.loadOutputPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadInputPowerTakeOff", PowerTakeOffs.loadInputPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadLocalPowerTakeOff", PowerTakeOffs.loadLocalPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "placeLocalPowerTakeOff", PowerTakeOffs.placeLocalPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOff", PowerTakeOffs.updatePowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateAttachedPowerTakeOffs", PowerTakeOffs.updateAttachedPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOffLength", PowerTakeOffs.updatePowerTakeOffLength)
	SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffsByJointDescIndex", PowerTakeOffs.getOutputPowerTakeOffsByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffs", PowerTakeOffs.getOutputPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffs", PowerTakeOffs.getInputPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffsByJointDescIndexAndName", PowerTakeOffs.getInputPowerTakeOffsByJointDescIndexAndName)
	SpecializationUtil.registerFunction(vehicleType, "getIsPowerTakeOffActive", PowerTakeOffs.getIsPowerTakeOffActive)
	SpecializationUtil.registerFunction(vehicleType, "attachPowerTakeOff", PowerTakeOffs.attachPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "detachPowerTakeOff", PowerTakeOffs.detachPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "checkPowerTakeOffCollision", PowerTakeOffs.checkPowerTakeOffCollision)
	SpecializationUtil.registerFunction(vehicleType, "parkPowerTakeOff", PowerTakeOffs.parkPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffFromConfigFile", PowerTakeOffs.loadPowerTakeOffFromConfigFile)
	SpecializationUtil.registerFunction(vehicleType, "onPowerTakeOffI3DLoaded", PowerTakeOffs.onPowerTakeOffI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadSingleJointPowerTakeOff", PowerTakeOffs.loadSingleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateSingleJointPowerTakeOff", PowerTakeOffs.updateSingleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadDoubleJointPowerTakeOff", PowerTakeOffs.loadDoubleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateDoubleJointPowerTakeOff", PowerTakeOffs.updateDoubleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadBasicPowerTakeOff", PowerTakeOffs.loadBasicPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "attachTypedPowerTakeOff", PowerTakeOffs.attachTypedPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "detachTypedPowerTakeOff", PowerTakeOffs.detachTypedPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "validatePowerTakeOffAttachment", PowerTakeOffs.validatePowerTakeOffAttachment)
end

function PowerTakeOffs.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", PowerTakeOffs.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", PowerTakeOffs.updateExtraDependentParts)
end

function PowerTakeOffs.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", PowerTakeOffs)
end

-- Local values: spec
function PowerTakeOffs:onPreLoad(savegame)
	self.spec_powerTakeOffs.configIndex = self:getPowerTakeOffConfigIndex()
end

-- Local values: spec
function PowerTakeOffs:onLoad(savegame)
	local v23_ = self.spec_powerTakeOffs
	v23_.outputPowerTakeOffs = {}
	v23_.inputPowerTakeOffs = {}
	v23_.localPowerTakeOffs = {}
	v23_.ignoreInvalidJointIndices = self.xmlFile:getValue("vehicle.powerTakeOffs#ignoreInvalidJointIndices", false)
	v23_.maxUpdateDistance = self.xmlFile:getValue("vehicle.powerTakeOffs#maxUpdateDistance", PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE)
	v23_.delayedPowerTakeOffsMountings = {}
	if self.isClient then
		v23_.samples = {}
		v23_.samples.turnedOn = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.powerTakeOffs.sounds", "turnedOn", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	else
		SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", PowerTakeOffs)
	end
end

-- Local values: spec, configKey
function PowerTakeOffs:onPostLoad(savegame)
	local v25_ = self.spec_powerTakeOffs
	self:loadPowerTakeOffsFromXML(self.xmlFile, "vehicle.powerTakeOffs")
	local v26_ = string.format("vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(%d)", v25_.configIndex - 1)
	if self.xmlFile:hasProperty(v26_) then
		self:loadPowerTakeOffsFromXML(self.xmlFile, v26_)
	end
end

-- Local values: spec, _, output, _, input, _, localPto
function PowerTakeOffs:onDelete()
	local v28_ = self.spec_powerTakeOffs
	if v28_.outputPowerTakeOffs ~= nil then
		for _, v29_ in pairs(v28_.outputPowerTakeOffs) do
			if v29_.xmlFile ~= nil then
				v29_.xmlFile:delete()
				v29_.xmlFile = nil
			end
			if v29_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v29_.sharedLoadRequestId)
				v29_.sharedLoadRequestId = nil
			end
			g_animationManager:deleteAnimations(v29_.localAnimationNodes)
			if v29_.rootNode ~= nil then
				delete(v29_.rootNode)
				delete(v29_.attachNode)
			end
		end
	end
	if v28_.inputPowerTakeOffs ~= nil then
		for _, v30_ in pairs(v28_.inputPowerTakeOffs) do
			if v30_.xmlFile ~= nil then
				v30_.xmlFile:delete()
				v30_.xmlFile = nil
			end
			if v30_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v30_.sharedLoadRequestId)
				v30_.sharedLoadRequestId = nil
			end
			g_animationManager:deleteAnimations(v30_.animationNodes)
			g_animationManager:deleteAnimations(v30_.localAnimationNodes)
			if v30_.rootNode ~= nil then
				delete(v30_.rootNode)
				delete(v30_.attachNode)
			end
		end
	end
	if v28_.localPowerTakeOffs ~= nil then
		for _, v31_ in pairs(v28_.localPowerTakeOffs) do
			if v31_.xmlFile ~= nil then
				v31_.xmlFile:delete()
				v31_.xmlFile = nil
			end
			if v31_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v31_.sharedLoadRequestId)
				v31_.sharedLoadRequestId = nil
			end
			g_animationManager:deleteAnimations(v31_.animationNodes)
		end
	end
	if v28_.samples ~= nil then
		g_soundManager:deleteSamples(v28_.samples.turnedOn)
	end
end

-- Local values: spec, i, input, impements, i, object, isPowerTakeOffActive, i, input, i, localPto
function PowerTakeOffs:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v34_ = self.spec_powerTakeOffs
		if self.currentUpdateDistance < v34_.maxUpdateDistance then
			for v35_ = 1, #v34_.inputPowerTakeOffs do
				local v36_ = v34_.inputPowerTakeOffs[v35_]
				if v36_.connectedVehicle ~= nil and self.updateLoopIndex == v36_.connectedVehicle.updateLoopIndex then
					self:updatePowerTakeOff(v36_, dt)
				end
			end
			if self.getAttachedImplements ~= nil then
				local v37_ = self:getAttachedImplements()
				for v38_ = 1, #v37_ do
					local v39_ = v37_[v38_].object
					if v39_.updateAttachedPowerTakeOffs ~= nil then
						v39_:updateAttachedPowerTakeOffs(dt, self)
					end
				end
			end
			local v40_ = self.isActive
			if v40_ then
				v40_ = self:getIsPowerTakeOffActive()
			end
			if v34_.lastIsPowerTakeOffActive ~= v40_ then
				for v41_ = 1, #v34_.inputPowerTakeOffs do
					local v42_ = v34_.inputPowerTakeOffs[v41_]
					if v40_ and v42_.connectedVehicle ~= nil then
						g_animationManager:startAnimations(v42_.animationNodes)
						g_animationManager:startAnimations(v42_.localAnimationNodes)
						g_animationManager:startAnimations(v42_.connectedOutput.localAnimationNodes)
						v42_.connectedOutput.isActive = true
						if v42_.connectedVehicle.updateDashboardValueType ~= nil then
							v42_.connectedVehicle:updateDashboardValueType("powerTakeOffs.state")
						end
					else
						g_animationManager:stopAnimations(v42_.animationNodes)
						g_animationManager:stopAnimations(v42_.localAnimationNodes)
						if v42_.connectedOutput ~= nil then
							g_animationManager:stopAnimations(v42_.connectedOutput.localAnimationNodes)
							v42_.connectedOutput.isActive = false
							if v42_.connectedVehicle.updateDashboardValueType ~= nil then
								v42_.connectedVehicle:updateDashboardValueType("powerTakeOffs.state")
							end
						end
					end
				end
				for v43_ = 1, #v34_.localPowerTakeOffs do
					local v44_ = v34_.localPowerTakeOffs[v43_]
					if v40_ then
						g_animationManager:startAnimations(v44_.animationNodes)
					else
						g_animationManager:stopAnimations(v44_.animationNodes)
					end
				end
				if v40_ then
					g_soundManager:playSamples(v34_.samples.turnedOn)
				else
					g_soundManager:stopSamples(v34_.samples.turnedOn)
				end
				v34_.lastIsPowerTakeOffActive = v40_
			end
		end
	end
end

function PowerTakeOffs:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	PowerTakeOffs.onUpdateInterpolation(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function PowerTakeOffs:getPowerTakeOffConfigIndex()
	return 1
end

-- Local values: spec
function PowerTakeOffs:loadPowerTakeOffsFromXML(xmlFile, key)
	local v_u_53_ = self.spec_powerTakeOffs
	if SpecializationUtil.hasSpecialization(AttacherJoints, self.specializations) then
		xmlFile:iterate(key .. ".output", function(_, p54_)
			-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_53_
			local v55_ = {}
			if self:loadOutputPowerTakeOff(xmlFile, p54_, v55_) then
				local v56_ = v_u_53_.outputPowerTakeOffs
				table.insert(v56_, v55_)
			end
		end)
	end
	if SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
		xmlFile:iterate(key .. ".input", function(_, p57_)
			-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_53_
			local v58_ = {}
			if self:loadInputPowerTakeOff(xmlFile, p57_, v58_) then
				local v59_ = v_u_53_.inputPowerTakeOffs
				table.insert(v59_, v58_)
			end
		end)
	end
	xmlFile:iterate(key .. ".local", function(_, p60_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_53_
		local v61_ = {}
		if self:loadLocalPowerTakeOff(xmlFile, p60_, v61_) then
			local v62_ = v_u_53_.localPowerTakeOffs
			table.insert(v62_, v61_)
		end
	end)
end

-- Local values: outputNode, attacherJointIndices, attacherJointIndicesRaw, _, attacherJointIndex, attacherJointNodesRaw, _, node, attacherJointIndex, powerTakeOffLoadFunc, state
function PowerTakeOffs:loadOutputPowerTakeOff(xmlFile, baseName, powerTakeOffOutput)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#linkNode", baseName .. "#outputNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#filename", "pto file is now defined in the pto input node")
	powerTakeOffOutput.skipToInputAttacherIndex = xmlFile:getValue(baseName .. "#skipToInputAttacherIndex")
	local v67_ = xmlFile:getValue(baseName .. "#outputNode", nil, self.components, self.i3dMappings)
	if v67_ == nil and powerTakeOffOutput.skipToInputAttacherIndex == nil then
		Logging.xmlWarning(xmlFile, "Pto output needs to have either a valid \'outputNode\' or a \'skipToInputAttacherIndex\' in \'%s\'", baseName)
		return false
	end
	local v68_ = {}
	local v69_ = xmlFile:getValue(baseName .. "#attacherJointIndices", nil, true)
	if v69_ ~= nil then
		for _, v70_ in ipairs(v69_) do
			if self:getAttacherJointByJointDescIndex(v70_) == nil then
				if not self.spec_powerTakeOffs.ignoreInvalidJointIndices then
					Logging.xmlWarning(self.xmlFile, "The given attacherJointIndex \'%d\' for powerTakeOff can\'t be resolved into a valid attacherJoint in %s", v70_, baseName)
				end
			else
				v68_[v70_] = true
			end
		end
	end
	local v71_ = xmlFile:getValue(baseName .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
	if v71_ ~= nil then
		for _, v72_ in ipairs(v71_) do
			local v73_ = self:getAttacherJointIndexByNode(v72_)
			if v73_ ~= nil then
				v68_[v73_] = true
			end
		end
	end
	if next(v68_) == nil then
		return false
	end
	powerTakeOffOutput.outputNode = v67_
	powerTakeOffOutput.attacherJointIndices = v68_
	powerTakeOffOutput.connectedInput = nil
	powerTakeOffOutput.ptoName = xmlFile:getValue(baseName .. "#ptoName", "DEFAULT_PTO")
	powerTakeOffOutput.localAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseName .. ".animationNodes", self.components, self, self.i3dMappings)
	powerTakeOffOutput.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, powerTakeOffOutput.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(powerTakeOffOutput.objectChanges, false, self, self.setMovingToolDirty)
	powerTakeOffOutput.isActive = false
	if self.registerDashboardValueType ~= nil then
		local v74_ = DashboardValueType.new("powerTakeOffs", "state")
		v74_:setXMLKey(baseName)
		v74_:setValue(powerTakeOffOutput, function(p75_, p76_)
			return (p76_.powerTakeOffOutput or p75_).isActive
		end)
		v74_:setAdditionalFunctions(function(p77_, p78_, p79_, p80_, _)
			local v81_ = p78_:getValue(p79_ .. "#powerTakeOffIndex")
			if v81_ ~= nil then
				p80_.powerTakeOffOutput = p77_.spec_powerTakeOffs.outputPowerTakeOffs[v81_]
			end
			return true
		end, nil)
		v74_:setPollUpdate(false)
		self:registerDashboardValueType(v74_)
	end
	return true
end

-- Local values: inputNode, inputAttacherJointIndices, inputAttacherJointIndicesRaw, _, inputAttacherJointIndex, inputAttacherJointNodesRaw, _, node, inputAttacherJointIndex, filename
function PowerTakeOffs:loadInputPowerTakeOff(xmlFile, baseName, powerTakeOffInput)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#color", baseName .. "#materialTemplateName")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#decalColor", baseName .. "#decalMaterialTemplateName")
	local v86_ = xmlFile:getValue(baseName .. "#inputNode", nil, self.components, self.i3dMappings)
	if v86_ == nil then
		Logging.xmlWarning(xmlFile, "Pto input needs to have a valid \'inputNode\' in \'%s\'", baseName)
		return false
	end
	local v87_ = {}
	local v88_ = xmlFile:getValue(baseName .. "#inputAttacherJointIndices", nil, true)
	if v88_ ~= nil then
		for _, v89_ in ipairs(v88_) do
			if self:getInputAttacherJointByJointDescIndex(v89_) == nil then
				if not self.spec_powerTakeOffs.ignoreInvalidJointIndices then
					Logging.xmlWarning(self.xmlFile, "The given inputAttacherJointIndex \'%d\' for powerTakeOff can\'t be resolved into a valid attacherJoint in %s", v89_, baseName)
				end
			else
				v87_[v89_] = true
			end
		end
	end
	local v90_ = xmlFile:getValue(baseName .. "#inputAttacherJointNodes", nil, self.components, self.i3dMappings, true)
	if v90_ ~= nil then
		for _, v91_ in ipairs(v90_) do
			local v92_ = self:getInputAttacherJointIndexByNode(v91_)
			if v92_ ~= nil then
				v87_[v92_] = true
			end
		end
	end
	if next(v87_) == nil then
		Logging.xmlWarning(xmlFile, "Pto output needs to have valid \'inputAttacherJointIndices\' or \'inputAttacherJointNodes\' in \'%s\'", baseName)
		return false
	end
	powerTakeOffInput.inputNode = v86_
	if Platform.gameplay.hasDetachedPowerTakeOffs then
		powerTakeOffInput.detachNode = xmlFile:getValue(baseName .. "#detachNode", nil, self.components, self.i3dMappings)
	end
	powerTakeOffInput.inputAttacherJointIndices = v87_
	powerTakeOffInput.aboveAttacher = xmlFile:getValue(baseName .. "#aboveAttacher", true)
	powerTakeOffInput.material = xmlFile:getValue(baseName .. "#materialTemplateName", nil, self.customEnvironment)
	powerTakeOffInput.decalMaterial = xmlFile:getValue(baseName .. "#decalMaterialTemplateName", nil, self.customEnvironment)
	powerTakeOffInput.ptoName = xmlFile:getValue(baseName .. "#ptoName", "DEFAULT_PTO")
	powerTakeOffInput.localAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseName .. ".animationNodes", self.components, self, self.i3dMappings)
	powerTakeOffInput.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, powerTakeOffInput.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(powerTakeOffInput.objectChanges, false, self, self.setMovingToolDirty)
	local v93_ = xmlFile:getValue(baseName .. "#filename", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
	if v93_ ~= nil then
		self:loadPowerTakeOffFromConfigFile(powerTakeOffInput, v93_)
	end
	return true
end

-- Local values: filename
function PowerTakeOffs:loadLocalPowerTakeOff(xmlFile, baseName, powerTakeOffLocal)
	powerTakeOffLocal.isLocal = true
	powerTakeOffLocal.inputNode = xmlFile:getValue(baseName .. "#startNode", nil, self.components, self.i3dMappings)
	if powerTakeOffLocal.inputNode == nil then
		Logging.xmlWarning(xmlFile, "Missing startNode for local power take off \'%s\'", baseName)
		return false
	end
	powerTakeOffLocal.endNode = xmlFile:getValue(baseName .. "#endNode", nil, self.components, self.i3dMappings)
	if powerTakeOffLocal.endNode == nil then
		Logging.xmlWarning(xmlFile, "Missing endNode for local power take off \'%s\'", baseName)
		return false
	end
	powerTakeOffLocal.material = xmlFile:getValue(baseName .. "#materialTemplateName", nil, self.customEnvironment)
	powerTakeOffLocal.decalMaterial = xmlFile:getValue(baseName .. "#decalMaterialTemplateName", nil, self.customEnvironment)
	powerTakeOffLocal.predefinedLength = xmlFile:getValue(baseName .. "#length")
	local v98_ = xmlFile:getValue(baseName .. "#filename", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
	if v98_ ~= nil then
		self:loadPowerTakeOffFromConfigFile(powerTakeOffLocal, v98_)
	end
	return true
end

function PowerTakeOffs:placeLocalPowerTakeOff(powerTakeOff)
	if powerTakeOff.i3dLoaded then
		if not powerTakeOff.isPlaced then
			link(powerTakeOff.endNode, powerTakeOff.linkNode)
			setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
			setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
			self:updatePowerTakeOffLength(powerTakeOff)
			powerTakeOff.isPlaced = true
		end
		self:updatePowerTakeOff(powerTakeOff, 0)
	end
end

function PowerTakeOffs:updatePowerTakeOff(input, dt)
	if input.i3dLoaded and (input.isLinked or input.isPlaced) and input.updateFunc ~= nil then
		input.updateFunc(self, input, dt)
	end
end

-- Local values: spec, _, input
function PowerTakeOffs:updateAttachedPowerTakeOffs(dt, attacherVehicle)
	local v107_ = self.spec_powerTakeOffs
	for _, v108_ in pairs(v107_.inputPowerTakeOffs) do
		if v108_.connectedVehicle ~= nil and (v108_.connectedVehicle == attacherVehicle and self.updateLoopIndex == v108_.connectedVehicle.updateLoopIndex) then
			self:updatePowerTakeOff(v108_, dt)
		end
	end
end

function PowerTakeOffs:updatePowerTakeOffLength(input)
	if input.i3dLoaded and input.updateDistanceFunc ~= nil then
		input.updateDistanceFunc(self, input)
	end
end

-- Local values: retOutputs, spec, _, output, _, output, secondAttacherVehicle, ownImplement
function PowerTakeOffs:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
	local v113_ = self.spec_powerTakeOffs
	local v114_ = {}
	for _, v115_ in pairs(v113_.outputPowerTakeOffs) do
		if v115_.attacherJointIndices[jointDescIndex] ~= nil then
			table.insert(v114_, v115_)
		end
	end
	if #v114_ > 0 then
		for _, v116_ in ipairs(v114_) do
			if v116_.skipToInputAttacherIndex ~= nil then
				local v117_ = self:getAttacherVehicle()
				if v117_ ~= nil then
					return v117_:getOutputPowerTakeOffsByJointDescIndex(v117_:getImplementByObject(_).jointDescIndex)
				end
			end
		end
	end
	return v114_
end

function PowerTakeOffs:getOutputPowerTakeOffs()
	return self.spec_powerTakeOffs.outputPowerTakeOffs
end

-- Local values: retInputs, spec, _, input, _, output, index, _, implement
function PowerTakeOffs:getInputPowerTakeOffsByJointDescIndexAndName(jointDescIndex, ptoName)
	local v122_ = self.spec_powerTakeOffs
	local v123_ = {}
	for _, v124_ in pairs(v122_.inputPowerTakeOffs) do
		if v124_.inputAttacherJointIndices[jointDescIndex] ~= nil and v124_.ptoName == ptoName then
			table.insert(v123_, v124_)
		end
	end
	if #v123_ == 0 then
		for _, v125_ in pairs(v122_.outputPowerTakeOffs) do
			if v125_.skipToInputAttacherIndex == jointDescIndex then
				for v126_, _ in pairs(v125_.attacherJointIndices) do
					local v127_ = self:getImplementFromAttacherJointIndex(v126_)
					if v127_ ~= nil then
						v123_ = v127_.object:getInputPowerTakeOffsByJointDescIndexAndName(v127_.inputJointDescIndex, ptoName)
					end
				end
			end
		end
	end
	return v123_
end

function PowerTakeOffs:getInputPowerTakeOffs()
	return self.spec_powerTakeOffs.inputPowerTakeOffs
end

function PowerTakeOffs:getIsPowerTakeOffActive()
	return false
end

-- Local values: spec, outputs, _, output, inputs, _, input
function PowerTakeOffs:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
	local v133_ = self.spec_powerTakeOffs
	local v134_ = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
	for _, v135_ in ipairs(v134_) do
		if attachableObject.getInputPowerTakeOffsByJointDescIndexAndName ~= nil then
			local v136_ = attachableObject:getInputPowerTakeOffsByJointDescIndexAndName(inputJointDescIndex, v135_.ptoName)
			for _, v137_ in ipairs(v136_) do
				v135_.connectedInput = v137_
				v135_.connectedVehicle = attachableObject
				v137_.connectedVehicle = self
				v137_.connectedOutput = v135_
				local v138_ = v133_.delayedPowerTakeOffsMountings
				table.insert(v138_, {
					["jointDescIndex"] = jointDescIndex,
					["input"] = v137_,
					["output"] = v135_
				})
			end
		end
	end
	return true
end

-- Local values: spec, outputs, _, output, input
function PowerTakeOffs:detachPowerTakeOff(detachingVehicle, implement, jointDescIndex)
	self.spec_powerTakeOffs.delayedPowerTakeOffsMountings = {}
	local v143_ = detachingVehicle:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex or implement.jointDescIndex)
	for _, v144_ in ipairs(v143_) do
		if v144_.connectedInput ~= nil then
			local v145_ = v144_.connectedInput
			if v145_.detachFunc ~= nil then
				v145_.detachFunc(self, v145_, v144_)
			end
			if v145_.connectedOutput ~= nil then
				g_animationManager:stopAnimations(v145_.connectedOutput.localAnimationNodes)
				v145_.connectedOutput.isActive = false
				if v145_.connectedVehicle.updateDashboardValueType ~= nil then
					v145_.connectedVehicle:updateDashboardValueType("powerTakeOffs.state")
				end
			end
			v145_.connectedVehicle = nil
			v145_.connectedOutput = nil
			v144_.connectedVehicle = nil
			v144_.connectedInput = nil
			ObjectChangeUtil.setObjectChanges(v145_.objectChanges, false, self, self.setMovingToolDirty)
			ObjectChangeUtil.setObjectChanges(v144_.objectChanges, false, self, self.setMovingToolDirty)
		end
	end
	return true
end

-- Local values: ptoOutputs, ptoOutput, ptoInput, _, y, _
function PowerTakeOffs:checkPowerTakeOffCollision(attacherJointNode, jointDescIndex, isTrailerAttacher)
	if isTrailerAttacher then
		local v150_ = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
		if v150_ ~= nil and #v150_ > 0 then
			local v151_ = v150_[1]
			local v152_ = v151_.connectedInput
			if v152_ ~= nil then
				local _, v153_, _ = localToLocal(v151_.outputNode, attacherJointNode, 0, 0, 0)
				if v152_.aboveAttacher and v153_ < 0 or not v152_.aboveAttacher and v153_ > 0 then
					self:detachPowerTakeOff(self, nil, jointDescIndex)
				end
			end
		end
	end
end

function PowerTakeOffs:parkPowerTakeOff(input)
	if input.detachNode == nil then
		link(input.inputNode, input.linkNode)
		link(input.inputNode, input.startNode)
		setVisibility(input.linkNode, false)
		setVisibility(input.startNode, false)
		input.isLinked = false
	else
		link(input.detachNode, input.linkNode)
		link(input.inputNode, input.startNode)
		self:updatePowerTakeOff(input, 0)
		self:updatePowerTakeOffLength(input)
		input.isLinked = true
	end
	setTranslation(input.linkNode, 0, 0, input.zOffset)
	setTranslation(input.startNode, 0, 0, -input.zOffset)
end

function PowerTakeOffs:onPreAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	self:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
end

-- Local values: spec, i, delayedMounting, input, output
function PowerTakeOffs:onPostAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v162_ = self.spec_powerTakeOffs
	for v163_ = #v162_.delayedPowerTakeOffsMountings, 1, -1 do
		local v164_ = v162_.delayedPowerTakeOffsMountings[v163_]
		if v164_.jointDescIndex == jointDescIndex then
			local v165_ = v164_.input
			local v166_ = v164_.output
			if v165_.attachFunc ~= nil then
				v165_.attachFunc(self, v165_, v166_)
			end
			ObjectChangeUtil.setObjectChanges(v165_.objectChanges, true, self, self.setMovingToolDirty)
			ObjectChangeUtil.setObjectChanges(v166_.objectChanges, true, self, self.setMovingToolDirty)
			table.remove(v162_.delayedPowerTakeOffsMountings, v163_)
		end
	end
end

-- Local values: spec
function PowerTakeOffs:onPreDetachImplement(implement)
	self:detachPowerTakeOff(self, implement)
	if self.isClient then
		local v169_ = self.spec_powerTakeOffs
		g_soundManager:stopSamples(v169_.samples.turnedOn)
	end
end

-- Local values: xmlFile, i3dFilename, arguments
function PowerTakeOffs:loadPowerTakeOffFromConfigFile(powerTakeOff, xmlFilename)
	local v173_ = Utils.getFilename(xmlFilename, self.baseDirectory)
	local v174_ = XMLFile.load("PtoConfig", v173_, PowerTakeOffs.xmlSchema)
	if v174_ == nil then
		Logging.warning("Failed to open powerTakeOff config file \'%s\'", v173_)
		return
	else
		local v175_ = v174_:getValue("powerTakeOff#filename")
		if v175_ == nil then
			Logging.xmlWarning(self.xmlFile, "Failed to open powerTakeOff i3d file \'%s\' in \'%s\'", v175_, v173_)
			v174_:delete()
		else
			local v176_ = Utils.getFilename(v175_, self.baseDirectory)
			powerTakeOff.xmlFile = v174_
			powerTakeOff.sharedLoadRequestId = self:loadSubSharedI3DFile(v176_, false, false, self.onPowerTakeOffI3DLoaded, self, {
				["xmlFile"] = v174_,
				["powerTakeOff"] = powerTakeOff
			})
		end
	end
end

-- Local values: xmlFile, powerTakeOff, materialName, materialName
function PowerTakeOffs:onPowerTakeOffI3DLoaded(i3dNode, failedReason, args)
	local v180_ = args.xmlFile
	local v181_ = args.powerTakeOff
	if i3dNode == 0 then
		if not (self.isDeleted or self.isDeleting) then
			Logging.xmlWarning(self.xmlFile, "Failed to find powerTakeOff in file \'%s\'", v180_.filename)
		end
	else
		v181_.components = {}
		v181_.i3dMappings = {}
		I3DUtil.loadI3DComponents(i3dNode, v181_.components)
		I3DUtil.loadI3DMapping(v180_, "powerTakeOff", v181_.components, v181_.i3dMappings)
		v181_.startNode = v180_:getValue("powerTakeOff.startNode#node", nil, v181_.components, v181_.i3dMappings)
		if v181_.startNode == nil then
			Logging.xmlWarning(v180_, "Failed to find startNode in powerTakeOff file \'%s\'", v180_.filename)
		else
			v181_.size = v180_:getValue("powerTakeOff#size", 0.19)
			v181_.minLength = v180_:getValue("powerTakeOff#minLength", 0.6)
			v181_.maxAngle = v180_:getValue("powerTakeOff#maxAngle", 45)
			v181_.zOffset = v180_:getValue("powerTakeOff#zOffset", 0)
			v181_.animationNodes = g_animationManager:loadAnimations(v180_, "powerTakeOff.animationNodes", v181_.components, self, v181_.i3dMappings)
			if v181_.material ~= nil then
				local v182_ = v180_:getValue("powerTakeOff#colorMaterialName", "powerTakeOff_main_mat")
				v181_.material:apply(v181_.startNode, v182_, true)
			end
			if v181_.decalMaterial ~= nil then
				local v183_ = v180_:getValue("powerTakeOff#decalColorMaterialName", "powerTakeOff_decal_mat")
				v181_.decalMaterial:apply(v181_.startNode, v183_, true)
			end
			if v180_:getValue("powerTakeOff#isSingleJoint") then
				self:loadSingleJointPowerTakeOff(v181_, v180_, v181_.components, v181_.i3dMappings)
			elseif v180_:getValue("powerTakeOff#isDoubleJoint") then
				self:loadDoubleJointPowerTakeOff(v181_, v180_, v181_.components, v181_.i3dMappings)
			else
				self:loadBasicPowerTakeOff(v181_, v180_, v181_.components, v181_.i3dMappings)
			end
			link(v181_.inputNode, v181_.startNode)
			v181_.i3dLoaded = true
			if v181_.isLocal then
				self:placeLocalPowerTakeOff(v181_)
			else
				self:parkPowerTakeOff(v181_)
			end
			self:updatePowerTakeOff(v181_, 0)
		end
		delete(i3dNode)
	end
	v180_:delete()
	v181_.xmlFile = nil
end

-- Local values: _, _, dis, _, _, betweenLength, _, _, ptoLength
function PowerTakeOffs:loadSingleJointPowerTakeOff(powerTakeOff, xmlFile, components, i3dMappings)
	powerTakeOff.startJoint = xmlFile:getValue("powerTakeOff.startJoint#node", nil, components, i3dMappings)
	powerTakeOff.scalePart = xmlFile:getValue("powerTakeOff.scalePart#node", nil, components, i3dMappings)
	powerTakeOff.scalePartRef = xmlFile:getValue("powerTakeOff.scalePart#referenceNode", nil, components, i3dMappings)
	local _, _, v188_ = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
	powerTakeOff.scalePartBaseDistance = v188_
	powerTakeOff.translationPart = xmlFile:getValue("powerTakeOff.translationPart#node", nil, components, i3dMappings)
	powerTakeOff.translationPartRef = xmlFile:getValue("powerTakeOff.translationPart#referenceNode", nil, components, i3dMappings)
	powerTakeOff.translationPartLength = xmlFile:getValue("powerTakeOff.translationPart#length", 0.4)
	powerTakeOff.decal = xmlFile:getValue("powerTakeOff.translationPart.decal#node", nil, components, i3dMappings)
	powerTakeOff.decalSize = xmlFile:getValue("powerTakeOff.translationPart.decal#size", 0.1)
	powerTakeOff.decalOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#offset", 0.05)
	powerTakeOff.decalMinOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#minOffset", 0.01)
	powerTakeOff.endJoint = xmlFile:getValue("powerTakeOff.endJoint#node", nil, components, i3dMappings)
	powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, components, i3dMappings)
	local _, _, v189_ = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
	local _, _, v190_ = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.betweenLength = math.abs(v189_)
	powerTakeOff.connectorLength = math.abs(v190_) - math.abs(v189_)
	setTranslation(powerTakeOff.linkNode, 0, 0, 0)
	setRotation(powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.updateFunc = PowerTakeOffs.updateSingleJointPowerTakeOff
	powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

-- Local values: x, y, z, dx, dy, dz, dist
function PowerTakeOffs:updateSingleJointPowerTakeOff(powerTakeOff, dt)
	local v192_, v193_, v194_ = getWorldTranslation(powerTakeOff.linkNode)
	local v195_, v196_, v197_ = worldToLocal(powerTakeOff.startNode, v192_, v193_, v194_)
	I3DUtil.setDirection(powerTakeOff.startJoint, v195_, v196_, v197_, 0, 1, 0)
	local v198_, v199_, v200_ = worldToLocal(getParent(powerTakeOff.endJoint), v192_, v193_, v194_)
	setTranslation(powerTakeOff.endJoint, 0, 0, MathUtil.vector3Length(v198_, v199_, v200_))
	local v201_ = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)
	setScale(powerTakeOff.scalePart, 1, 1, v201_ / powerTakeOff.scalePartBaseDistance)
end

-- Local values: _, _, dis, _, _, betweenLength, _, _, ptoLength
function PowerTakeOffs:loadDoubleJointPowerTakeOff(powerTakeOff, xmlFile, components, i3dMappings)
	powerTakeOff.startJoint1 = xmlFile:getValue("powerTakeOff.startJoint1#node", nil, components, i3dMappings)
	powerTakeOff.startJoint2 = xmlFile:getValue("powerTakeOff.startJoint2#node", nil, components, i3dMappings)
	powerTakeOff.scalePart = xmlFile:getValue("powerTakeOff.scalePart#node", nil, components, i3dMappings)
	powerTakeOff.scalePartRef = xmlFile:getValue("powerTakeOff.scalePart#referenceNode", nil, components, i3dMappings)
	local _, _, v206_ = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
	powerTakeOff.scalePartBaseDistance = v206_
	powerTakeOff.translationPart = xmlFile:getValue("powerTakeOff.translationPart#node", nil, components, i3dMappings)
	powerTakeOff.translationPartRef = xmlFile:getValue("powerTakeOff.translationPart#referenceNode", nil, components, i3dMappings)
	powerTakeOff.translationPartLength = xmlFile:getValue("powerTakeOff.translationPart#length", 0.4)
	powerTakeOff.decal = xmlFile:getValue("powerTakeOff.translationPart.decal#node", nil, components, i3dMappings)
	powerTakeOff.decalSize = xmlFile:getValue("powerTakeOff.translationPart.decal#size", 0.1)
	powerTakeOff.decalOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#offset", 0.05)
	powerTakeOff.decalMinOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#minOffset", 0.01)
	powerTakeOff.endJoint1 = xmlFile:getValue("powerTakeOff.endJoint1#node", nil, components, i3dMappings)
	powerTakeOff.endJoint1Ref = xmlFile:getValue("powerTakeOff.endJoint1#referenceNode", nil, components, i3dMappings)
	powerTakeOff.endJoint2 = xmlFile:getValue("powerTakeOff.endJoint2#node", nil, components, i3dMappings)
	powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, components, i3dMappings)
	local _, _, v207_ = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
	local _, _, v208_ = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.betweenLength = math.abs(v207_)
	powerTakeOff.connectorLength = math.abs(v208_) - math.abs(v207_)
	setTranslation(powerTakeOff.linkNode, 0, 0, 0)
	setRotation(powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.updateFunc = PowerTakeOffs.updateDoubleJointPowerTakeOff
	powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

-- Local values: x, y, z, dx, dy, dz, dist
function PowerTakeOffs:updateDoubleJointPowerTakeOff(powerTakeOff, dt)
	local v210_, v211_, v212_ = getWorldTranslation(powerTakeOff.startNode)
	local v213_, v214_, v215_ = worldToLocal(getParent(powerTakeOff.endJoint2), v210_, v211_, v212_)
	local v216_, v217_, v218_ = MathUtil.vector3Normalize(v213_, v214_, v215_)
	I3DUtil.setDirection(powerTakeOff.endJoint2, v216_ * 0.5, v217_ * 0.5, (v218_ + 1) * 0.5, 0, 1, 0)
	local v219_, v220_, v221_ = getWorldTranslation(powerTakeOff.endJoint1Ref)
	local v222_, v223_, v224_ = worldToLocal(getParent(powerTakeOff.startJoint1), v219_, v220_, v221_)
	local v225_, v226_, v227_ = MathUtil.vector3Normalize(v222_, v223_, v224_)
	I3DUtil.setDirection(powerTakeOff.startJoint1, v225_ * 0.5, v226_ * 0.5, (v227_ + 1) * 0.5, 0, 1, 0)
	local v228_, v229_, v230_ = getWorldTranslation(powerTakeOff.endJoint1Ref)
	local v231_, v232_, v233_ = worldToLocal(getParent(powerTakeOff.startJoint2), v228_, v229_, v230_)
	local v234_, v235_, v236_ = MathUtil.vector3Normalize(v231_, v232_, v233_)
	I3DUtil.setDirection(powerTakeOff.startJoint2, v234_, v235_, v236_, 0, 1, 0)
	local v237_, v238_, v239_ = worldToLocal(getParent(powerTakeOff.endJoint1), v228_, v229_, v230_)
	setTranslation(powerTakeOff.endJoint1, 0, 0, MathUtil.vector3Length(v237_, v238_, v239_))
	local v240_ = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)
	setScale(powerTakeOff.scalePart, 1, 1, v240_ / powerTakeOff.scalePartBaseDistance)
end

function PowerTakeOffs:loadBasicPowerTakeOff(powerTakeOff, xmlFile, components, i3dMappings)
	powerTakeOff.startNode = xmlFile:getValue("powerTakeOff.startNode#node", nil, components, i3dMappings)
	powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, components, i3dMappings)
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

-- Local values: attachLength, transPartScale, transPartLength, offset, decalTranslation, x, y, _
function PowerTakeOffs:updateDistanceOfTypedPowerTakeOff(powerTakeOff)
	local v246_ = (powerTakeOff.predefinedLength or calcDistanceFrom(powerTakeOff.linkNode, powerTakeOff.startNode)) - powerTakeOff.connectorLength
	local v247_ = math.max(v246_, 0) / powerTakeOff.betweenLength
	setScale(powerTakeOff.translationPart, 1, 1, v247_)
	if powerTakeOff.decal ~= nil then
		local v248_ = v247_ * powerTakeOff.translationPartLength
		if powerTakeOff.decalMinOffset * 2 + powerTakeOff.decalSize < v248_ then
			local v249_ = (v248_ - powerTakeOff.decalSize) / 2
			local v250_ = powerTakeOff.decalOffset
			local v251_ = math.min(v249_, v250_) + powerTakeOff.decalSize * 0.5
			local v252_, v253_, _ = getTranslation(powerTakeOff.decal)
			setTranslation(powerTakeOff.decal, v252_, v253_, -v251_ / v247_)
			setScale(powerTakeOff.decal, 1, 1, 1 / v247_)
			return
		end
		setVisibility(powerTakeOff.decal, false)
	end
end

function PowerTakeOffs:attachTypedPowerTakeOff(powerTakeOff, output)
	if self:validatePowerTakeOffAttachment(powerTakeOff, output) then
		link(output.outputNode, powerTakeOff.linkNode)
		link(powerTakeOff.inputNode, powerTakeOff.startNode)
		setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
		setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
		self:updatePowerTakeOff(powerTakeOff, 0)
		self:updatePowerTakeOffLength(powerTakeOff)
		setVisibility(powerTakeOff.linkNode, true)
		setVisibility(powerTakeOff.startNode, true)
		powerTakeOff.isLinked = true
	end
end

function PowerTakeOffs:detachTypedPowerTakeOff(powerTakeOff, output)
	self:parkPowerTakeOff(powerTakeOff)
end

-- Local values: x1, y1, z1, x2, y2, z2, length, length2D, angle
function PowerTakeOffs:validatePowerTakeOffAttachment(powerTakeOff, output)
	if output.outputNode == nil or powerTakeOff.inputNode == nil then
		return false
	end
	local v261_, v262_, v263_ = getWorldTranslation(output.outputNode)
	local v264_, v265_, v266_ = getWorldTranslation(powerTakeOff.inputNode)
	local v267_ = MathUtil.vector3Length(v261_ - v264_, v262_ - v265_, v263_ - v266_)
	if v267_ < powerTakeOff.minLength then
		return false
	end
	local v268_ = MathUtil.vector2Length(v261_ - v264_, v263_ - v266_) / v267_
	return math.acos(v268_) <= powerTakeOff.maxAngle
end

-- Local values: indices, i, localIndices, i
function PowerTakeOffs:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	local v274_ = xmlFile:getValue(baseName .. ".powerTakeOffs#indices", nil, true)
	if v274_ ~= nil then
		entry.powerTakeOffs = {}
		for v275_ = 1, #v274_ do
			local v276_ = entry.powerTakeOffs
			local v277_ = v274_[v275_]
			table.insert(v276_, v277_)
		end
	end
	local v278_ = xmlFile:getValue(baseName .. ".powerTakeOffs#localIndices", nil, true)
	if v278_ ~= nil then
		entry.localPowerTakeOffs = {}
		for v279_ = 1, #v278_ do
			local v280_ = entry.localPowerTakeOffs
			local v281_ = v278_[v279_]
			table.insert(v280_, v281_)
		end
	end
	return true
end

-- Local values: spec, i, index, spec, i, index
function PowerTakeOffs:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.powerTakeOffs ~= nil then
		local v286_ = self.spec_powerTakeOffs
		for v287_, v288_ in ipairs(part.powerTakeOffs) do
			if v286_.inputPowerTakeOffs[v288_] == nil then
				if self.finishedLoading then
					part.powerTakeOffs[v287_] = nil
					Logging.xmlWarning(self.xmlFile, "Unable to find powerTakeOff index \'%d\' for movingPart/movingTool \'%s\'", v288_, getName(part.node))
				end
			else
				self:updatePowerTakeOff(v286_.inputPowerTakeOffs[v288_], dt)
			end
		end
	end
	if part.localPowerTakeOffs ~= nil then
		local v289_ = self.spec_powerTakeOffs
		for v290_, v291_ in ipairs(part.localPowerTakeOffs) do
			if v289_.localPowerTakeOffs[v291_] == nil then
				if self.finishedLoading then
					part.localPowerTakeOffs[v290_] = nil
					Logging.xmlWarning(self.xmlFile, "Unable to find local powerTakeOff index \'%d\' for movingPart/movingTool \'%s\'", v291_, getName(part.node))
				end
			else
				self:placeLocalPowerTakeOff(v289_.localPowerTakeOffs[v291_], dt)
			end
		end
	end
end

-- Local values: spec, lineColor, _, output, i, node, material, attacherJointDesc
function PowerTakeOffs.consoleCommandTestConnection(vehicle, attacherJointIndex)
	local v294_ = vehicle.spec_powerTakeOffs
	if v294_ ~= nil then
		local v295_ = Color.new(0, 0.5, 1)
		for _, v296_ in pairs(v294_.outputPowerTakeOffs) do
			if v296_.debugLine ~= nil then
				g_debugManager:removeElement(v296_.debugLine)
				v296_.debugLine = nil
			end
			if v296_.debugText ~= nil then
				g_debugManager:removeElement(v296_.debugText)
				v296_.debugText = nil
			end
			for v297_ = getNumOfChildren(v296_.outputNode), 1, -1 do
				delete(getChildAt(v296_.outputNode, v297_ - 1))
			end
			if v296_.attacherJointIndices[attacherJointIndex] == nil then
				ObjectChangeUtil.setObjectChanges(v296_.objectChanges, false, vehicle, vehicle.setMovingToolDirty)
			else
				local v298_ = g_i3DManager:loadI3DFile("data/shared/assets/powerTakeOffs/walterscheidW.i3d", false, false)
				if v298_ ~= 0 then
					link(v296_.outputNode, v298_)
					setTranslation(v298_, 0, 0, 0.045)
					setRotation(v298_, 0, 3.141592653589793, 0)
					setVisibility(getChildAt(getChildAt(v298_, 0), 0), false)
					local v299_ = VehicleMaterial.new()
					v299_.colorScale = {
						1,
						0,
						1,
						1
					}
					v299_:apply(v298_)
				end
				ObjectChangeUtil.setObjectChanges(v296_.objectChanges, true, vehicle, vehicle.setMovingToolDirty)
				local v300_ = vehicle:getAttacherJointByJointDescIndex(attacherJointIndex)
				if v300_ ~= nil then
					v296_.debugLine = DebugLine.new():createWithStartAndEndNode(v300_.jointTransform, v296_.outputNode, false, true, 100, true)
					v296_.debugLine:setColors(v295_, v295_)
					g_debugManager:addElement(v296_.debugLine, nil, nil, math.huge)
					v296_.debugText = DebugText.new():createWithNode(v296_.outputNode, getName(v296_.outputNode), 0.01, true)
					g_debugManager:addElement(v296_.debugText, nil, nil, math.huge)
				end
			end
		end
	end
end

fun-- Local values: x, y, z, dirX, dirZ, ry, _, powerTakeOff, files, rowIndex, rowPosition, lastBasePath, lastName, _, file, linkNode, name, basePath, wx, wy, wz, rx, ry, rz, x, y, z, typeIndex, dummyVehicle, k, v, powerTakeOff, filename
ction PowerTakeOffs.consoleCommandDebug(_)
	if PowerTakeOffs.debugRootNode == nil then
		PowerTakeOffs.debugRootNode = createTransformGroup("powerTakeOffsDebugRoot")
		link(getRootNode(), PowerTakeOffs.debugRootNode)
		local v301_, v302_, v303_ = g_localPlayer:getPosition()
		local v304_, v305_ = g_localPlayer:getCurrentFacingDirection()
		local v306_ = v301_ + v304_ * 4
		local v307_ = v303_ + v305_ * 4
		local v308_ = MathUtil.getYRotationFromDirection(v304_, v305_)
		setWorldTranslation(PowerTakeOffs.debugRootNode, v306_, v302_, v307_)
		setWorldRotation(PowerTakeOffs.debugRootNode, 0, v308_, 0)
	end
	if PowerTakeOffs.debugPowerTakeOffs ~= nil then
		for _, v309_ in ipairs(PowerTakeOffs.debugPowerTakeOffs) do
			g_currentMission:removeUpdateable(v309_)
			if v309_.xmlFile ~= nil then
				v309_.xmlFile:delete()
			end
			if v309_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v309_.sharedLoadRequestId)
				v309_.sharedLoadRequestId = nil
			end
			g_animationManager:deleteAnimations(v309_.animationNodes)
			g_animationManager:deleteAnimations(v309_.localAnimationNodes)
			delete(v309_.inputNode)
		end
	end
	PowerTakeOffs.debugPowerTakeOffs = {}
	local v310_ = Files.getFilesRecursive(getAppBasePath() .. "data/shared/assets/powerTakeOffs")
	table.sort(v310_, function(p311_, p312_)
		return p311_.path < p312_.path
	end)
	local v313_ = nil
	local v314_ = nil
	local v315_ = 0
	local v316_ = 0
	for _, v317_ in ipairs(v310_) do
		if not v317_.isDirectory and v317_.filename:contains(".xml") then
			local v318_ = createTransformGroup("linkNode")
			link(PowerTakeOffs.debugRootNode, v318_)
			local v319_ = v317_.filename
			local v320_ = string.gsub(v319_, ".xml", "")
			local v321_ = v317_.path:split(v317_.filename)[1]
			local v322_
			if v321_ == v313_ and v320_ == v314_ then
				v320_ = v314_
				v321_ = v313_
				v322_ = v316_
			else
				v315_ = v315_ + 1
				local v323_, v324_, v325_ = localToWorld(PowerTakeOffs.debugRootNode, v315_ * 2, 1, -1)
				local v326_, v327_, v328_ = localRotationToWorld(PowerTakeOffs.debugRootNode, -1.5707963267948966, 3.141592653589793, 0)
				g_debugManager:addElement(DebugText3D.new():createWithWorldPos(v323_, v324_, v325_, v326_, v327_, v328_, v320_, 0.15), nil, nil, math.huge)
				v322_ = 0
			end
			local v329_ = v315_ * 2
			v316_ = v322_ + 1
			setTranslation(v318_, v329_, 1, v322_)
			setRotation(v318_, 0, 0, 0)
			v314_ = v320_
			v313_ = v321_
			for v_u_330_ = 1, 3 do
				local v_u_331_ = {
					["baseDirectory"] = ""
				}
				for v332_, v333_ in pairs(PowerTakeOffs) do
					v_u_331_[v332_] = v333_
				end
				function v_u_331_.onPowerTakeOffI3DLoaded(p334_, p335_, p336_, p337_)
					-- upvalues: (copy) v_u_330_, (copy) v_u_331_
					local v338_ = p337_.xmlFile:getValue("powerTakeOff#colorMaterialName", "powerTakeOff_main_mat")
					local v339_ = p337_.xmlFile:getValue("powerTakeOff#decalColorMaterialName", "powerTakeOff_decal_mat")
					PowerTakeOffs.onPowerTakeOffI3DLoaded(p334_, p335_, p336_, p337_)
					if p335_ ~= 0 then
						local v340_ = p337_.powerTakeOff
						if v_u_330_ == 2 then
							v340_.material = VehicleMaterial.new()
							v340_.material.colorScale = {
								0,
								1,
								1,
								1
							}
							v340_.material:apply(v340_.inputNode, v338_)
							v340_.decalMaterial = VehicleMaterial.new()
							v340_.decalMaterial.colorScale = {
								1,
								0,
								1,
								1
							}
							v340_.decalMaterial:apply(v340_.inputNode, v339_)
						elseif v_u_330_ == 3 then
							g_animationManager:startAnimations(v340_.animationNodes)
							v_u_331_.dynamicPowerTakeOff = v340_
							v_u_331_.time = 0
							function v_u_331_.update(p341_, p342_)
								p341_.time = (p341_.time + p342_) % 2500
								local v343_ = p341_.time / 2500
								setTranslation(p341_.dynamicPowerTakeOff.detachNode, v343_ * 0.5, v343_, -1.5)
								if p341_.dynamicPowerTakeOff.updateFunc ~= nil then
									p341_.dynamicPowerTakeOff.updateFunc(_, p341_.dynamicPowerTakeOff, p342_)
								end
							end
							g_currentMission:addUpdateable(v_u_331_, v340_)
						end
						local v344_ = PowerTakeOffs.debugPowerTakeOffs
						table.insert(v344_, v340_)
					end
				end
				function v_u_331_.loadSubSharedI3DFile(_, p345_, p346_, p347_, p348_, p349_, p350_)
					return g_i3DManager:loadSharedI3DFileAsync(p345_, p346_, p347_, p348_, p349_, p350_)
				end
				local v351_ = {
					["inputNode"] = createTransformGroup("inputNode")
				}
				link(v318_, v351_.inputNode)
				setTranslation(v351_.inputNode, 0, 0, v_u_330_ * 3)
				setRotation(v351_.inputNode, 0, 3.141592653589793, 0)
				v351_.detachNode = createTransformGroup("detachNode")
				link(v351_.inputNode, v351_.detachNode)
				setTranslation(v351_.detachNode, 0, 0, -1.5)
				setRotation(v351_.detachNode, 0, 0, 0)
				local v352_ = string.gsub(v317_.path, getAppBasePath(), "")
				PowerTakeOffs.loadPowerTakeOffFromConfigFile(v_u_331_, v351_, v352_)
				g_debugManager:addElement(DebugGizmo.new():createWithNode(v351_.inputNode, "start", nil, nil, 0.25), nil, nil, math.huge)
				g_debugManager:addElement(DebugGizmo.new():createWithNode(v351_.detachNode, "end", nil, nil, 0.25), nil, nil, math.huge)
				v320_ = v314_
				v321_ = v313_
				v314_ = v320_
				v313_ = v321_
			end
		end
	end
end
addConsoleCommand("gsVehicleDebugPowerTakeOffs", "Spawns all power take offs in front of the player", "PowerTakeOffs.consoleCommandDebug", nil)
