-- Local values: ExhaustEffect_mt
ExhaustEffect = {}
local ExhaustEffect_mt = Class(ExhaustEffect, Effect)

-- Upvalues: ExhaustEffect_mt
-- Local values: self
function ExhaustEffect.new(customMt)
	-- upvalues: (copy) ExhaustEffect_mt
	return Effect.new(customMt or ExhaustEffect_mt)
end

function ExhaustEffect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
	if ExhaustEffect:superClass().load(self, xmlFile, baseName, rootNodes, parent, i3dMapping) == nil then
		return nil
	end
	self.minRpmColor = xmlFile:getValue(baseName .. "#minRpmColor", "0 0 0 1", true)
	self.maxRpmColor = xmlFile:getValue(baseName .. "#maxRpmColor", "0.0384 0.0359 0.0627 2.0", true)
	self.minRpmScale = xmlFile:getValue(baseName .. "#minRpmScale", 0.25)
	self.maxRpmScale = xmlFile:getValue(baseName .. "#maxRpmScale", 0.95)
	self.upFactor = xmlFile:getValue(baseName .. "#upFactor", 0.75)
	self.lastPosition = nil
	self.xRot = 0
	self.zRot = 0
	self.isActive = false
	self.lastRpmScale = 0
	return self
end

function ExhaustEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	return (xmlFile == nil or not entityExists(xmlFile.handle)) and true or ExhaustEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping)
end

function ExhaustEffect:transformEffectNode(xmlFile, key, node)
	return (xmlFile == nil or not entityExists(xmlFile.handle)) and true or ExhaustEffect:superClass().transformEffectNode(self, xmlFile, key, node)
end

-- Local values: posX, posY, posZ, vx, vy, vz, ex, ey, ez, lx, ly, lz, distance, xFactor, yFactor, xRot, zRot, scale, r, g, b, a
function ExhaustEffect:update(dt)
	ExhaustEffect:superClass().update(self, dt)
	if self.isActive then
		local v21_, v22_, v23_ = localToWorld(self.node, 0, 0.5, 0)
		if self.lastPosition == nil then
			self.lastPosition = { v21_, v22_, v23_ }
		end
		local v24_ = (v21_ - self.lastPosition[1]) * 10
		local v25_ = (v22_ - self.lastPosition[2]) * 10
		local v26_ = (v23_ - self.lastPosition[3]) * 10
		local v27_, v28_, v29_ = localToWorld(self.node, 0, 1, 0)
		local v30_ = v27_ - v24_
		local v31_ = v28_ - v25_ + self.upFactor
		local v32_ = v29_ - v26_
		local v33_, v34_, v35_ = worldToLocal(self.node, v30_, v31_, v32_)
		local v36_ = MathUtil.vector2Length(v33_, v35_)
		local v37_, v38_ = MathUtil.vector2Normalize(v33_, v35_)
		local v39_ = math.max(v34_, 0.01)
		local v40_ = math.abs(v39_)
		local v41_ = v36_ / v40_
		local v42_ = math.atan(v41_) * (1.2 + 2 * v40_)
		local v43_ = v36_ / v40_
		local v44_ = math.atan(v43_) * (1.2 + 2 * v40_)
		local v45_ = v38_ / v40_
		local v46_ = math.atan(v45_) * v42_
		local v47_ = v37_ / v40_
		local v48_ = -math.atan(v47_) * v44_
		self.xRot = self.xRot * 0.95 + v46_ * 0.05
		self.zRot = self.zRot * 0.95 + v48_ * 0.05
		local v49_ = MathUtil.lerp(self.minRpmScale, self.maxRpmScale, self.lastRpmScale)
		setShaderParameter(self.node, "param", self.xRot, self.zRot, 0, v49_, false)
		local v50_ = MathUtil.lerp(self.minRpmColor[1], self.maxRpmColor[1], self.lastRpmScale)
		local v51_ = MathUtil.lerp(self.minRpmColor[2], self.maxRpmColor[2], self.lastRpmScale)
		local v52_ = MathUtil.lerp(self.minRpmColor[3], self.maxRpmColor[3], self.lastRpmScale)
		local v53_ = MathUtil.lerp(self.minRpmColor[4], self.maxRpmColor[4], self.lastRpmScale)
		setShaderParameter(self.node, "exhaustColor", v50_, v51_, v52_, v53_, false)
		self.lastPosition[1] = v21_
		self.lastPosition[2] = v22_
		self.lastPosition[3] = v23_
	end
end

function ExhaustEffect:isRunning()
	return self.isActive
end

-- Local values: color
function ExhaustEffect:start()
	self.isActive = true
	setVisibility(self.node, self.isActive)
	setShaderParameter(self.node, "param", self.xRot, self.zRot, 0, 0, false)
	local v56_ = self.minRpmColor
	setShaderParameter(self.node, "exhaustColor", v56_[1], v56_[2], v56_[3], v56_[4], false)
	return true
end

function ExhaustEffect:stop()
	self.isActive = false
	setVisibility(self.node, self.isActive)
	return true
end

function ExhaustEffect:reset() end

function ExhaustEffect:setFillType(fillType, force)
	return true
end

function ExhaustEffect:getIsVisible()
	return self.isActive
end

function ExhaustEffect:getIsFullyVisible()
	return self.isActive
end

function ExhaustEffect:setDensity(density)
	self.lastRpmScale = density
end

function ExhaustEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_4, basePath .. "#minRpmColor", "Min. rpm color", "0 0 0 1")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#maxRpmColor", "Max. rpm color", "0.0384 0.0359 0.0627 2.0")
	schema:register(XMLValueType.FLOAT, basePath .. "#minRpmScale", "Min. rpm scale", 0.25)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxRpmScale", "Max. rpm scale", 0.95)
	schema:register(XMLValueType.FLOAT, basePath .. "#upFactor", "Defines how far the effect goes up in the air in meter", 0.75)
end
g_effectManager:registerEffectClass("ExhaustEffect", ExhaustEffect)
