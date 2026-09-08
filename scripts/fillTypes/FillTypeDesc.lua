-- Local values: FillTypeDesc_mt
FillTypeDesc = {}
local FillTypeDesc_mt = Class(FillTypeDesc)

-- Upvalues: FillTypeDesc_mt
-- Local values: self
function FillTypeDesc.new(customMt)
	-- upvalues: (copy) FillTypeDesc_mt
	local v3_ = customMt or FillTypeDesc_mt
	local v4_ = setmetatable({}, v3_)
	v4_.index = nil
	v4_.name = "UNKNOWN"
	v4_.title = "Unknown"
	v4_.unitShort = ""
	v4_.achievementName = nil
	v4_.showOnPriceTable = false
	v4_.pricePerLiter = 0
	v4_.massPerLiter = 0.001
	v4_.maxPhysicalSurfaceAngle = 0.5235987755982988
	v4_.hudOverlayFilename = nil
	v4_.textureArrayIndex = nil
	v4_.layerTextures = {}
	v4_.layerTextures.diffuseMapFilename = nil
	v4_.layerTextures.normalMapFilename = nil
	v4_.layerTextures.heightMapFilename = nil
	v4_.layerTextures.displacementMapFilename = nil
	v4_.layerTextures.distanceFilename = nil
	v4_.layerTextures.isValid = false
	v4_.layerParameters = {}
	v4_.layerParameters.unitSize = 4
	v4_.layerParameters.displacementMaxHeight = 0.2
	v4_.layerParameters.blendContrast = 0.5
	v4_.layerParameters.noiseScale = 0.5
	v4_.layerParameters.fillBlendStart = 1
	v4_.layerParameters.porosityAtZeroRoughness = 0
	v4_.layerParameters.porosityAtFullRoughness = 0
	v4_.layerParameters.firmness = 0.5
	v4_.layerParameters.viscosity = 0.5
	v4_.layerParameters.firmnessWet = 0.5
	v4_.hudFilename = nil
	v4_.palletFilename = nil
	v4_.previousHourPrice = 0
	v4_.startPricePerLiter = 0
	v4_.totalAmount = 0
	v4_.economy = {}
	v4_.economy.factors = {}
	v4_.economy.history = {}
	v4_.economy.sychronizeData = true
	v4_.prioritizedEffectType = "ShaderPlaneEffect"
	v4_.fillSmokeColor = nil
	v4_.fruitSmokeColor = nil
	v4_.particles = {}
	v4_.alphaClip = {}
	v4_.alphaClip.value = 0.5
	v4_.alphaClip.sharpness = 0.5
	v4_.alphaClip.gradientScale = 1
	v4_.alphaClip.alphaScale = 1
	v4_.alphaClip.beltAlphaScale = 1
	v4_.finalized = false
	return v4_
end

