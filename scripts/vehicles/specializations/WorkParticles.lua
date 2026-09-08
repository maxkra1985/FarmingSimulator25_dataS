WorkParticles = {}
WorkParticles.PARTICLE_MAPPING_XML_PATH = "vehicle.workParticles.particle(?).node(?)"

function WorkParticles.prerequisitesPresent(self)
	return true
end
function WorkParticles.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("WorkParticles")
	v1_:register(XMLValueType.STRING, "vehicle.workParticles.particleAnimation(?)#file", "External effect i3d file")
	v1_:register(XMLValueType.FLOAT, "vehicle.workParticles.particleAnimation(?)#speedThreshold", "Speed threshold", 0)
	WorkParticles.registerGroundAnimationMappingXMLPaths(v1_, "vehicle.workParticles.particleAnimation(?).node(?)")
	v1_:register(XMLValueType.STRING, "vehicle.workParticles.particle(?)#file", "External effect i3d file")
	WorkParticles.registerGroundParticleMappingXMLPaths(v1_, "vehicle.workParticles.particle(?).node(?)")
	v1_:register(XMLValueType.BOOL, "vehicle.workParticles#requireField", "The effects require the vehicle to be on a field to work", true)
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.workParticles.effect(?)")
	v1_:register(XMLValueType.FLOAT, "vehicle.workParticles.effect(?)#speedThreshold", "Speed threshold", 0.5)
	v1_:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#activeDirection", "Active Direction (effect will be turned off wen in opposite direction)", 1)
	v1_:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#workAreaIndex", "Work area index")
	v1_:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#groundReferenceNodeIndex", "Index of ground reference node")
	v1_:register(XMLValueType.BOOL, "vehicle.workParticles.effect(?)#needsSetIsTurnedOn", "Needs set is turned on", false)
	v1_:register(XMLValueType.NODE_INDEX, GroundReference.GROUND_REFERENCE_XML_KEY .. "#depthNode", "Depth node")
	v1_:setXMLSpecializationType()
end

function WorkParticles.registerGroundAnimationMappingXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Link node in vehicle")
	schema:register(XMLValueType.INT, key .. "#refNodeIndex", "Ground reference node index")
	schema:register(XMLValueType.STRING, key .. "#animMeshNode", "Animation mesh node in external file")
	schema:register(XMLValueType.STRING, key .. "#materialType", "Material type name (If external file is not given)")
	schema:register(XMLValueType.INT, key .. "#materialId", "Material index (If external file is not given)", 1)
	schema:register(XMLValueType.FLOAT, key .. "#maxDepth", "Max. depth", -0.1)
end

function WorkParticles.registerGroundParticleMappingXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Link node in vehicle")
	schema:register(XMLValueType.INT, key .. "#refNodeIndex", "Ground reference node index")
	schema:register(XMLValueType.STRING, key .. "#particleNode", "Particle node in external file")
	schema:register(XMLValueType.STRING, key .. "#particleType", "Particle type name (If external file is not given)")
	schema:register(XMLValueType.STRING, key .. "#fillType", "Fill type for particles (If external file is not given)", "UNKNOWN")
	schema:register(XMLValueType.FLOAT, key .. "#speedThreshold", "Speed threshold", 0.5)
	schema:register(XMLValueType.INT, key .. "#movingDirection", "Moving direction")
	ParticleUtil.registerParticleCopyXMLPaths(schema, key)
end

function WorkParticles.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDoGroundManipulation", WorkParticles.getDoGroundManipulation)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimations", WorkParticles.loadGroundAnimations)
	SpecializationUtil.registerFunction(vehicleType, "onGroundAnimationI3DLoaded", WorkParticles.onGroundAnimationI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimationMapping", WorkParticles.loadGroundAnimationMapping)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundParticles", WorkParticles.loadGroundParticles)
	SpecializationUtil.registerFunction(vehicleType, "groundParticleI3DLoaded", WorkParticles.groundParticleI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundParticleMapping", WorkParticles.loadGroundParticleMapping)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundEffects", WorkParticles.loadGroundEffects)
	SpecializationUtil.registerFunction(vehicleType, "getFillTypeFromWorkAreaIndex", WorkParticles.getFillTypeFromWorkAreaIndex)
end

function WorkParticles.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundReferenceNode", WorkParticles.loadGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateGroundReferenceNode", WorkParticles.updateGroundReferenceNode)
end

function WorkParticles.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WorkParticles)
end

