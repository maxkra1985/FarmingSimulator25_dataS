AIVehicle = {}

function AIVehicle.prerequisitesPresent(self)
	return true
end
function AIVehicle.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("AIVehicle")
	AIVehicle.registerAgentAttachmentPaths(v1_, "vehicle.ai", true)
	v1_:setXMLSpecializationType()
end

function AIVehicle.registerAgentAttachmentPaths(schema, basePath, includeSubAttachments)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".agentAttachment(?)#jointNode", "Custom joint node (if not defined the current attacher joint is used)")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".agentAttachment(?)#rotCenterWheelIndices", "The center of these wheel indices define the steering center")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".agentAttachment(?)#rotCenterNode", "Custom node to define the steering center")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".agentAttachment(?)#rotCenterPosition", "Offset from root component that defines the steering center")
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#width", "Agent attachable width", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#height", "Agent attachable height", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#heightOffset", "Agent attachable height offset (only for visual debug)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#length", "Agent attachable length", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#lengthOffset", "Agent attachable length offset from rot center", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".agentAttachment(?)#hasCollision", "Agent attachable is doing collision checks", true)
	schema:register(XMLValueType.BOOL, basePath .. ".agentAttachment(?)#useSize", "Use the vehicle size definition for the agentAttachment size as well (for static tools)", false)
	if includeSubAttachments then
		AIVehicle.registerAgentAttachmentPaths(schema, basePath .. ".agentAttachment(?)", false)
	end
end

function AIVehicle.registerEvents(self)
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldCourseSettingsInitialized")
	SpecializationUtil.registerEvent(vehicleType, "onPostAIFieldCourseSettingsInitialized")
end

function AIVehicle.registerFunctions(self)
	SpecializationUtil.registerFunction(vehicleType, "collectAIAgentAttachments", AIVehicle.collectAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "registerAIAgentAttachment", AIVehicle.registerAIAgentAttachment)
	SpecializationUtil.registerFunction(vehicleType, "loadAIAgentAttachmentsFromXML", AIVehicle.loadAIAgentAttachmentsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "validateAIAgentAttachments", AIVehicle.validateAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "drawAIAgentAttachments", AIVehicle.drawAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "raiseAIEvent", AIVehicle.raiseAIEvent)
	SpecializationUtil.registerFunction(vehicleType, "safeRaiseAIEvent", AIVehicle.safeRaiseAIEvent)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIReadyToDrive", AIVehicle.getIsAIReadyToDrive)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIPreparingToDrive", AIVehicle.getIsAIPreparingToDrive)
end

function AIVehicle.registerOverwrittenFunctions(self) end

function AIVehicle.registerEventListeners(self)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIVehicle)
end

-- Local values: spec, baseName
function AIVehicle:onLoad(savegame)
	local v9_ = self.spec_aiVehicle
	v9_.agentAttachments = {}
	if self.getInputAttacherJoints ~= nil then
		self:loadAIAgentAttachmentsFromXML(self.xmlFile, "vehicle.ai.agentAttachment", v9_.agentAttachments)
	end
	v9_.debugSizeBox = DebugBox.new()
	v9_.debugSizeBox:setColorRGBA(0, 1, 1)
	v9_.debugSizeBox:setText("aiAgentAttachment")
end

-- Local values: spec, inputAttacherJoints
function AIVehicle:onPostLoad(savegame)
	local v11_ = self.spec_aiVehicle
	if #v11_.agentAttachments > 0 then
		local v12_ = self:getInputAttacherJoints()
		self:validateAIAgentAttachments(v11_.agentAttachments, v12_)
	end
end

-- Local values: spec, inputAttacherJointDesc, jointDesc, usedExplicitAttachment, i, agentAttachment, i, agentAttachment, i, agentAttachment
function AIVehicle:collectAIAgentAttachments(aiDrivableVehicle)
	local v15_ = self.spec_aiVehicle
	if #v15_.agentAttachments > 0 then
		local v16_ = self:getActiveInputAttacherJoint()
		if v16_ ~= nil then
			local v17_ = self:getAttacherVehicle():getAttacherJointDescFromObject(self)
			local v18_ = false
			for v19_ = 1, #v15_.agentAttachments do
				local v20_ = v15_.agentAttachments[v19_]
				if v20_.jointNode == v16_.node then
					v20_.attacherVehicleJointNode = v17_.jointTransform
					self:registerAIAgentAttachment(aiDrivableVehicle, v20_)
					v18_ = true
				end
			end
			if not v18_ then
				for v21_ = 1, #v15_.agentAttachments do
					local v22_ = v15_.agentAttachments[v21_]
					if v22_.isDirectAttachment then
						v22_.attacherVehicleJointNode = v17_.jointTransform
						v22_.jointNodeDynamic = v16_.node
						self:registerAIAgentAttachment(aiDrivableVehicle, v22_)
						break
					end
				end
			end
			for v23_ = 1, #v15_.agentAttachments do
				local v24_ = v15_.agentAttachments[v23_]
				if not v24_.isDirectAttachment then
					self:registerAIAgentAttachment(aiDrivableVehicle, v24_)
				end
			end
		end
	end
