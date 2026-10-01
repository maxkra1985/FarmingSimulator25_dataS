ShaderPlaneEffect = {}
local ShaderPlaneEffect_mt = Class(ShaderPlaneEffect, Effect)
ShaderPlaneEffect.STATE_OFF = 0
ShaderPlaneEffect.STATE_TURNING_ON = 1
ShaderPlaneEffect.STATE_ON = 2
ShaderPlaneEffect.STATE_TURNING_OFF = 3
function ShaderPlaneEffect.new(customMt)
	local self = Effect.new(customMt or ShaderPlaneEffect_mt)
	self.state = ShaderPlaneEffect.STATE_OFF
	self.planeFadeTime = 0
	return self
end
function ShaderPlaneEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not ShaderPlaneEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.fadeInTime = Effect.getValue(xmlFile, key, node, "fadeInTime", Effect.getValue(xmlFile, key, node, "fadeTime", 1)) * 1000
	self.fadeOutTime = Effect.getValue(xmlFile, key, node, "fadeOutTime", Effect.getValue(xmlFile, key, node, "fadeTime", 1)) * 1000
	self.fadeInTime = math.max(self.fadeInTime, 0.01)
	self.fadeOutTime = math.max(self.fadeOutTime, 0.01)
	self.planeFadeTime = math.max(self.planeFadeTime, self.fadeInTime, self.fadeOutTime)
	self.startDelay = Effect.getValue(xmlFile, key, node, "startDelay", Effect.getValue(xmlFile, key, node, "delay", 0)) * 1000
	self.stopDelay = Effect.getValue(xmlFile, key, node, "stopDelay", Effect.getValue(xmlFile, key, node, "delay", 0)) * 1000
	self.currentDelay = self.startDelay
	self.alwaysVisibile = Effect.getValue(xmlFile, key, node, "alwaysVisibile", false)
	self.showOnFirstUse = Effect.getValue(xmlFile, key, node, "showOnFirstUse", false)
	local defaultFillType = Effect.getValue(xmlFile, key, node, "defaultFillType")
	if defaultFillType ~= nil then
		self.defaultFillType = g_fillTypeManager:getFillTypeIndexByName(defaultFillType)
	end
	self.dynamicFillType = Effect.getValue(xmlFile, key, node, "dynamicFillType", true)
	self.materialType = Effect.getValue(xmlFile, key, node, "materialType", "unloading")
	self.materialTypeId = Effect.getValue(xmlFile, key, node, "materialTypeId", 1)
	self.alignToWorldY = Effect.getValue(xmlFile, key, node, "alignToWorldY", false)
	self.alignXAxisToWorldY = Effect.getValue(xmlFile, key, node, "alignXAxisToWorldY", false)
	self.alignXAxisToWorldNode = Effect.getValue(xmlFile, key, node, "alignXAxisToWorldNode", self.node, i3dNode, i3dMapping)
	self.hasValidMaterial = false
	self.useBaseMaterial = false
	if 1 < getNumOfMaterials(self.node) then
		Logging.xmlWarning(xmlFile, "Failed to assign material to shader plane effect. Node '%s' has multiple materials assigned. Please assign only one default material.", getName(self.node))
		return false
	else
		local effectMaterial = g_materialManager:getBaseMaterialByName(self.materialType)
		if effectMaterial ~= nil then
			setMaterial(self.node, effectMaterial, 0)
			local shaderFilename = getMaterialCustomShaderFilename(effectMaterial)
			local defaultUseTextureArrays = false
			if shaderFilename ~= nil then
				defaultUseTextureArrays = shaderFilename:contains("grainUnloadingSmokeShader") or shaderFilename:contains("grainUnloadingBeltShader") or shaderFilename:contains("grainUnloadingShader") or shaderFilename:contains("levelerShader")
			end
			self.useFillTypeTextureArrays = Effect.getValue(xmlFile, key, node, "useFillTypeTextureArrays", defaultUseTextureArrays)
			if self.useFillTypeTextureArrays and shaderFilename ~= nil then
				if shaderFilename:find("grainUnloadingSmokeShader") ~= nil then
					g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(self.node, g_terrainNode, true, false, false)
				else
					g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(self.node, g_terrainNode, true, true, true)
				end
			end
			self.useBaseMaterial = true
			self.hasValidMaterial = true
		elseif g_materialManager:getMaterialTypeByName(self.materialType) == nil then
			Logging.error("Failed to assign material to shader plane effect. Material '%s' not found!", self.materialType)
		end
		if not self.dynamicFillType then
			self:setEffectTypeInfo(self.defaultFillType, nil, nil, true)
		end
		self.fadeXDistance = { Effect.getValue(xmlFile, key, node, "fadeXMinDistance", -1.58), Effect.getValue(xmlFile, key, node, "fadeXMaxDistance", 4.18) }
		self.useDistance = Effect.getValue(xmlFile, key, node, "useDistance", true)
		self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", -0.25)
		self.extraDistanceNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, node, "extraDistanceNode"), i3dMapping)
		self.fadeScale = Effect.getValue(xmlFile, key, node, "fadeScale")
		self.uvSpeed = Effect.getValue(xmlFile, key, node, "uvSpeed")
		self.uvScale = Effect.getValue(xmlFile, key, node, "uvScale")
		self.fadeX = { -1, 1 }
		self.fadeY = { -1, 1 }
		self.fadeCur = { -1, 1 }
		self.fadeDir = { 1, 1 }
		self.offset = 0
		setShaderParameter(self.node, "fadeProgress", -1, 1, 0, 0, false)
		if self.alignXAxisToWorldY then
			self.worldYReferenceFrame = createTransformGroup("worldYReferenceFrame")
			link(getParent(self.alignXAxisToWorldNode), self.worldYReferenceFrame)
			setTranslation(self.worldYReferenceFrame, getTranslation(self.alignXAxisToWorldNode))
			setRotation(self.worldYReferenceFrame, getRotation(self.alignXAxisToWorldNode))
		end
		return true
	end
