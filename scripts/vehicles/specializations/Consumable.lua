Consumable = {}
Consumable.CONSUME_LEVEL_NUM_BITS = 7
Consumable.CONSUME_LEVEL_RESOLUTION = 2 ^ Consumable.CONSUME_LEVEL_NUM_BITS - 1
source("dataS/scripts/vehicles/specializations/events/ConsumableRefillEvent.lua")
source("dataS/scripts/vehicles/specializations/activatables/ConsumableActivatable.lua")
Consumable.CONFIG_NAMES = { "consumable", "consumable2" }

function Consumable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function Consumable.initSpecialization()
	for _, v2_ in ipairs(Consumable.CONFIG_NAMES) do
		g_vehicleConfigurationManager:addConfigurationType(v2_, g_i18n:getText("shop_configuration"), "consumable", VehicleConfigurationItem)
	end
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Consumable")
	for _, v4_ in ipairs(Consumable.CONFIG_NAMES) do
		v3_:register(XMLValueType.STRING, "vehicle.consumable." .. v4_ .. "Configurations#typeName", "Name of the consumable type that can be filled")
		v3_:register(XMLValueType.STRING, "vehicle.consumable." .. v4_ .. "Configurations." .. v4_ .. "Configuration(?)#consumableName", "Consumable Name")
	end
	v3_:register(XMLValueType.STRING, "vehicle.consumable.type(?)#typeName", "Name of the consumable type that can be filled")
	v3_:register(XMLValueType.STRING, "vehicle.consumable.type(?)#defaultConsumableName", "Name of the consumable that is loaded by default, if not given the tool spawns empty")
	v3_:register(XMLValueType.INT, "vehicle.consumable.type(?)#fillUnitIndex", "Fill unit index of the consumable fill unit", 1)
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?)#allowRefillDialog", "Defines if the type can be refilled via the UI dialog", true)
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?)#showWarning", "Show warning if the consumable is empty", true)
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?).consuming#useScale", "Scale the consuming meshes based on the fill level", false)
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?).consuming#useAmount", "Apply the fill level to the \'amount\' shader parameter", false)
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?).consuming#useHideByIndex", "Apply hideByIndex shader parameter to the consuming mesh", false)
	v3_:register(XMLValueType.FLOAT, "vehicle.consumable.type(?).consuming#hideByIndexOffset", "Offset for the hide by index fill level", 0)
	v3_:register(XMLValueType.STRING, "vehicle.consumable.type(?).consuming.animation(?)#name", "Name of the animation that is set based on the consuming fill level")
	v3_:register(XMLValueType.FLOAT, "vehicle.consumable.type(?).consuming.animation(?)#numLoops", "Number of times the animation is looping for the capacity of the consuming slots", 1)
	v3_:register(XMLValueType.INT, "vehicle.consumable.type(?).consuming.animation(?)#numSteps", "If defined, the animation will move in steps")
	v3_:register(XMLValueType.FLOAT, "vehicle.consumable.type(?).consuming.animation(?)#speedScale", "Speed of the animation", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.consumable.type(?).slot(?)#node", "Link node of visual slot")
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?).slot(?)#isConsumingSlot", "Slot is a consuming slot (different 3d model without packing if available)", false)
	v3_:register(XMLValueType.BOOL, "vehicle.consumable.type(?).slot(?)#useTensionBeltMesh", "A tension belt mesh will be loaded for this slot if available", "\'true\' for pallets")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.consumable.type(?).shaderParameterNode(?)#node", "Shader parameter defined in the consumable variation will be applied here as well")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v3_, "vehicle.consumable.type(?)")
	v3_:setXMLSpecializationType()
	local v5_ = Vehicle.xmlSchemaSavegame
	v5_:register(XMLValueType.STRING, "vehicles.vehicle(?).consumable.type(?)#typeName", "Consumer type name")
	v5_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).consumable.type(?)#consumingFillLevel", "Fill Level of consuming slots")
	v5_:register(XMLValueType.STRING, "vehicles.vehicle(?).consumable.type(?)#consumingVariationName", "Name of the variation that is currently loaded on the consuming slots")
	v5_:register(XMLValueType.STRING, "vehicles.vehicle(?).consumable.type(?).storageSlot(?)#consumableVariation", "Currently loaded consumer variation for slot")
end

function Consumable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onConsumableVariationChanged")
end

function Consumable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getConsumableVariationIndexByFillUnitIndex", Consumable.getConsumableVariationIndexByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setConsumableSlotVariationIndex", Consumable.setConsumableSlotVariationIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateConsumable", Consumable.updateConsumable)
	SpecializationUtil.registerFunction(vehicleType, "getConsumableIsAvailable", Consumable.getConsumableIsAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getShowConsumableEmptyWarning", Consumable.getShowConsumableEmptyWarning)
	SpecializationUtil.registerFunction(vehicleType, "getCustomFillTriggerSpeedFactor", Consumable.getCustomFillTriggerSpeedFactor)
end

function Consumable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", Consumable.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", Consumable.getFillUnitFreeCapacity)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "collectPalletTensionBeltNodes", Consumable.collectPalletTensionBeltNodes)
end

