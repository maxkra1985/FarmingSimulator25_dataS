-- Local values: AbstractFieldMission_mt
AbstractFieldMission = {}
source("dataS/scripts/missions/field/AbstractFieldMissionHotspot.lua")
local AbstractFieldMission_mt = Class(AbstractFieldMission, AbstractMission)
InitStaticObjectClass(AbstractFieldMission, "AbstractFieldMission")
AbstractFieldMission.FIELD_SIZE_MEDIUM = 1.5
AbstractFieldMission.FIELD_SIZE_LARGE = 4
AbstractFieldMission.SQM_PER_PARTITION = 2500

function AbstractFieldMission.registerSavegameXMLPaths(schema, key)
	AbstractFieldMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. ".field#id", "Field id")
	schema:register(XMLValueType.STRING, key .. ".field.preparingTask#className")
	FieldUpdateTask.registerXMLPaths(schema, key .. ".field.preparingTask")
end

-- Upvalues: AbstractFieldMission_mt
-- Local values: self
function AbstractFieldMission.new(isServer, isClient, title, description, customMt)
	-- upvalues: (copy) AbstractFieldMission_mt
	local v9_ = AbstractMission.new(isServer, isClient, title, description, customMt or AbstractFieldMission_mt)
	v9_.workAreaTypes = {}
	v9_.moneyMultiplier = 1
	v9_.isInMissionMap = false
	v9_.fieldPercentageDone = 0
	v9_.completionModifier = nil
	v9_.completionFilter = nil
	v9_.isHotspotAdded = false
	v9_.mapHotspot = nil
	return v9_
end

function AbstractFieldMission:init(field)
	self:setField(field)
	return AbstractFieldMission:superClass().init(self)
end

-- Local values: fieldId
function AbstractFieldMission:setField(field)
	self.field = field
	field:setMission(self)
	local v14_ = field:getId()
	if v14_ ~= nil then
		self.progressTitle = string.format("%s (%s %d)", self.title, g_i18n:getText("contract_details_field"), v14_)
	end
	g_fieldManager:onFieldMissionStarted()
	self:createMapHotspot()
end

function AbstractFieldMission:createMapHotspot()
	if self.mapHotspot == nil then
		self.mapHotspot = AbstractFieldMissionHotspot.new()
	end
	self.mapHotspot:setField(self.field)
	self.mapHotspots = { self.mapHotspot }
end

function AbstractFieldMission:getField()
	return self.field
end

function AbstractFieldMission:getMapHotspots()
	return self.mapHotspots
end

function AbstractFieldMission:getWorldPosition()
	return self.field:getIndicatorPosition()
end

-- Local values: name
function AbstractFieldMission:getLocation()
	local v20_ = self.field:getName()
	return string.format(g_i18n:getText("contract_farmland"), v20_)
end

function AbstractFieldMission:reactivate()
	self:createModifier()
	AbstractFieldMission:superClass().reactivate(self)
end

function AbstractFieldMission:delete()
	self:removeFromMissionMap()
	self:removeHotspot()
	if self.mapHotspot ~= nil then
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
	self.mapHotspots = nil
	if self.field ~= nil then
		self.field:setMission(nil)
		g_fieldManager:onFieldMissionDeleted()
	end
	AbstractFieldMission:superClass().delete(self)
end

-- Local values: taskKey
function AbstractFieldMission:saveToXMLFile(xmlFile, key)
	AbstractFieldMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. ".field#id", self.field:getId())
	if self.status == MissionStatus.PREPARING and (self.fieldPreparingTask ~= nil and self.fieldPreparingTask:getIsFinished()) then
		local v26_ = key .. ".field.preparingTask"
		xmlFile:setValue(v26_ .. "#className", ClassUtil.getClassNameByObject(self.fieldPreparingTask))
		self.fieldPreparingTask:saveToXMLFile(xmlFile, v26_)
	end
end

