WoodHarvesterLight = {}
WoodHarvesterLight.SPAWN_COLLISION_MASK = CollisionFlag.STATIC_OBJECT + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.ANIMAL

function WoodHarvesterLight.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AutomaticArmControlHarvester, specializations)
	end
	return v2_
end
function WoodHarvesterLight.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("woodHarvesterLight", g_i18n:getText("shop_configuration"), "woodHarvesterLight", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("WoodHarvesterLight")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvesterLight.cutNode#node", "Cut node")
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutNode#maxRadius", "Max. radius of the tree", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutNode#sizeY", "Size in Y direction", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutNode#sizeZ", "Size in Z direction", 1)
	v3_:register(XMLValueType.STRING, "vehicle.woodHarvesterLight.cutAnimation#name", "Cut animation name")
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutAnimation#speedScale", "Cut animation speed scale")
	v3_:register(XMLValueType.STRING, "vehicle.woodHarvesterLight.grabAnimation#name", "Grab animation name")
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.grabAnimation#speedScale", "Grab animation speed scale")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvesterLight.logSpawner#startNode", "Start reference node for spawning (end node is the tree)")
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.logSpawner#offset", "Offset from tree", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.logSpawner#maxSpawnWidth", "Max. spawning width to the left and right", 10)
	v3_:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.logSpawner#additionalLength", "Length of area behind the tree that can be used for the spawning", 4)
	EffectManager.registerEffectXMLPaths(v3_, "vehicle.woodHarvesterLight.cutEffects")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.woodHarvesterLight.sounds", "cut")
	v3_:setXMLSpecializationType()
end

function WoodHarvesterLight.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateLogSpawner", WoodHarvesterLight.updateLogSpawner)
	SpecializationUtil.registerFunction(vehicleType, "onWoodHarversterLogSpawnerCallback", WoodHarvesterLight.onWoodHarversterLogSpawnerCallback)
	SpecializationUtil.registerFunction(vehicleType, "spawnLogHeap", WoodHarvesterLight.spawnLogHeap)
	SpecializationUtil.registerFunction(vehicleType, "spawnTreeStump", WoodHarvesterLight.spawnTreeStump)
end

function WoodHarvesterLight.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsAutoTreeAlignment", WoodHarvesterLight.getSupportsAutoTreeAlignment)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoAlignHasValidTree", WoodHarvesterLight.getAutoAlignHasValidTree)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", WoodHarvesterLight.getAreControlledActionsAllowed)
end

function WoodHarvesterLight.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodHarvesterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodHarvesterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodHarvesterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodHarvesterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodHarvesterLight)
end

