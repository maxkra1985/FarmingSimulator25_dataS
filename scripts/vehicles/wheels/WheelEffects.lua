WheelEffects = {}
WheelEffects.MAX_UPDATE_DISTANCE = 75
WheelEffects.PARTICLE_SYSTEM_PATH = "data/effects/wheel/wheelEmitterShape.i3d"
WheelEffects.WATER_EFFECTS = "data/effects/wheel/water/water.i3d"
WheelEffects.WATER_EFFECT_FADE_IN_TIME = 0.001
WheelEffects.WATER_EFFECT_FADE_OUT_TIME = 0.002
WheelEffects.PARTICLE_SYSTEM_STATES = {}
WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_DUST = 1
WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_DRY = 2
WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_WET = 3
WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_SNOW = 4
WheelEffects.GROUND_PARTICLES = {}
WheelEffects.GROUND_PARTICLES[1] = true
WheelEffects.GROUND_PARTICLES[2] = false
WheelEffects.GROUND_PARTICLES[3] = true
WheelEffects.GROUND_PARTICLES[4] = false
WheelEffects.GROUND_PARTICLES[5] = true
WheelEffects.GROUND_PARTICLES[6] = true
WheelEffects.GROUND_PARTICLES[7] = false
WheelEffects.MAX_MUD_AMOUNT = {}
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.STUBBLE_TILLAGE] = 0.5
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.CULTIVATED] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.SEEDBED] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.PLOWED] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.ROLLED_SEEDBED] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.RIDGE] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.SOWN] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.DIRECT_SOWN] = 0.5
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.PLANTED] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.RIDGE_SOWN] = 0.5
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.ROLLER_LINES] = 0.5
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.HARVEST_READY] = 0.2
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.HARVEST_READY_OTHER] = 1
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.GRASS] = 0.2
WheelEffects.MAX_MUD_AMOUNT[FieldGroundType.GRASS_CUT] = 0.2

-- Local values: self
function WheelEffects.new(wheel)
	local v2_ = {
		["__index"] = WheelEffects
	}
	local v3_ = setmetatable({}, v2_)
	v3_.wheel = wheel
	v3_.vehicle = wheel.vehicle
	v3_.sharedLoadRequestIds = {}
	v3_.driveGroundParticleSystems = {}
	v3_.waterEffects = {}
	v3_.waterEffectsLoaded = false
	v3_.waterEffectsActive = false
	v3_.waterEffectScale = 0
	v3_.waterEffectReferenceRadius = nil
	v3_.speedSmooth = 0
	v3_.wheelSpeedSmooth = 0
	return v3_
end

-- Local values: _, particleSystem, _, sharedLoadRequestId
function WheelEffects:delete()
	for _, v5_ in pairs(self.driveGroundParticleSystems) do
		ParticleUtil.deleteParticleSystem(v5_)
	end
	for _, v6_ in ipairs(self.sharedLoadRequestIds) do
		g_i3DManager:releaseSharedI3DFile(v6_)
	end
	self.sharedLoadRequestIds = {}
	self:removeWaterEffects()
end

function WheelEffects:loadFromXML(xmlObject)
	self.hasTireTracks = xmlObject:getValue("#hasTireTracks", false)
	self.hasParticles = xmlObject:getValue("#hasParticles", false)
	self.hasWaterParticles = xmlObject:getValue("#hasWaterParticles")
	self.waterParticleDirection = xmlObject:getValue("#waterParticleDirection", 0)
	self.isShallowWaterObstacle = xmlObject:getValue("#isShallowWaterObstacle", true)
	self.tireTrackAtlasIndex = xmlObject:getValue(".tire#tireTrackAtlasIndex", 0)
	self.offset = xmlObject:getValue(".wheelParticleSystem#psOffset", "0 0 0", true)
	self.minSpeed = xmlObject:getValue(".wheelParticleSystem#minSpeed", 3) / 3600
	self.maxSpeed = xmlObject:getValue(".wheelParticleSystem#maxSpeed", 20) / 3600
	self.minScale = xmlObject:getValue(".wheelParticleSystem#minScale", 0.1)
	self.maxScale = xmlObject:getValue(".wheelParticleSystem#maxScale", 1)
	self.direction = xmlObject:getValue(".wheelParticleSystem#direction", 0)
	self.onlyActiveOnGroundContact = xmlObject:getValue(".wheelParticleSystem#onlyActiveOnGroundContact", true)
	return true
