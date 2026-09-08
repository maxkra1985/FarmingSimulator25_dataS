GroundReference = {}
GroundReference.GROUND_REFERENCE_XML_KEY = "vehicle.groundReferenceNodes.groundReferenceNode(?)"

function GroundReference.prerequisitesPresent(vehicleType)
	return true
end
function GroundReference.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("GroundReference")
	local v2_ = GroundReference.GROUND_REFERENCE_XML_KEY
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#node", "Ground reference node")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#threshold", "Threshold", 0)
	v1_:register(XMLValueType.BOOL, v2_ .. "#onlyActiveWhenLowered", "Node is only active when tool is lowered", true)
	v1_:register(XMLValueType.FLOAT, v2_ .. "#chargeValue", "Charge value to calculate power consumption", 1)
	v1_:register(XMLValueType.FLOAT, v2_ .. "#forceFactor", "Ground force factor")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#maxActivationDepth", "Max. activation depth", 10)
	v1_:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#groundReferenceNodeIndex", "Ground reference node index")
	v1_:setXMLSpecializationType()
end

function GroundReference.registerEvents(vehicleType) end

function GroundReference.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundReferenceNode", GroundReference.loadGroundReferenceNode)
	SpecializationUtil.registerFunction(vehicleType, "updateGroundReferenceNode", GroundReference.updateGroundReferenceNode)
	SpecializationUtil.registerFunction(vehicleType, "getGroundReferenceNodeFromIndex", GroundReference.getGroundReferenceNodeFromIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsGroundReferenceNodeActive", GroundReference.getIsGroundReferenceNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsGroundReferenceNodeThreshold", GroundReference.getIsGroundReferenceNodeThreshold)
	SpecializationUtil.registerFunction(vehicleType, "getGroundReferenceNodeForwardSpeed", GroundReference.getGroundReferenceNodeForwardSpeed)
end

function GroundReference.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerMultiplier", GroundReference.getPowerMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", GroundReference.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", GroundReference.getIsSpeedRotatingPartActive)
end

function GroundReference.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", GroundReference)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", GroundReference)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", GroundReference)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", GroundReference)
end

-- Local values: spec, i, baseName, entry, totalCharge, _, refNode, _, refNode, forceFactorSum, _, refNode, _, refNode
function GroundReference:onLoad(savegame)
	local v7_ = self.spec_groundReference
	v7_.hasForceFactors = false
	v7_.groundReferenceNodes = {}
	local v8_ = 0
	while true do
		local v9_ = string.format("vehicle.groundReferenceNodes.groundReferenceNode(%d)", v8_)
		if not self.xmlFile:hasProperty(v9_) then
			break
		end
		local v10_ = {}
		if self:loadGroundReferenceNode(self.xmlFile, v9_, v10_) then
			local v11_ = v7_.groundReferenceNodes
			table.insert(v11_, v10_)
		end
		v8_ = v8_ + 1
	end
	local v12_ = 0
	for _, v13_ in pairs(v7_.groundReferenceNodes) do
		v12_ = v12_ + v13_.chargeValue
	end
	if v12_ > 0 then
		for _, v14_ in pairs(v7_.groundReferenceNodes) do
			v14_.chargeValue = v14_.chargeValue / v12_
		end
	end
	local v15_ = 0
	for _, v16_ in pairs(v7_.groundReferenceNodes) do
		v15_ = v15_ + v16_.forceFactor
	end
	if v15_ > 0 then
		for _, v17_ in pairs(v7_.groundReferenceNodes) do
			v17_.forceFactor = v17_.forceFactor / v15_
		end
	end
	if #v7_.groundReferenceNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", GroundReference)
	end
end

-- Local values: spec, _, groundReferenceNode
function GroundReference:onReadUpdateStream(streamId, timestamp, connection)
	local v21_ = self.spec_groundReference
	if connection:getIsServer() then
		for _, v22_ in ipairs(v21_.groundReferenceNodes) do
			v22_.isActive = streamReadBool(streamId)
		end
	end
end

-- Local values: spec, _, groundReferenceNode
function GroundReference:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v26_ = self.spec_groundReference
	if not connection:getIsServer() then
		for _, v27_ in ipairs(v26_.groundReferenceNodes) do
			streamWriteBool(streamId, v27_.isActive)
		end
	end
end

-- Local values: spec, _, groundReferenceNode
function GroundReference:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v29_ = self.spec_groundReference
	for _, v30_ in ipairs(v29_.groundReferenceNodes) do
		self:updateGroundReferenceNode(v30_)
	end
end