-- Local values: spec
function WoodHarvesterLight:onLoad(savegame)
	local v8_ = self.spec_woodHarvesterLight
	v8_.cutNode = {}
	v8_.cutNode.node = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#node", nil, self.components, self.i3dMappings)
	v8_.cutNode.maxRadius = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#maxRadius", 1)
	v8_.cutNode.sizeY = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#sizeY", 1)
	v8_.cutNode.sizeZ = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#sizeZ", 1)
	v8_.cutAnimation = {}
	v8_.cutAnimation.name = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutAnimation#name")
	v8_.cutAnimation.speedScale = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutAnimation#speedScale", 1)
	v8_.grabAnimation = {}
	v8_.grabAnimation.name = self.xmlFile:getValue("vehicle.woodHarvesterLight.grabAnimation#name")
	v8_.grabAnimation.speedScale = self.xmlFile:getValue("vehicle.woodHarvesterLight.grabAnimation#speedScale", 1)
	v8_.logSpawner = {}
	v8_.logSpawner.startNode = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#startNode", nil, self.components, self.i3dMappings)
	v8_.logSpawner.offset = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#offset", 1)
	v8_.logSpawner.maxSpawnWidth = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#maxSpawnWidth", 10)
	v8_.logSpawner.additionalLength = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#additionalLength", 4)
	v8_.logSpawner.currentCheckIndex = 0
	v8_.logSpawner.hasValidBox = false
	v8_.logSpawner.validCheckBoxIndex = 0
	v8_.logSpawner.lastValidBox = {
		0,
		0,
		0,
		0
	}
	v8_.logSpawner.lastBoxToCheck = {
		0,
		0,
		0,
		0
	}
	v8_.logSpawner.logFilename = "data/maps/trees/logs/pineLog.i3d"
	v8_.logSpawner.logSize = { 0.4, 5 }
	v8_.logSpawner.logVolume = 0.66
	v8_.curSplitShape = nil
	if self.isClient then
		v8_.cutEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.woodHarvesterLight.cutEffects", self.components, self, self.i3dMappings)
		v8_.samples = {}
		v8_.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodHarvesterLight.sounds", "cut", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	if v8_.cutNode.node == nil then
		SpecializationUtil.removeEventListener(self, "onUpdate", WoodHarvesterLight)
		SpecializationUtil.removeEventListener(self, "onTurnedOn", WoodHarvesterLight)
		SpecializationUtil.removeEventListener(self, "onTurnedOff", WoodHarvesterLight)
	end
	v8_.texts = {}
	v8_.texts.warning_woodHarvesterNoTreeInRange = g_i18n:getText("warning_woodHarvesterNoTreeInRange")
	v8_.texts.warning_woodHarvesterNoSpawnPlace = g_i18n:getText("warning_woodHarvesterNoSpawnPlace")
	v8_.texts.warning_woodHarvesterTreeNotAllowed = g_i18n:getText("warning_youAreNotAllowedToCutThisTree")
	v8_.texts.warning_woodHarvesterTreeTypeNotSupported = g_i18n:getText("warning_treeTypeNotSupported")
	v8_.texts.warning_woodHarvesterTreeTooThick = g_i18n:getText("warning_treeTooThick")
end

-- Local values: spec
function WoodHarvesterLight:onDelete()
	local v10_ = self.spec_woodHarvesterLight
	if self.isClient then
		g_effectManager:deleteEffects(v10_.cutEffects)
		g_soundManager:deleteSamples(v10_.samples)
	end
end