function Consumable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onDirtyMaskCleared", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitIsFillingStateChanged", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onAddedFillUnitTrigger", Consumable)
	SpecializationUtil.registerEventListener(vehicleType, "onRemovedFillUnitTrigger", Consumable)
end

-- Local values: spec, _, typeKey, type, _, slotKey, slot, _, animationKey, animation, _, paramKey, node, _, configName, configsKey, configurationId, typeName, type, configKey
function Consumable:onLoad(savegame)
	local v11_ = self.spec_consumable
	v11_.animationsDirty = false
	v11_.types = {}
	v11_.typesByName = {}
	for _, v12_ in self.xmlFile:iterator("vehicle.consumable.type") do
		local v13_ = {
			["typeName"] = self.xmlFile:getValue(v12_ .. "#typeName")
		}
		if v13_.typeName == nil then
			Logging.xmlWarning(self.xmlFile, "Missing type name in \'%s\'", v12_)
		else
			v13_.fillUnitIndex = self.xmlFile:getValue(v12_ .. "#fillUnitIndex")
			if v13_.fillUnitIndex == nil then
				Logging.xmlWarning(self.xmlFile, "Missing fillUnitIndex in \'%s\'", v12_)
			elseif self:getFillUnitByIndex(v13_.fillUnitIndex) == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid fillUnitIndex in \'%s\'", v12_)
			else
				v13_.defaultConsumableName = self.xmlFile:getValue(v12_ .. "#defaultConsumableName")
				v13_.allowRefillDialog = self.xmlFile:getValue(v12_ .. "#allowRefillDialog", true)
				v13_.showWarning = self.xmlFile:getValue(v12_ .. "#showWarning", true)
				v13_.slots = {}
				v13_.storageSlots = {}
				v13_.consumingSlots = {}
				for _, v14_ in self.xmlFile:iterator(v12_ .. ".slot") do
					local v15_ = {
						["node"] = self.xmlFile:getValue(v14_ .. "#node", nil, self.components, self.i3dMappings),
						["isConsumingSlot"] = self.xmlFile:getValue(v14_ .. "#isConsumingSlot", false),
						["useTensionBeltMesh"] = self.xmlFile:getValue(v14_ .. "#useTensionBeltMesh", self.setPalletTensionBeltNodesDirty ~= nil),
						["mesh"] = nil,
						["consumingMesh"] = nil,
						["consumableVariationIndex"] = 0
					}
					if v15_.isConsumingSlot then
						local v16_ = v13_.consumingSlots
						table.insert(v16_, v15_)
					else
						local v17_ = v13_.storageSlots
						table.insert(v17_, v15_)
					end
					local v18_ = v13_.slots
					table.insert(v18_, v15_)
				end
				v13_.useScale = self.xmlFile:getValue(v12_ .. ".consuming#useScale", false)
				v13_.useAmount = self.xmlFile:getValue(v12_ .. ".consuming#useAmount", false)
				v13_.useHideByIndex = self.xmlFile:getValue(v12_ .. ".consuming#useHideByIndex", false)
				v13_.hideByIndexOffset = self.xmlFile:getValue(v12_ .. ".consuming#hideByIndexOffset", 0)
				v13_.animations = {}
				for _, v19_ in self.xmlFile:iterator(v12_ .. ".consuming.animation") do
					local v20_ = {
						["name"] = self.xmlFile:getValue(v19_ .. "#name")
					}
					if v20_.name ~= nil then
						local v21_ = self.xmlFile:getValue(v19_ .. "#numLoops", 1)
						v20_.numLoops = math.max(v21_, 1)
						v20_.numSteps = self.xmlFile:getValue(v19_ .. "#numSteps")
						v20_.speedScale = self.xmlFile:getValue(v19_ .. "#speedScale", 1) * 0.001
						v20_.currentTime = 0
						local v22_ = v13_.animations
						table.insert(v22_, v20_)
					end
				end
				v13_.numSlots = #v13_.slots
				v13_.numStorageSlots = #v13_.storageSlots
				v13_.numConsumingSlots = #v13_.consumingSlots
				v13_.objectChanges = {}
				ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, v12_, v13_.objectChanges, self.components, self)
				ObjectChangeUtil.setObjectChanges(v13_.objectChanges, false, self, self.setMovingToolDirty)
				v13_.shaderParameterNodes = {}
				for _, v23_ in self.xmlFile:iterator(v12_ .. ".shaderParameterNode") do
					local v24_ = self.xmlFile:getValue(v23_ .. "#node", nil, self.components, self.i3dMappings)
					if v24_ ~= nil then
						local v25_ = v13_.shaderParameterNodes
						table.insert(v25_, v24_)
					end
				end
				v13_.consumingFillLevel = 0
				v13_.consumingFillLevelSent = 0
				v13_.consumingVariationIndex = 0
				v13_.lastConsumedVariationIndex = 0
				v13_.isDirty = false
				self:setFillUnitCapacity(v13_.fillUnitIndex, v13_.numStorageSlots + v13_.numConsumingSlots, true)
				self:setFillUnitCapacityToDisplay(v13_.fillUnitIndex, v13_.numStorageSlots + v13_.numConsumingSlots)
				local v26_ = v11_.types
				table.insert(v26_, v13_)
				v13_.index = #v11_.types
				v11_.typesByName[v13_.typeName] = v13_
			end
		end
	end
	for _, v27_ in ipairs(Consumable.CONFIG_NAMES) do
		local v28_ = string.format("vehicle.consumable.%sConfigurations", v27_)
		if self.xmlFile:hasProperty(v28_) then
			local v29_ = self.configurations[v27_] or 1
			local v30_ = self.xmlFile:getValue(v28_ .. "#typeName")
			if v30_ ~= nil then
				local v31_ = v11_.typesByName[v30_]
				if v31_ == nil then
					Logging.xmlWarning(self.xmlFile, "Consumable type name \'%s\' not found for configuration \'%s\'", v30_, v27_)
				else
					local v32_ = string.format("%s.%sConfiguration(%d)", v28_, v27_, v29_ - 1)
					v31_.defaultConsumableName = self.xmlFile:getValue(v32_ .. "#consumableName")
				end
			end
		end
	end
	v11_.activatable = ConsumableActivatable.new(self)
	v11_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, key, _, typeKey, typeName, type, consumingVariationName, slotIndex, slotKey, consumableVariation, consumableVariationIndex, typeIndex, type