end

-- Local values: _, visualWheel, name, state, sourceParticleSystem, args, sharedLoadRequestId, args, sharedLoadRequestId, name, state, sourceParticleSystem, args, sharedLoadRequestId
function WheelEffects:finalize()
	for _, v10_ in ipairs(self.wheel.visualWheels) do
		if self.hasParticles then
			for v11_, v12_ in pairs(WheelEffects.PARTICLE_SYSTEM_STATES) do
				local v13_ = g_particleSystemManager:getParticleSystem(v11_)
				if v13_ ~= nil then
					local v14_ = {
						["name"] = v11_,
						["state"] = v12_,
						["wheelNode"] = v10_.node,
						["width"] = v10_.width,
						["radius"] = v10_.radius,
						["sourceParticleSystem"] = v13_,
						["sizeScale"] = 2 * v10_.width * v10_.radius
					}
					local v15_ = self.vehicle:loadSubSharedI3DFile(WheelEffects.PARTICLE_SYSTEM_PATH, false, false, self.onWheelParticleSystemI3DLoaded, self, v14_)
					local v16_ = self.sharedLoadRequestIds
					table.insert(v16_, v15_)
				end
			end
		end
		if self.hasWaterParticles ~= false then
			local v17_ = {
				["wheelNode"] = v10_.node,
				["width"] = v10_.width,
				["radius"] = v10_.radius
			}
			local v18_ = self.vehicle:loadSubSharedI3DFile(WheelEffects.WATER_EFFECTS, false, false, self.onWheelWaterEffectI3DLoaded, self, v17_)
			local v19_ = self.sharedLoadRequestIds
			table.insert(v19_, v18_)
		end
		if self.isShallowWaterObstacle then
			v10_:addShallowWaterObstacle()
		end
	end
	if #self.wheel.visualWheels == 0 then
		if self.hasParticles then
			for v20_, v21_ in pairs(WheelEffects.PARTICLE_SYSTEM_STATES) do
				local v22_ = g_particleSystemManager:getParticleSystem(v20_)
				if v22_ ~= nil then
					local v23_ = {
						["name"] = v20_,
						["state"] = v21_,
						["wheelNode"] = self.wheel.driveNode,
						["width"] = self.wheel.physics.width,
						["radius"] = self.wheel.physics.radius,
						["sourceParticleSystem"] = v22_,
						["sizeScale"] = 2 * self.wheel.physics.width * self.wheel.physics.radius
					}
					local v24_ = self.vehicle:loadSubSharedI3DFile(WheelEffects.PARTICLE_SYSTEM_PATH, false, false, self.onWheelParticleSystemI3DLoaded, self, v23_)
					local v25_ = self.sharedLoadRequestIds
					table.insert(v25_, v24_)
				end
			end
		end
		if self.hasWaterParticles == true then
			self:addWaterEffectsToPhysicsData()
		end
		if self.hasTireTracks and Platform.gameplay.wheelTireTracks then
			self.tireTrackNodeIndex = self.vehicle:addTireTrackNode(self.wheel, self.wheel.driveNodeDirectionNode, self.wheel.driveNode, self.tireTrackAtlasIndex, self.wheel.physics.width, self.wheel.physics.radius, false)
			self.wheel.syncContactState = true
		end
	end
end

