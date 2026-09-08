-- Local values: DeadwoodMission_mt
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

-- Upvalues: DeadwoodMission_mt
-- Local values: title, description, self, data
function DeadwoodMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) DeadwoodMission_mt
	local v11_ = g_i18n:getText("contract_forestry_deadwood_title")
	local v12_ = g_i18n:getText("contract_forestry_deadwood_description")
	local v13_ = AbstractMission.new(isServer, isClient, v11_, v12_, customMt or DeadwoodMission_mt)
	v13_.spot = nil
	v13_.deadTrees = {}
	v13_.deadTreeShapeToTree = {}
	v13_.deadTreeCutSplitShapes = {}
	v13_.pendingOriginalTrees = {}
	v13_.originalTrees = {}
	v13_.numDeadTrees = 0
	v13_.numCutDownTrees = 0
	v13_.wronglyCutDownTreesReward = 0
	v13_.resolveOriginalTreeServerIds = false
	v13_.resolveDeadTreeServerIds = false
	v13_.isHotspotAdded = false
	v13_.mapHotspot = nil
	g_messageCenter:subscribe(MessageType.SPLIT_SHAPE, v13_.onTreeShapeCut, v13_)
	local v14_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	table.addElement(v14_.activeMissions, v13_)
	return v13_
end

-- Local values: res, numTrees, numPreplaced, totalNumTrees, numDeadTrees, minTrees, maxTrees, data, rewardPerTree, _, treeNode, _, treeNode
function DeadwoodMission:init(spot, trees, preplacedDeadwood)
	local v19_ = DeadwoodMission:superClass().init(self)
	if spot == nil then
		return false
	end
	self:setSpot(spot)
	local v20_ = #trees
	local v21_ = #preplacedDeadwood
	if v20_ + v21_ == 0 then
		return false
	end
	if v21_ < 10 then
		local v22_ = math.min(5, v20_)
		local v23_ = math.min(10, v20_)
		v21_ = v21_ + math.random(v22_, v23_)
	end
	self.numDeadTrees = v21_
	if v21_ == 0 then
		return false
	end
	local v24_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).rewardPerTree
	self.reward = self.numDeadTrees * v24_
	Utils.shuffle(trees)
	for _, v25_ in ipairs(preplacedDeadwood) do
		local v26_ = self.originalTrees
		table.insert(v26_, v25_)
	end
	for _, v27_ in ipairs(trees) do
		if #self.originalTrees == self.numDeadTrees then
			break
		end
		local v28_ = self.originalTrees
		table.insert(v28_, v27_)
	end
	return v19_
end

-- Local values: x, z, radius
function DeadwoodMission:setSpot(spot)
	self.spot = spot
	spot.isInUse = true
	self.farmlandId = spot.farmlandId
	if self.mapHotspot == nil then
		self.mapHotspot = DeadwoodMissionHotspot.new()
	end
	local v31_ = self.spot.x
	local v32_ = self.spot.z
	local v33_ = self.spot.radius
	self.mapHotspot:setWorldPosition(v31_, v32_)
	self.mapHotspot:setWorldRadius(v33_)
	self.mapHotspots = { self.mapHotspot }
end

-- Local values: data
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
	local v35_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if v35_ ~= nil then
		table.removeElement(v35_.activeMissions, self)
	end
end

