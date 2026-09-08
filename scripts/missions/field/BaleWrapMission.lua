-- Local values: BaleWrapMission_mt
BaleWrapMission = {}
BaleWrapMission.NAME = "baleWrapMission"
local BaleWrapMission_mt = Class(BaleWrapMission, AbstractFieldMission)
InitStaticObjectClass(BaleWrapMission, "BaleWrapMission")

function BaleWrapMission.registerXMLPaths(schema, key)
	BaleWrapMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerBale", "Reward per bale")
end

function BaleWrapMission.registerSavegameXMLPaths(schema, key)
	BaleWrapMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#baleTypeIndex", "Bale type")
	schema:register(XMLValueType.INT, key .. "#numOfBales", "Bale count")
	schema:register(XMLValueType.STRING, key .. ".bale(?)#uniqueId", "Spawned bale")
end

-- Upvalues: BaleWrapMission_mt
-- Local values: title, description, self
function BaleWrapMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) BaleWrapMission_mt
	local v9_ = g_i18n:getText("contract_field_baleWrap_title")
	local v10_ = g_i18n:getText("contract_field_baleWrap_description")
	local v11_ = AbstractFieldMission.new(isServer, isClient, v9_, v10_, customMt or BaleWrapMission_mt)
	v11_.bales = {}
	v11_.balesToLoadByUniqueId = nil
	return v11_
end

function BaleWrapMission:init(field, baleTypeIndex, numOfBales)
	self.baleTypeIndex = baleTypeIndex
	self.numOfBales = numOfBales
	return BaleWrapMission:superClass().init(self, field)
end

-- Local values: fieldId, isRoundBale, baleType
function BaleWrapMission:setField(field)
	BaleWrapMission:superClass().setField(self, field)
	local v18_ = field:getId()
	if v18_ ~= nil then
		local v19_
		if g_baleManager:getIsRoundBale(self.baleTypeIndex) then
			v19_ = g_i18n:getText("fillType_roundBale")
		else
			v19_ = g_i18n:getText("fillType_squareBale")
		end
		self.progressTitle = string.format("%s (%s %d) - %s", self.title, g_i18n:getText("contract_details_field"), v18_, v19_)
	end
end

function BaleWrapMission:writeStream(streamId, connection)
	BaleWrapMission:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.baleTypeIndex, BaleManager.SEND_NUM_BITS)
	streamWriteUInt16(streamId, self.numOfBales)
end

function BaleWrapMission:readStream(streamId, connection)
	BaleWrapMission:superClass().readStream(self, streamId, connection)
	self.baleTypeIndex = streamReadUIntN(streamId, BaleManager.SEND_NUM_BITS)
	self.numOfBales = streamReadUInt16(streamId)
end

-- Local values: i, bale, baleKey
function BaleWrapMission:saveToXMLFile(xmlFile, key)
	BaleWrapMission:superClass().saveToXMLFile(self, xmlFile, key)
	for v29_, v30_ in ipairs(self.bales) do
		xmlFile:setValue(string.format("%s.bale(%d)", key, v29_ - 1) .. "#uniqueId", v30_:getUniqueId())
	end
	xmlFile:setValue(key .. "#baleTypeIndex", self.baleTypeIndex)
	xmlFile:setValue(key .. "#numOfBales", self.numOfBales)
end

-- Local values: _, baleKey, baleUniqueId
function BaleWrapMission:loadFromXMLFile(xmlFile, key)
	for _, v34_ in xmlFile:iterator(key .. ".bale") do
		local v35_ = xmlFile:getValue(v34_ .. "#uniqueId")
		if self.balesToLoadByUniqueId == nil then
			self.balesToLoadByUniqueId = {}
		end
		local v36_ = self.balesToLoadByUniqueId
		table.insert(v36_, v35_)
	end
	self.baleTypeIndex = xmlFile:getValue(key .. "#baleTypeIndex")
	if self.baleTypeIndex == nil then
		return false
	end
	self.numOfBales = xmlFile:getValue(key .. "#numOfBales")
	if self.numOfBales == nil then
		return false
	end
	self.finishedBaleSpawning = true
	return BaleWrapMission:superClass().loadFromXMLFile(self, xmlFile, key)
