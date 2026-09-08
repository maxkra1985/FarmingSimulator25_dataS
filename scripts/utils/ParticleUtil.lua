ParticleUtil = {}

-- Local values: position, rotation
function ParticleUtil.loadParticleSystemData(xmlFile, data, baseString)
	if type(xmlFile) == "table" then
		xmlFile = xmlFile.handle
	end
	data.nodeStr = getXMLString(xmlFile, baseString .. "#node")
	data.psFile = getXMLString(xmlFile, baseString .. "#file")
	local v4_ = string.getVector(getXMLString(xmlFile, baseString .. "#position"), 3)
	if v4_ ~= nil then
		local v5_, v6_, v7_ = unpack(v4_)
		data.posX = v5_
		data.posY = v6_
		data.posZ = v7_
	end
	local v8_ = string.getVector(getXMLString(xmlFile, baseString .. "#rotation"), 3)
	if v8_ ~= nil then
		local v9_ = MathUtil.degToRad(v8_[1])
		local v10_ = MathUtil.degToRad(v8_[2])
		local v11_ = MathUtil.degToRad(v8_[3])
		data.rotX = v9_
		data.rotY = v10_
		data.rotZ = v11_
	end
	data.worldSpace = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#worldSpace"), true)
	data.psRootNodeStr = getXMLString(xmlFile, baseString .. "#particleNode")
	data.forceFullLifespan = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#forceFullLifespan"), false)
	data.useEmitterVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#useEmitterVisibility"), false)
end

