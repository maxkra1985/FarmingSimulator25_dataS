-- Local values: TreeTransportMission_mt
TreeTransportMission = {}
source("dataS/scripts/missions/forestry/TreeTransportMissionHotspot.lua")
source("dataS/scripts/missions/forestry/TreeTransportMissionTreeCutEvent.lua")
source("dataS/scripts/missions/forestry/TreeTransportMissionWrongSellingStationEvent.lua")
TreeTransportMission.NAME = "treeTransportMission"
local TreeTransportMission_mt = Class(TreeTransportMission, AbstractMission)
InitStaticObjectClass(TreeTransportMission, "TreeTransportMission")

function TreeTransportMission.registerXMLPaths(schema, key)
	TreeTransportMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#maxNumInstances", "Max number of instances")
	schema:register(XMLValueType.INT, key .. "#rewardPerTree", "Reward per tree")
	schema:register(XMLValueType.INT, key .. "#penaltyPerTree", "Penalty per tree")
	schema:register(XMLValueType.STRING, key .. "#treeType", "Tree type")
	schema:register(XMLValueType.STRING, key .. ".spots#filename", "Filename to tree spots")
end

function TreeTransportMission.registerSavegameXMLPaths(schema, key)
	TreeTransportMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#spotIndex", "Spot index")
	schema:register(XMLValueType.INT, key .. "#numTrees", "Number of trees")
	schema:register(XMLValueType.INT, key .. "#numDeliveredTrees", "Number of delivered trees")
	schema:register(XMLValueType.INT, key .. "#numDeletedTrees", "Number of deleted trees")
	schema:register(XMLValueType.INT, key .. ".tree(?)#splitShapePart1", "Part1 of the tree")
	schema:register(XMLValueType.INT, key .. ".tree(?)#splitShapePart2", "Part2 of the tree")
	schema:register(XMLValueType.INT, key .. ".tree(?)#splitShapePart3", "Part3 of the tree")
	schema:register(XMLValueType.VECTOR_TRANS, key .. ".tree(?)#position", "Position of the tree")
	schema:register(XMLValueType.VECTOR_ROT, key .. ".tree(?)#rotation", "Rotation of the tree")
	schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart1", "Part1 of the cut split shape")
	schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart2", "Part2 of the cut split shape")
	schema:register(XMLValueType.INT, key .. ".cutSplitShape(?)#splitShapePart3", "Part3 of the cut split shape")
	schema:register(XMLValueType.STRING, key .. ".sellingStation#uniqueId", "UniqueId of the selling station")
	schema:register(XMLValueType.INT, key .. ".sellingStation#unloadingStationIndex", "Index of the unloading station")
end

function TreeTransportMission.registerMetaXMLPaths(schema, key)
	TreeTransportMission:superClass().registerMetaXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#nextDay", "Earliest day a new mission can spawn")
end

-- Upvalues: TreeTransportMission_mt
-- Local values: title, description, self, data
function TreeTransportMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) TreeTransportMission_mt
	local v11_ = g_i18n:getText("contract_forestry_treeTransport_title")
	local v12_ = g_i18n:getText("contract_forestry_treeTransport_description")
	local v13_ = AbstractMission.new(isServer, isClient, v11_, v12_, customMt or TreeTransportMission_mt)
	v13_.spot = nil
	v13_.trees = {}
	v13_.pendingTrees = {}
	v13_.treeShapeToTree = {}
	v13_.cutSplitShapes = {}
	v13_.resolveServerIds = false
	v13_.hasCollision = false
	v13_.numDeliveredTrees = 0
	v13_.numDeletedTrees = 0
	v13_.numTrees = 0
	v13_.mapHotspot = nil
	v13_.isHotspotAdded = false
	v13_.pendingSellingStationId = nil
	v13_.sellingStation = nil
	g_messageCenter:subscribe(MessageType.SPLIT_SHAPE, v13_.onTreeShapeCut, v13_)
	local v14_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	table.addElement(v14_.activeMissions, v13_)
	return v13_
end

-- Local values: data, rewardPerTree
function TreeTransportMission:init(spot, sellingStation)
	if spot == nil then
		return false
	end
	self:setSpot(spot)
	if not self:canSpawnTrees() then
		return false
	end
	self.numTrees = getNumOfChildren(spot.node)
	local v18_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).rewardPerTree
	self.reward = self.numTrees * v18_
	self:setSellingStation(sellingStation)
	return TreeTransportMission:superClass().init(self)
end

