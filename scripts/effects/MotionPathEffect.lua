-- Local values: MotionPathEffect_mt
MotionPathEffect = {}
local MotionPathEffect_mt = Class(MotionPathEffect, Effect)
MotionPathEffect.STATE_OFF = 0
MotionPathEffect.STATE_TURNING_ON = 1
MotionPathEffect.STATE_ON = 2
MotionPathEffect.STATE_TURNING_OFF = 3
MotionPathEffect.DEFAULT_CLIP_DISTANCE = 150

-- Upvalues: MotionPathEffect_mt
-- Local values: self
function MotionPathEffect.new(customMt)
	-- upvalues: (copy) MotionPathEffect_mt
	local v3_ = Effect.new(customMt or MotionPathEffect_mt)
	v3_.state = MotionPathEffect.STATE_OFF
	v3_.fadeIn = 0
	v3_.fadeOut = 0
	v3_.numRows = 0
	v3_.rowLength = 0
	v3_.lastSharedEffect = nil
	v3_.lastSharedEffectMesh = nil
	v3_.lastSharedEffectMaterial = nil
	v3_.currentEffectNodes = {}
	v3_.hasCurrentEffectNodes = false
	v3_.lastDensity = 0
	v3_.lastDensityReal = 1
	v3_.lastDensityDelay = ValueDelay.new(750, -1)
	v3_.effectDensityScale = 1
	v3_.pathPosition = 0
	v3_.lastPathPosition = 0
	v3_.useVehicleSpeed = false
	v3_.motionPathEffectManager = g_motionPathEffectManager
	return v3_
end

-- Local values: i
function MotionPathEffect:delete()
	if self.hasCurrentEffectNodes then
		for v5_ = #self.currentEffectNodes, 1, -1 do
			delete(self.currentEffectNodes[v5_])
			self.currentEffectNodes[v5_] = nil
		end
		self.hasCurrentEffectNodes = false
	end
	if self.texture ~= nil then
		delete(self.texture)
		self.texture = nil
	end
	if self.densityMask ~= nil then
		delete(self.densityMask)
		self.densityMask = nil
	end
	MotionPathEffect:superClass().delete(self)
end