-- Local values: _, visualWheel
function WheelEffects:postLoad()
	for _, v27_ in ipairs(self.wheel.visualWheels) do
		if self.hasTireTracks and Platform.gameplay.wheelTireTracks then
			self.tireTrackNodeIndex = self.vehicle:addTireTrackNode(self.wheel, self.wheel.driveNodeDirectionNode, v27_:getTireNode() or v27_.node, self.tireTrackAtlasIndex, v27_.width, v27_.radius, v27_:getIsTireInverted())
			self.wheel.syncContactState = true
		end
	end
end

-- Local values: emitterShape, particleSystem, wx, wy, wz
function WheelEffects:onWheelParticleSystemI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		local v31_ = getChildAt(i3dNode, 0)
		link(self.wheel.repr, v31_)
		delete(i3dNode)
		local v32_ = ParticleUtil.copyParticleSystem(nil, nil, args.sourceParticleSystem, v31_)
		v32_.state = args.state
		v32_.i3dFilename = args.i3dFilename
		v32_.particleSpeed = ParticleUtil.getParticleSystemSpeed(v32_)
		v32_.particleRandomSpeed = ParticleUtil.getParticleSystemSpeedRandom(v32_)
		v32_.sizeScale = args.sizeScale
		v32_.alpha = 0
		v32_.isTintable = Utils.getNoNil(getUserAttribute(v32_.shape, "tintable"), true)
		local v33_, v34_, v35_ = worldToLocal(self.wheel.repr, getWorldTranslation(args.wheelNode))
		setTranslation(v32_.emitterShape, v33_ + self.offset[1], v34_ + self.offset[2], v35_ + self.offset[3])
		setRotation(v32_.emitterShape, localRotationToLocal(args.wheelNode, getParent(v32_.emitterShape), 0, 0, 0))
		setScale(v32_.emitterShape, args.width, args.radius * 2, args.radius * 2)
		local v36_ = self.driveGroundParticleSystems
		table.insert(v36_, v32_)
	end
end

-- Local values: waterFront, waterFrontFoam, waterBack, waterBackFoam, waterEffectNode, waterEffect, baseDensity
function WheelEffects:onWheelWaterEffectI3DLoaded(i3dNode, failedReason, wheelData)
	if i3dNode ~= 0 and self.hasWaterParticles ~= false then
		local v40_ = getChildAt(i3dNode, 0)
		local v41_ = getChildAt(i3dNode, 1)
		local v42_ = getChildAt(i3dNode, 2)
		local v43_ = getChildAt(i3dNode, 3)
		local v44_ = createTransformGroup("waterEffectNode")
		link(self.wheel.node, v44_)
		setWorldTranslation(v44_, getWorldTranslation(wheelData.wheelNode))
		setWorldRotation(v44_, getWorldRotation(wheelData.wheelNode))
		link(v44_, v40_)
		link(v44_, v41_)
		link(v44_, v42_)
		link(v44_, v43_)
		setTranslation(v40_, 0, 0, wheelData.radius * 0.65)
		setTranslation(v41_, 0, 0, wheelData.radius * 0.65)
		setTranslation(v42_, 0, 0, -wheelData.radius * 0.35)
		setTranslation(v43_, 0, 0, -wheelData.radius * 0.35)
		local v45_ = wheelData.radius * wheelData.width
		local v46_ = math.min(v45_, 1)
		setShaderParameter(v40_, "fadeProgress", nil, nil, v46_, 0, false)
		setShaderParameter(v41_, "fadeProgress", nil, nil, v46_, 0, false)
		setShaderParameter(v42_, "fadeProgress", nil, nil, v46_, 0, false)
		setShaderParameter(v43_, "fadeProgress", nil, nil, v46_, 0, false)
		setVisibility(v44_, false)
		self.waterEffectsActive = false
		local v47_ = self.waterEffects
		table.insert(v47_, {
			["wheelData"] = wheelData,
			["waterEffectNode"] = v44_,
			["waterFront"] = v40_,
			["waterFrontFoam"] = v41_,
			["waterBack"] = v42_,
			["waterBackFoam"] = v43_
		})
		self.waterEffectsLoaded = true
		delete(i3dNode)
	end