-- Local values: fieldId, field, fieldPreparingTaskKey, className, class, fieldPreparingTask
function AbstractFieldMission:loadFromXMLFile(xmlFile, key)
	local v30_ = xmlFile:getValue(key .. ".field#id")
	local v31_ = g_fieldManager:getFieldById(v30_)
	if v31_ == nil then
		Logging.xmlWarning(xmlFile, "Mission \'%s\' field \'%s\' is not available.", key, v30_)
		return false
	end
	self:setField(v31_)
	if not AbstractFieldMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	local v32_ = key .. ".field.preparingTask"
	if xmlFile:hasProperty(v32_) then
		local v33_ = xmlFile:getValue(v32_ .. "#className", "FieldUpdateTask")
		local v34_ = ClassUtil.getClassObject(v33_)
		if v34_ == nil then
			Logging.xmlWarning(xmlFile, "Class \'%s\' not defined for update task \'%s\'", v33_, v32_)
		else
			local v35_ = v34_.new()
			if v35_:loadFromXMLFile(xmlFile, v32_) then
				v35_:setNeedsSaving(false)
				v35_:enqueue()
				self.fieldPreparingTask = v35_
			end
		end
	end
	if self.status == MissionStatus.PREPARING or self.status == MissionStatus.RUNNING then
		self:addToMissionMap()
	end
	return true
end

function AbstractFieldMission:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.field:getId())
	AbstractFieldMission:superClass().writeStream(self, streamId, connection)
end

-- Local values: fieldId, field
function AbstractFieldMission:readStream(streamId, connection)
	local v42_ = streamReadInt32(streamId)
	self:setField((g_fieldManager:getFieldById(v42_)))
	AbstractFieldMission:superClass().readStream(self, streamId, connection)
	if self.status == MissionStatus.PREPARING or self.status == MissionStatus.RUNNING then
		self:addToMissionMap()
	end
end

function AbstractFieldMission:update(dt)
	AbstractFieldMission:superClass().update(self, dt)
	if self.status == MissionStatus.RUNNING and (g_localPlayer ~= nil and (g_localPlayer.farmId == self.farmId and not self.isHotspotAdded)) then
		self:addHotspots()
	end
end

function AbstractFieldMission:start(spawnVehicles)
	if not AbstractFieldMission:superClass().start(self, spawnVehicles) then
		return false
	end
	self:addToMissionMap()
	return true
end

function AbstractFieldMission:prepare(spawnVehicles)
	AbstractFieldMission:superClass().prepare(self, spawnVehicles)
	self:prepareField()
	self:createModifier()
end

function AbstractFieldMission:prepareField()
	if self.isServer then
		self.fieldPreparingTask = self:getFieldPreparingTask()
		if self.fieldPreparingTask ~= nil then
			self.fieldPreparingTask:setNeedsSaving(false)
			g_fieldManager:addFieldUpdateTask(self.fieldPreparingTask)
		end
	end
end

-- Local values: fieldState, fieldPreparingTask
function AbstractFieldMission:getFieldPreparingTask()
	local v51_ = self.field:getFieldState()
	if v51_.isValid then
		local v52_ = v51_:createFieldUpdateTask()
		v52_:clearHeight()
		v52_:setField(self.field)
		return v52_
	end
end

function AbstractFieldMission:getIsPrepared()
	if AbstractFieldMission:superClass().getIsPrepared(self) then
		return self.fieldPreparingTask == nil and true or self.fieldPreparingTask:getIsFinished()
	else
		return false
	end
end

-- Local values: task
function AbstractFieldMission:finishField()
	if self.isServer then
		local v55_ = self:getFieldFinishTask()
		if v55_ ~= nil then
			v55_:setField(self.field)
			g_fieldManager:addFieldUpdateTask(v55_)
		end
	end
end

-- Local values: fieldState
function AbstractFieldMission:getFieldFinishTask()
	local v57_ = self.field:getFieldState()
	if v57_.isValid then
		return v57_:createFieldUpdateTask()
	else
		return nil
	end
end

function AbstractFieldMission:started()
	self:addToMissionMap()
end

