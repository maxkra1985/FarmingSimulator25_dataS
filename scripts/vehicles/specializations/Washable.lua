Washable = {}
Washable.SEND_NUM_BITS = 6
Washable.SEND_MAX_VALUE = 2 ^ Washable.SEND_NUM_BITS - 1
Washable.SEND_THRESHOLD = 1 / Washable.SEND_MAX_VALUE
Washable.SEND_NUM_BITS_WETNESS = 4
Washable.SEND_MAX_VALUE_WETNESS = 2 ^ Washable.SEND_NUM_BITS_WETNESS - 1
Washable.SEND_THRESHOLD_WETNESS = 1 / Washable.SEND_MAX_VALUE_WETNESS
Washable.WASHTYPE_HIGH_PRESSURE_WASHER = 1
Washable.WASHTYPE_RAIN = 2
Washable.WASHTYPE_TRIGGER = 3
Washable.SHADER_PARAMETERS = { "scratches_dirt_snow_wetness", "mudAmount" }

function Washable.prerequisitesPresent(specializations)
	return true
end
function Washable.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Washable")
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#dirtDuration", "Duration until fully dirty (minutes)", 90)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#washDuration", "Duration until fully clean (minutes)", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#rainWashDuration", "Duration until fully clean when it rains (minutes)", 10)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#wetDuration", "Duration until fully wet (ingame minutes)", 10)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#dryDuration", "Duration until the vehicle is fully dry again (ingame minutes)", 120)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#workMultiplier", "Multiplier while working", 4)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#fieldMultiplier", "Multiplier while on field", 2)
	v1_:register(XMLValueType.FLOAT, "vehicle.washable#wetMultiplier", "Multiplier while on it\'s wet", 5)
	v1_:register(XMLValueType.STRING, "vehicle.washable#blockedWashTypes", "Block specific ways to clean vehicle (HIGH_PRESSURE_WASHER, RAIN, TRIGGER)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.washable.wetnessIgnoreNode(?)#node", "Node, including it\'s children will never get wet")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#amount", "Dirt amount")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#snowScale", "Snow scale")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#wetness", "Wetness")
end

