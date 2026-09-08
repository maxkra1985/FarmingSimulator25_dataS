-- Local values: PERLIN_NOISE, sin, getRandomOffset
GroundAdjustedNodes = {}
GroundAdjustedNodes.GROUND_ADJUSTED_NODE_XML_KEY = "vehicle.groundAdjustedNodes.groundAdjustedNode(?)"
GroundAdjustedNodes.COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
GroundAdjustedNodes.COLLISION_MASK_WATER = GroundAdjustedNodes.COLLISION_MASK + CollisionFlag.WATER

function GroundAdjustedNodes.prerequisitesPresent(specializations)
	return true
end
function GroundAdjustedNodes.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("groundAdjustedNode", g_i18n:getText("shop_configuration"), "groundAdjustedNodes", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("GroundAdjustedNodes")
	v1_:register(XMLValueType.FLOAT, "vehicle.groundAdjustedNodes#maxUpdateDistance", "If the player is more than this distance away the nodes will no longer be updated", 100)
	v1_:register(XMLValueType.FLOAT, "vehicle.groundAdjustedNodes#maxUpdateDistanceWobble", "If the player is more than this distance away the wobble effect which is applied on the field will not be shown anymore", 50)
	v1_:register(XMLValueType.BOOL, "vehicle.groundAdjustedNodes#adjustToWater", "If \'true\', the adjust node will be placed on top of any water plane", false)
	v1_:register(XMLValueType.BOOL, "vehicle.groundAdjustedNodes#onlyActiveWhileAttached", "Defines if the tool needs to be attached to have the ground adjusted nodes active", true)
	GroundAdjustedNodes.registerNodeXMLPaths(v1_, "vehicle.groundAdjustedNodes.groundAdjustedNode(?)")
	GroundAdjustedNodes.registerNodeXMLPaths(v1_, "vehicle.groundAdjustedNodes.groundAdjustedNodeConfigurations.groundAdjustedNodeConfiguration(?).groundAdjustedNode(?)")
	v1_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p2_, p3_)
		p2_:register(XMLValueType.FLOAT, p3_ .. "#startGroundAdjustScale", "Start scale of ground adjusted node (blending between detected ground and inactive position)")
		p2_:register(XMLValueType.FLOAT, p3_ .. "#endGroundAdjustScale", "Start scale of ground adjusted node (blending between detected ground and inactive position)")
	end)
	v1_:setXMLSpecializationType()
end

function GroundAdjustedNodes.registerNodeXMLPaths(schema, basePath)
	schema:addDelayedRegistrationPath(basePath, "GroundAdjustedNodes:node")
	schema:register(XMLValueType.FLOAT, basePath .. "#activationTime", "In this time after the activation of the node the #moveSpeedStateChange will be used", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#yOffset", "Raycast Y translation offset (Raycast will start this distance above the node)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".raycastNode(?)#node", "Ground adjusted raycast node")
	schema:register(XMLValueType.FLOAT, basePath .. ".raycastNode(?)#distance", "Ground adjusted raycast distance", 4)
	schema:register(XMLValueType.INT, basePath .. ".raycastNode(?)#updateFrame", "Defines the frame delay between two raycasts", "Number of raycasts")
	schema:register(XMLValueType.FLOAT, basePath .. ".raycastNode(?)#yOffset", "Raycast Y translation offset (Raycast will start this distance above the node)", 0)
	GroundAdjustedNodes.registerAdjustNodeXMLPaths(schema, basePath)
	GroundAdjustedNodes.registerAdjustNodeXMLPaths(schema, basePath .. ".adjustNode(?)")
end

function GroundAdjustedNodes.registerAdjustNodeXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Ground adjusted node")
	schema:register(XMLValueType.FLOAT, basePath .. "#minY", "Min. Y translation", "translation in i3d - 1")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxY", "Max. Y translation", "minY + 1")
	schema:register(XMLValueType.FLOAT, basePath .. "#moveSpeed", "Move speed", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#resetIfNotActive", "Reset node to start translation if not active", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#moveSpeedStateChange", "Move speed while node is inactive or active an in range of #activationTime", "#moveSpeed")
	schema:register(XMLValueType.FLOAT, basePath .. "#updateThreshold", "Position of node will be updated if change is greater than this value", 0.002)
	schema:register(XMLValueType.FLOAT, basePath .. "#inActiveOffsetY", "Offset of the in active position in Y, will be applied on top of the current position in i3d", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#inActiveY", "Adjust node will go to this state while it\'s not active", "Position in i3d file")
	schema:register(XMLValueType.BOOL, basePath .. "#averageInActivePosY", "While nodes are turned off the average Y position will be used as target for all nodes", false)
end

function GroundAdjustedNodes.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAdjustedNodeFromXML", GroundAdjustedNodes.loadGroundAdjustedNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAdjustedAdjustNodeFromXML", GroundAdjustedNodes.loadGroundAdjustedAdjustNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "initGroundAdjustedAdjustNode", GroundAdjustedNodes.initGroundAdjustedAdjustNode)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAdjustedRaycastNodeFromXML", GroundAdjustedNodes.loadGroundAdjustedRaycastNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsGroundAdjustedNodeActive", GroundAdjustedNodes.getIsGroundAdjustedNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "updateGroundAdjustedRaycasts", GroundAdjustedNodes.updateGroundAdjustedRaycasts)
	SpecializationUtil.registerFunction(vehicleType, "updateGroundAdjustedNode", GroundAdjustedNodes.updateGroundAdjustedNode)
end

function GroundAdjustedNodes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", GroundAdjustedNodes)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", GroundAdjustedNodes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", GroundAdjustedNodes)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", GroundAdjustedNodes)
end

