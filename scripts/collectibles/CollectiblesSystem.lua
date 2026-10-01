source("dataS/scripts/collectibles/Collectible.lua")
source("dataS/scripts/collectibles/CollectibleStateEvent.lua")
source("dataS/scripts/collectibles/CollectibleTarget.lua")
source("dataS/scripts/collectibles/CollectibleTriggerEvent.lua")
source("dataS/scripts/collectibles/CollectibleActivatable.lua")
CollectiblesSystem = {}
local CollectiblesSystem_mt = Class(CollectiblesSystem)
function CollectiblesSystem.new(isServer, customMt)
	local self = setmetatable({}, customMt or CollectiblesSystem_mt)
	self.isServer = isServer
	self.isActive = false
	self.isComplete = false
	self.collectibles = {}
	self.collected = {}
	self.collectibleIndexToName = {}
	self.groups = {}
	return self
end
function CollectiblesSystem:delete()
	removeConsoleCommand("gsCollectiblesShowAll")
end
function CollectiblesSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	local xmlFilename = getXMLString(xmlFile, "map.collectibles#filename")
	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, baseDirectory)
		local collectiblesFile = XMLFile.load("collectibles", xmlFilename)
		if collectiblesFile == nil then
			Logging.error("Collectibles file '%s' does not exist", xmlFilename)
			return
		end
		local modName, _ = Utils.getModNameAndBaseDirectory(xmlFilename)
		local totalGroups = 0
		for index, key in collectiblesFile:iterator("collectibles.group") do
			local name = collectiblesFile:getString(key .. "#name")
			local target = collectiblesFile:getString(key .. "#target")
			local dialogText = collectiblesFile:getString(key .. "#dialogText")
			if dialogText ~= nil then
				dialogText = g_i18n:convertText(dialogText, modName)
			end
			local dialogIntroText = collectiblesFile:getString(key .. "#dialogIntroText")
			if dialogIntroText ~= nil then
				dialogIntroText = g_i18n:convertText(dialogIntroText, modName)
			end
			local dialogTitle = collectiblesFile:getString(key .. "#dialogTitle")
			if dialogTitle ~= nil then
				dialogTitle = g_i18n:convertText(dialogTitle, modName)
			end
			local incompleteNodeIndex = collectiblesFile:getString("collectibles.target.incompleteNode")
			local completeNodeIndex = collectiblesFile:getString("collectibles.target.completeNode")
			self.groups[name] = { targetName = target, index = index, dialogText = dialogText, dialogIntroText = dialogIntroText, dialogTitle = dialogTitle, incompleteNodeIndex = incompleteNodeIndex, completeNodeIndex = completeNodeIndex, moneyReward = collectiblesFile:getInt(key .. "#moneyReward"), totalItems = 0, collectedItems = 0 }
			totalGroups = totalGroups + 1
		end
		local totalItems = 0
		for index, key in collectiblesFile:iterator("collectibles.collectible") do
			if totalItems == 255 then
				Logging.warning("No more than 255 collectibles are supported.")
				break
			end
			local name = collectiblesFile:getString(key .. "#name")
			local target = collectiblesFile:getString(key .. "#target")
			if name == nil then
				Logging.xmlError(collectiblesFile, "Collectible has no name at %d", index)
				break
			end
			local dialogText = collectiblesFile:getString(key .. "#dialogText")
			if dialogText ~= nil then
				dialogText = g_i18n:convertText(dialogText, modName)
			end
			local dialogTitle = collectiblesFile:getString(key .. "#dialogTitle")
			if dialogTitle ~= nil then
				dialogTitle = g_i18n:convertText(dialogTitle, modName)
			end
			local groupName = collectiblesFile:getString(key .. "#group")
			if groupName == nil then
				break
			end
			if self.groups[groupName] == nil then
				Logging.xmlError(collectiblesFile, "Collectible has no group at %d", index)
				break
			end
			self.groups[groupName].totalItems = self.groups[groupName].totalItems + 1
			self.collectibles[name] = { targetName = target, index = index, dialogText = dialogText, dialogTitle = dialogTitle, groupName = groupName, moneyReward = collectiblesFile:getInt(key .. "#moneyReward") }
			self.collectibleIndexToName[index] = name
			self.collected[index] = false
			totalItems = totalItems + 1
		end
		self.achievementName = collectiblesFile:getString("collectibles#achievementName")
		self.incompleteNodeIndex = collectiblesFile:getString("collectibles.target.incompleteNode")
		self.completeNodeIndex = collectiblesFile:getString("collectibles.target.completeNode")
		self.hotspotThreshold = collectiblesFile:getInt("collectibles#hotspotThreshold", math.floor(totalItems / 4))
		collectiblesFile:delete()
		self.isActive = true
		if g_addCheatCommands and g_currentMission:getIsServer() then
			addConsoleCommand("gsCollectiblesShowAll", "Shows all collectibles on the map", "consoleCommandShowAll", self)
		end
	end