function Washable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "cleanVehicle", Washable.cleanVehicle)
	SpecializationUtil.registerFunction(vehicleType, "updateDirtAmount", Washable.updateDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "addDirtAmount", Washable.addDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "setDirtAmount", Washable.setDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getDirtAmount", Washable.getDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeDirtAmount", Washable.setNodeDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getNodeDirtAmount", Washable.getNodeDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeDirtColor", Washable.setNodeDirtColor)
	SpecializationUtil.registerFunction(vehicleType, "updateWetness", Washable.updateWetness)
	SpecializationUtil.registerFunction(vehicleType, "getIsWet", Washable.getIsWet)
	SpecializationUtil.registerFunction(vehicleType, "addWetnessAmount", Washable.addWetnessAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeWetness", Washable.setNodeWetness)
	SpecializationUtil.registerFunction(vehicleType, "addAllSubWashableNodes", Washable.addAllSubWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "addWashableNodes", Washable.addWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "addWashableNode", Washable.addWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "validateWashableNode", Washable.validateWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToGlobalWashableNode", Washable.addToGlobalWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "getWashableNodeByCustomIndex", Washable.getWashableNodeByCustomIndex)
	SpecializationUtil.registerFunction(vehicleType, "addToLocalWashableNode", Washable.addToLocalWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "removeAllSubWashableNodes", Washable.removeAllSubWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "removeWashableNode", Washable.removeWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "getDirtMultiplier", Washable.getDirtMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWorkDirtMultiplier", Washable.getWorkDirtMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWashDuration", Washable.getWashDuration)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsWashingByType", Washable.getAllowsWashingByType)
end

function Washable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Washable)
end

-- Local values: spec, _, key, node, blockedWashTypesStr, blockedWashTypes, _, typeStr
function Washable:onLoad(savegame)
	local v6_ = self.spec_washable
	v6_.wetnessIgnoreNodes = {}
	for _, v7_ in self.xmlFile:iterator("vehicle.washable.wetnessIgnoreNode") do
		local v8_ = self.xmlFile:getValue(v7_ .. "#node", nil, self.components, self.i3dMappings)
		if v8_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid node for wetnessIgnoreNode \'%s\'", v7_)
		else
			v6_.wetnessIgnoreNodes[v8_] = true
		end
	end
	v6_.washableNodes = {}
	v6_.washableNodesByIndex = {}
	self:addToLocalWashableNode(nil, Washable.updateDirtAmount, nil, nil)
	v6_.globalWashableNode = v6_.washableNodes[1]
	v6_.dirtDuration = self.xmlFile:getValue("vehicle.washable#dirtDuration", 90) * 60 * 1000
	if v6_.dirtDuration ~= 0 then
		v6_.dirtDuration = 1 / v6_.dirtDuration
	end
	local v9_ = self.xmlFile:getValue("vehicle.washable#washDuration", 1) * 60 * 1000
	v6_.washDuration = math.max(v9_, 0.00001)
	local v10_ = self.xmlFile:getValue("vehicle.washable#rainWashDuration", 10) * 60 * 1000
	v6_.rainWashDuration = math.max(v10_, 0.00001)
	v6_.wetDuration = self.xmlFile:getValue("vehicle.washable#wetDuration", 10) / 60 / 1000
	local v11_ = self.xmlFile:getValue("vehicle.washable#dryDuration", 120) * 60 * 1000
	v6_.dryDuration = 1 / math.max(v11_, 0.0001)
	v6_.workMultiplier = self.xmlFile:getValue("vehicle.washable#workMultiplier", 4)
	v6_.fieldMultiplier = self.xmlFile:getValue("vehicle.washable#fieldMultiplier", 2)
	v6_.wetMultiplier = self.xmlFile:getValue("vehicle.washable#wetMultiplier", 5)
	v6_.blockedWashTypes = {}
	local v12_ = self.xmlFile:getValue("vehicle.washable#blockedWashTypes")
	if v12_ ~= nil then
		local v13_ = v12_:split(" ")
		for _, v14_ in pairs(v13_) do
			local v15_ = "WASHTYPE_" .. v14_
			if Washable[v15_] == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wash type \'%s\' in \'%s\'", v15_, "vehicle.washable#blockedWashTypes")
			else
				v6_.blockedWashTypes[Washable[v15_]] = true
			end
		end
	end
	v6_.lastDirtMultiplier = 0
	v6_.dirtyFlag = self:getNextDirtyFlag()
	if self.propertyState == VehiclePropertyState.SHOP_CONFIG then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Washable)
	end
end

-- Local values: spec, _, component, i, nodeData, nodeKey, amount, wetness, i, nodeData
function Washable:onLoadFinished(savegame)
	local v18_ = self.spec_washable
	for _, v19_ in pairs(self.components) do
		self:addAllSubWashableNodes(v19_.node)
	end
	if savegame == nil or Washable.getIntervalMultiplier() == 0 then
		for v20_ = 1, #v18_.washableNodes do
			self:setNodeDirtAmount(v18_.washableNodes[v20_], 0, true)
		end
	else
		for v21_ = 1, #v18_.washableNodes do
			local v22_ = v18_.washableNodes[v21_]
			local v23_ = string.format("%s.washable.dirtNode(%d)", savegame.key, v21_ - 1)
			self:setNodeDirtAmount(v22_, savegame.xmlFile:getValue(v23_ .. "#amount", 0), true)
			self:setNodeWetness(v22_, savegame.xmlFile:getValue(v23_ .. "#wetness", 0), true)
			if v22_.loadFromSavegameFunc ~= nil then
				v22_.loadFromSavegameFunc(savegame.xmlFile, v23_)
			end
		end
	end
end