-- Local values: economicCurve, period, _, particleKey, particle
function FillTypeDesc:loadFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	self.name = xmlFile:getValue(key .. "#name")
	if not ClassUtil.getIsValidIndexName(self.name) then
		Logging.warning("\'%s\' is not a valid name for a fillType. Ignoring fillType!", self.name)
		return false
	end
	self.name = string.upper(self.name)
	self.title = xmlFile:getValue(key .. "#title", self.title, customEnvironment)
	self.achievementName = xmlFile:getValue(key .. "#achievementName", self.achievementName)
	self.showOnPriceTable = xmlFile:getValue(key .. "#showOnPriceTable", self.showOnPriceTable)
	self.unitShort = xmlFile:getValue(key .. "#unitShort", self.unitShort, customEnvironment)
	self.isBulkType = xmlFile:getValue(key .. "#isBulkType", false)
	self.isPalletType = xmlFile:getValue(key .. "#isPalletType", false)
	self.isBaleType = xmlFile:getValue(key .. "#isBaleType", false)
	self.massPerLiter = xmlFile:getValue(key .. ".physics#massPerLiter", self.massPerLiter * 1000) * 0.001
	self.maxPhysicalSurfaceAngle = Utils.getNoNilRad(xmlFile:getValue(key .. ".physics#maxPhysicalSurfaceAngle"), self.maxPhysicalSurfaceAngle)
	self.hudOverlayFilename = xmlFile:getValue(key .. ".image#hud", nil, baseDirectory) or self.hudOverlayFilename
	self.palletFilename = xmlFile:getValue(key .. ".pallet#filename", nil, baseDirectory) or self.palletFilename
	self.pricePerLiter = xmlFile:getValue(key .. ".economy#pricePerLiter", self.pricePerLiter)
	local v_u_10_ = {}
	xmlFile:iterate(key .. ".economy.factors.factor", function(_, p11_)
		-- upvalues: (copy) xmlFile, (copy) v_u_10_
		local v12_ = xmlFile:getValue(p11_ .. "#period")
		local v13_ = xmlFile:getValue(p11_ .. "#value")
		if v12_ ~= nil and v13_ ~= nil then
			v_u_10_[v12_] = v13_
		end
	end)
	for v14_ = SeasonPeriod.EARLY_SPRING, SeasonPeriod.LATE_WINTER do
		self.economy.factors[v14_] = v_u_10_[v14_] or (self.economy.factors[v14_] or 1)
		self.economy.history[v14_] = self.economy.factors[v14_] * self.pricePerLiter
	end
	self.layerTextures.diffuseMapFilename = xmlFile:getValue(key .. ".textures#diffuse", nil, baseDirectory) or self.layerTextures.diffuseMapFilename
	self.layerTextures.normalMapFilename = xmlFile:getValue(key .. ".textures#normal", nil, baseDirectory) or self.layerTextures.normalMapFilename
	self.layerTextures.heightMapFilename = xmlFile:getValue(key .. ".textures#height", nil, baseDirectory) or self.layerTextures.heightMapFilename
	self.layerTextures.displacementMapFilename = xmlFile:getValue(key .. ".textures#displacement", nil, baseDirectory) or self.layerTextures.displacementMapFilename
	self.layerTextures.distanceFilename = xmlFile:getValue(key .. ".textures#distance", nil, baseDirectory) or self.layerTextures.distanceFilename
	local v15_ = self.layerTextures
	local v16_
	if self.layerTextures.diffuseMapFilename == nil or (self.layerTextures.normalMapFilename == nil or self.layerTextures.heightMapFilename == nil) then
		v16_ = false
	else
		v16_ = self.layerTextures.displacementMapFilename ~= nil
	end
	v15_.isValid = v16_
	self.layerParameters.unitSize = xmlFile:getValue(key .. ".textures#unitSize", self.layerParameters.unitSize)
	self.layerParameters.displacementMaxHeight = xmlFile:getValue(key .. ".textures#displacementMaxHeight", self.layerParameters.displacementMaxHeight)
	self.layerParameters.blendContrast = xmlFile:getValue(key .. ".textures#blendContrast", self.layerParameters.blendContrast)
	self.layerParameters.noiseScale = xmlFile:getValue(key .. ".textures#noiseScale", self.layerParameters.noiseScale)
	self.layerParameters.fillBlendStart = xmlFile:getValue(key .. ".textures#fillBlendStart", self.layerParameters.fillBlendStart)
	self.layerParameters.porosityAtZeroRoughness = xmlFile:getValue(key .. ".textures#porosityAtZeroRoughness", self.layerParameters.porosityAtZeroRoughness)
	self.layerParameters.porosityAtFullRoughness = xmlFile:getValue(key .. ".textures#porosityAtFullRoughness", self.layerParameters.porosityAtFullRoughness)
	self.layerParameters.firmness = xmlFile:getValue(key .. ".textures#firmness", self.layerParameters.firmness)
	self.layerParameters.viscosity = xmlFile:getValue(key .. ".textures#viscosity", self.layerParameters.viscosity)
	self.layerParameters.firmnessWet = xmlFile:getValue(key .. ".textures#firmnessWet", self.layerParameters.firmness)
	self.prioritizedEffectType = xmlFile:getValue(key .. ".effects#prioritizedEffectType", self.prioritizedEffectType)
	self.fillSmokeColor = xmlFile:getValue(key .. ".effects#fillSmokeColor", self.fillSmokeColor, true)
	self.fruitSmokeColor = xmlFile:getValue(key .. ".effects#fruitSmokeColor", self.fruitSmokeColor, true)
	for _, v17_ in xmlFile:iterator(key .. ".effects.particle") do
		local v18_ = {
			["particleType"] = xmlFile:getValue(v17_ .. "#particleType")
		}
		if v18_.particleType == nil then
			Logging.xmlWarning(xmlFile, "Missing particleType in \'%s\'", v17_)
		else
			v18_.filename = xmlFile:getValue(v17_ .. "#filename", nil, baseDirectory)
			if v18_.filename == nil then
				Logging.xmlWarning(xmlFile, "Missing filename in \'%s\'", v17_)
			else
				v18_.useFillTexture = xmlFile:getValue(v17_ .. "#useFillTexture", false)
				v18_.emitCountScale = xmlFile:getValue(v17_ .. "#emitCountScale", 1)
				v18_.spriteScaleX = xmlFile:getValue(v17_ .. "#spriteScaleX")
				v18_.spriteScaleY = xmlFile:getValue(v17_ .. "#spriteScaleY")
				self.particles[v18_.particleType] = v18_
			end
		end
	end
	self.alphaClip = {}
	self.alphaClip.value = xmlFile:getValue(key .. ".effects.alphaClip#value", self.alphaClip.value)
	self.alphaClip.sharpness = xmlFile:getValue(key .. ".effects.alphaClip#sharpness", self.alphaClip.sharpness)
	self.alphaClip.gradientScale = xmlFile:getValue(key .. ".effects.alphaClip#gradientScale", self.alphaClip.gradientScale)
	self.alphaClip.alphaScale = xmlFile:getValue(key .. ".effects.alphaClip#alphaScale", self.alphaClip.alphaScale)
	self.alphaClip.beltAlphaScale = xmlFile:getValue(key .. ".effects.alphaClip#beltAlphaScale", self.alphaClip.beltAlphaScale)
	return true
