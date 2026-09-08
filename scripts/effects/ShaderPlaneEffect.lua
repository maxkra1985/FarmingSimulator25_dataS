-- Local values: ShaderPlaneEffect_mt
ShaderPlaneEffect = {}
local ShaderPlaneEffect_mt = Class(ShaderPlaneEffect, Effect)
ShaderPlaneEffect.STATE_OFF = 0
ShaderPlaneEffect.STATE_TURNING_ON = 1
ShaderPlaneEffect.STATE_ON = 2
ShaderPlaneEffect.STATE_TURNING_OFF = 3

-- Upvalues: ShaderPlaneEffect_mt
-- Local values: self
function ShaderPlaneEffect.new(customMt)
	-- upvalues: (copy) ShaderPlaneEffect_mt
	local v3_ = Effect.new(customMt or ShaderPlaneEffect_mt)
	v3_.state = ShaderPlaneEffect.STATE_OFF
	v3_.planeFadeTime = 0
	return v3_
end

-- Local values: defaultFillType, effectMaterial, shaderFilename, defaultUseTextureArrays
function ShaderPlaneEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not ShaderPlaneEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.fadeInTime = Effect.getValue(xmlFile, key, node, "fadeInTime", Effect.getValue(xmlFile, key, node, "fadeTime", 1)) * 1000
	self.fadeOutTime = Effect.getValue(xmlFile, key, node, "fadeOutTime", Effect.getValue(xmlFile, key, node, "fadeTime", 1)) * 1000
	local v10_ = self.fadeInTime
	local v11_ = math.max(v10_, 0.01)
	local v12_ = self.fadeOutTime
	local v13_ = math.max(v12_, 0.01)
	self.fadeInTime = v11_
	self.fadeOutTime = v13_
	local v14_ = self.planeFadeTime
	local v15_ = self.fadeInTime
	local v16_ = self.fadeOutTime
	self.planeFadeTime = math.max(v14_, v15_, v16_)
	self.startDelay = Effect.getValue(xmlFile, key, node, "startDelay", Effect.getValue(xmlFile, key, node, "delay", 0)) * 1000
	self.stopDelay = Effect.getValue(xmlFile, key, node, "stopDelay", Effect.getValue(xmlFile, key, node, "delay", 0)) * 1000
	self.currentDelay = self.startDelay
	self.alwaysVisibile = Effect.getValue(xmlFile, key, node, "alwaysVisibile", false)
	self.showOnFirstUse = Effect.getValue(xmlFile, key, node, "showOnFirstUse", false)
	local v17_ = Effect.getValue(xmlFile, key, node, "defaultFillType")
	if v17_ ~= nil then
		self.defaultFillType = g_fillTypeManager:getFillTypeIndexByName(v17_)
	end
	self.dynamicFillType = Effect.getValue(xmlFile, key, node, "dynamicFillType", true)
	self.materialType = Effect.getValue(xmlFile, key, node, "materialType", "unloading")
	self.materialTypeId = Effect.getValue(xmlFile, key, node, "materialTypeId", 1)
	self.alignToWorldY = Effect.getValue(xmlFile, key, node, "alignToWorldY", false)
	self.alignXAxisToWorldY = Effect.getValue(xmlFile, key, node, "alignXAxisToWorldY", false)
	self.alignXAxisToWorldNode = Effect.getValue(xmlFile, key, node, "alignXAxisToWorldNode", self.node, i3dNode, i3dMapping)
	self.hasValidMaterial = false
	self.useBaseMaterial = false
	if getNumOfMaterials(self.node) > 1 then
		Logging.xmlWarning(xmlFile, "Failed to assign material to shader plane effect. Node \'%s\' has multiple materials assigned. Please assign only one default material.", getName(self.node))
		return false
	end
	local v18_ = g_materialManager:getBaseMaterialByName(self.materialType)
	if v18_ == nil then
		if g_materialManager:getMaterialTypeByName(self.materialType) == nil then
			Logging.error("Failed to assign material to shader plane effect. Material \'%s\' not found!", self.materialType)
		end
	else
		setMaterial(self.node, v18_, 0)
		local v19_ = getMaterialCustomShaderFilename(v18_)
		local v20_
		if v19_ == nil then
			v20_ = false
		else
			v20_ = v19_:contains("grainUnloadingSmokeShader") or v19_:contains("grainUnloadingBeltShader") or (v19_:contains("grainUnloadingShader") or v19_:contains("levelerShader"))
		end
		self.useFillTypeTextureArrays = Effect.getValue(xmlFile, key, node, "useFillTypeTextureArrays", v20_)
		if self.useFillTypeTextureArrays then
			if v19_ == nil or v19_:find("grainUnloadingSmokeShader") == nil then
				g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(self.node, g_terrainNode, true, true, true)
			else
				g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(self.node, g_terrainNode, true, false, false)
			end
		end
		self.useBaseMaterial = true
		self.hasValidMaterial = true
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

