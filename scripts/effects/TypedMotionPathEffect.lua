-- Local values: TypedMotionPathEffect_mt
TypedMotionPathEffect = {}
local TypedMotionPathEffect_mt = Class(TypedMotionPathEffect, MotionPathEffect)

-- Upvalues: TypedMotionPathEffect_mt
-- Local values: self
function TypedMotionPathEffect.new(customMt)
	-- upvalues: (copy) TypedMotionPathEffect_mt
	local v3_ = MotionPathEffect.new(customMt or TypedMotionPathEffect_mt)
	v3_.fruitTypeIndex = FruitType.UNKNOWN
	v3_.fillTypeIndex = FillType.UNKNOWN
	v3_.growthState = 0
	v3_.isTypedEffectValid = true
	return v3_
end

-- Local values: forcedFillTypeName, fillTypeIndex, forcedFruitTypeName, fruitTypeDesc, requiredFillTypeName, requiredFruitTypeName
function TypedMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not TypedMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.meshType = xmlFile:getValue(key .. "#meshType")
	self.materialType = xmlFile:getValue(key .. "#materialType")
	local v10_ = xmlFile:getValue(key .. "#forcedFillType")
	local v11_ = g_fillTypeManager:getFillTypeIndexByName(v10_)
	if v11_ ~= nil then
		self.forcedFillType = v11_
		self.fillTypeIndex = v11_
	end
	local v12_ = xmlFile:getValue(key .. "#forcedFruitType")
	local v13_ = g_fruitTypeManager:getFruitTypeByName(v12_)
	if v13_ ~= nil then
		self.forcedFruitType = v13_.index
		self.fruitTypeIndex = v13_.index
	end
	self.forcedGrowthState = xmlFile:getValue(key .. "#forcedGrowthState")
	if self.forcedGrowthState ~= nil then
		self.growthState = self.forcedGrowthState
	end
	local v14_ = xmlFile:getValue(key .. "#requiredFillType")
	local v15_ = g_fillTypeManager:getFillTypeIndexByName(v14_)
	if v15_ ~= nil then
		self.requiredFillType = v15_
	end
	local v16_ = xmlFile:getValue(key .. "#requiredFruitType")
	local v17_ = g_fruitTypeManager:getFruitTypeByName(v16_)
	if v17_ ~= nil then
		self.requiredFruitType = v17_.index
	end
	self.requiredGrowthState = xmlFile:getValue(key .. "#requiredGrowthState")
	if self.requiredFillType ~= nil or (self.requiredFruitType ~= nil or self.requiredGrowthState ~= nil) then
		self.isTypedEffectValid = false
	end
	return true
end

-- Local values: isInvalid, changed
function TypedMotionPathEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
	local v22_ = false
	local v23_ = false
	if fillTypeIndex ~= self.fillTypeIndex and self.forcedFillType == nil then
		if self.requiredFillType == nil or self.requiredFillType == fillTypeIndex then
			self.fillTypeIndex = fillTypeIndex
			v23_ = true
		else
			v22_ = true
		end
	end
	if fruitTypeIndex ~= self.fruitTypeIndex and self.forcedFruitType == nil then
		if self.requiredFruitType == nil or self.requiredFruitType == fruitTypeIndex then
			self.fruitTypeIndex = fruitTypeIndex
			v23_ = true
		else
			v22_ = true
		end
	end
	if growthState ~= self.growthState and self.forcedGrowthState == nil then
		if self.requiredGrowthState == nil or self.requiredGrowthState == growthState then
			self.growthState = growthState
			v23_ = true
		else
			v22_ = true
		end
	end
	if v22_ then
		self.isTypedEffectValid = false
	elseif v23_ then
		self.isTypedEffectValid = true
	end
	if v23_ then
		self:loadSharedMotionPathEffect()
	end
	return self.hasCurrentEffectNodes
end
function TypedMotionPathEffect.loadSharedMotionPathEffect(p24_, ...)
	if p24_.isTypedEffectValid then
		return TypedMotionPathEffect:superClass().loadSharedMotionPathEffect(p24_, ...)
	else
		return nil
	end
end

function TypedMotionPathEffect:getIsSharedEffectMatching(sharedEffect, alternativeCheck)
	if TypedMotionPathEffect:superClass().getIsSharedEffectMatching(self, sharedEffect, alternativeCheck) then
		return self:getIsEffectSpecificDataMatching(sharedEffect, alternativeCheck) and true or false
	else
		return false
	end
end

function TypedMotionPathEffect:getIsEffectMeshMatching(effectMesh, alternativeCheck)
	if TypedMotionPathEffect:superClass().getIsEffectMeshMatching(self, effectMesh, alternativeCheck) then
		if effectMesh.meshType == self.meshType then
			return self:getIsEffectSpecificDataMatching(effectMesh, alternativeCheck) and true or false
		else
			return false
		end
	else
		return false
	end
end

function TypedMotionPathEffect:getIsEffectMaterialMatching(effectMaterial, alternativeCheck)
	if TypedMotionPathEffect:superClass().getIsEffectMaterialMatching(self, effectMaterial, alternativeCheck) then
		if effectMaterial.materialType == self.materialType then
			return self:getIsEffectSpecificDataMatching(effectMaterial, alternativeCheck) and true or false
		else
			return false
		end
	else
		return false
	end
