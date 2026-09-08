-- Local values: TreePlantManager_mt
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
	local v2_ = Mission00.xmlSchema
	v2_:register(XMLValueType.STRING, "map.treeTypes#filename", "")
	v2_:register(XMLValueType.INT, "map.treeTypes#maxNumTrees", "", 8000)
end)

-- Upvalues: TreePlantManager_mt
-- Local values: self
function TreePlantManager.new(customMt)
	-- upvalues: (copy) TreePlantManager_mt
	return AbstractManager.new(customMt or TreePlantManager_mt)
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

-- Local values: rootNode
function TreePlantManager:initialize()
	local v6_ = createTransformGroup("trees")
	link(getRootNode(), v6_)
	self.treesData = {}
	self.treesData.rootNode = v6_
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
		local v8_ = self.numTreesWithoutSplits - self.treesData.numTreesWithoutSplits
		self.numTreesWithoutSplits = math.max(v8_, 0)
		self:initDataStructures()
	end
end

-- Local values: xmlFile
function TreePlantManager:loadDefaultTypes(missionInfo, baseDirectory)
	local v12_ = loadXMLFile("treeTypes", "data/maps/maps_treeTypes.xml")
	self:loadTreeTypes(v12_, missionInfo, baseDirectory, true)
	delete(v12_)
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
	local v17_ = getXMLInt(xmlFile, "map.treeTypes#maxNumTrees") or 8000
	self.maxNumTrees = math.clamp(v17_, 1, 30000)
	g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, TreePlantManager.onMissionStarted, self)
	self:loadDefaultTypes(missionInfo, baseDirectory)
	return XMLUtil.loadDataFromMapXML(xmlFile, "treeTypes", baseDirectory, self, self.loadTreeTypes, missionInfo, baseDirectory)
end

-- Local values: i3dFilename, requestId
function TreePlantManager:unloadMapData()
	for v19_, v20_ in pairs(self.treeFileCache) do
		g_i3DManager:releaseSharedI3DFile(v20_)
		self.treeFileCache[v19_] = true
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

-- Local values: numTotal, numSplit
function TreePlantManager:onMissionStarted(isNewSavegame)
	local v22_, v23_ = getNumOfSplitShapes()
	Logging.info("TreePlantManager - NumTrees %d (%d split) / MaxNumTrees: %d", v22_, v23_, self.maxNumTrees)
end

-- Local values: _, treeTypeKey, name, title, growthTimeHours, splitTypeName, supportsPlanting, saplingPrice, splitTypeIndex, stages, _, stageKey, filename, variation, palletFilename, palletStoreItemFilename, planterFilename, variations, _, variationKey, variation, palletFilename, palletStoreItemFilename, planterFilename
function TreePlantManager:loadTreeTypes(xmlFile, missionInfo, baseDirectory, isBaseType, customEnvironment)
	if type(xmlFile) == "number" then
		xmlFile = XMLFile.wrap(xmlFile)
	end
	for _, v29_ in xmlFile:iterator("map.treeTypes.treeType") do
		local v30_ = xmlFile:getString(v29_ .. "#name")
		local v31_ = xmlFile:getString(v29_ .. "#title")
		local v32_ = xmlFile:getString(v29_ .. "#growthTimeHours")
		local v33_ = xmlFile:getString(v29_ .. "#splitType")
		local v34_ = xmlFile:getBool(v29_ .. "#supportsPlanting", true)
		local v35_ = xmlFile:getFloat(v29_ .. "#saplingPrice", 0)
		if v30_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'name\' attribute for treeType %q", v29_)
		elseif v31_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'title\' attribute for treeType %q", v29_)
		elseif v32_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'growthTimeHours\' attribute for treeType %q", v29_)
		elseif v33_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'splitType\' attribute for treeType %q", v29_)
		else
			local v36_ = g_splitShapeManager:getSplitTypeIndexByName(v33_)
			if v36_ == nil then
				Logging.xmlWarning(xmlFile, "SplitType \'%s\' not defined for treeType %q", v33_, v29_)
			else
				local v37_ = {}
				for _, v38_ in xmlFile:iterator(v29_ .. ".stage") do
					local v39_ = xmlFile:getString(v38_ .. "#filename")
					if v39_ == nil then
						local v40_ = {}
						for _, v41_ in xmlFile:iterator(v38_ .. ".variation") do
							local v42_ = xmlFile:getString(v41_ .. "#filename")
							if v42_ ~= nil then
								if #v40_ >= TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE then
									Logging.xmlWarning(xmlFile, "Unable to add variation %q for tree %q, max number of variations per stage (%d) reached", v42_, v30_, TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE)
									break
								end
								local v43_ = {
									["name"] = xmlFile:getString(v41_ .. "#name"),
									["filename"] = Utils.getFilename(v42_, baseDirectory)
								}
								local v44_ = xmlFile:getString(v41_ .. ".pallet#filename")
								if v44_ ~= nil then
									v43_.palletFilename = Utils.getFilename(v44_, baseDirectory)
								end
								local v45_ = xmlFile:getString(v41_ .. ".pallet#storeItem")
								if v45_ ~= nil then
									v43_.palletStoreItemFilename = Utils.getFilename(v45_, baseDirectory)
								end
								local v46_ = xmlFile:getString(v41_ .. ".planter#filename")
								if v46_ ~= nil then
									v43_.planterFilename = Utils.getFilename(v46_, baseDirectory)
								end
								table.insert(v40_, v43_)
							end
						end
						if #v37_ >= TreePlantManager.MAX_NUM_STAGES then
							Logging.xmlWarning(xmlFile, "Unable to add stage %q for tree %q, max number of stages (%d) reached", v38_, v30_, TreePlantManager.MAX_NUM_STAGES)
						end
						table.insert(v37_, v40_)
					else
						local v47_ = {
							["filename"] = Utils.getFilename(v39_, baseDirectory)
						}
						local v48_ = xmlFile:getString(v38_ .. ".pallet#filename")
						if v48_ ~= nil then
							v47_.palletFilename = Utils.getFilename(v48_, baseDirectory)
						end
						local v49_ = xmlFile:getString(v38_ .. ".pallet#storeItem")
						if v49_ ~= nil then
							v47_.palletStoreItemFilename = Utils.getFilename(v49_, baseDirectory)
						end
						local v50_ = xmlFile:getString(v38_ .. ".planter#filename")
						if v50_ ~= nil then
							v47_.planterFilename = Utils.getFilename(v50_, baseDirectory)
						end
						table.insert(v37_, { v47_ })
					end
				end
				if #v37_ == 0 then
					Logging.xmlWarning(xmlFile, "A treetype %q (%s) has no valid stages defined\'", v30_, v29_)
				else
					self:registerTreeType(v30_, g_i18n:convertText(v31_, customEnvironment), v37_, v32_, isBaseType, v36_, v34_, v35_)
				end
			end
		end
	end
	return true
end