-- Local values: i, _, treeNode, treeKey, splitShapePart1, splitShapePart2, splitShapePart3, _, deadTree, deadTreeKey, splitShapePart1, splitShapePart2, splitShapePart3, shape, _, cutSplitShapeKey, splitShapePart1, splitShapePart2, splitShapePart3
function DeadwoodMission:saveToXMLFile(xmlFile, key)
	DeadwoodMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#spotIndex", self.spot.index)
	local v39_ = 0
	for _, v40_ in ipairs(self.originalTrees) do
		local v41_ = string.format("%s.originalTree(%d)", key, v39_)
		if entityExists(v40_) then
			local v42_, v43_, v44_ = getSaveableSplitShapeId(v40_)
			if v42_ ~= 0 and v42_ ~= nil then
				xmlFile:setValue(v41_ .. "#splitShapePart1", v42_)
				xmlFile:setValue(v41_ .. "#splitShapePart2", v43_)
				xmlFile:setValue(v41_ .. "#splitShapePart3", v44_)
			end
		end
		v39_ = v39_ + 1
	end
	local v45_ = 0
	for _, v46_ in pairs(self.deadTrees) do
		local v47_ = string.format("%s.deadTree(%d)", key, v45_)
		xmlFile:setBool(v47_ .. "#cutDown", v46_.cutDown)
		if v46_.splitShapeId ~= nil and entityExists(v46_.splitShapeId) then
			local v48_, v49_, v50_ = getSaveableSplitShapeId(v46_.splitShapeId)
			if v48_ ~= 0 and v48_ ~= nil then
				xmlFile:setValue(v47_ .. "#splitShapePart1", v48_)
				xmlFile:setValue(v47_ .. "#splitShapePart2", v49_)
				xmlFile:setValue(v47_ .. "#splitShapePart3", v50_)
			end
		end
		v45_ = v45_ + 1
	end
	local v51_ = 0
	for v52_, _ in pairs(self.deadTreeCutSplitShapes) do
		local v53_ = string.format("%s.cutSplitShape(%d)", key, v51_)
		if entityExists(v52_) then
			local v54_, v55_, v56_ = getSaveableSplitShapeId(v52_)
			if v54_ ~= 0 and v54_ ~= nil then
				xmlFile:setValue(v53_ .. "#splitShapePart1", v54_)
				xmlFile:setValue(v53_ .. "#splitShapePart2", v55_)
				xmlFile:setValue(v53_ .. "#splitShapePart3", v56_)
				v51_ = v51_ + 1
			end
		end
	end
end

-- Local values: spotIndex, data, spot, _, treeKey, splitShapePart1, splitShapePart2, splitShapePart3, _, deadTreeKey, cutDown, splitShapePart1, splitShapePart2, splitShapePart3, _, cutSplitShapeKey, splitShapePart1, splitShapePart2, splitShapePart3
function DeadwoodMission:loadFromXMLFile(xmlFile, key)
	DeadwoodMission:superClass().loadFromXMLFile(self, xmlFile, key)
	local v60_ = xmlFile:getValue(key .. "#spotIndex") or 0
	local v61_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).spots[v60_]
	if v61_ == nil then
		return false
	end
	self:setSpot(v61_)
	self.pendingSavegameData = {
		["originalTrees"] = {},
		["deadTrees"] = {},
		["deadTreeCutSplitShapes"] = {}
	}
	for _, v62_ in xmlFile:iterator(key .. ".originalTree") do
		local v63_ = xmlFile:getValue(v62_ .. "#splitShapePart1")
		local v64_ = xmlFile:getValue(v62_ .. "#splitShapePart2")
		local v65_ = xmlFile:getValue(v62_ .. "#splitShapePart3")
		local v66_ = self.pendingSavegameData.originalTrees
		table.insert(v66_, {
			["splitShapePart1"] = v63_,
			["splitShapePart2"] = v64_,
			["splitShapePart3"] = v65_
		})
	end
	for _, v67_ in xmlFile:iterator(key .. ".deadTree") do
		local v68_ = xmlFile:getBool(v67_ .. "#cutDown")
		local v69_ = xmlFile:getValue(v67_ .. "#splitShapePart1")
		local v70_ = xmlFile:getValue(v67_ .. "#splitShapePart2")
		local v71_ = xmlFile:getValue(v67_ .. "#splitShapePart3")
		local v72_ = self.pendingSavegameData.deadTrees
		table.insert(v72_, {
			["splitShapePart1"] = v69_,
			["splitShapePart2"] = v70_,
			["splitShapePart3"] = v71_,
			["cutDown"] = v68_
		})
	end
	for _, v73_ in xmlFile:iterator(key .. ".cutSplitShape") do
		local v74_ = xmlFile:getValue(v73_ .. "#splitShapePart1")
		local v75_ = xmlFile:getValue(v73_ .. "#splitShapePart2")
		local v76_ = xmlFile:getValue(v73_ .. "#splitShapePart3")
		local v77_ = self.pendingSavegameData.deadTreeCutSplitShapes
		table.insert(v77_, {
			["splitShapePart1"] = v74_,
			["splitShapePart2"] = v75_,
			["splitShapePart3"] = v76_
		})
	end
	return true