end

-- Local values: args, sharedLoadRequestId
function WheelEffects:addWaterEffectsToPhysicsData()
	self.hasWaterParticles = true
	local v49_ = {
		["wheelNode"] = self.wheel.driveNode,
		["width"] = self.wheel.physics.width,
		["radius"] = self.wheel.physics.radius
	}
	local v50_ = self.vehicle:loadSubSharedI3DFile(WheelEffects.WATER_EFFECTS, false, false, self.onWheelWaterEffectI3DLoaded, self, v49_)
	local v51_ = self.sharedLoadRequestIds
	table.insert(v51_, v50_)
end

-- Local values: _, waterEffect
function WheelEffects:removeWaterEffects()
	for _, v53_ in ipairs(self.waterEffects) do
		delete(v53_.waterEffectNode)
	end
	self.waterEffects = {}
	self.waterEffectsLoaded = false
	self.hasWaterParticles = false
end

-- Local values: wheel, minSpeed, direction, maxSpeed, alpha, scale
function WheelEffects:getDriveGroundParticleSystemsScale(particleSystem, speed)
	local v56_ = self.wheel
	if not v56_.physics.hasSnowContact then
		if self.onlyActiveOnGroundContact and v56_.physics.contact ~= WheelContactType.GROUND then
			return 0
		end
		if not WheelEffects.GROUND_PARTICLES[v56_.physics.lastTerrainAttribute] then
			return 0
		end
		if v56_.physics.densityType == FieldGroundType.GRASS then
			return 0
		end
	end
	local v57_ = self.minSpeed
	local v58_ = self.direction
	if v57_ >= speed or v58_ ~= 0 and v58_ > 0 ~= (self.vehicle.movingDirection > 0) then
		return 0
	end
	local v59_ = self.maxSpeed
	local v60_ = (speed - v57_) / (v59_ - v57_)
	local v61_ = math.min(v60_, 1)
	return MathUtil.lerp(self.minScale, self.maxScale, v61_)
end

