-- Local values: updateNodeData
RandomlyMovingParts = {}
RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE = 50
RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY = "vehicle.randomlyMovingParts.randomlyMovingPart(?)"
RandomlyMovingParts.PRESETS = {}
RandomlyMovingParts.PRESETS.SOWINGMACHINE = {}
RandomlyMovingParts.PRESETS.SOWINGMACHINE.noiseFrequency = { 5, 23, 65 }
RandomlyMovingParts.PRESETS.SOWINGMACHINE.noiseAmount = { 0.4, 0.4, 0.2 }
RandomlyMovingParts.PRESETS.SOWINGMACHINE.hasBumps = false
RandomlyMovingParts.PRESETS.CULTIVATOR = {}
RandomlyMovingParts.PRESETS.CULTIVATOR.noiseFrequency = { 5, 23, 65 }
RandomlyMovingParts.PRESETS.CULTIVATOR.noiseAmount = { 0, 0.05, 0.05 }
RandomlyMovingParts.PRESETS.CULTIVATOR.hasBumps = true
RandomlyMovingParts.PRESETS.CULTIVATOR.bumpFrequency = 20
RandomlyMovingParts.PRESETS.CULTIVATOR.bumpDuration = 0.25

function RandomlyMovingParts.prerequisitesPresent(specializations)
	return true
