GroundAdjustedNodes = {}
GroundAdjustedNodes.GROUND_ADJUSTED_NODE_XML_KEY = "vehicle.groundAdjustedNodes.groundAdjustedNode(?)"
GroundAdjustedNodes.COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
GroundAdjustedNodes.COLLISION_MASK_WATER = GroundAdjustedNodes.COLLISION_MASK + CollisionFlag.WATER
function GroundAdjustedNodes.prerequisitesPresent(specializations)
	return true
end
function GroundAdjustedNodes.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("groundAdjustedNode", g_i18n:getText("shop_configuration"), "groundAdjustedNodes", VehicleConfigurationItem)
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("GroundAdjustedNodes")
	schema:register(XMLValueType.FLOAT, "vehicle.groundAdjustedNodes#maxUpdateDistance", "If the player is more than this distance away the nodes will no longer be updated", 100)
	schema:register(XMLValueType.FLOAT, "vehicle.groundAdjustedNodes#maxUpdateDistanceWobble", "If the player is more than this distance away the wobble effect which is applied on the field will not be shown anymore", 50)
	schema:register(XMLValueType.BOOL, "vehicle.groundAdjustedNodes#adjustToWater", "If 'true', the adjust node will be placed on top of any water plane", false)
	schema:register(XMLValueType.UINT, "vehicle.groundAdjustedNodes#collisionMask", "Collision mask used for the ground detection raycasts", GroundAdjustedNodes.COLLISION_MASK)
	schema:register(XMLValueType.BOOL, "vehicle.groundAdjustedNodes#onlyActiveWhileAttached", "Defines if the tool needs to be attached to have the ground adjusted nodes active", true)
	GroundAdjustedNodes.registerNodeXMLPaths(schema, "vehicle.groundAdjustedNodes.groundAdjustedNode(?)")
	GroundAdjustedNodes.registerNodeXMLPaths(schema, "vehicle.groundAdjustedNodes.groundAdjustedNodeConfigurations.groundAdjustedNodeConfiguration(?).groundAdjustedNode(?)")
	schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function(cSchema, cKey)
		cSchema:register(XMLValueType.FLOAT, cKey .. "#startGroundAdjustScale", "Start scale of ground adjusted node (blending between detected ground and inactive position)")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#endGroundAdjustScale", "Start scale of ground adjusted node (blending between detected ground and inactive position)")
	end)
	schema:setXMLSpecializationType()
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
	schema:register(XMLValueType.FLOAT, basePath .. "#inActiveY", "Adjust node will go to this state while it's not active", "Position in i3d file")
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
function GroundAdjustedNodes:onLoad(savegame)
	local spec = self.spec_groundAdjustedNodes
	local configurationId = self.configurations.groundAdjustedNode or 1
	local configKey = string.format("vehicle.groundAdjustedNodes.groundAdjustedNodeConfigurations.groundAdjustedNodeConfiguration(%d)", configurationId - 1)
	spec.raycastNodesByNode = {}
	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.groundAdjustedNodes#maxUpdateDistance", 100)
	spec.maxUpdateDistanceWobble = self.xmlFile:getValue("vehicle.groundAdjustedNodes#maxUpdateDistanceWobble", 50)
	spec.adjustToWater = self.xmlFile:getValue("vehicle.groundAdjustedNodes#adjustToWater", false)
	spec.onlyActiveWhileAttached = self.xmlFile:getValue("vehicle.groundAdjustedNodes#onlyActiveWhileAttached", true)
	spec.collisionMask = self.xmlFile:getValue("vehicle.groundAdjustedNodes#collisionMask")
	spec.groundAdjustedNodes = {}
	self.xmlFile:iterate("vehicle.groundAdjustedNodes.groundAdjustedNode", function(index, key)
		local groundAdjustedNode = {}
		if self:loadGroundAdjustedNodeFromXML(self.xmlFile, key, groundAdjustedNode) then
			table.insert(spec.groundAdjustedNodes, groundAdjustedNode)
		end
	end)
	self.xmlFile:iterate(configKey .. ".groundAdjustedNode", function(index, key)
		local groundAdjustedNode = {}
		if self:loadGroundAdjustedNodeFromXML(self.xmlFile, key, groundAdjustedNode) then
			table.insert(spec.groundAdjustedNodes, groundAdjustedNode)
		end
	end)
	if #spec.groundAdjustedNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", GroundAdjustedNodes)
		SpecializationUtil.removeEventListener(self, "onUpdate", GroundAdjustedNodes)
		SpecializationUtil.removeEventListener(self, "onRegisterAnimationValueTypes", GroundAdjustedNodes)
	end