-- Local values: physics, isActive, contactX, contactY, contactZ, terrainHeight, direction, speed, wheelSpeed, slipScale, densityFront, densityFrontFoam, densityBack, densityBackFoam, _, waterEffect, offsetX, _, offsetZ, _, offsetY, _, nx, _, nz, tx, tz, offsetX, offsetY, offsetZ, offsetX, offsetY, offsetZ, dx, dz, length, dy, upX, upY, upZ, _, ny, _, radius, scaleFront, scaleBack, scaleX, _, waterEffect
function WheelEffects:update(dt, groundWetness, currentUpdateIndex)
	if self.waterEffectsLoaded then
		local v64_ = self.wheel.physics
		if VehicleDebug.wheelEffectDebugState then
			v64_.hasWaterContact = true
			v64_.netInfo.lastSpeedSmoothed = 0.005555555555555556
			self.waterEffectScale = 1
			self.vehicle.lastSpeedSmoothed = 0.005555555555555556
		end
		if v64_.hasWaterContact then
			local v65_ = self.waterEffectScale + dt * WheelEffects.WATER_EFFECT_FADE_IN_TIME
			self.waterEffectScale = math.min(v65_, 1)
		else
			local v66_ = self.waterEffectScale - dt * WheelEffects.WATER_EFFECT_FADE_OUT_TIME
			self.waterEffectScale = math.max(v66_, 0)
		end
		local v67_
		if self.waterEffectScale > 0 then
			v67_ = v64_.lastContactX ~= nil
		else
			v67_ = false
		end
		if v67_ then
			local v68_ = v64_.lastContactX
			local v69_ = v64_.lastContactY
			local v70_ = v64_.lastContactZ
			if v69_ > 0 then
				local v71_ = getTerrainHeightAtWorldPos(g_terrainNode, v68_, 0, v70_)
				v69_ = math.max(v69_, v71_)
			end
			local v72_ = v64_.netInfo.lastSpeedSmoothed < -0.000277 and -1 or 1
			local v73_ = self.vehicle.lastSpeedSmoothed * 3600
			local v74_ = v64_.netInfo.lastSpeedSmoothed
			local v75_ = math.abs(v74_) * 3600
			local v76_ = 1 + v64_.netInfo.slip
			local v77_ = (v73_ - 1) / 11
			local v78_ = math.min(v77_, 1)
			local v79_ = math.max(v78_, 0) * self.waterEffectScale
			local v80_ = (v73_ - 11) / 21 * math.min(v76_, 2)
			local v81_ = math.min(v80_, 1)
			local v82_ = math.max(v81_, 0) * self.waterEffectScale
			local v83_ = (v75_ - 1) / 11
			local v84_ = math.min(v83_, 1)
			local v85_ = math.max(v84_, 0) * self.waterEffectScale
			local v86_ = (v75_ - 11) / 21 * math.min(v76_, 2)
			local v87_ = math.min(v86_, 1)
			local v88_ = math.max(v87_, 0) * self.waterEffectScale
			if self.waterParticleDirection ~= 0 then
				if self.waterParticleDirection > 0 == (v72_ > 0) then
					v85_ = 0
					v88_ = 0
				else
					v82_ = 0
					v79_ = 0
				end
			end
			for _, v89_ in ipairs(self.waterEffects) do
				if not self.waterEffectsActive then
					setVisibility(v89_.waterEffectNode, true)
				end
				local v90_, _, v91_ = localToLocal(v89_.wheelData.wheelNode, self.wheel.node, 0, 0, 0)
				local _, v92_, _ = worldToLocal(self.wheel.node, v68_, v69_, v70_)
				setTranslation(v89_.waterEffectNode, v90_, v92_, v91_)
				local v93_, _, v94_ = getWorldTranslation(v89_.waterEffectNode)
				local v95_, v96_
				if v64_.useReprDirection or (v64_.useDriveNodeDirection or v64_.rotSpeed ~= 0) then
					local v97_, v98_, v99_ = localToLocal(v89_.waterEffectNode, self.wheel.driveNodeDirectionNode, 0, 0, 0)
					local v100_
					v95_, v100_, v96_ = localToWorld(self.wheel.driveNodeDirectionNode, v97_, v98_, v99_ - v72_ * 0.25)
				else
					local v101_, v102_, v103_ = localToLocal(v89_.waterEffectNode, self.wheel.node, 0, 0, 0)
					local v104_
					v95_, v104_, v96_ = localToWorld(self.wheel.node, v101_, v102_, v103_ - v72_ * 0.25)
				end
				if v89_.worldTargetPosition == nil then
					v89_.worldTargetPosition = { v95_, v96_ }
				end
				v89_.worldTargetPosition[1] = v89_.worldTargetPosition[1] * 0.8 + v95_ * 0.2
				v89_.worldTargetPosition[2] = v89_.worldTargetPosition[2] * 0.8 + v96_ * 0.2
				local v105_ = v93_ - v89_.worldTargetPosition[1]
				local v106_ = v94_ - v89_.worldTargetPosition[2]
				local v107_ = MathUtil.vector3Length(v105_, 0, v106_)
				if v107_ > 0 then
					local v108_ = v105_ / v107_
					local v109_ = v106_ / v107_
					local v110_, v111_, v112_ = worldDirectionToLocal(getParent(v89_.waterEffectNode), v108_, 0, v109_)
					local v113_, v114_, v115_ = worldDirectionToLocal(getParent(v89_.waterEffectNode), 0, 1, 0)
					setDirection(v89_.waterEffectNode, v110_, v111_, v112_, v113_, v114_, v115_)
				end
				if VehicleDebug.wheelEffectDebugState then
					local _, v116_, _ = getWorldTranslation(v89_.waterEffectNode)
					drawDebugLine(v93_, v116_ + 2, v94_, 1, 0, 0, v89_.worldTargetPosition[1], v116_ + 2, v89_.worldTargetPosition[2], 1, 0, 0, true)
				end
				local v117_ = self.waterEffectReferenceRadius or v89_.wheelData.radius
				local v118_ = v73_ / 25
				local v119_ = math.min(v118_, 1)
				local v120_ = v117_ * math.max(v119_, 0.25)
				local v121_ = v75_ * math.min(v76_, 3) / 25
				local v122_ = math.min(v121_, 1)
				local v123_ = v117_ * math.max(v122_, 0.25)
				local v124_ = v89_.wheelData.width * 1.2
				setScale(v89_.waterFront, v124_, v120_, v120_)
				setScale(v89_.waterFrontFoam, v124_, v120_, v120_)
				setScale(v89_.waterBack, v124_, v123_, v123_)
				setScale(v89_.waterBackFoam, v124_, v123_, v123_)
				setShaderParameter(v89_.waterFront, "density", v79_, nil, nil, nil, false)
				setShaderParameter(v89_.waterFrontFoam, "density", v82_, nil, nil, nil, false)
				setShaderParameter(v89_.waterBack, "density", v85_, nil, nil, nil, false)
				setShaderParameter(v89_.waterBackFoam, "density", v88_, nil, nil, nil, false)
			end
		elseif self.waterEffectsActive then
			for _, v125_ in ipairs(self.waterEffects) do
				setVisibility(v125_.waterEffectNode, false)
			end
		end
		self.waterEffectsActive = v67_
	end
