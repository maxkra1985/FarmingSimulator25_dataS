-- Local values: BeehiveSystem_mt
BeehiveSystem = {}
BeehiveSystem.COOLDOWN_DURATION = 603
BeehiveSystem.DEBUG_ENABLED = false
local BeehiveSystem_mt = Class(BeehiveSystem)

-- Upvalues: BeehiveSystem_mt
-- Local values: self
function BeehiveSystem.new(mission, customMt)
	-- upvalues: (copy) BeehiveSystem_mt
	local v4_ = customMt or BeehiveSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.beehives = {}
	v5_.beehivesSortedRadius = {}
	v5_.beehivePalletSpawners = {}
	v5_.isFxActive = false
	v5_.isProductionActive = false
	if v5_.mission:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsBeehiveDebug", "Toggles beehive debug mode", "consoleCommandBeehiveDebug", v5_)
	end
	v5_.updateCooldown = BeehiveSystem.COOLDOWN_DURATION
	v5_.currentSpawnerUpdateIndex = 0
	v5_.lastTimeNoSpawnerWarningDisplayed = 0
	return v5_
end

function BeehiveSystem:delete()
	removeConsoleCommand("gsBeehiveDebug")
end

function BeehiveSystem:addBeehive(beehiveToAdd)
	if #self.beehivesSortedRadius == 0 then
		self:updateState()
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
		g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.updateBeehivesState, self)
	end
	local v8_ = self.beehivesSortedRadius
	table.insert(v8_, beehiveToAdd)
	if self.mission.isMissionStarted then
		self:showNoSpawnerWarning(beehiveToAdd)
	end
	table.sort(self.beehivesSortedRadius, function(p9_, p10_)
		return p9_.spec_beehive.actionRadius > p10_.spec_beehive.actionRadius
	end)
end

function BeehiveSystem:removeBeehive(beehive)
	table.removeElement(self.beehivesSortedRadius, beehive)
	if #self.beehivesSortedRadius == 0 then
		g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
		g_messageCenter:unsubscribe(MessageType.DAY_NIGHT_CHANGED, self)
	end
end

function BeehiveSystem:onHourChanged()
	self:updateBeehivesOutput()
	self:updateBeehivesState()
end

-- Local values: beehiveSpawner
function BeehiveSystem:update()
	if #self.beehivePalletSpawners == 0 or not self.mission:getIsServer() then
		return
	elseif self.updateCooldown <= 0 then
		local v15_ = self.beehivePalletSpawners[self.currentSpawnerUpdateIndex]
		if v15_ == nil then
			self.currentSpawnerUpdateIndex = 1
			self.updateCooldown = BeehiveSystem.COOLDOWN_DURATION
		else
			v15_:updatePallets()
			self.currentSpawnerUpdateIndex = self.currentSpawnerUpdateIndex + 1
		end
	else
		self.updateCooldown = self.updateCooldown - 1
		return
	end
end

-- Local values: i, beehive, beehiveOwner, palletSpawner, honeyAmount
function BeehiveSystem:updateBeehivesOutput(farmId)
	if self.mission:getIsServer() then
		for v18_ = 1, #self.beehivesSortedRadius do
			local v19_ = self.beehivesSortedRadius[v18_]
			local v20_ = v19_:getOwnerFarmId()
			if farmId == nil or farmId == v20_ then
				local v21_ = self:getFarmBeehivePalletSpawner(v20_)
				if v21_ ~= nil then
					local v22_ = v19_:getHoneyAmountToSpawn()
					if v22_ > 0 then
						v21_:addFillLevel(v22_)
					end
				end
			end
		end
	end
end

-- Local values: environment
function BeehiveSystem:updateState()
	local v24_ = g_currentMission.environment
	self.isFxActive = true
	self.isProductionActive = v24_.currentSeason ~= Season.WINTER
	if not v24_.isSunOn or (v24_.weather:getIsRaining() or not self.isProductionActive) then
		self.isFxActive = false
	end
end

-- Local values: i
function BeehiveSystem:updateBeehivesState()
	self:updateState()
	for v26_ = 1, #self.beehivesSortedRadius do
		self.beehivesSortedRadius[v26_]:updateBeehiveState()
	end
end

-- Local values: _, beehive
function BeehiveSystem:getFarmHasBeehive(farmId)
	for _, v29_ in ipairs(self.beehivesSortedRadius) do
		if v29_:getOwnerFarmId() == farmId then
			return true
		end
	end
	return false
end

function BeehiveSystem:getBeehives()
	return self.beehivesSortedRadius
end

-- Local values: beehiveInfluenceFactor, i, beehive
function BeehiveSystem:getBeehiveInfluenceFactorAt(wx, wz)
	local v34_ = 0
	for v35_ = 1, #self.beehivesSortedRadius do
		v34_ = v34_ + self.beehivesSortedRadius[v35_]:getBeehiveInfluenceFactor(wx, wz)
		if v34_ >= 1 then
			break
		end
	end
	return math.min(v34_, 1)
end

function BeehiveSystem:addBeehivePalletSpawner(beehivePalletSpawner)
	table.addElement(self.beehivePalletSpawners, beehivePalletSpawner)
	self:updateBeehivesOutput(beehivePalletSpawner:getOwnerFarmId())
end

function BeehiveSystem:removeBeehivePalletSpawner(beehivePalletSpawner)
	table.removeElement(self.beehivePalletSpawners, beehivePalletSpawner)
	self:showNoSpawnerWarning(beehivePalletSpawner)
end

-- Local values: placeableFarmId, farmId, text
function BeehiveSystem:showNoSpawnerWarning(placeable)
	if self.mission:getIsClient() and g_time - self.lastTimeNoSpawnerWarningDisplayed > 5000 then
		local v42_ = placeable:getOwnerFarmId()
		local v43_ = self.mission:getFarmId()
		if self:getFarmHasBeehive(v43_) and (v43_ == v42_ and self:getFarmBeehivePalletSpawner(v43_) == nil) then
			local v44_ = g_i18n:getText("ingameNotification_noPalletLocationAvailable") .. string.format(" (%s)", g_i18n:getText("category_beeHives"))
			self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, v44_)
			self.lastTimeNoSpawnerWarningDisplayed = g_time
		end
	end
end

-- Local values: _, beehivePalletSpawner
function BeehiveSystem:getFarmBeehivePalletSpawner(farmId)
	for _, v47_ in ipairs(self.beehivePalletSpawners) do
		if v47_:getOwnerFarmId() == farmId then
			return v47_
		end
	end
	return nil
end

function BeehiveSystem:consoleCommandBeehiveDebug()
	BeehiveSystem.DEBUG_ENABLED = not BeehiveSystem.DEBUG_ENABLED
	local v48_ = BeehiveSystem.DEBUG_ENABLED
	return "BeehiveSystem.DEBUG_ENABLED=" .. tostring(v48_)
end