function Consumable:onPostLoad(savegame)
	local v35_ = self.spec_consumable
	if savegame == nil then
		if not self.vehicleLoadingData:getCustomParameter("spawnEmpty") then
			for _, v36_ in ipairs(v35_.types) do
				if v36_.defaultConsumableName ~= nil then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v36_.fillUnitIndex, v36_.numStorageSlots, self:getFillUnitFirstSupportedFillType(v36_.fillUnitIndex), ToolType.UNDEFINED, nil)
					v36_.consumingFillLevel = 1
					v36_.consumingVariationIndex = g_consumableManager:getConsumableVariationIndexByName(v36_.defaultConsumableName, self.customEnvironment)
					self:updateConsumable(v36_.typeName, 0)
				end
			end
		end
	elseif not savegame.resetVehicles then
		local v37_ = savegame.key .. ".consumable"
		for _, v38_ in savegame.xmlFile:iterator(v37_ .. ".type") do
			local v39_ = savegame.xmlFile:getValue(v38_ .. "#typeName")
			local v40_ = v35_.typesByName[v39_]
			if v40_ ~= nil then
				v40_.consumingFillLevel = savegame.xmlFile:getValue(v38_ .. "#consumingFillLevel", 0)
				local v41_ = savegame.xmlFile:getValue(v38_ .. "#consumingVariationName")
				v40_.consumingVariationIndex = g_consumableManager:getConsumableVariationIndexByName(v41_, self.customEnvironment)
				for v42_, v43_ in savegame.xmlFile:iterator(v38_ .. ".storageSlot") do
					local v44_ = savegame.xmlFile:getValue(v43_ .. "#consumableVariation")
					if v44_ ~= nil then
						local v45_ = g_consumableManager:getConsumableVariationIndexByName(v44_, self.customEnvironment)
						self:setConsumableSlotVariationIndex(v40_.index, v42_, v45_)
					end
				end
				self:updateConsumable(v40_.typeName, 0)
				if self.updatePalletStraps ~= nil then
					self:updatePalletStraps()
				end
			end
		end
	end
	Consumable.updateActivatable(self)
end

-- Local values: spec
function Consumable:onDelete()
	local v47_ = self.spec_consumable
	g_currentMission.activatableObjectsSystem:removeActivatable(v47_.activatable)
end