-- Local values: placeable, unloadingStation
function TreeTransportMission:onSavegameLoaded()
	if not self:getIsFinished() then
		local v20_ = g_currentMission.placeableSystem:getPlaceableByUniqueId(self.sellingStationPlaceableUniqueId)
		if v20_ == nil then
			Logging.error("Selling station placeable with uniqueId \'%s\' not available for tree transport mission", self.sellingStationPlaceableUniqueId)
			g_missionManager:markMissionForDeletion(self)
			return
		end
		local v21_ = g_currentMission.storageSystem:getPlaceableUnloadingStation(v20_, self.unloadingStationIndex)
		if v21_ == nil then
			Logging.error("Unable to retrieve unloadingStation %d for placeable %s for tree transport mission", self.unloadingStationIndex, v20_.configFileName)
			g_missionManager:markMissionForDeletion(self)
			return
		end
		self:setSellingStation(v21_)
		if self:getWasStarted() then
			v21_.missions[self] = self
		end
	end
	TreeTransportMission:superClass().onSavegameLoaded(self)
end

-- Local values: x, z
function TreeTransportMission:setSpot(spot)
	self.spot = spot
	spot.isInUse = true
	self.farmlandId = spot.farmlandId
	if self.mapHotspot == nil then
		self.mapHotspot = TreeTransportMissionHotspot.new()
	end
	local v24_ = self.spot.x
	local v25_ = self.spot.z
	self.mapHotspot:setWorldPosition(v24_, v25_)
	self.mapHotspots = { self.mapHotspot }
end

-- Local values: data
function TreeTransportMission:delete()
	self:removeHotspot()
	self:deleteTrees()
	g_messageCenter:unsubscribeAll(self)
	if self.spot ~= nil then
		self.spot.isInUse = false
		self.spot = nil
	end
	if self.mapHotspot ~= nil then
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
	if self.sellingStationMapHotspot ~= nil then
		self.sellingStationMapHotspot:delete()
		self.sellingStationMapHotspot = nil
	end
	if self.sellingStation ~= nil then
		self.sellingStation.missions[self] = nil
		self.sellingStation = nil
	end
	local v27_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	if v27_ ~= nil then
		table.removeElement(v27_.activeMissions, self)
	end
	TreeTransportMission:superClass().delete(self)
end

-- Local values: i, _, shape, treeKey, splitShapePart1, splitShapePart2, splitShapePart3, x, y, z, rx, ry, rz, shape, _, cutSplitShapeKey, splitShapePart1, splitShapePart2, splitShapePart3, sellingStationPlaceable, sellPointName, unloadingStationIndex, sellPointName
function TreeTransportMission:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. "#numTrees", self.numTrees)
	TreeTransportMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#spotIndex", self.spot.index)
	xmlFile:setValue(key .. "#numDeliveredTrees", self.numDeliveredTrees)
	xmlFile:setValue(key .. "#numDeletedTrees", self.numDeletedTrees)
	if self:getWasRunning() then
		local v31_ = 0
		for _, v32_ in ipairs(self.trees) do
			local v33_ = string.format("%s.tree(%d)", key, v31_)
			if entityExists(v32_) then
				local v34_, v35_, v36_ = getSaveableSplitShapeId(v32_)
				if v34_ ~= 0 then
					xmlFile:setValue(v33_ .. "#splitShapePart1", v34_)
					xmlFile:setValue(v33_ .. "#splitShapePart2", v35_)
					xmlFile:setValue(v33_ .. "#splitShapePart3", v36_)
					local v37_, v38_, v39_ = getWorldTranslation(v32_)
					local v40_, v41_, v42_ = getWorldRotation(v32_)
					xmlFile:setValue(v33_ .. "#position", v37_, v38_, v39_)
					xmlFile:setValue(v33_ .. "#rotation", v40_, v41_, v42_)
					v31_ = v31_ + 1
				end
			end
		end
		local v43_ = 0
		for v44_, _ in pairs(self.cutSplitShapes) do
			local v45_ = string.format("%s.cutSplitShape(%d)", key, v43_)
			if entityExists(v44_) then
				local v46_, v47_, v48_ = getSaveableSplitShapeId(v44_)
				if v46_ ~= 0 then
					xmlFile:setValue(v45_ .. "#splitShapePart1", v46_)
					xmlFile:setValue(v45_ .. "#splitShapePart2", v47_)
					xmlFile:setValue(v45_ .. "#splitShapePart3", v48_)
					v43_ = v43_ + 1
				end
			end
		end
	end
	if self.sellingStation ~= nil then
		local v49_ = self.sellingStation.owningPlaceable
		if v49_ == nil then
			local v50_ = self.sellingStation.getName and self.sellingStation:getName() or "unknown"
			Logging.xmlWarning(xmlFile, "Unable to retrieve placeable of sellPoint \'%s\' for saving tree transport mission \'%s\' ", v50_, key)
			return
		end
		local v51_ = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(v49_, self.sellingStation)
		if v51_ == nil then
			local v52_ = self.sellingStation.getName and self.sellingStation:getName() or (v49_.getName and v49_:getName() or "unknown")
			Logging.xmlWarning(xmlFile, "Unable to retrieve unloading station index of sellPoint \'%s\' for saving tree transport mission \'%s\' ", v52_, key)
			return
		end
		xmlFile:setValue(key .. ".sellingStation#uniqueId", v49_:getUniqueId())
		xmlFile:setValue(key .. ".sellingStation#unloadingStationIndex", v51_)
	end
