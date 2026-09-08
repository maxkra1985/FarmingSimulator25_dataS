StumpCutter = {}
StumpCutter.CLIENT_DM_UPDATE_RADIUS = 50

function StumpCutter.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function StumpCutter.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("stumpCutter", true, false, false)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("StumpCutter")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.stumpCutter.cutNode(?)#node", "Cut node")
	v2_:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutSizeY", "Cut size Y", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutSizeZ", "Cut size X", 1)
	v2_:register(XMLValueType.TIME, "vehicle.stumpCutter.cutNode(?)#maxCutTime", "Time until cut", 4)
	v2_:register(XMLValueType.TIME, "vehicle.stumpCutter.cutNode(?)#maxResetCutTime", "Time between cuts", 4)
	v2_:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutFullTreeThreshold", "If the tree length below the cut node is smaller than this value it gets removed", 0.4)
	v2_:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutPartThreshold", "Cut part threshold", 0.2)
	v2_:register(XMLValueType.INT, "vehicle.stumpCutter.cutNode(?)#workAreaIndex", "Work area index")
	v2_:register(XMLValueType.TIME, "vehicle.stumpCutter.cutNode(?)#cutDuration", "Cut duration", 1)
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.stumpCutter.cutNode(?).effects")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.stumpCutter.sounds", "start")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.stumpCutter.sounds", "stop")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.stumpCutter.sounds", "idle")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.stumpCutter.sounds", "work")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.stumpCutter.effects")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.stumpCutter.animationNodes")
	v2_:setXMLSpecializationType()
end

function StumpCutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "crushSplitShape", StumpCutter.crushSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "stumpCutterSplitShapeCallback", StumpCutter.stumpCutterSplitShapeCallback)
	SpecializationUtil.registerFunction(vehicleType, "processStumpCutterArea", StumpCutter.processStumpCutterArea)
end

function StumpCutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", StumpCutter.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", StumpCutter.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCultivatorLimitToField", StumpCutter.getCultivatorLimitToField)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPlowLimitToField", StumpCutter.getPlowLimitToField)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPlowForceLimitToField", StumpCutter.getPlowForceLimitToField)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", StumpCutter.getConsumingLoad)
end

function StumpCutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", StumpCutter)
end

-- Local values: spec, baseKey, i, key, node, cutNode
function StumpCutter:onLoad(savegame)
	local v7_ = self.spec_stumpCutter
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.stumpCutter.animationNodes.animationNode", "stumbCutter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterStartSound", "vehicle.stumpCutter.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterIdleSound", "vehicle.stumpCutter.sounds.idle")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterWorkSound", "vehicle.stumpCutter.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterStopSound", "vehicle.stumpCutter.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter.emitterShape(0)", "vehicle.stumpCutter.effects.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter.particleSystem(0)", "vehicle.stumpCutter.effects.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutNode", "vehicle.stumpCutter.cutNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutSizeY", "vehicle.stumpCutter.cutNode#cutSizeY")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutSizeZ", "vehicle.stumpCutter.cutNode#cutSizeZ")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutFullTreeThreshold", "vehicle.stumpCutter.cutNode#cutFullTreeThreshold")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutPartThreshold", "vehicle.stumpCutter.cutNode#cutPartThreshold")
	v7_.cutNodes = {}
	v7_.currentCutNodeIndex = 1
	local v8_ = 0
	while true do
		local v9_ = string.format("%s.cutNode(%d)", "vehicle.stumpCutter", v8_)
		if not self.xmlFile:hasProperty(v9_) then
			break
		end
		local v10_ = self.xmlFile:getValue(v9_ .. "#node", nil, self.components, self.i3dMappings)
		if v10_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing \'node\' for \'%s\'!", v9_)
			break
		end
		local v11_ = {
			["node"] = v10_,
			["cutSizeY"] = self.xmlFile:getValue(v9_ .. "#cutSizeY", 1),
			["cutSizeZ"] = self.xmlFile:getValue(v9_ .. "#cutSizeZ", 1),
			["maxCutTime"] = self.xmlFile:getValue(v9_ .. "#maxCutTime", 4)
		}
		v11_.nextCutTime = v11_.maxCutTime
		v11_.maxResetCutTime = self.xmlFile:getValue(v9_ .. "#maxResetCutTime", 1)
		v11_.resetCutTime = v11_.maxResetCutTime
		v11_.cutFullTreeThreshold = self.xmlFile:getValue(v9_ .. "#cutFullTreeThreshold", 0.4)
		v11_.cutPartThreshold = self.xmlFile:getValue(v9_ .. "#cutPartThreshold", 0.2)
		v11_.workAreaIndex = self.xmlFile:getValue(v9_ .. "#workAreaIndex")
		v11_.workTimer = 0
		v11_.workDuration = self.xmlFile:getValue(v9_ .. "#cutDuration", 1)
		v11_.lastWorkTime = -1000
		v11_.workFadeTime = 0
		v11_.maxWorkFadeTime = 1000
		if self.isClient then
			v11_.effects = g_effectManager:loadEffect(self.xmlFile, v9_ .. ".effects", self.components, self, self.i3dMappings)
		end
		local v12_ = v7_.cutNodes
		table.insert(v12_, v11_)
		v8_ = v8_ + 1
	end
	if self.isClient then
		v7_.samples = {}
		v7_.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.samples.idle = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v7_.maxWorkFadeTime = 1000
		v7_.workFadeTime = 0
		v7_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stumpCutter.effects", self.components, self, self.i3dMappings)
		v7_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.stumpCutter.animationNodes", self.components, self, self.i3dMappings)
	end