-- Local values: spec, x, y, z, nx, ny, nz, yx, yy, yz, splitShapeId, _, _, _, _, animTime, volume, tx, ty, tz, total, _, _, plantedTreeCount, tx, ty, tz, radius
function WoodHarvesterLight:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v12_ = self.spec_woodHarvesterLight
	v12_.curSplitShape = nil
	if self:getIsTurnedOn() then
		local v13_, v14_, v15_ = localToWorld(v12_.cutNode.node, 0, 0, 0)
		local v16_, v17_, v18_ = localDirectionToWorld(v12_.cutNode.node, 1, 0, 0)
		local v19_, v20_, v21_ = localDirectionToWorld(v12_.cutNode.node, 0, 1, 0)
		local v22_, _, _, _, _ = findSplitShape(v13_, v14_, v15_, v16_, v17_, v18_, v19_, v20_, v21_, v12_.cutNode.sizeY, v12_.cutNode.sizeZ)
		if v22_ == 0 or getUserAttribute(v22_, "isTreeStump") == true then
			if self:getAnimationTime(v12_.cutAnimation.name) > 0.99 then
				self:setAnimationTime(v12_.cutAnimation.name, 0)
				if Platform.gameplay.automaticVehicleControl then
					self:playControlledActions()
				end
			end
		else
			v12_.curSplitShape = v22_
			if not (self:getIsAutomaticAlignmentActive() or self:getIsAnimationPlaying(v12_.cutAnimation.name)) then
				local v23_ = self:getAnimationTime(v12_.cutAnimation.name)
				if v23_ < 0.5 then
					self:setAnimationTime(v12_.cutAnimation.name, 0)
					self:playAnimation(v12_.cutAnimation.name, v12_.cutAnimation.speedScale, self:getAnimationTime(v12_.cutAnimation.name))
					if self.isClient then
						g_effectManager:setEffectTypeInfo(v12_.cutEffects, FillType.WOODCHIPS)
						g_effectManager:startEffects(v12_.cutEffects)
						g_soundManager:playSample(v12_.samples.cut)
					end
				elseif v23_ >= 0.5 then
					self:setAnimationTime(v12_.cutAnimation.name, 0)
					if self.isClient then
						g_effectManager:stopEffects(v12_.cutEffects)
						g_soundManager:stopSample(v12_.samples.cut)
					end
					g_currentMission:removeKnownSplitShape(v22_)
					if getVolume(v22_) ~= 0 then
						self:spawnLogHeap(getSplitType(v22_), getVolume(v22_))
						local v24_, v25_, v26_ = getWorldTranslation(v22_)
						self:spawnTreeStump(v24_, v25_, v26_)
					end
					delete(getParent(v22_))
					g_treePlantManager:removingSplitShape(v22_)
					local v27_, _ = g_farmManager:updateFarmStats(self:getActiveFarm(), "cutTreeCount", 1)
					if v27_ ~= nil then
						g_achievementManager:tryUnlock("CutTreeFirst", v27_)
						g_achievementManager:tryUnlock("CutTree", v27_)
						if v27_ == 1 then
							g_currentMission.introductionHelpSystem:showHint("forestryFirstTree")
						elseif v27_ == 20 then
							local _, v28_ = g_farmManager:getFarmStatValue(self:getActiveFarm(), "plantedTreeCount")
							if v28_ == 0 then
								g_currentMission.introductionHelpSystem:showHint("forestryStumpCutter")
							end
						end
					end
					if Platform.gameplay.automaticVehicleControl then
						self:playControlledActions()
					end
				end
			end
		end
	end
	local v29_, v30_, v31_, v32_ = self:getAutomaticAlignmentCurrentTarget()
	if v29_ == nil then
		v12_.logSpawner.lastOverlapCheckIsBlocked = false
		v12_.logSpawner.pendingOverlapCheck = false
		v12_.logSpawner.currentCheckIndex = 0
		v12_.logSpawner.validCheckBoxIndex = 0
		v12_.logSpawner.hasValidBox = false
	else
		self:updateLogSpawner(v29_, v30_, v31_, v32_)
	end
end

-- Local values: spec
function WoodHarvesterLight:onTurnedOn()
	local v34_ = self.spec_woodHarvesterLight
	self:playAnimation(v34_.grabAnimation.name, v34_.grabAnimation.speedScale, self:getAnimationTime(v34_.grabAnimation.name), true)
end

-- Local values: spec
function WoodHarvesterLight:onTurnedOff()
	local v36_ = self.spec_woodHarvesterLight
	self:playAnimation(v36_.grabAnimation.name, -v36_.grabAnimation.speedScale, self:getAnimationTime(v36_.grabAnimation.name), true)
	if self.isClient then
		g_effectManager:stopEffects(v36_.cutEffects)
		g_soundManager:stopSamples(v36_.samples)
	end
end

function WoodHarvesterLight:getSupportsAutoTreeAlignment(superFunc)
	return true
end

-- Local values: spec
function WoodHarvesterLight:getAutoAlignHasValidTree(superFunc, radius)
	local v39_ = self.spec_woodHarvesterLight
	return v39_.curSplitShape ~= nil, radius <= v39_.cutNode.maxRadius
end

