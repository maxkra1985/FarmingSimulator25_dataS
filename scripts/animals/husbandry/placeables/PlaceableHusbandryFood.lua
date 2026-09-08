PlaceableHusbandryFood = {}

function PlaceableHusbandryFood.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end

function PlaceableHusbandryFood.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateFillPlanes", PlaceableHusbandryFood.updateFillPlanes)
	SpecializationUtil.registerFunction(placeableType, "updateFoodPlaces", PlaceableHusbandryFood.updateFoodPlaces)
	SpecializationUtil.registerFunction(placeableType, "addFood", PlaceableHusbandryFood.addFood)
	SpecializationUtil.registerFunction(placeableType, "removeFood", PlaceableHusbandryFood.removeFood)
	SpecializationUtil.registerFunction(placeableType, "getTotalFood", PlaceableHusbandryFood.getTotalFood)
	SpecializationUtil.registerFunction(placeableType, "getAvailableFood", PlaceableHusbandryFood.getAvailableFood)
	SpecializationUtil.registerFunction(placeableType, "getFoodCapacity", PlaceableHusbandryFood.getFoodCapacity)
	SpecializationUtil.registerFunction(placeableType, "getFreeFoodCapacity", PlaceableHusbandryFood.getFreeFoodCapacity)
	SpecializationUtil.registerFunction(placeableType, "getFoodLitersPerHour", PlaceableHusbandryFood.getFoodLitersPerHour)
end

function PlaceableHusbandryFood.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryFood.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryFood.updateFeeding)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PlaceableHusbandryFood.getFoodInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandryFood.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalDescription", PlaceableHusbandryFood.getAnimalDescription)
end

function PlaceableHusbandryFood.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryFood)
end

function PlaceableHusbandryFood.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v7_ = basePath .. ".husbandry.food"
	schema:register(XMLValueType.INT, v7_ .. "#capacity", "Trough capacity", 5000)
	schema:register(XMLValueType.NODE_INDEX, v7_ .. ".foodPlaces.foodPlace(?)#node", "Foodplace")
	schema:register(XMLValueType.NODE_INDEX, v7_ .. ".dynamicFoodPlane#node", "Node")
	schema:register(XMLValueType.STRING, v7_ .. ".dynamicFoodPlane#defaultFillType", "Fillplane default filltype")
	FillPlaneUtil.registerFillPlaneXMLPaths(schema, v7_ .. ".dynamicFoodPlane")
	FillPlane.registerXMLPaths(schema, v7_ .. ".foodPlane")
	schema:register(XMLValueType.STRING, v7_ .. ".foodPlane#defaultFillType", "Fillplane default filltype")
	UnloadTrigger.registerTriggerXMLPaths(schema, v7_)
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryFood.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".fillLevel(?)#fillType", "Fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillLevel(?)#fillLevel", "Fill level")
	schema:setXMLSpecializationType()
end
function PlaceableHusbandryFood.initSpecialization()
	g_storeManager:addSpecType("animalFoodFillTypes", "shopListAttributeIconFillTypes", PlaceableHusbandryFood.loadSpecValueAnimalFoodFillTypes, PlaceableHusbandryFood.getSpecValueAnimalFoodFillTypes, StoreSpecies.PLACEABLE)
end