-- Local values: spec, typeIndex, type, typeKey, slotIndex, slot, slotKey
function Consumable:saveToXMLFile(xmlFile, key, usedModNames)
	local v51_ = self.spec_consumable
	for v52_, v53_ in ipairs(v51_.types) do
		local v54_ = string.format("%s.type(%d)", key, v52_ - 1)
		xmlFile:setValue(v54_ .. "#typeName", v53_.typeName)
		xmlFile:setValue(v54_ .. "#consumingFillLevel", v53_.consumingFillLevel)
		xmlFile:setValue(v54_ .. "#consumingVariationName", g_consumableManager:getConsumableVariationNameByIndex(v53_.consumingVariationIndex))
		for v55_, v56_ in ipairs(v53_.storageSlots) do
			xmlFile:setValue(string.format("%s.storageSlot(%d)", v54_, v55_ - 1) .. "#consumableVariation", g_consumableManager:getConsumableVariationNameByIndex(v56_.consumableVariationIndex))
		end
	end
end

-- Local values: spec, typeIndex, type, slotIndex, slot, consumableVariationIndex
function Consumable:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v60_ = self.spec_consumable
		for _, v61_ in ipairs(v60_.types) do
			if v61_.numConsumingSlots > 0 then
				v61_.consumingFillLevel = streamReadUIntN(streamId, Consumable.CONSUME_LEVEL_NUM_BITS) / Consumable.CONSUME_LEVEL_RESOLUTION
				v61_.consumingVariationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
				self:updateConsumable(v61_.typeName, 0)
			end
			for v62_, _ in ipairs(v61_.storageSlots) do
				local v63_ = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
				self:setConsumableSlotVariationIndex(v61_.index, v62_, v63_)
			end
		end
		if self.updatePalletStraps ~= nil then
			self:updatePalletStraps()
		end
	end
end