-- Local values: spec, i, key, animation, key, particle, key, effect
function WorkParticles:onLoad(savegame)
	local v10_ = self.spec_workParticles
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.groundParticleAnimations.groundParticleAnimation", "vehicle.workParticles.particleAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.groundParticleAnimations.groundParticle", "vehicle.workParticles.particle")
	if self.isClient then
		v10_.requireField = self.xmlFile:getValue("vehicle.workParticles#requireField", true)
		v10_.particleAnimations = {}
		local v11_ = 0
		while true do
			local v12_ = string.format("vehicle.workParticles.particleAnimation(%d)", v11_)
			if not self.xmlFile:hasProperty(v12_) then
				break
			end
			local v13_ = {}
			if self:loadGroundAnimations(self.xmlFile, v12_, v13_, v11_) then
				local v14_ = v10_.particleAnimations
				table.insert(v14_, v13_)
			end
			v11_ = v11_ + 1
		end
		v10_.particles = {}
		local v15_ = 0
		while true do
			local v16_ = string.format("vehicle.workParticles.particle(%d)", v15_)
			if not self.xmlFile:hasProperty(v16_) then
				break
			end
			local v17_ = {}
			if self:loadGroundParticles(self.xmlFile, v16_, v17_, v15_) then
				local v18_ = v10_.particles
				table.insert(v18_, v17_)
			end
			v15_ = v15_ + 1
		end
		v10_.effects = {}
		local v19_ = 0
		while true do
			local v20_ = string.format("vehicle.workParticles.effect(%d)", v19_)
			if not self.xmlFile:hasProperty(v20_) then
				break
			end
			local v21_ = {}
			if self:loadGroundEffects(self.xmlFile, v20_, v21_, v19_) then
				local v22_ = v10_.effects
				table.insert(v22_, v21_)
			end
			v19_ = v19_ + 1
		end
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onDelete", WorkParticles)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", WorkParticles)
		SpecializationUtil.removeEventListener(self, "onDeactivate", WorkParticles)
	end
end

-- Local values: spec, _, animation, _, ps, _, mapping, _, effect
function WorkParticles:onDelete()
	local v24_ = self.spec_workParticles
	if v24_.particleAnimations ~= nil then
		for _, v25_ in ipairs(v24_.particleAnimations) do
			if v25_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v25_.sharedLoadRequestId)
				v25_.sharedLoadRequestId = nil
			end
		end
	end
	if v24_.particles ~= nil then
		for _, v26_ in pairs(v24_.particles) do
			for _, v27_ in ipairs(v26_.mappings) do
				ParticleUtil.deleteParticleSystem(v27_.particleSystem)
			end
			if v26_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v26_.sharedLoadRequestId)
				v26_.sharedLoadRequestId = nil
			end
		end
	end
	if v24_.effects ~= nil then
		for _, v28_ in pairs(v24_.effects) do
			g_effectManager:deleteEffects(v28_.effect)
		end
	end
end