-- Local values: isRunning, fadeTime, valueX, valueY, isVisible, _, dy, dz, alpha, _, ry, rz
function ShaderPlaneEffect:update(dt)
	ShaderPlaneEffect:superClass().update(self, dt)
	local v23_ = false
	self.currentDelay = self.currentDelay - dt
	if self.currentDelay <= 0 then
		local v24_ = self.fadeInTime
		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			v24_ = self.fadeOutTime
		end
		local v25_ = self.fadeCur[1]
		local v26_ = self.fadeX[1] - self.fadeX[2]
		local v27_ = v25_ + math.abs(v26_) * (dt / v24_) * self.fadeDir[1]
		local v28_ = self.fadeCur[2]
		local v29_ = self.fadeY[1] - self.fadeY[2]
		local v30_ = v28_ + math.abs(v29_) * (dt / v24_) * self.fadeDir[2]
		local v31_ = self.fadeCur
		local v32_ = self.fadeX[1]
		local v33_ = self.fadeX[2]
		v31_[1] = math.clamp(v27_, v32_, v33_)
		local v34_ = self.fadeCur
		local v35_ = self.fadeY[1]
		local v36_ = self.fadeY[2]
		v34_[2] = math.clamp(v30_, v35_, v36_)
		setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
		if self.showOnFirstUse then
			if self.hasValidMaterial then
				setVisibility(self.node, true)
			end
		else
			local v37_
			if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
				local v38_
				if self.fadeCur[1] == self.fadeX[2] then
					v38_ = self.fadeCur[2] == self.fadeY[1]
				else
					v38_ = false
				end
				v37_ = not v38_
			else
				v37_ = true
			end
			local v39_ = setVisibility
			local v40_ = self.node
			if v37_ then
				v37_ = self.hasValidMaterial
			end
			v39_(v40_, v37_)
		end
		if self.state ~= ShaderPlaneEffect.STATE_TURNING_ON or (self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[2]) then
			v23_ = (self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF or (self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[1])) and true or v23_
		end
	else
		v23_ = true
	end
	if self.alignXAxisToWorldY then
		local _, v41_, v42_ = worldDirectionToLocal(self.worldYReferenceFrame, 0, 1, 0)
		local v43_ = math.atan2(v42_, v41_)
		local _, v44_, v45_ = getRotation(self.alignXAxisToWorldNode)
		setRotation(self.alignXAxisToWorldNode, v43_, v44_, v45_)
	end
	if self.alignToWorldY then
		I3DUtil.setWorldDirection(self.node, 0, 0, 1, 0, 1, 0)
	end
	if not v23_ then
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
	return (self.state == ShaderPlaneEffect.STATE_TURNING_OFF or self.state == ShaderPlaneEffect.STATE_TURNING_ON) and true or self.state == ShaderPlaneEffect.STATE_ON
end

function ShaderPlaneEffect:start()
	if not self:canStart() or (self.state == ShaderPlaneEffect.STATE_TURNING_ON or self.state == ShaderPlaneEffect.STATE_ON) then
		return false
	end
	self.state = ShaderPlaneEffect.STATE_TURNING_ON
	local v48_ = self.fadeCur
	local v49_ = self.fadeCur
	v48_[1] = -1
	v49_[2] = 1
	local v50_ = self.fadeDir
	local v51_ = self.fadeDir
	v50_[1] = 1
	v51_[2] = 1
	self.currentDelay = self.startDelay
	return true