end

-- Local values: spotIndex, data, spot, _, treeKey, splitShapePart1, splitShapePart2, splitShapePart3, x, y, z, rx, ry, rz, _, cutSplitShapeKey, splitShapePart1, splitShapePart2, splitShapePart3, sellingStationPlaceableUniqueId, unloadingStationIndex
function TreeTransportMission:loadFromXMLFile(xmlFile, key)
	self.numTrees = xmlFile:getValue(key .. "#numTrees") or self.numTrees
	TreeTransportMission:superClass().loadFromXMLFile(self, xmlFile, key)
	local v56_ = xmlFile:getValue(key .. "#spotIndex") or 0
	local v57_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).spots[v56_]
	if v57_ == nil then
		return false
	end
	self:setSpot(v57_)
	self.numDeliveredTrees = xmlFile:getValue(key .. "#numDeliveredTrees") or 0
	self.numDeletedTrees = xmlFile:getValue(key .. "#numDeletedTrees") or 0
	if self:getWasRunning() then
		self.pendingSavegameData = {
			["trees"] = {},
			["cutSplitShapes"] = {}
		}
		for _, v58_ in xmlFile:iterator(key .. ".tree") do
			local v59_ = xmlFile:getValue(v58_ .. "#splitShapePart1")
			local v60_ = xmlFile:getValue(v58_ .. "#splitShapePart2")
			local v61_ = xmlFile:getValue(v58_ .. "#splitShapePart3")
			local v62_, v63_, v64_ = xmlFile:getValue(v58_ .. "#position")
			local v65_, v66_, v67_ = xmlFile:getValue(v58_ .. "#rotation")
			local v68_ = self.pendingSavegameData.trees
			table.insert(v68_, {
				["splitShapeId1"] = v59_,
				["splitShapeId2"] = v60_,
				["splitShapeId3"] = v61_,
				["x"] = v62_ or 0,
				["y"] = v63_ or 0,
				["z"] = v64_ or 0,
				["rx"] = v65_ or 0,
				["ry"] = v66_ or 0,
				["rz"] = v67_ or 0
			})
		end
		for _, v69_ in xmlFile:iterator(key .. ".cutSplitShape") do
			local v70_ = xmlFile:getValue(v69_ .. "#splitShapePart1")
			local v71_ = xmlFile:getValue(v69_ .. "#splitShapePart2")
			local v72_ = xmlFile:getValue(v69_ .. "#splitShapePart3")
			local v73_ = self.pendingSavegameData.cutSplitShapes
			table.insert(v73_, {
				["splitShapePart1"] = v70_,
				["splitShapePart2"] = v71_,
				["splitShapePart3"] = v72_
			})
		end
	end
	if not self:getIsFinished() then
		local v74_ = xmlFile:getValue(key .. ".sellingStation#uniqueId")
		if v74_ == nil then
			Logging.xmlError(xmlFile, "No sellPointPlaceable uniqueId given for tree transport mission at \'%s\'", key)
			return false
		end
		local v75_ = xmlFile:getValue(key .. ".sellingStation#unloadingStationIndex")
		if v75_ == nil then
			Logging.xmlError(xmlFile, "No unloadting station index given for tree transport mission at \'%s\'", key)
			return false
		end
		self.sellingStationPlaceableUniqueId = v74_
		self.unloadingStationIndex = v75_
	end
	return true
end

-- Local values: _, treeNode, treeExists
function TreeTransportMission:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.numTrees)
	TreeTransportMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.spot.index)
	streamWriteUInt8(streamId, self.numDeletedTrees)
	streamWriteUInt8(streamId, self.numDeliveredTrees)
	streamWriteUInt8(streamId, #self.trees)
	for _, v79_ in ipairs(self.trees) do
		local v80_ = entityExists(v79_)
		if streamWriteBool(streamId, v80_) then
			writeSplitShapeIdToStream(streamId, v79_)
		end
	end
	NetworkUtil.writeNodeObject(streamId, self.sellingStation)
end

-- Local values: spotIndex, data, spot, numTrees, i, entityId, splitShapeId1, splitShapeId2
function TreeTransportMission:readStream(streamId, connection)
	self.numTrees = streamReadUInt8(streamId)
	TreeTransportMission:superClass().readStream(self, streamId, connection)
	local v84_ = streamReadUInt8(streamId)
	self:setSpot(g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).spots[v84_])
	self.numDeletedTrees = streamReadUInt8(streamId)
	self.numDeliveredTrees = streamReadUInt8(streamId)
	for _ = 1, streamReadUInt8(streamId) do
		if streamReadBool(streamId) then
			local v85_, v86_, v87_ = readSplitShapeIdFromStream(streamId)
			if v85_ == 0 then
				if v86_ ~= 0 then
					local v88_ = self.pendingTrees
					table.insert(v88_, { v86_, v87_ })
				end
			else
				local v89_ = self.trees
				table.insert(v89_, v85_)
			end
		end
	end
	self.pendingSellingStationId = NetworkUtil.readNodeObjectId(streamId)
	self.resolveServerIds = true