-- Local values: spec, configurationId, configKey
function GroundAdjustedNodes:onLoad(savegame)
	local v_u_11_ = self.spec_groundAdjustedNodes
	local v12_ = self.configurations.groundAdjustedNode or 1
	local v13_ = string.format("vehicle.groundAdjustedNodes.groundAdjustedNodeConfigurations.groundAdjustedNodeConfiguration(%d)", v12_ - 1)
	v_u_11_.raycastNodesByNode = {}
	v_u_11_.maxUpdateDistance = self.xmlFile:getValue("vehicle.groundAdjustedNodes#maxUpdateDistance", 100)
	v_u_11_.maxUpdateDistanceWobble = self.xmlFile:getValue("vehicle.groundAdjustedNodes#maxUpdateDistanceWobble", 50)
	v_u_11_.adjustToWater = self.xmlFile:getValue("vehicle.groundAdjustedNodes#adjustToWater", false)
	v_u_11_.onlyActiveWhileAttached = self.xmlFile:getValue("vehicle.groundAdjustedNodes#onlyActiveWhileAttached", true)
	v_u_11_.groundAdjustedNodes = {}
	self.xmlFile:iterate("vehicle.groundAdjustedNodes.groundAdjustedNode", function(_, p14_)
		-- upvalues: (copy) self, (copy) v_u_11_
		local v15_ = {}
		if self:loadGroundAdjustedNodeFromXML(self.xmlFile, p14_, v15_) then
			local v16_ = v_u_11_.groundAdjustedNodes
			table.insert(v16_, v15_)
		end
	end)
	self.xmlFile:iterate(v13_ .. ".groundAdjustedNode", function(_, p17_)
		-- upvalues: (copy) self, (copy) v_u_11_
		local v18_ = {}
		if self:loadGroundAdjustedNodeFromXML(self.xmlFile, p17_, v18_) then
			local v19_ = v_u_11_.groundAdjustedNodes
			table.insert(v19_, v18_)
		end
	end)
	if #v_u_11_.groundAdjustedNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", GroundAdjustedNodes)
		SpecializationUtil.removeEventListener(self, "onUpdate", GroundAdjustedNodes)
		SpecializationUtil.removeEventListener(self, "onRegisterAnimationValueTypes", GroundAdjustedNodes)
	end
end