end

-- Local values: _, particle, i3dNode, sharedLoadRequestId, failedReason
function FillTypeDesc:finalize(force)
	if not self.finalized or force then
		self.finalized = true
		for _, v21_ in pairs(self.particles) do
			if force then
				local v22_, v23_, v24_ = g_i3DManager:loadSharedI3DFile(v21_.filename, false, false)
				self:particleShapeI3DFileLoaded(v22_, v24_, v21_)
				v21_.sharedLoadRequestId = v23_
			else
				v21_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v21_.filename, false, false, self.particleShapeI3DFileLoaded, self, v21_)
			end
		end
	end
end

-- Local values: node
function FillTypeDesc:particleShapeI3DFileLoaded(i3dNode, failedReason, particle)
	if i3dNode == 0 then
		return
	elseif getNumOfChildren(i3dNode) == 0 then
		Logging.error("i3d file %q does not contain a shape", particle.filename)
		delete(i3dNode)
		return
	else
		local v27_ = getChildAt(i3dNode, 0)
		if getHasClassId(v27_, ClassIds.SHAPE) then
			particle.shape = v27_
			unlink(particle.shape)
			setVisibility(particle.shape, false)
			particle.materialId = getMaterial(particle.shape, 0)
			delete(i3dNode)
		else
			Logging.error("node %q in %q is not a shape", getName(v27_), particle.filename)
			delete(i3dNode)
		end
	end
end

-- Local values: _, particle
function FillTypeDesc:delete()
	for _, v29_ in pairs(self.particles) do
		if v29_.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(v29_.sharedLoadRequestId)
			v29_.sharedLoadRequestId = nil
		end
		if v29_.shape ~= nil then
			delete(v29_.shape)
			v29_.shape = nil
		end
		v29_.materialId = nil
	end
end

-- Local values: layerTextures, layerParameters
function FillTypeDesc:addTerrainFillLayer(terrainRootNodeId, index)
	local v33_ = self.layerTextures
	if not v33_.isValid then
		Logging.error("Failed to create terrain fill layer. Fill type \'%s\' does not have textures defined!", self.name)
		return false
	end
	local v34_ = self.layerParameters
	addTerrainFillLayer(terrainRootNodeId, self.name, v33_.diffuseMapFilename, v33_.normalMapFilename, v33_.heightMapFilename, v33_.displacementMapFilename, v34_.unitSize, v34_.displacementMaxHeight, v34_.blendContrast, v34_.noiseScale, v34_.fillBlendStart, v34_.porosityAtZeroRoughness, v34_.porosityAtFullRoughness, v34_.firmness, v34_.viscosity, v34_.firmnessWet)
	self.textureArrayIndex = index
	return true
