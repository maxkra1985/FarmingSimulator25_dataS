DeadwoodMission = {}
source("dataS/scripts/missions/forestry/DeadwoodMissionHotspot.lua")
source("dataS/scripts/missions/forestry/DeadwoodMissionTreeEvent.lua")
source("dataS/scripts/missions/forestry/DeadwoodMissionWrongTreeEvent.lua")
DeadwoodMission.NAME = "deadwoodMission"
local DeadwoodMission_mt = Class(DeadwoodMission, AbstractMission)
InitStaticObjectClass(DeadwoodMission, "DeadwoodMission")
function DeadwoodMission.registerXMLPaths(schema, key)
	DeadwoodMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#maxNumInstances", "Max number of instances")
	schema:register(XMLValueType.INT, key .. "#rewardPerTree", "Reward per tree")
	schema:register(XMLValueType.INT, key .. "#penaltyPerTree", "Penalty per tree")
	schema:register(XMLValueType.STRING, key .. "#treeType", "Tree type")
	schema:register(XMLValueType.STRING, key .. ".spots#filename", "Filename to tree spots")
end
function DeadwoodMission.registerSavegameXMLPaths(schema, key)
	DeadwoodMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#spotIndex", "Spot index")
	schema:register(XMLValueType.INT, key .. ".originalTree(?)#splitShapePart1", "Part1 of the original tree")
	schema:register(XMLValueType.INT, key .. ".originalTree(?)#splitShapePart2", "Part2 of the original tree")
	schema:register(XMLValueType.INT, key .. ".originalTree(?)#splitShapePart3", "Part3 of the original tree")
	schema:register(XMLValueType.INT, key .. ".deadTree(?)#splitShapePart1", "Part1 of the dead tree")
	schema:register(XMLValueType.INT, key .. ".deadTree(?)#splitShapePart2", "Part2 of the dead tree")
	schema:register(XMLValueType.INT, key .. ".deadTree(?)#splitShapePart3", "Part3 of the dead tree")
	schema:register(XMLValueType.BOOL, key .. ".deadTree(?)#cutDown", "If the tree was cut down")
	schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart1", "Part1 of the cut split shape")
	schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart2", "Part2 of the cut split shape")
	schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart3", "Part3 of the cut split shape")
end
function DeadwoodMission.registerMetaXMLPaths(schema, key)
	DeadwoodMission:superClass().registerMetaXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#nextDay", "Earliest day a new mission can spawn")
end
function DeadwoodMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_forestry_deadwood_title")
	local description = g_i18n:getText("contract_forestry_deadwood_description")
	local self = AbstractMission.new(isServer, isClient, title, description, customMt or DeadwoodMission_mt)
	self.spot = nil
	self.deadTrees = {}
	self.deadTreeShapeToTree = {}
	self.deadTreeCutSplitShapes = {}
	self.pendingOriginalTrees = {}
	self.originalTrees = {}
	self.numDeadTrees = 0
	self.numCutDownTrees = 0
	self.wronglyCutDownTreesReward = 0
	self.resolveOriginalTreeServerIds = false
	self.resolveDeadTreeServerIds = false
	self.isHotspotAdded = false
	self.mapHotspot = nil
	g_messageCenter:subscribe(MessageType.SPLIT_SHAPE, self.onTreeShapeCut, self)
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	table.addElement(data.activeMissions, self)
	return self
end
function DeadwoodMission:init(spot, trees, preplacedDeadwood)
	local res = DeadwoodMission:superClass().init(self)
	if spot == nil then
		return false
	end
	self:setSpot(spot)
	local numTrees = #trees
	local numPreplaced = #preplacedDeadwood
	local totalNumTrees = numTrees + numPreplaced
	if totalNumTrees == 0 then
		return false
	end
	local numDeadTrees = numPreplaced
	if numDeadTrees < 10 then
		local minTrees = math.min(5, numTrees)
		local maxTrees = math.min(10, numTrees)
		numDeadTrees = numDeadTrees + math.random(minTrees, maxTrees)
	end
	self.numDeadTrees = numDeadTrees
	if numDeadTrees == 0 then
		return false
	else
		local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
		local rewardPerTree = data.rewardPerTree
		self.reward = self.numDeadTrees * rewardPerTree
		Utils.shuffle(trees)
		for _, treeNode in ipairs(preplacedDeadwood) do
			table.insert(self.originalTrees, treeNode)
		end
		for _, treeNode in ipairs(trees) do
			if #self.originalTrees == self.numDeadTrees then
				break
			end
			table.insert(self.originalTrees, treeNode)
		end
		return res
	end
