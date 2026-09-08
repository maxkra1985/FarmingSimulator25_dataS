-- Local values: ParticleSystemManager_mt
ParticleSystemManager = {}
ParticleType = nil
local ParticleSystemManager_mt = Class(ParticleSystemManager, AbstractManager)

-- Upvalues: ParticleSystemManager_mt
-- Local values: self
function ParticleSystemManager.new(customMt)
	-- upvalues: (copy) ParticleSystemManager_mt
	return AbstractManager.new(customMt or ParticleSystemManager_mt)
end

function ParticleSystemManager:initDataStructures()
	self.nameToIndex = {}
	self.particleTypes = {}
	self.particleSystems = {}
end

function ParticleSystemManager:loadMapData()
	ParticleSystemManager:superClass().loadMapData(self)
	self:addParticleType("unloading")
	self:addParticleType("smoke")
	self:addParticleType("smoke_damping")
	self:addParticleType("smoke_chimney")
	self:addParticleType("smoke_train_main")
	self:addParticleType("smoke_train_side")
	self:addParticleType("chopper")
	self:addParticleType("straw")
	self:addParticleType("cutter_chopper")
	self:addParticleType("soil")
	self:addParticleType("soil_smoke")
	self:addParticleType("soil_chunks")
	self:addParticleType("soil_big_chunks")
	self:addParticleType("soil_harvesting")
	self:addParticleType("spreader")
	self:addParticleType("spreader_smoke")
	self:addParticleType("windrower")
	self:addParticleType("tedder")
	self:addParticleType("weeder")
	self:addParticleType("crusher_wood")
	self:addParticleType("crusher_dust")
	self:addParticleType("prepare_fruit")
	self:addParticleType("cleaning_soil")
	self:addParticleType("cleaning_dust")
	self:addParticleType("washer_water")
	self:addParticleType("chainsaw_wood")
	self:addParticleType("chainsaw_dust")
	self:addParticleType("pickup")
	self:addParticleType("pickup_falling")
	self:addParticleType("sowing")
	self:addParticleType("loading")
	self:addParticleType("wheel_dust")
	self:addParticleType("wheel_dry")
	self:addParticleType("wheel_wet")
	self:addParticleType("wheel_snow")
	self:addParticleType("bees")
	self:addParticleType("horse_step_slow")
	self:addParticleType("horse_step_fast")
	self:addParticleType("spraycan_paint")
	self:addParticleType("HYDRAULIC_HAMMER")
	self:addParticleType("HYDRAULIC_HAMMER_DEBRIS")
	self:addParticleType("STONE")
	ParticleType = self.nameToIndex
	return true
end

-- Local values: _, fillTypeParticleSystem
function ParticleSystemManager:unloadMapData()
	for _, v6_ in pairs(self.particleSystems) do
		ParticleUtil.deleteParticleSystem(v6_)
	end
	ParticleSystemManager:superClass().unloadMapData(self)
end

function ParticleSystemManager:addParticleType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a particleType. Ignoring it!")
		return nil
	end
	local v9_ = string.upper(name)
	if self.nameToIndex[v9_] == nil then
		local v10_ = self.particleTypes
		table.insert(v10_, v9_)
		self.nameToIndex[v9_] = #self.particleTypes
	end
	return nil
end

function ParticleSystemManager:getParticleSystemTypeByName(name)
	if name ~= nil then
		local v13_ = string.upper(name)
		if self.nameToIndex[v13_] ~= nil then
			return v13_
		end
	end
	return nil
end

function ParticleSystemManager:addParticleSystem(particleType, particleSystem)
	if self.particleSystems[particleType] ~= nil then
		ParticleUtil.deleteParticleSystem(self.particleSystems[particleType])
	end
	self.particleSystems[particleType] = particleSystem
end

-- Local values: particleType
function ParticleSystemManager:getParticleSystem(particleTypeName)
	local v19_ = self:getParticleSystemTypeByName(particleTypeName)
	if v19_ == nil then
		return nil
	else
		return self.particleSystems[v19_]
	end
end

-- Local values: x, y, z, dirX, dirZ, ry, i, child, _, particleSystem, index, _, fillTypeDesc, worldSpace, sourceParticleSystem, psClone, emitterShape, particleSystem, wx, wy, wz, rx, ry, rz
function ParticleSystemManager:consoleCommandDebug()
	if ParticleSystemManager.debugRootNode == nil then
		ParticleSystemManager.debugRootNode = createTransformGroup("ParticleSystemManager_DebugRootNode")
		link(getRootNode(), ParticleSystemManager.debugRootNode)
		local v21_, v22_, v23_ = g_localPlayer:getPosition()
		local v24_, v25_ = g_localPlayer:getCurrentFacingDirection()
		local v26_ = v21_ + v24_ * 10
		local v27_ = v23_ + v25_ * 10
		local v28_ = MathUtil.getYRotationFromDirection(v24_, v25_)
		setWorldTranslation(ParticleSystemManager.debugRootNode, v26_, v22_ + 2, v27_)
		setWorldRotation(ParticleSystemManager.debugRootNode, 0, v28_, 0)
	else
		for _ = 1, getNumOfChildren(ParticleSystemManager.debugRootNode) do
			local v29_ = getChildAt(ParticleSystemManager.debugRootNode, 0)
			delete(v29_)
		end
	end
	if ParticleSystemManager.debugParticleSystems == nil then
		ParticleSystemManager.debugParticleSystems = {}
	else
		for _, v30_ in pairs(ParticleSystemManager.debugParticleSystems) do
			ParticleUtil.deleteParticleSystem(v30_)
		end
	end
	local v31_ = 0
	for _, v32_ in pairs(g_fillTypeManager.fillTypes) do
		v32_:reloadData()
		if v32_.prioritizedEffectType == "ParticleEffect" then
			local v33_ = self:getParticleSystem("unloading")
			if v33_ ~= nil then
				local v34_ = clone(v33_.shape, true, false, true)
				local v35_ = clone(v33_.emitterShape, true, false, false)
				link(ParticleSystemManager.debugRootNode, v35_)
				setTranslation(v35_, v31_ * 3, 0, 0)
				local v36_ = {}
				ParticleUtil.loadParticleSystemFromNode(v34_, v36_, false, true, v33_.forceFullLifespan)
				ParticleUtil.setEmitterShape(v36_, v35_)
				v32_:setParticleSystemFillType(v36_, "unloading", "unloadingParticle", false, 1)
				ParticleUtil.setEmittingState(v36_, true)
				local v37_ = ParticleSystemManager.debugParticleSystems
				table.insert(v37_, v36_)
				local v38_, v39_, v40_ = getWorldTranslation(v35_)
				local v41_, v42_, v43_ = localRotationToWorld(v35_, 0, 3.141592653589793, 0)
				g_debugManager:addElement(DebugText3D.new():createWithWorldPos(v38_, v39_ + 1.3, v40_, v41_, v42_, v43_, v32_.name, 0.15), nil, nil, math.huge)
				v31_ = v31_ + 1
			end
		end
	end
end
g_particleSystemManager = ParticleSystemManager.new()
addConsoleCommand("gsParticleSystemDebug", "Debug particle effect", "consoleCommandDebug", g_particleSystemManager)
