-- Local values: AnimalSystem_mt
AnimalType = nil
AnimalSubType = nil
AnimalSystem = {}
local AnimalSystem_mt = Class(AnimalSystem)
AnimalSystem.SEND_NUM_BITS = 4

-- Upvalues: AnimalSystem_mt
-- Local values: self
function AnimalSystem.new(isServer, mission, customMt)
	-- upvalues: (copy) AnimalSystem_mt
	local v5_ = customMt or AnimalSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.isServer = isServer
	v6_.mission = mission
	v6_.subTypeIndexToAnimalData = {}
	v6_.types = {}
	v6_.nameToType = {}
	v6_.nameToTypeIndex = {}
	v6_.typeIndexToName = {}
	v6_.subTypes = {}
	v6_.nameToSubType = {}
	v6_.nameToSubTypeIndex = {}
	v6_.fillTypeIndexToSubType = {}
	AnimalType = v6_.nameToTypeIndex
	AnimalSubType = v6_.nameToSubTypeIndex
	return v6_
end

function AnimalSystem:delete()
	if self.animalHusbandryConfigXML ~= nil then
		self.animalHusbandryConfigXML:delete()
		self.animalHusbandryConfigXML = nil
	end
end

-- Local values: filename, xmlFileAnimals
function AnimalSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.customEnvironment = missionInfo.customEnvironment
	local v12_ = getXMLString(xmlFile, "map.animals#filename")
	if v12_ == nil or v12_ == "" then
		Logging.xmlInfo(xmlFile, "No animals xml given at \'map.animals#filename\'")
		return false
	end
	local v13_ = Utils.getFilename(v12_, baseDirectory)
	local v14_ = XMLFile.load("animals", v13_)
	if v14_ == nil then
		return false
	end
	self:loadAnimals(v14_, baseDirectory)
	v14_:delete()
	return #self.types > 0
end

-- Local values: _, key, typeName, configFilename, clusterClassName, statsBreedingName, groupTitle, agentHeight, agentRadius, agentMaxClimb, agentMaxSlope, sqmPerAnimal, animalType
function AnimalSystem:loadAnimals(xmlFile, baseDirectory)
	for _, v18_ in xmlFile:iterator("animals.animal") do
		if #self.types >= 2 ^ AnimalSystem.SEND_NUM_BITS - 1 then
			Logging.xmlWarning(xmlFile, "Maximum number of supported animal types reached. Ignoring remaining types")
			return
		end
		local v19_ = xmlFile:getString(v18_ .. "#type")
		if v19_ == nil then
			Logging.xmlError(xmlFile, "Missing animal type. \'%s\'", v18_)
			return
		end
		local v20_ = string.upper(v19_)
		if self.nameToTypeIndex[v20_] ~= nil then
			Logging.xmlError(xmlFile, "Animal type \'%s\' already defined. \'%s\'", v20_, v18_)
			return
		end
		local v21_ = xmlFile:getString(v18_ .. ".configFilename")
		if v21_ == nil then
			Logging.xmlError(xmlFile, "Missing config file for animal type \'%s\'. \'%s\'", v20_, v18_)
			return
		end
		local v22_ = xmlFile:getString(v18_ .. "#clusterClass")
		if v22_ == nil then
			Logging.xmlError(xmlFile, "Missing animal clusterClass for \'%s\'!", v18_)
			return
		end
		if not ClassUtil.getIsValidClassName(v22_) then
			Logging.xmlError(xmlFile, "Invalid animal clusterClass name \'%s\' for \'%s\'!", tostring(v22_), v18_)
			return
		end
		if ClassUtil.getClassObject(v22_) == nil then
			Logging.xmlError(xmlFile, "Unknown animal clusterClass \'%s\' for \'%s\'!", tostring(v22_), v18_)
			return
		end
		local v23_ = xmlFile:getString(v18_ .. "#statsBreeding")
		local v24_ = g_i18n:convertText(xmlFile:getString(v18_ .. "#groupTitle"), self.customEnvironment)
		local v25_ = xmlFile:getFloat(v18_ .. ".navMeshAgent#height")
		local v26_ = xmlFile:getFloat(v18_ .. ".navMeshAgent#radius")
		local v27_ = xmlFile:getFloat(v18_ .. ".navMeshAgent#maxClimbMeters")
		local v28_ = xmlFile:getFloat(v18_ .. ".navMeshAgent#maxSlope") or 15
		local v29_ = math.rad(v28_)
		local v30_ = xmlFile:getFloat(v18_ .. ".pasture#sqmPerAnimal") or 100
		local v31_ = {
			["name"] = v20_,
			["groupTitle"] = v24_,
			["typeIndex"] = #self.types + 1,
			["configFilename"] = Utils.getFilename(v21_, baseDirectory),
			["clusterClass"] = ClassUtil.getClassObject(v22_),
			["statsBreedingName"] = v23_,
			["navMeshAgentAttributes"] = {
				["height"] = v25_,
				["radius"] = v26_,
				["maxClimbMeters"] = v27_,
				["maxSlope"] = v29_
			},
			["sqmPerAnimal"] = v30_,
			["subTypes"] = {}
		}
		self:loadAnimalConfig(v31_, baseDirectory)
		if self:loadSubTypes(v31_, xmlFile, v18_, baseDirectory) then
			local v32_ = self.types
			table.insert(v32_, v31_)
			self.nameToType[v20_] = v31_
			self.nameToTypeIndex[v20_] = v31_.typeIndex
			self.typeIndexToName[v31_.typeIndex] = v20_
		end
	end