-- Local values: spec, reason, x, _, _, _
function WoodHarvesterLight:getAreControlledActionsAllowed(superFunc)
	if self:getActionControllerDirection() == 1 then
		local v42_ = self.spec_woodHarvesterLight
		local v43_ = self:getAutomaticAlignmentInvalidTreeReason()
		if v43_ == AutomaticArmControlHarvester.INVALID_REASON_NONE then
			local v44_, _, _, _ = self:getAutomaticAlignmentCurrentTarget()
			if v44_ == nil then
				return false, v42_.texts.warning_woodHarvesterNoTreeInRange
			end
			if not v42_.logSpawner.hasValidBox then
				return false, v42_.texts.warning_woodHarvesterNoSpawnPlace
			end
		else
			if v43_ == AutomaticArmControlHarvester.INVALID_REASON_NO_ACCESS then
				return false, v42_.texts.warning_woodHarvesterTreeNotAllowed
			end
			if v43_ == AutomaticArmControlHarvester.INVALID_REASON_WRONG_TYPE then
				return false, v42_.texts.warning_woodHarvesterTreeTypeNotSupported
			end
			if v43_ == AutomaticArmControlHarvester.INVALID_REASON_TOO_THICK then
				return false, v42_.texts.warning_woodHarvesterTreeTooThick
			end
		end
	end
	return superFunc(self)
end

-- Local values: spec, requiredWidth, requiredHeight, requiredLength, ex, ey, ez, sx, _, sz, dx, dz, ry, zOffset, xOffset, offsetDistance, offsetDirection, x, z, y
function WoodHarvesterLight:updateLogSpawner(tx, ty, tz, radius)
	local v49_ = self.spec_woodHarvesterLight
	if not v49_.logSpawner.pendingOverlapCheck then
		if v49_.logSpawner.lastOverlapCheckIsBlocked then
			if v49_.logSpawner.currentCheckIndex > v49_.logSpawner.validCheckBoxIndex then
				v49_.logSpawner.hasValidBox = false
				v49_.logSpawner.validCheckBoxIndex = 0
			end
		else
			v49_.logSpawner.hasValidBox = true
			local v50_ = v49_.logSpawner.lastValidBox
			local v51_ = v49_.logSpawner.lastValidBox
			local v52_ = v49_.logSpawner.lastValidBox
			local v53_ = v49_.logSpawner.lastValidBox
			local v54_ = v49_.logSpawner.lastBoxToCheck[1]
			local v55_ = v49_.logSpawner.lastBoxToCheck[2]
			local v56_ = v49_.logSpawner.lastBoxToCheck[3]
			local v57_ = v49_.logSpawner.lastBoxToCheck[4]
			v50_[1] = v54_
			v51_[2] = v55_
			v52_[3] = v56_
			v53_[4] = v57_
			v49_.logSpawner.validCheckBoxIndex = v49_.logSpawner.currentCheckIndex
			v49_.logSpawner.currentCheckIndex = 0
		end
	end
	local v58_ = v49_.logSpawner.logSize[1] * 5
	local v59_ = v49_.logSpawner.logSize[2] + 0.5
	local v60_ = v58_ * 0.5
	local v61_ = v59_ * 0.5
	local v62_, _, v63_ = getWorldTranslation(v49_.logSpawner.startNode)
	local v64_, v65_ = MathUtil.vector2Normalize(tx - v62_, tz - v63_)
	local v66_ = MathUtil.getYRotationFromDirection(v64_, v65_)
	local v67_ = 0
	local v68_ = radius + v49_.logSpawner.offset + v58_ * 0.5
	local v69_ = v49_.logSpawner.currentCheckIndex / 5
	local v70_ = math.floor(v69_) * 2
	local v71_ = v49_.logSpawner.currentCheckIndex % 5
	if v71_ == 0 then
		v68_ = v68_ + v70_
	elseif v71_ == 1 then
		v68_ = -(v68_ + v70_)
	elseif v71_ == 2 then
		v67_ = v67_ - v70_
		v68_ = v68_ + v60_
	elseif v71_ == 3 then
		v67_ = v67_ - v70_
		v68_ = -(v68_ + v60_)
	elseif v71_ == 4 then
		v67_ = v59_ + v70_
		v68_ = 0
	end
	if v49_.logSpawner.maxSpawnWidth < v70_ then
		v49_.logSpawner.currentCheckIndex = 0
	end
	local v72_ = tx + v64_ * v67_ + v65_ * v68_
	local v73_ = tz + v65_ * v67_ - v64_ * v68_
	local v74_ = getTerrainHeightAtWorldPos(g_terrainNode, v72_, 0, v73_)
	if not v49_.logSpawner.pendingOverlapCheck then
		v49_.logSpawner.lastOverlapCheckIsBlocked = false
		v49_.logSpawner.pendingOverlapCheck = true
		local v75_ = v49_.logSpawner.lastBoxToCheck
		local v76_ = v49_.logSpawner.lastBoxToCheck
		local v77_ = v49_.logSpawner.lastBoxToCheck
		local v78_ = v49_.logSpawner.lastBoxToCheck
		v75_[1] = v72_
		v76_[2] = v74_
		v77_[3] = v73_
		v78_[4] = v66_
		overlapBoxAsync(v72_, v74_, v73_, 0, v66_, 0, v60_, 2.5, v61_, "onWoodHarversterLogSpawnerCallback", self, WoodHarvesterLight.SPAWN_COLLISION_MASK, true, true, true, true)
	end