end

function TreeTransportMission:writeUpdateStream(streamId, connection, dirtyMask)
	TreeTransportMission:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	streamWriteUInt8(streamId, self.numDeletedTrees)
	streamWriteUInt8(streamId, self.numDeliveredTrees)
end

function TreeTransportMission:readUpdateStream(streamId, timestamp, connection)
	TreeTransportMission:superClass().readUpdateStream(self, streamId, timestamp, connection)
	self.numDeletedTrees = streamReadUInt8(streamId)
	self.numDeliveredTrees = streamReadUInt8(streamId)
end

-- Local values: found, numLoadedTrees, numSavegameTrees, _, data, treeNode, treeObj, numDeletedTrees, _, data, treeNode, splitShapeId, tree, i, tree, entityId
function TreeTransportMission:update(dt)
	if self.isServer then
		if self.pendingSellingStationId ~= nil then
			self:tryToResolveSellingStation()
		end
		if self.pendingSavegameData ~= nil then
			local v100_ = 0
			local v101_ = 0
			local v102_ = false
			for _, v103_ in ipairs(self.pendingSavegameData.trees) do
				v100_ = v100_ + 1
				if v103_.splitShapeId1 ~= nil then
					local v104_ = getShapeFromSaveableSplitShapeId(v103_.splitShapeId1, v103_.splitShapeId2, v103_.splitShapeId3)
					if v104_ ~= 0 then
						setWorldTranslation(v104_, v103_.x, v103_.y, v103_.z)
						setWorldRotation(v104_, v103_.rx, v103_.ry, v103_.rz)
						local v105_ = TreeTransportMissionTree.new(self.isServer, self.isClient)
						v105_:setNodeId(v104_)
						v105_:register()
						self.treeShapeToTree[v104_] = v105_
						local v106_ = self.trees
						table.insert(v106_, v104_)
						v101_ = v101_ + 1
						v102_ = true
					end
				end
			end
			if v102_ then
				local v107_ = v100_ - v101_
				self.numDeletedTrees = self.numDeletedTrees + v107_
			end
			for _, v108_ in ipairs(self.pendingSavegameData.cutSplitShapes) do
				if v108_.splitShapeId1 ~= nil then
					local v109_ = getShapeFromSaveableSplitShapeId(v108_.splitShapeId1, v108_.splitShapeId2, v108_.splitShapeId3)
					if v109_ ~= 0 then
						self.cutSplitShapes[v109_] = true
					end
				end
			end
			self.pendingSavegameData = nil
		end
		for v110_, _ in pairs(self.treeShapeToTree) do
			if not entityExists(v110_) then
				self:onMissionTreeCut(v110_)
			end
		end
	end
	TreeTransportMission:superClass().update(self, dt)
	if not self.isServer and self.pendingTrees ~= nil then
		for v111_ = #self.pendingTrees, 1, -1 do
			local v112_ = self.pendingTrees[v111_]
			local v113_ = resolveStreamSplitShapeId(v112_[1], v112_[2])
			if v113_ ~= 0 then
				table.remove(self.pendingTrees, v111_)
				local v114_ = self.trees
				table.insert(v114_, v113_)
			end
		end
		if #self.pendingTrees == 0 then
			self.pendingTrees = nil
		end
	end
	if self.status == MissionStatus.RUNNING and (g_localPlayer ~= nil and (g_localPlayer.farmId == self.farmId and not self.isHotspotAdded)) then
		self:addHotspots()
	end
end

-- Local values: sellingStation
function TreeTransportMission:tryToResolveSellingStation()
	if self.pendingSellingStationId ~= nil and self.sellingStation == nil then
		local v116_ = NetworkUtil.getObject(self.pendingSellingStationId)
		if v116_ ~= nil then
			self:setSellingStation(v116_)
		end
	end
end