end

-- Local values: availableAnimationNames, usedAnimations, animalHusbandryConfigXML, _, key
function AnimalSystem:validateAnimalType(animalType, baseDirectory)
	local v_u_36_ = {}
	local v_u_37_ = {}
	local v_u_38_ = XMLFile.load("animalHusbandryConfigXML", animalType.configFilename)
	if v_u_38_ ~= nil then
		self.animalHusbandryConfigXML = v_u_38_
		for _, v_u_39_ in v_u_38_:iterator("animalHusbandry.animals.animal") do
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) v_u_38_, (copy) v_u_39_, (copy) baseDirectory, (copy) v_u_36_, (copy) v_u_37_
				local v40_ = v_u_38_:getString(v_u_39_ .. ".locomotion#filename")
				local v41_ = Utils.getFilename(v40_, baseDirectory)
				local v42_ = v_u_38_:getString(v_u_39_ .. ".assets#animation")
				local v43_ = Utils.getFilename(v42_, baseDirectory)
				local v44_ = loadI3DFile(v43_, false, false, false)
				local v45_ = v_u_38_:getString(v_u_39_ .. ".assets#skeletonIndex")
				local v46_ = string.gsub(v45_, ">", "|")
				local v47_ = I3DUtil.indexToObject(v44_, v46_)
				if v47_ == nil then
					Logging.xmlError(v_u_38_, "Invalid skeleton index %q given at %q. Unable to find node", v45_, v_u_39_ .. ".assets#skeletonIndex")
					delete(v44_)
					return
				else
					local v48_ = v_u_38_:getString(v_u_39_ .. ".assets#headIndex")
					if v48_ ~= nil then
						local v49_ = string.gsub(v48_, ">", "|")
						if I3DUtil.indexToObject(v44_, v49_) == nil then
							Logging.xmlError(v_u_38_, "Invalid head index %q given at %q. Unable to find node", v48_, v_u_39_ .. ".assets#headIndex")
							delete(v44_)
							return
						end
					end
					local v50_ = getChildAt(v47_, 0)
					local v51_ = getAnimCharacterSet(v50_)
					if v51_ == 0 then
						Logging.xmlError(v_u_38_, "Invalid skeleton index given at %q. Given node %q (index path: %s) does not have a character set", v_u_39_ .. ".assets#skeletonIndex", getName(v50_), v45_)
						delete(v44_)
					else
						for v52_ = 0, getAnimNumOfClips(v51_) - 1 do
							local v53_ = getAnimClipName(v51_, v52_)
							v_u_36_[v43_] = v_u_36_[v43_] or {}
							v_u_36_[v43_][v53_] = true
						end
						delete(v44_)
						local v54_ = XMLFile.load("locomotionXML", v41_)
						local v55_ = v54_:getString("locomotion.animation#filename")
						v54_:delete()
						local v56_ = Utils.getFilename(v55_, baseDirectory)
						local v57_ = XMLFile.load("animationXML", v56_)
						local v58_ = {}
						for _, v59_ in v57_:iterator("animation.states.state") do
							local v60_ = v57_:getString(v59_ .. "#id")
							for _, v61_ in v57_:iterator(v59_ .. ".animation") do
								local v62_ = v57_:getString(v61_ .. "#id")
								v58_[v62_] = true
								local v63_ = { v57_:getString(v61_ .. "#clip"), v57_:getString(v61_ .. "#clipLeft"), v57_:getString(v61_ .. "#clipRight") }
								for _, v64_ in ipairs(v63_) do
									v_u_37_[v43_] = v_u_37_[v43_] or {}
									v_u_37_[v43_][v64_] = true
									if v_u_36_[v43_] == nil or v_u_36_[v43_][v64_] == nil then
										Logging.xmlWarning(v57_, "clip name %q at %s (stateId %q, animationId %q) does not exist in animation file %q", v64_, v61_, v60_, v62_, v43_)
									end
								end
							end
						end
						for v65_, v66_ in v57_:iterator("animation.transitions.transition") do
							local v67_ = v57_:getString(v66_ .. "#animationIdFrom")
							local v68_ = v57_:getString(v66_ .. "#animationIdTo")
							local v69_ = v57_:getString(v66_ .. "#clip")
							if v58_[v67_] == nil then
								Logging.xmlWarning("Unknown animationId %q in transition %d (%s -> %s)", v67_, v65_, v67_, v68_)
							end
							if v58_[v68_] == nil then
								Logging.xmlWarning("Unknown animationId %q in transition %d (%s -> %s)", v68_, v65_, v67_, v68_)
							end
							if v69_ ~= nil then
								v_u_37_[v43_] = v_u_37_[v43_] or {}
								v_u_37_[v43_][v69_] = true
								if v_u_36_[v43_] == nil or v_u_36_[v43_][v69_] == nil then
									Logging.xmlWarning(v57_, "clip name %q at %s (%s -> %s) does not exist in animation file %q", v69_, v66_, v67_, v68_, v43_)
								end
							end
						end
						v57_:delete()
					end
				end
			end, "validateAnimalType " .. v_u_39_)
		end
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			if self.animalHusbandryConfigXML ~= nil then
				self.animalHusbandryConfigXML:delete()
				self.animalHusbandryConfigXML = nil
			end
		end)
	end