end

-- Local values: spec, i
function StumpCutter:onDelete()
	local v14_ = self.spec_stumpCutter
	g_soundManager:deleteSamples(v14_.samples)
	g_animationManager:deleteAnimations(v14_.animationNodes)
	g_effectManager:deleteEffects(v14_.effects)
	if v14_.cutNodes ~= nil then
		for v15_ = 1, #v14_.cutNodes do
			g_effectManager:deleteEffects(v14_.cutNodes[v15_].effects)
		end
	end
end

-- Local values: spec, numCutNodes, nextCutNodeIndex, cutNode, x, y, z, nx, ny, nz, yx, yy, yz, shape, _, _, _, _, x1, y1, z1, x2, y2, z2, lenBelow, lenAbove, _, ly, _, curSplitShape, anyCutNodeWorking, i
function StumpCutter:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsTurnedOn() then
		local v18_ = self.spec_stumpCutter
		local v19_ = #v18_.cutNodes
		if v19_ > 0 then
			local v20_ = v18_.currentCutNodeIndex + 1
			local v21_ = v19_ < v20_ and 1 or v20_
			v18_.currentCutNodeIndex = v21_
			local v22_ = v18_.cutNodes[v21_]
			v22_.curLenAbove = 0
			v22_.curLenBelow = 0
			local v23_, v24_, v25_ = getWorldTranslation(v22_.node)
			local v26_, v27_, v28_ = localDirectionToWorld(v22_.node, 1, 0, 0)
			local v29_, v30_, v31_ = localDirectionToWorld(v22_.node, 0, 1, 0)
			if v22_.curSplitShape ~= nil and (not entityExists(v22_.curSplitShape) or testSplitShape(v22_.curSplitShape, v23_, v24_, v25_, v26_, v27_, v28_, v29_, v30_, v31_, v22_.cutSizeY, v22_.cutSizeZ) == nil) then
				v22_.curSplitShape = nil
			end
			if v22_.curSplitShape == nil then
				local v32_, _, _, _, _ = findSplitShape(v23_, v24_, v25_, v26_, v27_, v28_, v29_, v30_, v31_, v22_.cutSizeY, v22_.cutSizeZ)
				if v32_ ~= 0 then
					v22_.curSplitShape = v32_
				end
			end
			if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
				local v33_, v34_, v35_ = localToWorld(v22_.node, 0, 0, v22_.cutSizeZ)
				local v36_, v37_, v38_ = localToWorld(v22_.node, 0, v22_.cutSizeY, 0)
				DebugPlane.renderWithPositions(v23_, v24_, v25_, v33_, v34_, v35_, v36_, v37_, v38_, Color.PRESETS.PINK, false)
			end
			if v22_.curSplitShape == nil then
				local v39_ = v22_.workFadeTime - dt
				v22_.workFadeTime = math.max(0, v39_)
				if self.isServer and v22_.resetCutTime > 0 then
					v22_.resetCutTime = v22_.resetCutTime - dt
					if v22_.resetCutTime <= 0 then
						v22_.nextCutTime = v22_.maxCutTime
					end
				end
			else
				local v40_, v41_ = getSplitShapePlaneExtents(v22_.curSplitShape, v23_, v24_, v25_, v26_, v27_, v28_)
				if v22_.cutPartThreshold <= v41_ then
					v22_.lastWorkTime = g_time
				end
				local v42_ = v22_.maxWorkFadeTime
				local v43_ = v22_.workFadeTime + dt * v19_
				v22_.workFadeTime = math.min(v42_, v43_)
				if self.isServer then
					v22_.resetCutTime = v22_.maxResetCutTime
					if v22_.nextCutTime > 0 then
						v22_.nextCutTime = v22_.nextCutTime - dt
						if v22_.nextCutTime <= 0 then
							local _, v44_, _ = worldToLocal(v22_.curSplitShape, v23_, v24_, v25_)
							if (v40_ <= v22_.cutFullTreeThreshold or v44_ < v22_.cutPartThreshold + 0.01) and v41_ < 1 then
								self:crushSplitShape(v22_.curSplitShape)
								v22_.curSplitShape = nil
							elseif v22_.cutPartThreshold <= v41_ and v22_.cutPartThreshold <= v40_ then
								v22_.nextCutTime = v22_.maxCutTime
								local v45_ = v22_.curSplitShape
								v22_.curSplitShape = nil
								v22_.curLenAbove = v41_
								v22_.curLenBelow = v40_
								self.shapeBeingCut = v45_
								splitShape(v45_, v23_, v24_, v25_, v26_, v27_, v28_, v29_, v30_, v31_, v22_.cutSizeY, v22_.cutSizeZ, "stumpCutterSplitShapeCallback", self)
								g_treePlantManager:removingSplitShape(v45_)
							else
								v22_.curSplitShape = nil
								v22_.nextCutTime = v22_.maxCutTime
							end
						end
					end
				end
			end
			if self.isClient then
				if v22_.lastWorkTime + 500 > g_time then
					g_effectManager:setEffectTypeInfo(v22_.effects, FillType.WOODCHIPS)
					g_effectManager:startEffects(v22_.effects)
				else
					g_effectManager:stopEffects(v22_.effects)
				end
				local v46_ = false
				for v47_ = 1, #v18_.cutNodes do
					if v18_.cutNodes[v47_].lastWorkTime + 500 > g_time then
						v46_ = true
						break
					end
				end
				if v46_ then
					g_effectManager:setEffectTypeInfo(v18_.effects, FillType.WOODCHIPS)
					g_effectManager:startEffects(v18_.effects)
					if not g_soundManager:getIsSamplePlaying(v18_.samples.work) then
						g_soundManager:playSample(v18_.samples.work)
						return
					end
				else
					g_effectManager:stopEffects(v18_.effects)
					if g_soundManager:getIsSamplePlaying(v18_.samples.work) then
						g_soundManager:stopSample(v18_.samples.work)
					end
				end
			end
		end
	end
