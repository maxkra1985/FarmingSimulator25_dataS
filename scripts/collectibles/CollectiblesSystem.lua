-- Local values: CollectiblesSystem_mt
source("dataS/scripts/collectibles/Collectible.lua")
source("dataS/scripts/collectibles/CollectibleStateEvent.lua")
source("dataS/scripts/collectibles/CollectibleTarget.lua")
source("dataS/scripts/collectibles/CollectibleTriggerEvent.lua")
source("dataS/scripts/collectibles/CollectibleActivatable.lua")
CollectiblesSystem = {}
local CollectiblesSystem_mt = Class(CollectiblesSystem)

-- Upvalues: CollectiblesSystem_mt
-- Local values: self
function CollectiblesSystem.new(isServer, customMt)
	-- upvalues: (copy) CollectiblesSystem_mt
	local v4_ = customMt or CollectiblesSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.isServer = isServer
	v5_.isActive = false
	v5_.isComplete = false
	v5_.collectibles = {}
	v5_.collected = {}
	v5_.collectibleIndexToName = {}
	v5_.groups = {}
	return v5_
end

function CollectiblesSystem:delete()
	removeConsoleCommand("gsCollectiblesShowAll")
end

-- Local values: xmlFilename, collectiblesFile, modName, _, customEnv, totalGroups, index, key, name, target, dialogText, dialogIntroText, dialogTitle, incompleteNodeIndex, completeNodeIndex, totalItems, index, key, name, target, dialogText, dialogTitle, groupName
function CollectiblesSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	local v9_ = getXMLString(xmlFile, "map.collectibles#filename")
	if v9_ ~= nil then
		local v10_ = Utils.getFilename(v9_, baseDirectory)
		local v11_ = XMLFile.load("collectibles", v10_)
		if v11_ == nil then
			Logging.error("Collectibles file \'%s\' does not exist", v10_)
			return
		end
		local v12_, _ = Utils.getModNameAndBaseDirectory(v10_)
		local v13_ = 0
		for v14_, v15_ in v11_:iterator("collectibles.group") do
			local v16_ = v11_:getString(v15_ .. "#name")
			local v17_ = v11_:getString(v15_ .. "#target")
			local v18_ = v11_:getString(v15_ .. "#dialogText")
			if v18_ ~= nil then
				v18_ = g_i18n:convertText(v18_, v12_)
			end
			local v19_ = v11_:getString(v15_ .. "#dialogIntroText")
			if v19_ ~= nil then
				v19_ = g_i18n:convertText(v19_, v12_)
			end
			local v20_ = v11_:getString(v15_ .. "#dialogTitle")
			if v20_ ~= nil then
				v20_ = g_i18n:convertText(v20_, v12_)
			end
			local v21_ = v11_:getString("collectibles.target.incompleteNode")
			local v22_ = v11_:getString("collectibles.target.completeNode")
			self.groups[v16_] = {
				["targetName"] = v17_,
				["index"] = v14_,
				["dialogText"] = v18_,
				["dialogIntroText"] = v19_,
				["dialogTitle"] = v20_,
				["moneyReward"] = v11_:getInt(v15_ .. "#moneyReward"),
				["totalItems"] = 0,
				["collectedItems"] = 0,
				["incompleteNodeIndex"] = v21_,
				["completeNodeIndex"] = v22_
			}
			v13_ = v13_ + 1
		end
		local v23_ = 0
		for v24_, v25_ in v11_:iterator("collectibles.collectible") do
			if v23_ == 255 then
				Logging.warning("No more than 255 collectibles are supported.")
				break
			end
			local v26_ = v11_:getString(v25_ .. "#name")
			local v27_ = v11_:getString(v25_ .. "#target")
			if v26_ == nil then
				Logging.xmlError(v11_, "Collectible has no name at %d", v24_)
				break
			end
			local v28_ = v11_:getString(v25_ .. "#dialogText")
			if v28_ ~= nil then
				v28_ = g_i18n:convertText(v28_, v12_)
			end
			local v29_ = v11_:getString(v25_ .. "#dialogTitle")
			if v29_ ~= nil then
				v29_ = g_i18n:convertText(v29_, v12_)
			end
			local v30_ = v11_:getString(v25_ .. "#group")
			if v30_ == nil or self.groups[v30_] == nil then
				Logging.xmlError(v11_, "Collectible has no group at %d", v24_)
				break
			end
			self.groups[v30_].totalItems = self.groups[v30_].totalItems + 1
			self.collectibles[v26_] = {
				["targetName"] = v27_,
				["index"] = v24_,
				["dialogText"] = v28_,
				["dialogTitle"] = v29_,
				["moneyReward"] = v11_:getInt(v25_ .. "#moneyReward"),
				["groupName"] = v30_
			}
			self.collectibleIndexToName[v24_] = v26_
			self.collected[v24_] = false
			v23_ = v23_ + 1
		end
		self.achievementName = v11_:getString("collectibles#achievementName")
		self.incompleteNodeIndex = v11_:getString("collectibles.target.incompleteNode")
		self.completeNodeIndex = v11_:getString("collectibles.target.completeNode")
		local v31_ = v23_ / 4
		self.hotspotThreshold = v11_:getInt("collectibles#hotspotThreshold", (math.floor(v31_)))
		v11_:delete()
		self.isActive = true
		if g_addCheatCommands and g_currentMission:getIsServer() then
			addConsoleCommand("gsCollectiblesShowAll", "Shows all collectibles on the map", "consoleCommandShowAll", self)
		end
	end