-- Local values: spec, typeIndex, type, _, slot
function Consumable:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v67_ = self.spec_consumable
		for _, v68_ in ipairs(v67_.types) do
			if v68_.numConsumingSlots > 0 then
				local v69_ = streamWriteUIntN
				local v70_ = v68_.consumingFillLevel * Consumable.CONSUME_LEVEL_RESOLUTION
				v69_(streamId, math.floor(v70_), Consumable.CONSUME_LEVEL_NUM_BITS)
				streamWriteUIntN(streamId, v68_.consumingVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
			end
			for _, v71_ in ipairs(v68_.storageSlots) do
				streamWriteUIntN(streamId, v71_.consumableVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
			end
		end
	end
end

-- Local values: spec, typeIndex, type, slotIndex, slot, consumableVariationIndex
function Consumable:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v75_ = self.spec_consumable
		if streamReadBool(streamId) then
			for _, v76_ in ipairs(v75_.types) do
				if streamReadBool(streamId) then
					v76_.consumingFillLevel = streamReadUIntN(streamId, Consumable.CONSUME_LEVEL_NUM_BITS) / Consumable.CONSUME_LEVEL_RESOLUTION
					v76_.consumingVariationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
					self:updateConsumable(v76_.typeName, 0)
				end
				if streamReadBool(streamId) then
					for v77_, _ in ipairs(v76_.storageSlots) do
						local v78_ = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
						self:setConsumableSlotVariationIndex(v76_.index, v77_, v78_)
					end
					if self.updatePalletStraps ~= nil then
						self:updatePalletStraps()
					end
				end
			end
		end
	end
end

-- Local values: spec, typeIndex, type, anySlotDirty, _, slot, _, slot
function Consumable:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v83_ = self.spec_consumable
		local v84_ = streamWriteBool
		local v85_ = v83_.dirtyFlag
		if v84_(streamId, bit32.band(dirtyMask, v85_) ~= 0) then
			for _, v86_ in ipairs(v83_.types) do
				if streamWriteBool(streamId, v86_.isDirty) then
					local v87_ = streamWriteUIntN
					local v88_ = v86_.consumingFillLevel * Consumable.CONSUME_LEVEL_RESOLUTION
					v87_(streamId, math.floor(v88_), Consumable.CONSUME_LEVEL_NUM_BITS)
					streamWriteUIntN(streamId, v86_.consumingVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
				end
				local v89_ = false
				for _, v90_ in ipairs(v86_.storageSlots) do
					if v90_.isDirty then
						v89_ = true
						break
					end
				end
				if streamWriteBool(streamId, v89_) then
					for _, v91_ in ipairs(v86_.storageSlots) do
						streamWriteUIntN(streamId, v91_.consumableVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
					end
				end
			end
		end
	end
end

-- Local values: spec, typeIndex, type, _, slot
function Consumable:onDirtyMaskCleared()
	local v93_ = self.spec_consumable
	if v93_.types ~= nil then
		for _, v94_ in ipairs(v93_.types) do
			v94_.isDirty = false
			for _, v95_ in ipairs(v94_.storageSlots) do
				v95_.isDirty = false
			end
		end
	end
end

-- Local values: spec, typeIndex, type, _, animation, direction, limit
function Consumable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v98_ = self.spec_consumable
	if v98_.types ~= nil and v98_.animationsDirty then
		v98_.animationsDirty = false
		for _, v99_ in ipairs(v98_.types) do
			for _, v100_ in ipairs(v99_.animations) do
				if v100_.isDirty then
					local v101_ = v100_.targetTime - v100_.currentTime
					local v102_ = math.sign(v101_)
					v100_.currentTime = (v102_ > 0 and math.min or math.max)(v100_.currentTime + v102_ * dt * v100_.speedScale, v100_.targetTime)
					if v100_.currentTime > 1 and v100_.targetTime > 1 then
						v100_.currentTime = v100_.currentTime - 1
						v100_.targetTime = v100_.targetTime - 1
					elseif v100_.currentTime < 0 and v100_.targetTime < 0 then
						v100_.currentTime = v100_.currentTime + 1
						v100_.targetTime = v100_.targetTime + 1
					end
					self:setAnimationTime(v100_.name, v100_.currentTime, true)
					v100_.isDirty = v100_.targetTime ~= v100_.currentTime
					if v100_.isDirty then
						v98_.animationsDirty = true
						self:raiseActive()
					end
				end
			end
		end
	end
end

-- Local values: spec, typeIndex, type, text
function Consumable:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v104_ = self.spec_consumable
	if v104_.types ~= nil then
		for _, v105_ in ipairs(v104_.types) do
			if v105_.showWarning and (v105_.numConsumingSlots > 0 and (v105_.consumingFillLevel == 0 and (self:getFillUnitFillLevel(v105_.fillUnitIndex) == 0 and self:getShowConsumableEmptyWarning(v105_.typeName)))) then
				local v106_ = string.format(g_i18n:getText("warning_consumableEmpty"), g_consumableManager:getTypeTitle(v105_.typeName))
				g_currentMission:showBlinkingWarning(v106_, 500)
				return
			end
		end
	end
end

-- Local values: spec, fillLevel, typeIndex, type, numFilledSlots, slotIndex, slot, delta, consumableVariationIndex, specFillUnit, trigger, i, slotIndex, slot, fillConsumingSlots, i, slotIndex, slot
function Consumable:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if self.isServer then
		local v109_ = self.spec_consumable
		if v109_.types ~= nil then
			local v110_ = self:getFillUnitFillLevel(fillUnitIndex)
			for _, v111_ in ipairs(v109_.types) do
				if fillUnitIndex == v111_.fillUnitIndex then
					local v112_ = 0
					for _, v113_ in ipairs(v111_.storageSlots) do
						if v113_.consumableVariationIndex ~= 0 then
							v112_ = v112_ + 1
						end
					end
					local v114_ = v110_ - v112_
					local v115_ = math.abs(v114_)
					if v111_.numStorageSlots > 0 then
						v115_ = math.floor(v115_)
					end
					if v115_ > 0 then
						if v112_ < v110_ then
							local v116_ = nil
							local v117_ = self.spec_fillUnit
							if v117_.fillTrigger.isFilling then
								local v118_ = v117_.fillTrigger.currentTrigger
								if v118_ ~= nil and v118_.sourceObject.getConsumableVariationIndexByFillUnitIndex ~= nil then
									v116_ = v118_.sourceObject:getConsumableVariationIndexByFillUnitIndex(v118_.fillUnitIndex)
								end
							end
							if v116_ == nil and v111_.consumingVariationIndex ~= 0 then
								v116_ = v111_.consumingVariationIndex
							end
							if v116_ == nil then
								v116_ = v111_.defaultConsumableName == nil and 1 or g_consumableManager:getConsumableVariationIndexByName(v111_.defaultConsumableName, self.customEnvironment)
							end
							if v111_.numStorageSlots > 0 then
								for _ = 1, v115_ do
									for v119_ = #v111_.storageSlots, 1, -1 do
										if v111_.storageSlots[v119_].consumableVariationIndex == 0 then
											self:setConsumableSlotVariationIndex(v111_.index, v119_, v116_)
											break
										end
									end
								end
							end
							v111_.lastConsumedVariationIndex = v116_
							local v120_ = v111_.numStorageSlots == 0
							self:updateConsumable(v111_.typeName, 0, nil, v120_)
						else
							for _ = 1, v115_ do
								for v121_, v122_ in ipairs(v111_.storageSlots) do
									if v122_.consumableVariationIndex ~= 0 then
										v111_.lastConsumedVariationIndex = v122_.consumableVariationIndex
										self:setConsumableSlotVariationIndex(v111_.index, v121_, 0)
										break
									end
								end
							end
						end
						if self.updatePalletStraps ~= nil then
							self:updatePalletStraps()
						end
					end
				end
			end
		end
	end
end

-- Local values: spec, typeIndex, type
function Consumable:onFillUnitIsFillingStateChanged(isFilling)
	if not isFilling then
		local v125_ = self.spec_consumable
		if v125_.types ~= nil then
			for _, v126_ in ipairs(v125_.types) do
				if v126_.consumingFillLevel == 0 then
					self:updateConsumable(v126_.typeName, 0, nil, true)
				else
					self:updateConsumable(v126_.typeName, 0, nil, false)
				end
			end
		end
	end
end

function Consumable:onAddedFillUnitTrigger(fillTypeIndex, fillUnitIndex, numTriggers)
	Consumable.updateActivatable(self)
end

function Consumable:onRemovedFillUnitTrigger(numTriggers)
	Consumable.updateActivatable(self)
end

-- Local values: spec, typeIndex, type, i, slot
function Consumable:getConsumableVariationIndexByFillUnitIndex(fillUnitIndex)
	local v131_ = self.spec_consumable
	if v131_.types ~= nil then
		for _, v132_ in ipairs(v131_.types) do
			if v132_.fillUnitIndex == fillUnitIndex then
				for _, v133_ in ipairs(v132_.storageSlots) do
					if v133_.consumableVariationIndex ~= 0 then
						return v133_.consumableVariationIndex
					end
				end
				return v132_.lastConsumedVariationIndex
			end
		end
	end
	return nil
end

-- Local values: spec, type, slot, mesh, tensionBeltMesh
function Consumable:setConsumableSlotVariationIndex(typeIndex, slotIndex, variationIndex)
	local v138_ = variationIndex or 0
	local v139_ = self.spec_consumable
	local v140_ = v139_.types[typeIndex]
	if v140_ ~= nil then
		local v141_ = v140_.storageSlots[slotIndex]
		if v141_ ~= nil and v138_ ~= v141_.consumableVariationIndex then
			v141_.consumableVariationIndex = v138_
			v141_.isDirty = true
			if v141_.node ~= nil then
				if v141_.mesh ~= nil then
					if self.removeAllSubWashableNodes ~= nil then
						self:removeAllSubWashableNodes(v141_.mesh)
					end
					if self.removeAllSubWearableNodes ~= nil then
						self:removeAllSubWearableNodes(v141_.mesh)
					end
					delete(v141_.mesh)
					v141_.mesh = nil
					if v141_.tensionBeltMesh ~= nil then
						v141_.tensionBeltMesh = nil
						if self.setPalletTensionBeltNodesDirty ~= nil then
							self:setPalletTensionBeltNodesDirty()
						end
					end
				end
				local v142_, v143_ = g_consumableManager:getConsumableMeshByIndex(v141_.consumableVariationIndex, v141_.useTensionBeltMesh)
				if v142_ ~= nil then
					link(v141_.node, v142_)
					setTranslation(v142_, 0, 0, 0)
					setRotation(v142_, 0, 0, 0)
					v141_.mesh = v142_
					if self.addAllSubWashableNodes ~= nil then
						self:addAllSubWashableNodes(v142_)
					end
					if self.addAllSubWearableNodes ~= nil then
						self:addAllSubWearableNodes(v142_)
					end
					if v143_ ~= nil then
						v141_.tensionBeltMesh = v143_
						if self.setPalletTensionBeltNodesDirty ~= nil then
							self:setPalletTensionBeltNodesDirty()
						end
					end
				end
			end
			self:raiseDirtyFlags(v139_.dirtyFlag)
		end
	end
end

-- Local values: spec, type, fillLevel, delta, index, slot, shaderParameters, _, shaderParameter, _, node, metaData, consumingMesh, numChildren, i, child, _, animation, targetTime, divider, diff, fillLevel, totalFillLevel
function Consumable:updateConsumable(typeName, delta, consumingInProgress, fillConsumingSlots)
	local v149_ = self.spec_consumable
	local v150_ = v149_.typesByName[typeName]
	if v150_ ~= nil and v150_.numConsumingSlots ~= 0 then
		local v151_ = v150_.consumingFillLevel + delta / v150_.numConsumingSlots
		v150_.consumingFillLevel = math.clamp(v151_, 0, 1)
		if (fillConsumingSlots or fillConsumingSlots == nil and v150_.consumingFillLevel == 0) and self:getFillUnitFillLevel(v150_.fillUnitIndex) > 0 then
			local v152_ = self:addFillUnitFillLevel(self:getOwnerFarmId(), v150_.fillUnitIndex, -v150_.numConsumingSlots, self:getFillUnitFillType(v150_.fillUnitIndex), ToolType.UNDEFINED, nil)
			local v153_ = v150_.consumingFillLevel + -v152_ / v150_.numConsumingSlots
			local v154_ = v150_.numConsumingSlots
			v150_.consumingFillLevel = math.min(v153_, v154_)
			v150_.consumingVariationIndex = v150_.lastConsumedVariationIndex
		end
		for v155_, v156_ in ipairs(v150_.consumingSlots) do
			if v156_.consumingMesh == nil or v150_.consumingVariationIndex ~= v156_.consumableVariationIndex then
				v156_.consumableVariationIndex = v150_.consumingVariationIndex
				if v155_ == 1 then
					local v157_ = g_consumableManager:getConsumableVariationShaderParameterByIndex(v156_.consumableVariationIndex)
					if v157_ ~= nil then
						for _, v158_ in ipairs(v157_) do
							for _, v159_ in ipairs(v150_.shaderParameterNodes) do
								I3DUtil.setShaderParameterRec(v159_, v158_.name, v158_.value[1], v158_.value[2], v158_.value[3], v158_.value[4])
							end
						end
					end
					local v160_ = g_consumableManager:getConsumableVariationMetaDataByIndex(v156_.consumableVariationIndex)
					if v160_ ~= nil then
						SpecializationUtil.raiseEvent(self, "onConsumableVariationChanged", v156_.consumableVariationIndex, v160_)
					end
				end
				if v156_.node ~= nil then
					if v156_.consumingMesh ~= nil then
						if self.removeAllSubWashableNodes ~= nil then
							self:removeAllSubWashableNodes(v156_.consumingMesh)
						end
						if self.removeAllSubWearableNodes ~= nil then
							self:removeAllSubWearableNodes(v156_.consumingMesh)
						end
						delete(v156_.consumingMesh)
						v156_.consumingMesh = nil
					end
					local v161_ = g_consumableManager:getConsumableConsumingMeshByIndex(v156_.consumableVariationIndex)
					if v161_ ~= nil then
						link(v156_.node, v161_)
						setTranslation(v161_, 0, 0, 0)
						setRotation(v161_, 0, 0, 0)
						v156_.consumingMesh = v161_
						if self.addAllSubWashableNodes ~= nil then
							self:addAllSubWashableNodes(v161_)
						end
						if self.addAllSubWearableNodes ~= nil then
							self:addAllSubWearableNodes(v161_)
						end
					end
				end
			end
			if v156_.consumingMesh ~= nil then
				if v150_.useScale then
					local v162_ = setScale
					local v163_ = v156_.consumingMesh
					local v164_ = v150_.consumingFillLevel
					local v165_ = math.max(v164_, 0.1)
					local v166_ = v150_.consumingFillLevel
					v162_(v163_, v165_, 1, (math.max(v166_, 0.1)))
				end
				if v150_.useAmount then
					if getHasClassId(v156_.consumingMesh, ClassIds.SHAPE) and getHasShaderParameter(v156_.consumingMesh, "amount") then
						g_animationManager:setPrevShaderParameter(v156_.consumingMesh, "amount", v150_.consumingFillLevel, 0, 0, 0, false, "prevAmount")
					end
					for v167_ = 1, getNumOfChildren(v156_.consumingMesh) do
						local v168_ = getChildAt(v156_.consumingMesh, v167_ - 1)
						if getHasClassId(v168_, ClassIds.SHAPE) and getHasShaderParameter(v168_, "amount") then
							g_animationManager:setPrevShaderParameter(v168_, "amount", v150_.consumingFillLevel, 0, 0, 0, false, "prevAmount")
						end
					end
				end
				if v150_.useHideByIndex then
					local v169_ = I3DUtil.setHideByIndexRec
					local v170_ = v156_.consumingMesh
					local v171_ = v150_.consumingFillLevel + v150_.hideByIndexOffset
					v169_(v170_, (math.clamp(v171_, 0, 1)))
				end
				if consumingInProgress ~= true then
					setVisibility(v156_.consumingMesh, v150_.consumingFillLevel > 0)
				end
			end
		end
		for _, v172_ in ipairs(v150_.animations) do
			local v173_
			if v172_.numSteps == nil then
				local v174_ = 1 / v172_.numLoops
				local v175_ = (1 - v150_.consumingFillLevel) % v174_ / v174_
				v173_ = math.clamp(v175_, 0, 1)
			else
				local v176_ = v150_.consumingFillLevel * v172_.numSteps
				v173_ = 1 - math.ceil(v176_) / v172_.numSteps
			end
			local v177_ = v173_ - v172_.currentTime
			local v178_ = math.abs(v177_)
			if v172_.currentTime < v173_ then
				local v179_ = v173_ - 1 - v172_.currentTime
				if math.abs(v179_) < v178_ then
					v173_ = v173_ - 1
				end
			else
				local v180_ = v173_ + 1 - v172_.currentTime
				if math.abs(v180_) < v178_ then
					v172_.currentTime = v172_.currentTime - 1
					self:setAnimationTime(v172_.name, v172_.currentTime, true)
				end
			end
			v172_.targetTime = v173_
			v172_.isDirty = v172_.targetTime ~= v172_.currentTime
			if v172_.isDirty then
				v149_.animationsDirty = true
				self:raiseActive()
			end
		end
		if consumingInProgress ~= true then
			ObjectChangeUtil.setObjectChanges(v150_.objectChanges, v150_.consumingFillLevel > 0, self, self.setMovingToolDirty)
		end
		local v181_ = self:getFillUnitFillLevel(v150_.fillUnitIndex) + v150_.consumingFillLevel * v150_.numConsumingSlots
		local v182_ = v150_.fillUnitIndex
		local v183_ = math.min(v181_, self:getFillUnitCapacity(v182_))
		self:setFillUnitFillLevelToDisplay(v150_.fillUnitIndex, v183_, true)
		if MathUtil.round(v150_.consumingFillLevel * Consumable.CONSUME_LEVEL_RESOLUTION) ~= MathUtil.round(v150_.consumingFillLevelSent * Consumable.CONSUME_LEVEL_RESOLUTION) then
			self:raiseDirtyFlags(v149_.dirtyFlag)
			v150_.consumingFillLevelSent = v150_.consumingFillLevel
			v150_.isDirty = true
		end
	end
	if consumingInProgress ~= true then
		Consumable.updateActivatable(self)
	end
end

-- Local values: spec, type
function Consumable:getConsumableIsAvailable(typeName)
	local v186_ = self.spec_consumable.typesByName[typeName]
	return v186_ == nil and true or v186_.consumingFillLevel > 0
end

-- Local values: spec, type
function Consumable:getShowConsumableEmptyWarning(typeName)
	local v189_ = self.spec_consumable.typesByName[typeName]
	if v189_ == nil then
		return false
	else
		return v189_.consumingFillLevel == 0
	end
end

-- Local values: spec, i, type, slotIndex, slot
function Consumable:getCustomFillTriggerSpeedFactor(fillTrigger, fillUnitIndex, fillType)
	local v192_ = self.spec_consumable
	if v192_.types ~= nil then
		for _, v193_ in ipairs(v192_.types) do
			if v193_.fillUnitIndex == fillUnitIndex and v193_.numConsumingSlots > 0 then
				for _, v194_ in ipairs(v193_.storageSlots) do
					if v194_.consumableVariationIndex == 0 then
						return 1
					end
				end
				return math.huge
			end
		end
	end
	return 1
end
function Consumable.addFillUnitFillLevel(p195_, p196_, p197_, p198_, p199_, p200_, ...)
	if p199_ > 0 then
		local v201_ = p195_.spec_consumable
		if v201_.types ~= nil then
			for _, v202_ in ipairs(v201_.types) do
				if v202_.fillUnitIndex == p198_ then
					local v203_ = v202_.numConsumingSlots * (1 - v202_.consumingFillLevel) + v202_.numStorageSlots + 1e-6 - p195_:getFillUnitFillLevel(p198_)
					p199_ = math.min(p199_, v203_)
				end
			end
		end
	end
	return p196_(p195_, p197_, p198_, p199_, p200_, ...)
end
function Consumable.getFillUnitFreeCapacity(p204_, p205_, p206_, ...)
	local v207_ = p204_.spec_consumable
	if v207_.types ~= nil then
		for _, v208_ in ipairs(v207_.types) do
			if v208_.fillUnitIndex == p206_ then
				local v209_ = p204_:getFillUnitFillLevel(p206_)
				local v210_ = v208_.numStorageSlots + v208_.numConsumingSlots
				if v208_.consumingFillLevel ~= 0 and v208_.numStorageSlots ~= 0 then
					v210_ = v208_.numStorageSlots
				end
				return v210_ + 1e-6 - v209_
			end
		end
	end
	return p205_(p204_, p206_, ...)
end

-- Local values: spec, i, type, index, slot
function Consumable:collectPalletTensionBeltNodes(superFunc, nodes)
	superFunc(self, nodes)
	local v214_ = self.spec_consumable
	if v214_.types ~= nil then
		for _, v215_ in ipairs(v214_.types) do
			for _, v216_ in ipairs(v215_.storageSlots) do
				if v216_.tensionBeltMesh ~= nil then
					local v217_ = v216_.tensionBeltMesh
					table.insert(nodes, v217_)
				end
			end
		end
	end
end

-- Local values: spec, showActivatable, i, type
function Consumable:updateActivatable()
	local v219_ = self.spec_consumable
	local v220_ = false
	for _, v221_ in ipairs(v219_.types) do
		if v221_.consumingFillLevel == 0 and v221_.allowRefillDialog then
			v220_ = true
		end
	end
	if #self.spec_fillUnit.fillTrigger.triggers ~= 0 then
		v220_ = false
	end
	if v220_ then
		v219_.activatable:updateActivateText()
		g_currentMission.activatableObjectsSystem:addActivatable(v219_.activatable)
	else
		g_currentMission.activatableObjectsSystem:removeActivatable(v219_.activatable)
	end
end