end

-- Local values: xmlFile, _, key, animal, _, textureKey, variation
function AnimalSystem:loadAnimalConfig(animalType, baseDirectory)
	animalType.animals = {}
	local v72_ = XMLFile.load("animalsConfig", animalType.configFilename)
	if v72_ == nil then
		return false
	end
	for _, v73_ in v72_:iterator("animalHusbandry.animals.animal") do
		local v74_ = {
			["filename"] = Utils.getFilename(v72_:getString(v73_ .. ".assets#filename"), baseDirectory),
			["filenamePosed"] = Utils.getFilename(v72_:getString(v73_ .. ".assets#filenamePosed"), baseDirectory)
		}
		if v74_.filenamePosed == nil then
			Logging.xmlError(v72_, "Missing \'filenamePosed\' for animal \'%s\'", v73_)
			v74_.filenamePosed = v74_.filename
		end
		v74_.variations = {}
		for _, v75_ in v72_:iterator(v73_ .. ".assets.texture") do
			local v76_ = {}
			local v77_ = v72_:getInt(v75_ .. "#numTilesU", 1)
			v76_.numTilesU = math.max(v77_, 1)
			local v78_ = v72_:getInt(v75_ .. "#tileUIndex", 0)
			local v79_ = v76_.numTilesU - 1
			v76_.tileUIndex = math.clamp(v78_, 0, v79_)
			local v80_ = v72_:getInt(v75_ .. "#numTilesV", 1)
			v76_.numTilesV = math.max(v80_, 1)
			local v81_ = v72_:getInt(v75_ .. "#tileVIndex", 0)
			local v82_ = v76_.numTilesV - 1
			v76_.tileVIndex = math.clamp(v81_, 0, v82_)
			v76_.mirrorV = v72_:getBool(v75_ .. "#mirrorV", false)
			v76_.multi = v72_:getBool(v75_ .. "#multi", true)
			local v83_ = v74_.variations
			table.insert(v83_, v76_)
		end
		local v84_ = animalType.animals
		table.insert(v84_, v74_)
	end
	v72_:delete()
	return true