-- Local values: spec, _, groundAdjustedNode, i, adjustNode
function GroundAdjustedNodes:onLoadFinished(savegame)
	local v21_ = self.spec_groundAdjustedNodes
	for _, v22_ in pairs(v21_.groundAdjustedNodes) do
		v22_.isActive = self:getIsGroundAdjustedNodeActive(v22_, true)
		if v22_.isActive then
			for v23_ = 1, #v22_.adjustNodes do
				local v24_ = v22_.adjustNodes[v23_]
				local v25_ = v24_.y - v24_.curY
				if math.abs(v25_) > 0.01 then
					setTranslation(v24_.node, v24_.x, v24_.curY, v24_.z)
					if self.setMovingToolDirty ~= nil then
						self:setMovingToolDirty(v24_.node)
					end
				end
			end
		end
	end
end

-- Local values: spec, _, groundAdjustedNode
function GroundAdjustedNodes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v28_ = self.spec_groundAdjustedNodes
	if self.currentUpdateDistance < v28_.maxUpdateDistance then
		self:updateGroundAdjustedRaycasts(dt)
		for _, v29_ in pairs(v28_.groundAdjustedNodes) do
			self:updateGroundAdjustedNode(v29_, dt)
		end
	end
end

-- Local values: spec, baseAdjustNode, i
function GroundAdjustedNodes:loadGroundAdjustedNodeFromXML(xmlFile, key, groundAdjustedNode)
	local v_u_34_ = self.spec_groundAdjustedNodes
	groundAdjustedNode.yOffset = xmlFile:getValue(key .. "#yOffset")
	groundAdjustedNode.activationTime = xmlFile:getValue(key .. "#activationTime", 0) * 1000
	groundAdjustedNode.activationTimer = groundAdjustedNode.activationTime
	groundAdjustedNode.activeScale = 1
	groundAdjustedNode.adjustNodes = {}
	local v35_ = {}
	if self:loadGroundAdjustedAdjustNodeFromXML(xmlFile, key, groundAdjustedNode, v35_, false) then
		local v36_ = groundAdjustedNode.adjustNodes
		table.insert(v36_, v35_)
	end
	xmlFile:iterate(key .. ".adjustNode", function(_, p37_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) groundAdjustedNode
		local v38_ = {}
		if self:loadGroundAdjustedAdjustNodeFromXML(xmlFile, p37_, groundAdjustedNode, v38_, true) then
			local v39_ = groundAdjustedNode.adjustNodes
			table.insert(v39_, v38_)
		end
	end)
	groundAdjustedNode.raycastNodes = {}
	xmlFile:iterate(key .. ".raycastNode", function(_, p40_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) groundAdjustedNode, (copy) key, (copy) v_u_34_
		local v41_ = self:loadGroundAdjustedRaycastNodeFromXML(xmlFile, p40_, groundAdjustedNode, {})
		if v41_ ~= nil then
			if #groundAdjustedNode.raycastNodes > 2 then
				Logging.xmlWarning(self.xmlFile, "Max. two raycast nodes are allowed per groundAdjustedNode! (%s)", key)
				return
			end
			local v42_ = groundAdjustedNode.raycastNodes
			table.insert(v42_, v41_)
			v_u_34_.raycastNodesByNode[v41_.node] = v41_
		end
	end)
	for v43_ = 1, #groundAdjustedNode.adjustNodes do
		self:initGroundAdjustedAdjustNode(groundAdjustedNode, groundAdjustedNode.adjustNodes[v43_])
	end
	if #groundAdjustedNode.raycastNodes > 0 and #groundAdjustedNode.adjustNodes > 0 then
		groundAdjustedNode.isActive = false
		return true
	else
		Logging.xmlWarning(self.xmlFile, "No raycastNodes or adjust nodes defined for groundAdjustedNode \'%s\'!", key)
		return false
	end
end