-- Local values: placeable, mapHotspot
function TreeTransportMission:setSellingStation(sellingStation)
	if sellingStation ~= nil then
		self.pendingSellingStationId = nil
		self.sellingStation = sellingStation
		local v119_ = sellingStation.owningPlaceable
		if v119_ ~= nil and v119_.getHotspot ~= nil then
			local v120_ = v119_:getHotspot()
			if v120_ ~= nil then
				self.sellingStationMapHotspot = HarvestMissionHotspot.new()
				self.sellingStationMapHotspot:setWorldPosition(v120_:getWorldPosition())
				table.addElement(self.mapHotspots, self.sellingStationMapHotspot)
				if self.addSellingStationHotSpot then
					g_currentMission:addMapHotspot(self.sellingStationMapHotspot)
				end
			end
		end
	end
end

-- Local values: data, treeNode, splitShapeId, treeObj
function TreeTransportMission:createTree(x, y, z, rx, ry, rz)
	local v128_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	local v129_ = g_treePlantManager:plantTree(v128_.treeIndex, x, y, z, rx, ry, rz, 1, 1, false, nil)
	if v129_ == nil then
		return nil
	end
	local v130_ = SplitShapeUtil.getSplitShapeId(v129_)
	local v131_ = TreeTransportMissionTree.new(self.isServer, self.isClient)
	v131_:setNodeId(v130_)
	v131_:register()
	self.treeShapeToTree[v130_] = v131_
	local v132_ = self.trees
	table.insert(v132_, v130_)
	return v129_
end

-- Local values: _, tree, parent, splitShapeId, _
function TreeTransportMission:deleteTrees()
	for _, v134_ in ipairs(self.trees) do
		if entityExists(v134_) then
			local v135_ = getParent(v134_)
			if entityExists(v135_) then
				delete(v135_)
			end
		end
	end
	for v136_, _ in pairs(self.cutSplitShapes) do
		if entityExists(v136_) then
			delete(v136_)
			self.cutSplitShapes[v136_] = nil
		end
	end
end

function TreeTransportMission:start(spawnVehicles)
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.sellingStation == nil then
		return false
	else
		self.sellingStation.missions[self] = self
		if TreeTransportMission:superClass().start(self, spawnVehicles) then
			return self:canSpawnTrees() and true or false
		else
			return false
		end
	end
end

-- Local values: i, spawnNode, x, y, z, rx, ry, rz
function TreeTransportMission:prepare(spawnVehicles)
	TreeTransportMission:superClass().prepare(self, spawnVehicles)
	if self.isServer then
		for v141_ = 0, self.numTrees - 1 do
			local v142_ = getChildAt(self.spot.node, v141_)
			local v143_, v144_, v145_ = getWorldTranslation(v142_)
			local v146_, v147_, v148_ = getWorldRotation(v142_)
			self:createTree(v143_, v144_, v145_, v146_, v147_, v148_)
		end
	end
end

-- Local values: mission
function TreeTransportMission:finish(finishState)
	if self.sellingStation ~= nil then
		self.sellingStation.missions[self] = nil
		self.sellingStation = nil
	end
	self:removeHotspot()
	local v151_ = g_currentMission
	if v151_:getFarmId() == self.farmId then
		if finishState == MissionFinishState.SUCCESS then
			v151_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_forestry_treeTransport_finished"), self.farmlandId))
		elseif finishState == MissionFinishState.FAILED then
			v151_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_treeTransport_failed"), self.farmlandId))
		elseif finishState == MissionFinishState.TIMED_OUT then
			v151_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_treeTransport_timedOut"), self.farmlandId))
		end
	end
	TreeTransportMission:superClass().finish(self, finishState)
end

function TreeTransportMission:addHotspots()
	if self.mapHotspot ~= nil then
		self.isHotspotAdded = true
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
	if self.sellingStationMapHotspot ~= nil then
		g_currentMission:addMapHotspot(self.sellingStationMapHotspot)
	end
	self.addSellingStationHotSpot = true
end

function TreeTransportMission:removeHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
	if self.sellingStationMapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.sellingStationMapHotspot)
	end
	self.addSellingStationHotSpot = false
end

-- Local values: tree
function TreeTransportMission:onMissionTreeCut(splitShapeId)
	local v156_ = self.treeShapeToTree[splitShapeId]
	if v156_ ~= nil then
		v156_:delete()
		self.treeShapeToTree[splitShapeId] = nil
		self.numDeletedTrees = self.numDeletedTrees + 1
		g_currentMission:broadcastEventToFarm(TreeTransportMissionTreeCutEvent.new(), self.farmId, true)
	end
end

