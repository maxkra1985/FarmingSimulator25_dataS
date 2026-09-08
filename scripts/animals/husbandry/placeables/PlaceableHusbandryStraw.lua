PlaceableHusbandryStraw = {}

function PlaceableHusbandryStraw.prerequisitesPresent(specializations)
	return true
end

function PlaceableHusbandryStraw.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateStrawPlane", PlaceableHusbandryStraw.updateStrawPlane)
end

function PlaceableHusbandryStraw.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryStraw.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryStraw.updateProduction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryStraw.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryStraw.updateInfo)
end

function PlaceableHusbandryStraw.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryFillLevelChanged", PlaceableHusbandryStraw)
end

function PlaceableHusbandryStraw.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v6_ = basePath .. ".husbandry.straw"
	FillPlane.registerXMLPaths(schema, v6_ .. ".strawPlane")
	schema:register(XMLValueType.FLOAT, v6_ .. ".manure#factor", "Factor to transform straw to manure", 1)
	schema:register(XMLValueType.BOOL, v6_ .. ".manure#active", "Enable manure production", true)
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableHusbandryStraw:onLoad(savegame)
	local v8_ = self.spec_husbandryStraw
	v8_.manureFactor = self.xmlFile:getValue("placeable.husbandry.straw.manure#factor", 1)
	v8_.isManureActive = self.xmlFile:getValue("placeable.husbandry.straw.manure#active", true)
	v8_.strawPlane = FillPlane.new()
	if v8_.strawPlane:load(self.components, self.xmlFile, "placeable.husbandry.straw.strawPlane", self.i3dMappings) then
		v8_.strawPlane:setState(0)
	else
		v8_.strawPlane:delete()
		v8_.strawPlane = nil
	end
	v8_.inputFillType = FillType.STRAW
	v8_.outputFillType = FillType.MANURE
	v8_.inputLitersPerHour = 0
	v8_.outputLitersPerHour = 0
	v8_.info = {
		["title"] = g_i18n:getText("fillType_straw"),
		["text"] = ""
	}
	v8_.outputInfo = {
		["title"] = g_i18n:getText("fillType_manure"),
		["text"] = ""
	}
end

function PlaceableHusbandryStraw:onPostFinalizePlacement()
	self:updateStrawPlane()
end

-- Local values: spec
function PlaceableHusbandryStraw:onDelete()
	local v11_ = self.spec_husbandryStraw
	if v11_.strawPlane ~= nil then
		v11_.strawPlane:delete()
		v11_.strawPlane = nil
	end
end

-- Local values: spec
function PlaceableHusbandryStraw:onFinalizePlacement()
	local v13_ = self.spec_husbandryStraw
	if not self:getHusbandryIsFillTypeSupported(v13_.inputFillType) then
		Logging.xmlWarning(self.xmlFile, "Missing filltype \'straw\' in husbandry storage!")
	end
	if self.isManureActive and not self:getHusbandryIsFillTypeSupported(v13_.outputFillType) then
		Logging.xmlWarning(self.xmlFile, "Missing filltype \'manure\' in husbandry storage!")
	end
end

function PlaceableHusbandryStraw:onReadStream(streamId, connection)
	self:updateStrawPlane()
end

-- Local values: spec, capacity, fillLevel, factor
function PlaceableHusbandryStraw:updateStrawPlane()
	local v16_ = self.spec_husbandryStraw
	if v16_.strawPlane ~= nil then
		local v17_ = self:getHusbandryCapacity(v16_.inputFillType, nil)
		local v18_ = self:getHusbandryFillLevel(v16_.inputFillType, nil)
		local v19_ = v17_ <= 0 and 0 or v18_ / v17_
		v16_.strawPlane:setState(v19_)
	end
end

-- Local values: spec, amount, delta, liters
function PlaceableHusbandryStraw:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local v25_ = self.spec_husbandryStraw
		if v25_.inputLitersPerHour > 0 then
			local v26_ = v25_.inputLitersPerHour * g_currentMission.environment.timeAdjustment
			local v27_ = v26_ - self:removeHusbandryFillLevel(self:getOwnerFarmId(), v26_, v25_.inputFillType)
			if v25_.outputLitersPerHour > 0 and v27_ > 0 then
				local v28_ = foodFactor * v25_.outputLitersPerHour * (v27_ / v26_) * g_currentMission.environment.timeAdjustment
				if v28_ > 0 then
					self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), v28_, v25_.outputFillType, nil, nil, nil)
				end
			end
			self:updateStrawPlane()
		end
	end
	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