-- Local values: node, spec, otherRaycastNode
function GroundAdjustedNodes:loadGroundAdjustedRaycastNodeFromXML(xmlFile, key, groundAdjustedNode, raycastNode)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	local v49_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v49_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'node\' for groundAdjustedNodes raycast \'%s\'!", key)
		return nil
	end
	raycastNode.node = v49_
	raycastNode.maxDistance = xmlFile:getValue(key .. "#distance", 4)
	raycastNode.lastRaycastDistance = raycastNode.maxDistance
	raycastNode.yOffset = xmlFile:getValue(key .. "#yOffset", groundAdjustedNode.yOffset or 0)
	local v50_ = self.spec_groundAdjustedNodes
	if v50_.raycastNodesByNode[v49_] == nil then
		function raycastNode.groundAdjustRaycastCallback(_, p51_, _, _, _, p52_)
			-- upvalues: (copy) raycastNode
			if getHasTrigger(p51_) then
				return true
			end
			if p51_ ~= 0 then
				raycastNode.lastRaycastDistance = p52_
			end
			return false
		end
		raycastNode.parent = groundAdjustedNode
		return raycastNode
	end
	local v53_ = v50_.raycastNodesByNode[v49_]
	local v54_ = raycastNode.yOffset - v53_.yOffset
	if math.abs(v54_) < 0.01 then
		local v55_ = raycastNode.maxDistance - v53_.maxDistance
		if math.abs(v55_) < 0.01 then
			return v50_.raycastNodesByNode[v49_]
		end
	end
	Logging.xmlWarning(xmlFile, "Found multiple groundAdjustedNode raycasts with different settings for \'%s\'!", getName(v49_))
	return nil
end

-- Local values: node, x, y, z
function GroundAdjustedNodes:loadGroundAdjustedAdjustNodeFromXML(xmlFile, key, groundAdjustedNode, adjustNode, required)
	local v61_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v61_ == nil then
		if required == true then
			Logging.xmlWarning(xmlFile, "Missing \'node\' for groundAdjustedNode \'%s\'!", key)
		end
		return false
	end
	local v62_, v63_, v64_ = getTranslation(v61_)
	adjustNode.node = v61_
	adjustNode.x = v62_
	adjustNode.y = v63_
	adjustNode.z = v64_
	adjustNode.minY = xmlFile:getValue(key .. "#minY", v63_ - 1)
	adjustNode.maxY = xmlFile:getValue(key .. "#maxY", adjustNode.minY + 1)
	adjustNode.moveSpeed = xmlFile:getValue(key .. "#moveSpeed", 1) / 1000
	adjustNode.moveSpeedStateChange = xmlFile:getValue(key .. "#moveSpeedStateChange", adjustNode.moveSpeed * 1000) / 1000
	adjustNode.resetIfNotActive = xmlFile:getValue(key .. "#resetIfNotActive", true)
	adjustNode.updateThreshold = xmlFile:getValue(key .. "#updateThreshold", 0.002)
	adjustNode.inActiveY = xmlFile:getValue(key .. "#inActiveY", v63_) + xmlFile:getValue(key .. "#inActiveOffsetY", 0)
	adjustNode.averageInActivePosY = xmlFile:getValue(key .. "#averageInActivePosY", false)
	adjustNode.targetY = adjustNode.inActiveY
	adjustNode.curY = adjustNode.inActiveY
	adjustNode.lastY = adjustNode.inActiveY
	adjustNode.lastOffsetDistance = math.random() * 10000
	return true
end

-- Local values: x1, _, z1, x2, _, z2, x3, _, z3, dirX, dirZ, length
function GroundAdjustedNodes:initGroundAdjustedAdjustNode(groundAdjustedNode, adjustNode)
	if #groundAdjustedNode.raycastNodes == 2 then
		local v67_, _, v68_ = localToLocal(adjustNode.node, getParent(groundAdjustedNode.raycastNodes[1].node), 0, 0, 0)
		local v69_, _, v70_ = localToLocal(groundAdjustedNode.raycastNodes[1].node, getParent(groundAdjustedNode.raycastNodes[1].node), 0, 0, 0)
		local v71_, _, v72_ = localToLocal(groundAdjustedNode.raycastNodes[2].node, getParent(groundAdjustedNode.raycastNodes[1].node), 0, 0, 0)
		local v73_ = v71_ - v69_
		local v74_ = v72_ - v70_
		local v75_ = MathUtil.vector2Length(v71_ - v69_, v72_ - v70_)
		local v76_, v77_ = MathUtil.vector2Normalize(v73_, v74_)
		adjustNode.alpha = MathUtil.getProjectOnLineParameter(v67_, v68_, v69_, v70_, v76_, v77_) / v75_
	end
