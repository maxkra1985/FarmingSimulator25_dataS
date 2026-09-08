source("dataS/scripts/vehicles/specializations/events/WearableRepairEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WearableRepaintEvent.lua")
Wearable = {}
Wearable.SEND_NUM_BITS = 6
Wearable.SEND_MAX_VALUE = 2 ^ Wearable.SEND_NUM_BITS - 1
Wearable.SEND_THRESHOLD = 1 / Wearable.SEND_MAX_VALUE
Wearable.WEAR_FACTOR = 0.5

function Wearable.prerequisitesPresent(self)
	return true
end
function Wearable.initSpecialization()
	if Platform.gameplay.hasVehicleDamage then
		g_storeManager:addSpecType("wearable", "shopListAttributeIconCondition", Wearable.loadSpecValueCondition, Wearable.getSpecValueCondition, StoreSpecies.VEHICLE)
	end
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Wearable")
	v1_:register(XMLValueType.FLOAT, "vehicle.wearable#wearDuration", "Duration until fully worn (minutes)", 600)
	v1_:register(XMLValueType.FLOAT, "vehicle.wearable#workMultiplier", "Multiplier while working", 20)
	v1_:register(XMLValueType.FLOAT, "vehicle.wearable#fieldMultiplier", "Multiplier while on field", 2)
	v1_:register(XMLValueType.BOOL, "vehicle.wearable#showOnHud", "Show the damage on the hud", true)
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).wearable.wearNode(?)#amount", "Wear amount")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).wearable#damage", "Damage amount")
end

function Wearable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "addAllSubWearableNodes", Wearable.addAllSubWearableNodes)
	SpecializationUtil.registerFunction(vehicleType, "addDamageAmount", Wearable.addDamageAmount)
	SpecializationUtil.registerFunction(vehicleType, "addToGlobalWearableNode", Wearable.addToGlobalWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToLocalWearableNode", Wearable.addToLocalWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "addWearableNode", Wearable.addWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "addWearAmount", Wearable.addWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "getDamageAmount", Wearable.getDamageAmount)
	SpecializationUtil.registerFunction(vehicleType, "getDamageShowOnHud", Wearable.getDamageShowOnHud)
	SpecializationUtil.registerFunction(vehicleType, "getNodeWearAmount", Wearable.getNodeWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "getUsageCausesDamage", Wearable.getUsageCausesDamage)
	SpecializationUtil.registerFunction(vehicleType, "getUsageCausesWear", Wearable.getUsageCausesWear)
	SpecializationUtil.registerFunction(vehicleType, "getWearMultiplier", Wearable.getWearMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWearTotalAmount", Wearable.getWearTotalAmount)
	SpecializationUtil.registerFunction(vehicleType, "getWorkWearMultiplier", Wearable.getWorkWearMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "removeAllSubWearableNodes", Wearable.removeAllSubWearableNodes)
	SpecializationUtil.registerFunction(vehicleType, "removeWearableNode", Wearable.removeWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "repaintVehicle", Wearable.repaintVehicle)
	SpecializationUtil.registerFunction(vehicleType, "repairVehicle", Wearable.repairVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setDamageAmount", Wearable.setDamageAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeWearAmount", Wearable.setNodeWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "updateDamageAmount", Wearable.updateDamageAmount)
	SpecializationUtil.registerFunction(vehicleType, "updateWearAmount", Wearable.updateWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "validateWearableNode", Wearable.validateWearableNode)
end

function Wearable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleDamage", Wearable.getVehicleDamage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepairPrice", Wearable.getRepairPrice)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepaintPrice", Wearable.getRepaintPrice)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", Wearable.showInfo)
end

function Wearable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wearable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wearable)
	if not GS_IS_MOBILE_VERSION then
		SpecializationUtil.registerEventListener(vehicleType, "onSaleItemSet", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wearable)
	end
end