end

-- Local values: _, treeNode
function DeadwoodMission:writeStream(streamId, connection)
	DeadwoodMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.spot.index)
	streamWriteUInt8(streamId, self.numCutDownTrees)
	streamWriteUInt8(streamId, self.numDeadTrees)
	streamWriteUInt8(streamId, #self.originalTrees)
	for _, v81_ in ipairs(self.originalTrees) do
		writeSplitShapeIdToStream(streamId, v81_)
	end
	self:writeDeadTreesStream(streamId)
end

-- Local values: spotIndex, data, spot, numOriginalTrees, i, entityId, splitShapeId1, splitShapeId2
function DeadwoodMission:readStream(streamId, connection)
	DeadwoodMission:superClass().readStream(self, streamId, connection)
	local v85_ = streamReadUInt8(streamId)
	self:setSpot(g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).spots[v85_])
	self.numCutDownTrees = streamReadUInt8(streamId)
	self.numDeadTrees = streamReadUInt8(streamId)
	for _ = 1, streamReadUInt8(streamId) do
		local v86_, v87_, v88_ = readSplitShapeIdFromStream(streamId)
		if v86_ == 0 then
			if v87_ ~= 0 then
				local v89_ = self.pendingOriginalTrees
				table.insert(v89_, { v87_, v88_ })
			end
		else
			local v90_ = self.originalTrees
			table.insert(v90_, v86_)
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

-- Local values: numDeadTrees, i, tree, entityId, splitShapeId1, splitShapeId2
function DeadwoodMission:readDeadTreesStream(streamId)
	for _ = 1, streamReadUInt8(streamId) do
		local v101_ = {
			["cutDown"] = false,
			["splitShapeId"] = nil
		}
		if not streamReadBool(streamId) then
			local v102_, v103_, v104_ = readSplitShapeIdFromStream(streamId)
			if v102_ == 0 then
				if v103_ ~= 0 then
					v101_.serverSplitShapePart1 = v103_
					v101_.serverSplitShapePart2 = v104_
				end
			else
				v101_.splitShapeId = v102_
			end
		end
		local v105_ = self.deadTrees
		table.insert(v105_, v101_)
	end
	self.resolveDeadTreeServerIds = true
end

