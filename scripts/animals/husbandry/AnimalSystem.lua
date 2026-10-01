AnimalType = nil
AnimalSubType = nil
AnimalSystem = {}
local AnimalSystem_mt = Class(AnimalSystem)
AnimalSystem.SEND_NUM_BITS = 4
function AnimalSystem.new(isServer, mission, customMt)
	local self = setmetatable({}, customMt or AnimalSystem_mt)
	self.isServer = isServer
	self.mission = mission
	self.subTypeIndexToAnimalData = {}
	self.types = {}
	self.nameToType = {}
	self.nameToTypeIndex = {}
	self.typeIndexToName = {}
	self.subTypes = {}
	self.nameToSubType = {}
	self.nameToSubTypeIndex = {}
	self.fillTypeIndexToSubType = {}
	AnimalType = self.nameToTypeIndex
	AnimalSubType = self.nameToSubTypeIndex
	return self
end
function AnimalSystem:delete()
	if self.animalHusbandryConfigXML ~= nil then
		self.animalHusbandryConfigXML:delete()
		self.animalHusbandryConfigXML = nil
	end
end
function AnimalSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.customEnvironment = missionInfo.customEnvironment
	local filename = getXMLString(xmlFile, "map.animals#filename")
	if filename == nil or filename == "" then
		Logging.xmlInfo(xmlFile, "No animals xml given at 'map.animals#filename'")
		return false
	end
	filename = Utils.getFilename(filename, baseDirectory)
	local xmlFileAnimals = XMLFile.load("animals", filename)
	if xmlFileAnimals == nil then
		return false
	else
		self:loadAnimals(xmlFileAnimals, baseDirectory)
		xmlFileAnimals:delete()
		return 0 < #self.types
	end
end
function AnimalSystem:loadAnimals(xmlFile, baseDirectory)
	for _, key in xmlFile:iterator("animals.animal") do
		if 2 ^ AnimalSystem.SEND_NUM_BITS - 1 <= #self.types then
			Logging.xmlWarning(xmlFile, "Maximum number of supported animal types reached. Ignoring remaining types")
			return
		end
		local typeName = xmlFile:getString(key .. "#type")
		if typeName == nil then
			Logging.xmlError(xmlFile, "Missing animal type. '%s'", key)
			return
		end
		typeName = string.upper(typeName)
		if self.nameToTypeIndex[typeName] ~= nil then
			Logging.xmlError(xmlFile, "Animal type '%s' already defined. '%s'", typeName, key)
			return
		end
		local configFilename = xmlFile:getString(key .. ".configFilename")
		if configFilename == nil then
			Logging.xmlError(xmlFile, "Missing config file for animal type '%s'. '%s'", typeName, key)
			return
		end
		local clusterClassName = xmlFile:getString(key .. "#clusterClass")
		if clusterClassName == nil then
			Logging.xmlError(xmlFile, "Missing animal clusterClass for '%s'!", key)
			return
		end
		if not ClassUtil.getIsValidClassName(clusterClassName) then
			Logging.xmlError(xmlFile, "Invalid animal clusterClass name '%s' for '%s'!", tostring(clusterClassName), key)
			return
		end
		if ClassUtil.getClassObject(clusterClassName) == nil then
			Logging.xmlError(xmlFile, "Unknown animal clusterClass '%s' for '%s'!", tostring(clusterClassName), key)
			return
		end
		local statsBreedingName = xmlFile:getString(key .. "#statsBreeding")
		local groupTitle = g_i18n:convertText(xmlFile:getString(key .. "#groupTitle"), self.customEnvironment)
		local agentHeight = xmlFile:getFloat(key .. ".navMeshAgent#height")
		local agentRadius = xmlFile:getFloat(key .. ".navMeshAgent#radius")
		local agentMaxClimb = xmlFile:getFloat(key .. ".navMeshAgent#maxClimbMeters")
		local agentMaxSlope = math.rad(xmlFile:getFloat(key .. ".navMeshAgent#maxSlope") or 15)
		local sqmPerAnimal = xmlFile:getFloat(key .. ".pasture#sqmPerAnimal") or 100
		local animalType = {}
		animalType.name = typeName
		animalType.groupTitle = groupTitle
		animalType.typeIndex = #self.types + 1
		animalType.configFilename = Utils.getFilename(configFilename, baseDirectory)
		animalType.clusterClass = ClassUtil.getClassObject(clusterClassName)
		animalType.statsBreedingName = statsBreedingName
		animalType.navMeshAgentAttributes = { height = agentHeight, radius = agentRadius, maxClimbMeters = agentMaxClimb, maxSlope = agentMaxSlope }
		animalType.sqmPerAnimal = sqmPerAnimal
		animalType.subTypes = {}
		self:loadAnimalConfig(animalType, baseDirectory)
		if self:loadSubTypes(animalType, xmlFile, key, baseDirectory) then
			table.insert(self.types, animalType)
			self.nameToType[typeName] = animalType
			self.nameToTypeIndex[typeName] = animalType.typeIndex
			self.typeIndexToName[animalType.typeIndex] = typeName
		end
	end