-- Local values: spec, target, fillPlane, defaultFillTypeName, defaultFillTypeIndex, defaultFillTypeName, defaultFillTypeIndex
function PlaceableHusbandryFood:onLoad(savegame)
	local v_u_11_ = self.spec_husbandryFood
	v_u_11_.animalTypeIndex = nil
	v_u_11_.litersPerHour = 0
	v_u_11_.fillLevels = {}
	v_u_11_.supportedFillTypes = {}
	v_u_11_.fillTypes = {}
	v_u_11_.lastPositionInfoSent = { 0, 0 }
	v_u_11_.lastPositionInfo = { 0, 0 }
	v_u_11_.foodPlaces = {}
	v_u_11_.info = {
		["title"] = g_i18n:getText("ui_animalFood"),
		["text"] = ""
	}
	v_u_11_.dirtyFlagPosition = self:getNextDirtyFlag()
	v_u_11_.dirtyFlagFillLevel = self:getNextDirtyFlag()
	v_u_11_.capacity = self.xmlFile:getValue("placeable.husbandry.food#capacity", 5000)
	v_u_11_.FILLLEVEL_NUM_BITS = MathUtil.getNumRequiredBits(v_u_11_.capacity)
	v_u_11_.feedingTroughs = UnloadTrigger.createTriggers(self.isServer, self.isClient, self.xmlFile, "placeable.husbandry.food", self.components, {
		["getIsFillTypeAllowed"] = function(_, p12_)
			-- upvalues: (copy) v_u_11_
			return v_u_11_.supportedFillTypes[p12_]
		end,
		["getIsToolTypeAllowed"] = function(_, _)
			return true
		end,
		["addFillLevelFromTool"] = function(_, ...)
			-- upvalues: (copy) self
			return self:addFood(...)
		end,
		["getFreeCapacity"] = function(_, p13_)
			-- upvalues: (copy) self
			return self:getFreeFoodCapacity(p13_)
		end
	}, nil, self.i3dMappings)
	if #v_u_11_.feedingTroughs == 0 then
		Logging.xmlWarning(self.xmlFile, "Missing no unload triggers defined for husbandry food")
		self:setLoadingState(PlaceableLoadingState.ERROR)
	else
		v_u_11_.baseNode = self.xmlFile:getValue("placeable.husbandry.food.dynamicFoodPlane#node", nil, self.components, self.i3dMappings)
		if v_u_11_.baseNode ~= nil then
			local v14_ = FillPlaneUtil.createFromXML(self.xmlFile, "placeable.husbandry.food.dynamicFoodPlane", v_u_11_.baseNode, v_u_11_.capacity)
			local v15_ = self.xmlFile:getValue("placeable.husbandry.food.dynamicFoodPlane#defaultFillType")
			local v16_ = g_fillTypeManager:getFillTypeIndexByName(v15_) or FillType.FORAGE
			if v14_ ~= nil then
				FillPlaneUtil.assignDefaultMaterialsFromTerrain(v14_, g_terrainNode)
				FillPlaneUtil.setFillType(v14_, v16_)
				v_u_11_.dynamicFoodPlane = v14_
			end
		end
		v_u_11_.foodPlane = FillPlane.new()
		if v_u_11_.foodPlane:load(self.components, self.xmlFile, "placeable.husbandry.food.foodPlane", self.i3dMappings) then
			local v17_ = self.xmlFile:getValue("placeable.husbandry.food.foodPlane#defaultFillType")
			local v18_ = g_fillTypeManager:getFillTypeIndexByName(v17_) or FillType.DRYGRASS_WINDROW
			FillPlaneUtil.assignDefaultMaterialsFromTerrain(v_u_11_.foodPlane.node, g_terrainNode)
			FillPlaneUtil.setFillType(v_u_11_.foodPlane.node, v18_)
			setShaderParameter(v_u_11_.foodPlane.node, "isCustomShape", 1, 0, 0, 0, false)
			v_u_11_.foodPlane:setState(0)
		else
			v_u_11_.foodPlane:delete()
			v_u_11_.foodPlane = nil
		end
		self.xmlFile:iterate("placeable.husbandry.food.foodPlaces.foodPlace", function(_, p19_)
			-- upvalues: (copy) self, (copy) v_u_11_
			local v20_ = self.xmlFile:getValue(p19_ .. "#node", nil, self.components, self.i3dMappings)
			local v21_ = v_u_11_.foodPlaces
			table.insert(v21_, {
				["node"] = v20_,
				["place"] = nil
			})
		end)
	end
end

-- Local values: spec, animalFood, mixtures, _, foodGroup, _, fillTypeIndex, _, foodMixtureFillType
function PlaceableHusbandryFood:onPostLoad()
	local v23_ = self.spec_husbandryFood
	v23_.animalTypeIndex = self:getAnimalTypeIndex()
	local v24_ = g_currentMission.animalFoodSystem:getAnimalFood(v23_.animalTypeIndex)
	local v25_ = g_currentMission.animalFoodSystem:getMixturesByAnimalTypeIndex(v23_.animalTypeIndex)
	if v24_ ~= nil then
		for _, v26_ in pairs(v24_.groups) do
			for _, v27_ in pairs(v26_.fillTypes) do
				if v23_.fillLevels[v27_] == nil then
					v23_.fillLevels[v27_] = 0
					v23_.supportedFillTypes[v27_] = true
					local v28_ = v23_.fillTypes
					table.insert(v28_, v27_)
				end
			end
		end
	end
	if v25_ ~= nil then
		for _, v29_ in ipairs(v25_) do
			v23_.supportedFillTypes[v29_] = true
			local v30_ = v23_.fillTypes
			table.insert(v30_, v29_)
		end
	end