-- Local values: _, tree
function DeadwoodMission:writeDeadTreesStream(streamId)
	streamWriteUInt8(streamId, #self.deadTrees)
	for _, v108_ in ipairs(self.deadTrees) do
		if not streamWriteBool(streamId, v108_.cutDown) then
			writeSplitShapeIdToStream(streamId, v108_.splitShapeId)
		end
	end
end

-- Local values: _, data, splitShapeId, _, data, splitShapeId, rootNode, x, _, z, rotY, deadTree, _, data, cutSplitShapeId, _, treeNode, resolvedAll, _, tree, entityId, i, originalTree, entityId, _, treeNode
function DeadwoodMission:update(dt)
	if self.isServer then
		if self.pendingSavegameData ~= nil then
			for _, v111_ in ipairs(self.pendingSavegameData.originalTrees) do
				if v111_.splitShapePart1 ~= nil then
					local v112_ = getShapeFromSaveableSplitShapeId(v111_.splitShapePart1, v111_.splitShapePart2, v111_.splitShapePart3)
					if v112_ ~= 0 and v112_ ~= nil then
						local v113_ = self.originalTrees
						table.insert(v113_, v112_)
					end
				end
			end
			self.numDeadTrees = #self.originalTrees
			self.numCutDownTrees = 0
			for _, v114_ in ipairs(self.pendingSavegameData.deadTrees) do
				local v115_ = nil
				local v116_ = nil
				local v117_ = nil
				local v118_ = nil
				local v119_
				if v114_.splitShapePart1 == nil then
					v119_ = nil
				else
					v119_ = getShapeFromSaveableSplitShapeId(v114_.splitShapePart1, v114_.splitShapePart2, v114_.splitShapePart3)
					if v119_ == 0 or v119_ == nil then
						v119_ = nil
					else
						local v120_
						v116_, v120_, v117_ = getWorldTranslation(v119_)
						local v121_, v122_
						v121_, v118_, v122_ = getWorldRotation(v119_)
						v115_ = getParent(v119_)
					end
				end
				if v114_.cutDown then
					self.numCutDownTrees = self.numCutDownTrees + 1
				end
				local v123_ = {
					["x"] = v116_,
					["z"] = v117_,
					["rotY"] = v118_,
					["cutDown"] = v114_.cutDown,
					["splitShapeId"] = v119_,
					["rootNode"] = v115_
				}
				if v119_ ~= nil then
					self.deadTreeShapeToTree[v119_] = v123_
				end
				local v124_ = self.deadTrees
				table.insert(v124_, v123_)
			end
			for _, v125_ in ipairs(self.pendingSavegameData.deadTreeCutSplitShapes) do
				if v125_.splitShapePart1 ~= nil then
					local v126_ = getShapeFromSaveableSplitShapeId(v125_.splitShapePart1, v125_.splitShapePart2, v125_.splitShapePart3)
					if v126_ ~= 0 and v126_ ~= nil then
						self.deadTreeCutSplitShapes[v126_] = true
					end
				end
			end
			if self.status ~= MissionStatus.CREATED then
				for _, v127_ in ipairs(self.originalTrees) do
					self:setTreeVisibility(v127_, false)
				end
			end
			if self.status == MissionStatus.RUNNING then
				self:addTreeMarker()
			end
			self.pendingSavegameData = nil
		end
	else
		if self.resolveDeadTreeServerIds then
			local v128_ = true
			for _, v129_ in ipairs(self.deadTrees) do
				if v129_.serverSplitShapePart1 ~= nil and v129_.serverSplitShapePart2 ~= nil then
					local v130_ = resolveStreamSplitShapeId(v129_.serverSplitShapePart1, v129_.serverSplitShapePart2)
					if v130_ == 0 then
						v128_ = false
					else
						v129_.splitShapeId = v130_
						v129_.serverSplitShapePart1 = nil
						v129_.serverSplitShapePart2 = nil
					end
				end
			end
			if v128_ then
				self.resolveDeadTreeServerIds = false
				if self.status == MissionStatus.RUNNING then
					self:addTreeMarker()
				end
			end
		end
		if self.resolveOriginalTreeServerIds then
			for v131_ = #self.pendingOriginalTrees, 1, -1 do
				local v132_ = self.pendingOriginalTrees[v131_]
				local v133_ = resolveStreamSplitShapeId(v132_[1], v132_[2])
				if v133_ ~= 0 then
					table.remove(self.pendingOriginalTrees, v131_)
					local v134_ = self.originalTrees
					table.insert(v134_, v133_)
				end
			end
			if #self.pendingOriginalTrees == 0 then
				self.resolveOriginalTreeServerIds = false
				if self.status == MissionStatus.RUNNING or self.status == MissionStatus.FINISHED then
					for _, v135_ in ipairs(self.originalTrees) do
						self:setTreeVisibility(v135_, false)
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

-- Local values: treeRoot
function DeadwoodMission:setTreeVisibility(treeNode, isVisible)
	if entityExists(treeNode) then
		local v138_ = getParent(treeNode)
		setVisibility(v138_, isVisible)
		if isVisible then
			addToPhysics(v138_)
		else
			removeFromPhysics(v138_)
		end
	else
		return
	end
end

function DeadwoodMission:getLocation()
	return string.format(g_i18n:getText("contract_farmland"), self.farmlandId)
end

function DeadwoodMission:getMapHotspots()
	return self.mapHotspots
end

-- Local values: spot, farmland
function DeadwoodMission:getWorldPosition()
	local v142_ = self.spot
	if v142_ == nil then
		return g_farmlandManager:getFarmlandById(self.farmlandId):getIndicatorPosition()
	else
		return v142_.x, v142_.z
	end
end

-- Local values: treeRoot, x, y, z, rx, ry, rz, data, treeIndex, missionTreeNode, splitShapeId, deadTree
function DeadwoodMission:addMissionTree(treeNode)
	local v145_ = getParent(treeNode)
	local v146_, v147_, v148_ = getWorldTranslation(v145_)
	local v149_, v150_, v151_ = getWorldRotation(v145_)
	local v152_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).treeIndex
	local v153_ = g_treePlantManager:plantTree(v152_, v146_, v147_, v148_, v149_, v150_, v151_, 1, 1, false)
	local v154_ = SplitShapeUtil.getSplitShapeId(v153_)
	if v154_ ~= nil then
		local v155_ = {
			["rootNode"] = v153_,
			["splitShapeId"] = v154_,
			["x"] = v146_,
			["z"] = v148_,
			["rotY"] = v150_,
			["cutDown"] = false
		}
		local v156_ = self.deadTrees
		table.insert(v156_, v155_)
		self.deadTreeShapeToTree[v154_] = v155_
	end