-- Local values: _, linkNodeKey, linkNode, linkNode, speedFuncStr
function MotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#lengthAndRadius")
	self.linkNodes = {}
	for _, v11_ in xmlFile:iterator(key .. ".linkNode") do
		local v12_ = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), xmlFile:getValue(v11_ .. "#node"), i3dMapping)
		if v12_ ~= nil then
			local v13_ = self.linkNodes
			table.insert(v13_, v12_)
		end
	end
	local v14_ = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), xmlFile:getValue(key .. "#linkNode"), i3dMapping)
	if v14_ ~= nil then
		local v15_ = self.linkNodes
		table.insert(v15_, v14_)
	end
	if #self.linkNodes == 0 then
		Logging.xmlError(xmlFile, "Missing linkNode in \'%s\'", key)
		return false
	end
	self.effectNode = self.linkNodes[1]
	self.effectType = xmlFile:getValue(key .. "#effectType", "DEFAULT"):upper()
	self.textureFilename = xmlFile:getValue(key .. ".motionPathEffect#textureFilename")
	if self.textureFilename == nil then
		Logging.xmlError(xmlFile, "No texture defined for motion path effect \'%s\'. Please update effects to new motion path effect system.", key)
		return false
	end
	self.textureFilename = Utils.getFilename(self.textureFilename, self.baseDirectory)
	self.texture = createMaterialTextureFromFile(self.textureFilename, true, false)
	if self.texture == 0 then
		self.texture = nil
		return false
	end
	if g_currentMission.vehicleSystem.isReloadRunning then
		reloadResource(self.textureFilename)
	end
	self.textureRealWidth = xmlFile:getValue(key .. ".motionPathEffect#textureRealWidth")
	self.numRows = xmlFile:getValue(key .. ".motionPathEffect#numRows", 12)
	self.rowLength = xmlFile:getValue(key .. ".motionPathEffect#rowLength", 30)
	self.useVehicleSpeed = xmlFile:getValue(key .. ".motionPathEffect#useVehicleSpeed", self.useVehicleSpeed)
	self.maxReferenceVehicleSpeed = xmlFile:getValue(key .. ".motionPathEffect#maxReferenceVehicleSpeed", 10)
	self.speedScale = xmlFile:getValue(key .. ".motionPathEffect#speedScale")
	self.effectSpeedScale = self.speedScale or 1
	self.effectSpeedScaleOrig = self.speedScale or 1
	self.verticalOffset = xmlFile:getValue(key .. ".motionPathEffect#verticalOffset")
	self.shapeScale = xmlFile:getValue(key .. ".motionPathEffect#shapeScale")
	self.maxShapeScale = xmlFile:getValue(key .. ".motionPathEffect#maxShapeScale")
	self.fadeOutScale = xmlFile:getValue(key .. ".motionPathEffect#fadeOutScale", 1)
	self.minFade = xmlFile:getValue(key .. ".motionPathEffect#minFade", 0)
	self.inversedFadeOut = xmlFile:getValue(key .. ".motionPathEffect#inversedFadeOut", false)
	self.scrollLength = xmlFile:getValue(key .. ".motionPathEffect#scrollLength", 1)
	self.delay = xmlFile:getValue(key .. ".motionPathEffect#delay", 0)
	self.startDelay = xmlFile:getValue(key .. ".motionPathEffect#startDelay", self.delay) * 1000
	self.stopDelay = xmlFile:getValue(key .. ".motionPathEffect#stopDelay", self.delay) * 1000
	self.effectDensityScaleSetting = xmlFile:getValue(key .. ".motionPathEffect#density", 1)
	self.densityMaskFilename = xmlFile:getValue(key .. ".motionPathEffect#densityMaskFilename")
	if self.densityMaskFilename ~= nil then
		self.densityMaskFilename = Utils.getFilename(self.densityMaskFilename, self.baseDirectory)
		self.densityMask = createMaterialTextureFromFile(self.densityMaskFilename, true, false)
		if self.densityMask == 0 then
			self.densityMask = nil
		end
	end
	self.speedReferenceAnimation = xmlFile:getValue(key .. ".motionPathEffect#speedReferenceAnimation")
	self.speedReferenceAnimationOffset = xmlFile:getValue(key .. ".motionPathEffect#speedReferenceAnimationOffset", 0)
	self.visibilityX = xmlFile:getValue(key .. ".motionPathEffect#visibilityX", "50 -50", true)
	self.visibilityY = xmlFile:getValue(key .. ".motionPathEffect#visibilityY", "50 -50", true)
	self.visibilityZ = xmlFile:getValue(key .. ".motionPathEffect#visibilityZ", "50 -50", true)
	self.currentStartDelay = 0
	self.currentStopDelay = 0
	self.fadeIn = self.minFade
	self.fadeOut = self.minFade
	self.fadeVisibilityMin = xmlFile:getValue(key .. ".motionPathEffect#fadeVisibilityMin", 1)
	self.fadeVisibilityMax = xmlFile:getValue(key .. ".motionPathEffect#fadeVisibilityMax", 0)
	local v16_ = xmlFile:getValue(key .. ".motionPathEffect#speedFunc")
	if v16_ ~= nil then
		if self.parent[v16_] == nil then
			Logging.xmlWarning(xmlFile, "Could not find speed function \'%s\' for rotation animation \'%s\'!", v16_, key)
		else
			self.speedFunc = self.parent[v16_]
			self.speedFuncParam = xmlFile:getValue(key .. ".motionPathEffect#speedFuncParam")
		end
	end
	return true
end

function MotionPathEffect:transformEffectNode(xmlFile, key, node)
	if self.node ~= nil then
		MotionPathEffect:superClass().transformEffectNode(self, xmlFile, key, node)
		setVisibility(self.node, true)
	end
end