end
function RandomlyMovingParts.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("RandomlyMovingParts")
	v1_:register(XMLValueType.FLOAT, "vehicle.randomlyMovingParts#maxUpdateDistance", RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	v1_:register(XMLValueType.NODE_INDEX, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#node", "Node")
	v1_:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#refNodeIndex", "Ground reference node index")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#speedScale", "Speed scale", 1)
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#speedVariance", "Random variance in the speed scale", 0.1)
	v1_:register(XMLValueType.TIME, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#fadeTime", "Fade in and fade out time", 1)
	local v2_ = {}
	for v3_, _ in pairs(RandomlyMovingParts.PRESETS) do
		table.insert(v2_, v3_)
	end
	v1_:register(XMLValueType.STRING, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#preset", "Name of the preset to use for random value behaviour (%s)", "SOWINGMACHINE", nil, v2_)
	v1_:register(XMLValueType.VECTOR_3, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#noiseFrequency", "The frequency of the different offsets that is applied", "used from preset")
	v1_:register(XMLValueType.VECTOR_3, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#noiseAmount", "The max. offset for each frequency", "used from preset")
	v1_:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#hasBumps", "The max. offset for each frequency", "used from preset")
	v1_:register(XMLValueType.TIME, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#bumpFrequency", "Max. time between bumps", "used from preset")
	v1_:register(XMLValueType.TIME, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#bumpDuration", "Duration of the bump", "used from preset")
	v1_:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotAxis", "Rotation axis")
	v1_:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotMax", "Max. delta rotation value in position direction")
	v1_:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotMin", "Max. delta rotation value in negative direction", "Inverted rotMax value")
	v1_:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotStart", "Initial rotation value on the defined axis", "Current value from i3d")
	v1_:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transAxis", "Translation axis")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transMax", "Max. delta translation value in position direction")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transMin", "Max. delta translation value in negative direction", "Inverted rotMax value")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transStart", "Initial translation value on the defined axis", "Current value from i3d")
	v1_:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#isSpeedDependent", "Speed will adjust based on vehicle moving speed", true)
	v1_:register(XMLValueType.NODE_INDEX, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#node", "Node that receives the same value")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#scale", "Scale that is applied to the random value (use -1 to invert the value)", 1)
	v1_:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotAxis", "Rotation axis")
	v1_:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotMax", "Max. delta rotation value in position direction")
	v1_:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotMin", "Max. delta rotation value in negative direction", "Inverted rotMax value")
	v1_:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotStart", "Initial rotation value on the defined axis", "Current value from i3d")
	v1_:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transAxis", "Translation axis")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transMax", "Max. delta translation value in position direction")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transMin", "Max. delta translation value in negative direction", "Inverted rotMax value")
	v1_:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transStart", "Initial translation value on the defined axis", "Current value from i3d")
	v1_:setXMLSpecializationType()
end

function RandomlyMovingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRandomlyMovingPartFromXML", RandomlyMovingParts.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateRandomlyMovingPart", RandomlyMovingParts.updateRandomlyMovingPart)
	SpecializationUtil.registerFunction(vehicleType, "getIsRandomlyMovingPartActive", RandomlyMovingParts.getIsRandomlyMovingPartActive)
end

function RandomlyMovingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RandomlyMovingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RandomlyMovingParts)
end

-- Local values: spec, _, key, randomlyMovingPart
function RandomlyMovingParts:onLoad(savegame)
	local v7_ = self.spec_randomlyMovingParts
	v7_.maxUpdateDistance = self.xmlFile:getValue("vehicle.randomlyMovingParts#maxUpdateDistance", RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	v7_.nodes = {}
	for _, v8_ in self.xmlFile:iterator("vehicle.randomlyMovingParts.randomlyMovingPart") do
		local v9_ = {}
		if self:loadRandomlyMovingPartFromXML(v9_, self.xmlFile, v8_) then
			local v10_ = v7_.nodes
			table.insert(v10_, v9_)
		end
	end
	if not self.isClient or #v7_.nodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", RandomlyMovingParts)
	end
end

-- Local values: spec, _, part
function RandomlyMovingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v13_ = self.spec_randomlyMovingParts
	if self.currentUpdateDistance < v13_.maxUpdateDistance and self:getLastSpeed() > 0.1 then
		for _, v14_ in pairs(v13_.nodes) do
			self:updateRandomlyMovingPart(v14_, dt)
		end
	end
end

-- Local values: node, refNodeIndex, groundReferenceNode, preset, _, nodeKey, node, nodeData
function RandomlyMovingParts:loadRandomlyMovingPartFromXML(part, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotMean")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotVariance")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotTimeMean")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotTimeVariance")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#pauseMean")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#pauseVariance")
	local v19_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v19_ == nil then
		Logging.xmlWarning(xmlFile, "Unknown node for randomlyMovingPart in \'%s\'", key)
		return false
	end
	part.node = v19_
	if self.getGroundReferenceNodeFromIndex ~= nil then
		local v20_ = xmlFile:getValue(key .. "#refNodeIndex")
		if v20_ ~= nil then
			if v20_ == 0 then
				Logging.xmlWarning(xmlFile, "Unknown ground reference node in \'%s\'! Indices start with \'0\'", key .. "#refNodeIndex")
			else
				local v21_ = self:getGroundReferenceNodeFromIndex(v20_)
				if v21_ ~= nil then
					part.groundReferenceNode = v21_
				end
			end
		end
	end
	part.isSpeedDependent = xmlFile:getValue(key .. "#isSpeedDependent", true)
	part.speedScale = xmlFile:getValue(key .. "#speedScale", 1)
	part.speedVariance = xmlFile:getValue(key .. "#speedVariance", 0.1)
	part.speedScale = part.speedScale + (math.random() * part.speedVariance - part.speedVariance * 0.5)
	part.fadeTime = 1 / xmlFile:getValue(key .. "#fadeTime", 1)
	local v22_ = xmlFile:getValue(key .. "#preset", "SOWINGMACHINE")
	local v23_ = RandomlyMovingParts.PRESETS[string.upper(v22_)] or RandomlyMovingParts.PRESETS.SOWINGMACHINE
	part.noiseFrequency = xmlFile:getValue(key .. "#noiseFrequency", v23_.noiseFrequency, true)
	part.noiseAmount = xmlFile:getValue(key .. "#noiseAmount", v23_.noiseAmount, true)
	part.hasBumps = xmlFile:getValue(key .. "#hasBumps", v23_.hasBumps)
	if part.hasBumps then
		part.bumpFrequency = xmlFile:getValue(key .. "#bumpFrequency", v23_.bumpFrequency or 10)
		part.bumpNextTime = part.bumpFrequency * math.random()
		part.bumpTimer = 0
		part.bumpDuration = xmlFile:getValue(key .. "#bumpDuration", v23_.bumpDuration or 0.25)
	end
	part.rotAxis = xmlFile:getValue(key .. "#rotAxis", nil)
	if part.rotAxis ~= nil then
		part.rotMax = xmlFile:getValue(key .. "#rotMax", 0)
		part.rotMin = xmlFile:getValue(key .. "#rotMin") or -part.rotMax
		part.rotation = { getRotation(part.node) }
		part.initialRotation = { getRotation(part.node) }
		part.rotStart = xmlFile:getValue(key .. "#rotStart")
		if part.rotStart ~= nil then
			part.rotation[part.rotAxis] = part.rotStart
			part.initialRotation[part.rotAxis] = part.rotStart
			setRotation(part.node, part.initialRotation[1], part.initialRotation[2], part.initialRotation[3])
		end
	end
	part.transAxis = xmlFile:getValue(key .. "#transAxis", nil)
	if part.transAxis ~= nil then
		part.transMax = xmlFile:getValue(key .. "#transMax", 0)
		part.transMin = xmlFile:getValue(key .. "#transMin") or -part.transMax
		part.translation = { getTranslation(part.node) }
		part.initialTranslation = { getTranslation(part.node) }
		part.transStart = xmlFile:getValue(key .. "#transStart")
		if part.transStart ~= nil then
			part.translation[part.transAxis] = part.transStart
			part.initialTranslation[part.transAxis] = part.transStart
			setTranslation(part.node, part.initialTranslation[1], part.initialTranslation[2], part.initialTranslation[3])
		end
	end
	if part.rotAxis == nil and part.transAxis == nil then
		Logging.xmlWarning(xmlFile, "No rotation or translation axis for randomlyMovingPart in \'%s\'", key)
		return false
	end
	part.nodes = {}
	for _, v24_ in xmlFile:iterator(key .. ".node") do
		local v25_ = xmlFile:getValue(v24_ .. "#node", nil, self.components, self.i3dMappings)
		if v25_ ~= nil then
			local v26_ = {
				["node"] = v25_,
				["deltaScale"] = xmlFile:getValue(v24_ .. "#scale", 1),
				["rotAxis"] = xmlFile:getValue(key .. "#rotAxis", part.rotAxis)
			}
			if v26_.rotAxis ~= nil then
				v26_.rotMax = xmlFile:getValue(key .. "#rotMax", part.rotMax or 0)
				v26_.rotMin = xmlFile:getValue(key .. "#rotMin") or -v26_.rotMax
				v26_.rotation = { getRotation(v26_.node) }
				v26_.initialRotation = { getRotation(v26_.node) }
				v26_.rotStart = xmlFile:getValue(key .. "#rotStart")
				if v26_.rotStart ~= nil then
					v26_.rotation[v26_.rotAxis] = v26_.rotStart
					v26_.initialRotation[v26_.rotAxis] = v26_.rotStart
					setRotation(v26_.node, v26_.initialRotation[1], v26_.initialRotation[2], v26_.initialRotation[3])
				end
			end
			v26_.transAxis = xmlFile:getValue(key .. "#transAxis", part.transAxis)
			if v26_.transAxis ~= nil then
				v26_.transMax = xmlFile:getValue(key .. "#transMax", part.transMax or 0)
				v26_.transMin = xmlFile:getValue(key .. "#transMin") or -v26_.transMax
				v26_.translation = { getTranslation(v26_.node) }
				v26_.initialTranslation = { getTranslation(v26_.node) }
				v26_.transStart = xmlFile:getValue(key .. "#transStart")
				if v26_.transStart ~= nil then
					v26_.translation[v26_.transAxis] = v26_.transStart
					v26_.initialTranslation[v26_.transAxis] = v26_.transStart
					setTranslation(v26_.node, v26_.initialTranslation[1], v26_.initialTranslation[2], v26_.initialTranslation[3])
				end
			end
			if part.rotAxis ~= nil or part.transAxis ~= nil then
				local v27_ = part.nodes
				table.insert(v27_, v26_)
			end
		end
	end
	part.isActive = true
	part.time = math.random()
	part.alpha = 0
	return true
end
local function v_u_39_(p28_, p29_, p30_, p31_)
	if p29_.deltaScale ~= nil then
		p30_ = p30_ * p29_.deltaScale
	end
	if p29_.rotAxis ~= nil then
		local v32_ = p29_.rotMin
		local v33_ = math.min(p30_, 0)
		local v34_ = v32_ * math.abs(v33_)
		local v35_ = p29_.rotMax
		local v36_ = math.max(p30_, 0)
		local v37_ = v34_ + v35_ * math.abs(v36_)
		p29_.rotation[p29_.rotAxis] = p29_.initialRotation[p29_.rotAxis] + v37_ * p31_
		setRotation(p29_.node, p29_.rotation[1], p29_.rotation[2], p29_.rotation[3])
		if p28_.setMovingToolDirty ~= nil then
			p28_:setMovingToolDirty(p29_.node)
		end
	end
	if p29_.transAxis ~= nil then
		local v38_ = p29_.transMin + p30_ * (p29_.transMax - p29_.transMin)
		p29_.translation[p29_.transAxis] = p29_.initialTranslation[p29_.transAxis] + v38_ * p31_
		setTranslation(p29_.node, p29_.translation[1], p29_.translation[2], p29_.translation[3])
		if p28_.setMovingToolDirty ~= nil then
			p28_:setMovingToolDirty(p29_.node)
		end
	end
end

-- Upvalues: updateNodeData
-- Local values: speed, delta, bumpAlpha, i, nodeData
function RandomlyMovingParts:updateRandomlyMovingPart(part, dt)
	-- upvalues: (copy) v_u_39_
	local v43_
	if part.isSpeedDependent then
		v43_ = self.lastMovedDistance * self.movingDirection * 0.2
	else
		v43_ = dt * 0.00033
	end
	part.isActive = self:getIsRandomlyMovingPartActive(part)
	if part.isActive then
		if part.alpha < 1 then
			local v44_ = part.alpha + dt * part.fadeTime
			part.alpha = math.min(v44_, 1)
		end
		if part.hasBumps then
			if not part.isSpeedDependent or self:getLastSpeed() > 1 then
				part.bumpNextTime = part.bumpNextTime - dt
				if part.bumpNextTime <= 0 then
					part.bumpTimer = part.bumpDuration
					part.bumpNextTime = part.bumpFrequency * math.random()
				end
			end
			if part.bumpTimer > 0 then
				part.bumpTimer = part.bumpTimer - dt
			end
		end
	elseif part.alpha > 0 then
		local v45_ = part.alpha - dt * part.fadeTime
		part.alpha = math.max(v45_, 0)
	end
	if part.alpha > 0 then
		part.time = part.time + v43_ * part.speedScale
		local v46_ = part.time * part.noiseFrequency[1]
		local v47_ = math.sin(v46_) * part.noiseAmount[1]
		local v48_ = part.time * part.noiseFrequency[2]
		local v49_ = v47_ + math.sin(v48_) * part.noiseAmount[2]
		local v50_ = part.time * part.noiseFrequency[3]
		local v51_ = v49_ + math.sin(v50_) * part.noiseAmount[3]
		if part.hasBumps and part.bumpTimer > 0 then
			local v52_ = (1 - part.bumpTimer / part.bumpDuration) * 3.141592653589793
			local v53_ = v51_ + math.sin(v52_)
			v51_ = math.min(v53_, 1)
		end
		v_u_39_(self, part, v51_, part.alpha)
		for _, v54_ in ipairs(part.nodes) do
			v_u_39_(self, v54_, v51_, part.alpha)
		end
	end
end

-- Local values: retValue
function RandomlyMovingParts:getIsRandomlyMovingPartActive(part)
	return part.groundReferenceNode == nil and true or self:getIsGroundReferenceNodeActive(part.groundReferenceNode)
end