-- Local values: spec
function Wearable:onLoad(savegame)
	local v7_ = self.spec_wearable
	v7_.wearableNodes = {}
	v7_.wearableNodesByIndex = {}
	self:addToLocalWearableNode(nil, Wearable.updateWearAmount, nil, nil)
	v7_.wearDuration = self.xmlFile:getValue("vehicle.wearable#wearDuration", 600) * 60 * 1000
	if v7_.wearDuration ~= 0 then
		v7_.wearDuration = 1 / v7_.wearDuration * Wearable.WEAR_FACTOR
	end
	v7_.totalAmount = 0
	v7_.damage = 0
	v7_.damageByCurve = 0
	v7_.damageSent = 0
	v7_.workMultiplier = self.xmlFile:getValue("vehicle.wearable#workMultiplier", 20)
	v7_.fieldMultiplier = self.xmlFile:getValue("vehicle.wearable#fieldMultiplier", 2)
	v7_.showOnHud = self.xmlFile:getValue("vehicle.wearable#showOnHud", true)
	v7_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, _, component, i, nodeData, nodeKey, amount, _, nodeData
function Wearable:onLoadFinished(savegame)
	local v10_ = self.spec_wearable
	if savegame ~= nil then
		v10_.damage = savegame.xmlFile:getValue(savegame.key .. ".wearable#damage", 0)
		local v11_ = v10_.damage - 0.3
		v10_.damageByCurve = math.max(v11_, 0) / 0.7
	end
	if v10_.wearableNodes ~= nil then
		for _, v12_ in pairs(self.components) do
			self:addAllSubWearableNodes(v12_.node)
		end
		if savegame ~= nil then
			for v13_, v14_ in ipairs(v10_.wearableNodes) do
				local v15_ = string.format("%s.wearable.wearNode(%d)", savegame.key, v13_ - 1)
				self:setNodeWearAmount(v14_, savegame.xmlFile:getValue(v15_ .. "#amount", 0), true)
			end
			return
		end
		for _, v16_ in ipairs(v10_.wearableNodes) do
			self:setNodeWearAmount(v16_, 0, true)
		end
	end
end

function Wearable:onSaleItemSet(saleItem)
	self:addDamageAmount(saleItem.damage or 0, true)
	self:addWearAmount(saleItem.wear or 0, true)
end

-- Local values: spec, i, nodeData, nodeKey
function Wearable:saveToXMLFile(xmlFile, key, usedModNames)
	local v22_ = self.spec_wearable
	xmlFile:setValue(key .. "#damage", v22_.damage)
	if v22_.wearableNodes ~= nil then
		for v23_, v24_ in ipairs(v22_.wearableNodes) do
			xmlFile:setValue(string.format("%s.wearNode(%d)", key, v23_ - 1) .. "#amount", self:getNodeWearAmount(v24_))
		end
	end
end