-- Local values: speedScale, effectSpeed, finished, _, effectNode
function MotionPathEffect:update(dt)
	if self.useVehicleSpeed then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local v23_ = self.effectSpeedScaleOrig
			local v24_ = self.parent:getLastSpeed() / self.maxReferenceVehicleSpeed
			self.effectSpeedScale = v23_ * math.clamp(v24_, 0, 1)
		else
			self.effectSpeedScale = self.effectSpeedScaleOrig
			if self.inversedFadeOut then
				self.effectSpeedScale = -self.effectSpeedScale
			end
		end
	elseif self.speedFunc ~= nil then
		local v25_ = self.speedFunc(self.parent, self.speedFuncParam)
		if v25_ == nil then
			self.effectSpeedScale = self.effectSpeedScaleOrig
		else
			self.effectSpeedScale = self.effectSpeedScaleOrig * v25_
		end
	end
	local v26_ = self.effectSpeedScale
	if self.state == MotionPathEffect.STATE_TURNING_OFF then
		v26_ = v26_ * self.fadeOutScale
	end
	self.pathPosition = (self.pathPosition + dt * 0.001 * v26_) % self.scrollLength
	if self.speedReferenceAnimation ~= nil then
		self.pathPosition = self.parent:getAnimationTime(self.speedReferenceAnimation) + self.speedReferenceAnimationOffset
	end
	if self.state == MotionPathEffect.STATE_TURNING_ON then
		local v27_ = self.currentStartDelay - dt
		self.currentStartDelay = math.max(v27_, 0)
		if self.currentStartDelay == 0 then
			local v28_ = self.fadeIn + dt * 0.001 * v26_
			local v29_ = self.minFade
			self.fadeIn = math.clamp(v28_, v29_, 1)
			self.fadeOut = self.minFade
			if self.fadeIn == 1 then
				self.state = MotionPathEffect.STATE_ON
				if self.currentStopDelay > 0 then
					self.state = MotionPathEffect.STATE_TURNING_OFF
				end
			end
		end
	end
	if self.state == MotionPathEffect.STATE_TURNING_OFF then
		local v30_ = self.currentStopDelay - dt
		self.currentStopDelay = math.max(v30_, 0)
		if self.currentStopDelay == 0 then
			local v31_ = false
			local v32_
			if self.inversedFadeOut then
				local v33_ = self.fadeIn - dt * 0.001 * math.abs(v26_)
				local v34_ = self.minFade
				self.fadeIn = math.clamp(v33_, v34_, 1)
				self.fadeOut = self.minFade
				v32_ = self.fadeIn == self.minFade and true or v31_
			else
				local v35_ = self.fadeIn + dt * 0.001 * v26_
				local v36_ = self.minFade
				self.fadeIn = math.clamp(v35_, v36_, 1)
				local v37_ = self.fadeOut + dt * 0.001 * v26_
				local v38_ = self.minFade
				self.fadeOut = math.clamp(v37_, v38_, 1)
				v32_ = self.fadeOut == 1 and true or v31_
			end
			if v32_ then
				self.fadeIn = self.minFade
				self.fadeOut = self.minFade
				self.state = MotionPathEffect.STATE_OFF
			end
		end
	end
	if self.hasCurrentEffectNodes then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			self.lastDensity = self.lastDensityDelay:add(self.lastDensityReal)
		else
			self.lastDensityDelay:reset()
		end
		for _, v39_ in ipairs(self.currentEffectNodes) do
			setShaderParameterRecursive(v39_, "fadeProgress", self.fadeIn, self.fadeOut, self.fadeVisibilityMin, self.fadeVisibilityMax, false)
			setShaderParameterRecursive(v39_, "density", self.lastDensity * self.effectDensityScale * self.effectDensityScaleSetting, nil, nil, nil, false)
			setShaderParameterRecursive(v39_, "scrollPos", self.pathPosition, nil, nil, nil, false)
			setShaderParameterRecursive(v39_, "prevScrollPos", self.lastPathPosition, nil, nil, nil, false)
			setVisibility(v39_, self.fadeIn ~= self.minFade and true or self.fadeOut ~= self.minFade)
		end
		self.lastPathPosition = self.pathPosition
	end