end

-- Local values: _, treeNode
function DeadwoodMission:prepare(spawnVehicles)
	DeadwoodMission:superClass().prepare(self, spawnVehicles)
	for _, v159_ in ipairs(self.originalTrees) do
		self:setTreeVisibility(v159_, false)
		self:addMissionTree(v159_)
	end
	self:addTreeMarker()
	g_server:broadcastEvent(DeadwoodMissionTreeEvent.new(self))
end

-- Local values: _, treeNode
function DeadwoodMission:started()
	DeadwoodMission:superClass().started(self)
	for _, v161_ in ipairs(self.originalTrees) do
		self:setTreeVisibility(v161_, false)
	end
	self:addTreeMarker()
end

-- Local values: _, tree, i, splitShapeId, _, _, treeNode
function DeadwoodMission:destroyTrees()
	for _, v163_ in ipairs(self.deadTrees) do
		if v163_.rootNode ~= nil and entityExists(v163_.rootNode) then
			for v164_ = getNumOfChildren(v163_.rootNode), 1, -1 do
				delete(getChildAt(v163_.rootNode, v164_ - 1))
			end
		end
	end
	self.deadTrees = {}
	self.deadTreeShapeToTree = {}
	for v165_, _ in pairs(self.deadTreeCutSplitShapes) do
		if entityExists(v165_) then
			delete(v165_)
			self.deadTreeCutSplitShapes[v165_] = nil
		end
	end
	for _, v166_ in ipairs(self.originalTrees) do
		self:setTreeVisibility(v166_, true)
	end
end

-- Local values: treeMarkerSystem, treeMarkerType, _, tree
function DeadwoodMission:addTreeMarker()
	local v168_ = g_currentMission.treeMarkerSystem
	if v168_ == nil then
		return
	else
		local v169_ = v168_:getTreeMarkerTypeByName("EXCLAMATION")
		if v169_ ~= nil then
			for _, v170_ in pairs(self.deadTrees) do
				if v170_.splitShapeId ~= nil then
					v168_:addTreeMarkerByWorldDirection(v170_.splitShapeId, v169_.index, 0.7084, 0.0212, 0.0006, 1, 0, 1, 2, 0.7, true)
				end
			end
		end
	end
end

-- Local values: mission
function DeadwoodMission:finish(finishState)
	self:removeHotspot()
	local v173_ = g_currentMission
	if v173_:getFarmId() == self.farmId then
		if finishState == MissionFinishState.SUCCESS then
			v173_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_forestry_deadwood_completed"), self.farmlandId))
		elseif finishState == MissionFinishState.FAILED then
			v173_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_deadwood_failed"), self.farmlandId))
		elseif finishState == MissionFinishState.TIMED_OUT then
			v173_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_forestry_deadwood_timedOut"), self.farmlandId))
		end
	end
	DeadwoodMission:superClass().finish(self, finishState)
end

function DeadwoodMission:getIsMissionSplitShape(shape)
	if shape == nil or shape == 0 then
		return false
	elseif self.status == MissionStatus.RUNNING then
		return self.deadTreeCutSplitShapes[shape] ~= nil and true or self.deadTreeShapeToTree[shape] ~= nil
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