-- Local values: treeType
function TreePlantManager:registerTreeType(name, title, stages, growthTimeHours, isBaseType, splitTypeIndex, supportsPlanting, saplingPrice)
	local v60_ = string.upper(name)
	if #self.treeTypes >= TreePlantManager.MAX_NUM_TYPES then
		Logging.warning("Unable to register tree type %q, maximum number of tree types (%d) reached", v60_, TreePlantManager.MAX_NUM_TYPES)
		return nil
	end
	if isBaseType and self.nameToTreeType[v60_] ~= nil then
		Logging.warning("TreeType %q already exists. Ignoring treeType!", v60_)
		return nil
	end
	local v61_ = self.nameToTreeType[v60_]
	if v61_ == nil then
		v61_ = {
			["name"] = v60_,
			["title"] = title,
			["index"] = #self.treeTypes + 1,
			["splitTypeIndex"] = splitTypeIndex
		}
		local v62_ = self.treeTypes
		table.insert(v62_, v61_)
		self.indexToTreeType[v61_.index] = v61_
		self.nameToTreeType[v60_] = v61_
		self.splitTypeIndexToTreeType[splitTypeIndex] = v61_
	end
	v61_.stages = stages
	v61_.growthTimeHours = growthTimeHours
	v61_.supportsPlanting = supportsPlanting
	if supportsPlanting then
		v61_.saplingPrice = saplingPrice
	end
	return v61_
end

-- Local values: stage, variation
function TreePlantManager:getTreeTypeFilename(treeTypeDesc, growthStateI)
	if treeTypeDesc == nil then
		return nil
	end
	local v65_ = treeTypeDesc.stages
	local v66_ = #treeTypeDesc.stages
	local v67_ = v65_[math.min(growthStateI, v66_)]
	return v67_[math.random(1, #v67_)].filename
end

-- Local values: totalNumSplit, numSplit, numUnsplit
function TreePlantManager:canPlantTree()
	local v69_, v70_ = getNumOfSplitShapes()
	return v69_ - v70_ + self.numTreesWithoutSplits < self.maxNumTrees
end

-- Local values: treeTypeDesc, treeId, splitShapeFileId, treesData, tree
function TreePlantManager:plantTree(treeTypeIndex, x, y, z, rx, ry, rz, growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, existingSplitShapeFileId)
	local v84_ = self.indexToTreeType[treeTypeIndex]
	if v84_ == nil then
		return nil
	end
	local v85_, v86_ = self:loadTreeNode(v84_, x, y, z, rx, ry, rz, growthStateI, variationIndex, existingSplitShapeFileId)
	if v85_ == 0 then
		return nil
	end
	local v87_ = self.treesData
	local v88_ = {
		["node"] = v85_,
		["growthStateI"] = growthStateI,
		["variationIndex"] = variationIndex or 1
	}
	local v89_ = Utils.getNoNil(isGrowing, true)
	if v89_ then
		v89_ = growthStateI < #v84_.stages
	end
	v88_.isGrowing = v89_
	v88_.x = x
	v88_.y = y
	v88_.z = z
	v88_.rx = rx
	v88_.ry = ry
	v88_.rz = rz
	v88_.treeType = treeTypeIndex
	v88_.splitShapeFileId = v86_
	v88_.hasSplitShapes = getFileIdHasSplitShapes(v86_)
	if v88_.isGrowing then
		v88_.origSplitShape = getChildAt(v85_, 0)
		if nextGrowthTargetHour == nil then
			v88_.nextGrowthTargetHour = g_currentMission.environment:getMonotonicHour() + v84_.growthTimeHours
		else
			v88_.nextGrowthTargetHour = nextGrowthTargetHour
		end
		local v90_ = v87_.growingTrees
		table.insert(v90_, v88_)
	else
		local v91_ = v87_.splitTrees
		table.insert(v91_, v88_)
	end
	if not v88_.hasSplitShapes then
		self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
		v87_.numTreesWithoutSplits = v87_.numTreesWithoutSplits + 1
	end
	g_server:broadcastEvent(TreePlantEvent.new(treeTypeIndex, x, y, z, rx, ry, rz, growthStateI, v88_.variationIndex, v86_, v88_.isGrowing))
	return v85_
end

-- Local values: treesData, stage, variations, variation, i3dFilename, node, requestId, splitShapeFileId, treeId, requestId, numChildren, i, child, updateRange
function TreePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeLoadingFileId)
	local v103_ = self.treesData
	local v104_ = #treeTypeDesc.stages
	local v105_ = math.min(growthStateI, v104_)
	local v106_ = treeTypeDesc.stages[v105_]
	if v106_ == nil then
		Logging.error("TreePlantManager:loadTreeNode failed due to invalid stage index (stage %d of %d)", v105_, #treeTypeDesc.stages)
		return 0
	end
	local v107_ = #v106_
	local v_u_108_ = v106_[math.clamp(variationIndex, 1, v107_)].filename
	if self.treeFileCache[v_u_108_] == nil then
		setSplitShapesLoadingFileId(-1)
		setSplitShapesNextFileId(true)
		local v109_, v110_ = g_i3DManager:loadSharedI3DFile(v_u_108_, false, false)
		if v109_ ~= 0 then
			delete(v109_)
			self.treeFileCache[v_u_108_] = v110_
		end
	end
	setSplitShapesLoadingFileId(splitShapeLoadingFileId or -1)
	local v111_ = setSplitShapesNextFileId()
	local v112_, v113_ = g_i3DManager:loadSharedI3DFile(v_u_108_, false, false)
	g_i3DManager:releaseSharedI3DFile(v113_)
	if v112_ ~= 0 then
		link(v103_.rootNode, v112_)
		setTranslation(v112_, x, y, z)
		setRotation(v112_, rx, ry, rz)
		for v114_ = 0, getNumOfChildren(v112_) - 1 do
			local v115_ = getChildAt(v112_, v114_)
			if getHasClassId(v115_, ClassIds.MESH_SPLIT_SHAPE) and getIsSplitShapeSplit(v115_) then
				setWorldRotation(v115_, getRotation(v115_))
				setWorldTranslation(v115_, getTranslation(v115_))
			end
		end
		I3DUtil.iterateRecursively(v112_, function(p116_, _)
			-- upvalues: (copy) treeTypeDesc, (copy) v_u_108_
			if getHasClassId(p116_, ClassIds.MESH_SPLIT_SHAPE) then
				local v117_ = getSplitType(p116_)
				if v117_ ~= treeTypeDesc.splitTypeIndex then
					Logging.warning("Tree has wrong splitType \'%s\' assigned. Should be \'%s\'. File: \'%s\'", v117_, treeTypeDesc.splitTypeIndex, v_u_108_)
				end
				if g_server == nil and getRigidBodyType(p116_) == RigidBodyType.DYNAMIC then
					setRigidBodyType(p116_, RigidBodyType.KINEMATIC)
				end
			end
			return true
		end)
		addToPhysics(v112_)
	end
	g_densityMapHeightManager:setCollisionMapAreaDirty(x - 2, z - 2, x + 2, z + 2, true)
	g_currentMission.aiSystem:setAreaDirty(x - 2, x + 2, z - 2, z + 2)
	return v112_, v111_
end

-- Local values: treeId, splitShapeFileId, tree, loadTreeTrunkData
function TreePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthStateI, variationIndex, delimb, useOnlyStump)
	local v131_, v132_ = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, 0, 0, 0, growthStateI, variationIndex)
	if v131_ ~= 0 then
		if getFileIdHasSplitShapes(v132_) then
			local v133_ = {
				["node"] = v131_,
				["growthStateI"] = growthStateI,
				["variationIndex"] = variationIndex,
				["x"] = x,
				["y"] = y,
				["z"] = z,
				["rx"] = 0,
				["ry"] = 0,
				["rz"] = 0,
				["treeType"] = treeTypeDesc.index,
				["splitShapeFileId"] = v132_,
				["hasSplitShapes"] = getFileIdHasSplitShapes(v132_)
			}
			local v134_ = self.treesData.splitTrees
			table.insert(v134_, v133_)
			local v135_ = {
				["framesLeft"] = 2,
				["shape"] = v131_ + 2,
				["x"] = x,
				["y"] = y,
				["z"] = z,
				["length"] = length,
				["offset"] = 0.5,
				["dirX"] = dirX,
				["dirY"] = dirY,
				["dirZ"] = dirZ,
				["delimb"] = delimb,
				["useOnlyStump"] = useOnlyStump,
				["cutTreeTrunkCallback"] = TreePlantManager.cutTreeTrunkCallback
			}
			local v136_ = self.loadTreeTrunkDatas
			table.insert(v136_, v135_)
			return
		end
		delete(v131_)
	end