end

function MotionPathEffect:isRunning()
	return self.state ~= MotionPathEffect.STATE_OFF
end

function MotionPathEffect:start()
	if self.state == MotionPathEffect.STATE_OFF or self.state == MotionPathEffect.STATE_TURNING_OFF then
		self.state = MotionPathEffect.STATE_TURNING_ON
		if not self.hasCurrentEffectNodes then
			self:loadSharedMotionPathEffect()
		end
		if self.fadeOut > 0.5 then
			self.fadeIn = self.minFade
		end
		self.currentStartDelay = self.startDelay
	end
	self.currentStopDelay = 0
	return true
end

function MotionPathEffect:stop()
	if self.state == MotionPathEffect.STATE_ON or self.state == MotionPathEffect.STATE_TURNING_ON then
		if self.currentStartDelay <= 0 then
			self.state = MotionPathEffect.STATE_TURNING_OFF
			self.currentStopDelay = self.stopDelay
		else
			local v43_ = self.stopDelay - self.currentStartDelay
			self.currentStopDelay = math.max(v43_, 0.001)
		end
	end
	return true
end

-- Local values: _, effectNode
function MotionPathEffect:reset()
	self.fadeIn = self.minFade
	self.fadeOut = self.minFade
	for _, v45_ in ipairs(self.currentEffectNodes) do
		setVisibility(v45_, false)
	end
end

function MotionPathEffect:getIsVisible()
	return self.fadeIn > self.minFade
end

function MotionPathEffect:getIsFullyVisible()
	return self.fadeIn == 1
end

function MotionPathEffect:setDensity(density)
	self.lastDensityReal = density
end

-- Local values: i
function MotionPathEffect:getIsSharedEffectMatching(sharedEffect, alternativeCheck)
	for v52_ = 1, #sharedEffect.effectTypes do
		if sharedEffect.effectTypes[v52_] == self.effectType then
			return true
		end
	end
	return false
end

function MotionPathEffect:getIsEffectMeshMatching(effectMesh, alternativeCheck)
	return effectMesh.rowLength == self.rowLength and effectMesh.numRows == self.numRows
end

function MotionPathEffect:getIsEffectMaterialMatching(effectMaterial, alternativeCheck)
	return true
end

function MotionPathEffect:getEffectMatchingString()
	return string.format("Class: \'%s\', numRows: %d, rowLength: %d", ClassUtil.getClassName(self:class()), self.numRows, self.rowLength)
end