end
function CollectiblesSystem:loadFromXMLFile(xmlFilename)
	local xmlFile = XMLFile.load("collectibles", xmlFilename)
	self.isComplete = xmlFile:getBool("collectibles#isComplete", false)
	if not self.isComplete then
		for _, key in xmlFile:iterator("collectibles.collectible") do
			local index = xmlFile:getInt(key .. "#index")
			local collected = xmlFile:getBool(key .. "#collected", false)
			if index == nil then
				continue
			end
			self.collected[index] = collected
			local collectible = self.collectibles[self.collectibleIndexToName[index]]
			if collected then
				if collectible.groupName == nil then
					continue
				end
				self.groups[collectible.groupName].collectedItems = self.groups[collectible.groupName].collectedItems + 1
			end
		end
	else
		for _, info in pairs(self.collectibles) do
			self.collected[info.index] = true
			if info.groupName == nil then
				continue
			end
			self.groups[info.groupName].collectedItems = self.groups[info.groupName].collectedItems + 1
		end
	end
	xmlFile:delete()
	self:updateCollectiblesState()
	self:updateTargetState()
	self:updateHotspotState()
end
function CollectiblesSystem:saveToXMLFile(xmlFilename)
	if not self.isActive then
		return
	else
		local xmlFile = XMLFile.create("collectibles", xmlFilename, "collectibles")
		xmlFile:setBool("collectibles#isComplete", self.isComplete)
		if not self.isComplete then
			xmlFile:setTable("collectibles.collectible", self.collectibles, function(key, info, _)
				xmlFile:setInt(key .. "#index", info.index)
				xmlFile:setBool(key .. "#collected", self.collected[info.index] or false)
			end)
		end
		xmlFile:save()
		xmlFile:delete()
	end
end
function CollectiblesSystem:onClientJoined(connection)
	if next(self.collected) ~= nil then
		connection:sendEvent(CollectibleStateEvent.new(self.collected))
	end
end
function CollectiblesSystem:onTriggerEvent(index, player)
	if self.collected[index] then
		return
	else
		local info = self.collectibles[self.collectibleIndexToName[index]]
		self.collected[index] = true
		self.groups[info.groupName].collectedItems = self.groups[info.groupName].collectedItems + 1
		if info.moneyReward ~= nil then
			g_currentMission:addMoney(info.moneyReward, player.farmId, MoneyType.COLLECTIBLE, true, true)
		end
		local group = self.groups[info.groupName]
		local numLeftInGroup = group.totalItems - group.collectedItems
		if numLeftInGroup == 0 and group.moneyReward ~= nil then
			g_currentMission:addMoney(group.moneyReward, player.farmId, MoneyType.COLLECTIBLE, true, true)
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
function CollectiblesSystem:onStateEvent(state)
	self.collected = state
	for _, group in pairs(self.groups) do
		group.collectedItems = 0
	end
	for i = 1, #state do
		if state[i] then
			local groupName = self.collectibles[self.collectibleIndexToName[i]].groupName
			local group = self.groups[groupName]
			group.collectedItems = group.collectedItems + 1
		end
	end
	self:updateTargetState()
	self:updateCollectiblesState()
	self:updateHotspotState()