end

function TreePlantManager.cutTreeTrunkCallback(loadTreeTrunkData, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	g_treePlantManager:addingSplitShape(shape, loadTreeTrunkData.shapeBeingCut)
	local v145_ = loadTreeTrunkData.parts
	table.insert(v145_, {
		["shape"] = shape,
		["isBelow"] = isBelow,
		["isAbove"] = isAbove,
		["minY"] = minY,
		["maxY"] = maxY,
		["minZ"] = minZ,
		["maxZ"] = maxZ
	})
end

-- Local values: treesData, currentMonotonicHour, numGrowingTrees, i, tree, treeTypeDesc, numStages, growthStateNew, variations, treeId, splitShapeFileId, range, x, _, z, curTime, joint, x1, y1, z1, i, loadTreeTrunkData, nx, ny, nz, yx, yy, yz, x, y, z, shape, _, p, nx, ny, nz, yx, yy, yz, x, y, z, shape, cutDiameter, _, p, finalShape, _, p, treeId, x, y, z, localX, localY, localZ, cx, cy, cz, nx, ny, nz, yx, yy, yz, shape, data, newState
function TreePlantManager:updateTrees(dt, dtGame)
	local v148_ = self.treesData
	v148_.updateDtGame = v148_.updateDtGame + dtGame
	if v148_.updateDtGame > 3600000 then
		self:cleanupDeletedTrees()
		v148_.updateDtGame = 0
		local v149_ = g_currentMission.environment:getMonotonicHour()
		local v150_ = #v148_.growingTrees
		local v151_ = 1
		while v151_ <= v150_ do
			local v152_ = v148_.growingTrees[v151_]
			if getChildAt(v152_.node, 0) == v152_.origSplitShape then
				local v153_ = self.indexToTreeType[v152_.treeType]
				local v154_ = #v153_.stages
				if v152_.nextGrowthTargetHour < v149_ then
					local v155_ = v152_.growthStateI + 1
					local v156_ = #v153_.stages
					local v157_ = math.min(v155_, v156_)
					if self.debugActive then
						Logging.info("growing tree %s from stage %d to %d", v153_.name, v152_.growthStateI, v157_)
					end
					v152_.growthStateI = v157_
					if v154_ <= v152_.growthStateI then
						v152_.nextGrowthTargetHour = nil
					else
						v152_.nextGrowthTargetHour = v149_ + v153_.growthTimeHours
					end
					delete(v152_.node)
					if not v152_.hasSplitShapes then
						local v158_ = self.numTreesWithoutSplits - 1
						self.numTreesWithoutSplits = math.max(v158_, 0)
						local v159_ = v148_.numTreesWithoutSplits - 1
						v148_.numTreesWithoutSplits = math.max(v159_, 0)
					end
					local v160_ = v153_.stages[v152_.growthStateI]
					v152_.variationIndex = math.random(1, #v160_)
					local v161_, v162_ = self:loadTreeNode(v153_, v152_.x, v152_.y, v152_.z, v152_.rx, v152_.ry, v152_.rz, v152_.growthStateI, v152_.variationIndex, -1)
					g_server:broadcastEvent(TreeGrowEvent.new(v152_.treeType, v152_.x, v152_.y, v152_.z, v152_.rx, v152_.ry, v152_.rz, v152_.growthStateI, v152_.variationIndex, v162_, v152_.splitShapeFileId))
					v152_.origSplitShape = getChildAt(v161_, 0)
					v152_.splitShapeFileId = v162_
					v152_.hasSplitShapes = getFileIdHasSplitShapes(v162_)
					v152_.node = v161_
					local v163_, _, v164_ = getWorldTranslation(v161_)
					g_densityMapHeightManager:setCollisionMapAreaDirty(v163_ - 2.5, v164_ - 2.5, v163_ + 2.5, v164_ + 2.5, true)
					g_currentMission.aiSystem:setAreaDirty(v163_ - 2.5, v163_ + 2.5, v164_ - 2.5, v164_ + 2.5)
					if not v152_.hasSplitShapes then
						self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
						v148_.numTreesWithoutSplits = v148_.numTreesWithoutSplits + 1
					end
				end
				if v154_ <= v152_.growthStateI then
					if self.debugActive then
						Logging.info("Removing fully grown tree %d (%s stage %d) from growth", v152_.node, v153_.name, v152_.growthStateI)
					end
					table.remove(v148_.growingTrees, v151_)
					v150_ = v150_ - 1
					v152_.origSplitShape = nil
					local v165_ = v148_.splitTrees
					table.insert(v165_, v152_)
				else
					v151_ = v151_ + 1
				end
			else
				if self.debugActive then
					Logging.info("Removing cut tree %d from growing trees", v152_.node)
				end
				table.remove(v148_.growingTrees, v151_)
				v150_ = v150_ - 1
				v152_.origSplitShape = nil
				local v166_ = v148_.splitTrees
				table.insert(v166_, v152_)
			end
		end
	end
	local v167_ = g_currentMission.time
	for v168_ in pairs(v148_.treeCutJoints) do
		if v168_.destroyTime <= v167_ or not entityExists(v168_.shape) then
			removeJoint(v168_.jointIndex)
			v148_.treeCutJoints[v168_] = nil
		else
			local v169_, v170_, v171_ = localDirectionToWorld(v168_.shape, v168_.lnx, v168_.lny, v168_.lnz)
			if v169_ * v168_.nx + v170_ * v168_.ny + v171_ * v168_.nz < v168_.maxCosAngle then
				removeJoint(v168_.jointIndex)
				v148_.treeCutJoints[v168_] = nil
			end
		end
	end
	if #self.loadTreeTrunkDatas > 0 then
		for v172_ = #self.loadTreeTrunkDatas, 1, -1 do
			local v173_ = self.loadTreeTrunkDatas[v172_]
			v173_.framesLeft = v173_.framesLeft - 1
			if v173_.framesLeft == 1 then
				local v174_ = v173_.x + 1
				local v175_ = v173_.y
				local v176_ = v173_.z - 1
				v173_.parts = {}
				local v177_ = v173_.shape
				if v177_ ~= nil and v177_ ~= 0 then
					v173_.shapeBeingCut = v177_
					splitShape(v177_, v174_, v175_ + v173_.length + v173_.offset, v176_, 0, 1, 0, -1, 0, 0, 4, 4, "cutTreeTrunkCallback", v173_)
					self:removingSplitShape(v177_)
					for _, v178_ in pairs(v173_.parts) do
						if v178_.isAbove then
							delete(v178_.shape)
						else
							v173_.shape = v178_.shape
						end
					end
				end
			elseif v173_.framesLeft == 0 then
				local v179_ = v173_.x + 1
				local v180_ = v173_.y
				local v181_ = v173_.z - 1
				v173_.parts = {}
				local v182_ = v173_.shape
				if v182_ ~= nil and v182_ ~= 0 then
					splitShape(v182_, v179_, v180_ + v173_.offset, v181_, 0, 1, 0, -1, 0, 0, 5, 5, "cutTreeTrunkCallback", v173_)
					if v173_.useOnlyStump then
						for _, v183_ in pairs(v173_.parts) do
							if not v183_.isBelow then
								delete(v183_.shape)
							end
						end
					else
						local v184_ = nil
						for _, v185_ in pairs(v173_.parts) do
							if v185_.isBelow then
								delete(v185_.shape)
							else
								v184_ = v185_.shape
							end
						end
						if v184_ == nil then
							Logging.error("Unable to cut tree trunk with length \'%s\'. Try using a different value", v173_.length)
						else
							if v173_.delimb then
								removeSplitShapeAttachments(v184_, v179_, v180_ + v173_.offset, v181_, 0, 1, 0, -1, 0, 0, v173_.length, 4, 4)
							end
							removeFromPhysics(v184_)
							setDirection(v184_, 0, -1, 0, v173_.dirX, v173_.dirY, v173_.dirZ)
							addToPhysics(v184_)
						end
					end
				end
				table.remove(self.loadTreeTrunkDatas, v172_)
			end
		end
	end
	if self.commandCutTreeData ~= nil then
		if #self.commandCutTreeData.trees > 0 then
			local v186_ = self.commandCutTreeData.trees[1]
			local v187_, v188_, v189_ = getWorldTranslation(v186_)
			local v190_, v191_, v192_ = worldToLocal(v186_, v187_, v188_ + 0.5, v189_)
			local v193_, v194_, v195_ = localToWorld(v186_, v190_ - 2, v191_, v192_ - 2)
			local v196_, v197_, v198_ = localDirectionToWorld(v186_, 0, 1, 0)
			local v199_, v200_, v201_ = localDirectionToWorld(v186_, 0, 0, 1)
			self.commandCutTreeData.shapeBeingCut = v186_
			Logging.info("Cut tree \'%s\' (%d left)", getName(v186_), #self.commandCutTreeData.trees - 1)
			splitShape(v186_, v193_, v194_, v195_, v196_, v197_, v198_, v199_, v200_, v201_, 4, 4, "onTreeCutCommandSplitCallback", self)
			table.remove(self.commandCutTreeData.trees, 1)
		else
			self.commandCutTreeData = nil
		end
	end
	self.updateDecayDtGame = self.updateDecayDtGame + dtGame
	if self.updateDecayDtGame > TreePlantManager.DECAY_INTERVAL then
		for v202_, v203_ in pairs(self.activeDecayingSplitShapes) do
			if entityExists(v202_) then
				if v203_.state > 0 then
					local v204_ = v203_.state - TreePlantManager.DECAY_DURATION_INV * self.updateDecayDtGame
					local v205_ = math.max(v204_, 0)
					self:setSplitShapeLeafScaleAndVariation(v202_, v205_, v203_.variation)
					self.activeDecayingSplitShapes[v202_].state = v205_
				end
			else
				self.activeDecayingSplitShapes[v202_] = nil
			end
		end
		self.updateDecayDtGame = 0
	end
end

-- Local values: index, tree, treeTypeDesc, index, tree, treeTypeDesc, serverSplitShapeFileId, nodeId, rigidBodyType
function TreePlantManager:drawDebug()
	if self.treesData ~= nil and self.treesData.growingTrees ~= nil then
		for v207_, v208_ in ipairs(self.treesData.growingTrees) do
			local v209_ = self.indexToTreeType[v208_.treeType]
			DebugText.renderAtNode(v208_.node, string.format("growingTree #%d\ntype %s\ngrowthStateI %d\nvariation %d\nnextGrowthTargetHour %.2f", v207_, v209_.name, v208_.growthStateI, v208_.variationIndex, v208_.nextGrowthTargetHour), Color.PRESETS.GREEN, 0.01)
		end
		for v210_, v211_ in ipairs(self.treesData.splitTrees) do
			local v212_ = self.indexToTreeType[v211_.treeType]
			DebugText.renderAtNode(v211_.node, string.format("splitTree #%d\ntype %s\ngrowthStateI %d\nvariation %d\n", v210_, v212_.name, v211_.growthStateI, v211_.variationIndex), nil, 0.01)
		end
		for v213_, v214_ in pairs(self.treesData.clientTrees) do
			local v215_ = EnumUtil.getName(RigidBodyType, self:getTreeRigidBodyType(v214_) or RigidBodyType.NONE)
			DebugText.renderAtNode(v214_, string.format("clientTree\nserverSplitShapeFileId %s\nnodeId %s|%s\nRigidBodyType %s", v213_, v214_, getName(v214_), v215_), nil, 0.01)
		end
	end
end

-- Local values: treesData, lnx, lny, lnz, joint
function TreePlantManager:addTreeCutJoint(jointIndex, shape, nx, ny, nz, maxAngle, maxLifetime)
	local v224_ = self.treesData
	local v225_, v226_, v227_ = worldDirectionToLocal(shape, nx, ny, nz)
	local v228_ = {
		["jointIndex"] = jointIndex,
		["shape"] = shape,
		["nx"] = nx,
		["ny"] = ny,
		["nz"] = nz,
		["lnx"] = v225_,
		["lny"] = v226_,
		["lnz"] = v227_,
		["maxCosAngle"] = math.cos(maxAngle),
		["destroyTime"] = g_currentMission.time + maxLifetime
	}
	v224_.treeCutJoints[v228_] = v228_
end

-- Local values: i, child
function TreePlantManager:getIsTreeDeleted(node)
	for v231_ = 1, getNumOfChildren(node) do
		local v232_ = getChildAt(node, v231_ - 1)
		if getHasClassId(v232_, ClassIds.MESH_SPLIT_SHAPE) or getHasClassId(v232_, ClassIds.SHAPE) then
			return false
		end
		if not self:getIsTreeDeleted(v232_) then
			return false
		end
	end
	return true
end

-- Local values: i, child, rigidBodyType
function TreePlantManager:getTreeRigidBodyType(node)
	for v235_ = 1, getNumOfChildren(node) do
		local v236_ = getChildAt(node, v235_ - 1)
		if getHasClassId(v236_, ClassIds.MESH_SPLIT_SHAPE) then
			return getRigidBodyType(v236_)
		end
		local v237_ = self:getTreeRigidBodyType(v236_)
		if v237_ ~= nil then
			return v237_
		end
	end
	return nil
end

-- Local values: treesData, numGrowingTrees, growingTreeIndex, tree, numSplitTrees, splitTreeIndex, tree
function TreePlantManager:cleanupDeletedTrees()
	local v239_ = self.treesData
	local v240_ = #v239_.growingTrees
	local v241_ = 1
	while v241_ <= v240_ do
		local v242_ = v239_.growingTrees[v241_]
		if self:getIsTreeDeleted(v242_.node) then
			table.remove(v239_.growingTrees, v241_)
			v240_ = v240_ - 1
			delete(v242_.node)
			if not v242_.hasSplitShapes then
				local v243_ = self.numTreesWithoutSplits - 1
				self.numTreesWithoutSplits = math.max(v243_, 0)
				local v244_ = v239_.numTreesWithoutSplits - 1
				v239_.numTreesWithoutSplits = math.max(v244_, 0)
			end
		else
			v241_ = v241_ + 1
		end
	end
	local v245_ = #v239_.splitTrees
	local v246_ = 1
	while v246_ <= v245_ do
		local v247_ = v239_.splitTrees[v246_]
		if self:getIsTreeDeleted(v247_.node) then
			table.remove(v239_.splitTrees, v246_)
			v245_ = v245_ - 1
			delete(v247_.node)
			if not v247_.hasSplitShapes then
				local v248_ = self.numTreesWithoutSplits - 1
				self.numTreesWithoutSplits = math.max(v248_, 0)
				local v249_ = v239_.numTreesWithoutSplits - 1
				v239_.numTreesWithoutSplits = math.max(v249_, 0)
			end
		else
			v246_ = v246_ + 1
		end
	end
end

-- Local values: xmlFile, i, key, treeTypeName, treeType, pos, rot, growthStateI, variationIndex, nextGrowthTargetHour, isGrowing, splitShapeFileId
function TreePlantManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local v252_ = loadXMLFile("treePlantXML", xmlFilename)
	if v252_ == 0 then
		return false
	end
	local v253_ = 0
	while true do
		local v254_ = string.format("treePlant.tree(%d)", v253_)
		if not hasXMLProperty(v252_, v254_) then
			break
		end
		local v255_ = getXMLString(v252_, v254_ .. "#treeType")
		local v256_ = self.nameToTreeType[v255_]
		local v257_ = string.getVector(getXMLString(v252_, v254_ .. "#position"), 3)
		local v258_ = string.getRadians(getXMLString(v252_, v254_ .. "#rotation"), 3)
		if #v257_ == 3 and (#v258_ == 3 and v256_ ~= nil) then
			local v259_ = getXMLInt(v252_, v254_ .. "#growthStateI")
			local v260_ = getXMLInt(v252_, v254_ .. "#variationIndex") or 1
			local v261_ = getXMLFloat(v252_, v254_ .. "#nextGrowthTargetHour")
			local v262_ = Utils.getNoNil(getXMLBool(v252_, v254_ .. "#isGrowing"), true)
			local v263_ = getXMLInt(v252_, v254_ .. "#splitShapeFileId")
			self:plantTree(v256_.index, v257_[1], v257_[2], v257_[3], v258_[1], v258_[2], v258_[3], v259_, v260_, v262_, v261_, v263_)
		end
		v253_ = v253_ + 1
	end
	delete(v252_)
	return true
end

-- Local values: xmlFile, saveTreeToXML, index, _, tree, _, tree
function TreePlantManager:saveToXMLFile(xmlFilename)
	self:cleanupDeletedTrees()
	local v_u_266_ = createXMLFile("treePlantXML", xmlFilename, "treePlant")
	if v_u_266_ == 0 then
		Logging.error("Failed to create xml file %q", xmlFilename)
		return false
	end
	local function v282_(p267_, p268_)
		-- upvalues: (copy) self, (copy) v_u_266_
		local v269_ = self:getTreeTypeDescFromIndex(p267_.treeType).name
		local v270_ = getChildAt(p267_.node, 0) == p267_.origSplitShape
		local v271_ = p267_.splitShapeFileId or -1
		local v272_ = string.format("treePlant.tree(%d)", p268_)
		setXMLString(v_u_266_, v272_ .. "#treeType", v269_)
		setXMLString(v_u_266_, v272_ .. "#position", string.format("%.4f %.4f %.4f", p267_.x, p267_.y, p267_.z))
		local v273_ = setXMLString
		local v274_ = v_u_266_
		local v275_ = v272_ .. "#rotation"
		local v276_ = string.format
		local v277_ = p267_.rx
		local v278_ = math.deg(v277_)
		local v279_ = p267_.ry
		local v280_ = math.deg(v279_)
		local v281_ = p267_.rz
		v273_(v274_, v275_, v276_("%.4f %.4f %.4f", v278_, v280_, (math.deg(v281_))))
		setXMLInt(v_u_266_, v272_ .. "#growthStateI", p267_.growthStateI)
		if p267_.variationIndex ~= 1 then
			setXMLInt(v_u_266_, v272_ .. "#variationIndex", p267_.variationIndex)
		end
		if p267_.nextGrowthTargetHour ~= nil then
			setXMLFloat(v_u_266_, v272_ .. "#nextGrowthTargetHour", p267_.nextGrowthTargetHour)
		end
		setXMLBool(v_u_266_, v272_ .. "#isGrowing", v270_)
		setXMLInt(v_u_266_, v272_ .. "#splitShapeFileId", v271_)
	end
	local v283_ = 0
	for _, v284_ in ipairs(self.treesData.growingTrees) do
		v282_(v284_, v283_)
		v283_ = v283_ + 1
	end
	for _, v285_ in ipairs(self.treesData.splitTrees) do
		v282_(v285_, v283_)
		v283_ = v283_ + 1
	end
	saveXMLFile(v_u_266_)
	delete(v_u_266_)
	return true
end

-- Local values: treesData, numTrees, i, treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, serverSplitShapeFileId, treeTypeDesc, nodeId, splitShapeFileId
function TreePlantManager:readFromServerStream(streamId)
	local v288_ = self.treesData
	for _ = 1, streamReadInt32(streamId) do
		local v289_ = streamReadUInt8(streamId)
		local v290_ = streamReadFloat32(streamId)
		local v291_ = streamReadFloat32(streamId)
		local v292_ = streamReadFloat32(streamId)
		local v293_ = streamReadFloat32(streamId)
		local v294_ = streamReadFloat32(streamId)
		local v295_ = streamReadFloat32(streamId)
		local v296_ = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
		local v297_ = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
		local v298_ = streamReadInt32(streamId)
		local v299_ = self.indexToTreeType[v289_]
		if v299_ ~= nil then
			local v300_, v301_ = self:loadTreeNode(v299_, v290_, v291_, v292_, v293_, v294_, v295_, v296_, v297_, -1)
			setSplitShapesFileIdMapping(v301_, v298_)
			v288_.clientTrees[v298_] = v300_
		end
	end
end

-- Local values: treesData, numTrees, _, tree, _, tree
function TreePlantManager:writeToClientStream(streamId)
	local v304_ = self.treesData
	self:cleanupDeletedTrees()
	local v305_ = #v304_.growingTrees + #v304_.splitTrees
	streamWriteInt32(streamId, v305_)
	for _, v306_ in ipairs(v304_.growingTrees) do
		streamWriteUInt8(streamId, v306_.treeType)
		streamWriteFloat32(streamId, v306_.x)
		streamWriteFloat32(streamId, v306_.y)
		streamWriteFloat32(streamId, v306_.z)
		streamWriteFloat32(streamId, v306_.rx)
		streamWriteFloat32(streamId, v306_.ry)
		streamWriteFloat32(streamId, v306_.rz)
		streamWriteUIntN(streamId, v306_.growthStateI, TreePlantManager.STAGE_NUM_BITS)
		streamWriteUIntN(streamId, v306_.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
		streamWriteInt32(streamId, v306_.splitShapeFileId)
	end
	for _, v307_ in ipairs(v304_.splitTrees) do
		streamWriteUInt8(streamId, v307_.treeType)
		streamWriteFloat32(streamId, v307_.x)
		streamWriteFloat32(streamId, v307_.y)
		streamWriteFloat32(streamId, v307_.z)
		streamWriteFloat32(streamId, v307_.rx)
		streamWriteFloat32(streamId, v307_.ry)
		streamWriteFloat32(streamId, v307_.rz)
		streamWriteUIntN(streamId, v307_.growthStateI, TreePlantManager.STAGE_NUM_BITS)
		streamWriteUIntN(streamId, v307_.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
		streamWriteInt32(streamId, v307_.splitShapeFileId)
	end
end

function TreePlantManager:getTreeTypeDescFromIndex(index)
	if self.treeTypes == nil then
		return nil
	else
		return self.treeTypes[index]
	end
end

function TreePlantManager:getTreeTypeNameFromIndex(index)
	if self.treeTypes == nil or self.treeTypes[index] == nil then
		return nil
	else
		return self.treeTypes[index].name
	end
end

function TreePlantManager:getTreeTypeDescFromName(name)
	if self.nameToTreeType == nil or name == nil then
		return nil
	end
	local v314_ = string.upper(name)
	return self.nameToTreeType[v314_]
end

-- Local values: treeTypeDesc, stage, variationIndex, index, variation
function TreePlantManager:getTreeTypeIndexAndVariationFromName(name, stageIndex, variationName)
	if self.nameToTreeType ~= nil and name ~= nil then
		local v319_ = string.upper(name)
		local v320_ = self.nameToTreeType[v319_]
		if v320_ ~= nil then
			local v321_ = v320_.stages[stageIndex]
			if v321_ ~= nil then
				local v322_ = nil
				for v323_, v324_ in ipairs(v321_) do
					if string.lower(v324_.name or "DEFAULT") == string.lower(variationName or "DEFAULT") then
						v322_ = v323_
						break
					end
				end
				return v320_.index, v322_
			end
		end
	end
	return nil, nil
end

-- Local values: treeTypeDesc, variations, variation
function TreePlantManager:getTreeTypeNameAndVariationByIndex(treeTypeIndex, stageIndex, variationIndex)
	if self.treeTypes ~= nil then
		local v329_ = self.treeTypes[treeTypeIndex]
		if v329_ ~= nil then
			local v330_ = v329_.stages[stageIndex or 1]
			if v330_ ~= nil then
				local v331_ = v330_[variationIndex] or v330_[1]
				if v331_ ~= nil then
					return v329_.name, v331_.name or "DEFAULT"
				end
			end
		end
	end
	return nil, nil
end

-- Local values: treeTypeDesc, variations, variation
function TreePlantManager:getPalletStoreItemFilenameByIndex(treeTypeIndex, stageIndex, variationIndex)
	if self.treeTypes ~= nil then
		local v336_ = self.treeTypes[treeTypeIndex]
		if v336_ ~= nil then
			local v337_ = v336_.stages[stageIndex or 1]
			if v337_ ~= nil then
				local v338_ = v337_[variationIndex] or v337_[1]
				if v338_ ~= nil then
					return v338_.palletStoreItemFilename
				end
			end
		end
	end
	return nil
end

function TreePlantManager:getTreeTypeDescFromSplitType(splitTypeIndex)
	if self.splitTypeIndexToTreeType == nil or splitTypeIndex == nil then
		return nil
	else
		return self.splitTypeIndexToTreeType[splitTypeIndex]
	end
end

function TreePlantManager:getTreeTypeIndexFromName(name)
	if self.nameToTreeType ~= nil and name ~= nil then
		local v343_ = string.upper(name)
		if self.nameToTreeType[v343_] ~= nil then
			return self.nameToTreeType[v343_].index
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
	if self.treesData == nil then
		return nil
	else
		return self.treesData.clientTrees[serverSplitShapeFileId]
	end
end

-- Local values: state, variation, x, y, z
function TreePlantManager:addingSplitShape(shape, oldShape, fromTree)
	local v355_, v356_
	if oldShape == nil or self.activeDecayingSplitShapes[oldShape] == nil then
		if fromTree then
			local v357_, v358_, v359_ = getWorldTranslation(shape)
			v355_ = math.abs(v357_) + math.abs(v358_) + math.abs(v359_)
			v356_ = 1
		else
			v356_ = 0
			v355_ = 80
		end
	else
		v356_ = self.activeDecayingSplitShapes[oldShape].state
		v355_ = self.activeDecayingSplitShapes[oldShape].variation
	end
	if v356_ ~= nil and getNumOfChildren(shape) > 0 then
		self.activeDecayingSplitShapes[shape] = {
			["state"] = v356_,
			["variation"] = v355_
		}
		self:setSplitShapeLeafScaleAndVariation(shape, v356_, v355_)
	end
	g_messageCenter:publish(MessageType.TREE_SHAPE_CUT, oldShape, shape)
end

function TreePlantManager:removingSplitShape(shape)
	self.activeDecayingSplitShapes[shape] = nil
end

-- Local values: treeType, x, y, z, rx, ry, rz, treeIndex, newTreeNode
function TreePlantManager:replaceWithTreeType(node, treeTypeIndex)
	local v365_ = self:getTreeTypeDescFromIndex(treeTypeIndex)
	if v365_ == nil then
		return nil
	end
	local v366_, v367_, v368_ = getWorldTranslation(node)
	local v369_, v370_, v371_ = getWorldRotation(node)
	local v372_ = self:plantTree(v365_.index, v366_, v367_, v368_, v369_, v370_, v371_, 1, 1, false)
	if v372_ ~= nil then
		delete(node)
	end
	return v372_
end

function TreePlantManager:setSplitShapeLeafScaleAndVariation(shape, scale, variation)
	setShaderParameterRecursive(shape, "windSnowLeafScale", 0, 0, scale, variation, false)
end

-- Local values: x, y, z
function TreePlantManager:consoleCommandCutTrees(radius)
	local v378_ = tonumber(radius) or 50
	self.commandCutTreeData = {}
	self.commandCutTreeData.trees = {}
	local v379_, v380_, v381_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	overlapSphere(v379_, v380_, v381_, v378_, "onTreeCutCommandOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	return string.format("Found %d trees to cut in a %dm radius", #self.commandCutTreeData.trees, v378_)
end
function TreePlantManager.onTreeCutCommandOverlapCallback(p382_, p383_, ...)
	if getHasClassId(p383_, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(p383_) ~= 0 and (getRigidBodyType(p383_) == RigidBodyType.STATIC and not getIsSplitShapeSplit(p383_))) then
		local v384_ = p382_.commandCutTreeData.trees
		table.insert(v384_, p383_)
	end
end

function TreePlantManager:onTreeCutCommandSplitCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	rotate(shape, 0.1, 0, 0)
	g_currentMission:addKnownSplitShape(shape)
	self:addingSplitShape(shape, self.commandCutTreeData.shapeBeingCut, true)
end

-- Local values: x, y, z, dirX, dirZ, amount, usage, treeTypeDesc, variationIndex
function TreePlantManager:consoleCommandLoadTree(length, treeType, growthStage, delimb)
	local v392_, v393_, v394_ = g_localPlayer:getPosition()
	local v395_, v396_ = g_localPlayer:getCurrentFacingDirection()
	local v397_ = v392_ + v395_ * 4
	local v398_ = v394_ + v396_ * 4
	local v399_ = v393_ + 1
	if Platform.isMobile then
		local v400_ = tonumber(length)
		if v400_ == nil then
			return "No amount given. (gsTreeAdd amount)"
		end
		WoodHarvesterLight.spawnLogs("data/maps/trees/logs/pineLog.i3d", v400_, v397_, v399_, v398_, MathUtil.getYRotationFromDirection(v395_, v396_), 0.4, 5, self:getFarmId())
		return "Spawned log(s)"
	end
	local v401_ = tonumber(length)
	local v402_ = "gsTreeAdd length [type (available: " .. table.concatKeys(self.nameToTreeType, " ") .. ")] [growthStage] [delimb true/false]"
	if v401_ == nil then
		return "No length given. " .. v402_
	end
	if treeType == nil then
		treeType = "beech"
		growthStage = 7
	end
	local v403_ = self:getTreeTypeDescFromName(treeType)
	if v403_ == nil then
		return "Invalid tree type. " .. v402_
	end
	local v404_ = tonumber(growthStage) or #v403_.stages
	local v405_ = #v403_.stages
	local v406_ = math.clamp(v404_, 1, v405_)
	self:loadTreeTrunk(v403_, v397_, v399_, v398_, v395_, 0, v396_, v401_, v406_, math.random(1, #v403_.stages[v406_]), (Utils.stringToBoolean(delimb or "true")))
	return "Loaded tree"
end

-- Local values: usage, treeType, x, y, z, dirX, dirZ, numPlantedTrees, i, tx, tz, ty, ry
function TreePlantManager:consoleCommandPlantTrees(treeTypeName, number, growthStateI, variationIndex, isGrowing)
	local v413_ = "Usage: gsTreePlant treeType number growthState variationIndex isGrowing"
	local v414_ = self:getTreeTypeDescFromName(treeTypeName)
	if treeTypeName ~= nil and v414_ == nil then
		printError(string.format("Error: unknown tree type %q", treeTypeName))
		print("Available types:\n" .. table.concatKeys(g_treePlantManager.nameToTreeType, ", "))
		return v413_
	end
	local v415_ = v414_ or self:getTreeTypeDescFromName("lodgepolePine") or (self:getTreeTypeDescFromName("aspen") or self.treeTypes[1])
	local v416_ = tonumber(number) or 1
	local v417_ = tonumber(growthStateI) or #v415_.stages
	local v418_ = #v415_.stages
	local v419_ = math.clamp(v417_, 1, v418_)
	local v420_ = tonumber(variationIndex) or math.random(1, #v415_.stages[v419_])
	local v421_ = #v415_.stages[v419_]
	local v422_ = math.clamp(v420_, 1, v421_)
	local v423_ = Utils.stringToBoolean(isGrowing)
	local v424_, v425_, v426_ = g_localPlayer:getPosition()
	local v427_, v428_ = g_localPlayer:getCurrentFacingDirection()
	local v429_ = v424_ + v427_ * 5
	local v430_ = v426_ + v428_ * 5
	local v431_ = 0
	for v432_ = 0, v416_ - 1 do
		local v433_ = v429_ + v427_ * v432_ * 5
		local v434_ = v430_ + v428_ * v432_ * 5
		local v435_ = getTerrainHeightAtWorldPos(g_terrainNode, v433_, v425_, v434_)
		local v436_ = math.random() * 2 * 3.141592653589793
		self.plantTreeCommandHasCollision = false
		overlapBox(v433_, v435_, v434_, 0, 0, 0, 0.5, 1, 0.5, "onTreeOverlapCheckCallback", self, CollisionFlag.TREE)
		if self.plantTreeCommandHasCollision then
			printWarning("Warning: skipped tree due to overlap with existing tree")
		elseif self:plantTree(v415_.index, v433_, v435_, v434_, 0, v436_, 0, v419_, v422_, v423_) then
			v431_ = v431_ + 1
		end
	end
	return string.format("Planted %d trees of type %s", v431_, v415_.name)
end

-- Local values: x, _, z, dirX, dirZ, yRot, xOffset, zOffset, numPlantedTrees, index, treeType, tx, tz, stageIndex, stage, variationIndex, variation, ty, treeId, splitShapeId, splitTypeIndex, splitTypeName, allowWoodHarvester, sizeX, sizeY, sizeZ, numConvexes, numAttachments, boundingBox, dir0X, dir0Y, dir0Z, dir1X, dir1Y, dir1Z, _, _, _, centerX, centerY, centerZ, extent0, extent1, extent2, sx, sy, sz, debugPlane, debugText, rCenterX, rCenterY, rCenterZ, _, _, _, radius, color, debugCircleRadius1, debugTextRadius1, color, debugCircleRadius2, debugTextRadius2, splitShapeDescStr, debugText
function TreePlantManager:consoleCommandLoadAll(treeTypeName, number, growthStateI, variationIndex, isGrowing)
	g_debugManager:removeGroup("treeLoadAll")
	local v438_, _, v439_ = g_localPlayer:getPosition()
	local v440_, v441_ = g_localPlayer:getCurrentFacingDirection()
	local v442_ = MathUtil.getYRotationFromDirection(-v440_, -v441_)
	local v443_ = v438_ + v440_ * 5
	local v444_ = v439_ + v441_ * 5
	local v445_ = 0
	for v446_, v447_ in ipairs(self.treeTypes) do
		local v448_ = v443_ + v441_ * v446_ * 10
		local v449_ = v444_ - v440_ * v446_ * 10
		for v450_, v451_ in ipairs(v447_.stages) do
			for v452_, v453_ in ipairs(v451_) do
				local v454_ = getTerrainHeightAtWorldPos(g_terrainNode, v448_, 0, v449_)
				local v455_ = self:plantTree(v447_.index, v448_, v454_, v449_, 0, math.random() * 3.141592653589793, 0, v450_, v452_, false)
				if v455_ ~= nil and v455_ ~= 0 then
					local v456_ = getChildAt(getChildAt(v455_, 0), 0)
					local v457_, v458_, v459_, v460_, v461_, v462_, v463_, v464_
					if v456_ == 0 or not getHasClassId(v456_, ClassIds.MESH_SPLIT_SHAPE) then
						v457_ = nil
						v458_ = nil
						v459_ = nil
						v460_ = -1
						v461_ = nil
						v462_ = nil
						v463_ = "<NO_SPLIT_TYPE>"
						v464_ = false
					else
						v460_ = getSplitType(v456_)
						v463_ = g_splitShapeManager:getSplitTypeNameByIndex(v460_)
						v464_ = g_splitShapeManager:getSplitShapeAllowsHarvester(v456_)
						v459_, v461_, v462_, v457_, v458_ = getSplitShapeStats(v456_)
						local v465_ = getSplitShapeOrientedBoundingBox(v456_)
						local v466_, v467_, v468_, v469_, v470_, v471_, _, _, _, v472_, _, v473_, _, v474_, v475_ = unpack(v465_)
						local v476_, v477_, v478_ = localToWorld(v456_, v472_, 0, v473_)
						local v479_, v480_, v481_ = localDirectionToWorld(v456_, v469_, v470_, v471_)
						local v482_, v483_, v484_ = localDirectionToWorld(v456_, v466_, v467_, v468_)
						local v485_ = DebugPlane.new():createFromPosAndDir(v476_, v477_, v478_, v479_, v480_, v481_, v482_, v483_, v484_, v475_ * 2, v474_ * 2)
						v485_.color = v464_ and Color.PRESETS.GREEN or Color.PRESETS.RED
						g_debugManager:addElement(v485_, "treeLoadAll")
						local v486_ = DebugText3D.new():createWithWorldPos(v476_ - v440_ * 0.75, v477_ + 0.1, v478_ - v441_ * 0.75, 0, v442_, 0, string.format("Area: %.1fm\194\178", v461_ * v462_), 0.07)
						v486_.color = v485_.color
						g_debugManager:addElement(v486_, "treeLoadAll")
						local v487_, v488_, v489_, _, _, _, v490_ = SplitShapeUtil.getTreeOffsetPosition(v456_, v448_, v454_ + 0.5, v449_, 20, 0)
						if v487_ ~= nil then
							local v491_ = v490_ <= 0.601 and (v490_ <= 0.351 and Color.PRESETS.GREEN or Color.PRESETS.ORANGE) or Color.PRESETS.RED
							local v492_ = DebugCircle.new():createWithWorldPos(v487_, v488_, v489_, v490_, v491_, 20, false, false, false, false)
							g_debugManager:addElement(v492_, "treeLoadAll")
							local v493_ = DebugText3D.new():createWithWorldPos(v487_ - v440_ * v490_ * 1.2, v488_, v489_ - v441_ * v490_ * 1.2, 0, v442_, 0, string.format("Diameter: %.1fcm", v490_ * 200), 0.05)
							v493_.color = v491_
							g_debugManager:addElement(v493_, "treeLoadAll")
						end
						local v494_, v495_, v496_, _, _, _, v497_ = SplitShapeUtil.getTreeOffsetPosition(v456_, v448_, v454_ + 1, v449_, 20, 0)
						if v494_ ~= nil then
							local v498_ = v497_ <= 0.601 and (v497_ <= 0.351 and Color.PRESETS.GREEN or Color.PRESETS.ORANGE) or Color.PRESETS.RED
							local v499_ = DebugCircle.new():createWithWorldPos(v494_, v495_, v496_, v497_, v498_, 20, false, false, false, false)
							g_debugManager:addElement(v499_, "treeLoadAll")
							local v500_ = DebugText3D.new():createWithWorldPos(v494_ - v440_ * v497_ * 1.2, v495_, v496_ - v441_ * v497_ * 1.2, 0, v442_, 0, string.format("Diameter: %.1fcm", v497_ * 200), 0.05)
							v500_.color = v498_
							g_debugManager:addElement(v500_, "treeLoadAll")
						end
					end
					local v501_ = v459_ == nil and "" or string.format("\nSplit Shape Size: Height: %.2f | Width: %.2f | Length: %.2f | Area: %.2f m\194\178 | convexes: %d | attachments: %d", v459_, v461_, v462_, v461_ * v462_, v457_, v458_)
					local v502_ = DebugText3D.new():createWithWorldPos(v448_ - v440_, v454_ + 0.5, v449_ - v441_, 0, v442_, 0, string.format("%s : %s\nsplitType: %s / %s%s%s", v447_.name, Utils.getFilenameInfo(v453_.filename, true), v460_, v463_, v501_, v464_ and "\n\nSupports Wood Harvester" or ""), 0.07)
					if v464_ then
						v502_:setColor(Color.PRESETS.GREEN)
					end
					g_debugManager:addElement(v502_, "treeLoadAll")
					self:loadTreeTrunk(v447_, v448_ + v441_ * 2, v454_, v449_ - v440_ * 2, v440_, 0, v441_, 0.25, v450_, v452_, true, true)
					v445_ = v445_ + 1
					v448_ = v448_ + v440_ * 10
					v449_ = v449_ + v441_ * 10
				end
			end
		end
	end
	return string.format("Planted %d trees", v445_)
end
function TreePlantManager.onTreeOverlapCheckCallback(p503_, p504_, ...)
	if getHasClassId(p504_, ClassIds.SHAPE) and getHasClassId(p504_, ClassIds.MESH_SPLIT_SHAPE) then
		p503_.plantTreeCommandHasCollision = true
	end
end

-- Local values: cam, wx, wy, wz, dx, dy, dz, distance, callbackTarget
function TreePlantManager:consoleCommandRemoveSplitShape()
	local v505_ = getCamera()
	local v506_, v507_, v508_ = getWorldTranslation(v505_)
	local v509_, v510_, v511_ = localDirectionToWorld(v505_, 0, 0, -1)
	if raycastClosest(v506_, v507_, v508_, v509_, v510_, v511_, 10, "callback", {
		["callback"] = function(_, p512_, ...)
			if p512_ ~= 0 then
				local v513_, v514_, _, _, v515_, v516_ = getRigidBodyAABB(p512_)
				if getName(p512_) == "LOD0" and getRigidBodyType(p512_) == RigidBodyType.STATIC then
					p512_ = getParent(p512_)
				end
				Logging.info("removed %s (%d)", I3DUtil.getNodePath(p512_), p512_)
				delete(p512_)
				g_densityMapHeightManager:setCollisionMapAreaDirty(v513_, v515_, v514_, v516_, true)
				g_currentMission.aiSystem:setAreaDirty(v513_, v515_, v514_, v516_)
			end
		end
	}, CollisionFlag.TREE) == 0 then
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
	local v518_ = self.debugActive
	return "Tree/Splitshape debug = " .. tostring(v518_)
end
g_treePlantManager = TreePlantManager.new()