-- Local values: mission
function AbstractFieldMission:finish(finishState)
	AbstractFieldMission:superClass().finish(self, finishState)
	self:removeHotspot()
	local v61_ = g_currentMission
	if v61_:getFarmId() == self.farmId then
		if finishState == MissionFinishState.SUCCESS then
			v61_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_field_finished"), self.field:getId()))
			return
		end
		if finishState == MissionFinishState.FAILED then
			v61_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_field_failed"), self.field:getId()))
			return
		end
		if finishState == MissionFinishState.TIMED_OUT then
			v61_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_field_timedOut"), self.field:getId()))
		end
	end
end

function AbstractFieldMission:dismiss()
	self:finishField()
	AbstractFieldMission:superClass().dismiss(self)
end

function AbstractFieldMission:removeAccess()
	self:removeFromMissionMap()
	AbstractFieldMission:superClass().removeAccess(self)
end

function AbstractFieldMission:validate()
	if AbstractFieldMission:superClass().validate(self) then
		if self.field == nil then
			return false
		else
			return not self.field:getHasOwner()
		end
	else
		return false
	end
end

function AbstractFieldMission:createModifier() end

-- Local values: densityMapPolygon, numPartitions, minZ, maxZ, sizeSqm, currentMinZ, currentMaxZ, regionPerPartition, i, partition, partition
function AbstractFieldMission:initializeModifier()
	if self.completionModifier == nil then
		::l2::
	else
		self.field:getDensityMapPolygon():applyToModifier(self.completionModifier)
		self.completionPartitions = {}
		local v66_, v67_ = self.completionModifier:getPolygonMinMaxZ()
		if v66_ == nil then
			local v68_ = self.completionPartitions
			table.insert(v68_, {
				["wasCalculated"] = false,
				["percentageDone"] = 0,
				["sumPixels"] = 0,
				["area"] = 0,
				["totalArea"] = 0
			})
			goto l2
		end
		local v69_ = MathUtil.haToSqm(self.field:getAreaHa()) / AbstractFieldMission.SQM_PER_PARTITION
		local v70_ = math.ceil(v69_)
		local v71_ = (v67_ - v66_) / v70_
		local v72_ = nil
		local v73_ = nil
		for _ = 1, v70_ do
			if v72_ == nil then
				v73_ = v66_
			end
			local v74_ = v73_ + v71_
			local v75_ = math.ceil(v74_)
			local v76_ = {
				["wasCalculated"] = false,
				["percentageDone"] = 0,
				["sumPixels"] = 0,
				["area"] = 0,
				["totalArea"] = 0,
				["minZ"] = v73_,
				["maxZ"] = math.min(v75_, v67_)
			}
			local v77_ = self.completionPartitions
			table.insert(v77_, v76_)
			if v73_ == nil or v67_ <= v75_ then
				goto l2
			end
			v72_ = v73_
			v73_ = v75_
		end
	end
end

-- Local values: partition
function AbstractFieldMission:setPartitionRegion(partitionIndex)
	if self.completionPartitions ~= nil and #self.completionPartitions ~= 1 then
		if self.completionModifier ~= nil then
			local v80_ = self.completionPartitions[partitionIndex]
			self.completionModifier:setPolygonClipRegion(v80_.minZ, v80_.maxZ)
		end
	end
end

-- Local values: sumPixels, area, totalArea
function AbstractFieldMission:getPartitionCompletion(partitionIndex)
	self:setPartitionRegion(partitionIndex)
	if self.completionModifier == nil then
		return 0, 0, 0
	end
	local v83_, v84_, v85_ = self.completionModifier:executeGet(self.completionFilter)
	return v83_, v84_, v85_
end

-- Local values: fieldCompletion
function AbstractFieldMission:getCompletion()
	return self:getFieldCompletion() / AbstractMission.SUCCESS_FACTOR
end

