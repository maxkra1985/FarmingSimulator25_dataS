-- Local values: WindrowerEffect_mt
WindrowerEffect = {}
local WindrowerEffect_mt = Class(WindrowerEffect, MorphPositionEffect)

-- Upvalues: WindrowerEffect_mt
-- Local values: self
function WindrowerEffect.new(customMt)
	-- upvalues: (copy) WindrowerEffect_mt
	return MorphPositionEffect.new(customMt or WindrowerEffect_mt)
end

-- Local values: i, areaKey, start, width, height, particleKey, emitterShape, particleType, materialType, materialIndex, fadeInRange, fadeOutRange, x, y, z, xOffset, _, _, sourceParticleSystem, ps, psData
function WindrowerEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not WindrowerEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.unloadDirection = Effect.getValue(xmlFile, key, node, "unloadDirection", 0)
	self.width = Effect.getValue(xmlFile, key, node, "width", 0)
	self.dropOffset = Effect.getValue(xmlFile, key, node, "dropOffset", 0)
	self.turnOffRequiredEffect = Effect.getValue(xmlFile, key, node, "turnOffRequiredEffect", 0)
	self.testAreas = {}
	local v9_ = 0
	while true do
		local v10_ = key .. string.format(".testArea(%d)", v9_)
		if not xmlFile:hasProperty(v10_) then
			break
		end
		local v11_ = xmlFile:getValue(v10_ .. "#startNode", nil, self.rootNodes, i3dMapping)
		local v12_ = xmlFile:getValue(v10_ .. "#widthNode", nil, self.rootNodes, i3dMapping)
		local v13_ = xmlFile:getValue(v10_ .. "#heightNode", nil, self.rootNodes, i3dMapping)
		local v14_ = self.testAreas
		table.insert(v14_, {
			["start"] = v11_,
			["width"] = v12_,
			["height"] = v13_
		})
		v9_ = v9_ + 1
	end
	self.particleSystems = {}
	local v15_ = 0
	while true do
		local v16_ = key .. string.format(".particleSystem(%d)", v15_)
		if not xmlFile:hasProperty(v16_) then
			break
		end
		local v17_ = xmlFile:getValue(v16_ .. "#emitterShape", nil, self.rootNodes, i3dMapping)
		local v18_ = xmlFile:getValue(v16_ .. "#particleType")
		local v19_ = xmlFile:getValue(v16_ .. "#materialType", v18_)
		local v20_ = xmlFile:getValue(v16_ .. "#materialIndex", 1)
		local v21_ = xmlFile:getValue(v16_ .. "#fadeInRange", nil, true)
		local v22_ = xmlFile:getValue(v16_ .. "#fadeOutRange", nil, true)
		if v17_ ~= nil then
			local v23_, v24_, v25_ = getWorldTranslation(v17_)
			local v26_, _, _ = worldToLocal(self.node, v23_, v24_, v25_)
			local v27_ = g_particleSystemManager:getParticleSystem(v18_)
			if v27_ ~= nil then
				local v28_ = {
					["xOffset"] = v26_,
					["fadeInRange"] = v21_,
					["fadeOutRange"] = v22_,
					["particleSystem"] = ParticleUtil.copyParticleSystem(xmlFile, v16_, v27_, v17_),
					["materialType"] = v19_,
					["materialIndex"] = v20_,
					["fillType"] = FillType.UNKNOWN
				}
				local v29_ = self.particleSystems
				table.insert(v29_, v28_)
			end
		end
		v15_ = v15_ + 1
	end
	self.lastChargeTime = 0
	self.updateTick = 0
	self.scrollUpdate = false
	self.particleSystemsTurnedOff = false
	return true
end

-- Local values: _, particleSystemData
function WindrowerEffect:delete()
	WindrowerEffect:superClass().delete(self)
	for _, v31_ in ipairs(self.particleSystems) do
		ParticleUtil.deleteParticleSystem(v31_.particleSystem)
	end
end

-- Local values: minX, maxX, foundFillType, _, particleSystemData, inFadeInRange, inFadeOutRange, inXRange, material, _, particleSystemData, _, y, z, w
function WindrowerEffect:update(dt)
	WindrowerEffect:superClass().update(self, dt)
	if self.updateTick > 5 and self.state ~= ShaderPlaneEffect.STATE_OFF then
		local v34_, v35_, v36_ = WindrowerEffect.getCurrentTestAreaWidth(self)
		setShaderParameter(self.node, "offsetUV", self.scrollPosition, 0, v34_, v35_, false)
		for _, v37_ in ipairs(self.particleSystems) do
			local v38_
			if self.fadeCur[1] >= v37_.fadeInRange[1] then
				v38_ = self.fadeCur[1] <= v37_.fadeInRange[2]
			else
				v38_ = false
			end
			local v39_
			if self.fadeCur[2] >= v37_.fadeOutRange[1] then
				v39_ = self.fadeCur[2] <= v37_.fadeOutRange[2]
			else
				v39_ = false
			end
			local v40_
			if v34_ <= v37_.xOffset then
				v40_ = v37_.xOffset <= v35_
			else
				v40_ = false
			end
			if v40_ and (v38_ and (v39_ and self.state ~= ShaderPlaneEffect.STATE_OFF)) then
				if v37_.fillType ~= v36_ then
					local v41_ = g_materialManager:getParticleMaterial(v36_, v37_.materialType, v37_.materialIndex)
					if v41_ ~= nil then
						ParticleUtil.setMaterial(v37_.particleSystem, v41_)
					end
					v37_.fillType = v36_
				end
				ParticleUtil.setEmittingState(v37_.particleSystem, true)
			else
				ParticleUtil.setEmittingState(v37_.particleSystem, false)
			end
		end
		self.updateTick = 0
		self.particleSystemsTurnedOff = false
	elseif not self.particleSystemsTurnedOff then
		for _, v42_ in ipairs(self.particleSystems) do
			ParticleUtil.setEmittingState(v42_.particleSystem, false)
		end
		self.particleSystemsTurnedOff = true
	end
	local _, v43_, v44_, v45_ = getShaderParameter(self.node, "offsetUV")
	self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength
	setShaderParameter(self.node, "offsetUV", self.scrollPosition, v43_, v44_, v45_, false)
	self.updateTick = self.updateTick + 1
