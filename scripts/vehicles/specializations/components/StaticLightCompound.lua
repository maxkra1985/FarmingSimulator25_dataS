-- Local values: StaticLightCompound_mt
StaticLightCompound = {}
source("dataS/scripts/vehicles/specializations/components/StaticLightCompoundUVSlot.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLightCompoundLightType.lua")
local StaticLightCompound_mt = Class(StaticLightCompound)

-- Upvalues: StaticLightCompound_mt
-- Local values: self
function StaticLightCompound.new(vehicle, customMt)
	-- upvalues: (copy) StaticLightCompound_mt
	local v4_ = customMt or StaticLightCompound_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	return v5_
end

-- Local values: data, _, functionKey, functionName, defaultSlotIndex, uvSlotIndex, uvOffset, intensityScale, lightTypeStr, lightTypeIndex
function StaticLightCompound.loadFunctionMappingData(xmlFile, baseKey)
	local v8_ = {}
	for _, v9_ in xmlFile:iterator(baseKey .. ".function") do
		local v10_ = xmlFile:getValue(v9_ .. "#name")
		if v10_ == nil then
			Logging.xmlWarning(xmlFile, "Missing function name in \'%s\'", v9_)
		else
			local v11_ = StaticLightCompoundUVSlot.getByName(v10_)
			if v11_ == nil then
				Logging.xmlWarning(xmlFile, "Invalid function name \'%s\' in \'%s\'", v10_, v9_)
			else
				local v12_ = xmlFile:getValue(v9_ .. "#uvSlotIndex", v11_)
				if v12_ >= 1 and v12_ <= 16 then
					local v13_ = xmlFile:getValue(v9_ .. "#uvOffset", 0)
					local v14_ = xmlFile:getValue(v9_ .. "#intensityScale", 1)
					local v15_ = xmlFile:getValue(v9_ .. "#lightType")
					local v16_ = {
						["defaultSlotIndex"] = v11_,
						["uvSlotIndex"] = v12_,
						["uvOffset"] = v13_,
						["intensityScale"] = v14_,
						["lightTypeIndex"] = StaticLightCompoundLightType.getByName(v15_)
					}
					table.insert(v8_, v16_)
				else
					Logging.xmlWarning(xmlFile, "UV slot index out of range \'%d\' in \'%s\'. Range 1-16 is allowed.", v12_, v9_)
				end
			end
		end
	end
	return v8_
end