-- Local values: factor, spec, fillLevel, freeCapacity
function PlaceableHusbandryStraw:updateProduction(superFunc, foodFactor)
	local v32_ = superFunc(self, foodFactor)
	if self.isServer then
		local v33_ = self.spec_husbandryStraw
		if self:getHusbandryFillLevel(v33_.inputFillType) > 0 then
			if self:getHusbandryFreeCapacity(v33_.outputFillType) <= 0 then
				return v32_ * 0.75
			end
		else
			v32_ = v32_ * 0.9
		end
	end
	return v32_
end

-- Local values: spec, _, cluster, subType, straw, age, litersPerAnimal, litersPerDay, manure, age, litersPerAnimal, litersPerDay
function PlaceableHusbandryStraw:onHusbandryAnimalsUpdate(clusters)
	local v36_ = self.spec_husbandryStraw
	v36_.inputLitersPerHour = 0
	v36_.outputLitersPerHour = 0
	for _, v37_ in ipairs(clusters) do
		local v38_ = g_currentMission.animalSystem:getSubTypeByIndex(v37_.subTypeIndex)
		if v38_ ~= nil then
			local v39_ = v38_.input.straw
			if v39_ ~= nil then
				local v40_ = v39_:get((v37_:getAge())) * v37_:getNumAnimals()
				v36_.inputLitersPerHour = v36_.inputLitersPerHour + v40_ / 24
			end
			local v41_ = v38_.output.manure
			if v41_ ~= nil then
				local v42_ = v41_:get((v37_:getAge())) * v37_:getNumAnimals()
				v36_.outputLitersPerHour = v36_.outputLitersPerHour + v42_ / 24
			end
		end
	end
end

-- Local values: spec
function PlaceableHusbandryStraw:onHusbandryFillLevelChanged(fillTypeIndex, delta)
	if fillTypeIndex == self.spec_husbandryStraw.inputFillType then
		self:updateStrawPlane()
	end
end

-- Local values: infos, spec, fillType, info, capacity, ratio, outputFillType, info, capacity, ratio
function PlaceableHusbandryStraw:getConditionInfos(superFunc)
	local v47_ = superFunc(self)
	local v48_ = self.spec_husbandryStraw
	local v49_ = g_fillTypeManager:getFillTypeByIndex(v48_.inputFillType)
	if v49_ ~= nil then
		local v50_ = {
			["title"] = v49_.title,
			["value"] = self:getHusbandryFillLevel(v48_.inputFillType)
		}
		local v51_ = self:getHusbandryCapacity(v48_.inputFillType)
		local v52_ = v51_ <= 0 and 0 or v50_.value / v51_
		v50_.ratio = math.clamp(v52_, 0, 1)
		v50_.invertedBar = false
		table.insert(v47_, v50_)
	end
	local v53_ = g_fillTypeManager:getFillTypeByIndex(v48_.outputFillType)
	if v53_ ~= nil then
		local v54_ = {
			["title"] = v53_.title,
			["value"] = self:getHusbandryFillLevel(v48_.outputFillType)
		}
		local v55_ = self:getHusbandryCapacity(v48_.outputFillType)
		local v56_ = 1
		if v55_ > 0 then
			v56_ = v54_.value / v55_
		else
			v54_.disabled = true
			v54_.title = string.format("%s (%s)", v54_.title, g_i18n:getText("info_husbandryMissingManureHeap"))
		end
		v54_.ratio = math.clamp(v56_, 0, 1)
		v54_.invertedBar = true
		table.insert(v47_, v54_)
	end
	return v47_
end

-- Local values: spec, fillLevel, outputFillLevel
function PlaceableHusbandryStraw:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v60_ = self.spec_husbandryStraw
	local v61_ = self:getHusbandryFillLevel(v60_.inputFillType)
	v60_.info.text = string.format("%d l", v61_)
	local v62_ = v60_.info
	table.insert(infoTable, v62_)
	local v63_ = self:getHusbandryFillLevel(v60_.outputFillType)
	v60_.outputInfo.text = string.format("%d l", v63_)
	local v64_ = v60_.outputInfo
	table.insert(infoTable, v64_)
end