end
function AnimalSystem:validateAnimalType(animalType, baseDirectory)
	local availableAnimationNames = {}
	local usedAnimations = {}
	local animalHusbandryConfigXML = XMLFile.load("animalHusbandryConfigXML", animalType.configFilename)
	if animalHusbandryConfigXML == nil then
		return
	else
		self.animalHusbandryConfigXML = animalHusbandryConfigXML
		for _, key in animalHusbandryConfigXML:iterator("animalHusbandry.animals.animal") do
			g_asyncTaskManager:addTask(function()
				local locomotionFilename = animalHusbandryConfigXML:getString(key .. ".locomotion#filename")
				locomotionFilename = Utils.getFilename(locomotionFilename, baseDirectory)
				local animationI3DFilename = animalHusbandryConfigXML:getString(key .. ".assets#animation")
				animationI3DFilename = Utils.getFilename(animationI3DFilename, baseDirectory)
				local animationI3DFile = loadI3DFile(animationI3DFilename, false, false, false)
				local skeletonIndexRaw = animalHusbandryConfigXML:getString(key .. ".assets#skeletonIndex")
				local skeletonIndex = string.gsub(skeletonIndexRaw, ">", "|")
				local skeletonRoot = I3DUtil.indexToObject(animationI3DFile, skeletonIndex)
				if skeletonRoot == nil then
					Logging.xmlError(animalHusbandryConfigXML, "Invalid skeleton index %q given at %q. Unable to find node", skeletonIndexRaw, key .. ".assets#skeletonIndex")
					delete(animationI3DFile)
					return
				end
				local headIndexRaw = animalHusbandryConfigXML:getString(key .. ".assets#headIndex")
				if headIndexRaw ~= nil then
					local headIndex = string.gsub(headIndexRaw, ">", "|")
					local headNode = I3DUtil.indexToObject(animationI3DFile, headIndex)
					if headNode == nil then
						Logging.xmlError(animalHusbandryConfigXML, "Invalid head index %q given at %q. Unable to find node", headIndexRaw, key .. ".assets#headIndex")
						delete(animationI3DFile)
						return
					end
				end
				local skeleton = getChildAt(skeletonRoot, 0)
				local characterSet = getAnimCharacterSet(skeleton)
				if characterSet == 0 then
					Logging.xmlError(animalHusbandryConfigXML, "Invalid skeleton index given at %q. Given node %q (index path: %s) does not have a character set", key .. ".assets#skeletonIndex", getName(skeleton), skeletonIndexRaw)
					delete(animationI3DFile)
				else
					for index = 0, getAnimNumOfClips(characterSet) - 1 do
						local animClipName = getAnimClipName(characterSet, index)
						availableAnimationNames[animationI3DFilename] = availableAnimationNames[animationI3DFilename] or {}
						availableAnimationNames[animationI3DFilename][animClipName] = true
					end
					delete(animationI3DFile)
					local locomotionXML = XMLFile.load("locomotionXML", locomotionFilename)
					local animationXMLFilename = locomotionXML:getString("locomotion.animation#filename")
					locomotionXML:delete()
					animationXMLFilename = Utils.getFilename(animationXMLFilename, baseDirectory)
					local animationXML = XMLFile.load("animationXML", animationXMLFilename)
					local animationIds = {}
					for _, stateKey in animationXML:iterator("animation.states.state") do
						local stateId = animationXML:getString(stateKey .. "#id")
						for _, animationKey in animationXML:iterator(stateKey .. ".animation") do
							local animationId = animationXML:getString(animationKey .. "#id")
							animationIds[animationId] = true
							local clips = { animationXML:getString(animationKey .. "#clip"), animationXML:getString(animationKey .. "#clipLeft"), animationXML:getString(animationKey .. "#clipRight") }
							for _, clip in ipairs(clips) do
								usedAnimations[animationI3DFilename] = usedAnimations[animationI3DFilename] or {}
								usedAnimations[animationI3DFilename][clip] = true
								if availableAnimationNames[animationI3DFilename] == nil or availableAnimationNames[animationI3DFilename][clip] == nil then
									Logging.xmlWarning(animationXML, "clip name %q at %s (stateId %q, animationId %q) does not exist in animation file %q", clip, animationKey, stateId, animationId, animationI3DFilename)
								end
							end
						end
					end
					for transitionIndex, transitionKey in animationXML:iterator("animation.transitions.transition") do
						local from = animationXML:getString(transitionKey .. "#animationIdFrom")
						local to = animationXML:getString(transitionKey .. "#animationIdTo")
						local clip = animationXML:getString(transitionKey .. "#clip")
						if animationIds[from] == nil then
							Logging.xmlWarning("Unknown animationId %q in transition %d (%s -> %s)", from, transitionIndex, from, to)
						end
						if animationIds[to] == nil then
							Logging.xmlWarning("Unknown animationId %q in transition %d (%s -> %s)", to, transitionIndex, from, to)
						end
						if clip == nil then
							continue
						end
						usedAnimations[animationI3DFilename] = usedAnimations[animationI3DFilename] or {}
						usedAnimations[animationI3DFilename][clip] = true
						if availableAnimationNames[animationI3DFilename] == nil or availableAnimationNames[animationI3DFilename][clip] == nil then
							Logging.xmlWarning(animationXML, "clip name %q at %s (%s -> %s) does not exist in animation file %q", clip, transitionKey, from, to, animationI3DFilename)
						end
					end
					animationXML:delete()
				end
			end, "validateAnimalType " .. key)
		end
		g_asyncTaskManager:addTask(function()
			if self.animalHusbandryConfigXML ~= nil then
				self.animalHusbandryConfigXML:delete()
				self.animalHusbandryConfigXML = nil
			end
		end)
	end
