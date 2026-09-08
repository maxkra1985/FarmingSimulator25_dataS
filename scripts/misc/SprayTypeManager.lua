-- Local values: SprayTypeManager_mt
SprayType = nil
SprayTypeManager = {}
local SprayTypeManager_mt = Class(SprayTypeManager, AbstractManager)

-- Upvalues: SprayTypeManager_mt
-- Local values: self
function SprayTypeManager.new(customMt)
	-- upvalues: (copy) SprayTypeManager_mt
	return AbstractManager.new(customMt or SprayTypeManager_mt)
end

function SprayTypeManager:initDataStructures()
	self.numSprayTypes = 0
	self.sprayTypes = {}
	self.nameToSprayType = {}
	self.nameToIndex = {}
	self.indexToName = {}
	self.fillTypeIndexToSprayType = {}
	SprayType = self.nameToIndex
end

-- Local values: xmlFile
function SprayTypeManager:loadDefaultTypes()
	local v5_ = loadXMLFile("sprayTypes", "data/maps/maps_sprayTypes.xml")
	self:loadSprayTypes(v5_, nil, true)
	delete(v5_)
end

function SprayTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	SprayTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()
	return XMLUtil.loadDataFromMapXML(xmlFile, "sprayTypes", baseDirectory, self, self.loadSprayTypes, missionInfo)
end

-- Local values: i, key, name, litersPerSecond, typeName, sprayGroundType
function SprayTypeManager:loadSprayTypes(xmlFile, missionInfo, isBaseType)
	local v13_ = 0
	while true do
		local v14_ = string.format("map.sprayTypes.sprayType(%d)", v13_)
		if not hasXMLProperty(xmlFile, v14_) then
			break
		end
		self:addSprayType(getXMLString(xmlFile, v14_ .. "#name"), getXMLFloat(xmlFile, v14_ .. "#litersPerSecond"), getXMLString(xmlFile, v14_ .. "#type"), FieldSprayType.getValueByName(getXMLString(xmlFile, v14_ .. "#sprayGroundType")), isBaseType)
		v13_ = v13_ + 1
	end
	return true
end

-- Local values: fillType, sprayType
function SprayTypeManager:addSprayType(name, litersPerSecond, typeName, sprayGroundType, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a sprayType. Ignoring sprayType!")
		return nil
	end
	local v21_ = string.upper(name)
	local v22_ = g_fillTypeManager:getFillTypeByName(v21_)
	if v22_ ~= nil then
		if isBaseType and self.nameToSprayType[v21_] ~= nil then
			printWarning("Warning: SprayType \'" .. tostring(v21_) .. "\' already exists. Ignoring sprayType!")
			return nil
		end
		local v23_ = self.nameToSprayType[v21_]
		if v23_ == nil then
			self.numSprayTypes = self.numSprayTypes + 1
			v23_ = {
				["name"] = v21_,
				["index"] = self.numSprayTypes,
				["fillType"] = v22_,
				["litersPerSecond"] = Utils.getNoNil(litersPerSecond, 0)
			}
			local v24_ = string.upper(typeName)
			v23_.isFertilizer = v24_ == "FERTILIZER"
			v23_.isLime = v24_ == "LIME"
			v23_.isHerbicide = v24_ == "HERBICIDE"
			if not (v23_.isFertilizer or (v23_.isLime or v23_.isHerbicide)) then
				printWarning("Warning: SprayType \'" .. tostring(v21_) .. "\' type \'" .. tostring(v24_) .. "\' is invalid. Possible values are \'FERTILIZER\', \'HERBICIDE\' or \'LIME\'. Ignoring sprayType!")
				return nil
			end
			local v25_ = self.sprayTypes
			table.insert(v25_, v23_)
			self.nameToSprayType[v21_] = v23_
			self.nameToIndex[v21_] = self.numSprayTypes
			self.indexToName[self.numSprayTypes] = v21_
			self.fillTypeIndexToSprayType[v22_.index] = v23_
		end
		v23_.litersPerSecond = litersPerSecond or (v23_.litersPerSecond or 0)
		v23_.sprayGroundType = sprayGroundType or (v23_.sprayGroundType or 1)
		return v23_
	end
	printWarning("Warning: Missing fillType \'" .. tostring(v21_) .. "\' for sprayType definition. Ignoring sprayType!")
end

function SprayTypeManager:getSprayTypeByIndex(index)
	if index == nil then
		return nil
	else
		return self.sprayTypes[index]
	end
end

function SprayTypeManager:getSprayTypeByName(name)
	if name == nil then
		return nil
	end
	local v30_ = string.upper(name)
	return self.nameToSprayType[v30_]
end

function SprayTypeManager:getFillTypeNameByIndex(index)
	if index == nil then
		return nil
	else
		return self.indexToName[index]
	end
end

function SprayTypeManager:getFillTypeIndexByName(name)
	if name == nil then
		return nil
	end
	local v35_ = string.upper(name)
	return self.nameToIndex[v35_]
end

function SprayTypeManager:getFillTypeByName(name)
	if name == nil then
		return nil
	end
	local v38_ = string.upper(name)
	return self.nameToSprayType[v38_]
end

function SprayTypeManager:getSprayTypeByFillTypeIndex(index)
	if index == nil then
		return nil
	else
		return self.fillTypeIndexToSprayType[index]
	end
end

-- Local values: sprayType
function SprayTypeManager:getSprayTypeIndexByFillTypeIndex(index)
	if index ~= nil then
		local v43_ = self.fillTypeIndexToSprayType[index]
		if v43_ ~= nil then
			return v43_.index
		end
	end
	return nil
end

function SprayTypeManager:getSprayTypes()
	return self.sprayTypes
end
g_sprayTypeManager = SprayTypeManager.new()