-- Local values: spec, i, nodeData, nodeKey
function Washable:saveToXMLFile(xmlFile, key, usedModNames)
	local v27_ = self.spec_washable
	for v28_ = 1, #v27_.washableNodes do
		local v29_ = v27_.washableNodes[v28_]
		local v30_ = string.format("%s.dirtNode(%d)", key, v28_ - 1)
		xmlFile:setValue(v30_ .. "#amount", v29_.dirtAmount)
		xmlFile:setValue(v30_ .. "#wetness", v29_.wetness)
		if v29_.saveToSavegameFunc ~= nil then
			v29_.saveToSavegameFunc(xmlFile, v30_)
		end
	end
end

function Washable:onReadStream(streamId, connection)
	Washable.readWashableNodeData(self, streamId, connection)
end

function Washable:onWriteStream(streamId, connection)
	Washable.writeWashableNodeData(self, streamId, connection)
end

-- Local values: spec
function Washable:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and (self.spec_washable.washableNodes ~= nil and streamReadBool(streamId)) then
		Washable.readWashableNodeData(self, streamId, connection)
	end
end

-- Local values: spec
function Washable:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v44_ = self.spec_washable
		local v45_ = streamWriteBool
		local v46_ = v44_.dirtyFlag
		if v45_(streamId, bit32.band(dirtyMask, v46_) ~= 0) then
			Washable.writeWashableNodeData(self, streamId, connection)
		end
	end
end

-- Local values: spec, i, nodeData, dirtAmount, wetness, r, g, b
function Washable:readWashableNodeData(streamId, connection)
	local v49_ = self.spec_washable
	for v50_ = 1, #v49_.washableNodes do
		local v51_ = v49_.washableNodes[v50_]
		self:setNodeDirtAmount(v51_, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, true)
		self:setNodeWetness(v51_, streamReadUIntN(streamId, Washable.SEND_NUM_BITS_WETNESS) / Washable.SEND_MAX_VALUE_WETNESS, true)
		if streamReadBool(streamId) then
			self:setNodeDirtColor(v51_, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, true)
		end
	end
end

-- Local values: spec, i, nodeData
function Washable:writeWashableNodeData(streamId, connection)
	local v54_ = self.spec_washable
	for v55_ = 1, #v54_.washableNodes do
		local v56_ = v54_.washableNodes[v55_]
		local v57_ = streamWriteUIntN
		local v58_ = v56_.dirtAmount * Washable.SEND_MAX_VALUE + 0.5
		v57_(streamId, math.floor(v58_), Washable.SEND_NUM_BITS)
		local v59_ = streamWriteUIntN
		local v60_ = v56_.wetness * Washable.SEND_MAX_VALUE_WETNESS + 0.5
		v59_(streamId, math.floor(v60_), Washable.SEND_NUM_BITS_WETNESS)
		streamWriteBool(streamId, v56_.colorChanged)
		if v56_.colorChanged then
			local v61_ = streamWriteUIntN
			local v62_ = v56_.color[1] * Washable.SEND_MAX_VALUE + 0.5
			v61_(streamId, math.floor(v62_), Washable.SEND_NUM_BITS)
			local v63_ = streamWriteUIntN
			local v64_ = v56_.color[2] * Washable.SEND_MAX_VALUE + 0.5
			v63_(streamId, math.floor(v64_), Washable.SEND_NUM_BITS)
			local v65_ = streamWriteUIntN
			local v66_ = v56_.color[3] * Washable.SEND_MAX_VALUE + 0.5
			v65_(streamId, math.floor(v66_), Washable.SEND_NUM_BITS)
			v56_.colorChanged = false
		end
	end
end

-- Local values: spec, allowsWashingByRain, rainScale, timeSinceLastRain, temperature, weather, i, nodeData, changeDirt, changeWetness
function Washable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v69_ = self.spec_washable
		v69_.lastDirtMultiplier = self:getDirtMultiplier() * Washable.getIntervalMultiplier() * Platform.gameplay.dirtDurationScale
		local v70_ = self:getAllowsWashingByType(Washable.WASHTYPE_RAIN)
		local v71_, v72_, v73_
		if v70_ then
			local v74_ = g_currentMission.environment.weather
			v71_ = v74_:getRainFallScale()
			v72_ = v74_:getTimeSinceLastRain()
			v73_ = v74_:getCurrentTemperature()
		else
			v72_ = 0
			v73_ = 0
			v71_ = 0
		end
		for v75_ = 1, #v69_.washableNodes do
			local v76_ = v69_.washableNodes[v75_]
			local v77_, v78_ = v76_.updateFunc(self, v76_, dt, v70_, v71_, v72_, v73_)
			if v77_ ~= 0 then
				self:setNodeDirtAmount(v76_, v76_.dirtAmount + v77_)
			end
			if v78_ ~= 0 then
				self:setNodeWetness(v76_, v76_.wetness + v78_)
			end
		end
	end