end

-- Local values: spec, _, trigger
function PlaceableHusbandryFood:onDelete()
	local v32_ = self.spec_husbandryFood
	if v32_.feedingTroughs ~= nil then
		for _, v33_ in ipairs(v32_.feedingTroughs) do
			v33_:delete()
		end
		v32_.feedingTroughs = nil
	end
	if v32_.dynamicFoodPlane ~= nil then
		delete(v32_.dynamicFoodPlane)
		v32_.dynamicFoodPlane = nil
	end
	if v32_.foodPlane ~= nil then
		v32_.foodPlane:delete()
		v32_.foodPlane = nil
	end
end

-- Local values: spec, _, trigger
function PlaceableHusbandryFood:onFinalizePlacement()
	local v35_ = self.spec_husbandryFood
	if v35_.feedingTroughs ~= nil then
		for _, v36_ in ipairs(v35_.feedingTroughs) do
			v36_:register(true)
		end
	end
end

function PlaceableHusbandryFood:onPostFinalizePlacement()
	self:updateFillPlanes()
end

-- Local values: spec, _, fillTypeIndex, _, trigger, feedingTroughId
function PlaceableHusbandryFood:onReadStream(streamId, connection)
	local v41_ = self.spec_husbandryFood
	for _, v42_ in ipairs(v41_.fillTypes) do
		if v41_.fillLevels[v42_] ~= nil then
			v41_.fillLevels[v42_] = streamReadUIntN(streamId, v41_.FILLLEVEL_NUM_BITS)
		end
	end
	if v41_.feedingTroughs ~= nil then
		for _, v43_ in ipairs(v41_.feedingTroughs) do
			local v44_ = NetworkUtil.readNodeObjectId(streamId)
			v43_:readStream(streamId, connection)
			g_client:finishRegisterObject(v43_, v44_)
		end
	end
end

-- Local values: spec, _, fillTypeIndex, _, trigger
function PlaceableHusbandryFood:onWriteStream(streamId, connection)
	local v48_ = self.spec_husbandryFood
	for _, v49_ in ipairs(v48_.fillTypes) do
		if v48_.fillLevels[v49_] ~= nil then
			streamWriteUIntN(streamId, v48_.fillLevels[v49_], v48_.FILLLEVEL_NUM_BITS)
		end
	end
	if v48_.feedingTroughs ~= nil then
		for _, v50_ in ipairs(v48_.feedingTroughs) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v50_))
			v50_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v50_)
		end
	end
end

-- Local values: spec, _, fillTypeIndex, newFillLevel, delta
function PlaceableHusbandryFood:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v54_ = self.spec_husbandryFood
		if streamReadBool(streamId) then
			v54_.lastPositionInfo[1] = FillVolume.readStreamCompressedPosition(streamId)
			v54_.lastPositionInfo[2] = FillVolume.readStreamCompressedPosition(streamId)
		end
		if streamReadBool(streamId) then
			for _, v55_ in ipairs(v54_.fillTypes) do
				if v54_.fillLevels[v55_] ~= nil then
					local v56_ = streamReadUIntN(streamId, v54_.FILLLEVEL_NUM_BITS) - v54_.fillLevels[v55_]
					if v56_ > 0 then
						self:addFood(self:getOwnerFarmId(), v56_, v55_, nil, nil, nil)
					else
						self:removeFood(math.abs(v56_), v55_)
					end
				end
			end
		end
	end
end