-- Local values: spec, _, nodeData, wearAmount
function Wearable:onReadStream(streamId, connection)
	local v27_ = self.spec_wearable
	self:setDamageAmount(streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
	if v27_.wearableNodes ~= nil then
		for _, v28_ in ipairs(v27_.wearableNodes) do
			self:setNodeWearAmount(v28_, streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
		end
	end
end

-- Local values: spec, _, nodeData
function Wearable:onWriteStream(streamId, connection)
	local v31_ = self.spec_wearable
	local v32_ = streamWriteUIntN
	local v33_ = v31_.damage * Wearable.SEND_MAX_VALUE + 0.5
	v32_(streamId, math.floor(v33_), Wearable.SEND_NUM_BITS)
	if v31_.wearableNodes ~= nil then
		for _, v34_ in ipairs(v31_.wearableNodes) do
			local v35_ = streamWriteUIntN
			local v36_ = self:getNodeWearAmount(v34_) * Wearable.SEND_MAX_VALUE + 0.5
			v35_(streamId, math.floor(v36_), Wearable.SEND_NUM_BITS)
		end
	end
end

-- Local values: spec, _, nodeData, wearAmount
function Wearable:onReadUpdateStream(streamId, timestamp, connection)
	local v40_ = self.spec_wearable
	if connection:getIsServer() and streamReadBool(streamId) then
		self:setDamageAmount(streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
		if v40_.wearableNodes ~= nil then
			for _, v41_ in ipairs(v40_.wearableNodes) do
				self:setNodeWearAmount(v41_, streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
			end
		end
	end
end

-- Local values: spec, _, nodeData
function Wearable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v46_ = self.spec_wearable
	if not connection:getIsServer() then
		local v47_ = streamWriteBool
		local v48_ = v46_.dirtyFlag
		if v47_(streamId, bit32.band(dirtyMask, v48_) ~= 0) then
			local v49_ = streamWriteUIntN
			local v50_ = v46_.damage * Wearable.SEND_MAX_VALUE + 0.5
			v49_(streamId, math.floor(v50_), Wearable.SEND_NUM_BITS)
			if v46_.wearableNodes ~= nil then
				for _, v51_ in ipairs(v46_.wearableNodes) do
					local v52_ = streamWriteUIntN
					local v53_ = self:getNodeWearAmount(v51_) * Wearable.SEND_MAX_VALUE + 0.5
					v52_(streamId, math.floor(v53_), Wearable.SEND_NUM_BITS)
				end
			end
		end
	end
end

-- Local values: spec, changeAmount, _, nodeData, changedAmount
function Wearable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v56_ = self.spec_wearable
	if v56_.wearableNodes ~= nil and self.isServer then
		local v57_ = self:updateDamageAmount(dt)
		if v57_ ~= 0 then
			self:setDamageAmount(v56_.damage + v57_)
		end
		for _, v58_ in ipairs(v56_.wearableNodes) do
			local v59_ = v58_.updateFunc(self, v58_, dt)
			if v59_ ~= 0 then
				self:setNodeWearAmount(v58_, self:getNodeWearAmount(v58_) + v59_)
			end
		end
	end
end

-- Local values: spec, diff
function Wearable:setDamageAmount(amount, force)
	local v63_ = self.spec_wearable
	local v64_ = math.max(amount, 0)
	v63_.damage = math.min(v64_, 1)
	local v65_ = v63_.damage - 0.3
	v63_.damageByCurve = math.max(v65_, 0) / 0.7
	local v66_ = v63_.damageSent - v63_.damage
	if (math.abs(v66_) > Wearable.SEND_THRESHOLD or force) and self.isServer then
		self:raiseDirtyFlags(v63_.dirtyFlag)
		v63_.damageSent = v63_.damage
	end
end

-- Local values: spec
function Wearable:updateWearAmount(nodeData, dt)
	local v70_ = self.spec_wearable
	return not self:getUsageCausesWear() and 0 or dt * v70_.wearDuration * self:getWearMultiplier(nodeData) * 0.5
end

-- Local values: spec, factor, ageMultiplier, operatingTime, operatingTimeMultiplier
function Wearable:updateDamageAmount(dt)
	local v73_ = self.spec_wearable
	if not self:getUsageCausesDamage() then
		return 0
	end
	local v74_
	if self.lifetime == nil or self.lifetime == 0 then
		v74_ = 1
	else
		local v75_ = self.age / self.lifetime
		local v76_ = 0.15 * math.min(v75_, 1)
		local v77_ = self.operatingTime / 3600000 / (self.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO)
		local v78_ = 0.85 * math.min(v77_, 1)
		v74_ = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (v76_ + v78_)
	end
	return dt * v73_.wearDuration * 0.35 * v74_
end

function Wearable.getUsageCausesWear(self)
	return true
end

function Wearable:getUsageCausesDamage()
	if self.spec_motorized == nil and getIsSleeping(self.rootNode) then
		return false
	end
	local v80_ = self.isActive
	if v80_ then
		v80_ = self.propertyState ~= VehiclePropertyState.MISSION
	end
	return v80_
end

-- Local values: spec, _, nodeData
function Wearable:addWearAmount(wearAmount, force)
	local v84_ = self.spec_wearable
	if v84_.wearableNodes ~= nil then
		for _, v85_ in ipairs(v84_.wearableNodes) do
			self:setNodeWearAmount(v85_, self:getNodeWearAmount(v85_) + wearAmount, force)
		end
	end
end

-- Local values: spec
function Wearable:addDamageAmount(amount, force)
	self:setDamageAmount(self.spec_wearable.damage + amount, force)
end

-- Local values: spec, diff, _, node, i
function Wearable:setNodeWearAmount(nodeData, wearAmount, force)
	local v93_ = self.spec_wearable
	nodeData.wearAmount = math.clamp(wearAmount, 0, 1)
	local v94_ = nodeData.wearAmountSent - nodeData.wearAmount
	if math.abs(v94_) > Wearable.SEND_THRESHOLD or force then
		for _, v95_ in pairs(nodeData.nodes) do
			setShaderParameter(v95_, "scratches_dirt_snow_wetness", nodeData.wearAmount, nil, nil, nil, false)
		end
		if self.isServer then
			self:raiseDirtyFlags(v93_.dirtyFlag)
			nodeData.wearAmountSent = nodeData.wearAmount
		end
		v93_.totalAmount = 0
		for v96_ = 1, #v93_.wearableNodes do
			v93_.totalAmount = v93_.totalAmount + v93_.wearableNodes[v96_].wearAmount
		end
		v93_.totalAmount = v93_.totalAmount / #v93_.wearableNodes
	end
end

function Wearable:getNodeWearAmount(nodeData)
	return nodeData.wearAmount
end

function Wearable:getWearTotalAmount()
	return self.spec_wearable.totalAmount
end

function Wearable:getDamageAmount()
	return self.spec_wearable.damage
end

function Wearable:getDamageShowOnHud()
	return self.spec_wearable.showOnHud
end

-- Local values: total, _
function Wearable:repairVehicle()
	if self.isServer then
		g_currentMission:addMoney(-self:getRepairPrice(), self:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true, true)
		local v102_, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "repairVehicleCount", 1)
		if v102_ ~= nil then
			g_achievementManager:tryUnlock("VehicleRepairFirst", v102_)
			g_achievementManager:tryUnlock("VehicleRepair", v102_)
		end
	end
	self:setDamageAmount(0)
end

-- Local values: spec, total, _, _, data
function Wearable:repaintVehicle()
	local v104_ = self.spec_wearable
	if self.isServer then
		g_currentMission:addMoney(-self:getRepaintPrice(), self:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true, true)
		local v105_, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "repaintVehicleCount", 1)
		if v105_ ~= nil then
			g_achievementManager:tryUnlock("VehicleRepaint", v105_)
		end
	end
	for _, v106_ in ipairs(v104_.wearableNodes) do
		self:setNodeWearAmount(v106_, 0, true)
	end
end

function Wearable:getRepairPrice(superFunc)
	return superFunc(self) + Wearable.calculateRepairPrice(self:getPrice(), self.spec_wearable.damage)
end

function Wearable.calculateRepairPrice(price, damage)
	return price * math.pow(damage, 1.5) * 0.09
end

function Wearable:getRepaintPrice(superFunc)
	return superFunc(self) + Wearable.calculateRepaintPrice(self:getPrice(), self:getWearTotalAmount())
end

-- Local values: damage
function Wearable:showInfo(superFunc, box)
	local v116_ = self.spec_wearable.damage
	if v116_ > 0.01 then
		box:addLine(g_i18n:getText("infohud_damage"), string.format("%d %%", v116_ * 100))
	end
	superFunc(self, box)
end

function Wearable.calculateRepaintPrice(price, wear)
	local v119_ = wear / 100
	return price * math.sqrt(v119_) * 2
end

function Wearable:getVehicleDamage(superFunc)
	local v122_ = superFunc(self) + self.spec_wearable.damageByCurve
	return math.min(v122_, 1)
end

function Wearable:addAllSubWearableNodes(rootNode)
	if rootNode ~= nil then
		I3DUtil.iterateShaderParameterNodesRecursively(rootNode, "scratches_dirt_snow_wetness", self.addWearableNode, self)
	end
end

-- Local values: isGlobal, updateFunc, customIndex, extraParams
function Wearable:addWearableNode(node)
	local v127_, v128_, v129_, v130_ = self:validateWearableNode(node)
	if v127_ then
		self:addToGlobalWearableNode(node)
	elseif v128_ ~= nil then
		self:addToLocalWearableNode(node, v128_, v129_, v130_)
	end
end

function Wearable:validateWearableNode(node)
	return true, nil
end

-- Local values: spec
function Wearable:addToGlobalWearableNode(node)
	local v133_ = self.spec_wearable
	if v133_.wearableNodes[1] ~= nil then
		v133_.wearableNodes[1].nodes[node] = node
	end
end

-- Local values: spec, nodeData, i, v
function Wearable:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
	local v139_ = self.spec_wearable
	local v140_ = {}
	if customIndex ~= nil then
		if v139_.wearableNodesByIndex[customIndex] ~= nil then
			v139_.wearableNodesByIndex[customIndex].nodes[node] = node
			return
		end
		v139_.wearableNodesByIndex[customIndex] = v140_
	end
	v140_.nodes = {}
	if node ~= nil then
		v140_.nodes[node] = node
	end
	v140_.updateFunc = updateFunc
	v140_.wearAmount = 0
	v140_.wearAmountSent = 0
	if extraParams ~= nil then
		for v141_, v142_ in pairs(extraParams) do
			v140_[v141_] = v142_
		end
	end
	local v143_ = v139_.wearableNodes
	table.insert(v143_, v140_)
end

function Wearable:removeAllSubWearableNodes(rootNode)
	if rootNode ~= nil then
		I3DUtil.iterateShaderParameterNodesRecursively(rootNode, "scratches_dirt_snow_wetness", self.removeWearableNode, self)
	end
end

-- Local values: spec, _, nodeData
function Wearable:removeWearableNode(node)
	local v148_ = self.spec_wearable
	if v148_.wearableNodes ~= nil and node ~= nil then
		for _, v149_ in ipairs(v148_.wearableNodes) do
			v149_.nodes[node] = nil
		end
	end
end

-- Local values: spec, multiplier
function Wearable:getWearMultiplier()
	local v151_ = self.spec_wearable
	local v152_ = self:getLastSpeed() < 1 and 0 or 1
	if self.isOnField then
		v152_ = v152_ * v151_.fieldMultiplier
	end
	return v152_
end

-- Local values: spec
function Wearable:getWorkWearMultiplier()
	return self.spec_wearable.workMultiplier
end

-- Local values: spec, changedAmount, i, nodeData
function Wearable:updateDebugValues(values)
	local v156_ = self.spec_wearable
	local v157_ = self:updateDamageAmount(3600000)
	local v158_ = {
		["name"] = "Damage",
		["value"] = string.format("%.4f a/h (%.2f)", v157_, self:getDamageAmount())
	}
	table.insert(values, v158_)
	if v156_.wearableNodes ~= nil and self.isServer then
		for v159_, v160_ in ipairs(v156_.wearableNodes) do
			local v161_ = v160_.updateFunc(self, v160_, 3600000)
			local v162_ = {
				["name"] = "WearableNode" .. v159_,
				["value"] = string.format("%.4f a/h (%.6f)", v161_, self:getNodeWearAmount(v160_))
			}
			table.insert(values, v162_)
		end
	end
end

function Wearable.loadSpecValueCondition(xmlFile, customEnvironment, baseDir)
	return nil
end

function Wearable.getSpecValueCondition(storeItem, realItem)
	if realItem == nil then
		return nil
	elseif realItem.getDamageAmount == nil then
		return nil
	else
		return string.format("%d%%", realItem:getDamageAmount() * 100)
	end
end