-- Local values: spec, isOnField, _, animation, _, mapping, refNode, depth, lastSpeed, enabled, _, ps, _, mapping, nodeEnabled, _, effect, state, turnedOn, attacherVehicle, workArea, fillType
function WorkParticles:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v30_ = self.spec_workParticles
	local v31_ = self.isOnField or not v30_.requireField
	for _, v32_ in ipairs(v30_.particleAnimations) do
		for _, v33_ in ipairs(v32_.mappings) do
			local v34_ = v33_.groundRefNode
			if v34_ ~= nil and v34_.depthNode ~= nil then
				local v35_ = v34_.depth / v33_.maxWorkDepth
				local v36_ = not v31_ and 0 or math.clamp(v35_, 0, 1)
				local v37_ = v33_.lastDepth + v34_.movingDirection * (v34_.movedDistance / 0.5)
				local v38_ = math.min(v36_, v37_)
				local v39_ = math.clamp(v38_, 0, 1)
				v33_.lastDepth = v39_
				v33_.speed = v33_.speed - v34_.movedDistance * v34_.movingDirection
				setVisibility(v33_.animNode, v39_ > 0)
				setShaderParameter(v33_.animNode, "VertxoffsetVertexdeformMotionUVscale", -6, v39_, v33_.speed, 1.5, false)
			end
		end
	end
	local v40_ = self:getLastSpeed(true)
	local v41_ = self:getDoGroundManipulation() and v31_
	for _, v42_ in pairs(v30_.particles) do
		for _, v43_ in ipairs(v42_.mappings) do
			local v44_
			if v41_ then
				v44_ = v43_.groundRefNode.isActive
				if v44_ then
					v44_ = v43_.speedThreshold < v40_
				end
			else
				v44_ = v41_
			end
			if v43_.movingDirection ~= nil then
				if v44_ then
					v44_ = v43_.movingDirection == self.movingDirection
				end
			end
			ParticleUtil.setEmittingState(v43_.particleSystem, v44_)
		end
	end
	for _, v45_ in pairs(v30_.effects) do
		local v46_
		if v41_ then
			v46_ = v45_.speedThreshold < v40_
		else
			v46_ = v41_
		end
		if v45_.needsSetIsTurnedOn and self.getIsTurnedOn ~= nil then
			local v47_ = self:getIsTurnedOn()
			if self.getAttacherVehicle ~= nil then
				local v48_ = self:getAttacherVehicle()
				if v48_ ~= nil and v48_.getIsTurnedOn ~= nil then
					v47_ = v47_ or v48_:getIsTurnedOn()
				end
			end
			v46_ = v46_ and v47_
		end
		local v49_ = self:getWorkAreaByIndex(v45_.workAreaIndex)
		if v49_ ~= nil and v49_.requiresGroundContact then
			if v46_ then
				if v49_.groundReferenceNode == nil then
					v46_ = false
				else
					v46_ = v49_.groundReferenceNode.isActive
				end
			end
		end
		if v45_.groundReferenceNodeIndex ~= nil and v45_.groundReferenceNode == nil then
			v45_.groundReferenceNode = self:getGroundReferenceNodeFromIndex(v45_.groundReferenceNodeIndex)
			if v45_.groundReferenceNode == nil then
				Logging.warning("Unknown ground reference node \'%s\' for WorkParticle effect!", v45_.groundReferenceNodeIndex)
				v45_.groundReferenceNodeIndex = nil
			end
		end
		if v45_.groundReferenceNode ~= nil then
			if v46_ then
				v46_ = v45_.groundReferenceNode.isActive
			end
		end
		if v46_ then
			v46_ = self.movingDirection ~= -v45_.activeDirection and true or self:getLastSpeed() < 0.5
		end
		if v46_ then
			local v50_ = self:getFillTypeFromWorkAreaIndex(v45_.workAreaIndex)
			g_effectManager:setEffectTypeInfo(v45_.effect, v50_)
			g_effectManager:startEffects(v45_.effect)
		else
			g_effectManager:stopEffects(v45_.effect)
		end
	end
end

function WorkParticles.getDoGroundManipulation(self)
	return true
end

-- Local values: j, nodeBaseName, mapping, filenameStr, arguments
function WorkParticles:loadGroundAnimations(xmlFile, key, animation, index)
	animation.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0)
	animation.mappings = {}
	local v55_ = 0
	while true do
		local v56_ = string.format(key .. ".node(%d)", v55_)
		if not self.xmlFile:hasProperty(v56_) then
			break
		end
		local v57_ = {}
		if self:loadGroundAnimationMapping(xmlFile, v56_, v57_, v55_) then
			local v58_ = animation.mappings
			table.insert(v58_, v57_)
		end
		v55_ = v55_ + 1
	end
	local v59_ = self.xmlFile:getValue(key .. "#file")
	if v59_ ~= nil then
		local v60_ = Utils.getFilename(v59_, self.baseDirectory)
		animation.sharedLoadRequestId = self:loadSubSharedI3DFile(v60_, false, false, self.onGroundAnimationI3DLoaded, self, {
			["filename"] = v60_,
			["animation"] = animation
		})
	end
	return true
end

-- Local values: animation, _, mapping
function WorkParticles:onGroundAnimationI3DLoaded(i3dNode, args)
	if i3dNode ~= 0 then
		local v63_ = args.animation
		for _, v64_ in ipairs(v63_.mappings) do
			link(v64_.node, v64_.animNode)
			setVisibility(v64_.animNode, false)
		end
		v63_.filename = args.filename
		delete(i3dNode)
	end
end