end

-- Local values: spec, node, raycastNode, x, y, z, dx, dy, dz, mask, terrainHeight
function GroundAdjustedNodes:updateGroundAdjustedRaycasts(dt)
	local v79_ = self.spec_groundAdjustedNodes
	for _, v80_ in pairs(v79_.raycastNodesByNode) do
		if v80_.parent.isActive and v80_.parent.activeScale > 0 then
			local v81_, v82_, v83_ = localToWorld(v80_.node, 0, v80_.yOffset, 0)
			v80_.lastIsOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, v81_, 0, v83_) ~= 0
			if v82_ < 0 then
				v80_.lastIsOnField = false
			end
			if v80_.lastIsOnField and not v79_.adjustToWater then
				local v84_ = getTerrainHeightAtWorldPos(g_terrainNode, v81_, 0, v83_)
				if v84_ - 10 < v82_ then
					local v85_ = v82_ - v84_
					local v86_ = v80_.maxDistance
					v80_.lastRaycastDistance = math.min(v85_, v86_)
				end
			else
				local v87_, v88_, v89_ = localDirectionToWorld(v80_.node, 0, -1, 0)
				local v90_ = GroundAdjustedNodes.COLLISION_MASK
				if v79_.adjustToWater then
					v90_ = GroundAdjustedNodes.COLLISION_MASK_WATER
				end
				raycastAll(v81_, v82_, v83_, v87_, v88_, v89_, v80_.maxDistance, "groundAdjustRaycastCallback", v80_, v90_)
			end
		end
	end
end
local v_u_91_ = {
	["randomFrequency"] = 3.5,
	["persistence"] = 0,
	["numOctaves"] = 6,
	["randomSeed"] = 99,
	["maxOffset"] = 0.015
}
local v_u_92_ = math.sin

