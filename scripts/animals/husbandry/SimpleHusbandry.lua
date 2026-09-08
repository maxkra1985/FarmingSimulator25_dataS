-- Local values: SimpleHusbandry_mt
SimpleHusbandry = {}
SimpleHusbandry.MAX_NUM_ANIMALS = 8
local SimpleHusbandry_mt = Class(SimpleHusbandry)

-- Local values: husbandry
function SimpleHusbandry.onCreate(_, node)
	if g_dedicatedServer == nil then
		local v3_ = SimpleHusbandry.new()
		if v3_:load(node) then
			g_currentMission:addUpdateable(v3_)
		else
			v3_:delete()
		end
	else
		Logging.devInfo("SimpleHusbandry not available on Dedicated Server Host")
		return
	end
end

-- Upvalues: SimpleHusbandry_mt
-- Local values: self
function SimpleHusbandry.new(customMt)
	-- upvalues: (copy) SimpleHusbandry_mt
	local v5_ = customMt or SimpleHusbandry_mt
	local v6_ = setmetatable({}, v5_)
	v6_.husbandryId = nil
	v6_.animalIds = {}
	return v6_
end

-- Local values: raycastCollisionFlag, animalTypeName, animalType, raycastDistance, collisionMaskFilter
function SimpleHusbandry:load(node)
	local v9_ = CollisionMask.ANIMAL_POSITIONING
	if not getHasClassId(node, ClassIds.NAVIGATION_MESH) then
		Logging.error("Given node \'%s\' is not a navigation mesh!", getName(node))
		return false
	end
	local v10_ = getUserAttribute(node, "animalType")
	local v11_ = g_currentMission.animalSystem:getTypeByName(v10_)
	if v11_ == nil then
		Logging.error("Animal type \'%s\' not defined!", v10_)
		return false
	end
	local v12_ = getUserAttribute
	local v13_ = tonumber(v12_(node, "maxNumberOfAnimals")) or 5
	local v14_ = SimpleHusbandry.MAX_NUM_ANIMALS
	self.maxNumberOfAnimals = math.clamp(v13_, 1, v14_)
	local v15_ = getUserAttribute
	local v16_ = tonumber(v15_(node, "raycastDistance")) or 10
	self.animalType = v11_
	self.subTypeIndex = getUserAttribute(node, "subTypeIndex")
	local v17_ = CollisionMask.ANIMAL_SINGLEPLAYER
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		v17_ = CollisionMask.ANIMAL_MULTIPLAYER
	end
	self.husbandryId = createAnimalHusbandry(v10_, node, v11_.configFilename, v16_, v9_, v17_, AudioGroup.ENVIRONMENT)
	if self.husbandryId == 0 then
		self.husbandryId = nil
		Logging.error("Unable to create animal husbandry for animal type %q with nav mesh %q and config xml %q", v10_, I3DUtil.getNodePath(node), v11_.configFilename)
		return false
	end
	g_soundManager:addIndoorStateChangedListener(self)
	setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
	self.needsAnimals = true
	return true
end

-- Local values: animalId, _
function SimpleHusbandry:delete()
	g_currentMission:removeUpdateable(self)
	if self.husbandryId ~= nil then
		for v19_, _ in pairs(self.animalIds) do
			removeHusbandryAnimal(self.husbandryId, v19_)
		end
		g_soundManager:removeIndoorStateChangedListener(self)
		delete(self.husbandryId)
		self.husbandryId = nil
	end
end

function SimpleHusbandry:update(dt)
	if self.husbandryId ~= nil then
		setAnimalDaytime(self.husbandryId, g_currentMission.environment.dayTime)
		if self.needsAnimals and isHusbandryReady(self.husbandryId) then
			self:addAnimals()
			self.needsAnimals = false
		end
	end
end

function SimpleHusbandry:onIndoorStateChanged(isIndoor)
	setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
end

-- Local values: maxNumberOfAnimals, i, subType, subTypes, subTypeIndex, visuals, visual, animalId, animalRootNode, x, y, z, w
function SimpleHusbandry:addAnimals()
	local v23_ = math.random
	local v24_ = self.maxNumberOfAnimals
	for _ = 1, v23_(math.min(v24_, 2), self.maxNumberOfAnimals) do
		local v25_
		if self.subTypeIndex == nil then
			v25_ = nil
		else
			v25_ = g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex)
		end
		if v25_ == nil then
			local v26_ = self.animalType.subTypes
			local v27_ = v26_[math.random(1, #v26_)]
			v25_ = g_currentMission.animalSystem:getSubTypeByIndex(v27_)
		end
		local v28_ = v25_.visuals
		local v29_ = v28_[#v28_]
		local v30_ = addHusbandryAnimal(self.husbandryId, v29_.visualAnimalIndex - 1)
		local v31_ = self.animalIds
		table.insert(v31_, v30_)
		local v32_ = getAnimalRootNode(self.husbandryId, v30_)
		I3DUtil.setShaderParameterRec(v32_, "dirt", math.random(0, 0.7), nil, nil, nil)
		local v33_, v34_, v35_, v36_ = getAnimalShaderParameter(self.husbandryId, v30_, "atlasInvSizeAndOffsetUV")
		I3DUtil.setShaderParameterRec(v32_, "atlasInvSizeAndOffsetUV", v33_, v34_, v35_, v36_)
	end
end