-- Local values: node, groundRefIndex, animNode, animMeshNode, materialType, materialId, material
function WorkParticles:loadGroundAnimationMapping(xmlFile, key, mapping, index)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#animMeshIndex", key .. "#animMeshNode")
	local v69_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v69_ == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid node \'%s\' for \'%s\'", getXMLString(xmlFile.handle, key .. "#node"), key)
		return false
	end
	local v70_ = xmlFile:getValue(key .. "#refNodeIndex")
	if v70_ == nil or self:getGroundReferenceNodeFromIndex(v70_) == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid refNodeIndex \'%s\' for \'%s\'", xmlFile:getValue(key .. "#refNodeIndex"), key)
		return false
	end
	local v71_ = xmlFile:getValue(key .. "#animMeshNode")
	local v72_
	if v71_ == nil then
		local v73_ = xmlFile:getValue(key .. "#materialType")
		local v74_ = xmlFile:getValue(key .. "#materialId", 1)
		if v73_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing materialType in \'%s\'", key)
			return false
		end
		local v75_ = g_materialManager:getBaseMaterialByName(v73_)
		if v75_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid materialType \'%s\' or materialId \'%s\' in \'%s\'", v73_, v74_, key)
		else
			setMaterial(v69_, v75_, 0)
		end
		setVisibility(v69_, false)
		v72_ = v69_
	else
		v72_ = I3DUtil.indexToObject(v69_, v71_, self.i3dMappings)
		if v72_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid animMesh node \'%s\' \'%s\'", xmlFile:getValue(key .. "#animMeshNode"), key)
			return false
		end
	end
	mapping.node = v69_
	mapping.animNode = v72_
	mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(v70_)
	mapping.lastDepth = 0
	mapping.speed = 0
	mapping.maxWorkDepth = xmlFile:getValue(key .. "#maxDepth", -0.1)
	return true
end

-- Local values: filename, arguments, j, nodeBaseName, mapping
function WorkParticles:loadGroundParticles(xmlFile, key, particle, index)
	particle.mappings = {}
	local v80_ = xmlFile:getValue(key .. "#file")
	if v80_ == nil then
		local v81_ = 0
		while true do
			local v82_ = string.format(key .. ".node(%d)", v81_)
			if not xmlFile:hasProperty(v82_) then
				break
			end
			local v83_ = {}
			if self:loadGroundParticleMapping(xmlFile, v82_, v83_, v81_) then
				local v84_ = particle.mappings
				table.insert(v84_, v83_)
			end
			v81_ = v81_ + 1
		end
	else
		local v85_ = Utils.getFilename(v80_, self.baseDirectory)
		particle.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v85_, false, false, self.groundParticleI3DLoaded, self, {
			["xmlFile"] = xmlFile,
			["key"] = key,
			["particle"] = particle,
			["filename"] = v85_
		})
	end
	return true
end

-- Local values: xmlFile, key, particle, filename, j, nodeBaseName, mapping, _, mapping
function WorkParticles:groundParticleI3DLoaded(i3dNode, failedReason, args)
	local v89_ = args.xmlFile
	local v90_ = args.key
	local v91_ = args.particle
	local v92_ = args.filename
	local v93_ = 0
	while true do
		local v94_ = string.format(v90_ .. ".node(%d)", v93_)
		if not v89_:hasProperty(v94_) then
			break
		end
		local v95_ = {}
		if self:loadGroundParticleMapping(v89_, v94_, v95_, v93_, i3dNode) then
			local v96_ = v91_.mappings
			table.insert(v96_, v95_)
		end
		v93_ = v93_ + 1
	end
	if i3dNode ~= 0 then
		for _, v97_ in ipairs(v91_.mappings) do
			link(v97_.node, v97_.particleNode)
			ParticleUtil.loadParticleSystemFromNode(v97_.particleNode, v97_.particleSystem, false, true)
		end
		v91_.filename = v92_
		delete(i3dNode)
	end
end

-- Local values: node, groundRefIndex, particleNode, particleNodeIndex, particleType, fillTypeStr, fillType, particleSystem, material
function WorkParticles:loadGroundParticleMapping(xmlFile, key, mapping, index, i3dNode)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#particleIndex", key .. "#particleNode")
	mapping.particleSystem = {}
	local v103_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v103_ == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid node \'%s\' for \'%s\'", xmlFile:getValue(key .. "#node"), key)
		return false
	end
	local v104_ = xmlFile:getValue(key .. "#refNodeIndex")
	if v104_ == nil or self:getGroundReferenceNodeFromIndex(v104_) == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid refNodeIndex \'%s\' for \'%s\'", xmlFile:getValue(key .. "#refNodeIndex"), key)
		return false
	end
	local v105_ = xmlFile:getValue(key .. "#particleNode")
	local v106_
	if v105_ == nil then
		local v107_ = xmlFile:getValue(key .. "#particleType")
		if v107_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing particleType in \'%s\'", key)
			return false
		end
		local v108_ = xmlFile:getValue(key .. "#fillType")
		local v109_ = Utils.getNoNil(g_fillTypeManager:getFillTypeIndexByName(v108_), FillType.UNKNOWN)
		local v110_ = g_particleSystemManager:getParticleSystem(v107_)
		if v110_ == nil then
			return false
		end
		if v109_ ~= FillType.UNKNOWN then
			local v111_ = g_materialManager:getParticleMaterial(v109_, v107_, 1)
			if v111_ ~= nil then
				ParticleUtil.setMaterial(v110_, v111_)
			end
		end
		mapping.particleSystem = ParticleUtil.copyParticleSystem(xmlFile, key, v110_, v103_)
		v106_ = v103_
	else
		v106_ = I3DUtil.indexToObject(i3dNode, v105_, self.i3dMappings)
		if v106_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid particle node \'%s\' \'%s\'", xmlFile:getValue(key .. "#particleNode"), key)
			return false
		end
	end
	mapping.node = v103_
	mapping.particleNode = v106_
	mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(v104_)
	mapping.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0.5)
	mapping.movingDirection = xmlFile:getValue(key .. "#movingDirection")
	return true