-- Upvalues: sin, PERLIN_NOISE
-- Local values: spec, wasActive, groundAdjustedNodes, inActiveY, numNodes, _, _groundAdjustedNode, i, _adjustNode, _, _groundAdjustedNode, i, _adjustNode, i, adjustNode, _, y, _, raycastNode, height, _, targetY, _, t, noise, stateChangeActive, moveSpeed
function GroundAdjustedNodes:updateGroundAdjustedNode(groundAdjustedNode, dt)
	-- upvalues: (copy) v_u_92_, (copy) v_u_91_
	local v96_ = self.spec_groundAdjustedNodes
	local v97_ = groundAdjustedNode.isActive
	groundAdjustedNode.isActive = self:getIsGroundAdjustedNodeActive(groundAdjustedNode)
	if groundAdjustedNode.isActive then
		local v98_ = groundAdjustedNode.activationTimer - dt
		groundAdjustedNode.activationTimer = math.max(v98_, 0)
	else
		if groundAdjustedNode.averageInActivePosY and v97_ then
			local v99_ = v96_.groundAdjustedNodes
			local v100_ = 0
			local v101_ = 0
			for _, v102_ in pairs(v99_) do
				for v103_ = 1, #v102_.adjustNodes do
					local v104_ = v102_.adjustNodes[v103_]
					if v104_.averageInActivePosY then
						v100_ = v100_ + v104_.curY
						v101_ = v101_ + 1
					end
				end
			end
			if v101_ > 0 then
				groundAdjustedNode.inActiveY = v100_ / v101_
				for _, v105_ in pairs(v99_) do
					for v106_ = 1, #v105_.adjustNodes do
						local v107_ = v105_.adjustNodes[v106_]
						if v107_.averageInActivePosY then
							v107_.inActiveY = v100_ / v101_
						end
					end
				end
			end
		end
		groundAdjustedNode.activationTimer = groundAdjustedNode.activationTime
	end
	for v108_ = 1, #groundAdjustedNode.adjustNodes do
		local v109_ = groundAdjustedNode.adjustNodes[v108_]
		if groundAdjustedNode.isActive and groundAdjustedNode.activeScale > 0 then
			if not v97_ then
				local _, v110_, _ = getTranslation(v109_.node)
				v109_.curY = v110_
			end
			local v111_ = groundAdjustedNode.raycastNodes[1]
			local v112_
			if #groundAdjustedNode.raycastNodes == 2 then
				v112_ = groundAdjustedNode.raycastNodes[1].lastRaycastDistance * (1 - v109_.alpha) + groundAdjustedNode.raycastNodes[2].lastRaycastDistance * v109_.alpha
			else
				v112_ = groundAdjustedNode.raycastNodes[1].lastRaycastDistance
			end
			local _, v113_, _ = localToLocal(v111_.node, getParent(v109_.node), 0, v111_.yOffset - v112_, 0)
			if self.currentUpdateDistance < v96_.maxUpdateDistanceWobble and v111_.lastIsOnField then
				v109_.lastOffsetDistance = v109_.lastOffsetDistance + self.lastMovedDistance * self.movingDirection * 0.1
				local v114_ = v109_.lastOffsetDistance
				v113_ = v113_ + (v_u_92_(v114_ * 15.7079) * 0.4 + v_u_92_(v114_ * 41.46902) * 0.4 + v_u_92_(v114_ * 62.83185) * 0.3) * v_u_91_.maxOffset
			end
			local v115_ = v109_.minY
			local v116_ = v109_.maxY
			v109_.targetY = math.clamp(v113_, v115_, v116_)
		elseif v109_.resetIfNotActive then
			v109_.targetY = v109_.inActiveY
		end
		v109_.targetY = v109_.targetY * groundAdjustedNode.activeScale + v109_.inActiveY * (1 - groundAdjustedNode.activeScale)
		if v109_.targetY ~= v109_.curY then
			local v117_ = (not groundAdjustedNode.isActive or groundAdjustedNode.activationTimer > 0) and v109_.moveSpeedStateChange or v109_.moveSpeed
			if v109_.targetY > v109_.curY then
				local v118_ = v109_.curY + v117_ * dt
				local v119_ = v109_.targetY
				v109_.curY = math.min(v118_, v119_)
			else
				local v120_ = v109_.curY - v117_ * dt
				local v121_ = v109_.targetY
				v109_.curY = math.max(v120_, v121_)
			end
			local v122_ = v109_.lastY - v109_.curY
			if math.abs(v122_) > v109_.updateThreshold then
				setTranslation(v109_.node, v109_.x, v109_.curY, v109_.z)
				v109_.lastY = v109_.curY
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v109_.node)
				end
			end
		end
	end
end

-- Local values: spec
function GroundAdjustedNodes:getIsGroundAdjustedNodeActive(groundAdjustedNode, ignoreAttachState)
	return not self.spec_groundAdjustedNodes.onlyActiveWhileAttached or (self.getAttacherVehicle == nil and true or (self:getAttacherVehicle() ~= nil and true or ignoreAttachState))
end

function GroundAdjustedNodes:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("groundAdjustScale", "startGroundAdjustScale", "endGroundAdjustScale", false, AnimationValueFloat, function(p126_, p127_, p128_)
		p126_.node = p127_:getValue(p128_ .. "#node", nil, p126_.part.components, p126_.part.i3dMappings)
		if p126_.node == nil then
			return false
		end
		p126_:setWarningInformation("node: " .. getName(p126_.node))
		p126_:addCompareParameters("node")
		return true
	end, function(p129_)
		-- upvalues: (copy) self
		if p129_.groundAdjustedNode == nil then
			local v130_ = self.spec_groundAdjustedNodes
			for _, v131_ in pairs(v130_.groundAdjustedNodes) do
				for _, v132_ in pairs(v131_.adjustNodes) do
					if v132_.node == p129_.node then
						p129_.groundAdjustedNode = v131_
						break
					end
				end
				if p129_.groundAdjustedNode ~= nil then
					break
				end
			end
			if p129_.groundAdjustedNode == nil then
				Logging.xmlWarning(p129_.xmlFile, "Could not find groundAdjustedNode for node \'%s\'!", getName(p129_.node))
				return 0
			end
		end
		return p129_.groundAdjustedNode.activeScale
	end, function(p133_, p134_)
		if p133_.groundAdjustedNode ~= nil then
			p133_.groundAdjustedNode.activeScale = p134_
		end
	end)
end