end

-- Local values: _, subTypeKey, requiredDLC, subTypeName, fillTypeName, fillTypeIndex, subType
function AnimalSystem:loadSubTypes(animalType, xmlFile, key, baseDirectory)
	for _, v90_ in xmlFile:iterator(key .. ".subType") do
		local v91_ = xmlFile:getString(v90_ .. "#requiredDLC")
		if v91_ == nil or g_modIsLoaded[g_uniqueDlcNamePrefix .. v91_] ~= nil then
			local v92_ = xmlFile:getString(v90_ .. "#subType")
			if v92_ == nil then
				Logging.xmlError(xmlFile, "Missing animal subtype. \'%s\'", v90_)
				break
			end
			local v93_ = string.upper(v92_)
			if self.nameToSubTypeIndex[v93_] ~= nil then
				Logging.xmlError(xmlFile, "Animal subtype \'%s\' already defined. \'%s\'", v93_, v90_)
				break
			end
			local v94_ = xmlFile:getString(v90_ .. "#fillTypeName")
			local v95_ = g_fillTypeManager:getFillTypeIndexByName(v94_)
			if v95_ == nil then
				Logging.xmlError(xmlFile, "FillType \'%s\' for animal subtype \'%s\' not defined!", v94_, v90_)
				break
			end
			local v96_ = {
				["name"] = v93_,
				["subTypeIndex"] = #self.subTypes + 1,
				["fillTypeIndex"] = v95_,
				["typeIndex"] = animalType.typeIndex,
				["statsBreedingName"] = xmlFile:getString(v90_ .. "#statsBreeding") or animalType.statsBreedingName
			}
			local v97_ = animalType.subTypes
			local v98_ = v96_.subTypeIndex
			table.insert(v97_, v98_)
			if self:loadSubType(animalType, v96_, xmlFile, v90_, baseDirectory) then
				local v99_ = self.subTypes
				table.insert(v99_, v96_)
				self.nameToSubType[v93_] = v96_
				self.nameToSubTypeIndex[v93_] = v96_.subTypeIndex
				self.fillTypeIndexToSubType[v95_] = v96_
			end
		end
	end
	return true
end