end

-- Local values: spec, i, nodeData, nodeAmount
function Washable:cleanVehicle(amount)
	local v81_ = self.spec_washable
	for v82_ = 1, #v81_.washableNodes do
		local v83_ = v81_.washableNodes[v82_]
		local v84_ = amount * (v83_.cleaningMultiplier or 1)
		self:setNodeDirtAmount(v83_, v83_.dirtAmount - v84_, true)
		self:setNodeWetness(v83_, v83_.wetness + v84_ * 5, true)
	end
end

-- Local values: spec, changeDirt, changeWetness, dirtMultiplier
function Washable:updateDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
	local v92_ = self.spec_washable
	local v93_ = 0
	local v94_ = v92_.lastDirtMultiplier
	local v95_ = (not allowsWashingByRain or (rainScale <= 0.1 or (timeSinceLastRain >= 30 or (temperature <= 0 or (nodeData.dirtAmount <= 0.5 or self:getIsOnField() and self:getLastSpeed() >= 1))))) and 0 or -(dt / v92_.rainWashDuration)
	if temperature > 0 and (rainScale > 0.1 and timeSinceLastRain < 30) then
		v94_ = v94_ * 2.5
	end
	if v94_ ~= 0 then
		v95_ = dt * v92_.dirtDuration * v94_
	end
	return v95_, v93_
end

-- Local values: spec, i, nodeData
function Washable:addDirtAmount(dirtAmount, force)
	local v99_ = self.spec_washable
	for v100_ = 1, #v99_.washableNodes do
		local v101_ = v99_.washableNodes[v100_]
		self:setNodeDirtAmount(v101_, v101_.dirtAmount + dirtAmount, force)
	end
end

-- Local values: spec, i, nodeData
function Washable:setDirtAmount(dirtAmount)
	local v104_ = self.spec_washable
	for v105_ = 1, #v104_.washableNodes do
		local v106_ = v104_.washableNodes[v105_]
		if v106_.wheelDirtNode == nil then
			self:setNodeDirtAmount(v106_, dirtAmount, true)
		else
			self:setNodeDirtAmount(v106_, (dirtAmount - 0.75) / 0.25, true)
		end
	end
end

-- Local values: spec
function Washable:getDirtAmount()
	local v108_ = self.spec_washable
	return #v108_.washableNodes <= 0 and 0 or v108_.washableNodes[1].dirtAmount
end

-- Local values: spec, diff, node, _, node, _, node, _
function Washable:setNodeDirtAmount(nodeData, dirtAmount, force)
	local v113_ = self.spec_washable
	nodeData.dirtAmount = math.clamp(dirtAmount, 0, 1)
	local v114_ = nodeData.dirtAmountSent - nodeData.dirtAmount
	if math.abs(v114_) > Washable.SEND_THRESHOLD or (force or nodeData.dirtAmount == 0 and nodeData.dirtAmountSent ~= 0) then
		for v115_, _ in pairs(nodeData.nodes) do
			setShaderParameter(v115_, "scratches_dirt_snow_wetness", nil, nodeData.dirtAmount, nil, nil, false)
		end
		if nodeData.wheelDirtNode == nil then
			for v116_, _ in pairs(nodeData.mudNodes) do
				g_animationManager:setPrevShaderParameter(v116_, "mudAmount", (nodeData.dirtAmount - 0.75) / 0.25, 0, 0, 0, false, "prevMudAmount")
			end
		else
			for v117_, _ in pairs(nodeData.mudNodes) do
				g_animationManager:setPrevShaderParameter(v117_, "mudAmount", nodeData.dirtAmount, 0, 0, 0, false, "prevMudAmount")
			end
		end
		if self.isServer then
			self:raiseDirtyFlags(v113_.dirtyFlag)
			nodeData.dirtAmountSent = nodeData.dirtAmount
		end
	end