-- Local values: sumPixels, area, totalArea, partition
function AbstractFieldMission:getFieldCompletion()
	if not self.isFieldCompletionInitialized then
		self:initializeModifier()
		self.isFieldCompletionInitialized = true
	end
	if self.currentPartitionCompletionIndex == nil then
		self.currentPartitionCompletionIndex = 1
	end
	local v88_, v89_, v90_ = self:getPartitionCompletion(self.currentPartitionCompletionIndex)
	if v89_ ~= nil then
		local v91_ = self.completionPartitions[self.currentPartitionCompletionIndex]
		v91_.wasCalculated = true
		v91_.sumPixels = v88_
		v91_.area = v89_
		v91_.totalArea = v90_
	end
	self:updateFieldPercentageDone(v90_)
	self.currentPartitionCompletionIndex = self.currentPartitionCompletionIndex + 1
	if self.currentPartitionCompletionIndex > #self.completionPartitions then
		self.currentPartitionCompletionIndex = 1
	end
	return self.fieldPercentageDone
end

-- Local values: areaDone, areaTotal, allCalculated, _, partition
function AbstractFieldMission:updateFieldPercentageDone(totalArea)
	local v94_ = 0
	local v95_ = 0
	local v96_ = true
	for _, v97_ in ipairs(self.completionPartitions) do
		if not v97_.wasCalculated then
			v96_ = false
		end
		if totalArea > 0 then
			v94_ = v94_ + v97_.area
		else
			v94_ = v94_ + v97_.totalArea
		end
		v95_ = v95_ + v97_.totalArea
	end
	if v96_ then
		if v95_ == 0 then
			self:finish(MissionFinishState.FAILED)
			return
		end
		self.fieldPercentageDone = v94_ / v95_
	end
end

-- Local values: areaHa, fieldSize
function AbstractFieldMission:getVehicleSize()
	local v99_ = self.field:getAreaHa()
	return AbstractFieldMission.FIELD_SIZE_LARGE < v99_ and "large" or (AbstractFieldMission.FIELD_SIZE_MEDIUM < v99_ and "medium" or "small")
end

-- Local values: details
function AbstractFieldMission:getDetails()
	local v101_ = AbstractFieldMission:superClass().getDetails(self)
	local v102_ = {
		["title"] = g_i18n:getText("contract_details_field"),
		["value"] = self.field:getName()
	}
	table.insert(v101_, v102_)
	local v103_ = {
		["title"] = g_i18n:getText("contract_details_fieldSize"),
		["value"] = g_i18n:formatArea(self.field:getAreaHa(), 2)
	}
	table.insert(v101_, v103_)
	return v101_
end

function AbstractFieldMission:getRewardPerHa()
	return 1
end

-- Local values: mission, difficultyMultiplier, area, base, rewardPerHa, reward
function AbstractFieldMission:getReward()
	local v105_ = 1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty
	local v106_ = self.field:getAreaHa()
	return AbstractFieldMission:superClass().getReward(self) + self:getRewardPerHa() * v106_ * v105_
end

-- Local values: field
function AbstractFieldMission:getFarmlandId()
	local v108_ = self.field
	if v108_ == nil then
		return nil
	else
		return v108_:getId()
	end
end

function AbstractFieldMission:addToMissionMap()
	if not self.isInMissionMap then
		self:updateMissionMap(self.activeMissionId)
		self.isInMissionMap = true
	end
end

function AbstractFieldMission:removeFromMissionMap()
	if self.isInMissionMap then
		self:updateMissionMap(0)
		self.isInMissionMap = false
	end
end

-- Local values: polygon
function AbstractFieldMission:updateMissionMap(missionId)
	local v113_ = self.field:getDensityMapPolygon()
	g_missionManager:setMissionMapActiveMissionId(v113_, missionId)
end

function AbstractFieldMission:getNPC()
	return self.field.farmland:getNPC()
end

function AbstractFieldMission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)
	local v117_ = self:getIsRunning()
	if v117_ then
		v117_ = workAreaType == nil and true or self.workAreaTypes[workAreaType]
	end
	return v117_
end

function AbstractFieldMission:addHotspots()
	if self.mapHotspot ~= nil then
		self.isHotspotAdded = true
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
end

function AbstractFieldMission:removeHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
end