end
function ShaderPlaneEffect:update(dt)
	ShaderPlaneEffect:superClass().update(self, dt)
	local isRunning = false
	self.currentDelay = self.currentDelay - dt
	if self.currentDelay <= 0 then
		local fadeTime = self.fadeInTime
		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			fadeTime = self.fadeOutTime
		end
		local valueX = self.fadeCur[1] + math.abs(self.fadeX[1] - self.fadeX[2]) * (dt / fadeTime) * self.fadeDir[1]
		local valueY = self.fadeCur[2] + math.abs(self.fadeY[1] - self.fadeY[2]) * (dt / fadeTime) * self.fadeDir[2]
		self.fadeCur[1] = math.clamp(valueX, self.fadeX[1], self.fadeX[2])
		self.fadeCur[2] = math.clamp(valueY, self.fadeY[1], self.fadeY[2])
		setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
		if self.showOnFirstUse then
			if self.hasValidMaterial then
				setVisibility(self.node, true)
			end
		else
			local isVisible = true
			if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
				isVisible = not false
			end
			setVisibility(self.node, isVisible and self.hasValidMaterial)
		end
		if (self.state ~= ShaderPlaneEffect.STATE_TURNING_ON or self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[2]) and (self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF or self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[1]) then
			isRunning = true
		end
	else
		isRunning = true
	end
	if self.alignXAxisToWorldY then
		local _, dy, dz = worldDirectionToLocal(self.worldYReferenceFrame, 0, 1, 0)
		local alpha = math.atan2(dz, dy)
		local _, ry, rz = getRotation(self.alignXAxisToWorldNode)
		setRotation(self.alignXAxisToWorldNode, alpha, ry, rz)
	end
	if self.alignToWorldY then
		I3DUtil.setWorldDirection(self.node, 0, 0, 1, 0, 1, 0)
	end
	if not isRunning then
		if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
			self.state = ShaderPlaneEffect.STATE_ON
			return
		end
		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			self.state = ShaderPlaneEffect.STATE_OFF
		end
	end