end

function WorkParticles:loadGroundEffects(xmlFile, key, effect, index)
	effect.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0.5)
	effect.activeDirection = xmlFile:getValue(key .. "#activeDirection", 1)
	effect.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")
	effect.groundReferenceNodeIndex = xmlFile:getValue(key .. "#groundReferenceNodeIndex")
	effect.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
	effect.effect = g_effectManager:loadEffect(xmlFile, key, self.components, self, self.i3dMappings)
	return true
end

-- Local values: fillType, workArea
function WorkParticles:getFillTypeFromWorkAreaIndex(workAreaIndex)
	local v118_ = FillType.UNKNOWN
	local v119_ = self:getWorkAreaByIndex(workAreaIndex)
	if v119_ ~= nil then
		if v119_.fillType ~= nil then
			return v119_.fillType
		end
		if v119_.fruitType ~= nil then
			v118_ = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(v119_.fruitType)
		end
	end
	return v118_
end

-- Local values: returnValue
function WorkParticles:loadGroundReferenceNode(superFunc, xmlFile, key, groundReferenceNode)
	local v125_ = superFunc(self, xmlFile, key, groundReferenceNode)
	if v125_ then
		groundReferenceNode.depthNode = xmlFile:getValue(key .. "#depthNode", nil, self.components, self.i3dMappings)
		groundReferenceNode.movedDistance = 0
		groundReferenceNode.depth = 0
		groundReferenceNode.movingDirection = 0
	end
	return v125_
end

-- Local values: newX, newY, newZ, dx, dy, dz, terrainHeightDepthNode
function WorkParticles:updateGroundReferenceNode(superFunc, groundReferenceNode, x, y, z, terrainHeight, densityHeight)
	superFunc(self, groundReferenceNode, x, y, z, terrainHeight, densityHeight)
	if self.isClient and groundReferenceNode.depthNode ~= nil then
		local v134_, v135_, v136_ = getWorldTranslation(groundReferenceNode.depthNode)
		if groundReferenceNode.lastPosition == nil then
			groundReferenceNode.lastPosition = { v134_, v135_, v136_ }
		end
		local v137_, v138_, v139_ = worldDirectionToLocal(groundReferenceNode.depthNode, v134_ - groundReferenceNode.lastPosition[1], v135_ - groundReferenceNode.lastPosition[2], v136_ - groundReferenceNode.lastPosition[3])
		groundReferenceNode.movingDirection = 0
		if v139_ > 0.0001 then
			groundReferenceNode.movingDirection = 1
		elseif v139_ < -0.0001 then
			groundReferenceNode.movingDirection = -1
		end
		groundReferenceNode.movedDistance = MathUtil.vector3Length(v137_, v138_, v139_)
		local v140_ = groundReferenceNode.lastPosition
		local v141_ = groundReferenceNode.lastPosition
		local v142_ = groundReferenceNode.lastPosition
		v140_[1] = v134_
		v141_[2] = v135_
		v142_[3] = v136_
		groundReferenceNode.depth = v135_ - getTerrainHeightAtWorldPos(g_terrainNode, v134_, v135_, v136_)
	end
end

-- Local values: spec, _, ps, _, mapping, _, animation, _, mapping
function WorkParticles:onDeactivate()
	local v144_ = self.spec_workParticles
	for _, v145_ in pairs(v144_.particles) do
		for _, v146_ in ipairs(v145_.mappings) do
			ParticleUtil.setEmittingState(v146_.particleSystem, false)
		end
	end
	for _, v147_ in ipairs(v144_.particleAnimations) do
		for _, v148_ in ipairs(v147_.mappings) do
			setVisibility(v148_.animNode, false)
		end
	end
end