end

-- Local values: fruitType, fruitTypeDesc, litersPerSqm, fieldSizeSqm, litersToDrop, x, z, fieldCourseSettings, baleFillTypeIndex, baleXMLFilename, baleCapacity, baleDesc, isRoundBale, nextBaleLiters, spawnBale, segmentLiters, lastSx, lastSz, lastEx, lastEz, lastLength, segmentFunc, finishFunc
function BaleWrapMission:prepareField()
	BaleWrapMission:superClass().prepareField(self)
	if self.isServer then
		local v38_ = FruitType.GRASS
		local v39_ = g_fruitTypeManager:getFruitTypeByIndex(v38_)
		local v40_ = v39_.windrowLiterPerSqm or v39_.literPerSqm
		local v_u_41_ = MathUtil.haToSqm(self.field:getAreaHa()) * v40_
		local v42_, v43_ = self.field:getCenterOfFieldWorldPosition()
		local v44_ = FieldCourseSettings.new()
		v44_.implementWidth = 8
		v44_.numHeadlands = 2
		local v_u_45_ = v39_.windrowFillType.index
		local v_u_46_ = g_baleManager:getBaleXMLFilenameByIndex(self.baleTypeIndex)
		local v_u_47_ = g_baleManager:getBaleCapacityByBaleIndex(self.baleTypeIndex, v_u_45_)
		local v_u_48_ = g_baleManager:getBaleDescByIndex(self.baleTypeIndex)
		local v_u_49_ = g_baleManager:getIsRoundBale(self.baleTypeIndex)
		local v_u_50_ = v_u_47_
		local function v_u_67_(p51_, p52_, p53_, p54_, p55_, p56_)
			-- upvalues: (copy) v_u_48_, (copy) v_u_49_, (copy) self, (copy) v_u_46_, (copy) v_u_45_, (copy) v_u_47_
			local v57_ = p55_ * p56_
			local v58_, v59_ = MathUtil.vector2Normalize(p53_ - p51_, p54_ - p52_)
			local v60_ = p51_ + v58_ * v57_
			local v61_ = p52_ + v59_ * v57_
			local v62_ = MathUtil.getYRotationFromDirection(v58_, v59_) + 1.5707963267948966
			local v63_ = v_u_48_.diameter
			if not v_u_49_ then
				v62_ = v62_ + 1.5707963267948966
				v63_ = v_u_48_.height
			end
			local v64_ = getTerrainHeightAtWorldPos(g_terrainNode, v60_, 0, v61_) + v63_ * 0.5
			local v65_ = Bale.new(self.isServer, self.isClient)
			if v65_:loadFromConfigXML(v_u_46_, v60_, v64_, v61_, 0, v62_, 0) then
				v65_:setFillType(v_u_45_)
				v65_:setFillLevel(v_u_47_)
				v65_:setOwnerFarmId(self.field:getOwner(), true)
				v65_:register()
				local v66_ = self.bales
				table.insert(v66_, v65_)
			end
		end
		local v_u_68_ = 0
		local v_u_69_ = nil
		local v_u_70_ = nil
		local v_u_71_ = nil
		local v_u_72_ = nil
		local v_u_73_ = nil
		local function v83_(p74_, p75_, p76_, p77_, _, _, _, p78_)
			-- upvalues: (copy) v_u_41_, (ref) v_u_68_, (ref) v_u_69_, (ref) v_u_70_, (ref) v_u_71_, (ref) v_u_72_, (ref) v_u_73_, (ref) v_u_50_, (copy) v_u_47_, (copy) v_u_67_
			local v79_ = MathUtil.vector2Length(p76_ - p74_, p77_ - p75_)
			local v80_ = v79_ * (v_u_41_ / p78_)
			v_u_68_ = v80_
			v_u_69_ = p74_
			v_u_70_ = p75_
			v_u_71_ = p76_
			v_u_72_ = p77_
			v_u_73_ = v79_
			while v_u_68_ > 0 do
				if v_u_68_ <= v_u_50_ then
					v_u_50_ = v_u_50_ - v_u_68_
					v_u_68_ = 0
				else
					local v81_ = v_u_50_ - v_u_68_
					v_u_68_ = math.abs(v81_)
					local v82_ = 1 - v_u_68_ / v80_
					v_u_50_ = v_u_47_
					v_u_67_(p74_, p75_, p76_, p77_, v79_, v82_)
				end
			end
		end
		local function v84_()
			-- upvalues: (ref) v_u_68_, (copy) v_u_67_, (ref) v_u_69_, (ref) v_u_70_, (ref) v_u_71_, (ref) v_u_72_, (ref) v_u_73_, (copy) self
			if v_u_68_ > 0 then
				v_u_67_(v_u_69_, v_u_70_, v_u_71_, v_u_72_, v_u_73_, 1)
			end
			self.finishedBaleSpawning = true
		end
		FieldCourseIterator.new(v42_, v43_, v44_, v83_, v84_)
	end
