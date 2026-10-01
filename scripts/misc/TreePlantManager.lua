TreePlantManager = {}
TreePlantManager.DECAY_INTERVAL = 60000
TreePlantManager.DECAY_DURATION = 7200000
TreePlantManager.DECAY_DURATION_INV = 1 / TreePlantManager.DECAY_DURATION
TreePlantManager.MAX_NUM_TYPES = 255
TreePlantManager.STAGE_NUM_BITS = 5
TreePlantManager.MAX_NUM_STAGES = TreePlantManager.STAGE_NUM_BITS ^ 2 - 1
TreePlantManager.VARIATION_NUM_BITS = 3
TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE = TreePlantManager.VARIATION_NUM_BITS ^ 2 - 1
local TreePlantManager_mt = Class(TreePlantManager, AbstractManager)
g_xmlManager:addInitSchemaFunction(function()
	local missionXMLSchema = Mission00.xmlSchema
	missionXMLSchema:register(XMLValueType.STRING, "map.treeTypes#filename", "")
	missionXMLSchema:register(XMLValueType.INT, "map.treeTypes#maxNumTrees", "", 8000)
end)
function TreePlantManager.new(customMt)
	local self = AbstractManager.new(customMt or TreePlantManager_mt)
	return self
end
function TreePlantManager:initDataStructures()
	self.treeTypes = {}
	self.indexToTreeType = {}
	self.splitTypeIndexToTreeType = {}
	self.nameToTreeType = {}
	self.treeFileCache = {}
	self.loadTreeTrunkDatas = {}
	self.numTreesWithoutSplits = 0
	self.activeDecayingSplitShapes = {}
	self.updateDecayDtGame = 0
end
function TreePlantManager:initialize()
	local rootNode = createTransformGroup("trees")
	link(getRootNode(), rootNode)
	self.treesData = {}
	self.treesData.rootNode = rootNode
	self.treesData.growingTrees = {}
	self.treesData.splitTrees = {}
	self.treesData.clientTrees = {}
	self.treesData.updateDtGame = 0
	self.treesData.treeCutJoints = {}
	self.treesData.numTreesWithoutSplits = 0
end
function TreePlantManager:deleteTreesData()
	if self.treesData ~= nil then
		delete(self.treesData.rootNode)
		self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - self.treesData.numTreesWithoutSplits, 0)
		self:initDataStructures()
	end
end
function TreePlantManager:loadDefaultTypes(missionInfo, baseDirectory)
	local xmlFile = loadXMLFile("treeTypes", "data/maps/maps_treeTypes.xml")
	self:loadTreeTypes(xmlFile, missionInfo, baseDirectory, true)
	delete(xmlFile)
end
function TreePlantManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	TreePlantManager:superClass().loadMapData(self)
	if g_server ~= nil and g_addCheatCommands then
		addConsoleCommand("gsTreeCut", "Cut all trees around a given radius", "consoleCommandCutTrees", self, "[radius]")
		addConsoleCommand("gsTreeAdd", "Load a loose tree trunk", "consoleCommandLoadTree", self, "length; treeType; [growthState]; [delimb]")
		addConsoleCommand("gsTreePlant", "Plant given number of trees of a specified type", "consoleCommandPlantTrees", self, "treeType; number; growthState; variationIndex; isGrowing")
		addConsoleCommand("gsTreeLoadAll", "Spawn all trees in front of player", "consoleCommandLoadAll", self)
		addConsoleCommand("gsTreeRemove", "Remove currently looked at split shape or tree", "consoleCommandRemoveSplitShape", self)
	end
	if g_addCheatCommands then
		addConsoleCommand("gsTreeDebug", "Toggle tree/splitshape debug mode", "consoleCommandDebug", self)
	end
	self.maxNumTrees = math.clamp(getXMLInt(xmlFile, "map.treeTypes#maxNumTrees") or 8000, 1, 30000)
	g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, TreePlantManager.onMissionStarted, self)
	self:loadDefaultTypes(missionInfo, baseDirectory)
	return XMLUtil.loadDataFromMapXML(xmlFile, "treeTypes", baseDirectory, self, self.loadTreeTypes, missionInfo, baseDirectory)
end
function TreePlantManager:unloadMapData()
	for i3dFilename, requestId in pairs(self.treeFileCache) do
		g_i3DManager:releaseSharedI3DFile(requestId)
		self.treeFileCache[i3dFilename] = true
	end
	removeConsoleCommand("gsTreeCut")
	removeConsoleCommand("gsTreeAdd")
	removeConsoleCommand("gsTreePlant")
	removeConsoleCommand("gsTreeLoadAll")
	removeConsoleCommand("gsTreeRemove")
	removeConsoleCommand("gsTreeDebug")
	self:deleteTreesData()
	g_messageCenter:unsubscribe(MessageType.CURRENT_MISSION_START, self)
	TreePlantManager:superClass().unloadMapData(self)
end
function TreePlantManager:onMissionStarted(isNewSavegame)
	local numTotal, numSplit = getNumOfSplitShapes()
	Logging.info("TreePlantManager - NumTrees %d (%d split) / MaxNumTrees: %d", numTotal, numSplit, self.maxNumTrees)