end
function GroundAdjustedNodes:onLoadFinished(savegame)
	local spec = self.spec_groundAdjustedNodes
	for _, groundAdjustedNode in pairs(spec.groundAdjustedNodes) do
		groundAdjustedNode.isActive = self:getIsGroundAdjustedNodeActive(groundAdjustedNode, true)
		if groundAdjustedNode.isActive then
			for i = 1, #groundAdjustedNode.adjustNodes do
				local adjustNode = groundAdjustedNode.adjustNodes[i]
				if 0.01 < math.abs(adjustNode.y - adjustNode.curY) then
					setTranslation(adjustNode.node, adjustNode.x, adjustNode.curY, adjustNode.z)
					if self.setMovingToolDirty == nil then
						continue
					end
					self:setMovingToolDirty(adjustNode.node)
				end
			end
		end
	end
end
function GroundAdjustedNodes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_groundAdjustedNodes
	if self.currentUpdateDistance < spec.maxUpdateDistance then
		self:updateGroundAdjustedRaycasts(dt)
		for _, groundAdjustedNode in pairs(spec.groundAdjustedNodes) do
			self:updateGroundAdjustedNode(groundAdjustedNode, dt)
		end
	end
end
function GroundAdjustedNodes:loadGroundAdjustedNodeFromXML(xmlFile, key, groundAdjustedNode)
	local spec = self.spec_groundAdjustedNodes
	groundAdjustedNode.yOffset = xmlFile:getValue(key .. "#yOffset")
	groundAdjustedNode.activationTime = xmlFile:getValue(key .. "#activationTime", 0) * 1000
	groundAdjustedNode.activationTimer = groundAdjustedNode.activationTime
	groundAdjustedNode.activeScale = 1
	groundAdjustedNode.adjustNodes = {}
	local baseAdjustNode = {}
	if self:loadGroundAdjustedAdjustNodeFromXML(xmlFile, key, groundAdjustedNode, baseAdjustNode, false) then
		table.insert(groundAdjustedNode.adjustNodes, baseAdjustNode)
	end
	xmlFile:iterate(key .. ".adjustNode", function(index, adjustKey)
		local adjustNode = {}
		if self:loadGroundAdjustedAdjustNodeFromXML(xmlFile, adjustKey, groundAdjustedNode, adjustNode, true) then
			table.insert(groundAdjustedNode.adjustNodes, adjustNode)
		end
	end)
	groundAdjustedNode.raycastNodes = {}
	xmlFile:iterate(key .. ".raycastNode", function(index, raycastKey)
		local raycastNode = self:loadGroundAdjustedRaycastNodeFromXML(xmlFile, raycastKey, groundAdjustedNode, {})
		if raycastNode ~= nil then
			if 2 < #groundAdjustedNode.raycastNodes then
				Logging.xmlWarning(self.xmlFile, "Max. two raycast nodes are allowed per groundAdjustedNode! (%s)", key)
				return
			end
			table.insert(groundAdjustedNode.raycastNodes, raycastNode)
			spec.raycastNodesByNode[raycastNode.node] = raycastNode
		end
	end)
	for i = 1, #groundAdjustedNode.adjustNodes do
		self:initGroundAdjustedAdjustNode(groundAdjustedNode, groundAdjustedNode.adjustNodes[i])
	end
	if 0 < #groundAdjustedNode.raycastNodes and 0 < #groundAdjustedNode.adjustNodes then
		groundAdjustedNode.isActive = false
		return true
	end
	Logging.xmlWarning(self.xmlFile, "No raycastNodes or adjust nodes defined for groundAdjustedNode '%s'!", key)
	return false
