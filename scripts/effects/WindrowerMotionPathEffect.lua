-- Local values: WindrowerMotionPathEffect_mt
WindrowerMotionPathEffect = {}
local WindrowerMotionPathEffect_mt = Class(WindrowerMotionPathEffect, TypedMotionPathEffect)

-- Upvalues: WindrowerMotionPathEffect_mt
-- Local values: self
function WindrowerMotionPathEffect.new(customMt)
	-- upvalues: (copy) WindrowerMotionPathEffect_mt
	local v3_ = TypedMotionPathEffect.new(customMt or WindrowerMotionPathEffect_mt)
	v3_.workArea = nil
	v3_.hasTestAreas = false
	v3_.isLeft = false
	v3_.windrowerStartFade = 0.2
	v3_.windrowerEndFade = 0.8
	v3_.windrowerFadeLength = v3_.windrowerEndFade - v3_.windrowerStartFade
	return v3_
end

function WindrowerMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not WindrowerMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.isPickup = xmlFile:getValue(key .. ".motionPathEffect#isPickup", false)
	self.isLeft = xmlFile:getValue(key .. ".motionPathEffect#isLeft", self.isLeft)
	self.minFadeOrig = self.minFade
	self.windrowerStartFade = xmlFile:getValue(key .. ".motionPathEffect#startFade", 0.2)
	self.windrowerEndFade = xmlFile:getValue(key .. ".motionPathEffect#endFade", 0.8)
	self.windrowerFadeLength = self.windrowerEndFade - self.windrowerStartFade
	return true
end

-- Local values: currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX, fadePos, newFade, dir, min, max
function WindrowerMotionPathEffect:update(dt)
	if self.workArea == nil and self.workAreaIndex ~= nil then
		self.workArea = self.parent:getWorkAreaByIndex(self.workAreaIndex)
		local v12_
		if self.workArea == nil then
			v12_ = false
		else
			v12_ = self.workArea.hasTestAreas
		end
		self.hasTestAreas = v12_
	end
	if self.workArea ~= nil and self.hasTestAreas then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local v13_, v14_, v15_, v16_ = self.parent:getTestAreaWidthByWorkAreaIndex(self.workAreaIndex)
			if self.isPickup then
				if v13_ ~= -math.huge and v14_ ~= math.huge then
					if self.isLeft then
						self.fadeVisibilityMin = 0.5 + v13_ / v16_ * 0.5
						self.fadeVisibilityMax = 1 - (0.5 + v14_ / v15_ * 0.5)
					else
						self.fadeVisibilityMin = 0.5 + v14_ / v15_ * 0.5
						self.fadeVisibilityMax = 1 - (0.5 + v13_ / v16_ * 0.5)
					end
				end
			else
				local v17_
				if v13_ == -math.huge or v14_ == math.huge then
					v17_ = 1
				elseif self.isLeft then
					v17_ = 1 - (v13_ - v15_) / (v16_ - v15_)
				else
					v17_ = (v14_ - v15_) / (v16_ - v15_)
				end
				local v18_ = v17_ * self.windrowerFadeLength + self.windrowerStartFade
				local v19_ = v17_ <= 0.01 and 0 or (v17_ >= 0.99 and 1 or v18_)
				local v20_ = v19_ - self.fadeOut
				local v21_ = math.sign(v20_)
				local v22_, v23_
				if v21_ < 0 then
					v22_ = v19_
					v23_ = 1
				else
					v23_ = v19_
					v22_ = 0
				end
				local v24_ = self.fadeOut + dt * 0.001 * self.effectSpeedScale * v21_
				self.fadeOut = math.clamp(v24_, v22_, v23_)
				local v25_ = self.minFade
				local v26_ = self.fadeOut
				self.minFade = math.min(v25_, v26_)
				if self.immediateUpdate then
					self.fadeOut = v19_
					self.minFade = v19_
					self.immediateUpdate = false
				end
			end
		else
			self.immediateUpdate = true
			self.minFade = self.minFadeOrig
		end
	end
	WindrowerMotionPathEffect:superClass().update(self, dt)
end

function WindrowerMotionPathEffect:setWorkAreaIndex(workAreaIndex)
	self.workAreaIndex = workAreaIndex
end

function WindrowerMotionPathEffect:stop()
	return WindrowerMotionPathEffect:superClass().stop(self)
end

function WindrowerMotionPathEffect:reset()
	return WindrowerMotionPathEffect:superClass().reset(self)
end

function WindrowerMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function WindrowerMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function WindrowerMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function WindrowerMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function WindrowerMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function WindrowerMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isPickup", "(WindrowerMotionPathEffect) Defines if the effect is a pickup effect and width is adjusted by hiding rows instead of the fade value", false)
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isLeft", "(WindrowerMotionPathEffect) Defines if rake is mounted on left or right side", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#startFade", "(WindrowerMotionPathEffect) Start of fading depending on test area result", 0.2)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#endFade", "(WindrowerMotionPathEffect) End of fading depending on test area result", 0.8)
end