end
function AnimalSystem:loadAnimalConfig(animalType, baseDirectory)
	animalType.animals = {}
	local xmlFile = XMLFile.load("animalsConfig", animalType.configFilename)
	if xmlFile == nil then
		return false
	else
		for _, key in xmlFile:iterator("animalHusbandry.animals.animal") do
			local animal = {}
			animal.filename = Utils.getFilename(xmlFile:getString(key .. ".assets#filename"), baseDirectory)
			animal.filenamePosed = Utils.getFilename(xmlFile:getString(key .. ".assets#filenamePosed"), baseDirectory)
			if animal.filenamePosed == nil then
				Logging.xmlError(xmlFile, "Missing 'filenamePosed' for animal '%s'", key)
				animal.filenamePosed = animal.filename
			end
			animal.variations = {}
			for _, textureKey in xmlFile:iterator(key .. ".assets.texture") do
				local variation = {}
				variation.numTilesU = math.max(xmlFile:getInt(textureKey .. "#numTilesU", 1), 1)
				variation.tileUIndex = math.clamp(xmlFile:getInt(textureKey .. "#tileUIndex", 0), 0, variation.numTilesU - 1)
				variation.numTilesV = math.max(xmlFile:getInt(textureKey .. "#numTilesV", 1), 1)
				variation.tileVIndex = math.clamp(xmlFile:getInt(textureKey .. "#tileVIndex", 0), 0, variation.numTilesV - 1)
				variation.mirrorV = xmlFile:getBool(textureKey .. "#mirrorV", false)
				variation.multi = xmlFile:getBool(textureKey .. "#multi", true)
				table.insert(animal.variations, variation)
			end
			table.insert(animalType.animals, animal)
		end
		xmlFile:delete()
		return true
	end
end
function AnimalSystem:loadSubTypes(animalType, xmlFile, key, baseDirectory)
	for _, subTypeKey in xmlFile:iterator(key .. ".subType") do
		local requiredDLC = xmlFile:getString(subTypeKey .. "#requiredDLC")
		if requiredDLC ~= nil and g_modIsLoaded[g_uniqueDlcNamePrefix .. requiredDLC] == nil then
			continue
		end
		local subTypeName = xmlFile:getString(subTypeKey .. "#subType")
		if subTypeName == nil then
			Logging.xmlError(xmlFile, "Missing animal subtype. '%s'", subTypeKey)
			break
		end
		subTypeName = string.upper(subTypeName)
		if self.nameToSubTypeIndex[subTypeName] ~= nil then
			Logging.xmlError(xmlFile, "Animal subtype '%s' already defined. '%s'", subTypeName, subTypeKey)
			break
		end
		local fillTypeName = xmlFile:getString(subTypeKey .. "#fillTypeName")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		if fillTypeIndex == nil then
			Logging.xmlError(xmlFile, "FillType '%s' for animal subtype '%s' not defined!", fillTypeName, subTypeKey)
			break
		end
		local subType = {}
		subType.name = subTypeName
		subType.subTypeIndex = #self.subTypes + 1
		subType.fillTypeIndex = fillTypeIndex
		subType.typeIndex = animalType.typeIndex
		subType.statsBreedingName = xmlFile:getString(subTypeKey .. "#statsBreeding") or animalType.statsBreedingName
		table.insert(animalType.subTypes, subType.subTypeIndex)
		if self:loadSubType(animalType, subType, xmlFile, subTypeKey, baseDirectory) then
			table.insert(self.subTypes, subType)
			self.nameToSubType[subTypeName] = subType
			self.nameToSubTypeIndex[subTypeName] = subType.subTypeIndex
			self.fillTypeIndexToSubType[fillTypeIndex] = subType
		end
	end
	return true