end

-- Local values: i, subAgentAttachment
function AIVehicle:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)
	aiDrivableVehicle:addAIAgentAttachment(agentAttachment)
	for v27_ = 1, #agentAttachment.agentAttachments do
		aiDrivableVehicle:addAIAgentAttachment(agentAttachment.agentAttachments[v27_])
	end
end

function AIVehicle:loadAIAgentAttachmentsFromXML(xmlFile, baseKey, agentAttachments, loadSubAttachments, requiresJointNode)
	xmlFile:iterate(baseKey, function(_, p34_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) loadSubAttachments, (copy) requiresJointNode, (copy) agentAttachments
		local v35_ = {
			["jointNode"] = xmlFile:getValue(p34_ .. "#jointNode", nil, self.components, self.i3dMappings),
			["jointNodeDynamic"] = nil,
			["rotCenterNode"] = xmlFile:getValue(p34_ .. "#rotCenterNode", nil, self.components, self.i3dMappings),
			["rotCenterWheelIndices"] = xmlFile:getValue(p34_ .. "#rotCenterWheelIndices", nil, true),
			["rotCenterPosition"] = xmlFile:getValue(p34_ .. "#rotCenterPosition", nil, true),
			["useSize"] = xmlFile:getValue(p34_ .. "#useSize", false)
		}
		if v35_.useSize then
			v35_.width = self.size.width
			v35_.height = self.size.height
			v35_.heightOffset = self.size.heightOffset
			v35_.length = self.size.length
			v35_.lengthOffset = self.size.lengthOffset
		else
			v35_.width = 3
			v35_.height = 3
			v35_.heightOffset = 0
			v35_.length = 3
			v35_.lengthOffset = 0
		end
		v35_.width = xmlFile:getValue(p34_ .. "#width", v35_.width)
		v35_.height = xmlFile:getValue(p34_ .. "#height", v35_.height)
		v35_.heightOffset = xmlFile:getValue(p34_ .. "#heightOffset", v35_.heightOffset)
		v35_.length = xmlFile:getValue(p34_ .. "#length", v35_.length)
		v35_.lengthOffset = xmlFile:getValue(p34_ .. "#lengthOffset", v35_.lengthOffset)
		v35_.hasCollision = xmlFile:getValue(p34_ .. "#hasCollision", true)
		v35_.isDirectAttachment = false
		v35_.agentAttachments = {}
		if loadSubAttachments ~= false then
			self:loadAIAgentAttachmentsFromXML(xmlFile, p34_ .. ".agentAttachment", v35_.agentAttachments, false, true)
		end
		if requiresJointNode == true and v35_.jointNode == nil then
			Logging.xmlWarning(xmlFile, "No joint node defined for ai agent sub attachable \'%s\'!", p34_)
		else
			local v36_ = agentAttachments
			table.insert(v36_, v35_)
		end
	end)
	if loadSubAttachments == nil and #agentAttachments == 0 then
		Logging.xmlWarning(xmlFile, "Missing ai agent attachment definition for attachable vehicle")
	end
end

