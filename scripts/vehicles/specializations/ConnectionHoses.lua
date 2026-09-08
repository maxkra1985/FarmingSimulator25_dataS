-- Local values: ADDITIONAL_TOOL_CONNECTION_HOSES, ADDITIONAL_TOOL_CONNECTION_HOSES_XML, addHoseTarget
ConnectionHoses = {}
ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE = 50
source("dataS/scripts/vehicles/specializations/components/ToolConnectionHoseMount.lua")

function ConnectionHoses.prerequisitesPresent(self)
	return true
end
function ConnectionHoses.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ConnectionHoses")
	v1_:register(XMLValueType.FLOAT, "vehicle.connectionHoses#maxUpdateDistance", "Max. distance to vehicle root to update connection hoses", ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE)
	ConnectionHoses.registerConnectionHoseXMLPaths(v1_, "vehicle.connectionHoses")
	ConnectionHoses.registerConnectionHoseXMLPaths(v1_, "vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.connectionHoses.sounds", "connect(?)")
	v1_:register(XMLValueType.STRING, "vehicle.connectionHoses.sounds.connect(?)#type", "Connection hose type")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.connectionHoses.sounds", "disconnect(?)")
	v1_:register(XMLValueType.STRING, "vehicle.connectionHoses.sounds.disconnect(?)#type", "Connection hose type")
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p2_, p3_)
		p2_:register(XMLValueType.VECTOR_N, p3_ .. ".connectionHoses#customHoseIndices", "Custom hoses to update")
		p2_:register(XMLValueType.VECTOR_N, p3_ .. ".connectionHoses#customTargetIndices", "Custom hose targets to update")
		p2_:register(XMLValueType.VECTOR_N, p3_ .. ".connectionHoses#localHoseIndices", "Local hoses to update")
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p4_, p5_)
		p4_:register(XMLValueType.VECTOR_N, p5_ .. ".connectionHoses#customHoseIndices", "Custom hoses to update")
		p4_:register(XMLValueType.VECTOR_N, p5_ .. ".connectionHoses#customTargetIndices", "Custom hose targets to update")
		p4_:register(XMLValueType.VECTOR_N, p5_ .. ".connectionHoses#localHoseIndices", "Local hoses to update")
	end)
	v1_:setXMLSpecializationType()
end

function ConnectionHoses.registerConnectionHoseXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".skipNode(?)#node", "Skip node")
	schema:register(XMLValueType.INT, basePath .. ".skipNode(?)#inputAttacherJointIndex", "Input attacher joint index", 1)
	schema:register(XMLValueType.INT, basePath .. ".skipNode(?)#attacherJointIndex", "Attacher joint index", 1)
	schema:register(XMLValueType.STRING, basePath .. ".skipNode(?)#type", "Connection hose type")
	schema:register(XMLValueType.STRING, basePath .. ".skipNode(?)#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
	schema:register(XMLValueType.FLOAT, basePath .. ".skipNode(?)#length", "Hose length")
	schema:register(XMLValueType.BOOL, basePath .. ".skipNode(?)#isTwoPointHose", "Is two point hose without sagging", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".skipNode(?)")
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".target(?)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".toolConnectorHose(?)#mountingNode", "Mounting node to toggle visibility")
	schema:register(XMLValueType.BOOL, basePath .. ".toolConnectorHose(?)#moveNodes", "Defines if the start and end nodes are moved up depending on hose diameter", true)
	schema:register(XMLValueType.BOOL, basePath .. ".toolConnectorHose(?)#additionalHose", "Defines if between start and end node a additional hose is created", true)
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".toolConnectorHose(?).startTarget(?)")
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".toolConnectorHose(?).endTarget(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".toolConnectorHose(?)")
	ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath .. ".hose(?)")
	ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath .. ".localHose(?).hose")
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".localHose(?).target")
	ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath .. ".customHose(?)")
	ConnectionHoses.registerCustomHoseTargetNodesXMLPaths(schema, basePath .. ".customTarget(?)")
end

function ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath)
	schema:addDelayedRegistrationPath(basePath, "ConnectionHoses:targetNode")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "List of corresponding attacher joint indices")
	schema:register(XMLValueType.NODE_INDICES, basePath .. "#attacherJointNodes", "List of corresponding attacher joint nodes (i3dIdentifiers or paths separated by space)")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type")
	schema:registerAutoCompletionDataSource(basePath .. "#type", "data/shared/connectionHoses/connectionHoses.xml", "connectionHoses.connectionHoseTypes.connectionHoseType#name")
	schema:register(XMLValueType.STRING, basePath .. "#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
	schema:register(XMLValueType.FLOAT, basePath .. "#straighteningFactor", "Straightening Factor", 1)
	schema:register(XMLValueType.VECTOR_3, basePath .. "#straighteningDirection", "Straightening direction", "0 0 1")
	schema:register(XMLValueType.STRING, basePath .. "#socket", "Socket name to load")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#socketMaterialTemplateName", "Socket custom material")
	schema:registerAutoCompletionDataSource(basePath .. "#socketMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.STRING, basePath .. "#adapterType", "Adapter type to use", "DEFAULT")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "List of corresponding input attacher joint indices")
	schema:register(XMLValueType.NODE_INDICES, basePath .. "#inputAttacherJointNodes", "List of corresponding input attacher joint nodes (i3dIdentifiers or paths separated by space)")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type")
	schema:register(XMLValueType.STRING, basePath .. "#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
	schema:register(XMLValueType.STRING, basePath .. "#hoseType", "Hose material type", "DEFAULT")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Hose output node")
	schema:register(XMLValueType.BOOL, basePath .. "#isTwoPointHose", "Is two point hose without sagging", false)
	schema:register(XMLValueType.BOOL, basePath .. "#isWorldSpaceHose", "Sagging is calculated in world space or local space of hose node", true)
	schema:register(XMLValueType.STRING, basePath .. "#dampingRange", "Damping range in meters", 0.05)
	schema:register(XMLValueType.FLOAT, basePath .. "#dampingFactor", "Damping factor", 50)
	schema:register(XMLValueType.FLOAT, basePath .. "#length", "Hose length", 3)
	schema:register(XMLValueType.BOOL, basePath .. "#dynamicLength", "Use will calculate the length on attach", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#diameter", "Hose diameter", 0.02)
	schema:register(XMLValueType.FLOAT, basePath .. "#straighteningFactor", "Straightening Factor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#centerPointDropFactor", "Can be used to manipulate how much the hose will drop while it\'s getting shorter then set", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#centerPointTension", "Defines the tension on the center control point (0: default behavior)", 0)
	schema:register(XMLValueType.ANGLE, basePath .. "#minCenterPointAngle", "Min. angle of sagged curve", "Defined on connectionHose xml, default 90 degree")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#minCenterPointOffset", "Min. center point offset from hose node", "unlimited")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#maxCenterPointOffset", "Max. center point offset from hose node", "unlimited")
	schema:register(XMLValueType.FLOAT, basePath .. "#minDeltaY", "Min. delta Y from center point")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#minDeltaYComponent", "Min. delta Y reference node")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#materialTemplateName", "Hose material")
	schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#adapterMaterialTemplateName", "Material of colorable part of adapter")
	schema:registerAutoCompletionDataSource(basePath .. "#adapterMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.STRING, basePath .. "#adapterType", "Adapter type name")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#adapterNode", "Link node for detached adapter")
	schema:register(XMLValueType.STRING, basePath .. "#outgoingAdapter", "Adapter type that is used for outgoing connection hose")
	schema:register(XMLValueType.STRING, basePath .. "#socket", "Outgoing socket name to load")
	schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#socketMaterialTemplateName", "Socket custom material")
	schema:registerAutoCompletionDataSource(basePath .. "#socketMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target or source node")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type which can be any string that needs to match between hose and target node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
	schema:register(XMLValueType.BOOL, basePath .. "#isActiveDirty", "Custom hose is permanently updated", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerCustomHoseTargetNodesXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target or source node")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type which can be any string that needs to match between hose and target node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionHoseConfigIndex", ConnectionHoses.getConnectionHoseConfigIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateAttachedConnectionHoses", ConnectionHoses.updateAttachedConnectionHoses)
	SpecializationUtil.registerFunction(vehicleType, "updateConnectionHose", ConnectionHoses.updateConnectionHose)
	SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngle", ConnectionHoses.getCenterPointAngle)
	SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngleRegulation", ConnectionHoses.getCenterPointAngleRegulation)
	SpecializationUtil.registerFunction(vehicleType, "loadConnectionHosesFromXML", ConnectionHoses.loadConnectionHosesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseSkipNode", ConnectionHoses.loadHoseSkipNode)
	SpecializationUtil.registerFunction(vehicleType, "loadToolConnectorHoseNode", ConnectionHoses.loadToolConnectorHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "addHoseTargetNodes", ConnectionHoses.addHoseTargetNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadCustomHosesFromXML", ConnectionHoses.loadCustomHosesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseTargetNode", ConnectionHoses.loadHoseTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseNode", ConnectionHoses.loadHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "getClonedSkipHoseNode", ConnectionHoses.getClonedSkipHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionTarget", ConnectionHoses.getConnectionTarget)
	SpecializationUtil.registerFunction(vehicleType, "iterateConnectionTargets", ConnectionHoses.iterateConnectionTargets)
	SpecializationUtil.registerFunction(vehicleType, "getIsConnectionTargetUsed", ConnectionHoses.getIsConnectionTargetUsed)
	SpecializationUtil.registerFunction(vehicleType, "getIsConnectionHoseUsed", ConnectionHoses.getIsConnectionHoseUsed)
	SpecializationUtil.registerFunction(vehicleType, "getIsSkipNodeAvailable", ConnectionHoses.getIsSkipNodeAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionHosesByInputAttacherJoint", ConnectionHoses.getConnectionHosesByInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "connectHose", ConnectionHoses.connectHose)
	SpecializationUtil.registerFunction(vehicleType, "disconnectHose", ConnectionHoses.disconnectHose)
	SpecializationUtil.registerFunction(vehicleType, "updateToolConnectionHose", ConnectionHoses.updateToolConnectionHose)
	SpecializationUtil.registerFunction(vehicleType, "addHoseToDelayedMountings", ConnectionHoses.addHoseToDelayedMountings)
	SpecializationUtil.registerFunction(vehicleType, "connectHoseToSkipNode", ConnectionHoses.connectHoseToSkipNode)
	SpecializationUtil.registerFunction(vehicleType, "connectHosesToAttacherVehicle", ConnectionHoses.connectHosesToAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "retryHoseSkipNodeConnections", ConnectionHoses.retryHoseSkipNodeConnections)
	SpecializationUtil.registerFunction(vehicleType, "connectCustomHosesToAttacherVehicle", ConnectionHoses.connectCustomHosesToAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "connectCustomHoseNode", ConnectionHoses.connectCustomHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "updateCustomHoseNode", ConnectionHoses.updateCustomHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "disconnectCustomHoseNode", ConnectionHoses.disconnectCustomHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "setConnectionHosesActive", ConnectionHoses.setConnectionHosesActive)
end

function ConnectionHoses.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ConnectionHoses.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ConnectionHoses.updateExtraDependentParts)
end

function ConnectionHoses.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", ConnectionHoses)
end

-- Local values: spec
function ConnectionHoses:onPreLoad(savegame)
	local v20_ = self.spec_connectionHoses
	v20_.configIndex = self:getConnectionHoseConfigIndex()
	v20_.connectionHosesActive = true
	v20_.numHosesByType = {}
	v20_.numToolConnectionsByType = {}
	v20_.hoseSkipNodes = {}
	v20_.hoseSkipNodeByType = {}
	v20_.targetNodes = {}
	v20_.targetNodesByType = {}
	v20_.toolConnectorHoses = {}
	v20_.targetNodeToToolConnection = {}
	v20_.hoseNodes = {}
	v20_.hoseNodesByInputAttacher = {}
	v20_.localHoseNodes = {}
	v20_.customHoses = {}
	v20_.customHosesByAttacher = {}
	v20_.customHosesByInputAttacher = {}
	v20_.customHosesActiveDirty = {}
	v20_.customHoseTargets = {}
	v20_.customHoseTargetsByAttacher = {}
	v20_.customHoseTargetsByInputAttacher = {}
	v20_.additionalSharedLoadRequestIds = {}
	v20_.toolConnectionHoseMounts = {}
	v20_.maxUpdateDistance = self.xmlFile:getValue("vehicle.connectionHoses#maxUpdateDistance", ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE)
end

-- Local values: spec, configKey, loadSamplesFromKey
function ConnectionHoses:onPostLoad(savegame)
	local v_u_22_ = self.spec_connectionHoses
	local v23_ = string.format("vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(%d)", v_u_22_.configIndex - 1)
	self:loadConnectionHosesFromXML(self.xmlFile, "vehicle.connectionHoses")
	if self.xmlFile:hasProperty(v23_) then
		self:loadConnectionHosesFromXML(self.xmlFile, v23_)
	end
	ConnectionHoses.registerAdditionalToolConnectionHoses(self)
	v_u_22_.targetNodesAvailable = #v_u_22_.targetNodes > 0
	v_u_22_.hoseNodesAvailable = #v_u_22_.hoseNodes > 0
	v_u_22_.localHosesAvailable = #v_u_22_.localHoseNodes > 0
	v_u_22_.skipNodesAvailable = #v_u_22_.hoseSkipNodes > 0
	v_u_22_.activeDirtyCustomHosesAvailable = #v_u_22_.customHosesActiveDirty > 0
	v_u_22_.updateableHoses = {}
	if self.isClient then
		local function v33_(p24_)
			-- upvalues: (copy) self, (copy) v_u_22_
			local v25_ = 0
			local v26_ = {}
			while true do
				local v27_ = string.format("%s(%d)", p24_, v25_)
				local v28_ = "vehicle.connectionHoses.sounds." .. v27_
				if not self.xmlFile:hasProperty(v28_) then
					return v26_
				end
				local v29_ = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.connectionHoses.sounds", v27_, self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
				if v29_ ~= nil then
					local v30_ = self.xmlFile:getValue(v28_ .. "#type")
					local v31_ = false
					for _, v32_ in ipairs(v_u_22_.hoseNodes) do
						if v32_.type == v30_ then
							v31_ = true
							break
						end
					end
					if v31_ then
						v26_[v30_] = v29_
					else
						Logging.xmlWarning(self.xmlFile, "Failed load %s-sound with type %s. No hose with that type available.", p24_, v30_)
					end
				end
				v25_ = v25_ + 1
			end
		end
		v_u_22_.samples = {}
		v_u_22_.samples.connect = v33_("connect")
		v_u_22_.samples.disconnect = v33_("disconnect")
	end
	if not (self.isClient and (v_u_22_.targetNodesAvailable or (v_u_22_.hoseNodesAvailable or (v_u_22_.localHosesAvailable or (v_u_22_.skipNodesAvailable or v_u_22_.activeDirtyCustomHosesAvailable))))) then
		SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", ConnectionHoses)
	end
end

-- Local values: spec, _, localHoseNode
function ConnectionHoses:onLoadFinished(savegame)
	local v35_ = self.spec_connectionHoses
	for _, v36_ in ipairs(v35_.localHoseNodes) do
		self:connectHose(v36_.hose, self, v36_.target, false)
	end
end

-- Local values: spec, i, _, toolConnectionHoseMount
function ConnectionHoses:onDelete()
	local v38_ = self.spec_connectionHoses
	if v38_.additionalSharedLoadRequestIds ~= nil then
		for v39_ = 1, #v38_.additionalSharedLoadRequestIds do
			g_i3DManager:releaseSharedI3DFile(v38_.additionalSharedLoadRequestIds[v39_])
		end
		v38_.additionalSharedLoadRequestIds = nil
	end
	if v38_.toolConnectionHoseMounts ~= nil then
		for _, v40_ in pairs(v38_.toolConnectionHoseMounts) do
			v40_:delete()
		end
		v38_.toolConnectionHoseMounts = nil
	end
	if v38_.samples ~= nil then
		g_soundManager:deleteSamples(v38_.samples.connect)
		g_soundManager:deleteSamples(v38_.samples.disconnect)
	end
end

-- Local values: spec, i, hose, i, customHose, impements, i, object
function ConnectionHoses:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v42_ = self.spec_connectionHoses
	if self.currentUpdateDistance < v42_.maxUpdateDistance then
		for v43_ = 1, #v42_.updateableHoses do
			local v44_ = v42_.updateableHoses[v43_]
			if self.updateLoopIndex == v44_.connectedObject.updateLoopIndex then
				self:updateConnectionHose(v44_, v43_)
			end
		end
		for _, v45_ in ipairs(v42_.customHosesActiveDirty) do
			if v45_.isActive and (v45_.connectedTarget ~= nil and self.updateLoopIndex == v45_.connectedObject.updateLoopIndex) then
				self:updateCustomHoseNode(v45_, v45_.connectedTarget)
			end
		end
		if self.getAttachedImplements ~= nil then
			local v46_ = self:getAttachedImplements()
			for v47_ = 1, #v46_ do
				local v48_ = v46_[v47_].object
				if v48_.updateAttachedConnectionHoses ~= nil then
					v48_:updateAttachedConnectionHoses(self)
				end
			end
		end
	end
end

function ConnectionHoses:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	ConnectionHoses.onUpdateInterpolation(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function ConnectionHoses.getConnectionHoseConfigIndex(self)
	return 1
end

-- Local values: spec, i, hose, i, customHose
function ConnectionHoses:updateAttachedConnectionHoses(attacherVehicle)
	local v56_ = self.spec_connectionHoses
	for v57_ = 1, #v56_.updateableHoses do
		local v58_ = v56_.updateableHoses[v57_]
		if v58_.connectedObject == attacherVehicle and self.updateLoopIndex == v58_.connectedObject.updateLoopIndex then
			self:updateConnectionHose(v58_, v57_)
		end
	end
	for _, v59_ in ipairs(v56_.customHosesActiveDirty) do
		if v59_.isActive and (v59_.connectedTarget ~= nil and (v59_.connectedObject == attacherVehicle and self.updateLoopIndex == v59_.connectedObject.updateLoopIndex)) then
			self:updateCustomHoseNode(v59_, v59_.connectedTarget)
		end
	end
end

-- Local values: p0x, p0y, p0z, p3x, p3y, p3z, p4x, p4y, p4z, p2x, p2y, p2z, w1x, w1y, w1z, w2x, w2y, w2z, d, lengthDifference, p2yStart, _, x, y, z, _, yTarget, _, angle1, angle2, centerPointAngle, newX, newY, newZ, newVelX, newVelY, newVelZ, velX, velY, velZ, worldX, worldY, worldZ, _, _, wp2y, _, realLengthDifference, realLength, x1, y1, z1, x2, y2, z2, x0, y0, z0, x3, y3, z3, x4, y4, z4, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sideDirX, sideDirY, sideDirZ, minX, maxX, minY, maxY, minZ, maxZ, cx, cy, cz, blue, cx, cy, cz, green, cx, cy, cz, red, lx, _, lz, _, ly, _, x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function ConnectionHoses:updateConnectionHose(hose, index)
	local v63_ = -hose.startStraightening
	local v64_, v65_, v66_ = localToLocal(hose.targetNode, hose.hoseNode, 0, 0, 0)
	local v67_, v68_, v69_ = localToLocal(hose.targetNode, hose.hoseNode, hose.endStraighteningDirection[1] * hose.endStraightening, hose.endStraighteningDirection[2] * hose.endStraightening, hose.endStraighteningDirection[3] * hose.endStraightening)
	local v70_, v71_, v72_
	if hose.isWorldSpaceHose then
		local v73_, v74_, v75_ = getWorldTranslation(hose.hoseNode)
		local v76_, v77_, v78_ = getWorldTranslation(hose.targetNode)
		v70_ = (v73_ + v76_) / 2
		v71_ = (v74_ + v77_) / 2
		v72_ = (v75_ + v78_) / 2
	else
		v70_ = v64_ / 2
		v71_ = v65_ / 2
		v72_ = v66_ / 2
	end
	local v79_ = MathUtil.vector3Length(v64_, v65_, v66_)
	local v80_ = hose.length - v79_
	local v81_ = math.max(v80_, 0) * (hose.centerPointDropFactor or 1)
	local v82_
	if hose.isWorldSpaceHose then
		v82_ = v71_
	else
		local v83_, v84_
		v83_, v82_, v84_ = localToWorld(hose.hoseNode, v70_, v71_, v72_)
	end
	local v85_ = 0.04 * v79_
	local v86_ = v71_ - math.max(v81_, v85_)
	if hose.isWorldSpaceHose then
		if hose.minDeltaY ~= math.huge then
			local v87_, v88_, v89_ = worldToLocal(hose.minDeltaYComponent, v70_, v86_, v72_)
			local _, v90_, _ = localToLocal(hose.hoseNode, hose.minDeltaYComponent, 0, 0, 0)
			local v91_ = localToWorld
			local v92_ = hose.minDeltaYComponent
			local v93_ = v90_ + hose.minDeltaY
			v70_, v86_, v72_ = v91_(v92_, v87_, math.max(v88_, v93_), v89_)
		end
		v70_, v86_, v72_ = worldToLocal(hose.hoseNode, v70_, v86_, v72_)
	end
	local v94_, v95_ = self:getCenterPointAngle(hose.hoseNode, v70_, v86_, v72_, v64_, v65_, v66_, hose.isWorldSpaceHose)
	local v96_ = v94_ + v95_
	if v96_ < hose.minCenterPointAngle then
		v70_, v86_, v72_ = self:getCenterPointAngleRegulation(hose.hoseNode, v70_, v86_, v72_, v64_, v65_, v66_, v94_, v95_, hose.minCenterPointAngle, hose.isWorldSpaceHose)
	end
	if hose.minCenterPointOffset ~= nil and hose.maxCenterPointOffset ~= nil then
		local v97_ = hose.minCenterPointOffset[1]
		local v98_ = hose.maxCenterPointOffset[1]
		v70_ = math.clamp(v70_, v97_, v98_)
		local v99_ = hose.minCenterPointOffset[2]
		local v100_ = hose.maxCenterPointOffset[2]
		v86_ = math.clamp(v86_, v99_, v100_)
		local v101_ = hose.minCenterPointOffset[3]
		local v102_ = hose.maxCenterPointOffset[3]
		v72_ = math.clamp(v72_, v101_, v102_)
	end
	local v103_, v104_, v105_ = getWorldTranslation(hose.component)
	if hose.lastComponentPosition == nil or hose.lastComponentVelocity == nil then
		hose.lastComponentPosition = { v103_, v104_, v105_ }
		hose.lastComponentVelocity = { v103_, v104_, v105_ }
	end
	local v106_ = v103_ - hose.lastComponentPosition[1]
	local v107_ = v104_ - hose.lastComponentPosition[2]
	local v108_ = v105_ - hose.lastComponentPosition[3]
	local v109_ = hose.lastComponentPosition
	local v110_ = hose.lastComponentPosition
	local v111_ = hose.lastComponentPosition
	v109_[1] = v103_
	v110_[2] = v104_
	v111_[3] = v105_
	local v112_ = v106_ - hose.lastComponentVelocity[1]
	local v113_ = v107_ - hose.lastComponentVelocity[2]
	local v114_ = v108_ - hose.lastComponentVelocity[3]
	local v115_ = hose.lastComponentVelocity
	local v116_ = hose.lastComponentVelocity
	local v117_ = hose.lastComponentVelocity
	v115_[1] = v106_
	v116_[2] = v107_
	v117_[3] = v108_
	local v118_, v119_, v120_ = getWorldTranslation(hose.hoseNode)
	local _, v121_, v122_ = worldToLocal(hose.hoseNode, v118_ + v112_, v119_ + v113_, v120_ + v114_)
	local _, v123_, _ = localToWorld(hose.hoseNode, v70_, v86_, v72_)
	local v124_ = v82_ - v123_
	local v125_ = v121_ * -hose.dampingFactor
	local v126_ = -hose.dampingRange
	local v127_ = hose.dampingRange
	local v128_ = math.clamp(v125_, v126_, v127_) * v124_
	local v129_ = v122_ * -hose.dampingFactor
	local v130_ = -hose.dampingRange
	local v131_ = hose.dampingRange
	local v132_ = math.clamp(v129_, v130_, v131_) * v124_
	local v133_ = v128_ * 0.1 + hose.lastVelY * 0.9
	local v134_ = v132_ * 0.1 + hose.lastVelZ * 0.9
	hose.lastVelY = v133_
	hose.lastVelZ = v134_
	local v135_ = v86_ + v133_
	local v136_ = v72_ + v134_
	if hose.isTwoPointHose then
		v70_ = 0
		v135_ = 0
		v136_ = 0
	end
	setShaderParameter(hose.hoseNode, "cv2", v70_, v135_, v136_, hose.centerPointTension or 0, false)
	setShaderParameter(hose.hoseNode, "cv3", v64_, v65_, v66_, 0, false)
	setShaderParameter(hose.hoseNode, "cv4", v67_, v68_, v69_, 1, false)
	if VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS and self:getIsActiveForInput() then
		local v137_ = MathUtil.vector3Length(v70_, v135_, v136_) + MathUtil.vector3Length(v70_ - v64_, v135_ - v65_, v136_ - v66_)
		renderText(0.5, 0.9 - index * 0.02, 0.0175, string.format("hose %s:", getName(hose.node)))
		local v138_ = renderText
		local v139_ = 0.9 - index * 0.02
		local v140_ = string.format
		local v141_ = hose.length
		local v142_ = math.deg(v96_)
		local v143_ = hose.minCenterPointAngle
		v138_(0.62, v139_, 0.0175, v140_("directLength: %.2f configLength: %.2f realLength: %.2f angle: %.2f minAngle: %.2f", v79_, v141_, v137_, v142_, (math.deg(v143_))))
		local v144_, v145_, v146_ = localToWorld(hose.hoseNode, 0, 0, v63_)
		local v147_, v148_, v149_ = localToWorld(hose.hoseNode, 0, 0, 0)
		drawDebugLine(v144_, v145_, v146_, 1, 0, 0, v147_, v148_, v149_, 0, 1, 0)
		local v150_, v151_, v152_ = localToWorld(hose.hoseNode, 0, 0, 0)
		local v153_, v154_, v155_ = localToWorld(hose.hoseNode, v70_, v135_, v136_)
		drawDebugLine(v150_, v151_, v152_, 1, 0, 0, v153_, v154_, v155_, 0, 1, 0)
		local v156_, v157_, v158_ = localToWorld(hose.hoseNode, v70_, v135_, v136_)
		local v159_, v160_, v161_ = localToWorld(hose.hoseNode, v64_, v65_, v66_)
		drawDebugLine(v156_, v157_, v158_, 1, 0, 0, v159_, v160_, v161_, 0, 1, 0)
		local v162_, v163_, v164_ = localToWorld(hose.hoseNode, v64_, v65_, v66_)
		local v165_, v166_, v167_ = localToWorld(hose.hoseNode, v67_, v68_, v69_)
		drawDebugLine(v162_, v163_, v164_, 1, 0, 0, v165_, v166_, v167_, 0, 1, 0)
		local v168_, v169_, v170_ = localToWorld(hose.hoseNode, 0, 0, v63_)
		local v171_, v172_, v173_ = localToWorld(hose.hoseNode, 0, 0, 0)
		local v174_, v175_, v176_ = localToWorld(hose.hoseNode, v70_, v135_, v136_)
		local v177_, v178_, v179_ = localToWorld(hose.hoseNode, v64_, v65_, v66_)
		local v180_, v181_, v182_ = localToWorld(hose.hoseNode, v67_, v68_, v69_)
		drawDebugPoint(v168_, v169_, v170_, 1, 0, 0, 1)
		drawDebugPoint(v171_, v172_, v173_, 1, 0, 0, 1)
		drawDebugPoint(v174_, v175_, v176_, 1, 0, 0, 1)
		drawDebugPoint(v177_, v178_, v179_, 1, 0, 0, 1)
		drawDebugPoint(v180_, v181_, v182_, 1, 0, 0, 1)
		DebugGizmo.renderAtNode(hose.hoseNode, "hn")
		DebugGizmo.renderAtNode(hose.targetNode, "tn")
		if hose.minCenterPointOffset ~= nil and hose.maxCenterPointOffset ~= nil then
			local v183_, v184_, v185_ = localToWorld(hose.hoseNode, 0, 0, 0)
			local v186_, v187_, v188_ = localDirectionToWorld(hose.hoseNode, 0, 1, 0)
			local v189_, v190_, v191_ = localDirectionToWorld(hose.hoseNode, 0, 0, 1)
			local v192_, v193_, v194_ = localDirectionToWorld(hose.hoseNode, 1, 0, 0)
			local v195_ = hose.minCenterPointOffset[1]
			local v196_ = math.clamp(v195_, -1, 1)
			local v197_ = hose.maxCenterPointOffset[1]
			local v198_ = math.clamp(v197_, -1, 1)
			local v199_ = hose.minCenterPointOffset[2]
			local v200_ = math.clamp(v199_, -1, 1)
			local v201_ = hose.maxCenterPointOffset[2]
			local v202_ = math.clamp(v201_, -1, 1)
			local v203_ = hose.minCenterPointOffset[3]
			local v204_ = math.clamp(v203_, -1, 1)
			local v205_ = hose.maxCenterPointOffset[3]
			local v206_ = math.clamp(v205_, -1, 1)
			if hose.minCenterPointOffset[3] ~= -math.huge or hose.maxCenterPointOffset[3] ~= math.huge then
				local v207_ = v183_ + v186_ * (v200_ + v202_) * 0.5
				local v208_ = v184_ + v187_ * (v200_ + v202_) * 0.5
				local v209_ = v185_ + v188_ * (v200_ + v202_) * 0.5
				local v210_ = v207_ + v192_ * (v196_ + v198_) * 0.5
				local v211_ = v208_ + v193_ * (v196_ + v198_) * 0.5
				local v212_ = v209_ + v194_ * (v196_ + v198_) * 0.5
				local v213_ = Color.new(0, 0, 1, 0.1)
				DebugPlane.newSimple(true, true, v213_, false):createFromPosAndDir(v210_ + v189_ * v204_, v211_ + v190_ * v204_, v212_ + v191_ * v204_, v186_, v187_, v188_, v189_, v190_, v191_, v198_ - v196_, v202_ - v200_):draw()
				DebugPlane.newSimple(true, true, v213_, false):createFromPosAndDir(v210_ + v189_ * v206_, v211_ + v190_ * v206_, v212_ + v191_ * v206_, v186_, v187_, v188_, v189_, v190_, v191_, v198_ - v196_, v202_ - v200_):draw()
			end
			if hose.minCenterPointOffset[2] ~= -math.huge or hose.maxCenterPointOffset[2] ~= math.huge then
				local v214_ = v183_ + v189_ * (v204_ + v206_) * 0.5
				local v215_ = v184_ + v190_ * (v204_ + v206_) * 0.5
				local v216_ = v185_ + v191_ * (v204_ + v206_) * 0.5
				local v217_ = v214_ + v192_ * (v196_ + v198_) * 0.5
				local v218_ = v215_ + v193_ * (v196_ + v198_) * 0.5
				local v219_ = v216_ + v194_ * (v196_ + v198_) * 0.5
				local v220_ = Color.new(0, 1, 0, 0.1)
				DebugPlane.newSimple(true, true, v220_, false):createFromPosAndDir(v217_ + v186_ * v200_, v218_ + v187_ * v200_, v219_ + v188_ * v200_, v189_, v190_, v191_, v186_, v187_, v188_, v198_ - v196_, v206_ - v204_):draw()
				DebugPlane.newSimple(true, true, v220_, false):createFromPosAndDir(v217_ + v186_ * v202_, v218_ + v187_ * v202_, v219_ + v188_ * v202_, v189_, v190_, v191_, v186_, v187_, v188_, v198_ - v196_, v206_ - v204_):draw()
			end
			if hose.minCenterPointOffset[1] ~= -math.huge or hose.maxCenterPointOffset[1] ~= math.huge then
				local v221_ = v183_ + v189_ * (v204_ + v206_) * 0.5
				local v222_ = v184_ + v190_ * (v204_ + v206_) * 0.5
				local v223_ = v185_ + v191_ * (v204_ + v206_) * 0.5
				local v224_ = Color.new(1, 0, 0, 0.1)
				DebugPlane.newSimple(true, true, v224_, false):createFromPosAndDir(v221_ + v192_ * v196_, v222_ + v193_ * v196_, v223_ + v194_ * v196_, v189_, v190_, v191_, v192_, v193_, v194_, v202_ - v200_, v206_ - v204_):draw()
				DebugPlane.newSimple(true, true, v224_, false):createFromPosAndDir(v221_ + v192_ * v198_, v222_ + v193_ * v198_, v223_ + v194_ * v198_, v189_, v190_, v191_, v192_, v193_, v194_, v202_ - v200_, v206_ - v204_):draw()
			end
		end
		if hose.minDeltaY ~= math.huge and hose.minDeltaYComponent ~= nil then
			local v225_, _, v226_ = localToLocal(hose.hoseNode, hose.minDeltaYComponent, v70_, v135_, v136_)
			local _, v227_, _ = localToLocal(hose.hoseNode, hose.minDeltaYComponent, 0, 0, 0)
			local v228_, v229_, v230_ = localToWorld(hose.minDeltaYComponent, v225_, v227_ + hose.minDeltaY, v226_)
			local v231_, v232_, v233_ = localDirectionToWorld(hose.minDeltaYComponent, 0, 1, 0)
			local v234_, v235_, v236_ = localDirectionToWorld(hose.minDeltaYComponent, 0, 0, 1)
			DebugPlane.newSimple(true, true, Color.new(0, 1, 0, 0.1), false):createFromPosAndDir(v228_, v229_, v230_, v234_, v235_, v236_, v231_, v232_, v233_, 1, 1):draw()
		end
	end
end

-- Local values: lengthStartToCenter, lengthCenterToEnd, _, sY, _, lengthStartToCenter2, lengthCenterToEnd2, angle1, angle2
function ConnectionHoses:getCenterPointAngle(node, cX, cY, cZ, eX, eY, eZ, useWorldSpace)
	local v245_ = MathUtil.vector3Length(cX, cY, cZ)
	local v246_ = MathUtil.vector3Length(cX - eX, cY - eY, cZ - eZ)
	local v247_ = math.abs(v246_)
	local _, v248_, _ = getWorldTranslation(node)
	if useWorldSpace then
		local v249_, v250_
		v249_, cY, v250_ = localToWorld(node, cX, cY, cZ)
		local v251_, v252_
		v251_, eY, v252_ = localToWorld(node, eX, eY, eZ)
	else
		v248_ = 0
	end
	local v253_ = v248_ - cY
	local v254_ = eY - cY
	local v255_ = v253_ / v245_
	local v256_ = math.acos(v255_)
	local v257_ = v254_ / v247_
	return v256_, math.acos(v257_)
end

-- Local values: sX, sY, sZ, _, startCenterLength, centerEndLength, pct, alpha, newY1, newY2, newY
function ConnectionHoses:getCenterPointAngleRegulation(node, cX, cY, cZ, eX, eY, eZ, angle1, angle2, targetAngle, useWorldSpace)
	local v269_, v270_, v271_ = getWorldTranslation(node)
	if useWorldSpace then
		local v272_
		cX, v272_, cZ = localToWorld(node, cX, cY, cZ)
		local v273_
		eX, v273_, eZ = localToWorld(node, eX, eY, eZ)
	else
		v270_ = 0
		v269_ = 0
		v271_ = 0
	end
	local v274_ = MathUtil.vector2Length(v269_ - cX, v271_ - cZ)
	local v275_ = MathUtil.vector2Length(eX - cX, eZ - cZ)
	local v276_ = 1.5707963267948966 - angle1 / (angle1 + angle2) * targetAngle
	local v277_ = (math.tan(v276_) * v274_ + math.tan(v276_) * v275_) / 2
	if useWorldSpace then
		return worldToLocal(node, cX, v270_ - v277_, cZ)
	else
		return cX, v270_ - v277_, cZ
	end
end

-- Local values: spec
function ConnectionHoses:loadConnectionHosesFromXML(xmlFile, key)
	local v_u_281_ = self.spec_connectionHoses
	xmlFile:iterate(key .. ".skipNode", function(_, p282_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_281_
		local v283_ = {}
		if self:loadHoseSkipNode(xmlFile, p282_, v283_) then
			local v284_ = v_u_281_.hoseSkipNodes
			table.insert(v284_, v283_)
			if v_u_281_.hoseSkipNodeByType[v283_.type] == nil then
				v_u_281_.hoseSkipNodeByType[v283_.type] = {}
			end
			local v285_ = v_u_281_.hoseSkipNodeByType[v283_.type]
			table.insert(v285_, v283_)
		end
	end)
	self:addHoseTargetNodes(xmlFile, key .. ".target")
	xmlFile:iterate(key .. ".toolConnectorHose", function(_, p286_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_281_
		local v287_ = {}
		if self:loadToolConnectorHoseNode(xmlFile, p286_, v287_) then
			local v288_ = v_u_281_.toolConnectorHoses
			table.insert(v288_, v287_)
			v_u_281_.targetNodeToToolConnection[v287_.startTargetNodeIndex] = v287_
			v_u_281_.targetNodeToToolConnection[v287_.endTargetNodeIndex] = v287_
		end
	end)
	xmlFile:iterate(key .. ".hose", function(_, p289_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_281_
		local v290_ = {}
		if self:loadHoseNode(xmlFile, p289_, v290_, true) then
			local v291_ = v_u_281_.hoseNodes
			table.insert(v291_, v290_)
			v290_.index = #v_u_281_.hoseNodes
			for _, v292_ in pairs(v290_.inputAttacherJointIndices) do
				if v_u_281_.hoseNodesByInputAttacher[v292_] == nil then
					v_u_281_.hoseNodesByInputAttacher[v292_] = {}
				end
				local v293_ = v_u_281_.hoseNodesByInputAttacher[v292_]
				table.insert(v293_, v290_)
			end
		end
	end)
	xmlFile:iterate(key .. ".localHose", function(_, p294_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_281_
		local v295_ = {}
		if self:loadHoseNode(xmlFile, p294_ .. ".hose", v295_, false) then
			local v296_ = {}
			if self:loadHoseTargetNode(xmlFile, p294_ .. ".target", v296_) then
				local v297_ = v_u_281_.localHoseNodes
				table.insert(v297_, {
					["hose"] = v295_,
					["target"] = v296_
				})
			end
		end
	end)
	self:loadCustomHosesFromXML(true, v_u_281_.customHoses, v_u_281_.customHosesByAttacher, v_u_281_.customHosesByInputAttacher, xmlFile, key .. ".customHose")
	self:loadCustomHosesFromXML(false, v_u_281_.customHoseTargets, v_u_281_.customHoseTargetsByAttacher, v_u_281_.customHoseTargetsByInputAttacher, xmlFile, key .. ".customTarget")
end

function ConnectionHoses:loadHoseSkipNode(xmlFile, targetKey, entry)
	entry.node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
	if entry.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for hose skip node \'%s\'", targetKey)
		return false
	end
	entry.inputAttacherJointIndex = xmlFile:getValue(targetKey .. "#inputAttacherJointIndex", 1)
	entry.attacherJointIndex = xmlFile:getValue(targetKey .. "#attacherJointIndex", 1)
	entry.type = xmlFile:getValue(targetKey .. "#type")
	entry.specType = xmlFile:getValue(targetKey .. "#specType")
	if entry.type == nil then
		Logging.xmlWarning(xmlFile, "Missing type for hose skip node \'%s\'", targetKey)
		return false
	end
	entry.length = xmlFile:getValue(targetKey .. "#length")
	entry.isTwoPointHose = xmlFile:getValue(targetKey .. "#isTwoPointHose", false)
	entry.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
	entry.objectChangesTarget = self
	entry.isSkipNode = true
	return true
end

-- Local values: spec, key, startTarget, endTarget, index, _, x1, y1, z1, x2, y2, z2, dirX, dirY, dirZ, upX, upY, upZ, type
function ConnectionHoses:loadToolConnectorHoseNode(xmlFile, targetKey, entry)
	local v306_ = self.spec_connectionHoses
	entry.startTargetNodeIndex = self:addHoseTargetNodes(xmlFile, (string.format("%s.startTarget", targetKey)))
	if entry.startTargetNodeIndex == nil then
		Logging.xmlWarning(xmlFile, "startTarget is missing for tool connection hose \'%s\'", targetKey)
		return false
	end
	entry.endTargetNodeIndex = self:addHoseTargetNodes(xmlFile, (string.format("%s.endTarget", targetKey)))
	if entry.endTargetNodeIndex == nil then
		Logging.xmlWarning(xmlFile, "endTarget is missing for tool connection hose \'%s\'", targetKey)
		return false
	end
	local v307_ = v306_.targetNodes[entry.startTargetNodeIndex]
	local v308_ = v306_.targetNodes[entry.endTargetNodeIndex]
	for v309_, _ in pairs(v307_.attacherJointIndices) do
		if v308_.attacherJointIndices[v309_] ~= nil then
			Logging.xmlWarning(xmlFile, "Double usage of attacher joint index \'%d\' in \'%s\'", v309_, targetKey)
		end
	end
	entry.moveNodes = xmlFile:getValue(targetKey .. "#moveNodes", true)
	entry.additionalHose = xmlFile:getValue(targetKey .. "#additionalHose", true)
	if entry.moveNodes then
		local v310_, v311_, v312_ = getTranslation(v307_.node)
		local v313_, v314_, v315_ = getTranslation(v308_.node)
		local v316_, v317_, v318_ = MathUtil.vector3Normalize(v310_ - v313_, v311_ - v314_, v312_ - v315_)
		local v319_, v320_, v321_ = localDirectionToLocal(v308_.node, getParent(v308_.node), 0, 1, 0)
		if (v316_ ~= 0 or (v317_ ~= 0 or v318_ ~= 0)) and not (MathUtil.isNan(v316_) or (MathUtil.isNan(v317_) or MathUtil.isNan(v318_))) then
			setDirection(v307_.node, -v316_, -v317_, -v318_, v319_, v320_, v321_)
			setDirection(v308_.node, v316_, v317_, v318_, v319_, v320_, v321_)
		end
	end
	entry.mountingNode = xmlFile:getValue(targetKey .. "#mountingNode", nil, self.components, self.i3dMappings)
	if entry.mountingNode ~= nil then
		setVisibility(entry.mountingNode, false)
	end
	entry.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
	entry.objectChangesTarget = self
	local v322_ = v306_.targetNodes[entry.startTargetNodeIndex].type .. (v306_.targetNodes[entry.startTargetNodeIndex].specType or "")
	if v306_.numToolConnectionsByType[v322_] == nil then
		v306_.numToolConnectionsByType[v322_] = 0
	end
	v306_.numToolConnectionsByType[v322_] = v306_.numToolConnectionsByType[v322_] + 1
	entry.typedIndex = v306_.numToolConnectionsByType[v322_]
	entry.connected = false
	return true
end

-- Local values: spec, addedTarget
function ConnectionHoses:addHoseTargetNodes(xmlFile, key)
	local v_u_326_ = self.spec_connectionHoses
	local v_u_327_ = false
	xmlFile:iterate(key, function(_, p328_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_326_, (ref) v_u_327_
		local v329_ = {}
		if self:loadHoseTargetNode(xmlFile, p328_, v329_) then
			local v330_ = v_u_326_.targetNodes
			table.insert(v330_, v329_)
			v329_.index = #v_u_326_.targetNodes
			if v_u_326_.targetNodesByType[v329_.type] == nil then
				v_u_326_.targetNodesByType[v329_.type] = {}
			end
			local v331_ = v_u_326_.targetNodesByType[v329_.type]
			table.insert(v331_, v329_)
			v_u_327_ = true
		end
	end)
	return v_u_327_ and #v_u_326_.targetNodes or nil
end

function ConnectionHoses:loadCustomHosesFromXML(isHose, targetTable, attacherJointMapping, inputAttacherJointMapping, xmlFile, key)
	xmlFile:iterate(key, function(_, p339_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) inputAttacherJointMapping, (copy) attacherJointMapping, (copy) isHose, (copy) targetTable
		local v340_ = {
			["node"] = xmlFile:getValue(p339_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v340_.node == nil then
			Logging.xmlWarning(xmlFile, "Missing node for custom hose \'%s\'", p339_)
			return
		else
			v340_.type = xmlFile:getValue(p339_ .. "#type")
			if v340_.type == nil then
				Logging.xmlWarning(xmlFile, "Missing type for custom hose \'%s\'", p339_)
			else
				v340_.type = string.upper(v340_.type)
				v340_.inputAttacherJointIndices = {}
				local v341_ = xmlFile:getValue(p339_ .. "#inputAttacherJointIndices", nil, true)
				if v341_ ~= nil then
					for _, v342_ in ipairs(v341_) do
						v340_.inputAttacherJointIndices[v342_] = v342_
						if inputAttacherJointMapping[v342_] == nil then
							inputAttacherJointMapping[v342_] = {}
						end
						local v343_ = inputAttacherJointMapping[v342_]
						table.insert(v343_, v340_)
					end
				end
				v340_.attacherJointIndices = {}
				local v344_ = xmlFile:getValue(p339_ .. "#attacherJointIndices", nil, true)
				if v344_ ~= nil then
					for _, v345_ in ipairs(v344_) do
						v340_.attacherJointIndices[v345_] = v345_
						if attacherJointMapping[v345_] == nil then
							attacherJointMapping[v345_] = {}
						end
						local v346_ = attacherJointMapping[v345_]
						table.insert(v346_, v340_)
					end
				end
				if isHose then
					v340_.isActiveDirty = xmlFile:getValue(p339_ .. "#isActiveDirty", false)
					if v340_.isActiveDirty then
						local v347_ = self.spec_connectionHoses.customHosesActiveDirty
						table.insert(v347_, v340_)
					end
					v340_.startTranslation = { getTranslation(v340_.node) }
					v340_.startRotation = { getRotation(v340_.node) }
				end
				if next(v340_.inputAttacherJointIndices) == nil and next(v340_.attacherJointIndices) == nil then
					Logging.xmlWarning(xmlFile, "Missing inputAttacherJointIndices for custom hose \'%s\'", p339_)
					return false
				end
				v340_.objectChanges = {}
				ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, p339_, v340_.objectChanges, self.components, self)
				ObjectChangeUtil.setObjectChanges(v340_.objectChanges, false, self, self.setMovingToolDirty, true)
				v340_.objectChangesTarget = self
				v340_.isActive = false
				local v348_ = targetTable
				table.insert(v348_, v340_)
			end
		end
	end)
end

-- Local values: attacherJointIndices, _, attacherJointIndex, attacherJointNodes, _, node, attacherJointIndex, socketName, socketMaterial
function ConnectionHoses:loadHoseTargetNode(xmlFile, targetKey, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, targetKey .. "#socketColor", targetKey .. "#socketMaterialTemplateName")
	entry.node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
	if entry.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for connection hose target \'%s\'", targetKey)
		return false
	end
	entry.attacherJointIndices = {}
	local v353_ = xmlFile:getValue(targetKey .. "#attacherJointIndices", nil, true)
	if v353_ ~= nil then
		for _, v354_ in ipairs(v353_) do
			entry.attacherJointIndices[v354_] = v354_
		end
	end
	local v355_ = xmlFile:getValue(targetKey .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
	if v355_ ~= nil then
		for _, v356_ in ipairs(v355_) do
			local v357_ = self:getAttacherJointIndexByNode(v356_)
			if v357_ ~= nil then
				entry.attacherJointIndices[v357_] = v357_
			end
		end
	end
	entry.type = xmlFile:getValue(targetKey .. "#type")
	entry.specType = xmlFile:getValue(targetKey .. "#specType")
	entry.straighteningFactor = xmlFile:getValue(targetKey .. "#straighteningFactor", 1)
	entry.straighteningDirection = xmlFile:getValue(targetKey .. "#straighteningDirection", nil, true)
	local v358_ = xmlFile:getValue(targetKey .. "#socket")
	if v358_ ~= nil then
		local v359_ = xmlFile:getValue(targetKey .. "#socketMaterialTemplateName", nil, self.customEnvironment)
		entry.socket = g_connectionHoseManager:linkSocketToNode(v358_, entry.node, self.customEnvironment, v359_)
	end
	if entry.type == nil then
		Logging.xmlWarning(xmlFile, "Missing type for \'%s\'", targetKey)
		return false
	end
	entry.adapterName = xmlFile:getValue(targetKey .. "#adapterType", "DEFAULT")
	if entry.adapter == nil then
		entry.adapter = {}
		entry.adapter.node = entry.node
		entry.adapter.refNode = entry.node
	end
	entry.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
	return true
end

-- Local values: inputAttacherJointIndices, _, inputAttacherJointIndex, inputAttacherJointNodes, _, node, inputAttacherJointIndex, spec, type, i, i, node, socketName, socketMaterial, hose, startStraightening, endStraightening, minCenterPointAngle, outgoingNode, visibilityNode, rx, ry, rz, node, referenceNode
function ConnectionHoses:loadHoseNode(xmlFile, hoseKey, entry, isBaseHose)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, hoseKey .. "#color", hoseKey .. "#materialTemplateName")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, hoseKey .. "#socketColor", hoseKey .. "#socketMaterialTemplateName")
	entry.inputAttacherJointIndices = {}
	local v365_ = xmlFile:getValue(hoseKey .. "#inputAttacherJointIndices", nil, true)
	if v365_ ~= nil then
		for _, v366_ in ipairs(v365_) do
			entry.inputAttacherJointIndices[v366_] = v366_
		end
	end
	local v367_ = xmlFile:getValue(hoseKey .. "#inputAttacherJointNodes", nil, self.components, self.i3dMappings, true)
	if v367_ ~= nil then
		for _, v368_ in ipairs(v367_) do
			local v369_ = self:getInputAttacherJointIndexByNode(v368_)
			if v369_ ~= nil then
				entry.inputAttacherJointIndices[v369_] = v369_
			end
		end
	end
	entry.type = xmlFile:getValue(hoseKey .. "#type")
	entry.specType = xmlFile:getValue(hoseKey .. "#specType")
	if entry.type == nil then
		Logging.xmlWarning(xmlFile, "Missing type attribute in \'%s\'", hoseKey)
		return false
	end
	entry.hoseType = xmlFile:getValue(hoseKey .. "#hoseType", "DEFAULT")
	entry.node = xmlFile:getValue(hoseKey .. "#node", nil, self.components, self.i3dMappings)
	if entry.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for connection hose \'%s\'", hoseKey)
		return false
	end
	if isBaseHose then
		local v370_ = self.spec_connectionHoses
		local v371_ = entry.type .. (entry.specType or "")
		if v370_.numHosesByType[v371_] == nil then
			v370_.numHosesByType[v371_] = 0
		end
		v370_.numHosesByType[v371_] = v370_.numHosesByType[v371_] + 1
		entry.typedIndex = v370_.numHosesByType[v371_]
	end
	entry.isTwoPointHose = xmlFile:getValue(hoseKey .. "#isTwoPointHose", false)
	entry.isWorldSpaceHose = xmlFile:getValue(hoseKey .. "#isWorldSpaceHose", true)
	entry.component = self:getParentComponent(entry.node)
	entry.lastVelY = 0
	entry.lastVelZ = 0
	entry.dampingRange = xmlFile:getValue(hoseKey .. "#dampingRange", 0.05)
	entry.dampingFactor = xmlFile:getValue(hoseKey .. "#dampingFactor", 50)
	entry.length = xmlFile:getValue(hoseKey .. "#length", 3)
	entry.dynamicLength = xmlFile:getValue(hoseKey .. "#dynamicLength", false)
	entry.diameter = xmlFile:getValue(hoseKey .. "#diameter", 0.02)
	entry.straighteningFactor = xmlFile:getValue(hoseKey .. "#straighteningFactor", 1)
	entry.centerPointDropFactor = xmlFile:getValue(hoseKey .. "#centerPointDropFactor", 1)
	entry.centerPointTension = xmlFile:getValue(hoseKey .. "#centerPointTension", 0)
	entry.minCenterPointAngle = xmlFile:getValue(hoseKey .. "#minCenterPointAngle")
	entry.minCenterPointOffset = xmlFile:getValue(hoseKey .. "#minCenterPointOffset", nil, true)
	entry.maxCenterPointOffset = xmlFile:getValue(hoseKey .. "#maxCenterPointOffset", nil, true)
	if entry.minCenterPointOffset ~= nil and entry.maxCenterPointOffset ~= nil then
		for v372_ = 1, 3 do
			if entry.minCenterPointOffset[v372_] == 0 then
				entry.minCenterPointOffset[v372_] = -math.huge
			end
			if entry.maxCenterPointOffset[v372_] == 0 then
				entry.maxCenterPointOffset[v372_] = math.huge
			end
		end
		for v373_ = 1, 3 do
			if entry.maxCenterPointOffset[v373_] < entry.minCenterPointOffset[v373_] or entry.minCenterPointOffset[v373_] > entry.maxCenterPointOffset[v373_] then
				entry.minCenterPointOffset = nil
				entry.maxCenterPointOffset = nil
				Logging.xmlWarning(xmlFile, "Invalid centerPointOffset in \'%s\'. Max is smaller than min or min is greater than max.", hoseKey)
				break
			end
		end
	end
	entry.minDeltaY = xmlFile:getValue(hoseKey .. "#minDeltaY", math.huge)
	entry.minDeltaYComponent = xmlFile:getValue(hoseKey .. "#minDeltaYComponent", entry.component, self.components, self.i3dMappings)
	entry.material = xmlFile:getValue(hoseKey .. "#materialTemplateName", nil, self.customEnvironment)
	entry.adapterMaterial = xmlFile:getValue(hoseKey .. "#adapterMaterialTemplateName", nil, self.customEnvironment)
	entry.adapterName = xmlFile:getValue(hoseKey .. "#adapterType")
	entry.outgoingAdapter = xmlFile:getValue(hoseKey .. "#outgoingAdapter")
	entry.adapterNode = xmlFile:getValue(hoseKey .. "#adapterNode", nil, self.components, self.i3dMappings)
	if entry.adapterNode ~= nil then
		local v374_ = g_connectionHoseManager:getClonedAdapterNode(entry.type, entry.adapterName or "DEFAULT", self.customEnvironment, true)
		if v374_ == nil then
			Logging.xmlWarning(xmlFile, "Unable to find detached adapter for type \'%s\' in \'%s\'", entry.adapterName or "DEFAULT", hoseKey)
		else
			if entry.adapterMaterial ~= nil then
				entry.adapterMaterial:apply(v374_, "connector_color_mat")
			end
			link(entry.adapterNode, v374_)
		end
	end
	local v375_ = xmlFile:getValue(hoseKey .. "#socket")
	if v375_ ~= nil then
		local v376_ = xmlFile:getValue(hoseKey .. "#socketMaterialTemplateName", nil, self.customEnvironment)
		entry.socket = g_connectionHoseManager:linkSocketToNode(v375_, entry.node, self.customEnvironment, v376_)
		if entry.socket ~= nil then
			setRotation(entry.socket.node, 0, 3.141592653589793, 0)
		end
	end
	local v377_, v378_, v379_, v380_ = g_connectionHoseManager:getClonedHoseNode(entry.type, entry.hoseType, entry.length, entry.diameter, entry.material, self.customEnvironment)
	if v377_ == nil then
		Logging.xmlWarning(xmlFile, "Unable to find connection hose with length \'%.2f\' and diameter \'%.2f\' in \'%s\'", entry.length, entry.diameter, hoseKey)
		return false
	end
	local v381_ = g_connectionHoseManager:getSocketTarget(entry.socket, entry.node)
	local v382_ = 0
	local v383_
	if entry.outgoingAdapter == nil then
		v383_ = v377_
	else
		local v384_
		v383_, v384_ = g_connectionHoseManager:getClonedAdapterNode(entry.type, entry.outgoingAdapter, self.customEnvironment)
		if v383_ == nil then
			Logging.xmlWarning(xmlFile, "Unable to find adapter type \'%s\' in \'%s\'", entry.outgoingAdapter, hoseKey)
			v383_ = v377_
		else
			if entry.adapterMaterial ~= nil then
				entry.adapterMaterial:apply(v383_, "connector_color_mat")
			end
			link(v381_, v383_)
			v382_ = 3.141592653589793
			if entry.socket == nil then
				setRotation(v383_, 0, v382_, 0)
				v381_ = v384_
			else
				v381_ = v384_
			end
		end
	end
	link(v381_, v377_)
	setTranslation(v377_, 0, 0, 0)
	setRotation(v377_, 0, v382_, 0)
	entry.hoseNode = v377_
	entry.visibilityNode = v383_
	entry.startStraightening = v378_ * entry.straighteningFactor
	entry.endStraightening = v379_
	entry.endStraighteningBase = v379_
	entry.endStraighteningDirectionBase = { 0, 0, 1 }
	entry.endStraighteningDirection = entry.endStraighteningDirectionBase
	entry.minCenterPointAngle = entry.minCenterPointAngle or v380_
	setVisibility(entry.visibilityNode, false)
	entry.objectChanges = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, hoseKey, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
	return true
end

-- Local values: clonedHose, hose, startStraightening, endStraightening, minCenterPointAngle
function ConnectionHoses:getClonedSkipHoseNode(sourceHose, skipNode)
	local v388_ = {
		["isClonedSkipNodeHose"] = true,
		["type"] = sourceHose.type,
		["specType"] = sourceHose.specType,
		["hoseType"] = sourceHose.hoseType,
		["node"] = skipNode.node,
		["component"] = self:getParentComponent(skipNode.node),
		["lastVelY"] = 0,
		["lastVelZ"] = 0,
		["dampingRange"] = 0.05,
		["dampingFactor"] = 50,
		["minDeltaYComponent"] = self:getParentComponent(skipNode.node),
		["minDeltaY"] = math.huge,
		["length"] = skipNode.length or sourceHose.length,
		["diameter"] = sourceHose.diameter,
		["isTwoPointHose"] = skipNode.isTwoPointHose,
		["material"] = sourceHose.material
	}
	local v389_, v390_, v391_, v392_ = g_connectionHoseManager:getClonedHoseNode(v388_.type, v388_.hoseType, v388_.length, v388_.diameter, v388_.material, self.customEnvironment)
	if v389_ == nil then
		Logging.xmlWarning(self.xmlFile, "Unable to find connection hose with length \'%.2f\' and diameter \'%.2f\' in \'%s\'", v388_.length, v388_.diameter, "skipHoseClone")
		return false
	end
	link(v388_.node, v389_)
	setTranslation(v389_, 0, 0, 0)
	setRotation(v389_, 0, 0, 0)
	v388_.hoseNode = v389_
	v388_.visibilityNode = v389_
	v388_.startStraightening = v390_
	v388_.endStraightening = v391_
	v388_.endStraighteningBase = v391_
	v388_.endStraighteningDirectionBase = { 0, 0, 1 }
	v388_.endStraighteningDirection = v388_.endStraighteningDirectionBase
	v388_.minCenterPointAngle = v392_
	setVisibility(v388_.visibilityNode, false)
	v388_.objectChanges = {}
	return v388_
end

-- Local values: spec, nodes, _, node, toolConnectionHose, _, node
function ConnectionHoses:getConnectionTarget(attacherJointIndex, type, specType, excludeToolConnections)
	local v398_ = self.spec_connectionHoses
	if #v398_.targetNodes == 0 and #v398_.hoseSkipNodes == 0 then
		return nil
	end
	local v399_ = v398_.targetNodesByType[type]
	if v399_ ~= nil then
		for _, v400_ in ipairs(v399_) do
			if v400_.attacherJointIndices[attacherJointIndex] ~= nil and (v400_.specType == specType and not self:getIsConnectionTargetUsed(v400_)) then
				local v401_ = v398_.targetNodeToToolConnection[v400_.index]
				if v401_ == nil or (excludeToolConnections == nil or (not excludeToolConnections or v401_.delayedMounting ~= nil)) then
					return v400_, false
				else
					return nil
				end
			end
		end
	end
	local v402_ = v398_.hoseSkipNodeByType[type]
	if v402_ ~= nil then
		for _, v403_ in ipairs(v402_) do
			if v403_.specType == specType and self:getIsSkipNodeAvailable(v403_) then
				return v403_, true
			end
		end
	end
	return nil
end

-- Local values: spec, nodes, _, node, toolConnectionHose, _, node
function ConnectionHoses:iterateConnectionTargets(func, attacherJointIndex, type, specType, excludeToolConnections)
	local v410_ = self.spec_connectionHoses
	if #v410_.targetNodes == 0 and #v410_.hoseSkipNodes == 0 then
		return nil
	end
	local v411_ = v410_.targetNodesByType[type]
	if v411_ ~= nil then
		for _, v412_ in ipairs(v411_) do
			if v412_.attacherJointIndices[attacherJointIndex] ~= nil and (v412_.specType == specType and not self:getIsConnectionTargetUsed(v412_)) then
				local v413_ = v410_.targetNodeToToolConnection[v412_.index]
				if v413_ ~= nil and (excludeToolConnections ~= nil and (excludeToolConnections and v413_.delayedMounting == nil)) then
					return nil
				end
				if not func(v412_, false) then
					break
				end
			end
		end
	end
	local v414_ = v410_.hoseSkipNodeByType[type]
	if v414_ ~= nil then
		for _, v415_ in ipairs(v414_) do
			if v415_.specType == specType and (self:getIsSkipNodeAvailable(v415_) and not func(v415_, true)) then
				break
			end
		end
	end
	return nil
end

function ConnectionHoses:getIsConnectionTargetUsed(desc)
	return desc.connectedObject ~= nil
end

function ConnectionHoses:getIsConnectionHoseUsed(desc)
	return desc.connectedObject ~= nil
end

-- Local values: attacherVehicle, attacherJointIndex, implement
function ConnectionHoses:getIsSkipNodeAvailable(skipNode)
	if self.getAttacherVehicle == nil then
		return false
	end
	local v420_ = self:getAttacherVehicle()
	if v420_ ~= nil then
		local v421_ = v420_:getAttacherJointIndexFromObject(self)
		if v420_:getImplementFromAttacherJointIndex(v421_).inputJointDescIndex == skipNode.inputAttacherJointIndex then
			local v422_
			if v420_:getConnectionTarget(v421_, skipNode.type, skipNode.specType, true) == nil then
				v422_ = false
			else
				v422_ = skipNode.parentHose == nil
			end
			return v422_
		end
	end
	return false
end

-- Local values: spec
function ConnectionHoses:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
	local v425_ = self.spec_connectionHoses
	return v425_.hoseNodesByInputAttacher[inputJointDescIndex] == nil and {} or v425_.hoseNodesByInputAttacher[inputJointDescIndex]
end

-- Local values: spec, doConnect, node, referenceNode, hoseType, material, realLength, _, _, _, actualLength, sample
function ConnectionHoses:connectHose(sourceHose, targetObject, targetHose, updateToolConnections)
	local v431_ = self.spec_connectionHoses
	local v432_ = false
	if (updateToolConnections == nil or updateToolConnections) and not targetObject:updateToolConnectionHose(self, sourceHose, targetObject, targetHose, true) then
		targetObject:addHoseToDelayedMountings(self, sourceHose, targetObject, targetHose)
	else
		v432_ = true
	end
	if not v432_ then
		return false
	end
	targetHose.connectedObject = self
	sourceHose.connectedObject = targetObject
	sourceHose.targetHose = targetHose
	local v433_ = nil
	local v434_ = nil
	if sourceHose.adapterName == nil then
		if targetHose.adapterName ~= "NONE" then
			v433_, v434_ = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, targetHose.adapterName, self.customEnvironment)
		end
	elseif sourceHose.adapterName ~= "NONE" then
		v433_, v434_ = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, sourceHose.adapterName, self.customEnvironment)
	end
	if v433_ ~= nil then
		if sourceHose.adapterMaterial ~= nil then
			sourceHose.adapterMaterial:apply(v433_, "connector_color_mat")
		end
		link(g_connectionHoseManager:getSocketTarget(targetHose.socket, targetHose.node), v433_)
		setTranslation(v433_, 0, 0, 0)
		setRotation(v433_, 0, 0, 0)
		targetObject:addAllSubWashableNodes(v433_)
		targetHose.adapter.node = v433_
		targetHose.adapter.refNode = v434_
		targetHose.adapter.isLinked = true
	end
	sourceHose.targetNode = targetHose.adapter.refNode
	setVisibility(sourceHose.visibilityNode, true)
	setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)
	sourceHose.endStraightening = sourceHose.endStraighteningBase * targetHose.straighteningFactor
	sourceHose.endStraighteningDirection = targetHose.straighteningDirection or sourceHose.endStraighteningDirectionBase
	if sourceHose.dynamicLength then
		local v435_ = g_connectionHoseManager:getHoseTypeByName(sourceHose.type, self.customEnvironment)
		if v435_ ~= nil then
			local v436_ = g_connectionHoseManager:getHoseMaterialByName(v435_, sourceHose.hoseType, self.customEnvironment)
			if v436_ ~= nil then
				local v437_, _, _, _ = getShaderParameter(sourceHose.hoseNode, "lengthAndDiameter")
				local v438_ = calcDistanceFrom(sourceHose.hoseNode, sourceHose.targetNode)
				setShaderParameter(sourceHose.hoseNode, "uvScale", v438_ / v437_ * v436_.uvLengthScale, nil, nil, nil, false)
			end
		end
	end
	ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, true, sourceHose.connectedObject, sourceHose.connectedObject.setMovingToolDirty)
	ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true, targetHose.connectedObject, targetHose.connectedObject.setMovingToolDirty)
	g_connectionHoseManager:openSocket(sourceHose.socket)
	g_connectionHoseManager:openSocket(targetHose.socket)
	self:updateConnectionHose(sourceHose, 0)
	if self.isClient then
		local v439_ = v431_.samples.connect[sourceHose.type]
		if v439_ ~= nil and not g_soundManager:getIsSamplePlaying(v439_) then
			g_soundManager:playSample(v439_)
		end
	end
	local v440_ = v431_.updateableHoses
	table.insert(v440_, sourceHose)
	return true
end

-- Local values: spec, target, hoseHasSkipNodeTarget, hoseIsFromSkipNodeTarget, sample
function ConnectionHoses:disconnectHose(hose)
	local v443_ = self.spec_connectionHoses
	local v444_ = hose.targetHose
	if v444_ ~= nil then
		hose.connectedObject:updateToolConnectionHose(self, hose, hose.connectedObject, v444_, false)
		local v445_
		if v444_.isSkipNode == nil then
			v445_ = false
		else
			v445_ = v444_.isSkipNode
		end
		local v446_
		if hose.isClonedSkipNodeHose == nil then
			v446_ = false
		else
			v446_ = hose.isClonedSkipNodeHose
		end
		if v445_ or v446_ then
			if hose.parentVehicle ~= nil and hose.parentHose ~= nil then
				hose.parentHose.childVehicle = nil
				hose.parentHose.childHose = nil
				hose.parentVehicle:disconnectHose(hose.parentHose)
			end
			if hose.childVehicle ~= nil and hose.childHose ~= nil then
				hose.childHose.parentVehicle = nil
				hose.childHose.parentHose = nil
				hose.childVehicle:disconnectHose(hose.childHose)
			end
			v444_.parentHose = nil
		end
		if v444_.adapter ~= nil and (v444_.adapter.isLinked ~= nil and v444_.adapter.isLinked) then
			hose.connectedObject:removeAllSubWashableNodes(v444_.adapter.node)
			delete(v444_.adapter.node)
			v444_.adapter.node = v444_.node
			v444_.adapter.refNode = v444_.node
			v444_.adapter.isLinked = false
		end
		setVisibility(hose.visibilityNode, false)
		ObjectChangeUtil.setObjectChanges(v444_.objectChanges, false, hose.connectedObject, hose.connectedObject.setMovingToolDirty)
		ObjectChangeUtil.setObjectChanges(hose.objectChanges, false, v444_.connectedObject, v444_.connectedObject.setMovingToolDirty)
		g_connectionHoseManager:closeSocket(hose.socket)
		g_connectionHoseManager:closeSocket(v444_.socket)
		v444_.connectedObject = nil
		hose.connectedObject = nil
		hose.targetHose = nil
		table.removeElement(v443_.updateableHoses, hose)
		if self.isClient then
			local v447_ = v443_.samples.disconnect[hose.type]
			if v447_ ~= nil and not g_soundManager:getIsSamplePlaying(v447_) then
				g_soundManager:playSample(v447_)
			end
		end
	end
end

-- Local values: spec, setTargetNodeTranslation, toolConnectionHose, opositTargetIndex, opositTarget, differentSource, sameType, x, y, z, length, hose, _, _, _, dirX, dirY, dirZ, meshLength, diameterScale, _, _, materialId, _, additionalHoseNode, additionalLength, hose, _, _, _, dirX, dirY, dirZ, meshLength, diameterScale, _, _, materialId, parentToolConnectionHose, delayedHose, _, additionalHoseNode, parentToolConnectionHose, _, hose
function ConnectionHoses:updateToolConnectionHose(sourceObject, sourceHose, targetObject, targetHose, visibility)
	local v454_ = self.spec_connectionHoses
	local function v465_(p455_)
		-- upvalues: (copy) sourceHose
		if p455_.originalNodeTranslation == nil then
			p455_.originalNodeTranslation = { getTranslation(p455_.node) }
		else
			local v456_ = setTranslation
			local v457_ = p455_.node
			local v458_ = p455_.originalNodeTranslation
			v456_(v457_, unpack(v458_))
		end
		local v459_, v460_, v461_ = localToWorld(p455_.node, 0, sourceHose.diameter * 0.5, 0)
		local v462_, v463_, v464_ = worldToLocal(getParent(p455_.node), v459_, v460_, v461_)
		setTranslation(p455_.node, v462_, v463_, v464_)
	end
	local v466_ = v454_.targetNodeToToolConnection[targetHose.index]
	if v466_ == nil then
		return true
	end
	local v467_ = v466_.startTargetNodeIndex
	if v467_ == targetHose.index then
		v467_ = v466_.endTargetNodeIndex
	end
	local v468_ = v454_.targetNodes[v467_]
	if v468_ ~= nil then
		if visibility and (v466_.delayedMounting ~= nil and v466_.delayedMounting.sourceHose.connectedObject == nil) then
			local v469_ = v466_.delayedMounting.sourceObject ~= sourceObject
			local v470_
			if v466_.delayedMounting.sourceHose.type == sourceHose.type then
				v470_ = v466_.delayedMounting.sourceHose.specType == sourceHose.specType
			else
				v470_ = false
			end
			if v469_ and v470_ then
				local v471_, v472_, v473_ = localToLocal(targetHose.node, v468_.node, 0, 0, 0)
				local v474_ = MathUtil.vector3Length(v471_, v472_, v473_) - (v466_.additionalHoseOffset or 0) * 2
				if v466_.additionalHose then
					local v475_, _, _, _ = g_connectionHoseManager:getClonedHoseNode(sourceHose.type, sourceHose.hoseType, v474_, sourceHose.diameter, sourceHose.material, self.customEnvironment)
					if v475_ == nil then
						return false
					end
					link(targetHose.node, v475_)
					setTranslation(v475_, 0, 0, v466_.additionalHoseOffset or 0)
					local v476_, v477_, v478_ = localToLocal(v475_, v468_.node, 0, 0, 0)
					if v476_ ~= 0 or (v477_ ~= 0 or v478_ ~= 0) then
						setDirection(v475_, v476_, v477_, v478_, 0, 0, 1)
					end
					local v479_, v480_, _, _ = getShaderParameter(v475_, "lengthAndDiameter", 0)
					setScale(v475_, v480_, v480_, v474_ / v479_)
					local v481_ = getMaterial(v475_, 0)
					local v482_ = setMaterialCustomShaderVariation(v481_, "uvTransform", false)
					setMaterial(v475_, v482_, 0)
					if v466_.moveNodes then
						v465_(targetHose)
						v465_(v468_)
					end
					sourceObject:addAllSubWashableNodes(v475_)
					v466_.hoseNode = v475_
					v466_.hoseNodeObject = sourceObject
				end
				if v466_.additionalHoses ~= nil then
					for _, v483_ in ipairs(v466_.additionalHoses) do
						local v484_ = calcDistanceFrom(v483_.startNode, v483_.endNode)
						local v485_, _, _, _ = g_connectionHoseManager:getClonedHoseNode(sourceHose.type, sourceHose.hoseType, v484_, sourceHose.diameter, sourceHose.material, self.customEnvironment)
						if v485_ ~= nil then
							link(v483_.startNode, v485_)
							setTranslation(v485_, 0, 0, 0)
							local v486_, v487_, v488_ = localToLocal(v483_.endNode, v483_.startNode, 0, 0, 0)
							if v486_ ~= 0 or (v487_ ~= 0 or v488_ ~= 0) then
								setDirection(v485_, v486_, v487_, v488_, 0, 0, 1)
							end
							local v489_, v490_, _, _ = getShaderParameter(v485_, "lengthAndDiameter", 0)
							setScale(v485_, v490_, v490_, v484_ / v489_)
							local v491_ = getMaterial(v485_, 0)
							local v492_ = setMaterialCustomShaderVariation(v491_, "uvTransform", false)
							setMaterial(v485_, v492_, 0)
							sourceObject:addAllSubWashableNodes(v485_)
							v483_.hoseNode = v485_
							v483_.hoseNodeObject = sourceObject
						end
					end
				end
				v466_.connected = true
				if v466_.mountingNode ~= nil then
					setVisibility(v466_.mountingNode, true)
				end
				ObjectChangeUtil.setObjectChanges(v466_.objectChanges, true, v466_.objectChangesTarget, v466_.objectChangesTarget.setMovingToolDirty)
				if v466_.parentToolConnectionHose ~= nil then
					local v493_ = v466_.parentToolConnectionHose
					if v493_.mountingNode ~= nil then
						setVisibility(v493_.mountingNode, true)
					end
					ObjectChangeUtil.setObjectChanges(v493_.objectChanges, true, v493_.objectChangesTarget, v493_.objectChangesTarget.setMovingToolDirty)
				end
				if v466_.delayedMounting ~= nil then
					v466_.delayedUnmounting = {}
					local v494_ = v466_.delayedUnmounting
					local v495_ = v466_.delayedMounting
					table.insert(v494_, v495_)
					local v496_ = v466_.delayedUnmounting
					table.insert(v496_, {
						["sourceObject"] = sourceObject,
						["sourceHose"] = sourceHose,
						["targetObject"] = targetObject,
						["targetHose"] = targetHose
					})
					local v497_ = v466_.delayedMounting
					v466_.delayedMounting = nil
					v497_.sourceObject:connectHose(v497_.sourceHose, v497_.targetObject, v497_.targetHose, false)
					v497_.sourceObject:retryHoseSkipNodeConnections(false)
				end
				return true
			end
		elseif v466_.connected then
			v466_.connected = false
			if v466_.hoseNode ~= nil then
				v466_.hoseNodeObject:removeAllSubWashableNodes(v466_.hoseNode)
				delete(v466_.hoseNode)
				v466_.hoseNode = nil
				v466_.hoseNodeObject = nil
			end
			if v466_.additionalHoses ~= nil then
				for _, v498_ in ipairs(v466_.additionalHoses) do
					if v498_.hoseNode ~= nil then
						v498_.hoseNodeObject:removeAllSubWashableNodes(v498_.hoseNode)
						delete(v498_.hoseNode)
						v498_.hoseNode = nil
						v498_.hoseNodeObject = nil
					end
				end
			end
			if v466_.mountingNode ~= nil then
				setVisibility(v466_.mountingNode, false)
			end
			ObjectChangeUtil.setObjectChanges(v466_.objectChanges, false, v466_.objectChangesTarget, v466_.objectChangesTarget.setMovingToolDirty)
			if v466_.parentToolConnectionHose ~= nil then
				local v499_ = v466_.parentToolConnectionHose
				if not v499_.connected then
					if v499_.mountingNode ~= nil then
						setVisibility(v499_.mountingNode, false)
					end
					ObjectChangeUtil.setObjectChanges(v499_.objectChanges, false, v499_.objectChangesTarget, v499_.objectChangesTarget.setMovingToolDirty)
				end
			end
			if v466_.delayedUnmounting ~= nil then
				for _, v500_ in ipairs(v466_.delayedUnmounting) do
					if sourceHose ~= v500_.sourceHose then
						v500_.sourceObject:disconnectHose(v500_.sourceHose)
						if v500_.sourceHose.isClonedSkipNodeHose == nil or not v500_.sourceHose.isClonedSkipNodeHose then
							v466_.delayedMounting = v500_
						end
					end
				end
				v466_.delayedUnmounting = nil
			end
		end
	end
	return false
end

-- Local values: spec, toolConnectionHose, retry
function ConnectionHoses:addHoseToDelayedMountings(sourceObject, sourceHose, targetObject, targetHose)
	local v506_ = self.spec_connectionHoses.targetNodeToToolConnection[targetHose.index]
	if v506_ ~= nil and (v506_.delayedMounting == nil or sourceHose.typedIndex == v506_.typedIndex) then
		local v507_ = v506_.delayedMounting == nil
		v506_.delayedMounting = {
			["sourceObject"] = sourceObject,
			["sourceHose"] = sourceHose,
			["targetObject"] = targetObject,
			["targetHose"] = targetHose
		}
		if v507_ then
			self.rootVehicle:retryHoseSkipNodeConnections(true, sourceObject)
		end
	end
end

-- Local values: spec, attacherVehicle1, attacherVehicle2, attacherJointIndex, implement, firstValidTarget, isSkipNode, hose
function ConnectionHoses:connectHoseToSkipNode(sourceHose, targetObject, skipNode, childHose, childVehicle)
	local v514_ = self.spec_connectionHoses
	skipNode.connectedObject = self
	sourceHose.connectedObject = targetObject
	sourceHose.targetHose = skipNode
	sourceHose.targetNode = skipNode.node
	setVisibility(sourceHose.visibilityNode, true)
	setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)
	ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true, self, self.setMovingToolDirty)
	ObjectChangeUtil.setObjectChanges(skipNode.objectChanges, true, self, self.setMovingToolDirty)
	self:addAllSubWashableNodes(sourceHose.hoseNode)
	sourceHose.childVehicle = childVehicle
	sourceHose.childHose = childHose
	if self.getAttacherVehicle ~= nil then
		local v515_ = self:getAttacherVehicle()
		if v515_.getAttacherVehicle ~= nil then
			local v516_ = v515_:getAttacherVehicle()
			if v516_ ~= nil then
				local v517_ = v516_:getAttacherJointIndexFromObject(v515_)
				if v516_:getImplementFromAttacherJointIndex(v517_).inputJointDescIndex == skipNode.inputAttacherJointIndex then
					local v518_, v519_ = v516_:getConnectionTarget(v517_, skipNode.type, skipNode.specType)
					if v518_ == nil then
						if skipNode.parentHose ~= nil then
							sourceHose.parentVehicle = skipNode.parentVehicle
							sourceHose.parentHose = skipNode.parentHose
							sourceHose.parentHose.childVehicle = self
							sourceHose.parentHose.childHose = sourceHose
						end
					else
						local v520_ = v515_:getClonedSkipHoseNode(sourceHose, skipNode)
						if v519_ then
							v515_:connectHoseToSkipNode(v520_, v516_, v518_, sourceHose, v515_)
						else
							v515_:connectHose(v520_, v516_, v518_)
						end
						if skipNode.parentHose ~= nil then
							skipNode.parentVehicle:removeWashableNode(skipNode.parentHose.hoseNode)
							delete(skipNode.parentHose.hoseNode)
							table.removeElement(v514_.updateableHoses, skipNode.parentHose.childHose)
						end
						skipNode.parentVehicle = v515_
						skipNode.parentHose = v520_
						sourceHose.parentVehicle = v515_
						sourceHose.parentHose = v520_
						v520_.childVehicle = self
						v520_.childHose = sourceHose
						v515_:addAllSubWashableNodes(v520_.hoseNode)
					end
				end
			end
		end
	end
	local v521_ = v514_.updateableHoses
	table.insert(v521_, sourceHose)
	return true
end

-- Local values: hoses, _, hose
function ConnectionHoses:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex, updateToolConnections, excludeVehicle)
	if attacherVehicle.getConnectionTarget ~= nil then
		local v528_ = self:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
		for _, v_u_529_ in ipairs(v528_) do
			attacherVehicle:iterateConnectionTargets(function(p530_, p531_)
				-- upvalues: (copy) self, (copy) v_u_529_, (copy) attacherVehicle, (copy) updateToolConnections
				if self:getIsConnectionHoseUsed(v_u_529_) then
					return false
				end
				if p531_ then
					if self:connectHoseToSkipNode(v_u_529_, attacherVehicle, p530_) then
						return false
					end
				elseif self:connectHose(v_u_529_, attacherVehicle, p530_, updateToolConnections) then
					return false
				end
				return true
			end, jointDescIndex, v_u_529_.type, v_u_529_.specType)
		end
		self:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
	end
end

-- Local values: attachedImplements, _, implement, object
function ConnectionHoses:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
	if self.getAttachedImplements ~= nil then
		local v535_ = self:getAttachedImplements()
		for _, v536_ in ipairs(v535_) do
			local v537_ = v536_.object
			if v537_ ~= excludeVehicle and v537_.connectHosesToAttacherVehicle ~= nil then
				v537_:connectHosesToAttacherVehicle(self, v536_.inputJointDescIndex, v536_.jointDescIndex, updateToolConnections, excludeVehicle)
			end
		end
	end
end

-- Local values: spec, customHoses, i, customHose, customTargets, j, customTarget, customTargets, i, customTarget, j, customHose
function ConnectionHoses:connectCustomHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local v542_ = self.spec_connectionHoses
	local v543_ = v542_.customHosesByInputAttacher[inputJointDescIndex]
	if v543_ ~= nil then
		for v544_ = 1, #v543_ do
			local v545_ = v543_[v544_]
			if not v545_.isActive and attacherVehicle.spec_connectionHoses ~= nil then
				local v546_ = attacherVehicle.spec_connectionHoses.customHoseTargetsByAttacher[jointDescIndex]
				if v546_ ~= nil then
					for v547_ = 1, #v546_ do
						local v548_ = v546_[v547_]
						if not v548_.isActive and (v545_.type == v548_.type and v545_.specType == v548_.specType) then
							self:connectCustomHoseNode(v545_, v548_, attacherVehicle)
						end
					end
				end
			end
		end
	end
	local v549_ = v542_.customHoseTargetsByInputAttacher[inputJointDescIndex]
	if v549_ ~= nil then
		for v550_ = 1, #v549_ do
			local v551_ = v549_[v550_]
			if not v551_.isActive and attacherVehicle.spec_connectionHoses ~= nil then
				local v552_ = attacherVehicle.spec_connectionHoses.customHosesByAttacher[jointDescIndex]
				if v552_ ~= nil then
					for v553_ = 1, #v552_ do
						local v554_ = v552_[v553_]
						if not v554_.isActive and (v554_.type == v551_.type and v554_.specType == v551_.specType) then
							self:connectCustomHoseNode(v554_, v551_, attacherVehicle)
						end
					end
				end
			end
		end
	end
end

function ConnectionHoses:connectCustomHoseNode(customHose, customTarget, targetObject)
	self:updateCustomHoseNode(customHose, customTarget)
	customHose.isActive = true
	customTarget.isActive = true
	customHose.connectedTarget = customTarget
	customHose.connectedObject = targetObject
	customTarget.connectedHose = customHose
	customTarget.connectedObject = self
	ObjectChangeUtil.setObjectChanges(customHose.objectChanges, true, customHose.objectChangesTarget, customHose.objectChangesTarget.setMovingToolDirty)
	ObjectChangeUtil.setObjectChanges(customTarget.objectChanges, true, customTarget.objectChangesTarget, customTarget.objectChangesTarget.setMovingToolDirty)
	if self.setMovingToolDirty ~= nil then
		self:setMovingToolDirty(customHose.node, true)
	end
end

function ConnectionHoses:updateCustomHoseNode(customHose, customTarget)
	setTranslation(customHose.node, localToLocal(customTarget.node, getParent(customHose.node), 0, 0, 0))
	setRotation(customHose.node, localRotationToLocal(customTarget.node, getParent(customHose.node), 0, 0, 0))
	if self.setMovingToolDirty ~= nil then
		self:setMovingToolDirty(customHose.node)
	end
end

function ConnectionHoses:disconnectCustomHoseNode(customHose, customTarget)
	local v565_ = setTranslation
	local v566_ = customHose.node
	local v567_ = customHose.startTranslation
	v565_(v566_, unpack(v567_))
	local v568_ = setRotation
	local v569_ = customHose.node
	local v570_ = customHose.startRotation
	v568_(v569_, unpack(v570_))
	if self.setMovingToolDirty ~= nil then
		self:setMovingToolDirty(customHose.node, true)
	end
	customHose.isActive = false
	customTarget.isActive = false
	customHose.connectedTarget = nil
	customHose.connectedObject = nil
	customTarget.connectedHose = nil
	customTarget.connectedObject = nil
	ObjectChangeUtil.setObjectChanges(customHose.objectChanges, false, customHose.objectChangesTarget, customHose.objectChangesTarget.setMovingToolDirty)
	ObjectChangeUtil.setObjectChanges(customTarget.objectChanges, false, customTarget.objectChangesTarget, customTarget.objectChangesTarget.setMovingToolDirty)
end

-- Local values: spec, attacherVehicle, implement
function ConnectionHoses:setConnectionHosesActive(connectionHosesActive)
	local v573_ = self.spec_connectionHoses
	if connectionHosesActive ~= v573_.connectionHosesActive then
		v573_.connectionHosesActive = connectionHosesActive
		local v574_ = self:getAttacherVehicle()
		if v574_ ~= nil then
			local v575_ = v574_:getImplementByObject(self)
			if v575_ ~= nil then
				if connectionHosesActive then
					self:connectHosesToAttacherVehicle(v574_, v575_.inputJointDescIndex, v575_.jointDescIndex)
					self:connectCustomHosesToAttacherVehicle(v574_, v575_.inputJointDescIndex, v575_.jointDescIndex)
					return
				end
				ConnectionHoses.onPreDetach(self, v574_, v575_)
			end
		end
	end
end

-- Local values: customHoseIndices, customTargetIndices, localHoseIndices
function ConnectionHoses:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	local v581_ = xmlFile:getValue(baseName .. ".connectionHoses#customHoseIndices", nil, true)
	if v581_ ~= nil and #v581_ > 0 then
		entry.customHoseIndices = v581_
	end
	local v582_ = xmlFile:getValue(baseName .. ".connectionHoses#customTargetIndices", nil, true)
	if v582_ ~= nil and #v582_ > 0 then
		entry.customTargetIndices = v582_
	end
	local v583_ = xmlFile:getValue(baseName .. ".connectionHoses#localHoseIndices", nil, true)
	if v583_ ~= nil and #v583_ > 0 then
		entry.localHoseIndices = v583_
	end
	return true
end

-- Local values: spec, i, customHoseIndex, customHose, spec, i, customTargetIndex, customTarget, spec, i, localHoseIndex, localHose
function ConnectionHoses:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.customHoseIndices ~= nil then
		local v588_ = self.spec_connectionHoses
		for v589_ = 1, #part.customHoseIndices do
			local v590_ = part.customHoseIndices[v589_]
			local v591_ = v588_.customHoses[v590_]
			if v591_ ~= nil and v591_.isActive then
				self:updateCustomHoseNode(v591_, v591_.connectedTarget)
			end
		end
	end
	if part.customTargetIndices ~= nil then
		local v592_ = self.spec_connectionHoses
		for v593_ = 1, #part.customTargetIndices do
			local v594_ = part.customTargetIndices[v593_]
			local v595_ = v592_.customHoseTargets[v594_]
			if v595_ ~= nil and v595_.isActive then
				self:updateCustomHoseNode(v595_.connectedHose, v595_)
			end
		end
	end
	if part.localHoseIndices ~= nil then
		local v596_ = self.spec_connectionHoses
		for v597_ = 1, #part.localHoseIndices do
			local v598_ = part.localHoseIndices[v597_]
			local v599_ = v596_.localHoseNodes[v598_]
			if v599_ ~= nil and v599_.hose.connectedObject ~= nil then
				self:updateConnectionHose(v599_.hose, v598_)
			end
		end
	end
end

function ConnectionHoses:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if self.spec_connectionHoses.connectionHosesActive then
		self:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
		self:connectCustomHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
	end
end

-- Local values: spec, inputJointDescIndex, hoses, _, hose, i, hose, attacherVehicleSpec, _, toolConnector, customHoses, i, customHose, customTargets, i, customTarget
function ConnectionHoses:onPreDetach(attacherVehicle, implement)
	local v606_ = self.spec_connectionHoses
	local v607_ = self:getActiveInputAttacherJointDescIndex()
	local v608_ = self:getConnectionHosesByInputAttacherJoint(v607_)
	for _, v609_ in ipairs(v608_) do
		self:disconnectHose(v609_)
	end
	for v610_ = #v606_.updateableHoses, 1, -1 do
		local v611_ = v606_.updateableHoses[v610_]
		if v611_.connectedObject == attacherVehicle then
			self:disconnectHose(v611_)
		end
	end
	local v612_ = attacherVehicle.spec_connectionHoses
	if v612_ ~= nil then
		for _, v613_ in pairs(v612_.toolConnectorHoses) do
			if v613_.delayedMounting ~= nil and v613_.delayedMounting.sourceObject == self then
				v613_.delayedMounting = nil
			end
		end
	end
	local v614_ = v606_.customHosesByInputAttacher[v607_]
	if v614_ ~= nil then
		for v615_ = 1, #v614_ do
			local v616_ = v614_[v615_]
			if v616_.isActive then
				self:disconnectCustomHoseNode(v616_, v616_.connectedTarget)
			end
		end
	end
	local v617_ = v606_.customHoseTargetsByInputAttacher[v607_]
	if v617_ ~= nil then
		for v618_ = 1, #v617_ do
			local v619_ = v617_[v618_]
			if v619_.isActive then
				self:disconnectCustomHoseNode(v619_.connectedHose, v619_)
			end
		end
	end
end
local v_u_620_ = {
	{
		["sourceType"] = "TOOL_CONNECTOR_TOP_RIGHT",
		["name"] = "TOOL_CONNECTOR_TOP_RIGHT_02",
		["filename"] = "data/shared/connectionHoses/AdditionalTopRightHose.i3d",
		["sourceLength"] = 3.045
	}
}
local v_u_621_ = {
	{
		["sourceType"] = "TOOL_CONNECTOR_TOP_RIGHT",
		["filename"] = "data/shared/connectionHoses/toolConnectionHoseMounts/vaderstadProceedV.xml"
	},
	{
		["sourceType"] = "TOOL_CONNECTOR_TOP_RIGHT",
		["filename"] = "data/shared/connectionHoses/toolConnectionHoseMounts/skyProgressTF.xml"
	}
}

-- Upvalues: ADDITIONAL_TOOL_CONNECTION_HOSES, ADDITIONAL_TOOL_CONNECTION_HOSES_XML
-- Local values: spec, i, toolConnectorHose, startTarget, endTarget, _, data, length, arguments, sharedLoadRequestId, _, data, length, linkNode, x, y, z, rx, ry, rz, toolConnectionHoseMount
function ConnectionHoses:registerAdditionalToolConnectionHoses()
	-- upvalues: (copy) v_u_620_, (copy) v_u_621_
	local v_u_623_ = self.spec_connectionHoses
	for v624_ = 1, #v_u_623_.toolConnectorHoses do
		local v625_ = v_u_623_.toolConnectorHoses[v624_]
		local v626_ = v_u_623_.targetNodes[v625_.startTargetNodeIndex]
		local v627_ = v_u_623_.targetNodes[v625_.endTargetNodeIndex]
		for _, v628_ in pairs(v_u_620_) do
			if v626_ ~= nil and (v626_.type == v628_.sourceType and (v627_ ~= nil and (v627_.type == v628_.sourceType and calcDistanceFrom(v626_.node, v627_.node) > 0))) then
				local v629_ = self:loadSubSharedI3DFile(v628_.filename, false, false, ConnectionHoses.onAdditionalI3DFileLoaded, self, {
					["spec"] = v_u_623_,
					["startTarget"] = v626_,
					["endTarget"] = v627_,
					["data"] = v628_
				})
				local v630_ = v_u_623_.additionalSharedLoadRequestIds
				table.insert(v630_, v629_)
			end
		end
		for _, v631_ in pairs(v_u_621_) do
			if v626_ ~= nil and (v626_.type == v631_.sourceType and (v627_ ~= nil and v627_.type == v631_.sourceType)) then
				local v632_ = calcDistanceFrom(v626_.node, v627_.node)
				if v632_ > 0 then
					local v633_ = getParent(v627_.node)
					local v634_, v635_, v636_ = getTranslation(v627_.node)
					local v637_, v638_, v639_ = getRotation(v627_.node)
					local v_u_640_ = ToolConnectionHoseMount.new(self)
					v_u_640_:setReferenceTargets(v626_, v627_)
					v_u_640_:setLinkNode(v633_, v634_, v635_, v636_, v637_, v638_, v639_)
					v_u_640_:setLength(v632_)
					v_u_640_:setCallback(function(p641_)
						-- upvalues: (copy) v_u_623_, (copy) v_u_640_
						if p641_ then
							local v642_ = v_u_623_.toolConnectionHoseMounts
							local v643_ = v_u_640_
							table.insert(v642_, v643_)
						else
							v_u_640_:delete()
						end
					end)
					v_u_640_:loadFromXML(v631_.filename, self.baseDirectory)
				end
			end
		end
	end
end
local function v_u_651_(p644_, p645_, p646_, p647_)
	local v648_ = {
		["node"] = p645_,
		["attacherJointIndices"] = p646_.attacherJointIndices,
		["type"] = p647_,
		["straighteningFactor"] = p646_.straighteningFactor,
		["adapterName"] = p646_.adapterName,
		["adapter"] = {}
	}
	v648_.adapter.node = p645_
	v648_.adapter.refNode = p645_
	v648_.objectChanges = {}
	local v649_ = p644_.targetNodes
	table.insert(v649_, v648_)
	v648_.index = #p644_.targetNodes
	if p644_.targetNodesByType[v648_.type] == nil then
		p644_.targetNodesByType[v648_.type] = {}
	end
	local v650_ = p644_.targetNodesByType[v648_.type]
	table.insert(v650_, v648_)
	return v648_.index
end

-- Upvalues: addHoseTarget
-- Local values: spec, newMounting, newStartNode, newEndNode, length, newToolConnectionHose
function ConnectionHoses:onAdditionalI3DFileLoaded(node, failedReason, args)
	-- upvalues: (copy) v_u_651_
	if node ~= 0 then
		local v655_ = args.spec
		local v656_ = getChildAt(node, 0)
		local v657_ = getChildAt(v656_, 1)
		local v658_ = getChildAt(v656_, 0)
		link(getParent(args.endTarget.node), v656_)
		setTranslation(v656_, getTranslation(args.endTarget.node))
		setRotation(v656_, getRotation(args.endTarget.node))
		local v659_ = calcDistanceFrom(args.startTarget.node, args.endTarget.node)
		setScale(v656_, 1, 1, v659_ / args.data.sourceLength)
		setScale(v657_, 1, 1, 1 / (v659_ / args.data.sourceLength))
		setScale(v658_, 1, 1, 1 / (v659_ / args.data.sourceLength))
		delete(node)
		local v660_ = {
			["startTargetNodeIndex"] = v_u_651_(v655_, v657_, args.startTarget, args.data.name),
			["endTargetNodeIndex"] = v_u_651_(v655_, v658_, args.endTarget, args.data.name),
			["mountingNode"] = v656_,
			["moveNodes"] = true,
			["additionalHose"] = true,
			["objectChanges"] = {},
			["objectChangesTarget"] = self
		}
		setVisibility(v656_, false)
		if getHasShaderParameter(v660_.mountingNode, "colorMat0") then
			v660_.mountingNodeDefaultColor = { getShaderParameter(v660_.mountingNode, "colorMat0") }
		end
		local v661_ = args.spec.toolConnectorHoses
		table.insert(v661_, v660_)
		args.spec.targetNodeToToolConnection[v660_.startTargetNodeIndex] = v660_
		args.spec.targetNodeToToolConnection[v660_.endTargetNodeIndex] = v660_
	end
end

-- Local values: spec, colors, prefix, indexByType, index, targetHose, node, referenceNode, material, attacherJointDesc
function ConnectionHoses.consoleCommandTestSockets(vehicle, attacherJointIndex)
	local v664_ = vehicle.spec_connectionHoses
	if v664_ ~= nil then
		local v665_ = {
			["hydraulicIn"] = Color.new(0, 1, 0),
			["hydraulicOut"] = Color.new(0, 0, 1),
			["electric"] = Color.new(1, 0, 1),
			["airDoubleRed"] = Color.new(1, 0, 0),
			["airDoubleYellow"] = Color.new(1, 1, 0),
			["isobus"] = Color.new(1, 1, 1)
		}
		local v666_ = {}
		local v667_ = {
			["hydraulicIn"] = "in",
			["hydraulicOut"] = "out",
			["electric"] = "e",
			["airDoubleRed"] = "red",
			["airDoubleYellow"] = "yel",
			["isobus"] = "iso"
		}
		for _, v668_ in ipairs(v664_.targetNodes) do
			if v668_.socket ~= nil then
				g_connectionHoseManager:closeSocket(v668_.socket)
			end
			if v668_.debugNode ~= nil then
				delete(v668_.debugNode)
				v668_.debugNode = nil
			end
			if v668_.debugLine ~= nil then
				g_debugManager:removeElement(v668_.debugLine)
				v668_.debugLine = nil
			end
			if v668_.debugText ~= nil then
				g_debugManager:removeElement(v668_.debugText)
				v668_.debugText = nil
			end
			if v668_.objectChanges ~= nil then
				ObjectChangeUtil.setObjectChanges(v668_.objectChanges, false, vehicle, vehicle.setMovingToolDirty)
			end
			if v668_.attacherJointIndices[attacherJointIndex] ~= nil then
				if v666_[v668_.type] == nil then
					v666_[v668_.type] = 0
				end
				v666_[v668_.type] = v666_[v668_.type] + 1
				if v668_.socket ~= nil then
					g_connectionHoseManager:openSocket(v668_.socket)
				end
				local v669_, v670_ = g_connectionHoseManager:getClonedAdapterNode(v668_.type, "DEFAULT", vehicle.customEnvironment)
				if v669_ ~= nil then
					local v671_ = VehicleMaterial.new()
					v671_:setTemplateName("plasticPainted")
					v671_:setColor(1, 1, 1)
					v671_:apply(v669_)
					link(g_connectionHoseManager:getSocketTarget(v668_.socket, v668_.node), v669_)
					setTranslation(v669_, 0, 0, 0)
					setRotation(v669_, 0, 0, 0)
					v668_.debugNode = v669_
					local v672_ = vehicle:getAttacherJointByJointDescIndex(attacherJointIndex)
					if v672_ ~= nil then
						v668_.debugLine = DebugLine.new():createWithStartAndEndNode(v672_.jointTransform, v670_ or v669_, false, true, 100, true)
						v668_.debugLine:setColors(v665_[v668_.type], v665_[v668_.type])
						g_debugManager:addElement(v668_.debugLine, nil, nil, math.huge)
						local v673_ = DebugText.new()
						local v674_ = v667_[v668_.type]
						local v675_ = v666_[v668_.type]
						v668_.debugText = v673_:createWithNode(v670_, v674_ .. tostring(v675_), 0.015, true)
						v668_.debugText.color = v665_[v668_.type]
						g_debugManager:addElement(v668_.debugText, nil, nil, math.huge)
					end
				end
				if v668_.objectChanges ~= nil then
					ObjectChangeUtil.setObjectChanges(v668_.objectChanges, true, vehicle, vehicle.setMovingToolDirty)
				end
			end
		end
	end
end

-- Local values: spec, startColor, betweenColor, endColor, _, targetHose, _, element, i, toolConnectionHose, parentToolConnectionHose, _, element, toolConnectionHose, startTarget, endTarget, _, attacherJointIndex, attacherJointDesc, debugLine, debugText, _, attacherJointIndex, attacherJointDesc, debugLine, debugText, debugLine, debugTextStart, debugTextEnd, parentToolConnectionHose
function ConnectionHoses.consoleCommandTestToolConnection(vehicle, toolConnectionIndex)
	local v678_ = vehicle.spec_connectionHoses
	if v678_ ~= nil then
		local v679_ = Color.new(0, 1, 0)
		local v680_ = Color.new(0, 0, 1)
		local v681_ = Color.new(1, 0, 0)
		for _, v682_ in ipairs(v678_.targetNodes) do
			if v682_.socket ~= nil then
				g_connectionHoseManager:closeSocket(v682_.socket)
			end
			if v682_.debugElements ~= nil then
				for _, v683_ in pairs(v682_.debugElements) do
					g_debugManager:removeElement(v683_)
				end
				v682_.debugElements = nil
			end
			if v682_.debugText ~= nil then
				g_debugManager:removeElement(v682_.debugText)
				v682_.debugText = nil
			end
			if v682_.objectChanges ~= nil then
				ObjectChangeUtil.setObjectChanges(v682_.objectChanges, false, vehicle, vehicle.setMovingToolDirty)
			end
		end
		for v684_ = 1, #v678_.toolConnectorHoses do
			local v685_ = v678_.toolConnectorHoses[v684_]
			if v685_.mountingNode ~= nil then
				setVisibility(v685_.mountingNode, false)
			end
			ObjectChangeUtil.setObjectChanges(v685_.objectChanges, false, v685_.objectChangesTarget, v685_.objectChangesTarget.setMovingToolDirty)
			if v685_.parentToolConnectionHose ~= nil then
				local v686_ = v685_.parentToolConnectionHose
				if v686_.mountingNode ~= nil then
					setVisibility(v686_.mountingNode, false)
				end
				ObjectChangeUtil.setObjectChanges(v686_.objectChanges, false, v686_.objectChangesTarget, v686_.objectChangesTarget.setMovingToolDirty)
			end
			if v685_.debugElements ~= nil then
				for _, v687_ in pairs(v685_.debugElements) do
					g_debugManager:removeElement(v687_)
				end
				v685_.debugElements = nil
			end
		end
		local v688_ = v678_.toolConnectorHoses[toolConnectionIndex]
		if v688_ ~= nil then
			local v689_ = v678_.targetNodes[v688_.startTargetNodeIndex]
			local v690_ = v678_.targetNodes[v688_.endTargetNodeIndex]
			for _, v691_ in pairs(v689_.attacherJointIndices) do
				local v692_ = vehicle:getAttacherJointByJointDescIndex(v691_)
				if v692_ ~= nil then
					local v693_ = DebugLine.new():createWithStartAndEndNode(v692_.jointTransform, v689_.node, false, false, 100, true)
					v693_:setColors(v679_, v679_)
					g_debugManager:addElement(v693_, nil, nil, math.huge)
					local v694_ = DebugText.new():createWithNode(v692_.jointTransform, getName(v692_.jointTransform), 0.01, true)
					v694_.color = v679_
					g_debugManager:addElement(v694_, nil, nil, math.huge)
					if v689_.debugElements == nil then
						v689_.debugElements = {}
					end
					local v695_ = v689_.debugElements
					table.insert(v695_, v693_)
					local v696_ = v689_.debugElements
					table.insert(v696_, v694_)
				end
			end
			for _, v697_ in pairs(v690_.attacherJointIndices) do
				local v698_ = vehicle:getAttacherJointByJointDescIndex(v697_)
				if v698_ ~= nil then
					local v699_ = DebugLine.new():createWithStartAndEndNode(v698_.jointTransform, v690_.node, false, false, 100, true)
					v699_:setColors(v681_, v681_)
					g_debugManager:addElement(v699_, nil, nil, math.huge)
					local v700_ = DebugText.new():createWithNode(v698_.jointTransform, getName(v698_.jointTransform), 0.01, true)
					v700_.color = v681_
					g_debugManager:addElement(v700_, nil, nil, math.huge)
					if v690_.debugElements == nil then
						v690_.debugElements = {}
					end
					local v701_ = v690_.debugElements
					table.insert(v701_, v699_)
					local v702_ = v690_.debugElements
					table.insert(v702_, v700_)
				end
			end
			local v703_ = DebugLine.new():createWithStartAndEndNode(v689_.node, v690_.node, false, true, 100, true)
			v703_:setColors(v680_, v680_)
			g_debugManager:addElement(v703_, nil, nil, math.huge)
			local v704_ = DebugText.new():createWithNode(v689_.node, getName(v689_.node), 0.01, true)
			v704_.color = v679_
			g_debugManager:addElement(v704_, nil, nil, math.huge)
			local v705_ = DebugText.new():createWithNode(v690_.node, getName(v690_.node), 0.01, true)
			v705_.color = v681_
			g_debugManager:addElement(v705_, nil, nil, math.huge)
			if v688_.debugElements == nil then
				v688_.debugElements = {}
			end
			local v706_ = v688_.debugElements
			table.insert(v706_, v703_)
			local v707_ = v688_.debugElements
			table.insert(v707_, v704_)
			local v708_ = v688_.debugElements
			table.insert(v708_, v705_)
			if v688_.mountingNode ~= nil then
				setVisibility(v688_.mountingNode, true)
			end
			ObjectChangeUtil.setObjectChanges(v688_.objectChanges, true, v688_.objectChangesTarget, v688_.objectChangesTarget.setMovingToolDirty)
			if v688_.parentToolConnectionHose ~= nil then
				local v709_ = v688_.parentToolConnectionHose
				if v709_.mountingNode ~= nil then
					setVisibility(v709_.mountingNode, true)
				end
				ObjectChangeUtil.setObjectChanges(v709_.objectChanges, true, v709_.objectChangesTarget, v709_.objectChangesTarget.setMovingToolDirty)
			end
		end
	end
end