-- Local values: res, farmland
function DeadwoodMission:validate()
	local v179_ = DeadwoodMission:superClass().validate(self)
	if v179_ then
		local v180_ = g_farmlandManager:getFarmlandById(self.farmlandId)
		if v180_ == nil or v180_.isOwned then
			return false
		else
			return v179_
		end
	else
		return false
	end
end

-- Local values: change
function DeadwoodMission:dismiss()
	if self.isServer then
		local v182_ = (self.finishState ~= MissionFinishState.SUCCESS and 0 or self:getReward()) - self.wronglyCutDownTreesReward
		if v182_ ~= 0 then
			g_currentMission:addMoney(v182_, self.farmId, MoneyType.MISSIONS, true, true)
		end
	end
end

-- Local values: farmland, npc
function DeadwoodMission:getNPC()
	local v184_ = g_farmlandManager:getFarmlandById(self.farmlandId)
	return g_npcManager:getNPCByIndex(v184_.npcIndex)
end

-- Local values: remaining
function DeadwoodMission:getExtraProgressText()
	local v186_ = self.numDeadTrees - self.numCutDownTrees
	if v186_ == 1 then
		return g_i18n:getText("contract_forestry_deadwood_oneRemainingTree")
	else
		return string.format(g_i18n:getText("contract_forestry_deadwood_remainingTrees"), v186_)
	end
end

-- Local values: details, data
function DeadwoodMission:getDetails()
	local v188_ = DeadwoodMission:superClass().getDetails(self)
	local v189_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	local v190_ = {
		["title"] = g_i18n:getText("contract_details_farmland"),
		["value"] = self.farmlandId
	}
	table.insert(v188_, v190_)
	local v191_ = {
		["title"] = g_i18n:getText("contract_forestry_details_rewardPerTree"),
		["value"] = g_i18n:formatMoney(v189_.rewardPerTree, 0, true)
	}
	table.insert(v188_, v191_)
	local v192_ = {
		["title"] = g_i18n:getText("contract_forestry_details_penaltyPerTree"),
		["value"] = g_i18n:formatMoney(v189_.penaltyPerTree, 0, true)
	}
	table.insert(v188_, v192_)
	local v193_ = {
		["title"] = g_i18n:getText("contract_forestry_details_totalNumTrees"),
		["value"] = self.numDeadTrees
	}
	table.insert(v188_, v193_)
	if self.status ~= MissionStatus.CREATED then
		local v194_ = {
			["title"] = g_i18n:getText("contract_forestry_deadwood_details_cutNumTrees"),
			["value"] = self.numCutDownTrees
		}
		table.insert(v188_, v194_)
	end
	return v188_
end

function DeadwoodMission:getCompletion()
	return self.numDeadTrees == 0 and 0 or self.numCutDownTrees / self.numDeadTrees
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

-- Local values: missionTree, _, data, _, data, mission, farmlandId, volume, splitType, data, costs
function DeadwoodMission:onTreeShapeCut(shapeData, splitShapeData)
	if self.status == MissionStatus.RUNNING then
		if self.isServer then
			local v202_ = self.deadTreeShapeToTree[shapeData.shape]
			if v202_ ~= nil then
				v202_.cutDown = true
				self.numCutDownTrees = self.numCutDownTrees + 1
				for _, v203_ in ipairs(splitShapeData) do
					self.deadTreeCutSplitShapes[v203_.shape] = true
				end
				return
			end
			if self.deadTreeCutSplitShapes[shapeData.shape] ~= nil then
				for _, v204_ in ipairs(splitShapeData) do
					self.deadTreeCutSplitShapes[v204_.shape] = true
				end
				return
			end
			if shapeData.alreadySplit then
				return
			end
			if g_missionManager:getMissionBySplitShape(shapeData.shape) ~= nil then
				return
			end
			if g_farmlandManager:getFarmlandIdAtWorldPosition(shapeData.x, shapeData.z) == self.farmlandId then
				local v205_ = shapeData.volume
				local v206_ = g_splitShapeManager:getSplitTypeByIndex(shapeData.splitTypeIndex)
				local v207_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).penaltyPerTree
				local v208_ = v205_ * 1000 * v206_.pricePerLiter
				local v209_ = math.max(v207_, v208_)
				self.wronglyCutDownTreesReward = self.wronglyCutDownTreesReward + v209_
				g_currentMission:broadcastEventToFarm(DeadwoodMissionWrongTreeEvent.new(), self.farmId, true)
			end
		end
	end