end
function ShaderPlaneEffect:isRunning()
	local _v4 = true
	if self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
		_v4 = true
		if self.state ~= ShaderPlaneEffect.STATE_TURNING_ON then
			_v4 = self.state == ShaderPlaneEffect.STATE_ON
		end
	end
	return _v4
end
function ShaderPlaneEffect:start()
	if self:canStart() and (self.state ~= ShaderPlaneEffect.STATE_TURNING_ON and self.state ~= ShaderPlaneEffect.STATE_ON) then
		self.state = ShaderPlaneEffect.STATE_TURNING_ON
		self.fadeCur[1] = -1
		self.fadeCur[2] = 1
		self.fadeDir[1] = 1
		self.fadeDir[2] = 1
		self.currentDelay = self.startDelay
		return true
	end
	return false
end
function ShaderPlaneEffect:stop()
	if self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF and self.state ~= ShaderPlaneEffect.STATE_OFF then
		self.state = ShaderPlaneEffect.STATE_TURNING_OFF
		self.fadeDir[1] = 1
		self.fadeDir[2] = -1
		self.currentDelay = self.stopDelay
		return true
	end
	return false
end
function ShaderPlaneEffect:reset()
	self.fadeCur[1] = -1
	self.fadeCur[2] = 1
	self.fadeDir[1] = 1
	self.fadeDir[2] = -1
	setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
	setVisibility(self.node, false)
	self.state = ShaderPlaneEffect.STATE_OFF
end
function ShaderPlaneEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState, force)
	local success = true
	if self.dynamicFillType and (self.lastFillTypeIndex == fillTypeIndex and force) then
		if self.useFillTypeTextureArrays then
			local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(self.defaultFillType or fillTypeIndex)
			if textureArrayIndex ~= nil then
				setShaderParameter(self.node, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, false)
			end
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			if fillTypeDesc ~= nil then
				setShaderParameter(self.node, "alphaClipScale", fillTypeDesc:getBeltEffectAlphaClipScale(), nil, nil, nil, false)
			end
		end
		if not self.useBaseMaterial and (self.materialType ~= nil and self.materialTypeId ~= nil) then
			local material = g_materialManager:getMaterial(fillTypeIndex, self.materialType, self.materialTypeId)
			if material == nil and self.defaultFillType ~= nil then
				material = g_materialManager:getMaterial(self.defaultFillType, self.materialType, self.materialTypeId)
			end
			self.hasValidMaterial = material ~= nil
			if material ~= nil then
				setMaterial(self.node, material, 0)
			else
				success = false
			end
		end
		local material = getMaterial(self.node, 0)
		local materialIsAlphaBlended = getMaterialIsAlphaBlended(material)
		if string.contains(string.lower(self.materialType), "smoke") or materialIsAlphaBlended then
			setObjectMask(self.node, 16711807)
		end
		if self.fadeScale ~= nil then
			setShaderParameter(self.node, "fadeScale", self.fadeScale, 0, 0, 0, false)
		end
		if self.uvSpeed ~= nil then
			setShaderParameter(self.node, "uvSpeedMult", self.uvSpeed, 0, 0, 0, false)
		end
		setShaderParameter(self.node, "uvScaleSpeed", self.uvScale, self.uvSpeed, nil, nil, false)
		self.lastFillTypeIndex = fillTypeIndex
	end
	return success
end
function ShaderPlaneEffect:getIsVisible()
	local _v5 = false
	if self.fadeX[1] < self.fadeCur[1] then
		_v5 = self.fadeCur[2] == self.fadeY[2]
	end
	return _v5
end
function ShaderPlaneEffect:getIsFullyVisible()
	local _v5 = false
	if math.abs(self.fadeCur[1] - self.fadeX[2]) < 0.05 then
		_v5 = math.abs(self.fadeCur[2] - self.fadeY[2]) < 0.05
	end
	return _v5