end
function DeadwoodMission:setSpot(spot)
	self.spot = spot
	spot.isInUse = true
	self.farmlandId = spot.farmlandId
	if self.mapHotspot == nil then
		self.mapHotspot = DeadwoodMissionHotspot.new()
	end
	local x = self.spot.x
	local z = self.spot.z
	local radius = self.spot.radius
	self.mapHotspot:setWorldPosition(x, z)
	self.mapHotspot:setWorldRadius(radius)
	self.mapHotspots = { self.mapHotspot }
end
function DeadwoodMission:delete()
	DeadwoodMission:superClass().delete(self)
	self:removeHotspot()
	self:destroyTrees()
	g_messageCenter:unsubscribeAll(self)
	if self.spot ~= nil then
		self.spot.isInUse = false
		self.spot = nil
	end
	if self.mapHotspot ~= nil then
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
	self.mapHotspots = nil
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if data ~= nil then
		table.removeElement(data.activeMissions, self)
	end
end
function DeadwoodMission:saveToXMLFile(xmlFile, key)
	DeadwoodMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#spotIndex", self.spot.index)
	local i = 0
	for _, treeNode in ipairs(self.originalTrees) do
		local treeKey = string.format("%s.originalTree(%d)", key, i)
		if entityExists(treeNode) then
			local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(treeNode)
			if splitShapePart1 ~= 0 and splitShapePart1 ~= nil then
				xmlFile:setValue(treeKey .. "#splitShapePart1", splitShapePart1)
				xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
				xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
			end
		end
		i = i + 1
	end
	i = 0
	for _, deadTree in pairs(self.deadTrees) do
		local deadTreeKey = string.format("%s.deadTree(%d)", key, i)
		xmlFile:setBool(deadTreeKey .. "#cutDown", deadTree.cutDown)
		if deadTree.splitShapeId ~= nil and entityExists(deadTree.splitShapeId) then
			local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(deadTree.splitShapeId)
			if splitShapePart1 ~= 0 and splitShapePart1 ~= nil then
				xmlFile:setValue(deadTreeKey .. "#splitShapePart1", splitShapePart1)
				xmlFile:setValue(deadTreeKey .. "#splitShapePart2", splitShapePart2)
				xmlFile:setValue(deadTreeKey .. "#splitShapePart3", splitShapePart3)
			end
		end
		i = i + 1
	end
	i = 0
	for shape, _ in pairs(self.deadTreeCutSplitShapes) do
		local cutSplitShapeKey = string.format("%s.cutSplitShape(%d)", key, i)
		if entityExists(shape) then
			local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(shape)
			if splitShapePart1 == 0 or splitShapePart1 == nil then
				continue
			end
			xmlFile:setValue(cutSplitShapeKey .. "#splitShapePart1", splitShapePart1)
			xmlFile:setValue(cutSplitShapeKey .. "#splitShapePart2", splitShapePart2)
			xmlFile:setValue(cutSplitShapeKey .. "#splitShapePart3", splitShapePart3)
			i = i + 1
		end
	end