end

-- Local values: str
function TypedMotionPathEffect:getEffectMatchingString()
	local v35_ = TypedMotionPathEffect:superClass().getEffectMatchingString(self)
	if self.materialType ~= nil then
		v35_ = v35_ .. string.format(", materialType \'%s\'", self.materialType)
	end
	if self.meshType ~= nil then
		v35_ = v35_ .. string.format(", meshType \'%s\'", self.meshType)
	end
	if self.fruitTypeIndex ~= nil then
		v35_ = v35_ .. string.format(", fruitType \'%s\'", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
	end
	if self.growthState ~= nil then
		v35_ = v35_ .. string.format(", growthState \'%s\'", self.growthState)
	end
	if self.fillTypeIndex ~= nil then
		v35_ = v35_ .. string.format(", fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(self.fillTypeIndex))
	end
	return v35_
end

-- Local values: found, i, foundState, i, found, i
function TypedMotionPathEffect:getIsEffectSpecificDataMatching(target, alternativeCheck)
	if target.fruitTypes ~= nil then
		local v39_ = false
		for v40_ = 1, #target.fruitTypes do
			if target.fruitTypes[v40_] == self.fruitTypeIndex then
				v39_ = true
			end
		end
		if not v39_ then
			return false
		end
	end
	if target.growthStates == nil then
		if not alternativeCheck then
			return false
		end
	else
		local v41_ = false
		for v42_ = 1, #target.growthStates do
			if target.growthStates[v42_] == self.growthState then
				v41_ = true
			end
		end
		if not v41_ then
			return false
		end
	end
	if target.fillTypes ~= nil then
		local v43_ = false
		for v44_ = 1, #target.fillTypes do
			if target.fillTypes[v44_] == self.fillTypeIndex then
				v43_ = true
			end
		end
		if not v43_ then
			return false
		end
	end
	return true
end

function TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	MotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectSpecificDataFromXML(effectMaterial, xmlFile, key)
	effectMaterial.materialType = xmlFile:getValue(key .. "#materialType")
end

function TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	MotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectSpecificDataFromXML(effectMesh, xmlFile, key)
	effectMesh.meshType = xmlFile:getValue(key .. "#meshType")
end

function TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	MotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectSpecificDataFromXML(motionPathEffect, xmlFile, key)
end

-- Local values: fruitTypeNames, fruitTypes, i, fruitTypeDesc, growthStates, fillTypeNames, fillTypes, i, fillTypeIndex
function TypedMotionPathEffect.loadEffectSpecificDataFromXML(target, xmlFile, key)
	local v57_ = xmlFile:getValue(key .. "#fruitTypes")
	if v57_ ~= nil then
		target.fruitTypes = {}
		local v58_ = v57_:split(" ")
		for v59_ = 1, #v58_ do
			local v60_ = g_fruitTypeManager:getFruitTypeByName(v58_[v59_])
			if v60_ ~= nil then
				local v61_ = target.fruitTypes
				local v62_ = v60_.index
				table.insert(v61_, v62_)
			end
		end
	end
	local v63_ = xmlFile:getValue(key .. "#growthStates", nil, true)
	if v63_ ~= nil and #v63_ > 0 then
		target.growthStates = v63_
	end
	local v64_ = xmlFile:getValue(key .. "#fillTypes")
	if v64_ ~= nil then
		target.fillTypes = {}
		local v65_ = v64_:split(" ")
		for v66_ = 1, #v65_ do
			local v67_ = g_fillTypeManager:getFillTypeIndexByName(v65_[v66_])
			if v67_ ~= FillType.UNKNOWN then
				local v68_ = target.fillTypes
				table.insert(v68_, v67_)
			end
		end
	end
end

function TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
end

function TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#meshType", "(TypedMotionPathEffect) Mesh Type")
end

function TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(TypedMotionPathEffect) Material Type")
end

function TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#fruitTypes", "(TypedMotionPathEffect) Fruit Type Names")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#growthStates", "(TypedMotionPathEffect) All harvesting states of fruit type")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "(TypedMotionPathEffect) Fill Type Names")
end

function TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#meshType", "(TypedMotionPathEffect) Mesh Type")
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(TypedMotionPathEffect) Material Type")
	schema:register(XMLValueType.STRING, basePath .. "#forcedFillType", "(TypedMotionPathEffect) Forced fill type that is always applied")
	schema:register(XMLValueType.STRING, basePath .. "#forcedFruitType", "(TypedMotionPathEffect) Forced fruit type that is always applied")
	schema:register(XMLValueType.INT, basePath .. "#forcedGrowthState", "(TypedMotionPathEffect) Forced growth state that is always applied")
	schema:register(XMLValueType.STRING, basePath .. "#requiredFillType", "(TypedMotionPathEffect) Effect will only be used for this fill type")
	schema:register(XMLValueType.STRING, basePath .. "#requiredFruitType", "(TypedMotionPathEffect) Effect will only be used for this fruit type")
	schema:register(XMLValueType.INT, basePath .. "#requiredGrowthState", "(TypedMotionPathEffect) Effect will only be used for this growth state")
end
