StaticLightCompound = {}
source("dataS/scripts/vehicles/specializations/components/StaticLightCompoundUVSlot.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLightCompoundLightType.lua")
local StaticLightCompound_mt = Class(StaticLightCompound)
function StaticLightCompound.new(vehicle, customMt)
	local self = setmetatable({}, customMt or StaticLightCompound_mt)
	self.vehicle = vehicle
	return self
end
function StaticLightCompound.loadFunctionMappingData(xmlFile, baseKey)
	local data = {}
	for _, functionKey in xmlFile:iterator(baseKey .. ".function") do
		local functionName = xmlFile:getValue(functionKey .. "#name")
		if functionName ~= nil then
			local defaultSlotIndex = StaticLightCompoundUVSlot.getByName(functionName)
			if defaultSlotIndex ~= nil then
				local uvSlotIndex = xmlFile:getValue(functionKey .. "#uvSlotIndex", defaultSlotIndex)
				if 1 <= uvSlotIndex then
					if uvSlotIndex <= 16 then
						local uvOffset = xmlFile:getValue(functionKey .. "#uvOffset", 0)
						local intensityScale = xmlFile:getValue(functionKey .. "#intensityScale", 1)
						local lightTypeStr = xmlFile:getValue(functionKey .. "#lightType")
						local lightTypeIndex = StaticLightCompoundLightType.getByName(lightTypeStr)
						table.insert(data, { defaultSlotIndex = defaultSlotIndex, uvSlotIndex = uvSlotIndex, uvOffset = uvOffset, intensityScale = intensityScale, lightTypeIndex = lightTypeIndex })
					else
						Logging.xmlWarning(xmlFile, "UV slot index out of range '%d' in '%s'. Range 1-16 is allowed.", uvSlotIndex, functionKey)
					end
				end
			else
				Logging.xmlWarning(xmlFile, "Invalid function name '%s' in '%s'", functionName, functionKey)
			end
		else
			Logging.xmlWarning(xmlFile, "Missing function name in '%s'", functionKey)
		end
	end
	return data