end
function DeadwoodMission:loadFromXMLFile(xmlFile, key)
	DeadwoodMission:superClass().loadFromXMLFile(self, xmlFile, key)
	local spotIndex = xmlFile:getValue(key .. "#spotIndex") or 0
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	local spot = data.spots[spotIndex]
	if spot == nil then
		return false
	else
		self:setSpot(spot)
		self.pendingSavegameData = { originalTrees = {}, deadTrees = {}, deadTreeCutSplitShapes = {} }
		for _, treeKey in xmlFile:iterator(key .. ".originalTree") do
			local splitShapePart1 = xmlFile:getValue(treeKey .. "#splitShapePart1")
			local splitShapePart2 = xmlFile:getValue(treeKey .. "#splitShapePart2")
			local splitShapePart3 = xmlFile:getValue(treeKey .. "#splitShapePart3")
			table.insert(self.pendingSavegameData.originalTrees, { splitShapePart1 = splitShapePart1, splitShapePart2 = splitShapePart2, splitShapePart3 = splitShapePart3 })
		end
		for _, deadTreeKey in xmlFile:iterator(key .. ".deadTree") do
			local cutDown = xmlFile:getBool(deadTreeKey .. "#cutDown")
			local splitShapePart1 = xmlFile:getValue(deadTreeKey .. "#splitShapePart1")
			local splitShapePart2 = xmlFile:getValue(deadTreeKey .. "#splitShapePart2")
			local splitShapePart3 = xmlFile:getValue(deadTreeKey .. "#splitShapePart3")
			table.insert(self.pendingSavegameData.deadTrees, { splitShapePart1 = splitShapePart1, splitShapePart2 = splitShapePart2, splitShapePart3 = splitShapePart3, cutDown = cutDown })
		end
		for _, cutSplitShapeKey in xmlFile:iterator(key .. ".cutSplitShape") do
			local splitShapePart1 = xmlFile:getValue(cutSplitShapeKey .. "#splitShapePart1")
			local splitShapePart2 = xmlFile:getValue(cutSplitShapeKey .. "#splitShapePart2")
			local splitShapePart3 = xmlFile:getValue(cutSplitShapeKey .. "#splitShapePart3")
			table.insert(self.pendingSavegameData.deadTreeCutSplitShapes, { splitShapePart1 = splitShapePart1, splitShapePart2 = splitShapePart2, splitShapePart3 = splitShapePart3 })
		end
		return true
	end