end
function GroundAdjustedNodes:loadGroundAdjustedRaycastNodeFromXML(xmlFile, key, groundAdjustedNode, raycastNode)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for groundAdjustedNodes raycast '%s'!", key)
		return nil
	end
	raycastNode.node = node
	raycastNode.maxDistance = xmlFile:getValue(key .. "#distance", 4)
	raycastNode.lastRaycastDistance = raycastNode.maxDistance
	raycastNode.yOffset = xmlFile:getValue(key .. "#yOffset", groundAdjustedNode.yOffset or 0)
	local spec = self.spec_groundAdjustedNodes
	if spec.raycastNodesByNode[node] ~= nil then
		local otherRaycastNode = spec.raycastNodesByNode[node]
		if math.abs(raycastNode.yOffset - otherRaycastNode.yOffset) < 0.01 and math.abs(raycastNode.maxDistance - otherRaycastNode.maxDistance) < 0.01 then
			return spec.raycastNodesByNode[node]
		end
		Logging.xmlWarning(xmlFile, "Found multiple groundAdjustedNode raycasts with different settings for '%s'!", getName(node))
		return nil
	else
		function raycastNode.groundAdjustRaycastCallback(_, transformId, x, y, z, distance)
			if getHasTrigger(transformId) then
				return true
			else
				if transformId ~= 0 then
					raycastNode.lastRaycastDistance = distance
				end
				return false
			end
		end
		raycastNode.parent = groundAdjustedNode
		return raycastNode
	end
end
function GroundAdjustedNodes:loadGroundAdjustedAdjustNodeFromXML(xmlFile, key, groundAdjustedNode, adjustNode, required)
	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if node == nil then
		if required == true then
			Logging.xmlWarning(xmlFile, "Missing 'node' for groundAdjustedNode '%s'!", key)
		end
		return false
	else
		local x, y, z = getTranslation(node)
		adjustNode.node = node
		adjustNode.x = x
		adjustNode.y = y
		adjustNode.z = z
		adjustNode.minY = xmlFile:getValue(key .. "#minY", y - 1)
		adjustNode.maxY = xmlFile:getValue(key .. "#maxY", adjustNode.minY + 1)
		adjustNode.moveSpeed = xmlFile:getValue(key .. "#moveSpeed", 1) / 1000
		adjustNode.moveSpeedStateChange = xmlFile:getValue(key .. "#moveSpeedStateChange", adjustNode.moveSpeed * 1000) / 1000
		adjustNode.resetIfNotActive = xmlFile:getValue(key .. "#resetIfNotActive", true)
		adjustNode.updateThreshold = xmlFile:getValue(key .. "#updateThreshold", 0.002)
		adjustNode.inActiveY = xmlFile:getValue(key .. "#inActiveY", y) + xmlFile:getValue(key .. "#inActiveOffsetY", 0)
		adjustNode.averageInActivePosY = xmlFile:getValue(key .. "#averageInActivePosY", false)
		adjustNode.targetY = adjustNode.inActiveY
		adjustNode.curY = adjustNode.inActiveY
		adjustNode.lastY = adjustNode.inActiveY
		adjustNode.lastOffsetDistance = math.random() * 10000
		return true
	end
end
function GroundAdjustedNodes:initGroundAdjustedAdjustNode(groundAdjustedNode, adjustNode)
	if #groundAdjustedNode.raycastNodes == 2 then
		local x1, _, z1 = localToLocal(adjustNode.node, getParent(groundAdjustedNode.raycastNodes[1].node), 0, 0, 0)
		local x2, _, z2 = localToLocal(groundAdjustedNode.raycastNodes[1].node, getParent(groundAdjustedNode.raycastNodes[1].node), 0, 0, 0)
		local x3, _, z3 = localToLocal(groundAdjustedNode.raycastNodes[2].node, getParent(groundAdjustedNode.raycastNodes[1].node), 0, 0, 0)
		local dirX = x3 - x2
		local dirZ = z3 - z2
		local length = MathUtil.vector2Length(x3 - x2, z3 - z2)
		dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
		adjustNode.alpha = MathUtil.getProjectOnLineParameter(x1, z1, x2, z2, dirX, dirZ) / length
	end