-- Local values: sharedEffect, effectMesh, i, sourceNode, allUsed, defaultIndex, indexToUse, i, i, i, numChildren, _, linkNode, effectNode, effectMaterial, _, effectNode, i, _, effectNode, i
function MotionPathEffect:loadSharedMotionPathEffect()
	local v57_ = self.motionPathEffectManager:getSharedMotionPathEffect(self)
	if v57_ == nil then
		Logging.error("Could not find motion path effect for settings (%s)", self:getEffectMatchingString())
		if self.hasCurrentEffectNodes then
			for v58_ = #self.currentEffectNodes, 1, -1 do
				delete(self.currentEffectNodes[v58_])
				self.currentEffectNodes[v58_] = nil
			end
			self.hasCurrentEffectNodes = false
		end
	else
		if v57_ ~= self.lastSharedEffect then
			self.lastSharedEffect = v57_
		end
		self.effectDensityScale = v57_.densityScale or 1
		local v59_ = self.motionPathEffectManager:getMotionPathEffectMesh(v57_, self)
		if v59_ == nil then
			Logging.error("Could not find motion path effect mesh for settings (%s)", self:getEffectMatchingString())
			if self.hasCurrentEffectNodes then
				for v60_ = #self.currentEffectNodes, 1, -1 do
					delete(self.currentEffectNodes[v60_])
					self.currentEffectNodes[v60_] = nil
				end
				self.hasCurrentEffectNodes = false
			end
		else
			if v59_ ~= self.lastSharedEffectMesh or not self.hasCurrentEffectNodes then
				for v61_ = #self.currentEffectNodes, 1, -1 do
					delete(self.currentEffectNodes[v61_])
					self.currentEffectNodes[v61_] = nil
				end
				local v62_ = v59_.node
				if v59_.numVariations > 1 then
					local v63_ = nil
					local v64_ = 1
					local v65_ = true
					for v66_ = 1, v59_.numVariations do
						if not v59_.usedVariations[v66_] then
							if math.random(0, 100) > 75 then
								v59_.usedVariations[v66_] = true
								v63_ = v66_
							else
								v64_ = v66_
								v65_ = false
							end
						end
					end
					if v63_ == nil then
						v59_.usedVariations[v64_] = true
						if not v65_ then
							v65_ = true
							for v67_ = 1, v59_.numVariations do
								if not v59_.usedVariations[v67_] then
									v65_ = false
								end
							end
						end
					end
					if v65_ then
						for v68_ = 1, v59_.numVariations do
							v59_.usedVariations[v68_] = false
						end
					end
					if getNumOfChildren(v62_) > 0 then
						v62_ = getChildAt(v62_, (v63_ or (v64_ or 1)) - 1)
					end
				end
				for _, v69_ in ipairs(self.linkNodes) do
					local v70_ = clone(v62_, false, false, true)
					link(v69_, v70_)
					setVisibility(v70_, self.fadeIn ~= self.minFade and true or self.fadeOut ~= self.minFade)
					setClipDistance(v70_, MotionPathEffect.DEFAULT_CLIP_DISTANCE)
					local v71_ = self.currentEffectNodes
					table.insert(v71_, v70_)
				end
				self.hasCurrentEffectNodes = true
				self.currentEffectNode = self.currentEffectNodes[1]
				self.lastSharedEffectMesh = v59_
			end
			self.effectDensityScale = v59_.densityScale or self.effectDensityScale
			local v72_ = self.motionPathEffectManager:getMotionPathEffectMaterial(v57_, self)
			if v72_ ~= nil then
				for _, v73_ in ipairs(self.currentEffectNodes) do
					self.motionPathEffectManager:setEffectMaterial(v73_, v72_)
				end
				self.effectDensityScale = v72_.densityScale or self.effectDensityScale
				self.lastSharedEffectMaterial = v72_
			end
		end
		self.effectSpeedScale = self.motionPathEffectManager:applyEffectConfiguration(v57_, v59_, self.lastSharedEffectMaterial, self.currentEffectNodes, self.texture, self.speedScale)
		self.effectSpeedScaleOrig = self.effectSpeedScale
		for _, v74_ in ipairs(self.currentEffectNodes) do
			if self.verticalOffset ~= nil then
				setShaderParameterRecursive(v74_, "verticalOffset", self.verticalOffset, 0, 0, 0, false)
			end
			if self.shapeScale ~= nil then
				setShaderParameterRecursive(v74_, "sizeScale", self.shapeScale, nil, nil, nil, false)
			end
			if self.maxShapeScale ~= nil then
				setShaderParameterRecursive(v74_, "sizeScale", nil, self.maxShapeScale, nil, nil, false)
			end
			if self.visibilityX ~= nil and #self.visibilityX == 2 then
				setShaderParameterRecursive(v74_, "visibilityX", self.visibilityX[1], self.visibilityX[2], nil, nil, false)
			end
			if self.visibilityY ~= nil and #self.visibilityY == 2 then
				setShaderParameterRecursive(v74_, "visibilityY", self.visibilityY[1], self.visibilityY[2], nil, nil, false)
			end
			if self.visibilityZ ~= nil and #self.visibilityZ == 2 then
				setShaderParameterRecursive(v74_, "visibilityZ", self.visibilityZ[1], self.visibilityZ[2], nil, nil, false)
			end
			if self.densityMask ~= nil then
				self.motionPathEffectManager:setEffectCustomMap(v74_, "densityMask", self.densityMask)
			end
			setShaderParameterRecursive(v74_, "speed", 0, 0, nil, nil, false)
			setShaderParameterRecursive(v74_, "randomSeed", math.random() * 10000, nil, nil, nil, false)
		end
	end
