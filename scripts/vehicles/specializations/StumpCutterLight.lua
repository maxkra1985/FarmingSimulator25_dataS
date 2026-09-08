StumpCutterLight = {}

function StumpCutterLight.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function StumpCutterLight.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("StumpCutterLight")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.stumpCutterLight#cutNode", "Cut nodes which is used as reference to detect the stumps")
	v2_:register(XMLValueType.FLOAT, "vehicle.stumpCutterLight#cutRadius", "Stumps within this radius from the cut node will be removed", 1)
	v2_:register(XMLValueType.TIME, "vehicle.stumpCutterLight#cutTime", "Time until the stump has been cut", 1)
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.stumpCutterLight.effects")
	v2_:setXMLSpecializationType()
end

function StumpCutterLight.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "removeTreeStump", StumpCutterLight.removeTreeStump)
	SpecializationUtil.registerFunction(vehicleType, "stumpCutterLightOverlapCallback", StumpCutterLight.stumpCutterLightOverlapCallback)
end

function StumpCutterLight.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", StumpCutterLight.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", StumpCutterLight.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", StumpCutterLight.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", StumpCutterLight.getConsumingLoad)
end

function StumpCutterLight.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StumpCutterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StumpCutterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", StumpCutterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StumpCutterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", StumpCutterLight)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", StumpCutterLight)
end

-- Local values: spec, baseKey
function StumpCutterLight:onLoad(savegame)
	local v7_ = self.spec_stumpCutterLight
	v7_.cutNode = self.xmlFile:getValue("vehicle.stumpCutterLight#cutNode", nil, self.components, self.i3dMappings)
	v7_.cutRadius = self.xmlFile:getValue("vehicle.stumpCutterLight#cutRadius", 1)
	v7_.cutTime = self.xmlFile:getValue("vehicle.stumpCutterLight#cutTime", 1)
	v7_.cutTimer = 0
	v7_.foundStumps = {}
	v7_.numFoundStumps = 0
	v7_.overlapCheckActive = false
	if self.isClient then
		v7_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stumpCutterLight.effects", self.components, self, self.i3dMappings)
	end
	v7_.texts = {}
	v7_.texts.warning_stumpCutterNoStumpInRange = g_i18n:getText("warning_stumpCutterNoStumpInRange")
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdate", StumpCutterLight)
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onDelete", StumpCutterLight)
		SpecializationUtil.removeEventListener(self, "onDeactivate", StumpCutterLight)
		SpecializationUtil.removeEventListener(self, "onTurnedOn", StumpCutterLight)
		SpecializationUtil.removeEventListener(self, "onTurnedOff", StumpCutterLight)
	end
end

-- Local values: spec
function StumpCutterLight:onDelete()
	local v9_ = self.spec_stumpCutterLight
	g_effectManager:deleteEffects(v9_.effects)
end

-- Local values: spec, turnOffVehicle, i, i, x, y, z
function StumpCutterLight:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v12_ = self.spec_stumpCutterLight
	if self:getIsTurnedOn() then
		local v13_ = false
		if v12_.numFoundStumps > 0 then
			v12_.cutTimer = v12_.cutTimer + dt
			if v12_.cutTimer > v12_.cutTime and not v12_.overlapCheckActive then
				for v14_ = 1, #v12_.foundStumps do
					self:removeTreeStump(v12_.foundStumps[v14_])
				end
				v12_.cutTimer = 0
				v13_ = true
			end
		else
			v13_ = true
		end
		if v13_ then
			if Platform.gameplay.automaticVehicleControl then
				self.rootVehicle:playControlledActions()
			else
				self:setIsTurnedOn(false, true)
			end
		end
	end
	if not v12_.overlapCheckActive then
		v12_.numFoundStumps = #v12_.foundStumps
		for v15_ = #v12_.foundStumps, 1, -1 do
			v12_.foundStumps[v15_] = nil
		end
		v12_.overlapCheckActive = true
		local v16_, v17_, v18_ = getWorldTranslation(v12_.cutNode)
		overlapSphereAsync(v16_, v17_, v18_, v12_.cutRadius, "stumpCutterLightOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	end
end

-- Local values: spec
function StumpCutterLight:onDeactivate()
	local v20_ = self.spec_stumpCutterLight
	g_effectManager:stopEffects(v20_.effects)
end

-- Local values: spec
function StumpCutterLight:onTurnedOn()
	local v22_ = self.spec_stumpCutterLight
	g_effectManager:setEffectTypeInfo(v22_.effects, FillType.WOODCHIPS)
	g_effectManager:startEffects(v22_.effects)
end

-- Local values: spec
function StumpCutterLight:onTurnedOff()
	local v24_ = self.spec_stumpCutterLight
	g_effectManager:stopEffects(v24_.effects)
end

-- Local values: splitTypeIndex, treeTypeDesc, x, _, z, y, yRot
function StumpCutterLight:removeTreeStump(shapeId)
	if self.isServer then
		local v27_ = getSplitType(shapeId)
		local v28_ = g_treePlantManager:getTreeTypeDescFromSplitType(v27_)
		local v29_, _, v30_ = getWorldTranslation(shapeId)
		local v31_ = getTerrainHeightAtWorldPos(g_terrainNode, v29_, 0, v30_)
		local v32_ = math.random() * 2 * 3.141592653589793
		g_treePlantManager:plantTree(v28_.index, v29_, v31_, v30_, 0, v32_, 0, 0)
		g_farmManager:updateFarmStats(self:getActiveFarm(), "plantedTreeCount", 1)
		delete(shapeId)
	end
end
function StumpCutterLight.stumpCutterLightOverlapCallback(p33_, p34_, ...)
	local v35_ = p33_.spec_stumpCutterLight
	if not p33_.isDeleted and (p34_ ~= 0 and (p34_ ~= 0 and (getHasClassId(p34_, ClassIds.MESH_SPLIT_SHAPE) and getUserAttribute(p34_, "isTreeStump")))) then
		local v36_ = v35_.foundStumps
		table.insert(v36_, p34_)
	end
	v35_.overlapCheckActive = false
end

-- Local values: spec
function StumpCutterLight:getAreControlledActionsAllowed(superFunc)
	local v39_ = self.spec_stumpCutterLight
	if v39_.numFoundStumps == 0 then
		return false, v39_.texts.warning_stumpCutterNoStumpInRange
	else
		return superFunc(self)
	end
end

-- Local values: multiplier
function StumpCutterLight:getDirtMultiplier(superFunc)
	local v42_ = superFunc(self)
	if self:getIsTurnedOn() then
		v42_ = v42_ + self:getWorkDirtMultiplier()
	end
	return v42_
end

-- Local values: multiplier
function StumpCutterLight:getWearMultiplier(superFunc)
	local v45_ = superFunc(self)
	if self:getIsTurnedOn() then
		v45_ = v45_ + self:getWorkWearMultiplier()
	end
	return v45_
end

-- Local values: value, count, loadPercentage
function StumpCutterLight:getConsumingLoad(superFunc)
	local v48_, v49_ = superFunc(self)
	return v48_ + (self:getIsTurnedOn() and 1 or 0), v49_ + 1
end
