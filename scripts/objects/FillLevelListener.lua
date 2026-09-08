-- Local values: FillLevelListener_mt
FillLevelListener = {}
local FillLevelListener_mt = Class(FillLevelListener, Object)
InitStaticObjectClass(FillLevelListener, "FillLevelListener")

-- Upvalues: FillLevelListener_mt
-- Local values: self
function FillLevelListener.new(isServer, isClient, customMt)
	-- upvalues: (copy) FillLevelListener_mt
	return Object.new(isServer, isClient, customMt or FillLevelListener_mt)
end

-- Local values: fillTypeCategories, fillTypeNames, fillTypes, _, fillType, avoidFillTypes, avoidFillTypeNames, _, avoidFillType, minMaxY
function FillLevelListener:load(id)
	self.node = id
	self.fillTypes = {}
	local v7_ = getUserAttribute(id, "fillTypeCategories")
	local v8_ = getUserAttribute(id, "fillTypes")
	local v9_ = nil
	if v7_ == nil or v8_ ~= nil then
		if v7_ == nil and v8_ ~= nil then
			v9_ = g_fillTypeManager:getFillTypesByNames(v8_, "Warning: UnloadTrigger has invalid fillType \'%s\'.")
		end
	else
		v9_ = g_fillTypeManager:getFillTypesByCategoryNames(v7_, "Warning: UnloadTrigger has invalid fillTypeCategory \'%s\'.")
	end
	if v9_ == nil then
		self.fillTypes = nil
	else
		for _, v10_ in pairs(v9_) do
			self.fillTypes[v10_] = true
		end
	end
	if self.fillTypes ~= nil then
		local v11_ = getUserAttribute(id, "avoidFillTypes")
		local v12_
		if v11_ == nil then
			v12_ = nil
		else
			v12_ = g_fillTypeManager:getFillTypesByNames(v11_, "Warning: UnloadTrigger has invalid avoidFillType \'%s\'.")
		end
		if v12_ ~= nil then
			for _, v13_ in pairs(v12_) do
				if self.fillTypes[v13_] ~= nil then
					self.fillTypes[v13_] = nil
				end
			end
		end
	end
	self.fillLevelMaxY = getUserAttribute(id, "fillLevelMaxY")
	local v14_ = getUserAttribute(id, "minMaxY")
	self.minMaxY = string.getVector(v14_, 2)
	self.baseTranslation = { getTranslation(self.node) }
	self.currentY = self.baseTranslation[2]
	if self.fillTypes == nil or (self.fillLevelMaxY == nil or self.minMaxY == nil) then
		return false
	end
	self.dirtyFlag = self:getNextDirtyFlag()
	return true
end

function FillLevelListener:delete() end

-- Local values: newY
function FillLevelListener:readStream(streamId, connection)
	FillLevelListener:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local v18_ = streamReadFloat32(streamId)
		setTranslation(self.node, self.baseTranslation[1], v18_, self.baseTranslation[3])
	end
end

function FillLevelListener:writeStream(streamId, connection)
	FillLevelListener:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteFloat32(streamId, self.currentY)
	end
end

-- Local values: newY
function FillLevelListener:readUpdateStream(streamId, timestamp, connection)
	FillLevelListener:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v26_ = streamReadFloat32(streamId)
		setTranslation(self.node, self.baseTranslation[1], v26_, self.baseTranslation[3])
	end
end

function FillLevelListener:writeUpdateStream(streamId, connection, dirtyMask)
	FillLevelListener:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v31_ = streamWriteBool
		local v32_ = self.dirtyFlag
		if v31_(streamId, bit32.band(dirtyMask, v32_) ~= 0) then
			streamWriteFloat32(streamId, self.currentY)
		end
	end
end

-- Local values: supportedFillTypes, fillType, _, fillType, _
function FillLevelListener:setSource(source)
	local v35_ = source.getFillLevel ~= nil
	assert(v35_)
	local v36_ = source.getSupportedFillTypes ~= nil
	assert(v36_)
	self.source = source
	local v37_ = self.source:getSupportedFillTypes()
	for v38_, _ in pairs(self.fillTypes) do
		if v37_[v38_] ~= true then
			self.fillTypes[v38_] = nil
		end
	end
	self.fillLevels = {}
	for v39_, _ in pairs(self.fillTypes) do
		self.fillLevels[v39_] = 0
	end
end

-- Local values: fillLevelSum, fillType, fillLevel, p, newY
function FillLevelListener:fillLevelsChanged()
	local v41_ = 0
	for _, v42_ in pairs(self.fillLevels) do
		v41_ = v41_ + v42_
	end
	local v43_ = v41_ / self.fillLevelMaxY
	local v44_ = math.min(1, v43_)
	local v45_ = self.minMaxY[1] + v44_ * (self.minMaxY[2] - self.minMaxY[1])
	if v45_ ~= self.currentY then
		self:raiseDirtyFlags(self.dirtyFlag)
	end
	self.currentY = v45_
	setTranslation(self.node, self.baseTranslation[1], v45_, self.baseTranslation[3])
end
