-- Local values: StaticLight_mt
StaticLight = {}
local StaticLight_mt = Class(StaticLight)

-- Upvalues: StaticLight_mt
-- Local values: self
function StaticLight.new(vehicle, customMt)
	-- upvalues: (copy) StaticLight_mt
	local v4_ = customMt or StaticLight_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.chargeFunction = nil
	return v5_
end

-- Local values: isValid, parent, k, v
function StaticLight:loadFromXML(xmlFile, baseKey, components, i3dMappings, loadLightTypes, sharedLight)
	self.node = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings) or xmlFile:getValue(baseKey .. "#shaderNode", nil, components, i3dMappings)
	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing static lights node in \'%s\'", baseKey)
		return false
	end
	if getHasClassId(self.node, ClassIds.LIGHT_SOURCE) then
		Logging.xmlWarning(xmlFile, "Light source used in static light \'%s\'", baseKey)
		return false
	end
	if not getHasClassId(self.node, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "Node used in static light \'%s\' is not a shape", baseKey)
		return false
	end
	if sharedLight ~= nil then
		local v13_ = self.node
		local v14_ = false
		while v13_ ~= nil and (v13_ ~= 0 and v13_ ~= getRootNode()) do
			if v13_ == sharedLight.node then
				v14_ = true
				break
			end
			v13_ = getParent(v13_)
		end
		if not v14_ then
			Logging.xmlWarning(xmlFile, "Static light mesh \'%s\' is outside of the root shared light node (%s) in \'%s\'", getName(self.node), getName(sharedLight.node), baseKey)
			return false
		end
	end
	self.useLightControlShaderParameter = getHasShaderParameter(self.node, "lightControl")
	if not self.useLightControlShaderParameter then
		self.absUVSlotIndex = xmlFile:getValue(baseKey .. "#uvSlotIndex")
		if self.absUVSlotIndex ~= nil then
			self.uvSlotParameter = "lightIds0"
			self.uvSlotIndex = self.absUVSlotIndex
			if self.uvSlotIndex > 4 then
				self.uvSlotParameter = "lightIds1"
				self.uvSlotIndex = self.uvSlotIndex - 4
			end
			if self.uvSlotIndex > 4 then
				self.uvSlotParameter = "lightIds2"
				self.uvSlotIndex = self.uvSlotIndex - 4
			end
			if self.uvSlotIndex > 4 then
				self.uvSlotParameter = "lightIds3"
				self.uvSlotIndex = self.uvSlotIndex - 4
			end
		end
	end
	self.intensity = xmlFile:getValue(baseKey .. "#intensity", 5)
	self.toggleVisibility = xmlFile:getValue(baseKey .. "#toggleVisibility", false)
	if self.toggleVisibility then
		setVisibility(self.node, false)
	elseif not (getHasShaderParameter(self.node, "lightControl") or getHasShaderParameter(self.node, "lightIds0")) then
		Logging.xmlWarning(xmlFile, "Static lights not using \'lightControl\' or \'lightIds0\' shader parameter in \'%s\'", baseKey)
		return false
	end
	if loadLightTypes ~= false then
		self.lightTypes = xmlFile:getValue(baseKey .. "#lightTypes", nil, true)
		self.excludedLightTypes = xmlFile:getValue(baseKey .. "#excludedLightTypes", nil, true)
		if sharedLight ~= nil then
			if sharedLight.lightTypes ~= nil then
				self.lightTypes = table.clone(sharedLight.lightTypes, 1)
			end
			if sharedLight.excludedLightTypes ~= nil then
				self.excludedLightTypes = table.clone(sharedLight.excludedLightTypes, 1)
			end
		end
	end
	if sharedLight ~= nil and sharedLight.additionalAttributes ~= nil then
		for v15_, v16_ in pairs(sharedLight.additionalAttributes) do
			self[v15_] = v16_
		end
	end
	if self.lightTypes == nil then
		self.lightTypes = {}
	end
	if self.excludedLightTypes == nil then
		self.excludedLightTypes = {}
	end
	if self.vehicle ~= nil and xmlFile:getRootName() == "vehicle" then
		self.vehicle:loadAdditionalLightAttributesFromXML(xmlFile, baseKey, self)
	end
	self:setState(false)
	return true
end

-- Local values: i, lightType, i, excludedLightType
function StaticLight:merge(otherLight)
	if self.uvSlotIndex ~= nil and (self.uvSlotIndex ~= otherLight.uvSlotIndex or self.uvSlotParameter ~= otherLight.uvSlotParameter) then
		return self
	end
	for _, v19_ in ipairs(self.lightTypes) do
		table.addElement(otherLight.lightTypes, v19_)
	end
	for _, v20_ in ipairs(self.excludedLightTypes) do
		table.addElement(otherLight.excludedLightTypes, v20_)
	end
	return otherLight
end