end

function MotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	motionPathEffect.speedScale = xmlFile:getValue(key .. "#speedScale")
	motionPathEffect.densityScale = xmlFile:getValue(key .. "#densityScale")
end

function MotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	effectMesh.speedScale = xmlFile:getValue(key .. "#speedScale")
	effectMesh.densityScale = xmlFile:getValue(key .. "#densityScale")
end

function MotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	effectMaterial.speedScale = xmlFile:getValue(key .. "#speedScale")
	effectMaterial.densityScale = xmlFile:getValue(key .. "#densityScale")
end

function MotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed of effect", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#densityScale", "Density of effect", 1)
end

function MotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed of effect", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#densityScale", "Density of effect", 1)
end

function MotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed of effect", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#densityScale", "Density of effect", 1)
end

function MotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#linkNode", "Link node")
	schema:register(XMLValueType.STRING, basePath .. ".linkNode(?)#node", "Link node")
	schema:register(XMLValueType.STRING, basePath .. "#effectType", "(MotionPathEffect) Effect type string")
	schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#textureFilename", "(MotionPathEffect) Animation texture", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#textureRealWidth", "(MotionPathEffect) Real width of effect in meter with this texture")
	schema:register(XMLValueType.INT, basePath .. ".motionPathEffect#numRows", "(MotionPathEffect) Number of rows", 0)
	schema:register(XMLValueType.INT, basePath .. ".motionPathEffect#rowLength", "(MotionPathEffect) Number of plants for each row", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#speedScale", "(MotionPathEffect) Speed scale that is applied to effect speed defined in effect.xml or i3d file")
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#useVehicleSpeed", "(MotionPathEffect) Use speed of vehicle as effect speed")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxReferenceVehicleSpeed", "(MotionPathEffect) This speed represents speed \'1\' for effect", 10)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#verticalOffset", "(MotionPathEffect) Vertical offset of plants")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#shapeScale", "(MotionPathEffect) Scale of single shapes")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxShapeScale", "(MotionPathEffect) Scale of single shapes at the end of the effect")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minFade", "(MotionPathEffect) Defines start fade value", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#fadeOutScale", "(MotionPathEffect) Fade out speed multiplicator", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#inversedFadeOut", "(MotionPathEffect) Using inversed fade in as fade out", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#scrollLength", "(MotionPathEffect) Scroll length to wrap around", 1)
	schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#speedReferenceAnimation", "(MotionPathEffect) This animation will be used for the effect speed")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#speedReferenceAnimationOffset", "(MotionPathEffect) Time offset to apply", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#delay", "(MotionPathEffect) Start and stop delay", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#startDelay", "(MotionPathEffect) Start delay", "value of #delay")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#stopDelay", "(MotionPathEffect) Stop delay", "value of #delay")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#density", "(MotionPathEffect) Density Scale", 1)
	schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#densityMaskFilename", "(MotionPathEffect) Custom Density Mask Texture")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".motionPathEffect#visibilityX", "(MotionPathEffect) Visibility cut size X axis", "50 -50")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".motionPathEffect#visibilityY", "(MotionPathEffect) Visibility cut size Y axis", "50 -50")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".motionPathEffect#visibilityZ", "(MotionPathEffect) Visibility cut size Z axis", "50 -50")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#fadeVisibilityMin", "(MotionPathEffect) Default fade visibility min. value", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#fadeVisibilityMax", "(MotionPathEffect) Default fade visibility max. value", 0)
	schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#speedFunc", "Lua speed function")
	schema:register(XMLValueType.STRING, basePath .. ".motionPathEffect#speedFuncParam", "Additional string parameter that is passed to the speedFunc")
end