end
function GroundAdjustedNodes:updateGroundAdjustedRaycasts(dt)
	local spec = self.spec_groundAdjustedNodes
	for node, raycastNode in pairs(spec.raycastNodesByNode) do
		if raycastNode.parent.isActive and 0 < raycastNode.parent.activeScale then
			local x, y, z = localToWorld(raycastNode.node, 0, raycastNode.yOffset, 0)
			raycastNode.lastIsOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
			if y < 0 then
				raycastNode.lastIsOnField = false
			end
			if not raycastNode.lastIsOnField or spec.adjustToWater then
				local dx, dy, dz = localDirectionToWorld(raycastNode.node, 0, -1, 0)
				local mask = spec.collisionMask
				if mask == nil then
					mask = GroundAdjustedNodes.COLLISION_MASK
					if spec.adjustToWater then
						mask = GroundAdjustedNodes.COLLISION_MASK_WATER
					end
				elseif spec.adjustToWater then
					mask = bit32.bor(mask, CollisionFlag.WATER)
				end
				raycastAll(x, y, z, dx, dy, dz, raycastNode.maxDistance, "groundAdjustRaycastCallback", raycastNode, mask)
			else
				local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
				if terrainHeight - 10 < y then
					raycastNode.lastRaycastDistance = math.min(y - terrainHeight, raycastNode.maxDistance)
				end
			end
		end
	end
end
local PERLIN_NOISE = { randomFrequency = 3.5, persistence = 0, numOctaves = 6, randomSeed = 99, maxOffset = 0.015 }
local sin = math.sin
local getRandomOffset = function(t)
	return sin(t * 15.7079) * 0.4 + sin(t * 41.46902) * 0.4 + sin(t * 62.83185) * 0.3