end

-- Local values: spec, i
function StumpCutter:onDeactivate()
	if self.isClient then
		local v49_ = self.spec_stumpCutter
		g_effectManager:stopEffects(v49_.effects)
		for v50_ = 1, #v49_.cutNodes do
			g_effectManager:stopEffects(v49_.cutNodes[v50_].effects)
		end
	end
end

-- Local values: spec
function StumpCutter:onTurnedOn()
	if self.isClient then
		local v52_ = self.spec_stumpCutter
		g_soundManager:stopSamples(v52_.samples)
		g_soundManager:playSample(v52_.samples.start)
		g_soundManager:playSample(v52_.samples.idle, 0, v52_.samples.start)
		g_animationManager:startAnimations(v52_.animationNodes)
	end
end

-- Local values: spec, i
function StumpCutter:onTurnedOff()
	if self.isClient then
		local v54_ = self.spec_stumpCutter
		v54_.workFadeTime = 0
		g_effectManager:stopEffects(v54_.effects)
		for v55_ = 1, #v54_.cutNodes do
			g_effectManager:stopEffects(v54_.cutNodes[v55_].effects)
		end
		g_soundManager:stopSamples(v54_.samples)
		g_soundManager:playSample(v54_.samples.stop)
		g_animationManager:stopAnimations(v54_.animationNodes)
	end