end

-- Local values: xmlFile, _, key, index, collected, collectible, _, info
function CollectiblesSystem:loadFromXMLFile(xmlFilename)
	local v34_ = XMLFile.load("collectibles", xmlFilename)
	self.isComplete = v34_:getBool("collectibles#isComplete", false)
	if self.isComplete then
		for _, v35_ in pairs(self.collectibles) do
			self.collected[v35_.index] = true
			if v35_.groupName ~= nil then
				self.groups[v35_.groupName].collectedItems = self.groups[v35_.groupName].collectedItems + 1
			end
		end
	else
		for _, v36_ in v34_:iterator("collectibles.collectible") do
			local v37_ = v34_:getInt(v36_ .. "#index")
			local v38_ = v34_:getBool(v36_ .. "#collected", false)
			if v37_ ~= nil then
				self.collected[v37_] = v38_
				local v39_ = self.collectibles[self.collectibleIndexToName[v37_]]
				if v38_ and v39_.groupName ~= nil then
					self.groups[v39_.groupName].collectedItems = self.groups[v39_.groupName].collectedItems + 1
				end
			end
		end
	end
	v34_:delete()
	self:updateCollectiblesState()
	self:updateTargetState()
	self:updateHotspotState()
end

-- Local values: xmlFile
function CollectiblesSystem:saveToXMLFile(xmlFilename)
	if self.isActive then
		local v_u_42_ = XMLFile.create("collectibles", xmlFilename, "collectibles")
		v_u_42_:setBool("collectibles#isComplete", self.isComplete)
		if not self.isComplete then
			v_u_42_:setTable("collectibles.collectible", self.collectibles, function(p43_, p44_, _)
				-- upvalues: (copy) v_u_42_, (copy) self
				v_u_42_:setInt(p43_ .. "#index", p44_.index)
				v_u_42_:setBool(p43_ .. "#collected", self.collected[p44_.index] or false)
			end)
		end
		v_u_42_:save()
		v_u_42_:delete()
	end
end

function CollectiblesSystem:onClientJoined(connection)
	if next(self.collected) ~= nil then
		connection:sendEvent(CollectibleStateEvent.new(self.collected))
	end
end

-- Local values: info, group, numLeftInGroup
function CollectiblesSystem:onTriggerEvent(index, player)
	if not self.collected[index] then
		local v50_ = self.collectibles[self.collectibleIndexToName[index]]
		self.collected[index] = true
		self.groups[v50_.groupName].collectedItems = self.groups[v50_.groupName].collectedItems + 1
		if v50_.moneyReward ~= nil then
			g_currentMission:addMoney(v50_.moneyReward, player.farmId, MoneyType.COLLECTIBLE, true, true)
		end
		local v51_ = self.groups[v50_.groupName]
		if v51_.totalItems - v51_.collectedItems == 0 and v51_.moneyReward ~= nil then
			g_currentMission:addMoney(v51_.moneyReward, player.farmId, MoneyType.COLLECTIBLE, true, true)
		end
		if self:isCompleted() then
			self.isComplete = true
			if self.isServer and self.achievementName ~= nil then
				g_achievementManager:tryUnlock(self.achievementName, 1)
			end
		end
		g_server:broadcastEvent(CollectibleStateEvent.new(self.collected), true)
	end
end

-- Local values: _, group, i, groupName, group
function CollectiblesSystem:onStateEvent(state)
	self.collected = state
	for _, v54_ in pairs(self.groups) do
		v54_.collectedItems = 0
	end
	for v55_ = 1, #state do
		if state[v55_] then
			local v56_ = self.collectibles[self.collectibleIndexToName[v55_]].groupName
			local v57_ = self.groups[v56_]
			v57_.collectedItems = v57_.collectedItems + 1
		end
	end
	self:updateTargetState()
	self:updateCollectiblesState()
	self:updateHotspotState()
end