end
function WoodHarvesterLight.onWoodHarversterLogSpawnerCallback(p79_, p80_, ...)
	local v81_ = p79_.spec_woodHarvesterLight
	if p80_ ~= 0 and not (getHasClassId(p80_, ClassIds.TERRAIN_TRANSFORM_GROUP) or v81_.logSpawner.lastOverlapCheckIsBlocked) then
		v81_.logSpawner.lastOverlapCheckIsBlocked = true
		v81_.logSpawner.currentCheckIndex = v81_.logSpawner.currentCheckIndex + 1
	end
	v81_.logSpawner.pendingOverlapCheck = false
end

-- Local values: spec
function WoodHarvesterLight:spawnLogHeap(splitTypeIndex, treeVolume)
	local v84_ = self.spec_woodHarvesterLight
	if v84_.logSpawner.hasValidBox then
		local v85_ = WoodHarvesterLight.spawnLogs
		local v86_ = v84_.logSpawner.logFilename
		local v87_ = treeVolume / v84_.logSpawner.logVolume
		local v88_ = math.floor(v87_)
		v85_(v86_, math.max(v88_, 1), v84_.logSpawner.lastValidBox[1], v84_.logSpawner.lastValidBox[2], v84_.logSpawner.lastValidBox[3], v84_.logSpawner.lastValidBox[4], v84_.logSpawner.logSize[1], v84_.logSpawner.logSize[2], self:getOwnerFarmId())
	end
end