end
function StaticLightCompound:loadFromXML(xmlFile, baseKey, components, i3dMappings, vehicle, sharedLight)
	self.bottomLightAsHighBeam = xmlFile:getValue(baseKey .. "#bottomLightAsHighBeam", true)
	self.topLightAsHighBeam = xmlFile:getValue(baseKey .. "#topLightAsHighBeam", true)
	self.useSliderTurnLights = xmlFile:getValue(baseKey .. "#useSliderTurnLights", false)
	self.intensity = {}
	self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] = 1.4
	self.intensity[StaticLightCompoundUVSlot.DAY_TIME_RUNNING_LIGHT] = 0.4
	self.funcToUVSlotMapping = {}
	for index = 1, 16 do
		local i = {}
		self.funcToUVSlotMapping[index] = i
	end
	local data = StaticLightCompound.loadFunctionMappingData(xmlFile, baseKey)
	for i, mappingData in ipairs(data) do
		table.insert(self.funcToUVSlotMapping[mappingData.defaultSlotIndex], mappingData)
	end
	if sharedLight ~= nil and sharedLight.functionMappingData ~= nil then
		for _, mappingData in ipairs(sharedLight.functionMappingData) do
			for mappedFuncIndex, mappedSlots in pairs(self.funcToUVSlotMapping) do
				for i = #mappedSlots, 1, -1 do
					local mappedSlot = mappedSlots[i]
					if mappedSlot.uvSlotIndex == mappingData.uvSlotIndex then
						table.remove(mappedSlots, i)
					end
				end
			end
		end
		for i, mappingData in ipairs(sharedLight.functionMappingData) do
			table.insert(self.funcToUVSlotMapping[mappingData.defaultSlotIndex], mappingData)
		end
	end
	for index = 1, 16 do
		local uvSlotIsUsed = false
		for mappedFuncIndex, mappedSlots in pairs(self.funcToUVSlotMapping) do
			for _, mappedSlot in pairs(mappedSlots) do
				if mappedSlot.uvSlotIndex == index then
					uvSlotIsUsed = true
					break
				end
			end
			if not uvSlotIsUsed then
				continue
			end
			if not uvSlotIsUsed then
				table.insert(self.funcToUVSlotMapping[index], { uvSlotIndex = index, uvOffset = 0, intensityScale = 1 })
			end
		end
	end
	self.nodes = {}
	for _, nodeKey in xmlFile:iterator(baseKey .. ".node") do
		local node = xmlFile:getValue(nodeKey .. "#node", nil, components, i3dMappings)
		if node ~= nil then
			if sharedLight ~= nil then
				local isValid = false
				local parent = node
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
					Logging.xmlWarning(xmlFile, "Static compound light mesh '%s' is outside of the root shared light node (%s) in '%s'", getName(node), getName(sharedLight.node), baseKey)
				elseif getHasClassId(node, ClassIds.LIGHT_SOURCE) then
					Logging.xmlWarning(xmlFile, "Light source used in static light compound in '%s'", nodeKey)
				elseif not getHasClassId(node, ClassIds.SHAPE) then
					Logging.xmlWarning(xmlFile, "Node used in static light compound in '%s' is not a shape", nodeKey)
				elseif not getHasShaderParameter(node, "lightIds0") then
					Logging.xmlWarning(xmlFile, "Wrong shader applied to static light compound in '%s'. Missing 'lightIds' shader parameter.", nodeKey)
				else
					setShaderParameter(node, "lightIds0", 0, 0, 0, 0, false)
					setShaderParameter(node, "lightIds1", 0, 0, 0, 0, false)
					setShaderParameter(node, "lightIds2", 0, 0, 0, 0, false)
					setShaderParameter(node, "lightIds3", 0, 0, 0, 0, false)
					local nodeData = {}
					nodeData.node = node
					nodeData.intensity = xmlFile:getValue(nodeKey .. "#intensity", 5)
					nodeData.useSliderTurnLights = xmlFile:getValue(nodeKey .. "#useSliderTurnLights", self.useSliderTurnLights)
					if vehicle ~= nil and xmlFile:getRootName() == "vehicle" then
						vehicle:loadAdditionalLightAttributesFromXML(xmlFile, nodeKey, nodeData)
					end
					if sharedLight ~= nil and sharedLight.additionalAttributes ~= nil then
						for k, v in pairs(sharedLight.additionalAttributes) do
							nodeData[k] = v
						end
					end
					table.insert(self.nodes, nodeData)
				end
			end
		else
			Logging.xmlWarning(xmlFile, "Invalid node in '%s'", nodeKey)
		end
	end
	if #self.nodes == 0 then
		Logging.xmlWarning(xmlFile, "Missing nodes for static light compound in '%s'", baseKey)
		return false
	else
		self.states = {}
		self.stateFuncTypes = {}
		self.stateLightTypes = {}
		self.stateUVOffsets = {}
		for i = 1, 16 do
			table.insert(self.states, 0)
			table.insert(self.stateFuncTypes, 0)
			table.insert(self.stateLightTypes, -1)
			table.insert(self.stateUVOffsets, 0)
		end
		return true
	end
end
function StaticLightCompound:setLightTypes(lightTypes, excludedLightTypes)
	if lightTypes ~= nil and next(lightTypes) ~= nil then
		self.lightTypes = lightTypes
	end
	if excludedLightTypes ~= nil and next(excludedLightTypes) ~= nil then
		self.excludedLightTypes = excludedLightTypes
	end
end
function StaticLightCompound:setOverwriteSettings(turnLightLeft, turnLightRight, reverseLight)
	self.turnLightLeft = turnLightLeft
	self.turnLightRight = turnLightRight
	self.reverseLight = reverseLight
	if turnLightLeft then
		if self.lightTypes == nil then
			self.lightTypes = {}
		end
		table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightLeft)
		table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightAny)
	end
	if turnLightRight then
		if self.lightTypes == nil then
			self.lightTypes = {}
		end
		table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightRight)
		table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightAny)
	end
	if reverseLight then
		if self.lightTypes == nil then
			self.lightTypes = {}
		end
		table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.reverseLight)
	end