end

function Washable:getNodeDirtAmount(nodeData)
	return nodeData.dirtAmount
end

-- Local values: spec, cr, cg, cb, node, _, node, _
function Washable:setNodeDirtColor(nodeData, r, g, b, force)
	local v125_ = self.spec_washable
	local v126_ = nodeData.color[1]
	local v127_ = nodeData.color[2]
	local v128_ = nodeData.color[3]
	local v129_ = r - v126_
	if math.abs(v129_) <= Washable.SEND_THRESHOLD then
		local v130_ = g - v127_
		if math.abs(v130_) <= Washable.SEND_THRESHOLD then
			local v131_ = b - v128_
			if math.abs(v131_) <= Washable.SEND_THRESHOLD and not force then
				::l5::
				return
			end
		end
	end
	for v132_, _ in pairs(nodeData.nodes) do
		setShaderParameter(v132_, "dirtColor", r, g, b, nil, false)
	end
	for v133_, _ in pairs(nodeData.mudNodes) do
		setShaderParameter(v133_, "dirtColor", r, g, b, nil, false)
	end
	local v134_ = nodeData.color
	local v135_ = nodeData.color
	local v136_ = nodeData.color
	v134_[1] = r
	v135_[2] = g
	v136_[3] = b
	if self.isServer then
		self:raiseDirtyFlags(v125_.dirtyFlag)
		nodeData.colorChanged = true
	end
	goto l5
end

-- Local values: spec, changeWetness, i, nodeData, dirtFactor
function Washable:updateWetness(isRaining, dt)
	local v140_ = self.spec_washable
	local v141_
	if isRaining then
		local v142_ = dt * v140_.wetDuration
		local v143_ = self.lastSpeed * 3600 / 10
		v141_ = v142_ * (1 + math.min(v143_, 1))
	else
		v141_ = nil
	end
	for v144_ = 1, #v140_.washableNodes do
		local v145_ = v140_.washableNodes[v144_]
		if not isRaining then
			local v146_ = (1 - v145_.dirtAmount) * 0.5 + 0.5
			local v147_ = -dt * v140_.dryDuration * v146_
			local v148_ = self.lastSpeed * 3600 / 10
			v141_ = v147_ * (1 + math.min(v148_, 1))
		end
		self:setNodeWetness(v145_, v145_.wetness + v141_)
	end
end

-- Local values: _, nodeData
function Washable:getIsWet()
	for _, v150_ in pairs(self.spec_washable.washableNodes) do
		if v150_.wetness > 0 then
			return true
		end
	end
	return false
end

-- Local values: spec, i, nodeData
function Washable:addWetnessAmount(amount)
	local v153_ = self.spec_washable
	for v154_ = 1, #v153_.washableNodes do
		local v155_ = v153_.washableNodes[v154_]
		self:setNodeWetness(v155_, v155_.wetness + amount)
	end
end

-- Local values: spec, diff, node, useWetness, node, useWetness
function Washable:setNodeWetness(nodeData, wetness, force)
	local v160_ = self.spec_washable
	nodeData.wetness = math.clamp(wetness, 0, 1)
	local v161_ = nodeData.wetnessSent - nodeData.wetness
	if math.abs(v161_) > Washable.SEND_THRESHOLD_WETNESS or force then
		for v162_, v163_ in pairs(nodeData.nodes) do
			if v163_ then
				setShaderParameter(v162_, "scratches_dirt_snow_wetness", nil, nil, nil, nodeData.wetness, false)
			end
		end
		for v164_, v165_ in pairs(nodeData.mudNodes) do
			if v165_ then
				setShaderParameter(v164_, "wetness", nodeData.wetness, nil, nil, nil, false)
			end
		end
		if self.isServer then
			self:raiseDirtyFlags(v160_.dirtyFlag)
			nodeData.wetnessSent = nodeData.wetness
		end
	end
