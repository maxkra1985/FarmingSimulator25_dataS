-- Local values: AIJobTypeManager_mt
AIJobTypeManager = {}
AIJobType = nil
local AIJobTypeManager_mt = Class(AIJobTypeManager)

-- Upvalues: AIJobTypeManager_mt
-- Local values: self
function AIJobTypeManager.new(isServer, customMt)
	-- upvalues: (copy) AIJobTypeManager_mt
	local v4_ = customMt or AIJobTypeManager_mt
	local v5_ = setmetatable({}, v4_)
	v5_.isServer = isServer
	return v5_
end

function AIJobTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.jobTypes = {}
	self.nameToIndex = {}
	self.classObjectToIndex = {}
	AIJobType = self.nameToIndex
	self:registerJobType("GOTO", "$l10n_ai_jobTitleGoto", AIJobGoTo)
	self:registerJobType("FIELDWORK", "$l10n_ai_jobTitleFieldWork", AIJobFieldWork)
	self:registerJobType("CONVEYOR", "$l10n_ai_jobTitleConveyor", AIJobConveyor)
	self:registerJobType("DELIVER", "$l10n_ai_jobTitleDeliver", AIJobDeliver)
	self:registerJobType("LOAD_AND_DELIVER", "$l10n_ai_jobTitleLoadAndDeliver", AIJobLoadAndDeliver)
end

function AIJobTypeManager:delete()
	self.jobTypes = {}
	self.nameToIndex = {}
	self.classObjectToIndex = {}
	AIJobType = self.nameToIndex
end

-- Local values: jobType
function AIJobTypeManager:registerJobType(name, title, classObject)
	if not ClassUtil.getIsValidIndexName(name) then
		Logging.warning("\'%s\' is not a valid name for a ai job type!", (tostring(name)))
		return nil
	end
	local v12_ = string.upper(name)
	if self.nameToIndex[v12_] ~= nil then
		Logging.warning("AI job type \'%s\' already exists!", (tostring(v12_)))
		return nil
	end
	local v13_ = {
		["name"] = v12_,
		["title"] = g_i18n:convertText(title),
		["classObject"] = classObject,
		["index"] = #self.jobTypes + 1
	}
	local v14_ = self.jobTypes
	table.insert(v14_, v13_)
	self.nameToIndex[v12_] = v13_.index
	self.classObjectToIndex[classObject] = v13_.index
	return v13_
end

-- Local values: classObject
function AIJobTypeManager:getJobTypeIndex(job)
	local v17_ = ClassUtil.getClassObjectByObject(job)
	if v17_ == nil then
		return nil
	else
		return self.classObjectToIndex[v17_]
	end
end

-- Local values: jobType, job
function AIJobTypeManager:createJob(typeIndex)
	if typeIndex == nil then
		return nil
	end
	local v20_ = self.jobTypes[typeIndex]
	if v20_ == nil then
		return nil
	end
	local v21_ = v20_.classObject.new(self.isServer)
	v21_.jobTypeIndex = typeIndex
	return v21_
end

function AIJobTypeManager:getJobTypeByIndex(index)
	return self.jobTypes[index]
end

function AIJobTypeManager:getJobTypeIndexByName(name)
	if name == nil then
		return nil
	end
	local v26_ = string.upper(name)
	return self.nameToIndex[v26_]
end
