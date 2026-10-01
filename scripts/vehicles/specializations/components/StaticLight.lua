StaticLight = {}
local StaticLight_mt = Class(StaticLight)
function StaticLight.new(vehicle, customMt)
	local self = setmetatable({}, customMt or StaticLight_mt)
	self.vehicle = vehicle
	self.chargeFunction = nil
	return self
end
function StaticLight:loadFromXML(xmlFile, baseKey, components, i3dMappings, loadLightTypes, sharedLight)
	self.node = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings) or xmlFile:getValue(baseKey .. "#shaderNode", nil, components, i3dMappings)
	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing static lights node in '%s'", baseKey)
		return false
	elseif getHasClassId(self.node, ClassIds.LIGHT_SOURCE) then
		Logging.xmlWarning(xmlFile, "Light source used in static light '%s'", baseKey)
		return false
	elseif not getHasClassId(self.node, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "Node used in static light '%s' is not a shape", baseKey)
		return false
	else
		if sharedLight ~= nil then
			local isValid = false
			local parent = self.node
			while parent ~= nil do
				if parent == 0 or parent == getRootNode() then
					break
				end
				if parent == sharedLight.node then
					isValid = true
					break
				end
				parent = getParent(parent)
			end
			if not isValid then
				Logging.xmlWarning(xmlFile, "Static light mesh '%s' is outside of the root shared light node (%s) in '%s'", getName(self.node), getName(sharedLight.node), baseKey)
				return false
			end
		end
		self.useLightControlShaderParameter = getHasShaderParameter(self.node, "lightControl")
		if not self.useLightControlShaderParameter then
			self.absUVSlotIndex = xmlFile:getValue(baseKey .. "#uvSlotIndex")
			if self.absUVSlotIndex ~= nil then
				self.uvSlotParameter = "lightIds0"
				self.uvSlotIndex = self.absUVSlotIndex
				if 4 < self.uvSlotIndex then
					self.uvSlotParameter = "lightIds1"
					self.uvSlotIndex = self.uvSlotIndex - 4
				end
				if 4 < self.uvSlotIndex then
					self.uvSlotParameter = "lightIds2"
					self.uvSlotIndex = self.uvSlotIndex - 4
				end
				if 4 < self.uvSlotIndex then
					self.uvSlotParameter = "lightIds3"
					self.uvSlotIndex = self.uvSlotIndex - 4
				end
			end
		end
		self.intensity = xmlFile:getValue(baseKey .. "#intensity", 5)
		self.toggleVisibility = xmlFile:getValue(baseKey .. "#toggleVisibility", false)
		if self.toggleVisibility then
			setVisibility(self.node, false)
		elseif not getHasShaderParameter(self.node, "lightControl") then
			if not getHasShaderParameter(self.node, "lightIds0") then
				Logging.xmlWarning(xmlFile, "Static lights not using 'lightControl' or 'lightIds0' shader parameter in '%s'", baseKey)
				return false
			end
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
			for k, v in pairs(sharedLight.additionalAttributes) do
				self[k] = v
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
end
function StaticLight:merge(otherLight)
	if self.uvSlotIndex ~= nil and (self.uvSlotIndex ~= otherLight.uvSlotIndex or self.uvSlotParameter ~= otherLight.uvSlotParameter) then
		return self
	end
	for i, lightType in ipairs(self.lightTypes) do
		table.addElement(otherLight.lightTypes, lightType)
	end
	for i, excludedLightType in ipairs(self.excludedLightTypes) do
		table.addElement(otherLight.excludedLightTypes, excludedLightType)
	end
	return otherLight
end
function StaticLight:setLightTypesMask(lightsTypesMask)
	if #self.lightTypes == 0 then
		return
	elseif self.vehicle == nil then
		return
	elseif self.vehicle:getIsLightActive(self) then
		local isActive = false
		local chargeScale = nil
		for _, lightType in pairs(self.lightTypes) do
			if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 or lightType == -1 and self.vehicle:getIsActiveForLights(true) then
				if not isActive then
					isActive = true
				elseif self.vehicle.spec_lights.maxLightState < lightType then
					chargeScale = 2
				end
			end
		end
		if isActive and self.excludedLightTypes ~= nil then
			for _, excludedLightType in pairs(self.excludedLightTypes) do
				if bit32.band(lightsTypesMask, 2 ^ excludedLightType) ~= 0 then
					isActive = false
					break
				end
			end
		end
		if self.chargeFunction ~= nil then
			chargeScale = self.chargeFunction(self.chargeFunctionTarget)
		end
		self:setState(isActive, chargeScale)
	else
		self:setState(false, 0)
	end
