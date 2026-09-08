-- Local values: CombinedEffect_mt
CombinedEffect = {}
CombinedEffect.STATE_OFF = 0
CombinedEffect.STATE_TURNING_ON = 1
CombinedEffect.STATE_ON = 2
CombinedEffect.STATE_TURNING_OFF = 3
local CombinedEffect_mt = Class(CombinedEffect, Effect)

-- Upvalues: CombinedEffect_mt
-- Local values: self
function CombinedEffect.new(customMt)
	-- upvalues: (copy) CombinedEffect_mt
	return Effect.new(customMt or CombinedEffect_mt)
end

-- Local values: i, effect, key, _, nodeKey, node, object
function CombinedEffect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
	self.parent = parent
	self.effects = g_effectManager:loadEffect(xmlFile, baseName, rootNodes, parent, i3dMapping)
	self.state = CombinedEffect.STATE_OFF
	self.fadeIn = 0
	self.fadeOut = 0
	self.fadeDuration = 0
	for v9_, v10_ in ipairs(self.effects) do
		if v10_:isa(MotionPathEffect) then
			local v11_ = v10_.delay + 1 / v10_.effectSpeedScaleOrig
			local v12_ = self.fadeDuration
			self.fadeDuration = math.max(v11_, v12_)
			v10_.minDensity = 1
		elseif v10_:isa(MorphPositionEffect) then
			local v13_ = (v10_.startDelay + v10_.fadeInTime) * 0.001
			local v14_ = self.fadeDuration
			self.fadeDuration = math.max(v13_, v14_)
		end
		v10_.testAreaSubIndex = xmlFile:getValue(string.format("%s.effectNode(%d)", baseName, v9_ - 1) .. "#testAreaSubIndex")
	end
	self.testAreaIndex = xmlFile:getValue(baseName .. "#testAreaIndex")
	self.objectChanges = {}
	for _, v15_ in xmlFile:iterator(baseName .. ".objectChange") do
		local v16_ = xmlFile:getValue(v15_ .. "#node", nil, rootNodes, i3dMapping)
		if v16_ ~= nil then
			local v17_ = {
				["node"] = v16_,
				["isActive"] = false
			}
			local v18_ = xmlFile:getValue(v15_ .. "#fadeTime", 0)
			local v19_ = self.fadeDuration
			v17_.fadeTime = v18_ / math.max(v19_, 0.01)
			v17_.workModeIndex = xmlFile:getValue(v15_ .. "#workModeIndex")
			ObjectChangeUtil.loadValuesFromXML(xmlFile, v15_, v16_, v17_, parent, rootNodes, i3dMapping)
			ObjectChangeUtil.setObjectChange(v17_, false, self.parent, self.parent.setMovingToolDirty, false)
			local v20_ = self.objectChanges
			table.insert(v20_, v17_)
		end
	end
	if #self.objectChanges == 0 then
		self.objectChanges = nil
	end
	return self
end

-- Local values: _, effect
function CombinedEffect:delete()
	for _, v22_ in ipairs(self.effects) do
		v22_:delete()
	end
end