-- Local values: rideableFilename, input, output, _, visualKey, visual, valid
function AnimalSystem:loadSubType(animalType, subType, xmlFile, subTypeKey, baseDirectory)
	local v106_ = xmlFile:getString(subTypeKey .. ".rideable#filename")
	if v106_ ~= nil then
		subType.rideableFilename = Utils.getFilename(v106_, baseDirectory)
	end
	subType.input = {
		["straw"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.straw"),
		["water"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.water"),
		["food"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.food")
	}
	local v107_ = {}
	if xmlFile:hasProperty(subTypeKey .. ".output.milk") then
		v107_.milk = {
			["fillType"] = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getString(subTypeKey .. ".output.milk#fillType")),
			["curve"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.milk")
		}
	end
	if xmlFile:hasProperty(subTypeKey .. ".output.pallets") then
		v107_.pallets = {
			["fillType"] = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getString(subTypeKey .. ".output.pallets#fillType")),
			["curve"] = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.pallets")
		}
	end
	v107_.manure = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.manure")
	v107_.liquidManure = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.liquidManure")
	subType.output = v107_
	subType.buyPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".buyPrice")
	subType.transportPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".transportPrice")
	subType.sellPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".sellPrice")
	subType.supportsReproduction = xmlFile:getBool(subTypeKey .. ".reproduction#supported", true)
	subType.reproductionMinAgeMonth = xmlFile:getInt(subTypeKey .. ".reproduction#minAgeMonth", 18)
	subType.reproductionDurationMonth = xmlFile:getInt(subTypeKey .. ".reproduction#durationMonth", 10)
	local v108_ = xmlFile:getFloat(subTypeKey .. ".reproduction#minHealthFactor", 0.75)
	subType.reproductionMinHealth = math.clamp(v108_, 0, 1)
	local v109_ = xmlFile:getInt(subTypeKey .. ".health#increasePerHour", 10)
	subType.healthIncreaseHour = math.clamp(v109_, 0, 100)
	local v110_ = xmlFile:getInt(subTypeKey .. ".health#decreasePerHour", 25)
	subType.healthDecreaseHour = math.clamp(v110_, 0, 100)
	local v111_ = xmlFile:getFloat(subTypeKey .. ".health#thresholdFactor", 0.2)
	subType.healthThresholdFactor = math.clamp(v111_, 0, 1)
	local v112_ = xmlFile:getFloat(subTypeKey .. ".health#ridingThreshold", 0.4)
	subType.ridingThresholdFactor = math.clamp(v112_, 0, 1)
	subType.visuals = {}
	for _, v113_ in xmlFile:iterator(subTypeKey .. ".visuals.visual") do
		local v114_ = self:loadVisualData(animalType, xmlFile, v113_, baseDirectory)
		if v114_ ~= nil then
			local v115_ = true
			if #subType.visuals == 0 then
				if v114_.minAge ~= 0 then
					Logging.xmlWarning(xmlFile, "First visual must have minAge = 0 for \'%s\'", v113_)
					v115_ = false
				end
			elseif v114_.minAge <= subType.visuals[#subType.visuals].minAge then
				Logging.xmlWarning(xmlFile, "Visual minAge has to be greater than predecessor minAge. \'%s\'", v113_)
				v115_ = false
			end
			if v115_ then
				local v116_ = subType.visuals
				table.insert(v116_, v114_)
			end
		end
	end
	if #subType.visuals ~= 0 then
		return true
	end
	Logging.xmlWarning(xmlFile, "No visuals defined for \'%s\'", subTypeKey)
	return false
end

-- Local values: curve, _, valueKey, ageMonth, value
function AnimalSystem:loadAnimCurve(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	local v119_ = AnimCurve.new(linearInterpolator1)
	for _, v120_ in xmlFile:iterator(key .. ".key") do
		local v121_ = xmlFile:getInt(v120_ .. "#ageMonth")
		local v122_ = xmlFile:getInt(v120_ .. "#value")
		if v121_ == nil then
			Logging.xmlWarning(xmlFile, "Missing ageMonth for \'%s\'", v120_)
		elseif v122_ == nil then
			Logging.xmlWarning(xmlFile, "Missing value for \'%s\'", v120_)
		else
			v119_:addKeyframe({
				v122_,
				["time"] = v121_
			})
		end
	end
	return v119_
end

-- Local values: visualAnimalIndex, animal, image, minAge, descriptions, _, descKey, descItem, store, visualData
function AnimalSystem:loadVisualData(animalType, xmlFile, key, baseDirectory)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	local v128_ = xmlFile:getInt(key .. "#visualAnimalIndex")
	if v128_ == nil then
		Logging.xmlError(xmlFile, "Missing animal index for \'%s\'", key)
		return nil
	end
	local v129_ = animalType.animals[v128_]
	if v129_ == nil then
		Logging.xmlError(xmlFile, "Animal index not defined for \'%s\'", key)
		return nil
	end
	local v130_ = xmlFile:getString(key .. "#image")
	if v130_ == nil then
		Logging.xmlError(xmlFile, "Missing store image for \'%s\'", key)
		return nil
	end
	local v131_ = xmlFile:getInt(key .. "#minAge", 0)
	if v131_ < 0 then
		Logging.xmlError(xmlFile, "Invalid minAge for \'%s\'", key)
		return nil
	end
	local v132_ = {}
	for _, v133_ in xmlFile:iterator(key .. ".description") do
		local v134_ = xmlFile:getString(v133_)
		if v134_ ~= nil then
			local v135_ = g_i18n
			local v136_ = self.customEnvironment
			table.insert(v132_, v135_:convertText(v134_, v136_))
		end
	end
	if #v132_ ~= 0 then
		return {
			["store"] = {
				["imageFilename"] = Utils.getFilename(v130_, baseDirectory),
				["canBeBought"] = xmlFile:getBool(key .. "#canBeBought", false),
				["description"] = table.concat(v132_, " ")
			},
			["visualAnimalIndex"] = v128_,
			["minAge"] = v131_,
			["visualAnimal"] = v129_
		}
	end
	Logging.xmlError(xmlFile, "Missing description for \'%s\'", key)
	return nil
end

-- Local values: subType
function AnimalSystem:getAnimalBuyPrice(subTypeIndex, age)
	local v140_ = self.subTypes[subTypeIndex]
	if v140_ == nil then
		return nil
	else
		return v140_.buyPrice:get(age)
	end
end

-- Local values: subType
function AnimalSystem:getAnimalTransportFee(subTypeIndex, age)
	local v144_ = self.subTypes[subTypeIndex]
	return v144_ == nil and 0 or v144_.transportPrice:get(age)
end

-- Local values: visual
function AnimalSystem:getVisualAnimalIndexByAge(subTypeIndex, age)
	local v148_ = self:getVisualByAge(subTypeIndex, age)
	if v148_ == nil then
		return nil
	else
		return v148_.visualAnimalIndex
	end
end

-- Local values: subType, visual, _, v
function AnimalSystem:getVisualByAge(subTypeIndex, age)
	local v152_ = self.subTypes[subTypeIndex]
	if v152_ == nil then
		return nil
	end
	local v153_ = nil
	for _, v154_ in ipairs(v152_.visuals) do
		if v154_.minAge <= age then
			v153_ = v154_
		end
	end
	return v153_
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
	if self.fillTypeIndexToSubType[fillTypeIndex] == nil then
		return nil
	else
		return self.fillTypeIndexToSubType[fillTypeIndex].subTypeIndex
	end
end

-- Local values: subType
function AnimalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
	return self.subTypes[subTypeIndex].typeIndex
end

function AnimalSystem:getTypes()
	return self.types
end

-- Local values: subType, animalType
function AnimalSystem:getClusterClassBySubTypeIndex(subTypeIndex)
	return self:getTypeByIndex(self:getSubTypeByIndex(subTypeIndex).typeIndex).clusterClass
end

-- Local values: subType, animalType, cluster
function AnimalSystem:createClusterFromSubTypeIndex(subTypeIndex)
	local v178_ = self:getTypeByIndex(self:getSubTypeByIndex(subTypeIndex).typeIndex).clusterClass.new()
	v178_.subTypeIndex = subTypeIndex
	return v178_
end