end

function FillTypeDesc:addDistanceTexture(distanceConstr, index)
	if self.layerTextures.distanceFilename == nil or self.layerTextures.distanceFilename:len() <= 0 then
		Logging.error("Failed to create density height map distance texture array. Fill type \'%s\' does not have distance texture defined!", self.name)
		return false
	else
		distanceConstr:addTexture(index, self.layerTextures.distanceFilename, 3)
		return true
	end
end

function FillTypeDesc:getTextureUnitSize()
	return self.layerParameters.unitSize
end

function FillTypeDesc:getBeltEffectAlphaClipScale()
	return self.alphaClip.beltAlphaScale
end

-- Local values: customEmitCountScale, particleUseFillTextureArray, particle, effectMaterial, color, _, _, _, a
function FillTypeDesc:setParticleSystemFillType(particleSystem, particleType, materialType, useFruitColor, emitCountScale, alphaScale)
	local v47_ = nil
	if materialType ~= nil then
		local v48_ = true
		local v49_ = self.particles[particleType]
		if v49_ ~= nil and v49_.shape ~= nil then
			setParticleShape(getGeometry(particleSystem.shape), v49_.shape)
			setMaterial(particleSystem.shape, v49_.materialId, 0)
			v47_ = particleSystem.emitterShapeSize / particleSystem.defaultEmitterShapeSize * emitCountScale * v49_.emitCountScale
			ParticleUtil.initEmitterScale(particleSystem, v47_)
			if v49_.spriteScaleX ~= nil then
				ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, v49_.spriteScaleX)
			end
			if v49_.spriteScaleY ~= nil then
				ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, v49_.spriteScaleY)
			end
			if not v49_.useFillTexture then
				v48_ = false
			end
		end
		if v48_ then
			local v50_ = g_materialManager:getBaseMaterialByName(materialType)
			if v50_ == nil then
				Logging.error("Failed to assign material to shader plane effect. Base Material \'%s\' not found!", materialType)
			else
				ParticleUtil.setMaterial(particleSystem, v50_)
				setMaterial(particleSystem.shape, v50_, 0)
				if getMaterialCustomShaderFilename(v50_):contains("psSubUVShader") then
					g_fillTypeManager:assignCustomFillTypeTextureArraysFromTerrain(particleSystem.shape, g_terrainNode, "fillTypeColorMap", "", "")
				else
					g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(particleSystem.shape, g_terrainNode, true, true, true)
				end
			end
			if self.textureArrayIndex ~= nil then
				setShaderParameter(particleSystem.shape, "fillTypeId", self.textureArrayIndex - 1, 0, 0, 0, false)
			end
		end
		if string.lower(particleType):contains("smoke") or string.lower(materialType):contains("smoke") then
			local v51_
			if useFruitColor then
				v51_ = self.fruitSmokeColor or self.fillSmokeColor
			else
				v51_ = self.fillSmokeColor
			end
			if v51_ == nil then
				if getHasShaderParameter(particleSystem.shape, "colorAlpha") then
					local _, _, _, v52_ = getShaderParameter(particleSystem.shape, "colorAlpha")
					setShaderParameter(particleSystem.shape, "colorAlpha", nil, nil, nil, v52_ * (alphaScale or 1), false)
				end
			elseif getHasShaderParameter(particleSystem.shape, "colorAlpha") then
				setShaderParameter(particleSystem.shape, "colorAlpha", v51_[1], v51_[2], v51_[3], v51_[4] * (alphaScale or 1), false)
			end
		end
		if getHasShaderParameter(particleSystem.shape, "alphaClip") then
			setShaderParameter(particleSystem.shape, "alphaClip", self.alphaClip.value, self.alphaClip.sharpness, self.alphaClip.gradientScale, self.alphaClip.alphaScale, false)
		end
	end
	return v47_
end

