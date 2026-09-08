-- Local values: InfoLayer_mt
InfoLayer = {}
local InfoLayer_mt = Class(InfoLayer)

-- Upvalues: InfoLayer_mt
-- Local values: self
function InfoLayer.new(name, baseDirectory, customMt)
	-- upvalues: (copy) InfoLayer_mt
	local v5_ = customMt or InfoLayer_mt
	local v6_ = setmetatable({}, v5_)
	v6_.baseDirectory = baseDirectory
	v6_.bitVector = createBitVectorMap(name)
	v6_.name = name
	v6_.width = 0
	v6_.height = 0
	v6_.doDelete = true
	return v6_
end

-- Upvalues: InfoLayer_mt
-- Local values: self, infoLayerId, success
function InfoLayer.newFromMap(terrainNode, name, customMt)
	-- upvalues: (copy) InfoLayer_mt
	local v10_ = customMt or InfoLayer_mt
	local v11_ = setmetatable({}, v10_)
	v11_.name = name
	local v12_ = getInfoLayerFromTerrain(terrainNode, name)
	if v12_ == nil or v12_ == 0 then
		Logging.warning("Missing infolayer \'%s\' in map", name)
		return nil
	end
	if v11_:loadFromMemory(v12_) then
		return v11_
	end
	Logging.warning("Could not load infolayer from map")
	return nil
end

-- Local values: filename, numChannels
function InfoLayer:loadFromXML(xmlFile, key)
	return self:load(Utils.getFilename(xmlFile:getString(key .. "#filename"), self.baseDirectory), (xmlFile:getInt(key .. "#numChannels")))
end

-- Local values: success
function InfoLayer:load(filename, numChannels)
	if not loadBitVectorMapFromFile(self.bitVector, filename, numChannels) then
		printWarning("Warning: Loading infolayer \'" .. self.name .. "\' file \'" .. tostring(filename) .. "\' failed!")
		return false
	end
	self.numChannels = numChannels
	local v19_, v20_ = getBitVectorMapSize(self.bitVector)
	self.width = v19_
	self.height = v20_
	return true
end

function InfoLayer:create(width, height, numChannels, initAll)
	loadBitVectorMapNew(self.bitVector, width, height, numChannels, initAll)
	self.numChannels = numChannels
	self.width = width
	self.height = height
	return true
end

function InfoLayer:loadFromMemory(id)
	self.doDelete = false
	self.bitVector = id
	self.numChannels = getBitVectorMapNumChannels(id)
	local v28_, v29_ = getBitVectorMapSize(id)
	self.width = v28_
	self.height = v29_
	return true
end

function InfoLayer:delete()
	if self.doDelete then
		delete(self.bitVector)
	end
end

function InfoLayer:writeStream(streamId, connection)
	writeBitVectorMapToStream(self.bitVector, streamId)
end

function InfoLayer:readStream(streamId, connection)
	readBitVectorMapFromStream(self.bitVector, streamId)
end

function InfoLayer:getId()
	return self.bitVector
end

-- Local values: terrainSize
function InfoLayer:convertWorldToLocalPosition(worldPosX, worldPosZ)
	local v39_ = g_currentMission.terrainSize
	local v40_ = self.width * (worldPosX + v39_ * 0.5) / v39_
	local v41_ = math.floor(v40_)
	local v42_ = self.height * (worldPosZ + v39_ * 0.5) / v39_
	return v41_, math.floor(v42_)
end

-- Local values: x, y
function InfoLayer:getValueAtWorldPos(worldX, worldZ, firstChannel, numChannels)
	local v48_, v49_ = self:convertWorldToLocalPosition(worldX, worldZ)
	local v50_ = numChannels or self.numChannels
	return getBitVectorMapPoint(self.bitVector, v48_, v49_, firstChannel or 0, v50_)
end

function InfoLayer:getValueAtPos(x, y, firstChannel, numChannels)
	local v56_ = numChannels or self.numChannels
	return getBitVectorMapPoint(self.bitVector, x, y, firstChannel or 0, v56_)
end

function InfoLayer:getValueAtParallelogram(x, y, widthX, widthY, heightX, heightY, firstChannel, numChannels, roundingMode)
	local v67_ = numChannels or self.numChannels
	return getBitVectorMapParallelogram(self.bitVector, x, y, widthX - x, widthY - y, heightX - x, heightY - y, firstChannel or 0, v67_, roundingMode)
end

-- Local values: x, y, widthX, widthY, heightX, heightY
function InfoLayer:getValueAtWorldParallelogram(worldX, worldZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ, firstChannel, numChannels, roundingMode)
	local v78_, v79_ = self:convertWorldToLocalPosition(worldX, worldZ)
	local v80_, v81_ = self:convertWorldToLocalPosition(worldWidthX, worldWidthZ)
	local v82_, v83_ = self:convertWorldToLocalPosition(worldHeightX, worldHeightZ)
	local v84_ = numChannels or self.numChannels
	return getBitVectorMapParallelogram(self.bitVector, v78_, v79_, v80_ - v78_, v81_ - v79_, v82_ - v78_, v83_ - v79_, firstChannel or 0, v84_, roundingMode)
end

-- Local values: x, y, widthX, widthY, heightX, heightY
function InfoLayer:setValueAtWorldParallelogram(worldX, worldZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ, firstChannel, numChannels, value, roundingMode)
	local v96_, v97_ = self:convertWorldToLocalPosition(worldX, worldZ)
	local v98_, v99_ = self:convertWorldToLocalPosition(worldWidthX, worldWidthZ)
	local v100_, v101_ = self:convertWorldToLocalPosition(worldHeightX, worldHeightZ)
	local v102_ = numChannels or self.numChannels
	setBitVectorMapParallelogram(self.bitVector, v96_, v97_, v98_ - v96_, v99_ - v97_, v100_ - v96_, v101_ - v97_, firstChannel or 0, v102_, value, roundingMode)
end

function InfoLayer:setValueAtArea(area, value)
	if self.modifier == nil then
		self.modifier = DensityMapModifier.new(self.bitVector, 0, self.numChannels, g_terrainNode)
	end
	area:applyToModifier(self.modifier)
	self.modifier:executeSet(value)
end

function InfoLayer:saveToFile(filename, asyncCallback, asyncTarget)
	if asyncCallback == nil then
		saveBitVectorMapToFile(self.bitVector, filename)
	else
		prepareSaveBitVectorMapToFile(self.bitVector, filename)
		savePreparedBitVectorMapToFile(self.bitVector, asyncCallback, asyncTarget)
	end
end