end
function AnimalSystem:loadSubType(animalType, subType, xmlFile, subTypeKey, baseDirectory)
	local rideableFilename = xmlFile:getString(subTypeKey .. ".rideable#filename")
	if rideableFilename ~= nil then
		subType.rideableFilename = Utils.getFilename(rideableFilename, baseDirectory)
	end
	local input = { ["straw"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.straw"), ["water"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.water"), ["food"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.food") }
	subType.input = input
	local output = {}
	if xmlFile:hasProperty(subTypeKey .. ".output.milk") then
		output.milk = { fillType = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getString(subTypeKey .. ".output.milk#fillType")), curve = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.milk") }
	end
	if xmlFile:hasProperty(subTypeKey .. ".output.pallets") then
		output.pallets = { fillType = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getString(subTypeKey .. ".output.pallets#fillType")), curve = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.pallets") }
	end
	output.manure = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.manure")
	output.liquidManure = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.liquidManure")
	subType.output = output
	subType.buyPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".buyPrice")
	subType.transportPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".transportPrice")
	subType.sellPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".sellPrice")
	subType.supportsReproduction = xmlFile:getBool(subTypeKey .. ".reproduction#supported", true)
	subType.reproductionMinAgeMonth = xmlFile:getInt(subTypeKey .. ".reproduction#minAgeMonth", 18)
	subType.reproductionDurationMonth = xmlFile:getInt(subTypeKey .. ".reproduction#durationMonth", 10)
	subType.reproductionMinHealth = math.clamp(xmlFile:getFloat(subTypeKey .. ".reproduction#minHealthFactor", 0.75), 0, 1)
	subType.healthIncreaseHour = math.clamp(xmlFile:getInt(subTypeKey .. ".health#increasePerHour", 10), 0, 100)
	subType.healthDecreaseHour = math.clamp(xmlFile:getInt(subTypeKey .. ".health#decreasePerHour", 25), 0, 100)
	subType.healthThresholdFactor = math.clamp(xmlFile:getFloat(subTypeKey .. ".health#thresholdFactor", 0.2), 0, 1)
	subType.ridingThresholdFactor = math.clamp(xmlFile:getFloat(subTypeKey .. ".health#ridingThreshold", 0.4), 0, 1)
	subType.visuals = {}
	for _, visualKey in xmlFile:iterator(subTypeKey .. ".visuals.visual") do
		local visual = self:loadVisualData(animalType, xmlFile, visualKey, baseDirectory)
		if visual == nil then
			continue
		end
		local valid = true
		if #subType.visuals == 0 then
			if visual.minAge ~= 0 then
				valid = false
				Logging.xmlWarning(xmlFile, "First visual must have minAge = 0 for '%s'", visualKey)
			end
		elseif visual.minAge <= subType.visuals[#subType.visuals].minAge then
			valid = false
			Logging.xmlWarning(xmlFile, "Visual minAge has to be greater than predecessor minAge. '%s'", visualKey)
		end
		if valid then
			table.insert(subType.visuals, visual)
		end
	end
	if #subType.visuals == 0 then
		Logging.xmlWarning(xmlFile, "No visuals defined for '%s'", subTypeKey)
		return false
	else
		return true
	end
end
function AnimalSystem:loadAnimCurve(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return nil
	else
		local curve = AnimCurve.new(linearInterpolator1)
		for _, valueKey in xmlFile:iterator(key .. ".key") do
			local ageMonth = xmlFile:getInt(valueKey .. "#ageMonth")
			local value = xmlFile:getInt(valueKey .. "#value")
			if ageMonth == nil then
				Logging.xmlWarning(xmlFile, "Missing ageMonth for '%s'", valueKey)
			elseif value == nil then
				Logging.xmlWarning(xmlFile, "Missing value for '%s'", valueKey)
			else
				curve:addKeyframe({ value, ["time"] = ageMonth })
			end
		end
		return curve
	end
end
function AnimalSystem:loadVisualData(animalType, xmlFile, key, baseDirectory)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	local visualAnimalIndex = xmlFile:getInt(key .. "#visualAnimalIndex")
	if visualAnimalIndex == nil then
		Logging.xmlError(xmlFile, "Missing animal index for '%s'", key)
		return nil
	end
	local animal = animalType.animals[visualAnimalIndex]
	if animal == nil then
		Logging.xmlError(xmlFile, "Animal index not defined for '%s'", key)
		return nil
	end
	local image = xmlFile:getString(key .. "#image")
	if image == nil then
		Logging.xmlError(xmlFile, "Missing store image for '%s'", key)
		return nil
	end
	local minAge = xmlFile:getInt(key .. "#minAge", 0)
	if minAge < 0 then
		Logging.xmlError(xmlFile, "Invalid minAge for '%s'", key)
		return nil
	end
	local descriptions = {}
	for _, descKey in xmlFile:iterator(key .. ".description") do
		local descItem = xmlFile:getString(descKey)
		if descItem == nil then
			continue
		end
		table.insert(descriptions, g_i18n:convertText(descItem, self.customEnvironment))
	end
	if #descriptions == 0 then
		Logging.xmlError(xmlFile, "Missing description for '%s'", key)
		return nil
	else
		local store = { ["imageFilename"] = Utils.getFilename(image, baseDirectory), ["canBeBought"] = xmlFile:getBool(key .. "#canBeBought", false), ["description"] = table.concat(descriptions, " ") }
		local visualData = { ["store"] = store, ["visualAnimalIndex"] = visualAnimalIndex, ["minAge"] = minAge, ["visualAnimal"] = animal }
		return visualData
	end
end
function AnimalSystem:getAnimalBuyPrice(subTypeIndex, age)
	local subType = self.subTypes[subTypeIndex]
	if subType == nil then
		return nil
	else
		return subType.buyPrice:get(age)
	end
end
function AnimalSystem:getAnimalTransportFee(subTypeIndex, age)
	local subType = self.subTypes[subTypeIndex]
	if subType == nil then
		return 0
	else
		return subType.transportPrice:get(age)
	end
end
function AnimalSystem:getVisualAnimalIndexByAge(subTypeIndex, age)
	local visual = self:getVisualByAge(subTypeIndex, age)
	if visual == nil then
		return nil
	else
		return visual.visualAnimalIndex
	end
end
function AnimalSystem:getVisualByAge(subTypeIndex, age)
	local subType = self.subTypes[subTypeIndex]
	if subType == nil then
		return nil
	else
		local visual = nil
		for _, v in ipairs(subType.visuals) do
			if v.minAge <= age then
				visual = v
			end
		end
		return visual
	end
end
function AnimalSystem:getSubTypeByIndex(index)
	return self.subTypes[index]
end
function AnimalSystem:getSubTypeByName(name)
	return self.nameToSubType[string.upper(name)]
end
function AnimalSystem:getSubTypeIndexByName(name)
	return self.nameToSubTypeIndex[string.upper(name)]
end
function AnimalSystem:getTypeByIndex(index)
	return self.types[index]
end
function AnimalSystem:getTypeByName(name)
	return self.nameToType[string.upper(name)]
end
function AnimalSystem:getTypeIndexByName(name)
	return self.nameToTypeIndex[string.upper(name)]
end
function AnimalSystem:getSubTypeByFillTypeIndex(fillTypeIndex)
	return self.fillTypeIndexToSubType[fillTypeIndex]
end
function AnimalSystem:getSubTypeIndexByFillTypeIndex(fillTypeIndex)
	if self.fillTypeIndexToSubType[fillTypeIndex] ~= nil then
		return self.fillTypeIndexToSubType[fillTypeIndex].subTypeIndex
	else
		return nil
	end
end
function AnimalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
	local subType = self.subTypes[subTypeIndex]
	return subType.typeIndex
end
function AnimalSystem:getTypes()
	return self.types
end
function AnimalSystem:getClusterClassBySubTypeIndex(subTypeIndex)
	local subType = self:getSubTypeByIndex(subTypeIndex)
	local animalType = self:getTypeByIndex(subType.typeIndex)
	return animalType.clusterClass
end
function AnimalSystem:createClusterFromSubTypeIndex(subTypeIndex)
	local subType = self:getSubTypeByIndex(subTypeIndex)
	local animalType = self:getTypeByIndex(subType.typeIndex)
	local cluster = animalType.clusterClass.new()
	cluster.subTypeIndex = subTypeIndex
	return cluster
end