-- Local values: treeObj, _, data, _, data
function TreeTransportMission:onTreeShapeCut(shapeData, splitShapeData)
	if self.status == MissionStatus.RUNNING then
		if self.isServer then
			if self.treeShapeToTree[shapeData.shape] then
				self:onMissionTreeCut(shapeData.shape)
				for _, v160_ in ipairs(splitShapeData) do
					self.cutSplitShapes[v160_.shape] = true
				end
				return
			end
			if self.cutSplitShapes[shapeData.shape] ~= nil then
				for _, v161_ in ipairs(splitShapeData) do
					self.cutSplitShapes[v161_.shape] = true
				end
				return
			end
		end
	end
end

-- Local values: res, farmland
function TreeTransportMission:validate()
	local v163_ = TreeTransportMission:superClass().validate(self)
	if v163_ then
		local v164_ = g_farmlandManager:getFarmlandById(self.farmlandId)
		if v164_ == nil or v164_.isOwned then
			return false
		elseif self.sellingStation == nil or self.sellingStation.isRegistered then
			return v163_
		else
			return false
		end
	else
		return false
	end
end

function TreeTransportMission:getLocation()
	return string.format(g_i18n:getText("contract_farmland"), self.farmlandId)
end

function TreeTransportMission:getMapHotspots()
	return self.mapHotspots
end

-- Local values: spot, farmland
function TreeTransportMission:getWorldPosition()
	local v168_ = self.spot
	if v168_ == nil then
		return g_farmlandManager:getFarmlandById(self.farmlandId):getIndicatorPosition()
	else
		return v168_.x, v168_.z
	end
end

-- Local values: numTrees, vehicleSize
function TreeTransportMission:getVehicleSize()
	local v170_ = self.numTrees
	return v170_ > 20 and "large" or (v170_ >= 10 and "medium" or "small")
end

-- Local values: details, data, numTrees, title
function TreeTransportMission:getDetails()
	local v172_ = TreeTransportMission:superClass().getDetails(self)
	local v173_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	local v174_ = self.numTrees - self.numDeletedTrees
	local v175_ = {
		["title"] = g_i18n:getText("contract_details_farmland"),
		["value"] = self.farmlandId
	}
	table.insert(v172_, v175_)
	local v176_ = nil
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	if self.sellingStation ~= nil then
		v176_ = self.sellingStation:getName()
	end
	if v176_ ~= nil then
		local v177_ = {
			["title"] = g_i18n:getText("contract_forestry_details_sellingStation"),
			["value"] = v176_
		}
		table.insert(v172_, v177_)
	end
	local v178_ = {
		["title"] = g_i18n:getText("contract_forestry_details_rewardPerTree"),
		["value"] = g_i18n:formatMoney(v173_.rewardPerTree, 0, true)
	}
	table.insert(v172_, v178_)
	local v179_ = {
		["title"] = g_i18n:getText("contract_forestry_details_penaltyPerTree"),
		["value"] = g_i18n:formatMoney(v173_.penaltyPerTree, 0, true)
	}
	table.insert(v172_, v179_)
	local v180_ = {
		["title"] = g_i18n:getText("contract_forestry_details_totalNumTrees"),
		["value"] = v174_
	}
	table.insert(v172_, v180_)
	if self.status ~= MissionStatus.CREATED then
		local v181_ = {
			["title"] = g_i18n:getText("contract_forestry_treeTransport_details_deliveredNumTrees"),
			["value"] = self.numDeliveredTrees
		}
		table.insert(v172_, v181_)
	end
	return v172_
end

-- Local values: farmland, npc
function TreeTransportMission:getNPC()
	local v183_ = g_farmlandManager:getFarmlandById(self.farmlandId)
	return g_npcManager:getNPCByIndex(v183_.npcIndex)
end

-- Local values: remaining
function TreeTransportMission:getExtraProgressText()
	local v185_ = self.numTrees - (self.numDeliveredTrees + self.numDeletedTrees)
	local v186_ = math.max(0, v185_)
	return string.format(g_i18n:getText("contract_forestry_treeTransport_remainingTrees"), v186_)
end

function TreeTransportMission:getCompletion()
	return self.numTrees <= 0 and 1 or (self.numDeliveredTrees + self.numDeletedTrees) / self.numTrees
end

function TreeTransportMission:getReward()
	return self.reward
end

function TreeTransportMission:getFarmlandId()
	return self.farmlandId
end

-- Local values: data
function TreeTransportMission:calculateStealingCost()
	local v191_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	return v191_ == nil and 0 or self.numDeletedTrees * v191_.penaltyPerTree
end

-- Local values: change
function TreeTransportMission:dismiss()
	if self.isServer then
		local v193_ = (self.finishState ~= MissionFinishState.SUCCESS and 0 or self:getReward()) - self:calculateStealingCost()
		if v193_ ~= 0 then
			g_currentMission:addMoney(v193_, self.farmId, MoneyType.MISSIONS, true, true)
		end
	end
end