-- Local values: spec, node
function GroundReference:loadGroundReferenceNode(xmlFile, baseName, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#index", baseName .. "#node")
	local v35_ = self.spec_groundReference
	local v36_ = xmlFile:getValue(baseName .. "#node", nil, self.components, self.i3dMappings)
	if v36_ == nil then
		return false
	end
	entry.node = v36_
	entry.threshold = xmlFile:getValue(baseName .. "#threshold", 0)
	entry.onlyActiveWhenLowered = xmlFile:getValue(baseName .. "#onlyActiveWhenLowered", true)
	entry.chargeValue = xmlFile:getValue(baseName .. "#chargeValue", 1)
	entry.forceFactor = xmlFile:getValue(baseName .. "#forceFactor")
	if entry.forceFactor ~= nil then
		v35_.hasForceFactors = true
	end
	entry.forceFactor = entry.forceFactor or 1
	entry.maxActivationDepth = xmlFile:getValue(baseName .. "#maxActivationDepth", 10)
	entry.isActive = false
	return true
end

-- Local values: activeLowered, threshold, x, y, z, terrainHeight, terrainDiff, terrainActiv, densityHeight, _, densityDiff, densityActiv
function GroundReference:updateGroundReferenceNode(groundReferenceNode)
	if self.isServer then
		local v39_ = (not groundReferenceNode.onlyActiveWhenLowered or (self.getIsLowered == nil or self:getIsLowered(false))) and true or false
		local v40_ = self:getIsGroundReferenceNodeThreshold(groundReferenceNode)
		local v41_, v42_, v43_ = getWorldTranslation(groundReferenceNode.node)
		local v44_ = getTerrainHeightAtWorldPos(g_terrainNode, v41_, v42_, v43_) + v40_ - v42_
		local v45_
		if v44_ > 0 then
			v45_ = v44_ < groundReferenceNode.maxActivationDepth
		else
			v45_ = false
		end
		local v46_, _ = DensityMapHeightUtil.getHeightAtWorldPos(v41_, v42_, v43_)
		local v47_ = v46_ + v40_ - v42_
		local v48_
		if v47_ > 0 then
			v48_ = v47_ < groundReferenceNode.maxActivationDepth
		else
			v48_ = false
		end
		if v39_ then
			v39_ = v45_ or v48_
		end
		groundReferenceNode.isActive = v39_
	end
end

-- Local values: spec
function GroundReference:getGroundReferenceNodeFromIndex(refNodeIndex)
	return self.spec_groundReference.groundReferenceNodes[refNodeIndex]
end

function GroundReference:getIsGroundReferenceNodeActive(groundReferenceNode)
	return groundReferenceNode.isActive
end

function GroundReference:getIsGroundReferenceNodeThreshold(groundReferenceNode)
	return groundReferenceNode.threshold
end

-- Local values: spec, groundReferenceNode
function GroundReference:getGroundReferenceNodeForwardSpeed(groundReferenceNodeIndex)
	if groundReferenceNodeIndex ~= nil then
		local v55_ = self.spec_groundReference.groundReferenceNodes[tonumber(groundReferenceNodeIndex)]
		if v55_ ~= nil then
			return v55_.isActive and (self.movingDirection > 0 and self:getLastSpeed()) or 0
		end
	end
	return 0
end

-- Local values: powerMultiplier, spec, factor, _, refNode, _, refNode
function GroundReference:getPowerMultiplier(superFunc)
	local v58_ = superFunc(self)
	local v59_ = self.spec_groundReference
	if #v59_.groundReferenceNodes > 0 then
		local v60_ = 0
		if v59_.hasForceFactors then
			for _, v61_ in ipairs(v59_.groundReferenceNodes) do
				if v61_.isActive then
					v60_ = v60_ + v61_.forceFactor
				end
			end
		else
			for _, v62_ in ipairs(v59_.groundReferenceNodes) do
				if v62_.isActive then
					v60_ = v62_.chargeValue
				end
			end
		end
		v58_ = v58_ * v60_
	end
	return v58_
end

function GroundReference:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#refNodeIndex", key .. "#groundReferenceNodeIndex")
	speedRotatingPart.groundReferenceNodeIndex = xmlFile:getValue(key .. "#groundReferenceNodeIndex")
	if speedRotatingPart.groundReferenceNodeIndex ~= nil and speedRotatingPart.groundReferenceNodeIndex == 0 then
		Logging.xmlWarning(self.xmlFile, "Unknown ground reference node index \'%d\' in \'%s\'! Indices start with 1!", speedRotatingPart.groundReferenceNodeIndex, key)
	end
	return true
end

-- Local values: spec
function GroundReference:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.groundReferenceNodeIndex ~= nil then
		local v71_ = self.spec_groundReference
		if v71_.groundReferenceNodes[speedRotatingPart.groundReferenceNodeIndex] == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown ground reference node index \'%d\' for speed rotating part \'%s\'! Indices start with 1!", speedRotatingPart.groundReferenceNodeIndex, getName(speedRotatingPart.repr or speedRotatingPart.shaderNode))
			speedRotatingPart.groundReferenceNodeIndex = nil
		elseif not v71_.groundReferenceNodes[speedRotatingPart.groundReferenceNodeIndex].isActive then
			return false
		end
	end
	return superFunc(self, speedRotatingPart)
end
