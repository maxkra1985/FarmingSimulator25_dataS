-- Local values: CutterMotionPathEffect_mt
CutterMotionPathEffect = {}
CutterMotionPathEffect.DEFAULT_FOLIAGE_CLIP_DISTANCE = 80
local CutterMotionPathEffect_mt = Class(CutterMotionPathEffect, TypedMotionPathEffect)

-- Upvalues: CutterMotionPathEffect_mt
-- Local values: self
function CutterMotionPathEffect.new(customMt)
	-- upvalues: (copy) CutterMotionPathEffect_mt
	local v3_ = TypedMotionPathEffect.new(customMt or CutterMotionPathEffect_mt)
	v3_.minValue = 0
	v3_.maxValue = 0
	v3_.minValueDelay = ValueDelay.new(400, -1)
	v3_.maxValueDelay = ValueDelay.new(400, -1)
	v3_.effectMinValue = 0
	v3_.effectMaxValue = 0
	return v3_
end

-- Local values: _, linkNode
function CutterMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not CutterMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.useMaxValue = xmlFile:getValue(key .. "#useMaxValue", false)
	self.widthScale = xmlFile:getValue(key .. "#widthScale", 1)
	self.offset = xmlFile:getValue(key .. "#offset", 0)
	self.minOffset = xmlFile:getValue(key .. "#minOffset", 0)
	self.maxOffset = xmlFile:getValue(key .. "#maxOffset", 0)
	self.minDensity = xmlFile:getValue(key .. "#minDensity", 0.25)
	self.maxDensitySpeed = xmlFile:getValue(key .. "#maxDensitySpeed", 8)
	for _, v10_ in ipairs(self.linkNodes) do
		setClipDistance(v10_, CutterMotionPathEffect.DEFAULT_FOLIAGE_CLIP_DISTANCE * getFoliageViewDistanceCoeff())
	end
	return true
end

-- Local values: _, effectNode, minValue, maxValue, speed, density
function CutterMotionPathEffect:update(dt)
	CutterMotionPathEffect:superClass().update(self, dt)
	for _, v13_ in ipairs(self.currentEffectNodes) do
		local v14_ = 0.5 - (self.minOffset + self.effectMinValue) * 0.5
		local v15_ = 0.5 + (self.maxOffset + self.effectMaxValue) * 0.5
		setShaderParameterRecursive(v13_, "fadeProgress", self.fadeIn, self.fadeOut, v15_, v14_, false)
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local v16_ = self.parent:getLastSpeed() / self.maxDensitySpeed
			self:setDensity(math.min(v16_, 1) * (1 - self.minDensity) + self.minDensity)
		end
	end
end

function CutterMotionPathEffect:stop()
	self.minValueDelay:reset()
	self.maxValueDelay:reset()
	return CutterMotionPathEffect:superClass().stop(self)
end

function CutterMotionPathEffect:reset()
	self.effectMinValue = 0
	self.effectMaxValue = 0
	return CutterMotionPathEffect:superClass().reset(self)
end

function CutterMotionPathEffect:setMinMaxWidth(minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
	if minWidthNorm == 0 and maxWidthNorm == 0 then
		self.minValueDelay:reset()
		self.maxValueDelay:reset()
	else
		if self.textureRealWidth ~= nil then
			minWidthNorm = -minWidth / self.textureRealWidth * 2
			maxWidthNorm = maxWidth / self.textureRealWidth * 2
		end
		local v24_ = minWidthNorm + 1
		local v25_ = 2 - maxWidthNorm + 1
		local v26_ = self.minValueDelay:add(v24_)
		local v27_ = self.maxValueDelay:add(v25_)
		local v28_ = v26_ - 1
		local v29_ = 2 - v27_ + 1
		self.effectMinValue = v28_ * self.widthScale - self.offset
		self.effectMaxValue = v29_ * self.widthScale + self.offset
	end
end

function CutterMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function CutterMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function CutterMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function CutterMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function CutterMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function CutterMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#useMaxValue", "(CutterMotionPathEffect) Use max width of effect", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#widthScale", "(CutterMotionPathEffect) Width scale (Percentage)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#offset", "(CutterMotionPathEffect) Width offset (Percentage)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#minOffset", "(CutterMotionPathEffect) Width offset in min direction", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxOffset", "(CutterMotionPathEffect) Width offset in max direction", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#minDensity", "(CutterMotionPathEffect) Min. Density", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxDensitySpeed", "(CutterMotionPathEffect) Speed at which the density is 1", 8)
end