end
function StaticLightCompound:setLightTypesMask(lightsTypesMask, vehicle)
	local startIndex = 1
	if self.lightTypes ~= nil then
		local isActive = false
		for _, lightType in pairs(self.lightTypes) do
			if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 then
				isActive = true
				break
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
		self.states[1] = isActive and 1 or 0
		if self.turnLightLeft then
			self.stateFuncTypes[1] = StaticLightCompoundUVSlot.TURN_LIGHT_LEFT
		elseif self.turnLightRight then
			self.stateFuncTypes[1] = StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT
		end
		startIndex = 2
	end
	for index = startIndex, 16 do
		self.states[index] = 0
		self.stateFuncTypes[index] = 0
		self.stateLightTypes[index] = -1
		self.stateUVOffsets[index] = 0
		for mappedFuncIndex, mappedSlots in pairs(self.funcToUVSlotMapping) do
			for _, mappedSlot in pairs(mappedSlots) do
				if mappedSlot.uvSlotIndex == index then
					local value = self:getStateValueByFunction(index, mappedFuncIndex, lightsTypesMask, vehicle)
					if 0 < value then
						self.states[index] = value * (self.intensity[mappedFuncIndex] or 1) * mappedSlot.intensityScale
						if self.stateFuncTypes[index] ~= StaticLightCompoundUVSlot.TURN_LIGHT_LEFT and self.stateFuncTypes[index] ~= StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
							self.stateFuncTypes[index] = mappedFuncIndex
						end
						self.stateUVOffsets[index] = mappedSlot.uvOffset
						if mappedSlot.lightTypeIndex ~= nil then
							self.stateLightTypes[index] = mappedSlot.lightTypeIndex
						end
					end
				end
			end
		end
	end
	local lightTypesMask = self:getLightTypeMaskFromStates(self.useSliderTurnLights)
	local lightUvOffsetBitMask = self:getUVOffsetMaskFromStates()
	for i, nodeData in ipairs(self.nodes) do
		if vehicle:getIsLightActive(nodeData) then
			local intensity = nodeData.intensity
			setShaderParameter(nodeData.node, "lightIds0", self.states[1] * intensity, self.states[2] * intensity, self.states[3] * intensity, self.states[4] * intensity, false)
			setShaderParameter(nodeData.node, "lightIds1", self.states[5] * intensity, self.states[6] * intensity, self.states[7] * intensity, self.states[8] * intensity, false)
			setShaderParameter(nodeData.node, "lightIds2", self.states[9] * intensity, self.states[10] * intensity, self.states[11] * intensity, self.states[12] * intensity, false)
			setShaderParameter(nodeData.node, "lightIds3", self.states[13] * intensity, self.states[14] * intensity, self.states[15] * intensity, self.states[16] * intensity, false)
			if self.useSliderTurnLights ~= nodeData.useSliderTurnLights then
				local nodeLightTypesMask = self:getLightTypeMaskFromStates(nodeData.useSliderTurnLights)
				setShaderParameter(nodeData.node, "lightTypeBitMask", nodeLightTypesMask, nil, nil, nil, false)
			else
				setShaderParameter(nodeData.node, "lightTypeBitMask", lightTypesMask, nil, nil, nil, false)
			end
			setShaderParameter(nodeData.node, "lightUvOffsetBitMask", lightUvOffsetBitMask, nil, nil, nil, false)
		else
			setShaderParameter(nodeData.node, "lightIds0", 0, 0, 0, 0, false)
			setShaderParameter(nodeData.node, "lightIds1", 0, 0, 0, 0, false)
			setShaderParameter(nodeData.node, "lightIds2", 0, 0, 0, 0, false)
			setShaderParameter(nodeData.node, "lightIds3", 0, 0, 0, 0, false)
		end
	end
