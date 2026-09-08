-- Local values: PrecisionFarmingDensityMapUpdater_mt, getClassObject, getClassName, getClassNameByObject
PrecisionFarmingDensityMapUpdater = {}
PrecisionFarmingDensityMapUpdater.MOD_NAME = g_currentModName
local PrecisionFarmingDensityMapUpdater_mt = Class(PrecisionFarmingDensityMapUpdater)

-- Upvalues: PrecisionFarmingDensityMapUpdater_mt
-- Local values: self
function PrecisionFarmingDensityMapUpdater.new(precisionFarming, customMt)
	-- upvalues: (copy) PrecisionFarmingDensityMapUpdater_mt
	local v4_ = customMt or PrecisionFarmingDensityMapUpdater_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.pendingUpdateTasks = {}
	v5_.activeUpdateTask = nil
	return v5_
end

function PrecisionFarmingDensityMapUpdater:addUpdateTask(updateTask, immediate)
	if immediate then
		updateTask:start()
		while not updateTask:getIsFinished() do
			updateTask:update(9999)
		end
	else
		local v9_ = self.pendingUpdateTasks
		table.insert(v9_, updateTask)
	end
end

function PrecisionFarmingDensityMapUpdater:update(dt)
	if self.activeUpdateTask == nil and #self.pendingUpdateTasks > 0 then
		self.activeUpdateTask = table.remove(self.pendingUpdateTasks, 1)
		if not self.activeUpdateTask:start() then
			self.activeUpdateTask = nil
		end
	end
	if self.activeUpdateTask ~= nil then
		self.activeUpdateTask:update(dt)
		if self.activeUpdateTask:getIsFinished() then
			self.activeUpdateTask = nil
		end
	end
end
local function v_u_16_(p12_)
	local v13_ = string.split(p12_, ".")
	local v14_ = _G[v13_[1]]
	if type(v14_) ~= "table" then
		return nil
	end
	for v15_ = 2, #v13_ do
		v14_ = v14_[v13_[v15_]]
		if type(v14_) ~= "table" then
			return nil
		end
	end
	return v14_
end
local function v_u_20_(p17_)
	for v18_, v19_ in pairs(_G) do
		if v19_ == p17_ then
			return v18_
		end
	end
end
local function v_u_22_(p21_)
	-- upvalues: (copy) v_u_20_
	if p21_ == nil or p21_.class == nil then
		return nil
	else
		return v_u_20_((p21_:class()))
	end
end

-- Upvalues: getClassObject
function PrecisionFarmingDensityMapUpdater:loadFromItemsXML(xmlFile, key)
	-- upvalues: (copy) v_u_16_
	xmlFile:iterate((key .. ".densityMapUpdater") .. ".updateTask", function(_, p26_)
		-- upvalues: (copy) xmlFile, (ref) v_u_16_, (copy) self
		local v27_ = xmlFile:getString(p26_ .. "#className")
		if v27_ ~= nil then
			local v28_ = v_u_16_(v27_)
			if v28_ ~= nil then
				local v29_ = v28_.new()
				if v29_:loadFromXMLFile(xmlFile, p26_) then
					self:addUpdateTask(v29_)
				end
			end
		end
	end)
end

-- Upvalues: getClassNameByObject
-- Local values: i, baseKey, _, updateTask, baseKey
function PrecisionFarmingDensityMapUpdater:saveToXMLFile(xmlFile, key, usedModNames)
	-- upvalues: (copy) v_u_22_
	local v33_ = key .. ".densityMapUpdater"
	local v34_
	if self.activeUpdateTask == nil then
		v34_ = 0
	else
		local v35_ = string.format("%s.updateTask(0)", v33_)
		xmlFile:setString(v35_ .. "#className", v_u_22_(self.activeUpdateTask))
		self.activeUpdateTask:saveToXMLFile(xmlFile, v35_)
		v34_ = 1
	end
	for _, v36_ in pairs(self.pendingUpdateTasks) do
		local v37_ = string.format("%s.updateTask(%d)", v33_, v34_)
		xmlFile:setString(v37_ .. "#className", v_u_22_(v36_))
		v36_:saveToXMLFile(xmlFile, v37_)
		v34_ = v34_ + 1
	end
end

function PrecisionFarmingDensityMapUpdater:overwriteGameFunctions(pfModule) end