function TreeTransportMission:getIsShapeCutAllowed(shape, x, z, farmId)
	if self.status == MissionStatus.CREATED or self.treeShapeToTree[shape] == nil then
		return nil
	else
		return false
	end
end

-- Local values: found, target
function TreeTransportMission:onTriggerProcessedWood(trigger, splitShapeId, volume, fillType)
	if not self.isServer then
		return
	end
	if self.treeShapeToTree[splitShapeId] == nil then
		return
	end
	if self.pendingSellingStationId ~= nil then
		self:tryToResolveSellingStation()
	end
	local v199_ = false
	if self.sellingStation ~= nil then
		local v200_ = trigger:getTarget()
		while v200_ ~= nil do
			if v200_ == self.sellingStation then
				v199_ = true
				break
			end
			if v200_.getTarget == nil then
				break
			end
			v200_ = v200_:getTarget()
		end
	end
	if v199_ then
		self.numDeliveredTrees = self.numDeliveredTrees + 1
	else
		g_currentMission:broadcastEventToFarm(TreeTransportMissionWrongSellingStationEvent.new(), self.farmId, true)
		self.numDeletedTrees = self.numDeletedTrees + 1
	end
	self.treeShapeToTree[splitShapeId]:delete()
	self.treeShapeToTree[splitShapeId] = nil
end

function TreeTransportMission:getIsMissionSplitShape(shape)
	if shape == nil or shape == 0 then
		return false
	elseif self.status == MissionStatus.RUNNING then
		return self.treeShapeToTree[shape] ~= nil
	else
		return false
	end
end

-- Local values: spot, sizeX, sizeY, sizeZ, threshold, x, y, z, rx, ry, rz, collisionFilterMask
function TreeTransportMission:canSpawnTrees()
	local v204_ = self.spot
	local v205_ = v204_.sizeX * 0.5
	local v206_ = v204_.sizeY * 0.5
	local v207_ = v204_.sizeZ * 0.5
	local v208_, v209_, v210_ = localToWorld(v204_.node, v205_ - 0.15, v206_ - 0.15, v207_ - 0.15)
	local v211_, v212_, v213_ = getWorldRotation(v204_.node)
	local v214_ = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT
	self.hasCollision = false
	overlapBox(v208_, v209_, v210_, v211_, v212_, v213_, v205_ + 0.15, v206_ + 0.15, v207_ + 0.15, "onSpotCollision", self, v214_, true, true, true, true)
	return not self.hasCollision
end

function TreeTransportMission:onSpotCollision(node)
	if node ~= g_terrainNode and not getHasTrigger(node) then
		self.hasCollision = true
	end
end

function TreeTransportMission:getMissionTypeName()
	return TreeTransportMission.NAME
end

function TreeTransportMission:onDeleteSellingStation(sellingStation)
	if sellingStation == self.sellingStation and (self.isServer and (self.status == MissionStatus.RUNNING and not g_currentMission.isExitingGame)) then
		Logging.warning("Finish tree transport mission because selling station was removed")
		self:finish(MissionFinishState.FAILED)
	end
end

-- Local values: treeTypeName, treeDesc, spotFilename, i3dNode, data, root, i, spotNode, x, y, z, farmlandId, isValidFarmland, sizeX, sizeY, sizeZ, spot, farmland
function TreeTransportMission.loadMapData(xmlFile, key, baseDirectory)
	if xmlFile:hasProperty(key) then
		local v222_ = xmlFile:getString(key .. "#treeType")
		local v223_ = g_treePlantManager:getTreeTypeDescFromName(v222_)
		if v223_ == nil then
			Logging.xmlWarning(xmlFile, "Missing or undefined treeType \'%s\' for treeTransport mission (%s)!", v222_, key)
			return false
		end
		local v224_ = xmlFile:getString(key .. ".spots#filename")
		if v224_ == nil then
			Logging.xmlWarning(xmlFile, "Missing spot definition file for treeTransport mission (%s)", key)
			return false
		end
		local v225_ = Utils.getFilename(v224_, baseDirectory)
		local v226_ = g_i3DManager:loadI3DFile(v225_, false, false)
		if v226_ == 0 then
			return false
		end
		local v227_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
		v227_.spots = {}
		v227_.activeMissions = {}
		v227_.treeIndex = v223_.index
		v227_.maxNumInstances = xmlFile:getInt(key .. "#maxNumInstances") or 1
		v227_.rewardPerTree = xmlFile:getFloat(key .. "#rewardPerTree") or 255
		v227_.penaltyPerTree = xmlFile:getFloat(key .. "#penaltyPerTree") or 2000
		local v228_ = getChildAt(v226_, 0)
		link(getRootNode(), v228_)
		for v229_ = 0, getNumOfChildren(v228_) - 1 do
			local v230_ = getChildAt(v228_, v229_)
			local v231_, v232_, v233_ = getTranslation(v230_)
			local v234_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v231_, v233_)
			local v235_
			if v234_ == nil then
				v235_ = false
			else
				v235_ = v234_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID
			end
			if v235_ then
				local v236_ = getTerrainHeightAtWorldPos(g_terrainNode, v231_, v232_, v233_)
				local v237_ = getUserAttribute
				local v238_ = tonumber(v237_(v230_, "sizeX")) or 1
				local v239_ = getUserAttribute
				local v240_ = tonumber(v239_(v230_, "sizeY")) or 1
				local v241_ = getUserAttribute
				local v242_ = tonumber(v241_(v230_, "sizeZ")) or 1
				local v243_ = {
					["node"] = v230_,
					["index"] = #v227_.spots + 1,
					["x"] = v231_,
					["y"] = v236_,
					["z"] = v233_,
					["isInUse"] = false,
					["farmlandId"] = v234_,
					["sizeX"] = v238_,
					["sizeY"] = v240_,
					["sizeZ"] = v242_
				}
				local v244_ = v227_.spots
				table.insert(v244_, v243_)
			else
				local v245_ = v234_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID and "Not defined" or string.format("Not buyable (%d)", v234_)
				Logging.xmlWarning(xmlFile, "Invalid farmland \'%s\' found for tree transport mission spot \'%s\' at %d %d!", v245_, getName(v230_), v231_, v233_)
			end
		end
		v227_.spotRoot = v228_
		delete(v226_)
		return true
	end