end
function StaticLight:setIsBlinking(isBlinking)
	if not self.useLightControlShaderParameter then
		if self.absUVSlotIndex == nil then
			local lightTypeBitMask = 0
			for i = 0, 11 do
				lightTypeBitMask = bit32.bor(lightTypeBitMask, bit32.lshift(StaticLightCompoundLightType.BLINKING - 1, i * 2))
			end
			setShaderParameter(self.node, "lightTypeBitMask", lightTypeBitMask, nil, nil, nil, false)
			return
		end
		if self.absUVSlotIndex <= 12 then
			local lightTypeBitMask = getShaderParameter(self.node, "lightTypeBitMask")
			local bitIndex = (self.absUVSlotIndex - 1) * 2
			local mask = 16777215 - bit32.lshift(3, bitIndex)
			lightTypeBitMask = bit32.band(lightTypeBitMask, mask)
			lightTypeBitMask = bit32.bor(lightTypeBitMask, bit32.lshift(StaticLightCompoundLightType.BLINKING - 1, bitIndex))
			setShaderParameter(self.node, "lightTypeBitMask", lightTypeBitMask, nil, nil, nil, false)
		end
	end
end
function StaticLight:setState(isActive, chargeScale)
	if self.toggleVisibility then
		setVisibility(self.node, isActive)
		return
	end
	if not chargeScale then
		local lightCharge = isActive and 1 or 0
	end
	local intensity = self.intensity * lightCharge
	if self.useLightControlShaderParameter then
		setShaderParameter(self.node, "lightControl", intensity, nil, nil, nil, false)
	else
		if self.uvSlotIndex ~= nil then
			if self.uvSlotIndex == 1 then
				setShaderParameter(self.node, self.uvSlotParameter, intensity, nil, nil, nil, false)
				return
			end
			if self.uvSlotIndex == 2 then
				setShaderParameter(self.node, self.uvSlotParameter, nil, intensity, nil, nil, false)
				return
			end
			if self.uvSlotIndex == 3 then
				setShaderParameter(self.node, self.uvSlotParameter, nil, nil, intensity, nil, false)
				return
			end
			if self.uvSlotIndex == 4 then
				setShaderParameter(self.node, self.uvSlotParameter, nil, nil, nil, intensity, false)
			end
		else
			setShaderParameter(self.node, "lightIds0", intensity, intensity, intensity, intensity, false)
			setShaderParameter(self.node, "lightIds1", intensity, intensity, intensity, intensity, false)
			setShaderParameter(self.node, "lightIds2", intensity, intensity, intensity, intensity, false)
			setShaderParameter(self.node, "lightIds3", intensity, intensity, intensity, intensity, false)
		end
	end
end
function StaticLight:setChargeFunction(func, funcTarget)
	self.chargeFunction = func
	self.chargeFunctionTarget = funcTarget
end
function StaticLight.loadLightsFromXML(lights, xmlFile, baseKey, vehicle, components, i3dMappings, loadLightTypes, sharedLight)
	if lights == nil then
		lights = {}
	end
	for _, key in xmlFile:iterator(baseKey) do
		local light = StaticLight.new(vehicle)
		if light:loadFromXML(xmlFile, key, components, i3dMappings, loadLightTypes, sharedLight) then
			if vehicle ~= nil then
				local otherLight = vehicle:getStaticLightFromNode(light.node)
				if otherLight ~= nil then
					light = light:merge(otherLight)
				end
			end
			table.insert(lights, light)
		end
	end
	return lights
end
function StaticLight.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Visual light node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#shaderNode", "Shader node")
	schema:register(XMLValueType.INT, basePath .. "#uvSlotIndex", "UV slot if vehicleShader with 'lightIds' shader parameter is used (slot 1-16)", "if not defined, all slots will be set equally")
	schema:register(XMLValueType.FLOAT, basePath .. "#intensity", "Intensity", 5)
	schema:register(XMLValueType.BOOL, basePath .. "#toggleVisibility", "Toggle visibility", false)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
end