-- Local values: index, data, i, mappingData, _, mappingData, mappedFuncIndex, mappedSlots, i, mappedSlot, i, mappingData, index, uvSlotIsUsed, mappedFuncIndex, mappedSlots, _, mappedSlot, _, nodeKey, node, isValid, parent, nodeData, k, v, i
function StaticLightCompound:loadFromXML(xmlFile, baseKey, components, i3dMappings, vehicle, sharedLight)
	self.bottomLightAsHighBeam = xmlFile:getValue(baseKey .. "#bottomLightAsHighBeam", true)
	self.topLightAsHighBeam = xmlFile:getValue(baseKey .. "#topLightAsHighBeam", true)
	self.useSliderTurnLights = xmlFile:getValue(baseKey .. "#useSliderTurnLights", false)
	self.intensity = {}
	self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] = 1.4
	self.intensity[StaticLightCompoundUVSlot.DAY_TIME_RUNNING_LIGHT] = 0.4
	self.funcToUVSlotMapping = {}
	for v24_ = 1, 16 do
		self.funcToUVSlotMapping[v24_] = {}
	end
	local v25_ = StaticLightCompound.loadFunctionMappingData(xmlFile, baseKey)
	for _, v26_ in ipairs(v25_) do
		local v27_ = self.funcToUVSlotMapping[v26_.defaultSlotIndex]
		table.insert(v27_, v26_)
	end
	if sharedLight ~= nil and sharedLight.functionMappingData ~= nil then
		for _, v28_ in ipairs(sharedLight.functionMappingData) do
			for _, v29_ in pairs(self.funcToUVSlotMapping) do
				for v30_ = #v29_, 1, -1 do
					if v29_[v30_].uvSlotIndex == v28_.uvSlotIndex then
						table.remove(v29_, v30_)
					end
				end
			end
		end
		for _, v31_ in ipairs(sharedLight.functionMappingData) do
			local v32_ = self.funcToUVSlotMapping[v31_.defaultSlotIndex]
			table.insert(v32_, v31_)
		end
	end
	for v33_ = 1, 16 do
		local v34_ = false
		for _, v35_ in pairs(self.funcToUVSlotMapping) do
			for _, v36_ in pairs(v35_) do
				if v36_.uvSlotIndex == v33_ then
					v34_ = true
					break
				end
			end
			if v34_ then
				break
			end
		end
		if not v34_ then
			local v37_ = self.funcToUVSlotMapping[v33_]
			table.insert(v37_, {
				["uvSlotIndex"] = v33_,
				["uvOffset"] = 0,
				["intensityScale"] = 1
			})
		end
	end
	self.nodes = {}
	for _, v38_ in xmlFile:iterator(baseKey .. ".node") do
		local v39_ = xmlFile:getValue(v38_ .. "#node", nil, components, i3dMappings)
		if v39_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid node in \'%s\'", v38_)
		elseif sharedLight == nil then
			::l40::
			if getHasClassId(v39_, ClassIds.LIGHT_SOURCE) then
				Logging.xmlWarning(xmlFile, "Light source used in static light compound in \'%s\'", v38_)
			elseif getHasClassId(v39_, ClassIds.SHAPE) then
				if getHasShaderParameter(v39_, "lightIds0") then
					setShaderParameter(v39_, "lightIds0", 0, 0, 0, 0, false)
					setShaderParameter(v39_, "lightIds1", 0, 0, 0, 0, false)
					setShaderParameter(v39_, "lightIds2", 0, 0, 0, 0, false)
					setShaderParameter(v39_, "lightIds3", 0, 0, 0, 0, false)
					local v40_ = {
						["node"] = v39_,
						["intensity"] = xmlFile:getValue(v38_ .. "#intensity", 5),
						["useSliderTurnLights"] = xmlFile:getValue(v38_ .. "#useSliderTurnLights", self.useSliderTurnLights)
					}
					if vehicle ~= nil and xmlFile:getRootName() == "vehicle" then
						vehicle:loadAdditionalLightAttributesFromXML(xmlFile, v38_, v40_)
					end
					if sharedLight ~= nil and sharedLight.additionalAttributes ~= nil then
						for v41_, v42_ in pairs(sharedLight.additionalAttributes) do
							v40_[v41_] = v42_
						end
					end
					local v43_ = self.nodes
					table.insert(v43_, v40_)
				else
					Logging.xmlWarning(xmlFile, "Wrong shader applied to static light compound in \'%s\'. Missing \'lightIds\' shader parameter.", v38_)
				end
			else
				Logging.xmlWarning(xmlFile, "Node used in static light compound in \'%s\' is not a shape", v38_)
			end
		else
			local v44_ = v39_
			local v45_ = false
			while v39_ ~= nil and (v39_ ~= 0 and v39_ ~= getRootNode()) do
				if v39_ == sharedLight.node then
					v45_ = true
					break
				end
				v39_ = getParent(v39_)
			end
			if v45_ then
				v39_ = v44_
				goto l40
			end
			Logging.xmlWarning(xmlFile, "Static compound light mesh \'%s\' is outside of the root shared light node (%s) in \'%s\'", getName(v44_), getName(sharedLight.node), baseKey)
		end
	end
	if #self.nodes == 0 then
		Logging.xmlWarning(xmlFile, "Missing nodes for static light compound in \'%s\'", baseKey)
		return false
	end
	self.states = {}
	self.stateFuncTypes = {}
	self.stateLightTypes = {}
	self.stateUVOffsets = {}
	for _ = 1, 16 do
		local v46_ = self.states
		table.insert(v46_, 0)
		local v47_ = self.stateFuncTypes
		table.insert(v47_, 0)
		local v48_ = self.stateLightTypes
		table.insert(v48_, -1)
		local v49_ = self.stateUVOffsets
		table.insert(v49_, 0)
	end
	return true
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
		local v57_ = self.lightTypes
		local v58_ = self.vehicle.spec_lights.additionalLightTypes.turnLightLeft
		table.insert(v57_, v58_)
		local v59_ = self.lightTypes
		local v60_ = self.vehicle.spec_lights.additionalLightTypes.turnLightAny
		table.insert(v59_, v60_)
	end
	if turnLightRight then
		if self.lightTypes == nil then
			self.lightTypes = {}
		end
		local v61_ = self.lightTypes
		local v62_ = self.vehicle.spec_lights.additionalLightTypes.turnLightRight
		table.insert(v61_, v62_)
		local v63_ = self.lightTypes
		local v64_ = self.vehicle.spec_lights.additionalLightTypes.turnLightAny
		table.insert(v63_, v64_)
	end
	if reverseLight then
		if self.lightTypes == nil then
			self.lightTypes = {}
		end
		local v65_ = self.lightTypes
		local v66_ = self.vehicle.spec_lights.additionalLightTypes.reverseLight
		table.insert(v65_, v66_)
	end
