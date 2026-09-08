PlaceableHusbandryWater = {}

function PlaceableHusbandryWater.prerequisitesPresent(specializations)
	return true
end

function PlaceableHusbandryWater.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateWaterPlane", PlaceableHusbandryWater.updateWaterPlane)
end

function PlaceableHusbandryWater.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryWater.updateFeeding)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryWater.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryWater.updateInfo)
end

function PlaceableHusbandryWater.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryFillLevelChanged", PlaceableHusbandryWater)
end

function PlaceableHusbandryWater.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v6_ = basePath .. ".husbandry.water"
	schema:register(XMLValueType.BOOL, v6_ .. "#automaticWaterSupply", "If husbandry has a automatic water supply", false)
	schema:register(XMLValueType.NODE_INDEX, v6_ .. ".waterPlaces.waterPlace(?)#node", "Water place")
	FillPlane.registerXMLPaths(schema, v6_ .. ".waterPlane")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableHusbandryWater:onLoad(savegame)
	local v_u_8_ = self.spec_husbandryWater
	v_u_8_.husbandryId = nil
	v_u_8_.litersPerHour = 0
	v_u_8_.automaticWaterSupply = false
	v_u_8_.fillType = FillType.WATER
	v_u_8_.waterPlaces = {}
	v_u_8_.info = {
		["title"] = g_i18n:getText("fillType_water"),
		["text"] = ""
	}
	v_u_8_.automaticWaterSupply = self.xmlFile:getValue("placeable.husbandry.water#automaticWaterSupply", v_u_8_.automaticWaterSupply)
	v_u_8_.waterPlane = FillPlane.new()
	if v_u_8_.waterPlane:load(self.components, self.xmlFile, "placeable.husbandry.water.waterPlane", self.i3dMappings) then
		v_u_8_.waterPlane:setState(v_u_8_.automaticWaterSupply and 1 or 0)
	else
		v_u_8_.waterPlane:delete()
		v_u_8_.waterPlane = nil
	end
	self.xmlFile:iterate("placeable.husbandry.water.waterPlaces.waterPlace", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v10_ = self.xmlFile:getValue(p9_ .. "#node", nil, self.components, self.i3dMappings)
		local v11_ = v_u_8_.waterPlaces
		table.insert(v11_, {
			["node"] = v10_,
			["place"] = nil
		})
	end)
end

function PlaceableHusbandryWater:onPostFinalizePlacement()
	self:updateWaterPlane()
end

-- Local values: spec
function PlaceableHusbandryWater:onDelete()
	local v14_ = self.spec_husbandryWater
	if v14_.waterPlane ~= nil then
		v14_.waterPlane:delete()
		v14_.waterPlane = nil
	end
end

-- Local values: spec
function PlaceableHusbandryWater:onFinalizePlacement()
	local v16_ = self.spec_husbandryWater
	if not (v16_.automaticWaterSupply or self:getHusbandryIsFillTypeSupported(v16_.fillType)) then
		Logging.xmlWarning(self.xmlFile, "Missing filltype \'water\' in husbandry storage! Changing to automatic water supply")
		v16_.automaticWaterSupply = true
	end
end

-- Local values: spec, fillLevel, capacity, factor, _, waterPlace
function PlaceableHusbandryWater:updateWaterPlane()
	local v18_ = self.spec_husbandryWater
	local v19_ = self:getHusbandryFillLevel(v18_.fillType, nil)
	if v18_.waterPlane ~= nil then
		local v20_ = self:getHusbandryCapacity(v18_.fillType, nil)
		local v21_ = v20_ <= 0 and 0 or v19_ / v20_
		v18_.waterPlane:setState(v21_)
	end
	if v18_.husbandryId ~= nil then
		for _, v22_ in pairs(v18_.waterPlaces) do
			if v22_.place ~= nil then
				updateFeedingPlace(v18_.husbandryId, v22_.place, v19_)
			end
		end
	end
end

-- Local values: factor, spec, delta, fillType, price, remainingLiters, usedDelta
function PlaceableHusbandryWater:updateFeeding(superFunc)
	local v25_ = superFunc(self)
	local v26_ = self.spec_husbandryWater
	if self.isServer and v26_.litersPerHour > 0 then
		local v27_ = v26_.litersPerHour * g_currentMission.environment.timeAdjustment
		if v26_.automaticWaterSupply then
			local v28_ = v27_ * g_fillTypeManager:getFillTypeByIndex(v26_.fillType).pricePerLiter
			g_currentMission:addMoney(-v28_, self:getOwnerFarmId(), MoneyType.PURCHASE_WATER, false, false)
			return v25_
		end
		local v29_ = (v27_ - self:removeHusbandryFillLevel(nil, v27_, v26_.fillType)) / v27_
		v25_ = v25_ * math.clamp(v29_, 0, 1)
	end
	return v25_
end

-- Local values: spec, _, waterPlace, feedingPlaceIndex, isAccessible
function PlaceableHusbandryWater:onHusbandryAnimalsCreated(husbandryId)
	if husbandryId ~= nil then
		local v32_ = self.spec_husbandryWater
		v32_.husbandryId = husbandryId
		for _, v33_ in ipairs(v32_.waterPlaces) do
			local v34_, v35_ = addFeedingPlace(husbandryId, v33_.node, 0, AnimalHusbandryFeedingType.WATER)
			if v35_ then
				v33_.place = v34_
			end
		end
	end
end

-- Local values: spec, _, cluster, subType, water, age, litersPerAnimal, litersPerDay
function PlaceableHusbandryWater:onHusbandryAnimalsUpdate(clusters)
	local v38_ = self.spec_husbandryWater
	v38_.litersPerHour = 0
	for _, v39_ in ipairs(clusters) do
		local v40_ = g_currentMission.animalSystem:getSubTypeByIndex(v39_.subTypeIndex)
		if v40_ ~= nil then
			local v41_ = v40_.input.water
			if v41_ ~= nil then
				local v42_ = v41_:get((v39_:getAge())) * v39_:getNumAnimals()
				v38_.litersPerHour = v38_.litersPerHour + v42_ / 24
			end
		end
	end
end

-- Local values: spec
function PlaceableHusbandryWater:onHusbandryFillLevelChanged(fillTypeIndex, delta)
	if fillTypeIndex == self.spec_husbandryWater.fillType then
		self:updateWaterPlane()
	end
end

-- Local values: infos, spec, info, fillType, capacity, ratio
function PlaceableHusbandryWater:getConditionInfos(superFunc)
	local v47_ = superFunc(self)
	local v48_ = self.spec_husbandryWater
	if not v48_.automaticWaterSupply then
		local v49_ = {}
		local v50_ = g_fillTypeManager:getFillTypeByIndex(v48_.fillType)
		if v50_ ~= nil then
			v49_.title = v50_.title
			v49_.value = self:getHusbandryFillLevel(v48_.fillType)
			local v51_ = self:getHusbandryCapacity(v48_.fillType)
			local v52_ = v51_ <= 0 and 0 or v49_.value / v51_
			v49_.ratio = math.clamp(v52_, 0, 1)
			v49_.invertedBar = false
			table.insert(v47_, v49_)
		end
	end
	return v47_
end

-- Local values: spec, fillLevel
function PlaceableHusbandryWater:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v56_ = self.spec_husbandryWater
	if not v56_.automaticWaterSupply then
		local v57_ = self:getHusbandryFillLevel(v56_.fillType)
		v56_.info.text = string.format("%d l", v57_)
		local v58_ = v56_.info
		table.insert(infoTable, v58_)
	end
end