end
function DeadwoodMission:writeStream(streamId, connection)
	DeadwoodMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.spot.index)
	streamWriteUInt8(streamId, self.numCutDownTrees)
	streamWriteUInt8(streamId, self.numDeadTrees)
	streamWriteUInt8(streamId, #self.originalTrees)
	for _, treeNode in ipairs(self.originalTrees) do
		writeSplitShapeIdToStream(streamId, treeNode)
	end
	self:writeDeadTreesStream(streamId)
end
function DeadwoodMission:readStream(streamId, connection)
	DeadwoodMission:superClass().readStream(self, streamId, connection)
	local spotIndex = streamReadUInt8(streamId)
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	local spot = data.spots[spotIndex]
	self:setSpot(spot)
	self.numCutDownTrees = streamReadUInt8(streamId)
	self.numDeadTrees = streamReadUInt8(streamId)
	local numOriginalTrees = streamReadUInt8(streamId)
	for i = 1, numOriginalTrees do
		local entityId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
		if entityId ~= 0 then
			table.insert(self.originalTrees, entityId)
		else
			if splitShapeId1 == 0 then
				continue
			end
			table.insert(self.pendingOriginalTrees, { splitShapeId1, splitShapeId2 })
		end
	end
	self.resolveOriginalTreeServerIds = true
	self:readDeadTreesStream(streamId)
end
function DeadwoodMission:readUpdateStream(streamId, timestamp, connection)
	DeadwoodMission:superClass().readUpdateStream(self, streamId, timestamp, connection)
	self.numCutDownTrees = streamReadUInt8(streamId)
end
function DeadwoodMission:writeUpdateStream(streamId, connection, dirtyMask)
	DeadwoodMission:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	streamWriteUInt8(streamId, self.numCutDownTrees)
end
function DeadwoodMission:readDeadTreesStream(streamId)
	local numDeadTrees = streamReadUInt8(streamId)
	for i = 1, numDeadTrees do
		local tree = { cutDown = false, splitShapeId = nil }
		if not streamReadBool(streamId) then
			local entityId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
			if entityId ~= 0 then
				tree.splitShapeId = entityId
			elseif splitShapeId1 ~= 0 then
				tree.serverSplitShapePart1 = splitShapeId1
				tree.serverSplitShapePart2 = splitShapeId2
			end
		end
		table.insert(self.deadTrees, tree)
	end
	self.resolveDeadTreeServerIds = true
end
function DeadwoodMission:writeDeadTreesStream(streamId)
	streamWriteUInt8(streamId, #self.deadTrees)
	for _, tree in ipairs(self.deadTrees) do
		if streamWriteBool(streamId, tree.cutDown) then
			continue
		end
		writeSplitShapeIdToStream(streamId, tree.splitShapeId)
	end
end
function DeadwoodMission:update(dt)
	if self.isServer then
		if self.pendingSavegameData ~= nil then
			for _, data in ipairs(self.pendingSavegameData.originalTrees) do
				if data.splitShapePart1 == nil then
					continue
				end
				local splitShapeId = getShapeFromSaveableSplitShapeId(data.splitShapePart1, data.splitShapePart2, data.splitShapePart3)
				if splitShapeId == 0 or splitShapeId == nil then
					continue
				end
				table.insert(self.originalTrees, splitShapeId)
			end
			self.numDeadTrees = #self.originalTrees
			self.numCutDownTrees = 0
			for _, data in ipairs(self.pendingSavegameData.deadTrees) do
				local splitShapeId = nil
				local rootNode = nil
				local x = nil
				local _ = nil
				local z = nil
				local rotY = nil
				if data.splitShapePart1 ~= nil then
					splitShapeId = getShapeFromSaveableSplitShapeId(data.splitShapePart1, data.splitShapePart2, data.splitShapePart3)
					if splitShapeId ~= 0 then
						if splitShapeId ~= nil then
							x, _, z = getWorldTranslation(splitShapeId)
							_, rotY, _ = getWorldRotation(splitShapeId)
							rootNode = getParent(splitShapeId)
						else
							splitShapeId = nil
						end
					end
				end
				if data.cutDown then
					self.numCutDownTrees = self.numCutDownTrees + 1
				end
				local deadTree = { x = x, z = z, rotY = rotY, splitShapeId = splitShapeId, rootNode = rootNode }
				deadTree.cutDown = data.cutDown
				if splitShapeId ~= nil then
					self.deadTreeShapeToTree[splitShapeId] = deadTree
				end
				table.insert(self.deadTrees, deadTree)
			end
			for _, data in ipairs(self.pendingSavegameData.deadTreeCutSplitShapes) do
				if data.splitShapePart1 == nil then
					continue
				end
				local cutSplitShapeId = getShapeFromSaveableSplitShapeId(data.splitShapePart1, data.splitShapePart2, data.splitShapePart3)
				if cutSplitShapeId == 0 or cutSplitShapeId == nil then
					continue
				end
				self.deadTreeCutSplitShapes[cutSplitShapeId] = true
			end
			if self.status ~= MissionStatus.CREATED then
				for _, treeNode in ipairs(self.originalTrees) do
					self:setTreeVisibility(treeNode, false)
				end
			end
			if self.status == MissionStatus.RUNNING then
				self:addTreeMarker()
			end
			self.pendingSavegameData = nil
		end
	else
		if self.resolveDeadTreeServerIds then
			local resolvedAll = true
			for _, tree in ipairs(self.deadTrees) do
				if tree.serverSplitShapePart1 == nil or tree.serverSplitShapePart2 == nil then
					continue
				end
				local entityId = resolveStreamSplitShapeId(tree.serverSplitShapePart1, tree.serverSplitShapePart2)
				if entityId ~= 0 then
					tree.splitShapeId = entityId
					tree.serverSplitShapePart1 = nil
					tree.serverSplitShapePart2 = nil
				else
					resolvedAll = false
				end
			end
			if resolvedAll then
				self.resolveDeadTreeServerIds = false
				if self.status == MissionStatus.RUNNING then
					self:addTreeMarker()
				end
			end
		end
		if self.resolveOriginalTreeServerIds then
			for i = #self.pendingOriginalTrees, 1, -1 do
				local originalTree = self.pendingOriginalTrees[i]
				local entityId = resolveStreamSplitShapeId(originalTree[1], originalTree[2])
				if entityId == 0 then
					continue
				end
				table.remove(self.pendingOriginalTrees, i)
				table.insert(self.originalTrees, entityId)
			end
			if #self.pendingOriginalTrees == 0 then
				self.resolveOriginalTreeServerIds = false
				if self.status == MissionStatus.RUNNING or self.status == MissionStatus.FINISHED then
					for _, treeNode in ipairs(self.originalTrees) do
						self:setTreeVisibility(treeNode, false)
					end
				end
			end
		end
	end
	if self.isServer and (self.numDeadTrees == 0 and self.status == MissionStatus.RUNNING) then
		Logging.warning("Finish deadwood mission because no trees are available")
		self:finish(MissionFinishState.FAILED)
	end
	DeadwoodMission:superClass().update(self, dt)
	if self.status == MissionStatus.RUNNING and (g_localPlayer ~= nil and (g_localPlayer.farmId == self.farmId and not self.isHotspotAdded)) then
		self:addHotspots()
	end
end
function DeadwoodMission:setTreeVisibility(treeNode, isVisible)
	if not entityExists(treeNode) then
		return
	end
	local treeRoot = getParent(treeNode)
	setVisibility(treeRoot, isVisible)
	if isVisible then
		addToPhysics(treeRoot)
	else
		removeFromPhysics(treeRoot)
	end
end
function DeadwoodMission:getLocation()
	return string.format(g_i18n:getText("contract_farmland"), self.farmlandId)
end
function DeadwoodMission:getMapHotspots()
	return self.mapHotspots
end
function DeadwoodMission:getWorldPosition()
	local spot = self.spot
	if spot ~= nil then
		return spot.x, spot.z
	else
		local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
		return farmland:getIndicatorPosition()
	end
end
function DeadwoodMission:addMissionTree(treeNode)
	local treeRoot = getParent(treeNode)
	local x, y, z = getWorldTranslation(treeRoot)
	local rx, ry, rz = getWorldRotation(treeRoot)
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	local treeIndex = data.treeIndex
	local missionTreeNode = g_treePlantManager:plantTree(treeIndex, x, y, z, rx, ry, rz, 1, 1, false)
	local splitShapeId = SplitShapeUtil.getSplitShapeId(missionTreeNode)
	if splitShapeId ~= nil then
		local deadTree = { rootNode = missionTreeNode, splitShapeId = splitShapeId, x = x, z = z, rotY = ry, cutDown = false }
		table.insert(self.deadTrees, deadTree)
		self.deadTreeShapeToTree[splitShapeId] = deadTree
	end
end
function DeadwoodMission:prepare(spawnVehicles)
	DeadwoodMission:superClass().prepare(self, spawnVehicles)
	for _, treeNode in ipairs(self.originalTrees) do
		self:setTreeVisibility(treeNode, false)
		self:addMissionTree(treeNode)
	end
	self:addTreeMarker()
	g_server:broadcastEvent(DeadwoodMissionTreeEvent.new(self))
end
function DeadwoodMission:started()
	DeadwoodMission:superClass().started(self)
	for _, treeNode in ipairs(self.originalTrees) do
		self:setTreeVisibility(treeNode, false)
	end
	self:addTreeMarker()
end
function DeadwoodMission:destroyTrees()
	for _, tree in ipairs(self.deadTrees) do
		if tree.rootNode == nil then
			continue
		end
		if entityExists(tree.rootNode) then
			for i = getNumOfChildren(tree.rootNode), 1, -1 do
				delete(getChildAt(tree.rootNode, i - 1))
			end
		end
	end
	self.deadTrees = {}
	self.deadTreeShapeToTree = {}
	for splitShapeId, _ in pairs(self.deadTreeCutSplitShapes) do
		if entityExists(splitShapeId) then
			delete(splitShapeId)
			self.deadTreeCutSplitShapes[splitShapeId] = nil
		end
	end
	for _, treeNode in ipairs(self.originalTrees) do
		self:setTreeVisibility(treeNode, true)
	end
end
function DeadwoodMission:addTreeMarker()
	local treeMarkerSystem = g_currentMission.treeMarkerSystem
	if treeMarkerSystem == nil then
		return
	end
	local treeMarkerType = treeMarkerSystem:getTreeMarkerTypeByName("EXCLAMATION")
	if treeMarkerType == nil then
		return
	else
		for _, tree in pairs(self.deadTrees) do
			if tree.splitShapeId == nil then
				continue
			end
			treeMarkerSystem:addTreeMarkerByWorldDirection(tree.splitShapeId, treeMarkerType.index, 0.7084, 0.0212, 0.0006, 1, 0, 1, 2, 0.7, true)
		end
	end
end
function DeadwoodMission:finish(finishState)
	self:removeHotspot()
	local mission = g_currentMission
	if mission:getFarmId() == self.farmId then
		if finishState == MissionFinishState.SUCCESS then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_forestry_deadwood_completed"), self.farmlandId))
		elseif finishState == MissionFinishState.FAILED then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_deadwood_failed"), self.farmlandId))
		elseif finishState == MissionFinishState.TIMED_OUT then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_deadwood_timedOut"), self.farmlandId))
		end
	end
	DeadwoodMission:superClass().finish(self, finishState)
end
function DeadwoodMission:getIsMissionSplitShape(shape)
	if shape == nil or shape == 0 then
		return false
	end
	if self.status ~= MissionStatus.RUNNING then
		return false
	elseif self.deadTreeCutSplitShapes[shape] ~= nil then
		return true
	elseif self.deadTreeShapeToTree[shape] ~= nil then
		return true
	else
		return false
	end
end
function DeadwoodMission:addHotspots()
	if self.mapHotspot ~= nil then
		self.isHotspotAdded = true
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
end
function DeadwoodMission:removeHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
end
function DeadwoodMission:validate()
	local res = DeadwoodMission:superClass().validate(self)
	if not res then
		return false
	else
		local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
		if farmland == nil or farmland.isOwned then
			return false
		end
		return res
	end
end
function DeadwoodMission:dismiss()
	if self.isServer then
		local change = 0
		if self.finishState == MissionFinishState.SUCCESS then
			change = self:getReward()
		end
		change = change - self.wronglyCutDownTreesReward
		if change ~= 0 then
			g_currentMission:addMoney(change, self.farmId, MoneyType.MISSIONS, true, true)
		end
	end
end
function DeadwoodMission:getNPC()
	local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
	local npc = g_npcManager:getNPCByIndex(farmland.npcIndex)
	return npc
end
function DeadwoodMission:getExtraProgressText()
	local remaining = self.numDeadTrees - self.numCutDownTrees
	if remaining == 1 then
		return g_i18n:getText("contract_forestry_deadwood_oneRemainingTree")
	else
		return string.format(g_i18n:getText("contract_forestry_deadwood_remainingTrees"), remaining)
	end
end
function DeadwoodMission:getDetails()
	local details = DeadwoodMission:superClass().getDetails(self)
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	table.insert(details, { title = g_i18n:getText("contract_details_farmland"), value = self.farmlandId })
	table.insert(details, { title = g_i18n:getText("contract_forestry_details_rewardPerTree"), value = g_i18n:formatMoney(data.rewardPerTree, 0, true) })
	table.insert(details, { title = g_i18n:getText("contract_forestry_details_penaltyPerTree"), value = g_i18n:formatMoney(data.penaltyPerTree, 0, true) })
	table.insert(details, { title = g_i18n:getText("contract_forestry_details_totalNumTrees"), value = self.numDeadTrees })
	if self.status ~= MissionStatus.CREATED then
		table.insert(details, { title = g_i18n:getText("contract_forestry_deadwood_details_cutNumTrees"), value = self.numCutDownTrees })
	end
	return details
end
function DeadwoodMission:getCompletion()
	if self.numDeadTrees == 0 then
		return 0
	else
		return self.numCutDownTrees / self.numDeadTrees
	end
end
function DeadwoodMission:getReward()
	return self.reward
end
function DeadwoodMission:getFarmlandId()
	return self.farmlandId
end
function DeadwoodMission:calculateStealingCost()
	return self.wronglyCutDownTreesReward
end
function DeadwoodMission:onTreeShapeCut(shapeData, splitShapeData)
	if self.status ~= MissionStatus.RUNNING then
		return
	else
		if self.isServer then
			local missionTree = self.deadTreeShapeToTree[shapeData.shape]
			if missionTree ~= nil then
				missionTree.cutDown = true
				self.numCutDownTrees = self.numCutDownTrees + 1
				for _, data in ipairs(splitShapeData) do
					self.deadTreeCutSplitShapes[data.shape] = true
				end
				return
			end
			if self.deadTreeCutSplitShapes[shapeData.shape] ~= nil then
				for _, data in ipairs(splitShapeData) do
					self.deadTreeCutSplitShapes[data.shape] = true
				end
				return
			end
			if shapeData.alreadySplit then
				return
			end
			local mission = g_missionManager:getMissionBySplitShape(shapeData.shape)
			if mission ~= nil then
				return
			end
			local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(shapeData.x, shapeData.z)
			if self.farmlandId == farmlandId then
				local volume = shapeData.volume
				local splitType = g_splitShapeManager:getSplitTypeByIndex(shapeData.splitTypeIndex)
				local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
				local costs = math.max(data.penaltyPerTree, volume * 1000 * splitType.pricePerLiter)
				self.wronglyCutDownTreesReward = self.wronglyCutDownTreesReward + costs
				g_currentMission:broadcastEventToFarm(DeadwoodMissionWrongTreeEvent.new(), self.farmId, true)
			end
		end
	end
end
function DeadwoodMission:getIsShapeCutAllowed(shape, x, z, farmId)
	if self.farmId == farmId then
		local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
		if self.farmlandId == farmlandId then
			if self.status == MissionStatus.FINISHED then
				return getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) and getIsSplitShapeSplit(shape)
			end
			if self.status == MissionStatus.RUNNING then
				return true
			end
		end
	end
	return nil
end
function DeadwoodMission:getMissionTypeName()
	return DeadwoodMission.NAME
end
function DeadwoodMission.loadMapData(xmlFile, key, baseDirectory)
	if not xmlFile:hasProperty(key) then
		return
	end
	local treeTypeName = xmlFile:getString(key .. "#treeType")
	local treeDesc = g_treePlantManager:getTreeTypeDescFromName(treeTypeName)
	if treeDesc == nil then
		Logging.xmlWarning(xmlFile, "Missing or undefined treeType '%s' for deadwood mission (%s)!", treeTypeName, key)
		return false
	end
	local spotFilename = xmlFile:getString(key .. ".spots#filename")
	if spotFilename == nil then
		Logging.xmlWarning(xmlFile, "Missing spot definition file for deadwood mission (%s)", key)
		return false
	end
	spotFilename = Utils.getFilename(spotFilename, baseDirectory)
	local i3dNode = g_i3DManager:loadI3DFile(spotFilename, false, false)
	if i3dNode == 0 then
		return false
	else
		local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
		data.spots = {}
		data.spotsDisabled = {}
		data.activeMissions = {}
		data.maxNumInstances = xmlFile:getInt(key .. "#maxNumInstances") or 1
		data.treeIndex = treeDesc.index
		data.rewardPerTree = xmlFile:getFloat(key .. "#rewardPerTree") or 150
		data.penaltyPerTree = xmlFile:getFloat(key .. "#penaltyPerTree") or 2000
		data.deadwoodSplitTypeIndex = g_splitShapeManager:getSplitTypeIndexByName("DEADWOOD")
		local root = getChildAt(i3dNode, 0)
		link(getRootNode(), root)
		for i = 0, getNumOfChildren(root) - 1 do
			local spotNode = getChildAt(root, i)
			local x, y, z = getTranslation(spotNode)
			local radius = tonumber(getUserAttribute(spotNode, "radius"))
			if radius ~= nil then
				local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
				local isValidFarmland = farmlandId ~= nil and farmlandId ~= FarmlandManager.NOT_BUYABLE_FARM_ID
				if isValidFarmland then
					y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
					local spot = { x = x, y = y, z = z, radius = radius, farmlandId = farmlandId }
					spot.index = #data.spots + 1
					spot.isInUse = false
					table.insert(data.spots, spot)
				else
					local farmland = "Not defined"
					if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
						farmland = string.format("Not buyable (%d)", farmlandId)
					end
					Logging.xmlWarning(xmlFile, "Invalid farmland '%s' found for deadwood mission spot '%s' at %d %d!", farmland, getName(spotNode), x, z)
				end
			else
				Logging.xmlWarning(xmlFile, "No radius defined for deadwood mission spot '%s'!", getName(spotNode))
			end
		end
		data.spotRoot = root
		delete(i3dNode)
		return true
	end
end
function DeadwoodMission.unloadMapData()
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if data.spotRoot ~= nil then
		delete(data.spotRoot)
	end
end
function DeadwoodMission.loadMetaDataFromXMLFile(xmlFile, key)
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	data.nextMissionDay = xmlFile:getValue(key .. "#nextDay")
end
function DeadwoodMission.saveMetaDataToXMLFile(xmlFile, key)
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if data.nextMissionDay ~= nil then
		xmlFile:setValue(key .. "#nextDay", data.nextMissionDay)
	end
end
function DeadwoodMission.onFinishCallback()
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	data.treeCheck.isRunning = false
end
function DeadwoodMission.onTreeCallback(_, transformId, subShapeIndex, isLast)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) then
		local splitType = getSplitType(transformId)
		if splitType ~= 0 and not getIsSplitShapeSplit(transformId) then
			local x, _, z = getWorldTranslation(transformId)
			local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
			local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
			local treeCheck = data.treeCheck
			if farmlandId == treeCheck.farmlandId then
				if splitType == data.deadwoodSplitTypeIndex then
					table.insert(treeCheck.preplacedDeadwood, transformId)
				else
					table.insert(treeCheck.trees, transformId)
				end
			end
		end
	end
	if isLast then
		DeadwoodMission.onFinishCallback()
	end
	return true