end

-- Local values: success, minX, fade
function WindrowerEffect:start()
	local v47_ = WindrowerEffect:superClass().start(self)
	if v47_ and self.unloadDirection ~= 0 then
		local v49_, v49_ = WindrowerEffect.getCurrentTestAreaWidth(self, true)
		local _ = self.unloadDirection < 0
		local v50_ = (v49_ / (self.width / 2) + 1) / 2
		self.fadeCur[2] = math.clamp(v50_, 0, 1)
		if self.unloadDirection < 0 then
			local v51_ = self.fadeCur
			local v52_ = 1 - self.fadeCur[2]
			v51_[2] = math.abs(v52_)
		end
	end
	return v47_
end

-- Local values: success, _, _, fade, maxX
function WindrowerEffect:stop()
	local v54_ = WindrowerEffect:superClass().stop(self)
	if v54_ and (self.unloadDirection ~= 0 and self.fadeCur[1] == 0) then
		local _, _, v56_, v56_ = getShaderParameter(self.node, "offsetUV")
		local _ = self.unloadDirection < 0
		local v57_ = (v56_ / (self.width / 2) + 1) / 2
		self.fadeCur[1] = math.clamp(v57_, 0, 1)
		if self.unloadDirection < 0 then
			local v58_ = self.fadeCur
			local v59_ = 1 - self.fadeCur[1]
			v58_[1] = math.abs(v59_)
		end
	end
	return v54_
end

-- Local values: minX, maxX, foundFillType, _, testArea, x0, y0, z0, x1, y1, z1, x2, _, z2, fillType, xStart, _, _, xWidth, _, _
function WindrowerEffect:getCurrentTestAreaWidth(real)
	local v62_ = self.width / 2 + self.dropOffset
	local v63_ = -self.width / 2 - self.dropOffset
	local v64_ = FillType.UNKNOWN
	for _, v65_ in ipairs(self.testAreas) do
		local v66_, v67_, v68_ = getWorldTranslation(v65_.start)
		local v69_, v70_, v71_ = getWorldTranslation(v65_.width)
		local v72_, _, v73_ = getWorldTranslation(v65_.height)
		local v74_ = DensityMapHeightUtil.getFillTypeAtArea(v66_, v68_, v69_, v71_, v72_, v73_)
		if v74_ ~= FillType.UNKNOWN then
			local v75_, _, _ = worldToLocal(self.node, v66_, v67_, v68_)
			local v76_, _, _ = worldToLocal(self.node, v69_, v70_, v71_)
			if v75_ >= v62_ then
				v75_ = v62_
			end
			if v63_ >= v76_ then
				v76_ = v63_
			end
			v64_ = v74_
			v63_ = v76_
			v62_ = v75_
		end
	end
	if (not real or real == nil) and self.unloadDirection ~= 0 then
		if self.unloadDirection < 0 then
			v62_ = -self.width / 2 - self.dropOffset
		end
		if self.unloadDirection > 0 then
			v63_ = self.width / 2 + self.dropOffset
		end
	end
	return v62_, v63_, v64_
end

function WindrowerEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#unloadDirection", "(WindrowerEffect) Unload direction")
	schema:register(XMLValueType.FLOAT, basePath .. "#width", "(WindrowerEffect) Width", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#dropOffset", "(WindrowerEffect) Drop offset", 0)
	schema:register(XMLValueType.INT, basePath .. "#turnOffRequiredEffect", "(WindrowerEffect) Index of turn off required effect", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#startNode", "(WindrowerEffect) Test area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#widthNode", "(WindrowerEffect) Test area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#heightNode", "(WindrowerEffect) Test area height node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".particleSystem(?)#emitterShape", "(WindrowerEffect) Emitter shape node")
	schema:register(XMLValueType.STRING, basePath .. ".particleSystem(?)#particleType", "(WindrowerEffect) Particle type")
	schema:register(XMLValueType.STRING, basePath .. ".particleSystem(?)#materialType", "(WindrowerEffect) Material type", "same as particleType")
	schema:register(XMLValueType.INT, basePath .. ".particleSystem(?)#materialIndex", "(WindrowerEffect) Particle type", 1)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".particleSystem(?)#fadeInRange", "(WindrowerEffect) Fade in range")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".particleSystem(?)#fadeOutRange", "(WindrowerEffect) Fade out range")
	ParticleUtil.registerParticleCopyXMLPaths(schema, basePath .. ".particleSystem(?)")
end
