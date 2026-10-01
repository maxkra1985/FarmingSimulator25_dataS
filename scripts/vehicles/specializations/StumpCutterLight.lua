StumpCutterLight = {}
function StumpCutterLight.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function StumpCutterLight.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("StumpCutterLight")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.stumpCutterLight#cutNode", "Cut nodes which is used as reference to detect the stumps")
	schema:register(XMLValueType.FLOAT, "vehicle.stumpCutterLight#cutRadius", "Stumps within this radius from the cut node will be removed", 1)
	schema:register(XMLValueType.TIME, "vehicle.stumpCutterLight#cutTime", "Time until the stump has been cut", 1)
	EffectManager.registerEffectXMLPaths(schema, "vehicle.stumpCutterLight.effects")
	schema:setXMLSpecializationType()
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
function StumpCutterLight:onLoad(savegame)
	local spec = self.spec_stumpCutterLight
	local baseKey = "vehicle.stumpCutterLight"
	spec.cutNode = self.xmlFile:getValue("vehicle.stumpCutterLight" .. "#cutNode", nil, self.components, self.i3dMappings)
	spec.cutRadius = self.xmlFile:getValue("vehicle.stumpCutterLight" .. "#cutRadius", 1)
	spec.cutTime = self.xmlFile:getValue("vehicle.stumpCutterLight" .. "#cutTime", 1)
	spec.cutTimer = 0
	spec.foundStumps = {}
	spec.numFoundStumps = 0
	spec.overlapCheckActive = false
	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stumpCutterLight" .. ".effects", self.components, self, self.i3dMappings)
	end
	spec.texts = {}
	spec.texts.warning_stumpCutterNoStumpInRange = g_i18n:getText("warning_stumpCutterNoStumpInRange")
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
function StumpCutterLight:onDelete()
	local spec = self.spec_stumpCutterLight
	g_effectManager:deleteEffects(spec.effects)
end
function StumpCutterLight:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_stumpCutterLight
	if self:getIsTurnedOn() then
		local turnOffVehicle = false
		if 0 < spec.numFoundStumps then
			spec.cutTimer = spec.cutTimer + dt
			if spec.cutTime < spec.cutTimer and not spec.overlapCheckActive then
				for i = 1, #spec.foundStumps do
					self:removeTreeStump(spec.foundStumps[i])
				end
				spec.cutTimer = 0
				turnOffVehicle = true
			end
		else
			turnOffVehicle = true
		end
		if turnOffVehicle then
			if Platform.gameplay.automaticVehicleControl then
				self.rootVehicle:playControlledActions()
			else
				self:setIsTurnedOn(false, true)
			end
		end
	end
	if not spec.overlapCheckActive then
		spec.numFoundStumps = #spec.foundStumps
		for i = #spec.foundStumps, 1, -1 do
			spec.foundStumps[i] = nil
		end
		spec.overlapCheckActive = true
		local x, y, z = getWorldTranslation(spec.cutNode)
		overlapSphereAsync(x, y, z, spec.cutRadius, "stumpCutterLightOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
	end
end
function StumpCutterLight:onDeactivate()
	local spec = self.spec_stumpCutterLight
	g_effectManager:stopEffects(spec.effects)
end
function StumpCutterLight:onTurnedOn()
	local spec = self.spec_stumpCutterLight
	g_effectManager:setEffectTypeInfo(spec.effects, FillType.WOODCHIPS)
	g_effectManager:startEffects(spec.effects)
end
function StumpCutterLight:onTurnedOff()
	local spec = self.spec_stumpCutterLight
	g_effectManager:stopEffects(spec.effects)
end
function StumpCutterLight:removeTreeStump(shapeId)
	if self.isServer then
		local splitTypeIndex = getSplitType(shapeId)
		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromSplitType(splitTypeIndex)
		local x, _, z = getWorldTranslation(shapeId)
		local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		local yRot = math.random() * 2 * 3.141592653589793
		g_treePlantManager:plantTree(treeTypeDesc.index, x, y, z, 0, yRot, 0, 0)
		g_farmManager:updateFarmStats(self:getActiveFarm(), "plantedTreeCount", 1)
		delete(shapeId)
	end
end
function StumpCutterLight:stumpCutterLightOverlapCallback(objectId, ...)
	local spec = self.spec_stumpCutterLight
	if not self.isDeleted and (objectId ~= 0 and (objectId ~= 0 and (getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) and getUserAttribute(objectId, "isTreeStump")))) then
		table.insert(spec.foundStumps, objectId)
	end
	spec.overlapCheckActive = false
end
function StumpCutterLight:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_stumpCutterLight
	if spec.numFoundStumps == 0 then
		return false, spec.texts.warning_stumpCutterNoStumpInRange
	else
		return superFunc(self)
	end
end
function StumpCutterLight:getDirtMultiplier(superFunc)
	local multiplier = superFunc(self)
	if self:getIsTurnedOn() then
		multiplier = multiplier + self:getWorkDirtMultiplier()
	end
	return multiplier
end
function StumpCutterLight:getWearMultiplier(superFunc)
	local multiplier = superFunc(self)
	if self:getIsTurnedOn() then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end
	return multiplier
end
function StumpCutterLight:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local loadPercentage = 0
	if self:getIsTurnedOn() then
		loadPercentage = 1
	end
	return value + loadPercentage, count + 1
end