-- Local values: updateEffectWidth, currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX, i, effect, i, effect, startAlpha, endAlpha, fadeInPos, fadeOutPos, spec, testAreas, minWidthNorm, maxWidthNorm, startAlpha, endAlpha, fadeInPos, fadeOutPos, _, object, isActive
function CombinedEffect:update(dt)
	if self.state == CombinedEffect.STATE_TURNING_ON then
		local v25_ = self.fadeIn + dt * 0.001 / self.fadeDuration
		self.fadeIn = math.min(v25_, 1)
		if self.fadeIn == 1 then
			self.state = CombinedEffect.STATE_ON
		end
	elseif self.state == CombinedEffect.STATE_TURNING_OFF then
		local v26_ = self.fadeIn + dt * 0.001 / self.fadeDuration
		self.fadeIn = math.min(v26_, 1)
		local v27_ = self.fadeOut + dt * 0.001 / self.fadeDuration
		self.fadeOut = math.min(v27_, 1)
		if self.fadeOut == 1 then
			self.state = CombinedEffect.STATE_OFF
		end
	end
	local v28_ = false
	if self.state ~= CombinedEffect.STATE_TURNING_OFF and self.testAreaIndex ~= nil then
		local v29_, v30_, v31_, v32_ = self.parent:getTestAreaWidthByWorkAreaIndex(self.testAreaIndex)
		if v29_ ~= -math.huge and v30_ ~= math.huge then
			for _, v33_ in ipairs(self.effects) do
				if v33_.setMinMaxWidth ~= nil and v33_.testAreaSubIndex == nil then
					v33_:setMinMaxWidth(v29_, v30_, -(v29_ / v31_), -(v30_ / v32_), false)
				end
			end
			v28_ = true
		end
	end
	for _, v34_ in ipairs(self.effects) do
		if v34_:isa(MotionPathEffect) then
			local v35_ = v34_.delay
			local v36_ = v34_.delay + 1 / v34_.effectSpeedScaleOrig * (1 - v34_.minFade)
			local v37_ = MathUtil.inverseLerp(v35_, v36_, self.fadeIn * self.fadeDuration)
			local v38_ = MathUtil.inverseLerp(v35_, v36_, self.fadeOut * self.fadeDuration)
			if v34_.minFade > 0 then
				if v37_ > 0 then
					v37_ = v34_.minFade + v37_ * (1 - v34_.minFade)
				end
				if v38_ > 0 then
					v38_ = v34_.minFade + v38_ * (1 - v34_.minFade)
				end
			end
			v34_.state = MotionPathEffect.STATE_ON
			v34_.fadeIn = v37_
			v34_.fadeOut = v38_
			if v28_ and (v34_:isa(CutterMotionPathEffect) and v34_.testAreaSubIndex ~= nil) then
				local v39_ = self.parent.spec_testAreas.testAreasByWorkAreaIndex[self.testAreaIndex]
				if v39_ ~= nil then
					local v40_, v41_
					if v39_[v34_.testAreaSubIndex] == nil or not v39_[v34_.testAreaSubIndex].hasContact then
						v40_ = 0
						v41_ = 0
					else
						v40_ = 1
						v41_ = 1
					end
					local v42_ = v40_ + 1
					local v43_ = 2 - v41_ + 1
					local v44_ = v34_.minValueDelay:add(v42_)
					local v45_ = v34_.maxValueDelay:add(v43_)
					local v46_ = v44_ - 1
					local v47_ = 2 - v45_ + 1
					v34_.effectMinValue = v46_ * v34_.widthScale - v34_.offset
					v34_.effectMaxValue = v47_ * v34_.widthScale + v34_.offset
				end
			end
			v34_:update(dt)
		elseif v34_:isa(MorphPositionEffect) then
			local v48_ = v34_.startDelay * 0.001
			local v49_ = (v34_.startDelay + v34_.fadeInTime) * 0.001
			local v50_ = MathUtil.inverseLerp(v48_, v49_, self.fadeIn * self.fadeDuration)
			local v51_ = MathUtil.inverseLerp(v48_, v49_, self.fadeOut * self.fadeDuration)
			v34_.fadeCur[1] = v51_
			v34_.fadeCur[2] = v50_
			g_animationManager:setPrevShaderParameter(v34_.node, "morphPos", v34_.fadeCur[1], v34_.fadeCur[2], 1, v34_.speed, false, "prevMorphPos")
			if v34_.scrollUpdate then
				v34_.scrollPosition = (v34_.scrollPosition + dt * v34_.scrollSpeed) % v34_.scrollLength
				setShaderParameter(v34_.node, "offsetUV", v34_.scrollPosition, nil, nil, nil, false)
			end
			setVisibility(v34_.node, self.state ~= CombinedEffect.STATE_OFF)
		end
	end
	if self.objectChanges ~= nil then
		for _, v52_ in ipairs(self.objectChanges) do
			local v53_
			if v52_.fadeTime <= self.fadeIn then
				v53_ = v52_.fadeTime >= self.fadeOut
			else
				v53_ = false
			end
			if v52_.workModeIndex ~= nil then
				if v53_ then
					if self.parent.spec_workMode == nil then
						v53_ = false
					else
						v53_ = self.parent.spec_workMode.state == v52_.workModeIndex
					end
				end
			end
			if v53_ ~= v52_.isActive then
				v52_.isActive = v53_
				ObjectChangeUtil.setObjectChange(v52_, v53_, self.parent, self.parent.setMovingToolDirty, false)
			end
		end
	end