end

-- Local values: x, _, z, range
function StumpCutter:crushSplitShape(shape)
	if self.isServer then
		local v58_, _, v59_ = getWorldTranslation(shape)
		delete(shape)
		g_densityMapHeightManager:setCollisionMapAreaDirty(v58_ - 10, v59_ - 10, v58_ + 10, v59_ + 10, true)
		g_currentMission.aiSystem:setAreaDirty(v58_ - 10, v58_ + 10, v59_ - 10, v59_ + 10)
	end
end

-- Local values: spec, cutNode, yPos, zPos, _, y, _, height
function StumpCutter:stumpCutterSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	local v67_ = self.spec_stumpCutter
	local v68_ = v67_.cutNodes[v67_.currentCutNodeIndex]
	if isBelow then
		local v69_ = minY + (maxY - minY) / 2
		local v70_ = minZ + (maxZ - minZ) / 2
		local _, v71_, _ = localToWorld(v68_.node, -0.05, v69_, v70_)
		if v71_ < getTerrainHeightAtWorldPos(g_terrainNode, getWorldTranslation(v68_.node)) then
			self:crushSplitShape(shape)
		else
			v67_.curSplitShape = shape
			g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut)
		end
	elseif v68_.curLenAbove < 1 then
		self:crushSplitShape(shape)
	else
		g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut)
	end
end

-- Local values: spec, area, totalArea, _, cutNode, xs, _, zs, xw, _, zw, xh, _, zh, _area, _totalArea, nonMowableCut
function StumpCutter:processStumpCutterArea(workArea, dt)
	local v74_ = self.spec_stumpCutter
	if not self.isServer and self.currentUpdateDistance > StumpCutter.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v75_ = 0
	local v76_ = 0
	for _, v77_ in ipairs(v74_.cutNodes) do
		if v77_.workAreaIndex == workArea.index then
			local v78_, _, v79_ = getWorldTranslation(workArea.start)
			local v80_, _, v81_ = getWorldTranslation(workArea.width)
			local v82_, _, v83_ = getWorldTranslation(workArea.height)
			local v84_, v85_, v86_ = FSDensityMapUtil.clearDecoArea(v78_, v79_, v80_, v81_, v82_, v83_)
			if v84_ > 0 and v86_ then
				v77_.lastWorkTime = g_time
			end
			v75_ = v75_ + v84_
			v76_ = v76_ + v85_
		end
	end
	return v75_, v76_
end

-- Local values: multiplier, spec
function StumpCutter:getDirtMultiplier(superFunc)
	local v89_ = superFunc(self)
	if self.spec_stumpCutter.curSplitShape ~= nil then
		v89_ = v89_ + self:getWorkDirtMultiplier()
	end
	return v89_
end

-- Local values: multiplier, spec
function StumpCutter:getWearMultiplier(superFunc)
	local v92_ = superFunc(self)
	if self.spec_stumpCutter.curSplitShape ~= nil then
		v92_ = v92_ + self:getWorkWearMultiplier()
	end
	return v92_
end

function StumpCutter:getCultivatorLimitToField(superFunc)
	return false
end

function StumpCutter:getPlowLimitToField()
	return false
end

function StumpCutter:getPlowForceLimitToField()
	return true
end

-- Local values: value, count, spec, loadPercentage, i
function StumpCutter:getConsumingLoad(superFunc)
	local v95_, v96_ = superFunc(self)
	local v97_ = self.spec_stumpCutter
	local v98_ = 0
	for v99_ = 1, #v97_.cutNodes do
		if v97_.cutNodes[v99_].lastWorkTime + 500 > g_time then
			v98_ = 1
			break
		end
	end
	return v95_ + v98_, v96_ + 1
end