end

-- Local values: fruitType, fruitTypeDesc, fieldPreparingTask
function BaleWrapMission:getFieldPreparingTask()
	local v86_ = FruitType.GRASS
	local v87_ = g_fruitTypeManager:getFruitTypeByIndex(v86_)
	local v88_ = FieldUpdateTask.new()
	v88_:setArea(self.field:getDensityMapPolygon())
	v88_:setField(self.field)
	v88_:setFruit(v86_, v87_.cutState)
	if v87_.harvestGroundType ~= nil then
		v88_:setGroundType(v87_.harvestGroundType)
	end
	return v88_
end

function BaleWrapMission:getIsPrepared()
	if BaleWrapMission:superClass().getIsPrepared(self) then
		return self.finishedBaleSpawning
	else
		return false
	end
end

-- Local values: _, bale
function BaleWrapMission:finishField()
	if self.isServer then
		for _, v91_ in ipairs(self.bales) do
			v91_:delete()
		end
		self.bales = {}
	end
	BaleWrapMission:superClass().finishField(self)
end

-- Local values: _, baleUniqueId, bale, numLoadedBales
function BaleWrapMission:update(dt)
	if self.isServer and self.balesToLoadByUniqueId ~= nil then
		for _, v94_ in ipairs(self.balesToLoadByUniqueId) do
			local v95_ = g_currentMission.itemSystem:getItemByUniqueId(v94_)
			if v95_ ~= nil then
				local v96_ = self.bales
				table.insert(v96_, v95_)
			end
		end
		self.balesToLoadByUniqueId = nil
		local v97_ = #self.bales
		if v97_ ~= self.numOfBales then
			Logging.error("Could not load all bales from savegame")
			self.numOfBales = v97_
		end
	end
	BaleWrapMission:superClass().update(self, dt)
end

-- Local values: wrapStateSum, completion, allDropped, _, bale, totalBaleWrapState, numBales, percentage
function BaleWrapMission:getCompletion()
	local v99_ = 0
	local v100_ = 0
	local v101_ = true
	for _, v102_ in ipairs(self.bales) do
		v99_ = v99_ + v102_.wrappingState
		if v102_:getIsMounted() then
			v101_ = false
		end
	end
	if self.balesToLoadByUniqueId == nil then
		local v103_ = #self.bales
		local v104_ = v103_ <= 0 and 1 or v99_ / v103_
		v100_ = v104_ * 0.99
		if v104_ == 1 and v101_ then
			v100_ = v100_ + 0.01
		end
	end
	return v100_
end