end
function ShaderPlaneEffect:setDelays(startDelay, stopDelay)
	if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
		self.currentDelay = math.max(0, self.currentDelay + (startDelay - self.startDelay))
	elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
		self.currentDelay = math.max(0, self.currentDelay + (stopDelay - self.stopDelay))
	end
	self.startDelay = startDelay
	self.stopDelay = stopDelay
end
function ShaderPlaneEffect:setOffset(offset)
	self.offset = offset
end
function ShaderPlaneEffect:setDistance(distance)
	if self.useDistance then
		distance = distance + self.extraDistance
		if self.extraDistanceNode ~= nil then
			local _, y, _ = localToLocal(self.node, self.extraDistanceNode, 0, 0, 0)
			distance = distance + y
		end
		local percent = (distance - self.fadeXDistance[1]) / (self.fadeXDistance[2] - self.fadeXDistance[1])
		self.fadeX[2] = 2 * percent - 1
	end
end
function ShaderPlaneEffect:setColor(r, g, b, a)
	if self.node ~= nil then
		setShaderParameter(self.node, "colorScale", r, g, b, a, false)
	end
end
function ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#fadeTime", "(ShaderPlaneEffect) Fade time for fade in and fade out", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#fadeInTime", "(ShaderPlaneEffect) Fade in time", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#fadeOutTime", "(ShaderPlaneEffect) Fade out time", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#delay", "(ShaderPlaneEffect) Start/Stop delay", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#startDelay", "(ShaderPlaneEffect) Start delay", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#stopDelay", "(ShaderPlaneEffect) Stop delay", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#alwaysVisibile", "(ShaderPlaneEffect) Always visible", false)
	schema:register(XMLValueType.BOOL, basePath .. "#showOnFirstUse", "(ShaderPlaneEffect) Show on first use", false)
	schema:register(XMLValueType.STRING, basePath .. "#defaultFillType", "(ShaderPlaneEffect) Default fill type name")
	schema:register(XMLValueType.BOOL, basePath .. "#dynamicFillType", "(ShaderPlaneEffect) Dynamic fill type", false)
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(ShaderPlaneEffect) Material type name", "unloading")
	schema:register(XMLValueType.STRING, basePath .. "#materialTypeId", "(ShaderPlaneEffect) Material type id", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#useFillTypeTextureArrays", "(ShaderPlaneEffect) Apply shared fill type texture array to effect")
	schema:register(XMLValueType.BOOL, basePath .. "#alignToWorldY", "(ShaderPlaneEffect) Align Y axis to world Y", false)
	schema:register(XMLValueType.BOOL, basePath .. "#alignXAxisToWorldY", "(ShaderPlaneEffect) Align X axis to world Y", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#alignXAxisToWorldNode", "(ShaderPlaneEffect) Custom node that is used for the alignment instead of the effect node")
	schema:register(XMLValueType.FLOAT, basePath .. "#fadeXMinDistance", "(ShaderPlaneEffect) Fade X min. distance", -1.58)
	schema:register(XMLValueType.FLOAT, basePath .. "#fadeXMaxDistance", "(ShaderPlaneEffect) Fade X max. distance", 4.18)
	schema:register(XMLValueType.BOOL, basePath .. "#useDistance", "(ShaderPlaneEffect) Use distance", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#extraDistance", "(ShaderPlaneEffect) Extra distance", -0.25)
	schema:register(XMLValueType.STRING, basePath .. "#extraDistanceNode", "(ShaderPlaneEffect) Distance between effect and this node will be added to distance")
	schema:register(XMLValueType.FLOAT, basePath .. "#fadeScale", "(ShaderPlaneEffect) Fade scale")
	schema:register(XMLValueType.FLOAT, basePath .. "#uvSpeed", "(ShaderPlaneEffect) UV speed")
	schema:register(XMLValueType.FLOAT, basePath .. "#uvScale", "(ShaderPlaneEffect) UV Scale")
end
