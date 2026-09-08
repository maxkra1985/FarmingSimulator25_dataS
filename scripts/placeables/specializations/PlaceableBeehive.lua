PlaceableBeehive = {}

function PlaceableBeehive.prerequisitesPresent(self)
	return true
end

function PlaceableBeehive.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getBeehiveInfluenceFactor", PlaceableBeehive.getBeehiveInfluenceFactor)
	SpecializationUtil.registerFunction(placeableType, "updateBeehiveState", PlaceableBeehive.updateBeehiveState)
	SpecializationUtil.registerFunction(placeableType, "getHoneyAmountToSpawn", PlaceableBeehive.getHoneyAmountToSpawn)
end

function PlaceableBeehive.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBeehive.updateInfo)
end

function PlaceableBeehive.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBeehive)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBeehive)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBeehive)
	SpecializationUtil.registerEventListener(placeableType, "onBuy", PlaceableBeehive)
end

function PlaceableBeehive.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Beehive")
	schema:register(XMLValueType.FLOAT, basePath .. ".beehive#actionRadius", "Bees action radius")
	schema:register(XMLValueType.FLOAT, basePath .. ".beehive#litersHoneyPerDay", "Beehive honey production per active day")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".beehive.effects")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".beehive.sounds", "idle")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, wx, _, wz
function PlaceableBeehive:onLoad(savegame)
	local v7_ = self.spec_beehive
	local v8_ = self.xmlFile
	v7_.environment = g_currentMission.environment
	v7_.isFxActive = false
	v7_.isProductionActive = false
	v7_.actionRadius = v8_:getFloat("placeable.beehive#actionRadius", 25)
	v7_.honeyPerHour = v8_:getFloat("placeable.beehive#litersHoneyPerDay", 10) / 24
	v7_.infoTableRange = {
		["title"] = g_i18n:getText("infohud_range"),
		["text"] = g_i18n:formatNumber(v7_.actionRadius, 0) .. "m"
	}
	v7_.infoTableNoSpawnerA = {
		["title"] = g_i18n:getText("infohud_beehive_noPalletLocationA"),
		["accentuate"] = true
	}
	v7_.infoTableNoSpawnerB = {
		["title"] = g_i18n:getText("infohud_beehive_noPalletLocationB"),
		["accentuate"] = true
	}
	v7_.honeyAtPalletLocation = {
		["title"] = "",
		["text"] = g_i18n:getText("infohud_beehive_honeyAtPalletLocation")
	}
	v7_.actionRadiusSquared = v7_.actionRadius ^ 2
	local v9_, _, v10_ = getWorldTranslation(self.rootNode)
	v7_.wx = v9_
	v7_.wz = v10_
	if self.isClient then
		v7_.effects = g_effectManager:loadEffect(v8_, "placeable.beehive.effects", self.components, self, self.i3dMappings)
		g_effectManager:setEffectTypeInfo(v7_.effects, FillType.UNKNOWN)
		v7_.samples = {}
		v7_.samples.idle = g_soundManager:loadSampleFromXML(v8_, "placeable.beehive.sounds", "idle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
	end
	v7_.lastDayTimeHoneySpawned = -1
end

-- Local values: spec
function PlaceableBeehive:onDelete()
	local v12_ = self.spec_beehive
	g_effectManager:deleteEffects(v12_.effects)
	g_soundManager:deleteSamples(v12_.samples)
	g_currentMission.beehiveSystem:removeBeehive(self)
end

-- Local values: spec
function PlaceableBeehive:onFinalizePlacement()
	local v14_ = self.spec_beehive
	v14_.lastDayTimeHoneySpawned = v14_.environment.dayTime
	g_currentMission.beehiveSystem:addBeehive(self)
	self:updateBeehiveState()
end

-- Local values: spec, distanceToPointSquared
function PlaceableBeehive:getBeehiveInfluenceFactor(wx, wz)
	local v18_ = self.spec_beehive
	local v19_ = MathUtil.getPointPointDistanceSquared(v18_.wx, v18_.wz, wx, wz)
	return v19_ > v18_.actionRadiusSquared and 0 or 1 - v19_ * 0.85 / v18_.actionRadiusSquared
end

-- Local values: spec, beehiveSystem
function PlaceableBeehive:updateBeehiveState()
	local v21_ = self.spec_beehive
	local v22_ = g_currentMission.beehiveSystem
	v21_.isProductionActive = v22_.isProductionActive
	if v21_.isFxActive ~= v22_.isFxActive then
		v21_.isFxActive = v22_.isFxActive
		if self.isClient then
			if v22_.isFxActive then
				g_effectManager:startEffects(v21_.effects)
				g_soundManager:playSample(v21_.samples.idle, 0)
				return
			end
			g_effectManager:stopEffects(v21_.effects)
			g_soundManager:stopSample(v21_.samples.idle)
		end
	end
end

-- Local values: spec, hours, amount
function PlaceableBeehive:getHoneyAmountToSpawn()
	local v24_ = self.spec_beehive
	if not v24_.isProductionActive then
		return 0
	end
	local v25_ = (v24_.environment.dayTime - v24_.lastDayTimeHoneySpawned) / 1000 / 60 / 60
	local v26_ = math.abs(v25_)
	local v27_ = math.min(v26_, 1)
	local v28_ = v24_.honeyPerHour * v27_ * g_currentMission.environment.timeAdjustment
	v24_.lastDayTimeHoneySpawned = v24_.environment.dayTime
	return v28_
end

-- Local values: spec, owner, spawner
function PlaceableBeehive:updateInfo(superFunc, infoTable)
	local v31_ = self.spec_beehive
	local v32_ = v31_.infoTableRange
	table.insert(infoTable, v32_)
	local v33_ = self:getOwnerFarmId()
	if v33_ == g_currentMission:getFarmId() then
		if g_currentMission.beehiveSystem:getFarmBeehivePalletSpawner(v33_) == nil then
			local v34_ = v31_.infoTableNoSpawnerA
			table.insert(infoTable, v34_)
			local v35_ = v31_.infoTableNoSpawnerB
			table.insert(infoTable, v35_)
			return
		end
		local v36_ = v31_.honeyAtPalletLocation
		table.insert(infoTable, v36_)
	end
end

function Pl-- Local values: serverFarmId, numBeehives, _, existingPlaceable
aceableBeehive.onBuy(self)
	local v37_ = g_currentMission:getFarmId()
	local v38_ = 0
	for _, v39_ in ipairs(g_currentMission.placeableSystem.placeables) do
		if v39_:getOwnerFarmId() == v37_ and v39_.spec_beehive ~= nil then
			v38_ = v38_ + 1
		end
	end
	g_achievementManager:tryUnlock("NumBeehives", v38_)
end