end
function CollectiblesSystem:updateTargetState()
	if self.target ~= nil then
		if self.incompleteNode ~= nil then
			setVisibility(self.incompleteNode, not self.isComplete)
		end
		if self.completeNode ~= nil then
			setVisibility(self.completeNode, self.isComplete)
		end
		for _, info in pairs(self.collectibles) do
			if info.targetName == nil then
				continue
			end
			local collected = self.collected[info.index] or false
			if info.target == nil then
				continue
			end
			setVisibility(info.target, collected)
			if collected then
				addToPhysics(info.target)
			else
				removeFromPhysics(info.target)
			end
		end
		for _, info in pairs(self.groups) do
			if info.targetName == nil then
				continue
			end
			local collected = info.totalItems == info.collectedItems
			if info.target == nil then
				continue
			end
			setVisibility(info.target, collected)
			if collected then
				addToPhysics(info.target)
			else
				removeFromPhysics(info.target)
			end
		end
	end
end
function CollectiblesSystem:updateCollectiblesState()
	for _, info in pairs(self.collectibles) do
		local collected = self.collected[info.index]
		if info.object == nil then
			continue
		end
		if collected then
			info.object:deactivate()
		else
			info.object:activate()
		end
	end
end
function CollectiblesSystem:isCompleted()
	for _, info in pairs(self.collectibles) do
		if self.collected[info.index] == true then
			continue
		end
		return false
	end
	return true
end
function CollectiblesSystem:updateHotspotState()
	if self.hotspotThreshold ~= nil then
		local visible = self.hotspotThreshold <= self:getTotalCollected()
		for _, info in pairs(self.collectibles) do
			if info.object == nil then
				continue
			end
			info.object:setHotspotVisible(visible)
		end
	end
end
function CollectiblesSystem:addCollectible(collectible)
	local info = self.collectibles[collectible.name]
	if info == nil then
		Logging.error("Collectible with name '%s' is unknown (%s).", collectible.name, I3DUtil.getNodePath(collectible.node))
	else
		info.object = collectible
		collectible:activate()
	end
end
function CollectiblesSystem:removeCollectible(collectible)
	local data = self.collectibles[collectible.name]
	if data == nil then
		Logging.error("Collectible with name '%s' is unknown.", collectible.name)
	else
		data.object = nil
	end
end
function CollectiblesSystem:addCollectibleTarget(target)
	self.target = target
	for _, info in pairs(self.collectibles) do
		if info.targetName == nil then
			continue
		end
		local node = getChild(target.node, info.targetName)
		if node == 0 then
			continue
		end
		info.target = node
	end
	for _, info in pairs(self.groups) do
		if info.targetName == nil then
			continue
		end
		local node = getChild(target.node, info.targetName)
		if node == 0 then
			continue
		end
		info.target = node
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
function CollectiblesSystem:onTriggerCollectible(collectible)
	local info = self.collectibles[collectible.name]
	if self.collected[info.index] then
		return
	else
		local player = g_localPlayer
		local group = self.groups[info.groupName]
		local numLeftInGroup = group.totalItems - group.collectedItems - 1
		local prefixText = ""
		if group.collectedItems == 0 and group.dialogIntroText ~= nil then
			prefixText = group.dialogIntroText .. "\n"
		end
		if info.moneyReward == nil then
			g_gui.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.COLLECTIBLE)
		end
		if numLeftInGroup == 0 then
			g_currentMission.hud:showInGameMessage(group.dialogTitle or g_i18n:getText("ui_collectibleMessageTitle"), prefixText .. group.dialogText, -1)
		elseif info.dialogText ~= nil then
			g_currentMission.hud:showInGameMessage(string.format(info.dialogTitle or g_i18n:getText("ui_collectibleMessageTitle"), numLeftInGroup), prefixText .. string.format(info.dialogText, numLeftInGroup), -1)
		end
		g_client:getServerConnection():sendEvent(CollectibleTriggerEvent.new(player, info.index))
	end
end
function CollectiblesSystem:getIsActive()
	return self.isActive
end
function CollectiblesSystem:getTotalCollected()
	if self.isActive then
		local n = 0
		for i = 1, #self.collectibleIndexToName do
			if self.collected[i] then
				n = n + 1
			end
		end
		return n
	else
		return nil
	end
end
function CollectiblesSystem:getTotalCollectable()
	if self.isActive then
		return #self.collectibleIndexToName
	else
		return nil
	end
end
function CollectiblesSystem:consoleCommandShowAll()
	self.hotspotThreshold = 0
	self:updateHotspotState()
end