-- Local values: fillTypesXMLFile
function FillTypeDesc:reloadData()
	if self.index ~= FillType.UNKNOWN then
		if self.xmlFilename ~= nil then
			self:delete()
			local v54_ = XMLFile.load("fillTypes", self.xmlFilename, FillTypeManager.xmlSchema)
			self:loadFromXMLFile(v54_, self.xmlKey, self.xmlBaseDirectory, self.xmlCustomEnvironment)
			v54_:delete()
			self:finalize(true)
			return
		end
		Logging.error("Failed to reload fillType data. Only possible with -scriptDebug!")
	end
end

function FillTypeDesc.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of fill type")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "Display name of fill type")
	schema:register(XMLValueType.STRING, basePath .. "#achievementName", "Name of linked archivement")
	schema:register(XMLValueType.BOOL, basePath .. "#showOnPriceTable", "Show fill type in pricing menu", false)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#unitShort", "Unit short localization key")
	schema:register(XMLValueType.BOOL, basePath .. "#isBulkType", "Fill type can be sold as bulk (tipped via trailer for example)", false)
	schema:register(XMLValueType.BOOL, basePath .. "#isPalletType", "Fill type can be sold as pallet", false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBaleType", "Fill type can be sold as bale", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".physics#massPerLiter", "Mass per liter/unit in kilograms", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".physics#maxPhysicalSurfaceAngle", "Max physical surface angle used on fill volumes", 30)
	schema:register(XMLValueType.FILENAME, basePath .. ".image#hud", "Path to hud image")
	schema:register(XMLValueType.FILENAME, basePath .. ".pallet#filename", "Pallet xml filename which is spawned on unloading")
	schema:register(XMLValueType.FLOAT, basePath .. ".economy#pricePerLiter", "Price per liter", 0)
	schema:register(XMLValueType.INT, basePath .. ".economy.factors.factor(?)#period", "Period index")
	schema:register(XMLValueType.FLOAT, basePath .. ".economy.factors.factor(?)#value", "Price factor to apply in this period")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#diffuse", "Path to fill plane diffuse map")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#normal", "Path to fill plane normal map")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#height", "Path to fill plane height map")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#displacement", "Path to fill plane displacement map")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#distance", "Path to fill plane distance diffuse map")
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#unitSize", "Unit size for fill plane texture, in meters", 4)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#displacementMaxHeight", "Max height for displacement map, in meters", 0.2)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#blendContrast", "Blend contrast for texture", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#noiseScale", "Noise scale for texture blending", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#fillBlendStart", "Start of alpha blending region for fill layer (1.0 = no blending)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#porosityAtZeroRoughness", "Porosity of fill material at zero roughness", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#porosityAtFullRoughness", "Porosity of fill material at full roughness", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#firmness", "Firmness of fill plane (for tyre tracks)", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#viscosity", "Viscosity of fill plane (for tyre tracks)", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".textures#firmnessWet", "Firmness of fill plane when terrain is wet (for tyre tracks)", 0.5)
	schema:register(XMLValueType.STRING, basePath .. ".effects#prioritizedEffectType", "Defines which effect type is priorized in e.g. unloading effects", "ShaderPlaneEffect")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".effects#fillSmokeColor", "Color of smoke effects")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".effects#fruitSmokeColor", "Color of fruit smoke effects")
	schema:register(XMLValueType.STRING, basePath .. ".effects.particle(?)#particleType", "Name of particle type")
	schema:register(XMLValueType.FILENAME, basePath .. ".effects.particle(?)#filename", "Path to the particle shape i3d file")
	schema:register(XMLValueType.BOOL, basePath .. ".effects.particle(?)#useFillTexture", "Use the fill type texture array for the particle meshes, or keep the material of the particle shape", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.particle(?)#emitCountScale", "Emit count scale to use", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.particle(?)#spriteScaleX", "Custom sprite scale X")
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.particle(?)#spriteScaleY", "Custom sprite scale Y")
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#value", "alpha clip value based on the shader formula (for particle with psColorShader)", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#sharpness", "sharpness of the final alpha in the shader formula (for particle with psColorShader)", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#gradientScale", "alphaMap gradient scale", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#alphaScale", "baseMap alpha scale", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#beltAlphaScale", "Scale of the alpha clip on belt / shader plane effects", 1)
end