function BaleWrapMission:getRewardPerHa()
	return 1
end

-- Local values: data, difficultyMultiplier, base, reward
function BaleWrapMission:getReward()
	local v106_ = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
	local v107_ = 1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty
	return BaleWrapMission:superClass().getReward(self) + v106_.rewardPerBale * self.numOfBales * v107_
end

-- Local values: details, isRoundBale, baleType
function BaleWrapMission:getDetails()
	local v109_ = BaleWrapMission:superClass().getDetails(self)
	local v110_
	if g_baleManager:getIsRoundBale(self.baleTypeIndex) then
		v110_ = g_i18n:getText("contract_details_bale_type_round")
	else
		v110_ = g_i18n:getText("contract_details_bale_type_square")
	end
	local v111_ = {
		["title"] = g_i18n:getText("contract_details_bale_type"),
		["value"] = v110_
	}
	table.insert(v109_, v111_)
	return v109_
end

-- Local values: isRoundBale
function BaleWrapMission:getVehicleVariant()
	return g_baleManager:getIsRoundBale(self.baleTypeIndex) and "ROUNDBALE" or "SQUAREBALE"
end

-- Local values: isRoundBale
function BaleWrapMission:getVariant()
	return g_baleManager:getIsRoundBale(self.baleTypeIndex) and "ROUNDBALER" or "SQUAREBALER"
end

function BaleWrapMission:getMissionTypeName()
	return BaleWrapMission.NAME
end

function BaleWrapMission:validate(event)
	if BaleWrapMission:superClass().validate(self, event) then
		return (self:getIsFinished() or BaleWrapMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function BaleWrapMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME).rewardPerBale = xmlFile:getFloat(key .. "#rewardPerBale", 300)
	return true
end
function BaleWrapMission.tryGenerateMission()
	if BaleWrapMission.canRun() then
		local v118_ = g_fieldManager:getFieldForMission()
		if v118_ == nil then
			return
		end
		if v118_.currentMission ~= nil then
			return
		end
		if not BaleWrapMission.isAvailableForField(v118_, nil) then
			return
		end
		local v119_
		if math.random() > 0.5 then
			v119_ = g_baleManager:getBaleIndex(FillType.GRASS_WINDROW, true, 1.2, 0, 0, 1.5, "")
		else
			v119_ = g_baleManager:getBaleIndex(FillType.GRASS_WINDROW, false, 1.2, 0.9, 1.8, 0, "")
		end
		if v119_ == nil then
			return
		end
		local v120_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS).literPerSqm
		local v121_ = MathUtil.haToSqm(v118_:getAreaHa())
		local v122_ = g_baleManager:getBaleCapacityByBaleIndex(v119_, FillType.GRASS_WINDROW)
		local v123_ = v121_ * v120_ / v122_
		local v124_ = math.floor(v123_)
		if v124_ == 0 then
			return
		end
		local v125_ = BaleWrapMission.new(true, g_client ~= nil)
		if v125_:init(v118_, v119_, v124_) then
			v125_:setDefaultEndDate()
			return v125_
		end
		v125_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, fruitTypeDesc, growthState, environment
function BaleWrapMission.isAvailableForField(field, mission)
	if mission == nil then
		local v128_ = field:getFieldState()
		if not v128_.isValid then
			return false
		end
		local v129_ = v128_.fruitTypeIndex
		if v129_ ~= FruitType.GRASS then
			return false
		end
		if not g_fruitTypeManager:getFruitTypeByIndex(v129_):getIsHarvestable(v128_.growthState) then
			return false
		end
	end
	local v130_ = g_currentMission.environment
	return v130_ == nil or v130_.currentSeason ~= Season.WINTER
end
function BaleWrapMission.canRun()
	local v131_ = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
	return v131_.numInstances < v131_.maxNumInstances
end
g_missionManager:registerMissionType(BaleWrapMission, BaleWrapMission.NAME, 2)