-- Local values: isActive, chargeScale, _, lightType, _, excludedLightType
function StaticLight:setLightTypesMask(lightsTypesMask)
	if #self.lightTypes == 0 then
		return
	end
	if self.vehicle == nil then
		return
	end
	if not self.vehicle:getIsLightActive(self) then
		self:setState(false, 0)
		return
	end
	local v23_ = false
	local v24_ = nil
	for _, v25_ in pairs(self.lightTypes) do
		local v26_ = 2 ^ v25_
		if bit32.band(lightsTypesMask, v26_) ~= 0 or v25_ == -1 and self.vehicle:getIsActiveForLights(true) then
			if v23_ then
				if self.vehicle.spec_lights.maxLightState < v25_ then
					v24_ = 2
				end
			else
				v23_ = true
			end
		end
	end
	if v23_ and self.excludedLightTypes ~= nil then
		for _, v27_ in pairs(self.excludedLightTypes) do
			local v28_ = 2 ^ v27_
			if bit32.band(lightsTypesMask, v28_) ~= 0 then
				v23_ = false
				break
			end
		end
	end
	if self.chargeFunction ~= nil then
		v24_ = self.chargeFunction(self.chargeFunctionTarget)
	end
	self:setState(v23_, v24_)
end

-- Local values: lightTypeBitMask, i, lightTypeBitMask, bitIndex, mask
function StaticLight:setIsBlinking(isBlinking)
	if not self.useLightControlShaderParameter then
		if self.absUVSlotIndex == nil then
			local v30_ = 0
			for v31_ = 0, 11 do
				local v32_ = StaticLightCompoundLightType.BLINKING - 1
				local v33_ = v31_ * 2
				local v34_ = bit32.lshift(v32_, v33_)
				v30_ = bit32.bor(v30_, v34_)
			end
			setShaderParameter(self.node, "lightTypeBitMask", v30_, nil, nil, nil, false)
			return
		end
		if self.absUVSlotIndex <= 12 then
			local v35_ = getShaderParameter(self.node, "lightTypeBitMask")
			local v36_ = (self.absUVSlotIndex - 1) * 2
			local v37_ = 16777215 - bit32.lshift(3, v36_)
			local v38_ = bit32.band(v35_, v37_)
			local v39_ = StaticLightCompoundLightType.BLINKING - 1
			local v40_ = bit32.lshift(v39_, v36_)
			local v41_ = bit32.bor(v38_, v40_)
			setShaderParameter(self.node, "lightTypeBitMask", v41_, nil, nil, nil, false)
		end
	end
end

-- Local values: lightCharge, intensity
function StaticLight:setState(isActive, chargeScale)
	if self.toggleVisibility then
		setVisibility(self.node, isActive)
		return
	else
		local v45_ = self.intensity * (chargeScale or (isActive and 1 or 0))
		if self.useLightControlShaderParameter then
			setShaderParameter(self.node, "lightControl", v45_, nil, nil, nil, false)
		elseif self.uvSlotIndex == nil then
			setShaderParameter(self.node, "lightIds0", v45_, v45_, v45_, v45_, false)
			setShaderParameter(self.node, "lightIds1", v45_, v45_, v45_, v45_, false)
			setShaderParameter(self.node, "lightIds2", v45_, v45_, v45_, v45_, false)
			setShaderParameter(self.node, "lightIds3", v45_, v45_, v45_, v45_, false)
		else
			if self.uvSlotIndex == 1 then
				setShaderParameter(self.node, self.uvSlotParameter, v45_, nil, nil, nil, false)
				return
			end
			if self.uvSlotIndex == 2 then
				setShaderParameter(self.node, self.uvSlotParameter, nil, v45_, nil, nil, false)
				return
			end
			if self.uvSlotIndex == 3 then
				setShaderParameter(self.node, self.uvSlotParameter, nil, nil, v45_, nil, false)
				return
			end
			if self.uvSlotIndex == 4 then
				setShaderParameter(self.node, self.uvSlotParameter, nil, nil, nil, v45_, false)
				return
			end
		end
	end
end

function StaticLight:setChargeFunction(func, funcTarget)
	self.chargeFunction = func
	self.chargeFunctionTarget = funcTarget
end

-- Local values: _, key, light, otherLight
function StaticLight.loadLightsFromXML(lights, xmlFile, baseKey, vehicle, components, i3dMappings, loadLightTypes, sharedLight)
	local v57_ = lights == nil and {} or lights
	for _, v58_ in xmlFile:iterator(baseKey) do
		local v59_ = StaticLight.new(vehicle)
		if v59_:loadFromXML(xmlFile, v58_, components, i3dMappings, loadLightTypes, sharedLight) then
			if vehicle ~= nil then
				local v60_ = vehicle:getStaticLightFromNode(v59_.node)
				if v60_ ~= nil then
					v59_ = v59_:merge(v60_)
				end
			end
			table.insert(v57_, v59_)
		end
	end
	return v57_
end

function StaticLight.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Visual light node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#shaderNode", "Shader node")
	schema:register(XMLValueType.INT, basePath .. "#uvSlotIndex", "UV slot if vehicleShader with \'lightIds\' shader parameter is used (slot 1-16)", "if not defined, all slots will be set equally")
	schema:register(XMLValueType.FLOAT, basePath .. "#intensity", "Intensity", 5)
	schema:register(XMLValueType.BOOL, basePath .. "#toggleVisibility", "Toggle visibility", false)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
end
