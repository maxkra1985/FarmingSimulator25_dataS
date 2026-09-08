-- Local values: AIParameterFillType_mt
AIParameterFillType = {}
local AIParameterFillType_mt = Class(AIParameterFillType, AIParameter)

-- Upvalues: AIParameterFillType_mt
-- Local values: self
function AIParameterFillType.new(customMt)
	-- upvalues: (copy) AIParameterFillType_mt
	local v3_ = AIParameter.new(customMt or AIParameterFillType_mt)
	v3_.type = AIParameterType.FILLTYPE
	v3_.fillTypes = {}
	v3_.fillTypeIndex = nil
	return v3_
end

-- Local values: fillTypeName
function AIParameterFillType:saveToXMLFile(xmlFile, key, usedModNames)
	if self.fillTypeIndex ~= nil then
		local v7_ = g_fillTypeManager:getFillTypeNameByIndex(self.fillTypeIndex)
		xmlFile:setString(key .. "#fillType", v7_)
	end
end

-- Local values: fillTypeName
function AIParameterFillType:loadFromXMLFile(xmlFile, key)
	local v11_ = xmlFile:getString(key .. "#fillType")
	if v11_ ~= nil then
		self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(v11_)
	end
end

-- Local values: fillTypeIndex
function AIParameterFillType:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self:setFillTypeIndex((streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
	end
end

function AIParameterFillType:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.fillTypeIndex ~= nil) then
		streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
	end
end

-- Local values: maxFillLevel, maxFillLevelFillTypeIndex, isCurrentFillTypeIndexAvailable, fillTypeIndex, fillLevel, title
function AIParameterFillType:setValidFillTypes(fillTypes)
	self.fillTypes = {}
	local v18_ = 0
	local v19_ = nil
	local v20_ = false
	for v21_, v22_ in pairs(fillTypes) do
		if v18_ < v22_ then
			v19_ = v21_
		end
		v20_ = self.fillTypeIndex == v21_ and true or v20_
		local v23_ = g_fillTypeManager:getFillTypeTitleByIndex(v21_)
		local v24_ = string.format("%s (%d l)", v23_, v22_)
		local v25_ = self.fillTypes
		local v26_ = {
			["index"] = #self.fillTypes + 1,
			["fillTypeIndex"] = v21_,
			["title"] = v24_,
			["fillLevel"] = v22_
		}
		table.insert(v25_, v26_)
	end
	table.sort(self.fillTypes, function(p27_, p28_)
		return p27_.title < p28_.title
	end)
	if self.fillTypeIndex == nil or not v20_ then
		if v19_ ~= nil then
			self.fillTypeIndex = v19_
			return
		end
		self:setFillTypeByIndex(1)
	end
end

-- Local values: nextIndex, k, data
function AIParameterFillType:setNextItem()
	local v30_ = 0
	for v31_, v32_ in ipairs(self.fillTypes) do
		if self.fillTypeIndex == v32_.fillTypeIndex then
			v30_ = v31_ + 1
		end
	end
	self:setFillTypeByIndex(#self.fillTypes < v30_ and 1 or v30_)
end

-- Local values: previousIndex, k, data
function AIParameterFillType:setPreviousItem()
	local v34_ = 0
	for v35_, v36_ in ipairs(self.fillTypes) do
		if self.fillTypeIndex == v36_.fillTypeIndex then
			v34_ = v35_ - 1
		end
	end
	self:setFillTypeByIndex(v34_ < 1 and #self.fillTypes or v34_)
end

-- Local values: data
function AIParameterFillType:setFillTypeByIndex(index)
	local v39_ = self.fillTypes[index]
	if v39_ == nil then
		self.fillTypeIndex = nil
	else
		self.fillTypeIndex = v39_.fillTypeIndex
	end
end

function AIParameterFillType:setFillTypeIndex(fillTypeIndex)
	self.fillTypeIndex = fillTypeIndex
end

function AIParameterFillType:getFillTypeIndex()
	return self.fillTypeIndex
end

-- Local values: _, data
function AIParameterFillType:getString()
	for _, v44_ in ipairs(self.fillTypes) do
		if v44_.fillTypeIndex == self.fillTypeIndex then
			return v44_.title
		end
	end
	return ""
end

function AIParameterFillType:validate()
	if self.fillTypeIndex == nil then
		return false, g_i18n:getText("ai_validationErrorNoFillType")
	else
		return true, nil
	end
end