end

-- Local values: physics, groundColor, enableSoilPS, hasSnowContact, state, wheelSpeed, wheelSlip, _, particleSystem, scale, r, g, b, maxSpeed, circum, maxWheelRpm, wheelRotFactor, emitScale
function WheelEffects:updateTick(dt, groundWetness, currentUpdateDistance)
	if WheelEffects.MAX_UPDATE_DISTANCE >= currentUpdateDistance then
		local v130_ = self.wheel.physics
		local v131_ = v130_.groundColor
		local v132_ = v130_.hasSoilContact
		local v133_ = 0
		if v130_.hasSnowContact then
			v133_ = WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_SNOW
		elseif v132_ then
			if groundWetness > 0.2 then
				v133_ = WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_WET
			else
				v133_ = WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_DRY
			end
		elseif groundWetness <= 0.2 then
			v133_ = WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_DUST
		end
		local v134_ = v130_.netInfo.lastSpeedSmoothed
		local v135_ = 1 + v130_.netInfo.slip
		for _, v136_ in ipairs(self.driveGroundParticleSystems) do
			if v136_.state == v133_ then
				local v137_
				if v136_.state == WheelEffects.PARTICLE_SYSTEM_STATES.WHEEL_DUST then
					v137_ = self:getDriveGroundParticleSystemsScale(v136_, self.vehicle.lastSpeedSmoothed)
				else
					v137_ = self:getDriveGroundParticleSystemsScale(v136_, v134_) * v135_
				end
				if v136_.isTintable then
					if v136_.lastColor == nil then
						v136_.lastColor = { v131_[1], v131_[2], v131_[3] }
						v136_.targetColor = { v131_[1], v131_[2], v131_[3] }
						v136_.currentColor = { v131_[1], v131_[2], v131_[3] }
						v136_.alpha = 1
					end
					if v136_.alpha ~= 1 then
						local v138_ = v136_.alpha + dt * 0.001
						v136_.alpha = math.min(v138_, 1)
						local v139_, v140_, v141_ = MathUtil.vector3ArrayLerp(v136_.lastColor, v136_.targetColor, v136_.alpha)
						v136_.currentColor[1] = v139_
						v136_.currentColor[2] = v140_
						v136_.currentColor[3] = v141_
						if v136_.alpha == 1 then
							v136_.lastColor[1] = v136_.currentColor[1]
							v136_.lastColor[2] = v136_.currentColor[2]
							v136_.lastColor[3] = v136_.currentColor[3]
						end
					end
					if v136_.alpha == 1 and (v131_[1] ~= v136_.targetColor[1] and (v131_[2] ~= v136_.targetColor[2] and v131_[3] ~= v136_.targetColor[3])) then
						v136_.alpha = 0
						v136_.targetColor[1] = v131_[1]
						v136_.targetColor[2] = v131_[2]
						v136_.targetColor[3] = v131_[3]
					end
				end
				if v137_ > 0 then
					ParticleUtil.setEmittingState(v136_, true)
					if v136_.isTintable then
						I3DUtil.setShaderParameterRec(v136_.shape, "colorAlpha", v136_.currentColor[1], v136_.currentColor[2], v136_.currentColor[3], 1)
					end
				else
					ParticleUtil.setEmittingState(v136_, false)
				end
				local v142_ = 13.88888888888889 / v130_.radiusOriginal
				local v143_ = v137_ * ((v130_.netInfo.xDriveSpeed or 0) / v142_) * v136_.sizeScale
				local v144_ = ParticleUtil.setEmitCountScale
				local v145_ = self.minScale
				local v146_ = self.maxScale
				v144_(v136_, (math.clamp(v143_, v145_, v146_)))
				ParticleUtil.setParticleSystemSpeed(v136_, v136_.particleSpeed)
				ParticleUtil.setParticleSystemSpeedRandom(v136_, v136_.particleRandomSpeed)
			else
				ParticleUtil.setEmittingState(v136_, false)
			end
		end
	end