-- Local values: data
function ParticleUtil.loadParticleSystem(xmlFile, particleSystem, baseString, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
	local v20_ = {}
	ParticleUtil.loadParticleSystemData(xmlFile, v20_, baseString)
	return ParticleUtil.loadParticleSystemFromData(v20_, particleSystem, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
end

-- Local values: linkNode, psFile, arguments
function ParticleUtil.loadParticleSystemFromData(data, particleSystem, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
	if defaultLinkNode == nil then
		if type(linkNodes) == "table" then
			defaultLinkNode = linkNodes[1].node
		else
			defaultLinkNode = linkNodes
		end
	end
	local v28_ = Utils.getNoNil(I3DUtil.indexToObject(linkNodes, data.nodeStr), defaultLinkNode)
	local v29_ = data.psFile
	if v29_ ~= nil then
		defaultPsFile = v29_
	end
	if defaultPsFile ~= nil then
		local v30_ = Utils.getFilename(defaultPsFile, baseDir)
		particleSystem.isValid = false
		particleSystem.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v30_, true, true, ParticleUtil.particleI3DFileLoaded, ParticleUtil, {
			["data"] = data,
			["particleSystem"] = particleSystem,
			["linkNode"] = v28_,
			["psFile"] = v30_,
			["defaultEmittingState"] = defaultEmittingState
		})
		return true
	end
end

-- Local values: data, particleSystem, linkNode, psFile, defaultEmittingState, rootNode, newRootNode, posX, posY, posZ, rotX, rotY, rotZ
function ParticleUtil.particleI3DFileLoaded(_, i3dNode, failedReason, args)
	local v33_ = args.data
	local v34_ = args.particleSystem
	local v35_ = args.linkNode
	local v36_ = args.psFile
	local v37_ = args.defaultEmittingState
	if i3dNode == 0 then
		printError("Error: failed to load particle system " .. v36_)
	else
		local v38_
		if v33_.psRootNodeStr == nil then
			v38_ = getChildAt(i3dNode, 0)
		else
			v38_ = I3DUtil.indexToObject(i3dNode, v33_.psRootNodeStr)
			if v38_ == nil then
				v38_ = i3dNode
			end
		end
		if v35_ ~= nil then
			link(v35_, v38_)
		end
		local v39_ = v33_.posX
		local v40_ = v33_.posY
		local v41_ = v33_.posZ
		if v39_ ~= nil and (v40_ ~= nil and v41_ ~= nil) then
			setTranslation(v38_, v39_, v40_, v41_)
		end
		local v42_ = v33_.rotX
		local v43_ = v33_.rotY
		local v44_ = v33_.rotZ
		if v42_ ~= nil and (v43_ ~= nil and v44_ ~= nil) then
			setRotation(v38_, v42_, v43_, v44_)
		end
		ParticleUtil.loadParticleSystemFromNode(v38_, v34_, v37_, v33_.worldSpace, v33_.forceFullLifespan, v36_)
		if v38_ ~= i3dNode then
			delete(i3dNode)
		end
	end
end

-- Local values: geometry, parent, x, y, z, dx, dy, dz, upx, upy, upz
function ParticleUtil.loadParticleSystemFromNode(rootNode, particleSystem, defaultEmittingState, worldSpace, forceFullLifespan)
	local v50_ = defaultEmittingState == nil and true or defaultEmittingState
	if getHasClassId(rootNode, ClassIds.SHAPE) then
		local v51_ = getGeometry(rootNode)
		if v51_ ~= 0 and getHasClassId(v51_, ClassIds.PARTICLE_SYSTEM) then
			particleSystem.emitterShape = getEmitterShape(v51_)
			particleSystem.emitterShapeSize = getEmitterSurfaceSize(v51_)
			particleSystem.defaultEmitterShapeSize = getEmitterSurfaceSize(v51_)
			if worldSpace then
				local v52_ = getParent(rootNode)
				if particleSystem.emitterShape ~= 0 and getParent(particleSystem.emitterShape) == rootNode then
					local v53_, v54_, v55_ = getScale(particleSystem.emitterShape)
					setTranslation(particleSystem.emitterShape, worldToLocal(v52_, getWorldTranslation(particleSystem.emitterShape)))
					local v56_, v57_, v58_ = worldDirectionToLocal(rootNode, localDirectionToWorld(particleSystem.emitterShape, 0, 0, 1))
					local v59_, v60_, v61_ = worldDirectionToLocal(rootNode, localDirectionToWorld(particleSystem.emitterShape, 0, 1, 0))
					setDirection(particleSystem.emitterShape, v56_, v57_, v58_, v59_, v60_, v61_)
					link(v52_, particleSystem.emitterShape)
					setScale(particleSystem.emitterShape, v53_, v54_, v55_)
				end
				link(getRootNode(), rootNode)
				setTranslation(rootNode, 0, 0, 0)
				setRotation(rootNode, 0, 0, 0)
			end
			setObjectMask(rootNode, 16711807)
			particleSystem.geometry = v51_
			particleSystem.shape = rootNode
			particleSystem.worldSpace = worldSpace
			particleSystem.forceFullLifespan = forceFullLifespan
			particleSystem.originalLifespan = getParticleSystemLifespan(v51_)
			particleSystem.isValid = true
			setEmittingState(v51_, v50_)
		end
	end
	particleSystem.isEmitting = v50_
	return rootNode
end

function ParticleUtil.deleteParticleSystem(particleSystem)
	if particleSystem ~= nil and particleSystem.shape ~= nil then
		if entityExists(particleSystem.shape) then
			delete(particleSystem.shape)
		end
		particleSystem.shape = nil
		if particleSystem.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(particleSystem.sharedLoadRequestId)
			particleSystem.sharedLoadRequestId = nil
		end
	end
end

-- Local values: _, ps
function ParticleUtil.deleteParticleSystems(particleSystems)
	if particleSystems ~= nil then
		for _, v64_ in pairs(particleSystems) do
			ParticleUtil.deleteParticleSystem(v64_)
		end
	end
end

function ParticleUtil.setEmittingState(particleSystem, state, resetStartTimer, resetStopTimer)
	if particleSystem ~= nil and (particleSystem.isValid and particleSystem.isEmitting ~= state) then
		particleSystem.isEmitting = state
		local v69_ = resetStartTimer == nil and true or resetStartTimer
		local v70_ = resetStopTimer == nil and true or resetStopTimer
		if state then
			if v69_ then
				resetEmitStartTimer(particleSystem.geometry)
			end
		elseif v70_ then
			resetEmitStopTimer(particleSystem.geometry)
		end
		setEmittingState(particleSystem.geometry, state)
		if state and particleSystem.useEmitterVisibility then
			setVisibility(particleSystem.shape, getEffectiveVisibility(particleSystem.emitterShape))
		end
	end
end

function ParticleUtil.getParticleSystemAverageSpeed(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemAverageSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemTimeScale(particleSystem, scale)
	if particleSystem ~= nil and (particleSystem.isValid and scale ~= nil) then
		setParticleSystemTimeScale(particleSystem.geometry, scale)
	end
end

function ParticleUtil.setEmitCountScale(particleSystem, scale)
	if particleSystem ~= nil and (particleSystem.isValid and scale ~= nil) then
		setEmitCountScale(particleSystem.geometry, scale)
	end
end

function ParticleUtil.setParticleLifespan(particleSystem, lifespan)
	if particleSystem ~= nil and (particleSystem.isValid and lifespan ~= nil) then
		setParticleSystemLifespan(particleSystem.geometry, lifespan, true)
	end
end

function ParticleUtil.addParticleSystemSimulationTime(particleSystem, simTime)
	if particleSystem ~= nil and (particleSystem.isValid and simTime ~= nil) then
		addParticleSystemSimulationTime(particleSystem.geometry, simTime)
	end
end

function ParticleUtil.setParticleStartStopTime(particleSystem, startTime, stopTime)
	if particleSystem ~= nil and (particleSystem.isValid and (startTime ~= nil and stopTime ~= nil)) then
		setEmitStartTime(particleSystem.geometry, startTime * 1000)
		setEmitStopTime(particleSystem.geometry, stopTime * 1000)
	end
end

function ParticleUtil.getParticleSystemSpeed(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpeed(particleSystem, speed)
	if particleSystem ~= nil and (particleSystem.isValid and speed ~= nil) then
		setParticleSystemSpeed(particleSystem.geometry, speed)
	end
end

function ParticleUtil.getParticleSystemSpeedRandom(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemSpeedRandom(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpeedRandom(particleSystem, randomSpeed)
	if particleSystem ~= nil and (particleSystem.isValid and randomSpeed ~= nil) then
		setParticleSystemSpeedRandom(particleSystem.geometry, randomSpeed)
	end
end

function ParticleUtil.getParticleSystemNormalSpeed(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemNormalSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemNormalSpeed(particleSystem, normalSpeed)
	if particleSystem ~= nil and (particleSystem.isValid and normalSpeed ~= nil) then
		setParticleSystemNormalSpeed(particleSystem.geometry, normalSpeed)
	end
end

function ParticleUtil.getParticleSystemTangentSpeed(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemTangentSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemTangentSpeed(particleSystem, tangentSpeed)
	if particleSystem ~= nil and (particleSystem.isValid and tangentSpeed ~= nil) then
		setParticleSystemTangentSpeed(particleSystem.geometry, tangentSpeed)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleX(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemSpriteScaleX(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, spriteScaleX)
	if particleSystem ~= nil and (particleSystem.isValid and spriteScaleX ~= nil) then
		setParticleSystemSpriteScaleX(particleSystem.geometry, spriteScaleX)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleY(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemSpriteScaleY(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, spriteScaleY)
	if particleSystem ~= nil and (particleSystem.isValid and spriteScaleY ~= nil) then
		setParticleSystemSpriteScaleY(particleSystem.geometry, spriteScaleY)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleXGain(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemSpriteScaleXGain(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleXGain(particleSystem, spriteScaleXGain)
	if particleSystem ~= nil and (particleSystem.isValid and spriteScaleXGain ~= nil) then
		setParticleSystemSpriteScaleXGain(particleSystem.geometry, spriteScaleXGain)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleYGain(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getParticleSystemSpriteScaleYGain(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleYGain(particleSystem, spriteScaleYGain)
	if particleSystem ~= nil and (particleSystem.isValid and spriteScaleYGain ~= nil) then
		setParticleSystemSpriteScaleYGain(particleSystem.geometry, spriteScaleYGain)
	end
end

function ParticleUtil.getParticleSystemVelocityScale(particleSystem)
	if particleSystem == nil or not particleSystem.isValid then
		return nil
	else
		return getEmitterShapeVelocityScale(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemVelocityScale(particleSystem, velocityScale)
	if particleSystem ~= nil and (particleSystem.isValid and velocityScale ~= nil) then
		setEmitterShapeVelocityScale(particleSystem.geometry, velocityScale)
	end
end

function ParticleUtil.resetNumOfEmittedParticles(particleSystem)
	if particleSystem ~= nil and particleSystem.isValid then
		resetNumOfEmittedParticles(particleSystem.geometry)
	end
end

function ParticleUtil.setEmitterShape(particleSystem, emitterShape)
	if particleSystem ~= nil and (particleSystem.isValid and (emitterShape ~= nil and (particleSystem.geometry ~= nil and (particleSystem.geometry ~= 0 and getHasClassId(particleSystem.geometry, ClassIds.PARTICLE_SYSTEM))))) then
		if not getHasClassId(emitterShape, ClassIds.SHAPE) then
			Logging.warning("Trying to set an emitter shape for a particle system but given node (\'%s\') is not a shape. Ignoring it!", getName(emitterShape))
			return
		end
		setEmitterShape(particleSystem.geometry, emitterShape)
		particleSystem.emitterShape = emitterShape
		particleSystem.emitterShapeSize = getEmitterSurfaceSize(particleSystem.geometry)
	end
end

function ParticleUtil.initEmitterScale(particleSystem, scale)
	if particleSystem ~= nil and particleSystem.isValid then
		if particleSystem.baseNumOfParticlesToEmitPerMs == nil then
			particleSystem.baseNumOfParticlesToEmitPerMs = getNumOfParticlesToEmitPerMs(particleSystem.geometry)
		end
		setNumOfParticlesToEmitPerMs(particleSystem.geometry, particleSystem.baseNumOfParticlesToEmitPerMs * scale)
		if particleSystem.baseMaxNumOfParticles == nil then
			particleSystem.baseMaxNumOfParticles = getMaxNumOfParticles(particleSystem.geometry)
		end
		local v115_ = setMaxNumOfParticles
		local v116_ = particleSystem.geometry
		local v117_ = particleSystem.baseMaxNumOfParticles * scale
		v115_(v116_, (math.ceil(v117_)))
	end
end

function ParticleUtil.setMaxNumOfParticlesToEmitScale(particleSystem, scale)
	if particleSystem ~= nil and particleSystem.isValid then
		if particleSystem.baseNumOfParticlesToEmitPerMs == nil then
			particleSystem.baseNumOfParticlesToEmitPerMs = getNumOfParticlesToEmitPerMs(particleSystem.geometry)
		end
		setNumOfParticlesToEmitPerMs(particleSystem.geometry, particleSystem.baseNumOfParticlesToEmitPerMs * scale)
	end
end

function ParticleUtil.setMaterial(particleSystem, material)
	if particleSystem ~= nil and particleSystem.isValid then
		setMaterial(particleSystem.shape, material, 0)
	end
end

-- Local values: currentPS, psClone, scale
function ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, emitterShape)
	local v126_ = {
		["worldSpace"] = true,
		["emitCountScale"] = 1,
		["useEmitterVisibility"] = false
	}
	if key ~= nil then
		v126_.worldSpace = xmlFile:getValue(key .. "#worldSpace", v126_.worldSpace)
		v126_.emitCountScale = xmlFile:getValue(key .. "#emitCountScale", v126_.emitCountScale)
		v126_.delay = xmlFile:getValue(key .. "#delay")
		v126_.startTime = xmlFile:getValue(key .. "#startTime", v126_.delay)
		v126_.stopTime = xmlFile:getValue(key .. "#stopTime", v126_.delay)
		v126_.lifespan = xmlFile:getValue(key .. "#lifespan")
		v126_.useEmitterVisibility = xmlFile:getValue(key .. "#useEmitterVisibility", v126_.useEmitterVisibility)
	end
	v126_.isValid = true
	local v127_ = clone(particleSystem.shape, true, false, true)
	setObjectMask(v127_, 16711807)
	ParticleUtil.loadParticleSystemFromNode(v127_, v126_, false, v126_.worldSpace, particleSystem.forceFullLifespan)
	if emitterShape ~= nil then
		local v128_ = clone(emitterShape, true, false, false)
		ParticleUtil.setEmitterShape(v126_, v128_)
		local v129_ = v126_.emitterShapeSize / v126_.defaultEmitterShapeSize * v126_.emitCountScale
		ParticleUtil.initEmitterScale(v126_, v129_)
		ParticleUtil.setEmitCountScale(v126_, 1)
		if v126_.lifespan ~= nil then
			ParticleUtil.setParticleLifespan(v126_, v126_.lifespan * 1000)
			v126_.originalLifespan = v126_.lifespan * 1000
		end
		ParticleUtil.setParticleStartStopTime(v126_, v126_.startTime, v126_.stopTime)
		if not v126_.worldSpace then
			link(getParent(v128_), v126_.shape, getChildIndex(v128_))
			setTranslation(v126_.shape, getTranslation(v128_))
			setRotation(v126_.shape, getRotation(v128_))
			link(v126_.shape, v128_)
			setTranslation(v128_, 0, 0, 0)
			setRotation(v128_, 0, 0, 0)
		end
	end
	return v126_
end

function ParticleUtil.registerParticleXMLPaths(schema, basePath, name)
	schema:setXMLSharedRegistration("ParticleSystem", basePath)
	local v133_ = basePath .. "." .. name
	schema:register(XMLValueType.STRING, v133_ .. "#node", "Particle link node")
	schema:register(XMLValueType.STRING, v133_ .. "#file", "Particle file name")
	schema:register(XMLValueType.VECTOR_TRANS, v133_ .. "#position", "Particle position")
	schema:register(XMLValueType.VECTOR_ROT, v133_ .. "#rotation", "Particle rotation")
	schema:register(XMLValueType.BOOL, v133_ .. "#worldSpace", "Is world space", true)
	schema:register(XMLValueType.STRING, v133_ .. "#particleNode", "Particle node in loaded file")
	schema:register(XMLValueType.BOOL, v133_ .. "#forceFullLifespan", "Force full lifespan", false)
	schema:register(XMLValueType.BOOL, v133_ .. "#useEmitterVisibility", "Use emitter visibility to show/hide particles", false)
	schema:resetXMLSharedRegistration("ParticleSystem", v133_)
end

function ParticleUtil.registerParticleCopyXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#worldSpace", "Is world space", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#emitCountScale", "Emit count scale", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#delay", "Activation delay")
	schema:register(XMLValueType.FLOAT, basePath .. "#startTime", "Start time", "Delay value")
	schema:register(XMLValueType.FLOAT, basePath .. "#stopTime", "Stop time", "Delay value")
	schema:register(XMLValueType.FLOAT, basePath .. "#lifespan", "Lifespan")
	schema:register(XMLValueType.BOOL, basePath .. "#useEmitterVisibility", "use emitter shape visibility", true)
end