end

function Washable:addAllSubWashableNodes(rootNode)
	if rootNode ~= nil then
		I3DUtil.iterateShaderParametersNodesRecursively(rootNode, Washable.SHADER_PARAMETERS, self.addWashableNode, self)
	end
	self:addDirtAmount(0, true)
end

-- Local values: _, node
function Washable:addWashableNodes(nodes)
	for _, v170_ in ipairs(nodes) do
		self:addWashableNode(v170_)
	end
end

-- Local values: isGlobal, updateFunc, customIndex, extraParams
function Washable:addWashableNode(node)
	local v173_, v174_, v175_, v176_ = self:validateWashableNode(node)
	if v173_ then
		self:addToGlobalWashableNode(node)
	elseif v174_ ~= nil then
		self:addToLocalWashableNode(node, v174_, v175_, v176_)
	end
end

function Washable:validateWashableNode(node)
	return true, nil
end

-- Local values: spec, useWetness, nodeToCheck
function Washable:addToGlobalWashableNode(node)
	local v179_ = self.spec_washable
	if v179_.washableNodes[1] ~= nil then
		local v180_ = true
		if next(v179_.wetnessIgnoreNodes) ~= nil then
			local v181_ = node
			while true do
				if node == 0 then
					node = v181_
					break
				end
				if v179_.wetnessIgnoreNodes[node] == true then
					node = v181_
					v180_ = false
					break
				end
				node = getParent(node)
			end
		end
		if getHasShaderParameter(node, "scratches_dirt_snow_wetness") then
			v179_.washableNodes[1].nodes[node] = v180_
			return
		end
		v179_.washableNodes[1].mudNodes[node] = v180_
	end
end

function Washable:getWashableNodeByCustomIndex(customIndex)
	return self.spec_washable.washableNodesByIndex[customIndex]
end

-- Local values: spec, useWetness, nodeToCheck, nodeData, defaultColor, _, i, v
function Washable:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
	local v189_ = self.spec_washable
	local v190_ = true
	if node ~= nil and next(v189_.wetnessIgnoreNodes) ~= nil then
		local v191_ = node
		while true do
			if node == 0 then
				node = v191_
				break
			end
			if v189_.wetnessIgnoreNodes[node] == true then
				node = v191_
				v190_ = false
				break
			end
			node = getParent(node)
		end
	end
	local v192_ = {}
	if customIndex ~= nil then
		if v189_.washableNodesByIndex[customIndex] ~= nil then
			if getHasShaderParameter(node, "scratches_dirt_snow_wetness") then
				v189_.washableNodesByIndex[customIndex].nodes[node] = v190_
			else
				v189_.washableNodesByIndex[customIndex].mudNodes[node] = v190_
			end
		end
		v189_.washableNodesByIndex[customIndex] = v192_
	end
	v192_.nodes = {}
	v192_.mudNodes = {}
	if node ~= nil then
		if getHasShaderParameter(node, "scratches_dirt_snow_wetness") then
			v192_.nodes[node] = v190_
		else
			v192_.mudNodes[node] = v190_
		end
	end
	v192_.updateFunc = updateFunc
	v192_.dirtAmount = 0
	v192_.dirtAmountSent = 0
	v192_.wetness = 0
	v192_.wetnessSent = 0
	v192_.colorChanged = false
	local v193_, _ = g_currentMission.environment:getDirtColors()
	v192_.color = { v193_[1], v193_[2], v193_[3] }
	v192_.defaultColor = { v193_[1], v193_[2], v193_[3] }
	if extraParams ~= nil then
		for v194_, v195_ in pairs(extraParams) do
			v192_[v194_] = v195_
		end
	end
	local v196_ = v189_.washableNodes
	table.insert(v196_, v192_)
end

function Washable:removeAllSubWashableNodes(rootNode)
	if rootNode ~= nil then
		I3DUtil.iterateShaderParametersNodesRecursively(rootNode, Washable.SHADER_PARAMETERS, self.removeWashableNode, self)
	end