end

-- Local values: startIndex, isActive, _, lightType, _, excludedLightType, index, mappedFuncIndex, mappedSlots, _, mappedSlot, value, lightTypesMask, lightUvOffsetBitMask, i, nodeData, intensity, nodeLightTypesMask
function StaticLightCompound:setLightTypesMask(lightsTypesMask, vehicle)
	local v70_
	if self.lightTypes == nil then
		v70_ = 1
	else
		local v71_ = false
		for _, v72_ in pairs(self.lightTypes) do
			local v73_ = 2 ^ v72_
			if bit32.band(lightsTypesMask, v73_) ~= 0 then
				v71_ = true
				break
			end
		end
		if v71_ and self.excludedLightTypes ~= nil then
			for _, v74_ in pairs(self.excludedLightTypes) do
				local v75_ = 2 ^ v74_
				if bit32.band(lightsTypesMask, v75_) ~= 0 then
					v71_ = false
					break
				end
			end
		end
		self.states[1] = v71_ and 1 or 0
		if self.turnLightLeft then
			self.stateFuncTypes[1] = StaticLightCompoundUVSlot.TURN_LIGHT_LEFT
			v70_ = 2
		elseif self.turnLightRight then
			self.stateFuncTypes[1] = StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT
			v70_ = 2
		else
			v70_ = 2
		end
	end
	for v76_ = v70_, 16 do
		self.states[v76_] = 0
		self.stateFuncTypes[v76_] = 0
		self.stateLightTypes[v76_] = -1
		self.stateUVOffsets[v76_] = 0
		for v77_, v78_ in pairs(self.funcToUVSlotMapping) do
			for _, v79_ in pairs(v78_) do
				if v79_.uvSlotIndex == v76_ then
					local v80_ = self:getStateValueByFunction(v76_, v77_, lightsTypesMask, vehicle)
					if v80_ > 0 then
						self.states[v76_] = v80_ * (self.intensity[v77_] or 1) * v79_.intensityScale
						if self.stateFuncTypes[v76_] ~= StaticLightCompoundUVSlot.TURN_LIGHT_LEFT and self.stateFuncTypes[v76_] ~= StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
							self.stateFuncTypes[v76_] = v77_
						end
						self.stateUVOffsets[v76_] = v79_.uvOffset
						if v79_.lightTypeIndex ~= nil then
							self.stateLightTypes[v76_] = v79_.lightTypeIndex
						end
						break
					end
				end
			end
		end
	end
	local v81_ = self:getLightTypeMaskFromStates(self.useSliderTurnLights)
	local v82_ = self:getUVOffsetMaskFromStates()
	for _, v83_ in ipairs(self.nodes) do
		if vehicle:getIsLightActive(v83_) then
			local v84_ = v83_.intensity
			setShaderParameter(v83_.node, "lightIds0", self.states[1] * v84_, self.states[2] * v84_, self.states[3] * v84_, self.states[4] * v84_, false)
			setShaderParameter(v83_.node, "lightIds1", self.states[5] * v84_, self.states[6] * v84_, self.states[7] * v84_, self.states[8] * v84_, false)
			setShaderParameter(v83_.node, "lightIds2", self.states[9] * v84_, self.states[10] * v84_, self.states[11] * v84_, self.states[12] * v84_, false)
			setShaderParameter(v83_.node, "lightIds3", self.states[13] * v84_, self.states[14] * v84_, self.states[15] * v84_, self.states[16] * v84_, false)
			if self.useSliderTurnLights == v83_.useSliderTurnLights then
				setShaderParameter(v83_.node, "lightTypeBitMask", v81_, nil, nil, nil, false)
			else
				local v85_ = self:getLightTypeMaskFromStates(v83_.useSliderTurnLights)
				setShaderParameter(v83_.node, "lightTypeBitMask", v85_, nil, nil, nil, false)
			end
			setShaderParameter(v83_.node, "lightUvOffsetBitMask", v82_, nil, nil, nil, false)
		else
			setShaderParameter(v83_.node, "lightIds0", 0, 0, 0, 0, false)
			setShaderParameter(v83_.node, "lightIds1", 0, 0, 0, 0, false)
			setShaderParameter(v83_.node, "lightIds2", 0, 0, 0, 0, false)
			setShaderParameter(v83_.node, "lightIds3", 0, 0, 0, 0, false)
		end
	end