end

-- Local values: farmlandId
function DeadwoodMission:getIsShapeCutAllowed(shape, x, z, farmId)
	if self.farmId == farmId and g_farmlandManager:getFarmlandIdAtWorldPosition(x, z) == self.farmlandId then
		if self.status == MissionStatus.FINISHED then
			local v215_ = getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE)
			if v215_ then
				v215_ = getIsSplitShapeSplit(shape)
			end
			return v215_
		end
		if self.status == MissionStatus.RUNNING then
			return true
		end
	end
	return nil
end

function DeadwoodMission:getMissionTypeName()
	return DeadwoodMission.NAME
end

-- Local values: treeTypeName, treeDesc, spotFilename, i3dNode, data, root, i, spotNode, x, y, z, radius, farmlandId, isValidFarmland, spot, farmland
function DeadwoodMission.loadMapData(xmlFile, key, baseDirectory)
	if xmlFile:hasProperty(key) then
		local v219_ = xmlFile:getString(key .. "#treeType")
		local v220_ = g_treePlantManager:getTreeTypeDescFromName(v219_)
		if v220_ == nil then
			Logging.xmlWarning(xmlFile, "Missing or undefined treeType \'%s\' for deadwood mission (%s)!", v219_, key)
			return false
		end
		local v221_ = xmlFile:getString(key .. ".spots#filename")
		if v221_ == nil then
			Logging.xmlWarning(xmlFile, "Missing spot definition file for deadwood mission (%s)", key)
			return false
		end
		local v222_ = Utils.getFilename(v221_, baseDirectory)
		local v223_ = g_i3DManager:loadI3DFile(v222_, false, false)
		if v223_ == 0 then
			return false
		end
		local v224_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
		v224_.spots = {}
		v224_.spotsDisabled = {}
		v224_.activeMissions = {}
		v224_.maxNumInstances = xmlFile:getInt(key .. "#maxNumInstances") or 1
		v224_.treeIndex = v220_.index
		v224_.rewardPerTree = xmlFile:getFloat(key .. "#rewardPerTree") or 150
		v224_.penaltyPerTree = xmlFile:getFloat(key .. "#penaltyPerTree") or 2000
		v224_.deadwoodSplitTypeIndex = g_splitShapeManager:getSplitTypeIndexByName("DEADWOOD")
		local v225_ = getChildAt(v223_, 0)
		link(getRootNode(), v225_)
		for v226_ = 0, getNumOfChildren(v225_) - 1 do
			local v227_ = getChildAt(v225_, v226_)
			local v228_, v229_, v230_ = getTranslation(v227_)
			local v231_ = getUserAttribute
			local v232_ = tonumber(v231_(v227_, "radius"))
			if v232_ == nil then
				Logging.xmlWarning(xmlFile, "No radius defined for deadwood mission spot \'%s\'!", getName(v227_))
			else
				local v233_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v228_, v230_)
				local v234_
				if v233_ == nil then
					v234_ = false
				else
					v234_ = v233_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID
				end
				if v234_ then
					local v235_ = getTerrainHeightAtWorldPos(g_terrainNode, v228_, v229_, v230_)
					local v236_ = {
						["index"] = #v224_.spots + 1,
						["x"] = v228_,
						["y"] = v235_,
						["z"] = v230_,
						["radius"] = v232_,
						["isInUse"] = false,
						["farmlandId"] = v233_
					}
					local v237_ = v224_.spots
					table.insert(v237_, v236_)
				else
					local v238_ = v233_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID and "Not defined" or string.format("Not buyable (%d)", v233_)
					Logging.xmlWarning(xmlFile, "Invalid farmland \'%s\' found for deadwood mission spot \'%s\' at %d %d!", v238_, getName(v227_), v228_, v230_)
				end
			end
		end
		v224_.spotRoot = v225_
		delete(v223_)
		return true
	end