-- Local values: _, info, collected, _, info, collected
function CollectiblesSystem:updateTargetState()
	if self.target ~= nil then
		if self.incompleteNode ~= nil then
			setVisibility(self.incompleteNode, not self.isComplete)
		end
		if self.completeNode ~= nil then
			setVisibility(self.completeNode, self.isComplete)
		end
		for _, v59_ in pairs(self.collectibles) do
			if v59_.targetName ~= nil then
				local v60_ = self.collected[v59_.index] or false
				if v59_.target ~= nil then
					setVisibility(v59_.target, v60_)
					if v60_ then
						addToPhysics(v59_.target)
					else
						removeFromPhysics(v59_.target)
					end
				end
			end
		end
		for _, v61_ in pairs(self.groups) do
			if v61_.targetName ~= nil then
				local v62_ = v61_.totalItems == v61_.collectedItems
				if v61_.target ~= nil then
					setVisibility(v61_.target, v62_)
					if v62_ then
						addToPhysics(v61_.target)
					else
						removeFromPhysics(v61_.target)
					end
				end
			end
		end
	end
end

-- Local values: _, info, collected
function CollectiblesSystem:updateCollectiblesState()
	for _, v64_ in pairs(self.collectibles) do
		local v65_ = self.collected[v64_.index]
		if v64_.object ~= nil then
			if v65_ then
				v64_.object:deactivate()
			else
				v64_.object:activate()
			end
		end
	end
end

-- Local values: _, info
function CollectiblesSystem:isCompleted()
	for _, v67_ in pairs(self.collectibles) do
		if self.collected[v67_.index] ~= true then
			return false
		end
	end
	return true
end

-- Local values: visible, _, info
function CollectiblesSystem:updateHotspotState()
	if self.hotspotThreshold ~= nil then
		local v69_ = self:getTotalCollected() >= self.hotspotThreshold
		for _, v70_ in pairs(self.collectibles) do
			if v70_.object ~= nil then
				v70_.object:setHotspotVisible(v69_)
			end
		end
	end
end

-- Local values: info
function CollectiblesSystem:addCollectible(collectible)
	local v73_ = self.collectibles[collectible.name]
	if v73_ == nil then
		Logging.error("Collectible with name \'%s\' is unknown (%s).", collectible.name, I3DUtil.getNodePath(collectible.node))
	else
		v73_.object = collectible
		collectible:activate()
	end
end

-- Local values: data
function CollectiblesSystem:removeCollectible(collectible)
	local v76_ = self.collectibles[collectible.name]
	if v76_ == nil then
		Logging.error("Collectible with name \'%s\' is unknown.", collectible.name)
	else
		v76_.object = nil
	end
end

-- Local values: _, info, node, _, info, node
function CollectiblesSystem:addCollectibleTarget(target)
	self.target = target
	for _, v79_ in pairs(self.collectibles) do
		if v79_.targetName ~= nil then
			local v80_ = getChild(target.node, v79_.targetName)
			if v80_ ~= 0 then
				v79_.target = v80_
			end
		end
	end
	for _, v81_ in pairs(self.groups) do
		if v81_.targetName ~= nil then
			local v82_ = getChild(target.node, v81_.targetName)
			if v82_ ~= 0 then
				v81_.target = v82_
			end
		end
	end
	self.incompleteNode = I3DUtil.indexToObject(target, self.incompleteNodeIndex)
	self.completeNode = I3DUtil.indexToObject(target, self.completeNodeIndex)
	self:updateTargetState()
end

function CollectiblesSystem:removeCollectibleTarget(target)
	self.target = nil
	self.incompleteNode = nil
	self.completeNode = nil
end

-- Local values: info, player, group, numLeftInGroup, prefixText
function CollectiblesSystem:onTriggerCollectible(collectible)
	local v86_ = self.collectibles[collectible.name]
	if not self.collected[v86_.index] then
		local v87_ = g_localPlayer
		local v88_ = self.groups[v86_.groupName]
		local v89_ = v88_.totalItems - v88_.collectedItems - 1
		local v90_ = (v88_.collectedItems ~= 0 or v88_.dialogIntroText == nil) and "" or v88_.dialogIntroText .. "\n"
		if v86_.moneyReward == nil then
			g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.COLLECTIBLE)
		end
		if v89_ == 0 then
			g_currentMission.hud:showInGameMessage(v88_.dialogTitle or g_i18n:getText("ui_collectibleMessageTitle"), v90_ .. v88_.dialogText, -1)
		elseif v86_.dialogText ~= nil then
			g_currentMission.hud:showInGameMessage(string.format(v86_.dialogTitle or g_i18n:getText("ui_collectibleMessageTitle"), v89_), v90_ .. string.format(v86_.dialogText, v89_), -1)
		end
		g_client:getServerConnection():sendEvent(CollectibleTriggerEvent.new(v87_, v86_.index))
	end
end

function CollectiblesSystem:getIsActive()
	return self.isActive
end

-- Local values: n, i
function CollectiblesSystem:getTotalCollected()
	if not self.isActive then
		return nil
	end
	local v93_ = 0
	for v94_ = 1, #self.collectibleIndexToName do
		if self.collected[v94_] then
			v93_ = v93_ + 1
		end
	end
	return v93_
end

function CollectiblesSystem:getTotalCollectable()
	return self.isActive and #self.collectibleIndexToName or nil
end

function CollectiblesSystem:consoleCommandShowAll()
	self.hotspotThreshold = 0
	self:updateHotspotState()
end