end
function GroundAdjustedNodes:updateGroundAdjustedNode(groundAdjustedNode, dt)
	local spec = self.spec_groundAdjustedNodes
	local wasActive = groundAdjustedNode.isActive
	groundAdjustedNode.isActive = self:getIsGroundAdjustedNodeActive(groundAdjustedNode)
	if groundAdjustedNode.isActive then
		groundAdjustedNode.activationTimer = math.max(groundAdjustedNode.activationTimer - dt, 0)
	else
		if groundAdjustedNode.averageInActivePosY and wasActive then
			local groundAdjustedNodes = spec.groundAdjustedNodes
			local inActiveY = 0
			local numNodes = 0
			for _, _groundAdjustedNode in pairs(groundAdjustedNodes) do
				for i = 1, #_groundAdjustedNode.adjustNodes do
					local _adjustNode = _groundAdjustedNode.adjustNodes[i]
					if _adjustNode.averageInActivePosY then
						inActiveY = inActiveY + _adjustNode.curY
						numNodes = numNodes + 1
					end
				end
			end
			if 0 < numNodes then
				groundAdjustedNode.inActiveY = inActiveY / numNodes
				for _, _groundAdjustedNode in pairs(groundAdjustedNodes) do
					for i = 1, #_groundAdjustedNode.adjustNodes do
						local _adjustNode = _groundAdjustedNode.adjustNodes[i]
						if _adjustNode.averageInActivePosY then
							_adjustNode.inActiveY = inActiveY / numNodes
						end
					end
				end
			end
		end
		groundAdjustedNode.activationTimer = groundAdjustedNode.activationTime
	end
	for i = 1, #groundAdjustedNode.adjustNodes do
		local adjustNode = groundAdjustedNode.adjustNodes[i]
		if groundAdjustedNode.isActive then
			if 0 < groundAdjustedNode.activeScale then
				if not wasActive then
					local _, y, _ = getTranslation(adjustNode.node)
					adjustNode.curY = y
				end
				local raycastNode = groundAdjustedNode.raycastNodes[1]
				local height = nil
				height = #groundAdjustedNode.raycastNodes == 2 and groundAdjustedNode.raycastNodes[1].lastRaycastDistance * (1 - adjustNode.alpha) + groundAdjustedNode.raycastNodes[2].lastRaycastDistance * adjustNode.alpha or groundAdjustedNode.raycastNodes[1].lastRaycastDistance
				local _, targetY, _ = localToLocal(raycastNode.node, getParent(adjustNode.node), 0, raycastNode.yOffset - height, 0)
				if self.currentUpdateDistance < spec.maxUpdateDistanceWobble and raycastNode.lastIsOnField then
					adjustNode.lastOffsetDistance = adjustNode.lastOffsetDistance + self.lastMovedDistance * self.movingDirection * 0.1
					local t = adjustNode.lastOffsetDistance
					local noise = sin(t * 15.7079) * 0.4 + sin(t * 41.46902) * 0.4 + sin(t * 62.83185) * 0.3
					targetY = targetY + noise * PERLIN_NOISE.maxOffset
				end
				adjustNode.targetY = math.clamp(targetY, adjustNode.minY, adjustNode.maxY)
			elseif adjustNode.resetIfNotActive then
				adjustNode.targetY = adjustNode.inActiveY
			end
		end
		adjustNode.targetY = adjustNode.targetY * groundAdjustedNode.activeScale + adjustNode.inActiveY * (1 - groundAdjustedNode.activeScale)
		if adjustNode.targetY == adjustNode.curY then
			continue
		end
		local moveSpeed = (not groundAdjustedNode.isActive or 0 < groundAdjustedNode.activationTimer) and adjustNode.moveSpeedStateChange or adjustNode.moveSpeed
		if adjustNode.curY < adjustNode.targetY then
			adjustNode.curY = math.min(adjustNode.curY + moveSpeed * dt, adjustNode.targetY)
		else
			adjustNode.curY = math.max(adjustNode.curY - moveSpeed * dt, adjustNode.targetY)
		end
		if adjustNode.updateThreshold < math.abs(adjustNode.lastY - adjustNode.curY) then
			setTranslation(adjustNode.node, adjustNode.x, adjustNode.curY, adjustNode.z)
			adjustNode.lastY = adjustNode.curY
			if self.setMovingToolDirty == nil then
				continue
			end
			self:setMovingToolDirty(adjustNode.node)
		end
	end
end
function GroundAdjustedNodes:getIsGroundAdjustedNodeActive(groundAdjustedNode, ignoreAttachState)
	local spec = self.spec_groundAdjustedNodes
	local _v8 = not spec.onlyActiveWhileAttached
	if not _v8 then
		_v8 = true
		if self.getAttacherVehicle ~= nil then
			_v8 = true
			if self:getAttacherVehicle() == nil then
				_v8 = ignoreAttachState
			end
		end
	end
	return _v8
end
function GroundAdjustedNodes:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("groundAdjustScale", "startGroundAdjustScale", "endGroundAdjustScale", false, AnimationValueFloat, function(value, xmlFile, xmlKey)
		value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)
		if value.node ~= nil then
			value:setWarningInformation("node: " .. getName(value.node))
			value:addCompareParameters("node")
			return true
		else
			return false
		end
	end, function(value)
		if value.groundAdjustedNode == nil then
			local spec = self.spec_groundAdjustedNodes
			for _, groundAdjustedNode in pairs(spec.groundAdjustedNodes) do
				for _, adjustNode in pairs(groundAdjustedNode.adjustNodes) do
					if adjustNode.node == value.node then
						value.groundAdjustedNode = groundAdjustedNode
						break
					end
				end
				if value.groundAdjustedNode == nil then
					continue
				end
				if value.groundAdjustedNode == nil then
					Logging.xmlWarning(value.xmlFile, "Could not find groundAdjustedNode for node '%s'!", getName(value.node))
					return 0
				else
					return value.groundAdjustedNode.activeScale
				end
			end
		end
	end, function(value, activeScale)
		if value.groundAdjustedNode ~= nil then
			value.groundAdjustedNode.activeScale = activeScale
		end
	end)
end