end

function ShaderPlaneEffect:stop()
	if self.state == ShaderPlaneEffect.STATE_TURNING_OFF or self.state == ShaderPlaneEffect.STATE_OFF then
		return false
	end
	self.state = ShaderPlaneEffect.STATE_TURNING_OFF
	local v53_ = self.fadeDir
	local v54_ = self.fadeDir
	v53_[1] = 1
	v54_[2] = -1
	self.currentDelay = self.stopDelay
	return true
end

function ShaderPlaneEffect:reset()
	local v56_ = self.fadeCur
	local v57_ = self.fadeCur
	v56_[1] = -1
	v57_[2] = 1
	local v58_ = self.fadeDir
	local v59_ = self.fadeDir
	v58_[1] = 1
	v59_[2] = -1
	setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
	setVisibility(self.node, false)
	self.state = ShaderPlaneEffect.STATE_OFF
end

-- Local values: success, textureArrayIndex, fillTypeDesc, material, material, materialIsAlphaBlended
function ShaderPlaneEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState, force)
	local v63_ = true
	if self.dynamicFillType and self.lastFillTypeIndex ~= fillTypeIndex or force then
		if self.useFillTypeTextureArrays then
			local v64_ = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(self.defaultFillType or fillTypeIndex)
			if v64_ ~= nil then
				setShaderParameter(self.node, "fillTypeId", v64_ - 1, 0, 0, 0, false)
			end
			local v65_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			if v65_ ~= nil then
				setShaderParameter(self.node, "alphaClipScale", v65_:getBeltEffectAlphaClipScale(), nil, nil, nil, false)
			end
		end
		if not self.useBaseMaterial and (self.materialType ~= nil and self.materialTypeId ~= nil) then
			local v66_ = g_materialManager:getMaterial(fillTypeIndex, self.materialType, self.materialTypeId)
			if v66_ == nil and self.defaultFillType ~= nil then
				v66_ = g_materialManager:getMaterial(self.defaultFillType, self.materialType, self.materialTypeId)
			end
			self.hasValidMaterial = v66_ ~= nil
			if v66_ == nil then
				v63_ = false
			else
				setMaterial(self.node, v66_, 0)
			end
		end
		local v67_ = getMaterial(self.node, 0)
		local v68_ = getMaterialIsAlphaBlended(v67_)
		if string.contains(string.lower(self.materialType), "smoke") or v68_ then
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
	return v63_
end

function ShaderPlaneEffect:getIsVisible()
	local v70_
	if self.fadeCur[1] > self.fadeX[1] then
		v70_ = self.fadeCur[2] == self.fadeY[2]
	else
		v70_ = false
	end
	return v70_
end

function ShaderPlaneEffect:getIsFullyVisible()
	local v72_ = self.fadeCur[1] - self.fadeX[2]
	local v73_
	if math.abs(v72_) < 0.05 then
		local v74_ = self.fadeCur[2] - self.fadeY[2]
		v73_ = math.abs(v74_) < 0.05
	else
		v73_ = false
	end
	return v73_
end

function ShaderPlaneEffect:setDelays(startDelay, stopDelay)
	if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
		local v78_ = self.currentDelay + (startDelay - self.startDelay)
		self.currentDelay = math.max(0, v78_)
	elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
		local v79_ = self.currentDelay + (stopDelay - self.stopDelay)
		self.currentDelay = math.max(0, v79_)
	end
	self.startDelay = startDelay
	self.stopDelay = stopDelay
end

function ShaderPlaneEffect:setOffset(offset)
	self.offset = offset
end

-- Local values: _, y, _, percent
function ShaderPlaneEffect:setDistance(distance)
	if self.useDistance then
		local v84_ = distance + self.extraDistance
		if self.extraDistanceNode ~= nil then
			local _, v85_, _ = localToLocal(self.node, self.extraDistanceNode, 0, 0, 0)
			v84_ = v84_ + v85_
		end
		local v86_ = (v84_ - self.fadeXDistance[1]) / (self.fadeXDistance[2] - self.fadeXDistance[1])
		self.fadeX[2] = 2 * v86_ - 1
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