end
function DeadwoodMission.unloadMapData()
	local v239_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if v239_.spotRoot ~= nil then
		delete(v239_.spotRoot)
	end
end

-- Local values: data
function DeadwoodMission.loadMetaDataFromXMLFile(xmlFile, key)
	g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).nextMissionDay = xmlFile:getValue(key .. "#nextDay")
end

-- Local values: data
function DeadwoodMission.saveMetaDataToXMLFile(xmlFile, key)
	local v244_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if v244_.nextMissionDay ~= nil then
		xmlFile:setValue(key .. "#nextDay", v244_.nextMissionDay)
	end
end
function DeadwoodMission.onFinishCallback()
	g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME).treeCheck.isRunning = false
end

-- Local values: splitType, x, _, z, farmlandId, data, treeCheck
function DeadwoodMission.onTreeCallback(_, transformId, subShapeIndex, isLast)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) then
		local v247_ = getSplitType(transformId)
		if v247_ ~= 0 and not getIsSplitShapeSplit(transformId) then
			local v248_, _, v249_ = getWorldTranslation(transformId)
			local v250_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v248_, v249_)
			local v251_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
			local v252_ = v251_.treeCheck
			if v250_ == v252_.farmlandId then
				if v247_ == v251_.deadwoodSplitTypeIndex then
					local v253_ = v252_.preplacedDeadwood
					table.insert(v253_, transformId)
				else
					local v254_ = v252_.trees
					table.insert(v254_, transformId)
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
	if not DeadwoodMission.canRun() then
		return nil
	end
	local v255_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	local v256_ = v255_.treeCheck
	if v256_ ~= nil then
		if v256_.isRunning then
			return nil
		end
		local v257_ = nil
		if #v256_.trees + #v256_.preplacedDeadwood > 0 then
			v257_ = DeadwoodMission.new(true, g_client ~= nil)
			if v257_:init(v256_.spot, v256_.trees, v256_.preplacedDeadwood) then
				v257_:setEndDate(g_currentMission.environment.currentMonotonicDay + 2, MathUtil.hoursToMs(math.random(10, 18)))
			else
				v257_:delete()
				v257_ = nil
			end
		else
			log("disable spot: no trees found")
			v255_.spotsDisabled[v256_.spot] = true
		end
		v255_.treeCheck = nil
		return v257_
	end
	local v258_ = v255_.spots
	Utils.shuffle(v258_)
	local v259_ = {}
	for _, v260_ in ipairs(v255_.activeMissions) do
		v259_[v260_.spot.farmlandId] = true
	end
	local v261_ = nil
	for _, v262_ in ipairs(v258_) do
		if v255_.spotsDisabled[v262_] == nil and (not v262_.isInUse and (v259_[v262_.farmlandId] == nil and g_farmlandManager:getFarmlandOwner(v262_.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID)) then
			v261_ = v262_
			break
		end
	end
	if v261_ == nil then
		return nil
	end
	local v263_ = {
		["spot"] = v261_,
		["isRunning"] = true,
		["trees"] = {},
		["preplacedDeadwood"] = {},
		["farmlandId"] = v261_.farmlandId
	}
	local v264_ = v261_.x
	local v265_ = v261_.y
	local v266_ = v261_.z
	local v267_ = v261_.radius
	local v268_ = CollisionFlag.TREE
	local v269_ = v261_.height or 30
	overlapCylinderAsync(v264_, v265_, v266_, v267_, v269_, Axis.Y, "onTreeCallback", DeadwoodMission, v268_)
	v255_.treeCheck = v263_
	return nil
end
function DeadwoodMission.canRun()
	local v270_ = g_missionManager:getMissionTypeDataByName(DeadwoodMission.NAME)
	if v270_.spots == nil then
		return false
	elseif #v270_.spots == 0 then
		return false
	elseif v270_.treeIndex == nil then
		return false
	elseif v270_.numInstances >= v270_.maxNumInstances then
		return false
	else
		return v270_.nextMissionDay == nil or g_currentMission.environment.currentMonotonicDay >= v270_.nextMissionDay
	end
end
g_missionManager:registerMissionType(DeadwoodMission, DeadwoodMission.NAME, 1)