end
function DeadwoodMission.tryGenerateMission()
	if DeadwoodMission.canRun() then
		local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
		local treeCheck = data.treeCheck
		if treeCheck == nil then
			local spots = data.spots
			Utils.shuffle(spots)
			local blockedFarmlands = {}
			for _, activeMission in ipairs(data.activeMissions) do
				blockedFarmlands[activeMission.spot.farmlandId] = true
			end
			local foundSpot = nil
			for _, spot in ipairs(spots) do
				if data.spotsDisabled[spot] == nil then
					if spot.isInUse then
						continue
					end
					if blockedFarmlands[spot.farmlandId] == nil and g_farmlandManager:getFarmlandOwner(spot.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID then
						foundSpot = spot
						break
					end
				end
			end
			if foundSpot == nil then
				return nil
			else
				treeCheck = {}
				treeCheck.spot = foundSpot
				treeCheck.isRunning = true
				treeCheck.trees = {}
				treeCheck.preplacedDeadwood = {}
				treeCheck.farmlandId = foundSpot.farmlandId
				local x = foundSpot.x
				local y = foundSpot.y
				local z = foundSpot.z
				local radius = foundSpot.radius
				local collisionMask = CollisionFlag.TREE
				local height = foundSpot.height or 30
				overlapCylinderAsync(x, y, z, radius, height, Axis.Y, "onTreeCallback", DeadwoodMission, collisionMask)
				data.treeCheck = treeCheck
				return nil
			end
		elseif not treeCheck.isRunning then
			local mission = nil
			local numTrees = #treeCheck.trees
			local numPreplaced = #treeCheck.preplacedDeadwood
			local totalNumTrees = numTrees + numPreplaced
			if 0 < totalNumTrees then
				mission = DeadwoodMission.new(true, g_client ~= nil)
				if mission:init(treeCheck.spot, treeCheck.trees, treeCheck.preplacedDeadwood) then
					local environment = g_currentMission.environment
					mission:setEndDate(environment.currentMonotonicDay + 2, MathUtil.hoursToMs(math.random(10, 18)))
				else
					mission:delete()
					mission = nil
				end
			else
				log("disable spot: no trees found")
				data.spotsDisabled[treeCheck.spot] = true
			end
			data.treeCheck = nil
			return mission
		else
			return nil
		end
	end
	return nil
end
function DeadwoodMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if data.spots == nil then
		return false
	end
	local numSpots = #data.spots
	if numSpots == 0 then
		return false
	elseif data.treeIndex == nil then
		return false
	elseif data.maxNumInstances <= data.numInstances then
		return false
	else
		if data.nextMissionDay ~= nil then
			local monotonicDay = g_currentMission.environment.currentMonotonicDay
			if monotonicDay < data.nextMissionDay then
				return false
			end
		end
		return true
	end
end
g_missionManager:registerMissionType(DeadwoodMission, DeadwoodMission.NAME, 1)