end

-- Local values: _, particleSystem
function WheelEffects:onUpdateEnd(dt)
	for _, v148_ in ipairs(self.driveGroundParticleSystems) do
		ParticleUtil.setEmittingState(v148_, false)
	end
end

function WheelEffects.registerXMLPaths(schema, key)
	schema:register(XMLValueType.BOOL, key .. "#hasTireTracks", "Has tire tracks", false)
	schema:register(XMLValueType.BOOL, key .. "#hasParticles", "Has particles", false)
	schema:register(XMLValueType.BOOL, key .. "#hasWaterParticles", "Has water particles", "true if visual wheel is defined")
	schema:register(XMLValueType.INT, key .. "#waterParticleDirection", "The direction in which the water particles should only be active (0: both, 1: only the front, -1: only the back)", 0)
	schema:register(XMLValueType.BOOL, key .. "#isShallowWaterObstacle", "The visual wheels will interact with the shallow water simulation", true)
	schema:register(XMLValueType.FLOAT, key .. ".tire#tireTrackAtlasIndex", "Tire track atlas index", 0)
	schema:register(XMLValueType.VECTOR_TRANS, key .. ".wheelParticleSystem#psOffset", "Translation offset", "0 0 0")
	schema:register(XMLValueType.FLOAT, key .. ".wheelParticleSystem#minSpeed", "Min. speed for activation", 3)
	schema:register(XMLValueType.FLOAT, key .. ".wheelParticleSystem#maxSpeed", "Max. speed for activation", 20)
	schema:register(XMLValueType.FLOAT, key .. ".wheelParticleSystem#minScale", "Min. scale", 0.1)
	schema:register(XMLValueType.FLOAT, key .. ".wheelParticleSystem#maxScale", "Max. scale", 1)
	schema:register(XMLValueType.INT, key .. ".wheelParticleSystem#direction", "Moving direction for activation", 0)
	schema:register(XMLValueType.BOOL, key .. ".wheelParticleSystem#onlyActiveOnGroundContact", "Only active while wheel has ground contact", true)
end