-- Local values: i, agentAttachment, j, rotCenterNode, wheels, x, y, z, dirX, dirY, dirZ, numWheels, component, j, wheelIndex, wheel, wx, wy, wz, dx, dy, dz, rotCenterNode, j, _, _, z, _
function AIVehicle:validateAIAgentAttachments(agentAttachments, inputAttacherJoints)
	for v40_ = 1, #agentAttachments do
		local v41_ = agentAttachments[v40_]
		for v42_ = 1, #inputAttacherJoints do
			if v41_.jointNode == nil or v41_.jointNode == inputAttacherJoints[v42_].node then
				v41_.isDirectAttachment = true
			end
		end
		if v41_.rotCenterNode == nil then
			if v41_.rotCenterPosition == nil or #v41_.rotCenterPosition ~= 2 then
				if v41_.rotCenterWheelIndices ~= nil and (#v41_.rotCenterWheelIndices > 0 and self.getWheels ~= nil) then
					local v43_ = self:getWheels()
					local v44_ = nil
					local v45_ = 0
					local v46_ = 0
					local v47_ = 0
					local v48_ = 0
					local v49_ = 0
					local v50_ = 0
					local v51_ = 0
					for v52_ = 1, #v41_.rotCenterWheelIndices do
						local v53_ = v41_.rotCenterWheelIndices[v52_]
						local v54_ = v43_[v53_]
						if v54_ == nil then
							Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%d\' ground in ai agent attachment entry \'vehicle.ai.agentAttachment(%d)\'!", v53_, v40_ - 1)
						else
							v44_ = v44_ or v54_.node
							local v55_, v56_, v57_ = localToLocal(v54_.repr, v44_, 0, -v54_.physics.radius, 0)
							local v58_, v59_, v60_ = localDirectionToLocal(v54_.driveNode, v44_, 0, 0, 1)
							v45_ = v45_ + v55_
							v46_ = v46_ + v56_
							v47_ = v47_ + v57_
							v48_ = v48_ + v58_
							v49_ = v49_ + v59_
							v51_ = v51_ + v60_
							v50_ = v50_ + 1
						end
					end
					if v50_ > 0 then
						v45_ = v45_ / v50_
						v46_ = v46_ / v50_
						v47_ = v47_ / v50_
						v48_ = v48_ / v50_
						v49_ = v49_ / v50_
						v51_ = v51_ / v50_
					end
					local v61_, v62_, v63_ = MathUtil.vector3Normalize(v48_, v49_, v51_)
					if v41_.useSize then
						v41_.lengthOffset = self.size.lengthOffset - v47_
					end
					local v64_ = createTransformGroup("aiAgentAttachmentRotCenter" .. v40_)
					link(v44_, v64_)
					setTranslation(v64_, v45_, v46_, v47_)
					v41_.rotCenterNode = v64_
					if v50_ > 0 and MathUtil.vector3Length(v61_, v62_, v63_) > 0 then
						setDirection(v64_, v61_, v62_, v63_, 0, 1, 0)
					end
				end
			else
				local v65_ = createTransformGroup("aiAgentAttachmentRotCenter" .. v40_)
				link(self.components[1].node, v65_)
				setTranslation(v65_, v41_.rotCenterPosition[1], 0, v41_.rotCenterPosition[2])
				v41_.rotCenterNode = v65_
			end
		end
		if v41_.rotCenterNode == nil then
			v41_.rootNode = self.rootNode
		end
		if v41_.rotCenterNode ~= nil then
			if v41_.jointNode == nil then
				v41_.jointNodeToHitchOffset = {}
				for v66_ = 1, #inputAttacherJoints do
					local _, _, v67_ = localToLocal(inputAttacherJoints[v66_].node, v41_.rotCenterNode, 0, 0, 0)
					v41_.jointNodeToHitchOffset[inputAttacherJoints[v66_].node] = v67_
				end
			else
				local _, _, v68_ = localToLocal(v41_.jointNode, v41_.rotCenterNode, 0, 0, 0)
				v41_.trailerHitchOffset = v68_
			end
		end
		self:validateAIAgentAttachments(v41_.agentAttachments, inputAttacherJoints)
	end
end

-- Local values: spec, i, agentAttachment
function AIVehicle:drawAIAgentAttachments(agentAttachments)
	local v71_ = self.spec_aiVehicle
	local v72_ = agentAttachments or v71_.agentAttachments
	for v73_ = 1, #v72_ do
		local v74_ = v72_[v73_]
		if v74_.rotCenterNode == nil then
			v71_.debugSizeBox:setColorRGBA(0, 0.15, 1)
			v71_.debugSizeBox:createWithNode(v74_.rootNode, v74_.width, v74_.height, v74_.length, 0, v74_.height * 0.5 + v74_.heightOffset, v74_.lengthOffset)
			v71_.debugSizeBox:draw()
		else
			v71_.debugSizeBox:setColorRGBA(0, 1, 0.25)
			v71_.debugSizeBox:createWithNode(v74_.rotCenterNode, v74_.width, v74_.height, v74_.length, 0, v74_.height * 0.5 + v74_.heightOffset, v74_.lengthOffset)
			v71_.debugSizeBox:draw()
		end
		self:drawAIAgentAttachments(v74_.agentAttachments)
	end
end
function AIVehicle.raiseAIEvent(p75_, p76_, p77_, ...)
	local v78_ = p75_.rootVehicle.actionController
	for _, v79_ in ipairs(p75_.rootVehicle.childVehicles) do
		if v79_ ~= p75_ then
			p75_:safeRaiseAIEvent(v79_, p77_, ...)
			if v78_ ~= nil then
				v78_:onAIEvent(v79_, p77_)
			end
		end
	end
	p75_:safeRaiseAIEvent(p75_, p77_, ...)
	if v78_ ~= nil then
		v78_:onAIEvent(p75_, p77_)
	end
	p75_:safeRaiseAIEvent(p75_, p76_, ...)
	if v78_ ~= nil then
		v78_:onAIEvent(p75_, p76_)
	end
end
function AIVehicle.safeRaiseAIEvent(_, p80_, p81_, ...)
	if p80_.eventListeners[p81_] ~= nil then
		SpecializationUtil.raiseEvent(p80_, p81_, ...)
	end
end

function AIVehicle.getIsAIReadyToDrive(self)
	return true
end

function AIVehicle:getIsAIPreparingToDrive()
	return false
end