end

function CombinedEffect:isRunning()
	return self.state ~= CombinedEffect.STATE_OFF
end

function CombinedEffect:start()
	if self.state ~= CombinedEffect.STATE_ON and self.state ~= CombinedEffect.STATE_TURNING_ON then
		self.state = CombinedEffect.STATE_TURNING_ON
		if self.fadeOut > 0.5 then
			self.fadeIn = 0
		end
		self.fadeOut = 0
	end
	return true
end

function CombinedEffect:stop()
	if self.state == CombinedEffect.STATE_ON or self.state == CombinedEffect.STATE_TURNING_ON then
		self.state = CombinedEffect.STATE_TURNING_OFF
	end
	return true
end

function CombinedEffect:reset()
	self.state = CombinedEffect.STATE_OFF
	self.fadeIn = 0
	self.fadeOut = 0
end

-- Local values: _, effect, i, effect
function CombinedEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
	for _, v62_ in ipairs(self.effects) do
		if v62_.setEffectTypeInfo ~= nil then
			v62_:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
		end
	end
	self.fadeDuration = 0
	for _, v63_ in ipairs(self.effects) do
		if v63_:isa(MotionPathEffect) then
			local v64_ = v63_.delay + 1 / v63_.effectSpeedScaleOrig
			local v65_ = self.fadeDuration
			self.fadeDuration = math.max(v64_, v65_)
		elseif v63_:isa(MorphPositionEffect) then
			local v66_ = (v63_.startDelay + v63_.fadeInTime) * 0.001
			local v67_ = self.fadeDuration
			self.fadeDuration = math.max(v66_, v67_)
		end
	end
	return true
end

-- Local values: _, effect
function CombinedEffect:setDistance(distance)
	for _, v70_ in ipairs(self.effects) do
		if v70_.setDistance ~= nil then
			v70_:setDistance(distance)
		end
	end
	return true
end

function CombinedEffect:getIsVisible()
	return self.state ~= CombinedEffect.STATE_OFF
end

function CombinedEffect:getIsFullyVisible()
	local v73_
	if self.state == CombinedEffect.STATE_OFF then
		v73_ = false
	else
		v73_ = self.fadeIn == 1
	end
	return v73_
end

-- Local values: _, effect
function CombinedEffect:setDensity(density)
	for _, v76_ in ipairs(self.effects) do
		if v76_.setDensity ~= nil then
			v76_:setDensity(density)
		end
	end
end

function CombinedEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#testAreaIndex", "Index of work area which contains a test area to be used")
	schema:register(XMLValueType.STRING, basePath .. ".effectNode(?)#effectClass", "Effect class", "ShaderPlaneEffect")
	schema:register(XMLValueType.INT, basePath .. ".effectNode(?)#testAreaSubIndex", "Defines which test index of the test area should be used for this sub effect")
	Effect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ExhaustEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	LevelerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MorphPositionEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ParticleEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PipeEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	GrainTankEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#fadeTime", "Fade time which activated the object change", 0)
	schema:register(XMLValueType.INT, basePath .. ".objectChange(?)#workModeIndex", "Index of current work mode to activate it")
end
g_effectManager:registerEffectClass("CombinedEffect", CombinedEffect)