-- Local values: spec, _, fillTypeIndex
function PlaceableHusbandryFood:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v61_ = self.spec_husbandryFood
		local v62_ = streamWriteBool
		local v63_ = v61_.dirtyFlagPosition
		if v62_(streamId, bit32.band(dirtyMask, v63_) ~= 0) then
			FillVolume.writeStreamCompressedPosition(streamId, v61_.lastPositionInfoSent[1])
			FillVolume.writeStreamCompressedPosition(streamId, v61_.lastPositionInfoSent[2])
		end
		local v64_ = streamWriteBool
		local v65_ = v61_.dirtyFlagFillLevel
		if v64_(streamId, bit32.band(dirtyMask, v65_) ~= 0) then
			for _, v66_ in ipairs(v61_.fillTypes) do
				if v61_.fillLevels[v66_] ~= nil then
					streamWriteUIntN(streamId, v61_.fillLevels[v66_], v61_.FILLLEVEL_NUM_BITS)
				end
			end
		end
	end
end

-- Local values: spec
function PlaceableHusbandryFood:loadFromXMLFile(xmlFile, key)
	local v_u_70_ = self.spec_husbandryFood
	xmlFile:iterate(key .. ".fillLevel", function(_, p71_)
		-- upvalues: (copy) xmlFile, (copy) v_u_70_, (copy) self
		local v72_ = xmlFile:getValue(p71_ .. "#fillType")
		local v73_ = xmlFile:getValue(p71_ .. "#fillLevel")
		if v72_ ~= nil and v73_ ~= nil then
			local v74_ = g_fillTypeManager:getFillTypeIndexByName(v72_)
			if v74_ ~= nil and v_u_70_.supportedFillTypes[v74_] ~= nil then
				self:addFood(self:getOwnerFarmId(), v73_, v74_, nil, nil, nil)
			end
		end
	end)
end

-- Local values: spec, index, fillTypeIndex, fillLevel, fillTypeName, fillLevelKey
function PlaceableHusbandryFood:saveToXMLFile(xmlFile, key, usedModNames)
	local v78_ = self.spec_husbandryFood
	local v79_ = 0
	for v80_, v81_ in pairs(v78_.fillLevels) do
		if v81_ > 0 then
			local v82_ = g_fillTypeManager:getFillTypeNameByIndex(v80_)
			if v82_ ~= nil then
				local v83_ = string.format("%s.fillLevel(%d)", key, v79_)
				xmlFile:setValue(v83_ .. "#fillType", v82_)
				xmlFile:setValue(v83_ .. "#fillLevel", v81_)
				v79_ = v79_ + 1
			end
		end
	end
end

-- Local values: factor, spec, consumedFood, fillTypeIndex, delta
function PlaceableHusbandryFood:updateFeeding(superFunc)
	local v86_ = superFunc(self)
	local v87_ = self.spec_husbandryFood
	if self.isServer and v87_.animalTypeIndex ~= nil then
		local v88_ = {}
		v86_ = v86_ * g_currentMission.animalFoodSystem:consumeFood(v87_.animalTypeIndex, v87_.litersPerHour * g_currentMission.environment.timeAdjustment, self, v88_)
		for v89_, v90_ in pairs(v88_) do
			self:removeFood(v90_, v89_)
		end
	end
	return v86_
end

-- Local values: spec
function PlaceableHusbandryFood:getFoodLitersPerHour()
	return self.spec_husbandryFood.litersPerHour
end

-- Local values: spec, fillLevel
function PlaceableHusbandryFood:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v95_ = self.spec_husbandryFood
	local v96_ = self:getTotalFood()
	v95_.info.text = string.format("%d l", v96_)
	local v97_ = v95_.info
	table.insert(infoTable, v97_)
end

-- Local values: foodInfos, spec, animalFood, _, foodGroup, title, fillLevel, capacity, _, fillTypeIndex, info
function PlaceableHusbandryFood:getFoodInfos(superFunc)
	local v100_ = superFunc(self)
	local v101_ = self.spec_husbandryFood
	local v102_ = g_currentMission.animalFoodSystem:getAnimalFood(v101_.animalTypeIndex)
	if v102_ ~= nil then
		for _, v103_ in pairs(v102_.groups) do
			local v104_ = v103_.title
			local v105_ = v101_.capacity
			local v106_ = 0
			for _, v107_ in pairs(v103_.fillTypes) do
				if v101_.fillLevels[v107_] ~= nil then
					v106_ = v106_ + v101_.fillLevels[v107_]
				end
			end
			local v108_ = {
				["title"] = string.format("%s (%d%%)", v104_, MathUtil.round(v103_.productionWeight * 100)),
				["value"] = v106_,
				["capacity"] = v105_,
				["ratio"] = 0
			}
			if v105_ > 0 then
				v108_.ratio = v106_ / v105_
			end
			table.insert(v100_, v108_)
		end
	end
	return v100_