end
function StaticLightCompound:getStateValueByFunction(uvSlotIndex, funcIndex, lightsTypesMask, vehicle)
	local spec = vehicle.spec_lights
	local highBeamActive = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM) ~= 0
	local value = 0
	if funcIndex == StaticLightCompoundUVSlot.DEFAULT_LIGHT then
		value = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 and 1 or 0
		return value
	else
		if funcIndex == StaticLightCompoundUVSlot.DEFAULT_LIGHT_HIGH_BEAM then
			if not highBeamActive then
				value = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 and 1 or 0
				if highBeamActive then
					value = math.max(value, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
					return value
				end
			end
		else
			if funcIndex == StaticLightCompoundUVSlot.HIGH_BEAM then
				value = highBeamActive and 1 or 0
				return value
			end
			if funcIndex == StaticLightCompoundUVSlot.BOTTOM_LIGHT then
				value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.bottomLight) ~= 0 and 1 or 0
				if self.bottomLightAsHighBeam and (not spec.topLightsVisibility and highBeamActive) then
					value = math.max(value, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
					return value
				end
			elseif funcIndex == StaticLightCompoundUVSlot.TOP_LIGHT then
				value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.topLight) ~= 0 and 1 or 0
				if self.topLightAsHighBeam and (spec.topLightsVisibility and highBeamActive) then
					value = math.max(value, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
					return value
				end
			else
				if funcIndex == StaticLightCompoundUVSlot.DAY_TIME_RUNNING_LIGHT and not vehicle:getIsPowered() then
					value = vehicle:getIsInShowroom() and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_LEFT and bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightLeft) == 0 then
					value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightAny) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT and bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightRight) == 0 then
					value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightAny) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.BACK_LIGHT then
					value = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.BRAKE_LIGHT then
					value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.brakeLight) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.BACK_BRAKE_LIGHT then
					local chargeScale = 0
					if bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
						chargeScale = chargeScale + 1
					end
					if bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.brakeLight) ~= 0 then
						chargeScale = chargeScale + 1
					end
					value = chargeScale
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.REVERSE_LIGHT then
					value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.reverseLight) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_FRONT then
					value = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_BACK then
					value = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_BACK) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_ADDITIONAL then
					value = bit32.band(lightsTypesMask, 2 ^ (Lights.LIGHT_TYPE_HIGHBEAM + 1)) ~= 0 and 1 or 0
					return value
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_ADDITIONAL2 then
					value = bit32.band(lightsTypesMask, 2 ^ (Lights.LIGHT_TYPE_HIGHBEAM + 2)) ~= 0 and 1 or 0
				end
			end
		end
		return value
	end
end
function StaticLightCompound:getLightTypeMaskFromStates(slider)
	local mask = 0
	for index = 1, 12 do
		local funcIndex = self.stateFuncTypes[index]
		local type = nil
		if funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_LEFT or funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
			type = slider and StaticLightCompoundLightType.SLIDE or StaticLightCompoundLightType.BLINKING
		end
		if self.stateLightTypes[index] ~= -1 then
			type = self.stateLightTypes[index]
		end
		if type == nil then
			continue
		end
		mask = bit32.bor(bit32.lshift(type - 1, (index - 1) * 2), mask)
	end
	return mask
end
function StaticLightCompound:getUVOffsetMaskFromStates()
	local mask = 0
	local offset = self.stateUVOffsets[1]
	mask = bit32.bor(bit32.lshift(offset, 0), mask)
	local offset = self.stateUVOffsets[2]
	mask = bit32.bor(bit32.lshift(offset, 6), mask)
	local offset = self.stateUVOffsets[3]
	mask = bit32.bor(bit32.lshift(offset, 12), mask)
	local offset = self.stateUVOffsets[4]
	mask = bit32.bor(bit32.lshift(offset, 18), mask)
	return mask
end
function StaticLightCompound.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#bottomLightAsHighBeam", "Use bottom light as high beam as well", true)
	schema:register(XMLValueType.BOOL, basePath .. "#topLightAsHighBeam", "Use top light as high beam as well", true)
	schema:register(XMLValueType.BOOL, basePath .. "#useSliderTurnLights", "Turn lights will work as sliders if set to 'true'", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Static light node")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#intensity", "Intensity for all lights in this node", 5)
	schema:register(XMLValueType.BOOL, basePath .. ".node(?)#useSliderTurnLights", "Turn lights will work as sliders if set to 'true'", false)
	schema:register(XMLValueType.INT, basePath .. ".node(?)#lightTypeBitMask", "Custom light type bit mask")
	schema:register(XMLValueType.STRING, basePath .. ".function(?)#name", "Function name", nil, nil, StaticLightCompoundUVSlot.getAllOrderedByName())
	schema:register(XMLValueType.INT, basePath .. ".function(?)#uvSlotIndex", "Custom UV slot index to assign the defined function name")
	schema:register(XMLValueType.INT, basePath .. ".function(?)#uvOffset", "Vertical UV offset that is used while this light function is active (value range: 0-64 -> this represents the height of the texture with a resolution of 1/64). This is used for double usage of certain lights with different colors.", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".function(?)#intensityScale", "Custom intensity scale for this light type (is multiplied by the intensity defined in the node)")
	schema:register(XMLValueType.STRING, basePath .. ".function(?)#lightType", "Name of the light type to use", nil, nil, StaticLightCompoundLightType.getAllOrderedByName())
	schema:register(XMLValueType.INT, basePath .. "#lightTypeBitMask", "Custom light type bit mask", "Default mask is '20480' with blinking type set for turn light slots 7 & 8")
end