end
function TreePlantManager:loadTreeTypes(xmlFile, missionInfo, baseDirectory, isBaseType, customEnvironment)
	if type(xmlFile) == "number" then
		xmlFile = XMLFile.wrap(xmlFile)
	end
	for _, treeTypeKey in xmlFile:iterator("map.treeTypes.treeType") do
		local name = xmlFile:getString(treeTypeKey .. "#name")
		local title = xmlFile:getString(treeTypeKey .. "#title")
		local growthTimeHours = xmlFile:getString(treeTypeKey .. "#growthTimeHours")
		local splitTypeName = xmlFile:getString(treeTypeKey .. "#splitType")
		local supportsPlanting = xmlFile:getBool(treeTypeKey .. "#supportsPlanting", true)
		local saplingPrice = xmlFile:getFloat(treeTypeKey .. "#saplingPrice", 0)
		if name == nil then
			Logging.xmlWarning(xmlFile, "Missing 'name' attribute for treeType %q", treeTypeKey)
		elseif title == nil then
			Logging.xmlWarning(xmlFile, "Missing 'title' attribute for treeType %q", treeTypeKey)
		elseif growthTimeHours == nil then
			Logging.xmlWarning(xmlFile, "Missing 'growthTimeHours' attribute for treeType %q", treeTypeKey)
		elseif splitTypeName == nil then
			Logging.xmlWarning(xmlFile, "Missing 'splitType' attribute for treeType %q", treeTypeKey)
		else
			local splitTypeIndex = g_splitShapeManager:getSplitTypeIndexByName(splitTypeName)
			if splitTypeIndex == nil then
				Logging.xmlWarning(xmlFile, "SplitType '%s' not defined for treeType %q", splitTypeName, treeTypeKey)
			else
				local stages = {}
				for _, stageKey in xmlFile:iterator(treeTypeKey .. ".stage") do
					local filename = xmlFile:getString(stageKey .. "#filename")
					if filename ~= nil then
						local variation = {}
						variation.filename = Utils.getFilename(filename, baseDirectory)
						local palletFilename = xmlFile:getString(stageKey .. ".pallet#filename")
						if palletFilename ~= nil then
							variation.palletFilename = Utils.getFilename(palletFilename, baseDirectory)
						end
						local palletStoreItemFilename = xmlFile:getString(stageKey .. ".pallet#storeItem")
						if palletStoreItemFilename ~= nil then
							variation.palletStoreItemFilename = Utils.getFilename(palletStoreItemFilename, baseDirectory)
						end
						local planterFilename = xmlFile:getString(stageKey .. ".planter#filename")
						if planterFilename ~= nil then
							variation.planterFilename = Utils.getFilename(planterFilename, baseDirectory)
						end
						table.insert(stages, { variation })
					else
						local variations = {}
						for _, variationKey in xmlFile:iterator(stageKey .. ".variation") do
							filename = xmlFile:getString(variationKey .. "#filename")
							if filename == nil then
								continue
							end
							if TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE <= #variations then
								Logging.xmlWarning(xmlFile, "Unable to add variation %q for tree %q, max number of variations per stage (%d) reached", filename, name, TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE)
								break
							end
							local variation = {}
							variation.name = xmlFile:getString(variationKey .. "#name")
							variation.filename = Utils.getFilename(filename, baseDirectory)
							local palletFilename = xmlFile:getString(variationKey .. ".pallet#filename")
							if palletFilename ~= nil then
								variation.palletFilename = Utils.getFilename(palletFilename, baseDirectory)
							end
							local palletStoreItemFilename = xmlFile:getString(variationKey .. ".pallet#storeItem")
							if palletStoreItemFilename ~= nil then
								variation.palletStoreItemFilename = Utils.getFilename(palletStoreItemFilename, baseDirectory)
							end
							local planterFilename = xmlFile:getString(variationKey .. ".planter#filename")
							if planterFilename ~= nil then
								variation.planterFilename = Utils.getFilename(planterFilename, baseDirectory)
							end
							table.insert(variations, variation)
						end
						if TreePlantManager.MAX_NUM_STAGES <= #stages then
							Logging.xmlWarning(xmlFile, "Unable to add stage %q for tree %q, max number of stages (%d) reached", stageKey, name, TreePlantManager.MAX_NUM_STAGES)
							break
						end
						table.insert(stages, variations)
					end
				end
				if #stages == 0 then
					Logging.xmlWarning(xmlFile, "A treetype %q (%s) has no valid stages defined'", name, treeTypeKey)
				else
					title = g_i18n:convertText(title, customEnvironment)
					self:registerTreeType(name, title, stages, growthTimeHours, isBaseType, splitTypeIndex, supportsPlanting, saplingPrice)
				end
			end
		end
	end
	return true
end
function TreePlantManager:registerTreeType(name, title, stages, growthTimeHours, isBaseType, splitTypeIndex, supportsPlanting, saplingPrice)
	name = string.upper(name)
	if TreePlantManager.MAX_NUM_TYPES <= #self.treeTypes then
		Logging.warning("Unable to register tree type %q, maximum number of tree types (%d) reached", name, TreePlantManager.MAX_NUM_TYPES)
		return nil
	elseif isBaseType and self.nameToTreeType[name] ~= nil then
		Logging.warning("TreeType %q already exists. Ignoring treeType!", name)
		return nil
	else
		local treeType = self.nameToTreeType[name]
		if treeType == nil then
			treeType = {}
			treeType.name = name
			treeType.title = title
			treeType.index = #self.treeTypes + 1
			treeType.splitTypeIndex = splitTypeIndex
			table.insert(self.treeTypes, treeType)
			self.indexToTreeType[treeType.index] = treeType
			self.nameToTreeType[name] = treeType
			self.splitTypeIndexToTreeType[splitTypeIndex] = treeType
		end
		treeType.stages = stages
		treeType.growthTimeHours = growthTimeHours
		treeType.supportsPlanting = supportsPlanting
		if supportsPlanting then
			treeType.saplingPrice = saplingPrice
		end
		return treeType
	end