end

-- Local values: spec, fillLevel, capacity, state
function PlaceableHusbandryFood:updateFillPlanes(fillTypeIndex)
	local v111_ = self.spec_husbandryFood
	if v111_.foodPlane ~= nil then
		local v112_ = self:getTotalFood()
		local v113_ = self:getFoodCapacity()
		local v114_
		if v113_ > 0 then
			local v115_ = v112_ / v113_
			v114_ = math.clamp(v115_, 0, 1)
		else
			v114_ = 0
		end
		v111_.foodPlane:setState(v114_)
		if v114_ > 0 and fillTypeIndex ~= nil then
			FillPlaneUtil.assignDefaultMaterialsFromTerrain(v111_.foodPlane.node, g_terrainNode)
			FillPlaneUtil.setFillType(v111_.foodPlane.node, fillTypeIndex)
			setShaderParameter(v111_.foodPlane.node, "isCustomShape", 1, 0, 0, 0, false)
		end
	end
end

-- Local values: spec, _, trigger
function PlaceableHusbandryFood:collectPickObjects(superFunc, node)
	local v119_ = self.spec_husbandryFood
	if v119_.feedingTroughs ~= nil then
		for _, v120_ in ipairs(v119_.feedingTroughs) do
			if node == v120_.exactFillRootNode then
				return
			end
		end
	end
	superFunc(self, node)
end

-- Local values: spec, _, foodPlace, feedingPlaceIndex, isAccessible
function PlaceableHusbandryFood:onHusbandryAnimalsCreated(husbandryId)
	if husbandryId ~= nil then
		local v123_ = self.spec_husbandryFood
		v123_.husbandryId = husbandryId
		for _, v124_ in ipairs(v123_.foodPlaces) do
			local v125_, v126_ = addFeedingPlace(husbandryId, v124_.node, 0, AnimalHusbandryFeedingType.FOOD)
			if v126_ then
				v124_.place = v125_
			end
		end
	end
end

-- Local values: spec, fillLevel, _, foodPlace
function PlaceableHusbandryFood:updateFoodPlaces()
	local v128_ = self.spec_husbandryFood
	if v128_.husbandryId ~= nil then
		local v129_ = self:getTotalFood()
		for _, v130_ in pairs(v128_.foodPlaces) do
			if v130_.place ~= nil then
				updateFeedingPlace(v128_.husbandryId, v130_.place, v129_)
			end
		end
	end
end

-- Local values: spec, fillLevel, _, level
function PlaceableHusbandryFood:getTotalFood()
	local v132_ = self.spec_husbandryFood
	local v133_ = 0
	for _, v134_ in pairs(v132_.fillLevels) do
		v133_ = v133_ + v134_
	end
	return v133_
end

-- Local values: spec
function PlaceableHusbandryFood:getAvailableFood(fillTypeIndex)
	return self.spec_husbandryFood.fillLevels[fillTypeIndex]
end

function PlaceableHusbandryFood:getFoodCapacity()
	return self.spec_husbandryFood.capacity
end

-- Local values: spec
function PlaceableHusbandryFood:getFreeFoodCapacity(fillTypeIndex)
	local v140_ = self.spec_husbandryFood
	return v140_.supportedFillTypes[fillTypeIndex] == nil and 0 or v140_.capacity - self:getTotalFood()
end