end

-- Local values: spec, i
function Washable:removeWashableNode(node)
	local v201_ = self.spec_washable
	if node ~= nil then
		for v202_ = 1, #v201_.washableNodes do
			v201_.washableNodes[v202_].nodes[node] = nil
			v201_.washableNodes[v202_].mudNodes[node] = nil
		end
	end
end

-- Local values: spec, multiplier, wetness
function Washable:getDirtMultiplier()
	local v204_ = self.spec_washable
	local v205_ = self:getLastSpeed() < 1 and 0 or 1
	if self.isOnField then
		v205_ = v205_ * v204_.fieldMultiplier
		local v206_ = g_currentMission.environment.weather:getGroundWetness()
		if v206_ > 0 then
			v205_ = v205_ * (1 + v206_ * v204_.wetMultiplier)
		end
	end
	return v205_
end

-- Local values: spec
function Washable:getWorkDirtMultiplier()
	return self.spec_washable.workMultiplier
end

-- Local values: spec
function Washable:getWashDuration()
	return self.spec_washable.washDuration
end
function Washable.getIntervalMultiplier()
	return g_currentMission.missionInfo.dirtInterval == 1 and 0 or (g_currentMission.missionInfo.dirtInterval == 2 and 0.25 or (g_currentMission.missionInfo.dirtInterval == 3 and 0.5 or (g_currentMission.missionInfo.dirtInterval == 4 and 1 or 1)))
end

-- Local values: spec
function Washable:getAllowsWashingByType(type)
	return self.spec_washable.blockedWashTypes[type] == nil
end

-- Local values: spec, allowsWashingByRain, rainScale, timeSinceLastRain, temperature, weather, isRaining, changeWetness, i, nodeData, changedAmountDirt, changedAmountWetness, dirtFactor
function Washable:updateDebugValues(values)
	local v213_ = self.spec_washable
	if v213_.washableNodes ~= nil then
		local v214_ = self:getAllowsWashingByType(Washable.WASHTYPE_RAIN)
		local v215_, v216_, v217_
		if v214_ then
			local v218_ = g_currentMission.environment.weather
			v215_ = v218_:getRainFallScale()
			v216_ = v218_:getTimeSinceLastRain()
			v217_ = v218_:getCurrentTemperature()
		else
			v215_ = 0
			v216_ = 0
			v217_ = 0
		end
		local v219_
		if v215_ > 0.1 and v216_ < 30 then
			v219_ = v217_ > 0
		else
			v219_ = false
		end
		local v220_
		if v219_ then
			local v221_ = 3600000 * v213_.wetDuration
			local v222_ = self.lastSpeed * 3600 / 10
			v220_ = v221_ * (1 + math.min(v222_, 1))
		else
			v220_ = 0
		end
		local v223_ = {
			["name"] = "Dirt Multiplier",
			["value"] = string.format("%.3f", self:getDirtMultiplier())
		}
		table.insert(values, v223_)
		for v224_, v225_ in ipairs(v213_.washableNodes) do
			local v226_, v227_ = v225_.updateFunc(self, v225_, 3600000, v214_, v215_, v216_, v217_)
			local v228_
			if v219_ then
				v228_ = v227_ + v220_
			else
				local v229_ = (1 - v225_.dirtAmount) * 0.5 + 0.5
				local v230_ = 3600000 * v213_.dryDuration * v229_
				local v231_ = self.lastSpeed * 3600 / 10
				v228_ = v227_ - v230_ * (1 + math.min(v231_, 1))
			end
			local v232_ = {
				["name"] = "WashableNode" .. v224_,
				["value"] = string.format("%.4f a/h (%.2f) (color %.2f %.2f %.2f) (wetness: %.2f , %.4f a/min)", v226_, v213_.washableNodes[v224_].dirtAmount, v225_.color[1], v225_.color[2], v225_.color[3], v225_.wetness, v228_ / 60)
			}
			table.insert(values, v232_)
		end
	end
end