end

-- Local values: spec, highBeamActive, value, chargeScale
function StaticLightCompound:getStateValueByFunction(uvSlotIndex, funcIndex, lightsTypesMask, vehicle)
	local v90_ = vehicle.spec_lights
	local v91_ = 2 ^ Lights.LIGHT_TYPE_HIGHBEAM
	local v92_ = bit32.band(lightsTypesMask, v91_) ~= 0
	local v93_ = 0
	if funcIndex == StaticLightCompoundUVSlot.DEFAULT_LIGHT then
		local v94_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
		return bit32.band(lightsTypesMask, v94_) == 0 and 0 or 1
	else
		if funcIndex == StaticLightCompoundUVSlot.DEFAULT_LIGHT_HIGH_BEAM then
			if v92_ then
				v93_ = 1
			else
				local v95_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
				v93_ = bit32.band(lightsTypesMask, v95_) == 0 and 0 or 1
			end
			if v92_ then
				return math.max(v93_, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
			end
		else
			if funcIndex == StaticLightCompoundUVSlot.HIGH_BEAM then
				return v92_ and 1 or 0
			end
			if funcIndex == StaticLightCompoundUVSlot.BOTTOM_LIGHT then
				local v96_ = 2 ^ v90_.additionalLightTypes.bottomLight
				v93_ = bit32.band(lightsTypesMask, v96_) == 0 and 0 or 1
				if self.bottomLightAsHighBeam and (not v90_.topLightsVisibility and v92_) then
					return math.max(v93_, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
				end
			elseif funcIndex == StaticLightCompoundUVSlot.TOP_LIGHT then
				local v97_ = 2 ^ v90_.additionalLightTypes.topLight
				v93_ = bit32.band(lightsTypesMask, v97_) == 0 and 0 or 1
				if self.topLightAsHighBeam and (v90_.topLightsVisibility and v92_) then
					return math.max(v93_, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
				end
			else
				if funcIndex == StaticLightCompoundUVSlot.DAY_TIME_RUNNING_LIGHT then
					return (vehicle:getIsPowered() or vehicle:getIsInShowroom()) and 1 or 0
				end
				if funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_LEFT then
					local v98_ = 2 ^ v90_.additionalLightTypes.turnLightLeft
					local v99_
					if bit32.band(lightsTypesMask, v98_) == 0 then
						local v100_ = 2 ^ v90_.additionalLightTypes.turnLightAny
						v99_ = bit32.band(lightsTypesMask, v100_) == 0 and 0 or 1
					else
						v99_ = 1
					end
					return v99_
				end
				if funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
					local v101_ = 2 ^ v90_.additionalLightTypes.turnLightRight
					local v102_
					if bit32.band(lightsTypesMask, v101_) == 0 then
						local v103_ = 2 ^ v90_.additionalLightTypes.turnLightAny
						v102_ = bit32.band(lightsTypesMask, v103_) == 0 and 0 or 1
					else
						v102_ = 1
					end
					return v102_
				end
				if funcIndex == StaticLightCompoundUVSlot.BACK_LIGHT then
					local v104_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
					return bit32.band(lightsTypesMask, v104_) == 0 and 0 or 1
				end
				if funcIndex == StaticLightCompoundUVSlot.BRAKE_LIGHT then
					local v105_ = 2 ^ v90_.additionalLightTypes.brakeLight
					return bit32.band(lightsTypesMask, v105_) == 0 and 0 or 1
				end
				if funcIndex == StaticLightCompoundUVSlot.BACK_BRAKE_LIGHT then
					local v106_ = 0
					local v107_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
					if bit32.band(lightsTypesMask, v107_) ~= 0 then
						v106_ = v106_ + 1
					end
					local v108_ = 2 ^ v90_.additionalLightTypes.brakeLight
					if bit32.band(lightsTypesMask, v108_) ~= 0 then
						v106_ = v106_ + 1
					end
					return v106_
				end
				if funcIndex == StaticLightCompoundUVSlot.REVERSE_LIGHT then
					local v109_ = 2 ^ v90_.additionalLightTypes.reverseLight
					return bit32.band(lightsTypesMask, v109_) == 0 and 0 or 1
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_FRONT then
					local v110_ = 2 ^ Lights.LIGHT_TYPE_WORK_FRONT
					return bit32.band(lightsTypesMask, v110_) == 0 and 0 or 1
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_BACK then
					local v111_ = 2 ^ Lights.LIGHT_TYPE_WORK_BACK
					return bit32.band(lightsTypesMask, v111_) == 0 and 0 or 1
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_ADDITIONAL then
					local v112_ = 2 ^ (Lights.LIGHT_TYPE_HIGHBEAM + 1)
					return bit32.band(lightsTypesMask, v112_) == 0 and 0 or 1
				end
				if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_ADDITIONAL2 then
					local v113_ = 2 ^ (Lights.LIGHT_TYPE_HIGHBEAM + 2)
					v93_ = bit32.band(lightsTypesMask, v113_) == 0 and 0 or 1
				end
			end
		end
		return v93_
	end
end

-- Local values: mask, index, funcIndex, type
function StaticLightCompound:getLightTypeMaskFromStates(slider)
	local v116_ = 0
	for v117_ = 1, 12 do
		local v118_ = self.stateFuncTypes[v117_]
		local v119_
		if v118_ == StaticLightCompoundUVSlot.TURN_LIGHT_LEFT or v118_ == StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
			v119_ = slider and StaticLightCompoundLightType.SLIDE or StaticLightCompoundLightType.BLINKING
		else
			v119_ = nil
		end
		if self.stateLightTypes[v117_] ~= -1 then
			v119_ = self.stateLightTypes[v117_]
		end
		if v119_ ~= nil then
			local v120_ = v119_ - 1
			local v121_ = (v117_ - 1) * 2
			local v122_ = bit32.lshift(v120_, v121_)
			v116_ = bit32.bor(v122_, v116_)
		end
	end
	return v116_
end

-- Local values: mask, offset, offset, offset, offset
function StaticLightCompound:getUVOffsetMaskFromStates()
	local v124_ = self.stateUVOffsets[1]
	local v125_ = bit32.lshift(v124_, 0)
	local v126_ = bit32.bor(v125_, 0)
	local v127_ = self.stateUVOffsets[2]
	local v128_ = bit32.lshift(v127_, 6)
	local v129_ = bit32.bor(v128_, v126_)
	local v130_ = self.stateUVOffsets[3]
	local v131_ = bit32.lshift(v130_, 12)
	local v132_ = bit32.bor(v131_, v129_)
	local v133_ = self.stateUVOffsets[4]
	local v134_ = bit32.lshift(v133_, 18)
	return bit32.bor(v134_, v132_)
end

function StaticLightCompound.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#bottomLightAsHighBeam", "Use bottom light as high beam as well", true)
	schema:register(XMLValueType.BOOL, basePath .. "#topLightAsHighBeam", "Use top light as high beam as well", true)
	schema:register(XMLValueType.BOOL, basePath .. "#useSliderTurnLights", "Turn lights will work as sliders if set to \'true\'", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Static light node")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#intensity", "Intensity for all lights in this node", 5)
	schema:register(XMLValueType.BOOL, basePath .. ".node(?)#useSliderTurnLights", "Turn lights will work as sliders if set to \'true\'", false)
	schema:register(XMLValueType.INT, basePath .. ".node(?)#lightTypeBitMask", "Custom light type bit mask")
	schema:register(XMLValueType.STRING, basePath .. ".function(?)#name", "Function name", nil, nil, StaticLightCompoundUVSlot.getAllOrderedByName())
	schema:register(XMLValueType.INT, basePath .. ".function(?)#uvSlotIndex", "Custom UV slot index to assign the defined function name")
	schema:register(XMLValueType.INT, basePath .. ".function(?)#uvOffset", "Vertical UV offset that is used while this light function is active (value range: 0-64 -> this represents the height of the texture with a resolution of 1/64). This is used for double usage of certain lights with different colors.", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".function(?)#intensityScale", "Custom intensity scale for this light type (is multiplied by the intensity defined in the node)")
	schema:register(XMLValueType.STRING, basePath .. ".function(?)#lightType", "Name of the light type to use", nil, nil, StaticLightCompoundLightType.getAllOrderedByName())
	schema:register(XMLValueType.INT, basePath .. "#lightTypeBitMask", "Custom light type bit mask", "Default mask is \'20480\' with blinking type set for turn light slots 7 & 8")
end