-- Local values: spec, mixture, filled, maxDelta, _, ingredient, delta, ingredientFillType, filledDelta, freeCapacity, data, x0, y0, z0, d1x, d1y, d1z, d2x, d2y, d2z, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z, steps, _
function PlaceableHusbandryFood:addFood(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local v148_ = self.spec_husbandryFood
	if v148_.supportedFillTypes[fillTypeIndex] == nil then
		return 0
	end
	local v149_ = g_currentMission.animalFoodSystem:getMixtureByFillType(fillTypeIndex)
	if v149_ ~= nil then
		local v150_ = math.min(deltaFillLevel, self:getFreeFoodCapacity(fillTypeIndex))
		local v151_ = 0
		for _, v152_ in ipairs(v149_.ingredients) do
			v151_ = v151_ + self:addFood(farmId, v150_ * v152_.weight, v152_.fillTypes[1], fillPositionData, toolType, extraAttributes)
		end
		if v151_ > 0 then
			self:updateFillPlanes(fillTypeIndex)
		end
		return v151_
	end
	local v153_ = self:getFreeFoodCapacity(fillTypeIndex)
	if v153_ == 0 then
		return 0
	end
	local v154_ = math.min(v153_, deltaFillLevel)
	if v148_.dynamicFoodPlane == nil then
		::l13::
		if self.isServer then
			self:raiseDirtyFlags(v148_.dirtyFlagFillLevel)
		end
		v148_.fillLevels[fillTypeIndex] = v148_.fillLevels[fillTypeIndex] + v154_
		self:updateFillPlanes(fillTypeIndex)
		self:updateFoodPlaces()
		return v154_
	end
	if fillPositionData == nil then
		local v155_, v156_, v157_ = localToWorld(v148_.dynamicFoodPlane, 0, 0, 0)
		local v158_, v159_, v160_ = localDirectionToWorld(v148_.dynamicFoodPlane, 0.1, 0, 0)
		local v161_, v162_, v163_ = localDirectionToWorld(v148_.dynamicFoodPlane, 0, 0, 0.1)
		if not self.isServer and (v148_.lastPositionInfo[1] ~= 0 and v148_.lastPositionInfo[2] ~= 0) then
			v155_, v156_, v157_ = localToWorld(v148_.dynamicFoodPlane, v148_.lastPositionInfo[1], 0, v148_.lastPositionInfo[2])
		end
		local v164_ = v154_ / 400
		local v165_ = math.floor(v164_)
		local v166_ = math.clamp(v165_, 1, 25)
		for _ = 1, v166_ do
			fillPlaneAdd(v148_.dynamicFoodPlane, v154_ / v166_, v155_, v156_, v157_, v158_, v159_, v160_, v161_, v162_, v163_)
		end
		goto l13
	end
	local v167_, v168_, v169_ = getWorldTranslation(fillPositionData.node)
	local v170_, v171_, v172_ = localDirectionToWorld(fillPositionData.node, fillPositionData.width, 0, 0)
	local v173_, v174_, v175_ = localDirectionToWorld(fillPositionData.node, 0, 0, fillPositionData.length)
	if VehicleDebug.state == VehicleDebug.DEBUG then
		drawDebugLine(v167_, v168_, v169_, 1, 0, 0, v167_ + v170_, v168_ + v171_, v169_ + v172_, 1, 0, 0)
		drawDebugLine(v167_, v168_, v169_, 0, 0, 1, v167_ + v173_, v168_ + v174_, v169_ + v175_, 0, 0, 1)
		drawDebugPoint(v167_, v168_, v169_, 1, 1, 1, 1)
		drawDebugPoint(v167_ + v170_, v168_ + v171_, v169_ + v172_, 1, 0, 0, 1)
		drawDebugPoint(v167_ + v173_, v168_ + v174_, v169_ + v175_, 0, 0, 1, 1)
	end
	local v176_ = v167_ - (v170_ + v173_) / 2
	local v177_ = v168_ - (v171_ + v174_) / 2
	local v178_ = v169_ - (v172_ + v175_) / 2
	fillPlaneAdd(v148_.dynamicFoodPlane, v154_, v176_, v177_, v178_, v170_, v171_, v172_, v173_, v174_, v175_)
	if self.isServer then
		local v179_ = v176_ - v148_.lastPositionInfoSent[1]
		if math.abs(v179_) > FillVolume.SEND_PRECISION then
			::l20::
			v148_.lastPositionInfoSent[1] = v176_
			v148_.lastPositionInfoSent[2] = v178_
			self:raiseDirtyFlags(v148_.dirtyFlagPosition)
			goto l13
		end
	end
	local v180_ = v178_ - v148_.lastPositionInfoSent[2]
	if math.abs(v180_) <= FillVolume.SEND_PRECISION then
		goto l13
	end
	goto l20
end

-- Local values: spec, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z, steps, delta, _
function PlaceableHusbandryFood:removeFood(absDeltaFillLevel, fillTypeIndex)
	local v184_ = self.spec_husbandryFood
	if v184_.supportedFillTypes[fillTypeIndex] == nil then
		return 0
	end
	if absDeltaFillLevel <= 0 then
		return 0
	end
	local v185_ = math.abs(absDeltaFillLevel)
	local v186_ = v184_.fillLevels[fillTypeIndex]
	local v187_ = math.min(v185_, v186_)
	if v184_.dynamicFoodPlane ~= nil then
		local v188_, v189_, v190_ = localToWorld(v184_.dynamicFoodPlane, 0, 0, 0)
		local v191_, v192_, v193_ = localDirectionToWorld(v184_.dynamicFoodPlane, 0.1, 0, 0)
		local v194_, v195_, v196_ = localDirectionToWorld(v184_.dynamicFoodPlane, 0, 0, 0.1)
		local v197_ = v187_ / 400
		local v198_ = math.floor(v197_)
		local v199_ = math.clamp(v198_, 1, 25)
		local v200_ = v187_ / v199_
		for _ = 1, v199_ do
			fillPlaneAdd(v184_.dynamicFoodPlane, -v200_, v188_, v189_, v190_, v191_, v192_, v193_, v194_, v195_, v196_)
		end
	end
	v184_.fillLevels[fillTypeIndex] = v184_.fillLevels[fillTypeIndex] - v187_
	if self.isServer then
		self:raiseDirtyFlags(v184_.dirtyFlagFillLevel)
	end
	self:updateFillPlanes()
	self:updateFoodPlaces()
	return v187_
end

-- Local values: spec, _, cluster, subType, food, age, litersPerAnimal, litersPerDay
function PlaceableHusbandryFood:onHusbandryAnimalsUpdate(clusters)
	local v203_ = self.spec_husbandryFood
	v203_.litersPerHour = 0
	for _, v204_ in ipairs(clusters) do
		local v205_ = g_currentMission.animalSystem:getSubTypeByIndex(v204_.subTypeIndex)
		if v205_ ~= nil then
			local v206_ = v205_.input.food
			if v206_ ~= nil then
				local v207_ = v206_:get((v204_:getAge())) * v204_:getNumAnimals()
				v203_.litersPerHour = v203_.litersPerHour + v207_ / 24
			end
		end
	end
end

-- Local values: text
function PlaceableHusbandryFood:getAnimalDescription(superFunc, cluster)
	return superFunc(self, cluster) .. " " .. g_i18n:getText("animal_descriptionPercentage")
end

-- Local values: data
function PlaceableHusbandryFood.loadSpecValueAnimalFoodFillTypes(xmlFile, customEnvironment, baseDir)
	local v212_ = nil
	if xmlFile:hasProperty("placeable.husbandry.animals") then
		v212_ = v212_ or {}
		v212_.animalTypeName = xmlFile:getString("placeable.husbandry.animals#type")
	end
	if xmlFile:hasProperty("placeable.husbandry.water") then
		v212_ = v212_ or {}
		v212_.needsWater = not xmlFile:getValue("placeable.husbandry.water#automaticWaterSupply", false)
	end
	return v212_
end

-- Local values: data, fillTypes, animalType, animalFood, mixtures, _, foodGroup, _, fillTypeIndex, _, foodMixtureFillType
function PlaceableHusbandryFood.getSpecValueAnimalFoodFillTypes(storeItem, realItem)
	local v214_ = storeItem.specs.animalFoodFillTypes
	if v214_ == nil then
		return nil
	end
	local v215_ = {}
	local v216_ = g_currentMission.animalSystem:getTypeByName(v214_.animalTypeName)
	if v216_ == nil then
		return nil
	end
	local v217_ = g_currentMission.animalFoodSystem:getAnimalFood(v216_.typeIndex)
	local v218_ = g_currentMission.animalFoodSystem:getMixturesByAnimalTypeIndex(v216_.typeIndex)
	if v217_ ~= nil then
		for _, v219_ in pairs(v217_.groups) do
			for _, v220_ in pairs(v219_.fillTypes) do
				table.addElement(v215_, v220_)
			end
		end
	end
	if v218_ ~= nil then
		for _, v221_ in ipairs(v218_) do
			table.addElement(v215_, v221_)
		end
	end
	if v214_.needsWater then
		table.addElement(v215_, FillType.WATER)
	end
	return v215_
end