-- Local values: bDirX, bDirZ, spawnPositions, numTopRow, numBaseRow, hLength, i, sideOffset, sx, sy, sz, ex, ey, ez, cx, cy, cz, dx, dy, dz, i, startPosition, endPosition, sx, sy, sz, ex, ey, ez, yOffset, cx, cy, cz, dx, dy, dz, tempHelperNode, i, cx, cy, cz, dx, dy, dz, rx, ry, rz, forestryLog
function WoodHarvesterLight.spawnLogs(filename, numTrees, bx, by, bz, bry, lDiameter, lLength, farmId)
	local v98_, v99_ = MathUtil.getDirectionFromYRotation(bry)
	local v100_ = {}
	local v101_
	if numTrees > 2 then
		local v102_ = (numTrees - 1) / 2
		v101_ = math.floor(v102_)
	else
		v101_ = 0
	end
	local v103_ = numTrees - v101_
	local v104_ = lLength * 0.5
	for v105_ = 1, v103_ do
		local v106_ = -v103_ * 0.5 * lDiameter + lDiameter * 0.5 + (v105_ - 1) * lDiameter
		local v107_ = bx + v98_ * v104_ + v99_ * v106_
		local v108_ = bz + v99_ * v104_ - v98_ * v106_
		local v109_ = bx - v98_ * v104_ + v99_ * v106_
		local v110_ = bz - v99_ * v104_ - v98_ * v106_
		local v111_ = getTerrainHeightAtWorldPos(g_terrainNode, v107_, by, v108_) + lDiameter * 0.5
		local v112_ = getTerrainHeightAtWorldPos(g_terrainNode, v109_, by, v110_) + lDiameter * 0.5
		local v113_ = (v107_ + v109_) * 0.5
		local v114_ = (v111_ + v112_) * 0.5
		local v115_ = (v108_ + v110_) * 0.5
		local v116_, v117_, v118_ = MathUtil.vector3Normalize(v107_ - v109_, v111_ - v112_, v108_ - v110_)
		local v119_ = getTerrainHeightAtWorldPos(g_terrainNode, v113_, v114_, v115_) + lDiameter * 0.5
		local v120_ = {
			["sx"] = v113_ + v116_ * v104_,
			["sy"] = v119_ + v117_ * v104_,
			["sz"] = v115_ + v118_ * v104_,
			["ex"] = v113_ - v116_ * v104_,
			["ey"] = v119_ - v117_ * v104_,
			["ez"] = v115_ - v118_ * v104_,
			["cx"] = v113_,
			["cy"] = v119_,
			["cz"] = v115_,
			["dx"] = v116_,
			["dy"] = v117_,
			["dz"] = v118_
		}
		table.insert(v100_, v120_)
	end
	for v121_ = 1, v101_ do
		local v122_ = v100_[v121_]
		local v123_ = v100_[v121_ + 1]
		if v122_ ~= nil and v123_ ~= nil then
			local v124_ = (v122_.sx + v123_.sx) * 0.5
			local v125_ = (v122_.sy + v123_.sy) * 0.5
			local v126_ = (v122_.sz + v123_.sz) * 0.5
			local v127_ = (v122_.ex + v123_.ex) * 0.5
			local v128_ = (v122_.ey + v123_.ey) * 0.5
			local v129_ = (v122_.ez + v123_.ez) * 0.5
			local v130_ = math.pow(lDiameter, 2)
			local v131_ = lDiameter * 0.5
			local v132_ = v130_ - math.pow(v131_, 2)
			local v133_ = math.sqrt(v132_)
			local v134_ = v125_ + v133_
			local v135_ = v128_ + v133_
			local v136_ = (v124_ + v127_) * 0.5
			local v137_ = (v134_ + v135_) * 0.5
			local v138_ = (v126_ + v129_) * 0.5
			local v139_, v140_, v141_ = MathUtil.vector3Normalize(v124_ - v127_, v134_ - v135_, v126_ - v129_)
			table.insert(v100_, {
				["sx"] = v124_,
				["sy"] = v134_,
				["sz"] = v126_,
				["ex"] = v127_,
				["ey"] = v135_,
				["ez"] = v129_,
				["cx"] = v136_,
				["cy"] = v137_,
				["cz"] = v138_,
				["dx"] = v139_,
				["dy"] = v140_,
				["dz"] = v141_
			})
		end
	end
	local v142_ = createTransformGroup("tempHelperNode")
	link(getRootNode(), v142_)
	for v143_ = 1, #v100_ do
		local v144_ = v100_[v143_].cx
		local v145_ = v100_[v143_].cy
		local v146_ = v100_[v143_].cz
		local v147_ = v100_[v143_].dx
		local v148_ = v100_[v143_].dy
		local v149_ = v100_[v143_].dz
		setTranslation(v142_, v144_, v145_, v146_)
		setDirection(v142_, v147_, v148_, v149_, 0, 1, 0)
		local v150_, v151_, v152_ = getRotation(v142_)
		local v153_ = ForestryLog.new(g_currentMission:getIsServer(), g_client ~= nil)
		v153_:loadFromFilename(filename, v144_, v145_, v146_, v150_, v151_, v152_)
		v153_:setOwnerFarmId(farmId)
	end
	delete(v142_)
end

-- Local values: treeType
function WoodHarvesterLight:spawnTreeStump(x, y, z)
	local v157_ = g_treePlantManager:getTreeTypeDescFromName("pineStump")
	if v157_ ~= nil then
		g_treePlantManager:plantTree(v157_.index, x, y, z, 0, 0, 0, 1, 1, false, nil)
	end
end