end
function TreeTransportMission.unloadMapData()
	local v246_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	if v246_ ~= nil and v246_.spotRoot ~= nil then
		delete(v246_.spotRoot)
	end
end

-- Local values: data
function TreeTransportMission.loadMetaDataFromXMLFile(xmlFile, key)
	g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME).nextMissionDay = xmlFile:getValue(key .. "#nextDay")
end

-- Local values: data
function TreeTransportMission.saveMetaDataToXMLFile(xmlFile, key)
	local v251_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	if v251_.nextMissionDay ~= nil then
		xmlFile:setValue(key .. "#nextDay", v251_.nextMissionDay)
	end
end
function TreeTransportMission.getSellPointWithHighestPrice()
	local v252_ = 0
	local v253_ = nil
	for _, v254_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		local v255_ = v254_.owningPlaceable
		local v256_ = v254_.isSellingPoint
		local v257_ = v254_.allowMissions
		if v255_ ~= nil and (v256_ and (v257_ and v254_.acceptedFillTypes[FillType.WOOD])) then
			local v258_ = false
			for _, v259_ in ipairs(v254_.unloadTriggers) do
				if v259_:isa(WoodUnloadTrigger) then
					v258_ = true
					break
				end
			end
			if v258_ then
				local v260_ = v254_:getEffectiveFillTypePrice(FillType.WOOD)
				if v252_ < v260_ then
					v253_ = v254_
					v252_ = v260_
				end
			end
		end
	end
	return v253_, v252_
end
function TreeTransportMission.tryGenerateMission()
	if TreeTransportMission.canRun() then
		local v261_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
		local v262_ = v261_.spots
		Utils.shuffle(v262_)
		local v263_ = {}
		for _, v264_ in ipairs(v261_.activeMissions) do
			v263_[v264_.spot.farmlandId] = true
		end
		local v265_ = nil
		for _, v266_ in ipairs(v262_) do
			if not v266_.isInUse and (v263_[v266_.farmlandId] == nil and g_farmlandManager:getFarmlandOwner(v266_.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID) then
				v265_ = v266_
				break
			end
		end
		if not v265_ then
			return
		end
		local v267_, _ = TreeTransportMission.getSellPointWithHighestPrice()
		if v267_ == nil then
			return
		end
		local v268_ = TreeTransportMission.new(true, g_client ~= nil)
		if v268_:init(v265_, v267_) then
			v268_:setEndDate(g_currentMission.environment.currentMonotonicDay + 2, MathUtil.hoursToMs(math.random(10, 18)))
			return v268_
		end
		v268_:delete()
	end
	return nil
end
function TreeTransportMission.canRun()
	local v269_ = g_missionManager:getMissionTypeDataByName(TreeTransportMission.NAME)
	if v269_.spots == nil then
		return false
	elseif #v269_.spots == 0 then
		return false
	elseif v269_.treeIndex == nil then
		return false
	elseif v269_.numInstances >= v269_.maxNumInstances then
		return false
	else
		return v269_.nextMissionDay == nil or g_currentMission.environment.currentMonotonicDay >= v269_.nextMissionDay
	end
end
g_missionManager:registerMissionType(TreeTransportMission, TreeTransportMission.NAME, 1)