end
function TreePlantManager:getTreeTypeFilename(treeTypeDesc, growthStateI)
	if treeTypeDesc == nil then
		return nil
	else
		local stage = treeTypeDesc.stages[math.min(growthStateI, #treeTypeDesc.stages)]
		local variation = stage[math.random(1, #stage)]
		return variation.filename
	end
end
function TreePlantManager:canPlantTree()
	local totalNumSplit, numSplit = getNumOfSplitShapes()
	local numUnsplit = totalNumSplit - numSplit
	return numUnsplit + self.numTreesWithoutSplits < self.maxNumTrees
end
function TreePlantManager:plantTree(treeTypeIndex, x, y, z, rx, ry, rz, growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, existingSplitShapeFileId)
	local treeTypeDesc = self.indexToTreeType[treeTypeIndex]
	if treeTypeDesc == nil then
		return nil
	end
	local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, existingSplitShapeFileId)
	if treeId == 0 then
		return nil
	else
		local treesData = self.treesData
		local tree = {}
		tree.node = treeId
		tree.growthStateI = growthStateI
		tree.variationIndex = variationIndex or 1
		tree.isGrowing = Utils.getNoNil(isGrowing, true) and growthStateI < #treeTypeDesc.stages
		tree.x = x
		tree.y = y
		tree.z = z
		tree.rx = rx
		tree.ry = ry
		tree.rz = rz
		tree.treeType = treeTypeIndex
		tree.splitShapeFileId = splitShapeFileId
		tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
		if tree.isGrowing then
			tree.origSplitShape = getChildAt(treeId, 0)
			if nextGrowthTargetHour == nil then
				tree.nextGrowthTargetHour = g_currentMission.environment:getMonotonicHour() + treeTypeDesc.growthTimeHours
			else
				tree.nextGrowthTargetHour = nextGrowthTargetHour
			end
			table.insert(treesData.growingTrees, tree)
		else
			table.insert(treesData.splitTrees, tree)
		end
		if not tree.hasSplitShapes then
			self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
			treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
		end
		g_server:broadcastEvent(TreePlantEvent.new(treeTypeIndex, x, y, z, rx, ry, rz, growthStateI, tree.variationIndex, splitShapeFileId, tree.isGrowing))
		return treeId
	end
end
function TreePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeLoadingFileId)
	local treesData = self.treesData
	local stage = math.min(growthStateI, #treeTypeDesc.stages)
	local variations = treeTypeDesc.stages[stage]
	if variations == nil then
		Logging.error("TreePlantManager:loadTreeNode failed due to invalid stage index (stage %d of %d)", stage, #treeTypeDesc.stages)
		return 0
	else
		local variation = variations[math.clamp(variationIndex, 1, #variations)]
		local i3dFilename = variation.filename
		if self.treeFileCache[i3dFilename] == nil then
			setSplitShapesLoadingFileId(-1)
			setSplitShapesNextFileId(true)
			local node, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
			if node ~= 0 then
				delete(node)
				self.treeFileCache[i3dFilename] = requestId
			end
		end
		setSplitShapesLoadingFileId(splitShapeLoadingFileId or -1)
		local splitShapeFileId = setSplitShapesNextFileId()
		local treeId, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
		g_i3DManager:releaseSharedI3DFile(requestId)
		if treeId ~= 0 then
			link(treesData.rootNode, treeId)
			setTranslation(treeId, x, y, z)
			setRotation(treeId, rx, ry, rz)
			local numChildren = getNumOfChildren(treeId)
			for i = 0, numChildren - 1 do
				local child = getChildAt(treeId, i)
				if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) and getIsSplitShapeSplit(child) then
					setWorldRotation(child, getRotation(child))
					setWorldTranslation(child, getTranslation(child))
				end
			end
			I3DUtil.iterateRecursively(treeId, function(node, _)
				if getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
					local splitTypeIndex = getSplitType(node)
					if splitTypeIndex ~= treeTypeDesc.splitTypeIndex then
						Logging.warning("Tree has wrong splitType '%s' assigned. Should be '%s'. File: '%s'", splitTypeIndex, treeTypeDesc.splitTypeIndex, i3dFilename)
					end
					if g_server == nil and getRigidBodyType(node) == RigidBodyType.DYNAMIC then
						setRigidBodyType(node, RigidBodyType.KINEMATIC)
					end
				end
				return true
			end)
			addToPhysics(treeId)
		end
		local updateRange = 2
		g_densityMapHeightManager:setCollisionMapAreaDirty(x - 2, z - 2, x + 2, z + 2, true)
		g_currentMission.aiSystem:setAreaDirty(x - 2, x + 2, z - 2, z + 2)
		return treeId, splitShapeFileId
	end
end
function TreePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthStateI, variationIndex, delimb, useOnlyStump)
	local treeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, 0, 0, 0, growthStateI, variationIndex)
	if treeId ~= 0 then
		if getFileIdHasSplitShapes(splitShapeFileId) then
			local tree = {}
			tree.node = treeId
			tree.growthStateI = growthStateI
			tree.variationIndex = variationIndex
			tree.x = x
			tree.y = y
			tree.z = z
			tree.rx = 0
			tree.ry = 0
			tree.rz = 0
			tree.treeType = treeTypeDesc.index
			tree.splitShapeFileId = splitShapeFileId
			tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
			table.insert(self.treesData.splitTrees, tree)
			local loadTreeTrunkData = { framesLeft = 2, shape = treeId + 2, x = x, y = y, z = z, length = length, offset = 0.5, dirX = dirX, dirY = dirY, dirZ = dirZ, delimb = delimb, useOnlyStump = useOnlyStump, cutTreeTrunkCallback = TreePlantManager.cutTreeTrunkCallback }
			table.insert(self.loadTreeTrunkDatas, loadTreeTrunkData)
			return
		end
		delete(treeId)
	end
end
function TreePlantManager.cutTreeTrunkCallback(loadTreeTrunkData, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	g_treePlantManager:addingSplitShape(shape, loadTreeTrunkData.shapeBeingCut)
	table.insert(loadTreeTrunkData.parts, { shape = shape, isBelow = isBelow, isAbove = isAbove, minY = minY, maxY = maxY, minZ = minZ, maxZ = maxZ })
end
function TreePlantManager:updateTrees(dt, dtGame)
	local treesData = self.treesData
	treesData.updateDtGame = treesData.updateDtGame + dtGame
	if 3600000 < treesData.updateDtGame then
		self:cleanupDeletedTrees()
		treesData.updateDtGame = 0
		local currentMonotonicHour = g_currentMission.environment:getMonotonicHour()
		local numGrowingTrees = #treesData.growingTrees
		local i = 1
		while i <= numGrowingTrees do
			local tree = treesData.growingTrees[i]
			if getChildAt(tree.node, 0) ~= tree.origSplitShape then
				if self.debugActive then
					Logging.info("Removing cut tree %d from growing trees", tree.node)
				end
				table.remove(treesData.growingTrees, i)
				numGrowingTrees = numGrowingTrees - 1
				tree.origSplitShape = nil
				table.insert(treesData.splitTrees, tree)
			else
				local treeTypeDesc = self.indexToTreeType[tree.treeType]
				local numStages = #treeTypeDesc.stages
				if tree.nextGrowthTargetHour < currentMonotonicHour then
					local growthStateNew = math.min(tree.growthStateI + 1, #treeTypeDesc.stages)
					if self.debugActive then
						Logging.info("growing tree %s from stage %d to %d", treeTypeDesc.name, tree.growthStateI, growthStateNew)
					end
					tree.growthStateI = growthStateNew
					if numStages <= tree.growthStateI then
						tree.nextGrowthTargetHour = nil
					else
						tree.nextGrowthTargetHour = currentMonotonicHour + treeTypeDesc.growthTimeHours
					end
					delete(tree.node)
					if not tree.hasSplitShapes then
						self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
						treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
					end
					local variations = treeTypeDesc.stages[tree.growthStateI]
					tree.variationIndex = math.random(1, #variations)
					local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthStateI, tree.variationIndex, -1)
					g_server:broadcastEvent(TreeGrowEvent.new(tree.treeType, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthStateI, tree.variationIndex, splitShapeFileId, tree.splitShapeFileId))
					tree.origSplitShape = getChildAt(treeId, 0)
					tree.splitShapeFileId = splitShapeFileId
					tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
					tree.node = treeId
					local range = 2.5
					local x, _, z = getWorldTranslation(treeId)
					g_densityMapHeightManager:setCollisionMapAreaDirty(x - 2.5, z - 2.5, x + 2.5, z + 2.5, true)
					g_currentMission.aiSystem:setAreaDirty(x - 2.5, x + 2.5, z - 2.5, z + 2.5)
					if not tree.hasSplitShapes then
						self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
						treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
					end
				end
				if numStages <= tree.growthStateI then
					if self.debugActive then
						Logging.info("Removing fully grown tree %d (%s stage %d) from growth", tree.node, treeTypeDesc.name, tree.growthStateI)
					end
					table.remove(treesData.growingTrees, i)
					numGrowingTrees = numGrowingTrees - 1
					tree.origSplitShape = nil
					table.insert(treesData.splitTrees, tree)
				else
					i = i + 1
				end
			end
		end
	end
	local curTime = g_currentMission.time
	for joint in pairs(treesData.treeCutJoints) do
		if joint.destroyTime <= curTime or not entityExists(joint.shape) then
			removeJoint(joint.jointIndex)
			treesData.treeCutJoints[joint] = nil
		else
			local x1, y1, z1 = localDirectionToWorld(joint.shape, joint.lnx, joint.lny, joint.lnz)
			if x1 * joint.nx + y1 * joint.ny + z1 * joint.nz < joint.maxCosAngle then
				removeJoint(joint.jointIndex)
				treesData.treeCutJoints[joint] = nil
			end
		end
	end
	if 0 < #self.loadTreeTrunkDatas then
		for i = #self.loadTreeTrunkDatas, 1, -1 do
			local loadTreeTrunkData = self.loadTreeTrunkDatas[i]
			loadTreeTrunkData.framesLeft = loadTreeTrunkData.framesLeft - 1
			if loadTreeTrunkData.framesLeft == 1 then
				local nx = 0
				local ny = 1
				local nz = 0
				local yx = -1
				local yy = 0
				local yz = 0
				local x = loadTreeTrunkData.x + 1
				local y = loadTreeTrunkData.y
				local z = loadTreeTrunkData.z - 1
				loadTreeTrunkData.parts = {}
				local shape = loadTreeTrunkData.shape
				if shape == nil or shape == 0 then
					continue
				end
				loadTreeTrunkData.shapeBeingCut = shape
				splitShape(shape, x, y + loadTreeTrunkData.length + loadTreeTrunkData.offset, z, 0, 1, 0, -1, 0, 0, 4, 4, "cutTreeTrunkCallback", loadTreeTrunkData)
				self:removingSplitShape(shape)
				for _, p in pairs(loadTreeTrunkData.parts) do
					if p.isAbove then
						delete(p.shape)
					else
						loadTreeTrunkData.shape = p.shape
					end
				end
			elseif loadTreeTrunkData.framesLeft == 0 then
				local nx = 0
				local ny = 1
				local nz = 0
				local yx = -1
				local yy = 0
				local yz = 0
				local x = loadTreeTrunkData.x + 1
				local y = loadTreeTrunkData.y
				local z = loadTreeTrunkData.z - 1
				loadTreeTrunkData.parts = {}
				local shape = loadTreeTrunkData.shape
				if shape ~= nil and shape ~= 0 then
					local cutDiameter = 2.5
					splitShape(shape, x, y + loadTreeTrunkData.offset, z, 0, 1, 0, -1, 0, 0, 5, 5, "cutTreeTrunkCallback", loadTreeTrunkData)
					if loadTreeTrunkData.useOnlyStump then
						for _, p in pairs(loadTreeTrunkData.parts) do
							if p.isBelow then
								continue
							end
							delete(p.shape)
						end
					else
						local finalShape = nil
						for _, p in pairs(loadTreeTrunkData.parts) do
							if p.isBelow then
								delete(p.shape)
							else
								finalShape = p.shape
							end
						end
						if finalShape ~= nil then
							if loadTreeTrunkData.delimb then
								removeSplitShapeAttachments(finalShape, x, y + loadTreeTrunkData.offset, z, 0, 1, 0, -1, 0, 0, loadTreeTrunkData.length, 4, 4)
							end
							removeFromPhysics(finalShape)
							setDirection(finalShape, 0, -1, 0, loadTreeTrunkData.dirX, loadTreeTrunkData.dirY, loadTreeTrunkData.dirZ)
							addToPhysics(finalShape)
						else
							Logging.error("Unable to cut tree trunk with length '%s'. Try using a different value", loadTreeTrunkData.length)
						end
					end
				end
				table.remove(self.loadTreeTrunkDatas, i)
			end
		end
	end
	if self.commandCutTreeData ~= nil then
		if 0 < #self.commandCutTreeData.trees then
			local treeId = self.commandCutTreeData.trees[1]
			local x, y, z = getWorldTranslation(treeId)
			local localX, localY, localZ = worldToLocal(treeId, x, y + 0.5, z)
			local cx, cy, cz = localToWorld(treeId, localX - 2, localY, localZ - 2)
			local nx, ny, nz = localDirectionToWorld(treeId, 0, 1, 0)
			local yx, yy, yz = localDirectionToWorld(treeId, 0, 0, 1)
			self.commandCutTreeData.shapeBeingCut = treeId
			Logging.info("Cut tree '%s' (%d left)", getName(treeId), #self.commandCutTreeData.trees - 1)
			splitShape(treeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, 4, 4, "onTreeCutCommandSplitCallback", self)
			table.remove(self.commandCutTreeData.trees, 1)
		else
			self.commandCutTreeData = nil
		end
	end
	self.updateDecayDtGame = self.updateDecayDtGame + dtGame
	if TreePlantManager.DECAY_INTERVAL < self.updateDecayDtGame then
		for shape, data in pairs(self.activeDecayingSplitShapes) do
			if not entityExists(shape) then
				self.activeDecayingSplitShapes[shape] = nil
			elseif 0 < data.state then
				local newState = math.max(data.state - TreePlantManager.DECAY_DURATION_INV * self.updateDecayDtGame, 0)
				self:setSplitShapeLeafScaleAndVariation(shape, newState, data.variation)
				self.activeDecayingSplitShapes[shape].state = newState
			end
		end
		self.updateDecayDtGame = 0
	end
end
function TreePlantManager:drawDebug()
	if self.treesData == nil or self.treesData.growingTrees == nil then
		return
	end
	for index, tree in ipairs(self.treesData.growingTrees) do
		local treeTypeDesc = self.indexToTreeType[tree.treeType]
		DebugText.renderAtNode(tree.node, string.format("growingTree #%d\ntype %s\ngrowthStateI %d\nvariation %d\nnextGrowthTargetHour %.2f", index, treeTypeDesc.name, tree.growthStateI, tree.variationIndex, tree.nextGrowthTargetHour), Color.PRESETS.GREEN, 0.01)
	end
	for index, tree in ipairs(self.treesData.splitTrees) do
		local treeTypeDesc = self.indexToTreeType[tree.treeType]
		DebugText.renderAtNode(tree.node, string.format("splitTree #%d\ntype %s\ngrowthStateI %d\nvariation %d\n", index, treeTypeDesc.name, tree.growthStateI, tree.variationIndex), nil, 0.01)
	end
	for serverSplitShapeFileId, nodeId in pairs(self.treesData.clientTrees) do
		local rigidBodyType = EnumUtil.getName(RigidBodyType, self:getTreeRigidBodyType(nodeId) or RigidBodyType.NONE)
		DebugText.renderAtNode(nodeId, string.format("clientTree\nserverSplitShapeFileId %s\nnodeId %s|%s\nRigidBodyType %s", serverSplitShapeFileId, nodeId, getName(nodeId), rigidBodyType), nil, 0.01)
	end
end
function TreePlantManager:addTreeCutJoint(jointIndex, shape, nx, ny, nz, maxAngle, maxLifetime)
	local treesData = self.treesData
	local lnx, lny, lnz = worldDirectionToLocal(shape, nx, ny, nz)
	local joint = { jointIndex = jointIndex, shape = shape, nx = nx, ny = ny, nz = nz, lnx = lnx, lny = lny, lnz = lnz }
	joint.maxCosAngle = math.cos(maxAngle)
	joint.destroyTime = g_currentMission.time + maxLifetime
	treesData.treeCutJoints[joint] = joint
end
function TreePlantManager:getIsTreeDeleted(node)
	for i = 1, getNumOfChildren(node) do
		local child = getChildAt(node, i - 1)
		if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) or getHasClassId(child, ClassIds.SHAPE) then
			return false
		end
		if self:getIsTreeDeleted(child) then
			continue
		end
		return false
	end
	return true
end
function TreePlantManager:getTreeRigidBodyType(node)
	for i = 1, getNumOfChildren(node) do
		local child = getChildAt(node, i - 1)
		if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) then
			return getRigidBodyType(child)
		end
		local rigidBodyType = self:getTreeRigidBodyType(child)
		if rigidBodyType == nil then
			continue
		end
		return rigidBodyType
	end
	return nil
end
function TreePlantManager:cleanupDeletedTrees()
	local treesData = self.treesData
	local numGrowingTrees = #treesData.growingTrees
	local growingTreeIndex = 1
	while growingTreeIndex <= numGrowingTrees do
		local tree = treesData.growingTrees[growingTreeIndex]
		if self:getIsTreeDeleted(tree.node) then
			table.remove(treesData.growingTrees, growingTreeIndex)
			numGrowingTrees = numGrowingTrees - 1
			delete(tree.node)
			if tree.hasSplitShapes then
				continue
			end
			self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
			treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
		else
			growingTreeIndex = growingTreeIndex + 1
		end
	end
	local numSplitTrees = #treesData.splitTrees
	local splitTreeIndex = 1
	while splitTreeIndex <= numSplitTrees do
		local tree = treesData.splitTrees[splitTreeIndex]
		if self:getIsTreeDeleted(tree.node) then
			table.remove(treesData.splitTrees, splitTreeIndex)
			numSplitTrees = numSplitTrees - 1
			delete(tree.node)
			if tree.hasSplitShapes then
				continue
			end
			self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
			treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
		else
			splitTreeIndex = splitTreeIndex + 1
		end
	end
end
function TreePlantManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local xmlFile = loadXMLFile("treePlantXML", xmlFilename)
	if xmlFile == 0 then
		return false
	else
		local i = 0
		while true do
			local key = string.format("treePlant.tree(%d)", i)
			if not hasXMLProperty(xmlFile, key) then
				break
			end
			local treeTypeName = getXMLString(xmlFile, key .. "#treeType")
			local treeType = self.nameToTreeType[treeTypeName]
			local pos = string.getVector(getXMLString(xmlFile, key .. "#position"), 3)
			local rot = string.getRadians(getXMLString(xmlFile, key .. "#rotation"), 3)
			if #pos == 3 and (#rot == 3 and treeType ~= nil) then
				local growthStateI = getXMLInt(xmlFile, key .. "#growthStateI")
				local variationIndex = getXMLInt(xmlFile, key .. "#variationIndex") or 1
				local nextGrowthTargetHour = getXMLFloat(xmlFile, key .. "#nextGrowthTargetHour")
				local isGrowing = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isGrowing"), true)
				local splitShapeFileId = getXMLInt(xmlFile, key .. "#splitShapeFileId")
				self:plantTree(treeType.index, pos[1], pos[2], pos[3], rot[1], rot[2], rot[3], growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, splitShapeFileId)
			end
			i = i + 1
		end
		delete(xmlFile)
		return true
	end
end
function TreePlantManager:saveToXMLFile(xmlFilename)
	self:cleanupDeletedTrees()
	local xmlFile = createXMLFile("treePlantXML", xmlFilename, "treePlant")
	if xmlFile == 0 then
		Logging.error("Failed to create xml file %q", xmlFilename)
		return false
	else
		local saveTreeToXML = function(tree, xmlIndex)
			local treeTypeDesc = self:getTreeTypeDescFromIndex(tree.treeType)
			local treeTypeName = treeTypeDesc.name
			local isGrowing = getChildAt(tree.node, 0) == tree.origSplitShape
			local splitShapeFileId = tree.splitShapeFileId or -1
			local treeKey = string.format("treePlant.tree(%d)", xmlIndex)
			setXMLString(xmlFile, treeKey .. "#treeType", treeTypeName)
			setXMLString(xmlFile, treeKey .. "#position", string.format("%.4f %.4f %.4f", tree.x, tree.y, tree.z))
			setXMLString(xmlFile, treeKey .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(tree.rx), math.deg(tree.ry), math.deg(tree.rz)))
			setXMLInt(xmlFile, treeKey .. "#growthStateI", tree.growthStateI)
			if tree.variationIndex ~= 1 then
				setXMLInt(xmlFile, treeKey .. "#variationIndex", tree.variationIndex)
			end
			if tree.nextGrowthTargetHour ~= nil then
				setXMLFloat(xmlFile, treeKey .. "#nextGrowthTargetHour", tree.nextGrowthTargetHour)
			end
			setXMLBool(xmlFile, treeKey .. "#isGrowing", isGrowing)
			setXMLInt(xmlFile, treeKey .. "#splitShapeFileId", splitShapeFileId)
		end
		local index = 0
		for _, tree in ipairs(self.treesData.growingTrees) do
			saveTreeToXML(tree, index)
			index = index + 1
		end
		for _, tree in ipairs(self.treesData.splitTrees) do
			saveTreeToXML(tree, index)
			index = index + 1
		end
		saveXMLFile(xmlFile)
		delete(xmlFile)
		return true
	end
end
function TreePlantManager:readFromServerStream(streamId)
	local treesData = self.treesData
	local numTrees = streamReadInt32(streamId)
	for i = 1, numTrees do
		local treeType = streamReadUInt8(streamId)
		local x = streamReadFloat32(streamId)
		local y = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)
		local rx = streamReadFloat32(streamId)
		local ry = streamReadFloat32(streamId)
		local rz = streamReadFloat32(streamId)
		local growthStateI = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
		local variationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
		local serverSplitShapeFileId = streamReadInt32(streamId)
		local treeTypeDesc = self.indexToTreeType[treeType]
		if treeTypeDesc == nil then
			continue
		end
		local nodeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, -1)
		setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
		treesData.clientTrees[serverSplitShapeFileId] = nodeId
	end
end
function TreePlantManager:writeToClientStream(streamId)
	local treesData = self.treesData
	self:cleanupDeletedTrees()
	local numTrees = #treesData.growingTrees + #treesData.splitTrees
	streamWriteInt32(streamId, numTrees)
	for _, tree in ipairs(treesData.growingTrees) do
		streamWriteUInt8(streamId, tree.treeType)
		streamWriteFloat32(streamId, tree.x)
		streamWriteFloat32(streamId, tree.y)
		streamWriteFloat32(streamId, tree.z)
		streamWriteFloat32(streamId, tree.rx)
		streamWriteFloat32(streamId, tree.ry)
		streamWriteFloat32(streamId, tree.rz)
		streamWriteUIntN(streamId, tree.growthStateI, TreePlantManager.STAGE_NUM_BITS)
		streamWriteUIntN(streamId, tree.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
		streamWriteInt32(streamId, tree.splitShapeFileId)
	end
	for _, tree in ipairs(treesData.splitTrees) do
		streamWriteUInt8(streamId, tree.treeType)
		streamWriteFloat32(streamId, tree.x)
		streamWriteFloat32(streamId, tree.y)
		streamWriteFloat32(streamId, tree.z)
		streamWriteFloat32(streamId, tree.rx)
		streamWriteFloat32(streamId, tree.ry)
		streamWriteFloat32(streamId, tree.rz)
		streamWriteUIntN(streamId, tree.growthStateI, TreePlantManager.STAGE_NUM_BITS)
		streamWriteUIntN(streamId, tree.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
		streamWriteInt32(streamId, tree.splitShapeFileId)
	end
end
function TreePlantManager:getTreeTypeDescFromIndex(index)
	if self.treeTypes ~= nil then
		return self.treeTypes[index]
	else
		return nil
	end
end
function TreePlantManager:getTreeTypeNameFromIndex(index)
	if self.treeTypes ~= nil and self.treeTypes[index] ~= nil then
		return self.treeTypes[index].name
	end
	return nil
end
function TreePlantManager:getTreeTypeDescFromName(name)
	if self.nameToTreeType ~= nil and name ~= nil then
		name = string.upper(name)
		return self.nameToTreeType[name]
	end
	return nil
end
function TreePlantManager:getTreeTypeIndexAndVariationFromName(name, stageIndex, variationName)
	if self.nameToTreeType ~= nil and name ~= nil then
		name = string.upper(name)
		local treeTypeDesc = self.nameToTreeType[name]
		if treeTypeDesc ~= nil then
			local stage = treeTypeDesc.stages[stageIndex]
			if stage ~= nil then
				local variationIndex = nil
				for index, variation in ipairs(stage) do
					if string.lower(variation.name or "DEFAULT") == string.lower(variationName or "DEFAULT") then
						variationIndex = index
						break
					end
				end
				return treeTypeDesc.index, variationIndex
			end
		end
	end
	return nil, nil
end
function TreePlantManager:getTreeTypeNameAndVariationByIndex(treeTypeIndex, stageIndex, variationIndex)
	if self.treeTypes ~= nil then
		local treeTypeDesc = self.treeTypes[treeTypeIndex]
		if treeTypeDesc ~= nil then
			local variations = treeTypeDesc.stages[stageIndex or 1]
			if variations ~= nil then
				local variation = variations[variationIndex] or variations[1]
				if variation ~= nil then
					return treeTypeDesc.name, variation.name or "DEFAULT"
				end
			end
		end
	end
	return nil, nil
end
function TreePlantManager:getPalletStoreItemFilenameByIndex(treeTypeIndex, stageIndex, variationIndex)
	if self.treeTypes ~= nil then
		local treeTypeDesc = self.treeTypes[treeTypeIndex]
		if treeTypeDesc ~= nil then
			local variations = treeTypeDesc.stages[stageIndex or 1]
			if variations ~= nil then
				local variation = variations[variationIndex] or variations[1]
				if variation ~= nil then
					return variation.palletStoreItemFilename
				end
			end
		end
	end
	return nil
end
function TreePlantManager:getTreeTypeDescFromSplitType(splitTypeIndex)
	if self.splitTypeIndexToTreeType ~= nil and splitTypeIndex ~= nil then
		return self.splitTypeIndexToTreeType[splitTypeIndex]
	end
	return nil
end
function TreePlantManager:getTreeTypeIndexFromName(name)
	if self.nameToTreeType ~= nil and name ~= nil then
		name = string.upper(name)
		if self.nameToTreeType[name] ~= nil then
			return self.nameToTreeType[name].index
		end
	end
	return nil
end
function TreePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
	if self.treesData ~= nil then
		self.treesData.clientTrees[serverSplitShapeFileId] = nodeId
	end
end
function TreePlantManager:removeClientTree(serverSplitShapeFileId)
	if self.treesData ~= nil then
		self.treesData.clientTrees[serverSplitShapeFileId] = nil
	end
end
function TreePlantManager:getClientTree(serverSplitShapeFileId)
	if self.treesData ~= nil then
		return self.treesData.clientTrees[serverSplitShapeFileId]
	else
		return nil
	end
end
function TreePlantManager:addingSplitShape(shape, oldShape, fromTree)
	local state = nil
	local variation = nil
	if oldShape ~= nil then
		if self.activeDecayingSplitShapes[oldShape] ~= nil then
			state = self.activeDecayingSplitShapes[oldShape].state
			variation = self.activeDecayingSplitShapes[oldShape].variation
		elseif fromTree then
			state = 1
			local x, y, z = getWorldTranslation(shape)
			variation = math.abs(x) + math.abs(y) + math.abs(z)
		else
			state = 0
			variation = 80
		end
	end
	if state ~= nil and 0 < getNumOfChildren(shape) then
		self.activeDecayingSplitShapes[shape] = { state = state, variation = variation }
		self:setSplitShapeLeafScaleAndVariation(shape, state, variation)
	end
	g_messageCenter:publish(MessageType.TREE_SHAPE_CUT, oldShape, shape)
end
function TreePlantManager:removingSplitShape(shape)
	self.activeDecayingSplitShapes[shape] = nil
end
function TreePlantManager:replaceWithTreeType(node, treeTypeIndex)
	local treeType = self:getTreeTypeDescFromIndex(treeTypeIndex)
	if treeType == nil then
		return nil
	else
		local x, y, z = getWorldTranslation(node)
		local rx, ry, rz = getWorldRotation(node)
		local treeIndex = treeType.index
		local newTreeNode = self:plantTree(treeIndex, x, y, z, rx, ry, rz, 1, 1, false)
		if newTreeNode ~= nil then
			delete(node)
		end
		return newTreeNode
	end
end
function TreePlantManager:setSplitShapeLeafScaleAndVariation(shape, scale, variation)
	setShaderParameterRecursive(shape, "windSnowLeafScale", 0, 0, scale, variation, false)
end
function TreePlantManager:consoleCommandCutTrees(radius)
	radius = tonumber(radius) or 50
	self.commandCutTreeData = {}
	self.commandCutTreeData.trees = {}
	local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	overlapSphere(x, y, z, radius, "onTreeCutCommandOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	return string.format("Found %d trees to cut in a %dm radius", #self.commandCutTreeData.trees, radius)
end
function TreePlantManager:onTreeCutCommandOverlapCallback(objectId, ...)
	if getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(objectId) ~= 0 and (getRigidBodyType(objectId) == RigidBodyType.STATIC and not getIsSplitShapeSplit(objectId))) then
		table.insert(self.commandCutTreeData.trees, objectId)
	end
end
function TreePlantManager:onTreeCutCommandSplitCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	rotate(shape, 0.1, 0, 0)
	g_currentMission:addKnownSplitShape(shape)
	self:addingSplitShape(shape, self.commandCutTreeData.shapeBeingCut, true)
end
function TreePlantManager:consoleCommandLoadTree(length, treeType, growthStage, delimb)
	local x, y, z = g_localPlayer:getPosition()
	local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
	x = x + dirX * 4
	z = z + dirZ * 4
	y = y + 1
	if Platform.isMobile then
		local amount = tonumber(length)
		if amount == nil then
			return "No amount given. (gsTreeAdd amount)"
		else
			WoodHarvesterLight.spawnLogs("data/maps/trees/logs/pineLog.i3d", amount, x, y, z, MathUtil.getYRotationFromDirection(dirX, dirZ), 0.4, 5, self:getFarmId())
			return "Spawned log(s)"
		end
	else
		length = tonumber(length)
		local usage = "gsTreeAdd length [type (available: " .. table.concatKeys(self.nameToTreeType, " ") .. ")] [growthStage] [delimb true/false]"
		if length == nil then
			return "No length given. " .. usage
		end
		if treeType == nil then
			treeType = "beech"
			growthStage = 7
		end
		local treeTypeDesc = self:getTreeTypeDescFromName(treeType)
		if treeTypeDesc == nil then
			return "Invalid tree type. " .. usage
		else
			growthStage = tonumber(growthStage) or #treeTypeDesc.stages
			growthStage = math.clamp(growthStage, 1, #treeTypeDesc.stages)
			local variationIndex = math.random(1, #treeTypeDesc.stages[growthStage])
			delimb = Utils.stringToBoolean(delimb or "true")
			self:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, 0, dirZ, length, growthStage, variationIndex, delimb)
			return "Loaded tree"
		end
	end
end
function TreePlantManager:consoleCommandPlantTrees(treeTypeName, number, growthStateI, variationIndex, isGrowing)
	local usage = "Usage: gsTreePlant treeType number growthState variationIndex isGrowing"
	local treeType = self:getTreeTypeDescFromName(treeTypeName)
	if treeTypeName ~= nil and treeType == nil then
		printError(string.format("Error: unknown tree type %q", treeTypeName))
		print("Available types:\n" .. table.concatKeys(g_treePlantManager.nameToTreeType, ", "))
		return usage
	end
	treeType = treeType or self:getTreeTypeDescFromName("lodgepolePine") or self:getTreeTypeDescFromName("aspen") or self.treeTypes[1]
	number = tonumber(number) or 1
	growthStateI = tonumber(growthStateI) or #treeType.stages
	growthStateI = math.clamp(growthStateI, 1, #treeType.stages)
	variationIndex = tonumber(variationIndex) or math.random(1, #treeType.stages[growthStateI])
	variationIndex = math.clamp(variationIndex, 1, #treeType.stages[growthStateI])
	isGrowing = Utils.stringToBoolean(isGrowing)
	local x, y, z = g_localPlayer:getPosition()
	local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
	x = x + dirX * 5
	z = z + dirZ * 5
	local numPlantedTrees = 0
	for i = 0, number - 1 do
		local tx = x + dirX * i * 5
		local tz = z + dirZ * i * 5
		local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, y, tz)
		local ry = math.random() * 2 * 3.141592653589793
		self.plantTreeCommandHasCollision = false
		overlapBox(tx, ty, tz, 0, 0, 0, 0.5, 1, 0.5, "onTreeOverlapCheckCallback", self, CollisionFlag.TREE)
		if not self.plantTreeCommandHasCollision then
			if self:plantTree(treeType.index, tx, ty, tz, 0, ry, 0, growthStateI, variationIndex, isGrowing) then
				numPlantedTrees = numPlantedTrees + 1
			end
		else
			printWarning("Warning: skipped tree due to overlap with existing tree")
		end
	end
	return string.format("Planted %d trees of type %s", numPlantedTrees, treeType.name)
end
function TreePlantManager:consoleCommandLoadAll(treeTypeName, number, growthStateI, variationIndex, isGrowing)
	g_debugManager:removeGroup("treeLoadAll")
	local x, _, z = g_localPlayer:getPosition()
	local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
	local yRot = MathUtil.getYRotationFromDirection(-dirX, -dirZ)
	x = x + dirX * 5
	z = z + dirZ * 5
	local xOffset = 10
	local zOffset = 10
	local numPlantedTrees = 0
	for index, treeType in ipairs(self.treeTypes) do
		local tx = x + dirZ * index * 10
		local tz = z - dirX * index * 10
		for stageIndex, stage in ipairs(treeType.stages) do
			for variationIndex, variation in ipairs(stage) do
				local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, 0, tz)
				local treeId = self:plantTree(treeType.index, tx, ty, tz, 0, math.random() * 3.141592653589793, 0, stageIndex, variationIndex, false)
				if treeId == nil or treeId == 0 then
					continue
				end
				local splitShapeId = getChildAt(getChildAt(treeId, 0), 0)
				local splitTypeIndex = -1
				local splitTypeName = "<NO_SPLIT_TYPE>"
				local allowWoodHarvester = false
				local sizeX = nil
				local sizeY = nil
				local sizeZ = nil
				local numConvexes = nil
				local numAttachments = nil
				if splitShapeId ~= 0 and getHasClassId(splitShapeId, ClassIds.MESH_SPLIT_SHAPE) then
					splitTypeIndex = getSplitType(splitShapeId)
					splitTypeName = g_splitShapeManager:getSplitTypeNameByIndex(splitTypeIndex)
					allowWoodHarvester = g_splitShapeManager:getSplitShapeAllowsHarvester(splitShapeId)
					sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(splitShapeId)
					local boundingBox = getSplitShapeOrientedBoundingBox(splitShapeId)
					local dir0X, dir0Y, dir0Z, dir1X, dir1Y, dir1Z, _, _, _, centerX, centerY, centerZ, extent0, extent1, extent2 = unpack(boundingBox)
					local sx, sy, sz = localToWorld(splitShapeId, centerX, 0, centerZ)
					dir1X, dir1Y, dir1Z = localDirectionToWorld(splitShapeId, dir1X, dir1Y, dir1Z)
					dir0X, dir0Y, dir0Z = localDirectionToWorld(splitShapeId, dir0X, dir0Y, dir0Z)
					local debugPlane = DebugPlane.new():createFromPosAndDir(sx, sy, sz, dir1X, dir1Y, dir1Z, dir0X, dir0Y, dir0Z, extent2 * 2, extent1 * 2)
					debugPlane.color = allowWoodHarvester and Color.PRESETS.GREEN or Color.PRESETS.RED
					g_debugManager:addElement(debugPlane, "treeLoadAll")
					local debugText = DebugText3D.new():createWithWorldPos(sx - dirX * 0.75, sy + 0.1, sz - dirZ * 0.75, 0, yRot, 0, string.format("Area: %.1fm\194\178", sizeY * sizeZ), 0.07)
					debugText.color = debugPlane.color
					g_debugManager:addElement(debugText, "treeLoadAll")
					local rCenterX, rCenterY, rCenterZ, _, _, _, radius = SplitShapeUtil.getTreeOffsetPosition(splitShapeId, tx, ty + 0.5, tz, 20, 0)
					if rCenterX ~= nil then
						if radius <= 0.601 and radius <= 0.351 then
							local color = Color.PRESETS.GREEN or Color.PRESETS.ORANGE or Color.PRESETS.RED
						end
						local debugCircleRadius1 = DebugCircle.new():createWithWorldPos(rCenterX, rCenterY, rCenterZ, radius, color, 20, false, false, false, false)
						g_debugManager:addElement(debugCircleRadius1, "treeLoadAll")
						local debugTextRadius1 = DebugText3D.new():createWithWorldPos(rCenterX - dirX * radius * 1.2, rCenterY, rCenterZ - dirZ * radius * 1.2, 0, yRot, 0, string.format("Diameter: %.1fcm", radius * 200), 0.05)
						debugTextRadius1.color = color
						g_debugManager:addElement(debugTextRadius1, "treeLoadAll")
					end
					rCenterX, rCenterY, rCenterZ, _, _, _, radius = SplitShapeUtil.getTreeOffsetPosition(splitShapeId, tx, ty + 1, tz, 20, 0)
					if rCenterX ~= nil then
						if radius <= 0.601 and radius <= 0.351 then
							local color = Color.PRESETS.GREEN or Color.PRESETS.ORANGE or Color.PRESETS.RED
						end
						local debugCircleRadius2 = DebugCircle.new():createWithWorldPos(rCenterX, rCenterY, rCenterZ, radius, color, 20, false, false, false, false)
						g_debugManager:addElement(debugCircleRadius2, "treeLoadAll")
						local debugTextRadius2 = DebugText3D.new():createWithWorldPos(rCenterX - dirX * radius * 1.2, rCenterY, rCenterZ - dirZ * radius * 1.2, 0, yRot, 0, string.format("Diameter: %.1fcm", radius * 200), 0.05)
						debugTextRadius2.color = color
						g_debugManager:addElement(debugTextRadius2, "treeLoadAll")
					end
				end
				local splitShapeDescStr = ""
				if sizeX ~= nil then
					splitShapeDescStr = string.format("\nSplit Shape Size: Height: %.2f | Width: %.2f | Length: %.2f | Area: %.2f m\194\178 | convexes: %d | attachments: %d", sizeX, sizeY, sizeZ, sizeY * sizeZ, numConvexes, numAttachments)
				end
				local debugText = DebugText3D.new():createWithWorldPos(tx - dirX, ty + 0.5, tz - dirZ, 0, yRot, 0, string.format("%s : %s\nsplitType: %s / %s%s%s", treeType.name, Utils.getFilenameInfo(variation.filename, true), splitTypeIndex, splitTypeName, splitShapeDescStr, allowWoodHarvester and "\n\nSupports Wood Harvester" or ""), 0.07)
				if allowWoodHarvester then
					debugText:setColor(Color.PRESETS.GREEN)
				end
				g_debugManager:addElement(debugText, "treeLoadAll")
				self:loadTreeTrunk(treeType, tx + dirZ * 2, ty, tz - dirX * 2, dirX, 0, dirZ, 0.25, stageIndex, variationIndex, true, true)
				numPlantedTrees = numPlantedTrees + 1
				tx = tx + dirX * 10
				tz = tz + dirZ * 10
			end
		end
	end
	return string.format("Planted %d trees", numPlantedTrees)
end
function TreePlantManager:onTreeOverlapCheckCallback(objectId, ...)
	if getHasClassId(objectId, ClassIds.SHAPE) and getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) then
		self.plantTreeCommandHasCollision = true
	end
end
function TreePlantManager:consoleCommandRemoveSplitShape()
	local cam = getCamera()
	local wx, wy, wz = getWorldTranslation(cam)
	local dx, dy, dz = localDirectionToWorld(cam, 0, 0, -1)
	local distance = 10
	local callbackTarget = {}
	function callbackTarget.callback(_, shape, ...)
		if shape ~= 0 then
			local minX, maxX, _, _, minZ, maxZ = getRigidBodyAABB(shape)
			local nodeToDelete = shape
			local nodeName = getName(shape)
			if nodeName == "LOD0" and getRigidBodyType(shape) == RigidBodyType.STATIC then
				nodeToDelete = getParent(shape)
			end
			Logging.info("removed %s (%d)", I3DUtil.getNodePath(nodeToDelete), nodeToDelete)
			delete(nodeToDelete)
			g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
			g_currentMission.aiSystem:setAreaDirty(minX, minZ, maxX, maxZ)
		end
	end
	if raycastClosest(wx, wy, wz, dx, dy, dz, 10, "callback", callbackTarget, CollisionFlag.TREE) == 0 then
		printWarning("No split shape found at current camera ray")
	end
end
function TreePlantManager:consoleCommandDebug()
	self.debugActive = not self.debugActive
	if self.debugActive then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	return "Tree/Splitshape debug = " .. tostring(self.debugActive)
end
g_treePlantManager = TreePlantManager.new()
