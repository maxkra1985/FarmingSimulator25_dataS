-- Local values: ManureHeap_mt
ManureHeap = {}
local ManureHeap_mt = Class(ManureHeap, Object)
InitStaticObjectClass(ManureHeap, "ManureHeap")

-- Upvalues: ManureHeap_mt
-- Local values: self
function ManureHeap.new(isServer, isClient, customMt)
	-- upvalues: (copy) ManureHeap_mt
	local v5_ = Object.new(isServer, isClient, customMt or ManureHeap_mt)
	v5_.unloadingStations = {}
	v5_.loadingStations = {}
	v5_.fillLevelChangedListeners = {}
	v5_.rootNode = 0
	return v5_
end

function ManureHeap:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.rootNode = xmlFile:getValue(key .. "#node", components[1].node, components, i3dMappings)
	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing root node for manure heap")
		return false
	end
	self.isExtension = xmlFile:getValue(key .. "#isExtension", true)
	self.area = {}
	self.area.start = xmlFile:getValue(key .. ".area#startNode", nil, components, i3dMappings)
	self.area.width = xmlFile:getValue(key .. ".area#widthNode", nil, components, i3dMappings)
	self.area.height = xmlFile:getValue(key .. ".area#heightNode", nil, components, i3dMappings)
	local v11_ = self.area
	local v12_
	if self.area.start == nil or self.area.width == nil then
		v12_ = false
	else
		v12_ = self.area.height ~= nil
	end
	v11_.isAvailable = v12_
	if self.area.isAvailable then
		self.splitAreas = DensityMapHeightUtil.getAreaPartitions(self.area.start, self.area.width, self.area.height)
	end
	self.activationTriggerNode = xmlFile:getValue(key .. ".area#activationTriggerNode", nil, components, i3dMappings)
	if self.activationTriggerNode == nil and self.area.isAvailable then
		Logging.xmlError(xmlFile, "Missing activation trigger node for manure heap")
		return false
	end
	if self.area.isAvailable and self.isServer then
		addTrigger(self.activationTriggerNode, "onVehicleCallback", self)
	end
	self.clearArea = {}
	self.clearArea.start = xmlFile:getValue(key .. ".clearArea#startNode", nil, components, i3dMappings)
	self.clearArea.width = xmlFile:getValue(key .. ".clearArea#widthNode", nil, components, i3dMappings)
	self.clearArea.height = xmlFile:getValue(key .. ".clearArea#heightNode", nil, components, i3dMappings)
	local v13_ = self.clearArea
	local v14_
	if self.clearArea.start == nil or self.clearArea.width == nil then
		v14_ = false
	else
		v14_ = self.clearArea.height ~= nil
	end
	v13_.isAvailable = v14_
	self.capacity = xmlFile:getValue(key .. "#capacity", 20000)
	if self.capacity <= 0 then
		Logging.xmlError(xmlFile, "Invalid capacity")
		return false
	end
	self.fillTypeIndex = FillType.MANURE
	self.fillTypes = {
		[self.fillTypeIndex] = true
	}
	self.fillLevels = {
		[self.fillTypeIndex] = 0
	}
	self.fillPlane = FillPlane.new()
	if self.fillPlane:load(components, xmlFile, key .. ".fillPlane", i3dMappings) then
		self.fillPlane:setFillType(self.fillTypeIndex)
		self.fillPlane:setState(0)
		self.fillPlaneCapacity = xmlFile:getValue(key .. ".fillPlane#capacity", self.capacity)
	else
		self.fillPlane:delete()
		self.fillPlane = nil
	end
	self.minValidLiterValue = g_densityMapHeightManager:getMinValidLiterValue(self.fillTypeIndex)
	self.manureToDrop = 0
	self.manureToPick = 0
	self.visibleFillLevel = 0
	self.lastVisibleFillLevel = 0
	self.dirtyFlag = self:getNextDirtyFlag()
	return true
end

-- Local values: xs, _, zs, xw, _, zw, xh, _, zh
function ManureHeap:delete()
	if self.isServer then
		if self.clearArea ~= nil and self.clearArea.isAvailable then
			local v16_, _, v17_ = getWorldTranslation(self.clearArea.start)
			local v18_, _, v19_ = getWorldTranslation(self.clearArea.width)
			local v20_, _, v21_ = getWorldTranslation(self.clearArea.height)
			DensityMapHeightUtil.clearArea(v16_, v17_, v18_, v19_, v20_, v21_)
		end
		if self.activationTriggerNode ~= nil then
			removeTrigger(self.activationTriggerNode)
			self.activationTriggerNode = nil
		end
	end
	if self.area ~= nil and self.area.isAvailable then
		g_densityMapHeightManager:removeFixedFillTypesArea(self.area)
	end
	ManureHeap:superClass().delete(self)
end

function ManureHeap:finalize()
	if self.area.isAvailable then
		g_densityMapHeightManager:setFixedFillTypesArea(self.area, self.fillTypes)
	end
	self:updateTotalFillLevel(true)
end

function ManureHeap:loadFromXMLFile(xmlFile, key)
	self.manureToDrop = xmlFile:getValue(key .. "#manureToDrop", self.manureToDrop)
	self.manureToPick = xmlFile:getValue(key .. "#manureToPick", self.manureToPick)
	return true
end

function ManureHeap:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#manureToDrop", self.manureToDrop)
	xmlFile:setValue(key .. "#manureToPick", self.manureToPick)
end

function ManureHeap:readStream(streamId, connection)
	ManureHeap:superClass().readStream(self, streamId, connection)
	self.fillLevels[self.fillTypeIndex] = streamReadFloat32(streamId)
end

function ManureHeap:writeStream(streamId, connection)
	ManureHeap:superClass().writeStream(self, streamId, connection)
	streamWriteFloat32(streamId, self.fillLevels[self.fillTypeIndex])
end

function ManureHeap:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		self.fillLevels[self.fillTypeIndex] = streamReadInt32(streamId)
	end
end

function ManureHeap:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v42_ = streamWriteBool
		local v43_ = self.dirtyFlag
		if v42_(streamId, bit32.band(dirtyMask, v43_) ~= 0) then
			streamWriteInt32(streamId, self.fillLevels[self.fillTypeIndex])
		end
	end
end

-- Local values: litersToDrop, _, area, lsx, lsy, lsz, lex, ley, lez, radius, dropped, lineOffset, litersToPick, i, area, lsx, lsy, lsz, lex, ley, lez, radius, picked, lineOffset
function ManureHeap:update(dt)
	if self.area.isAvailable and self.isServer then
		if self.manureToDrop > self.minValidLiterValue then
			local v45_ = self.manureToDrop
			for _, v46_ in ipairs(self.splitAreas) do
				local v47_, v48_, v49_, v50_, v51_, v52_, v53_ = DensityMapHeightUtil.getLineByArea(v46_.start, v46_.width, v46_.height, false)
				local v54_, v55_ = DensityMapHeightUtil.tipToGroundAroundLine(nil, v45_, self.fillTypeIndex, v47_, v48_, v49_, v50_, v51_, v52_, v53_, v53_, v46_.lineOffset, false, nil)
				v46_.lineOffset = v55_
				local v56_ = v45_ - v54_
				v45_ = math.max(v56_, 0)
				if v45_ <= 0 then
					break
				end
			end
			self.manureToDrop = v45_
		end
		if self.manureToPick > self.minValidLiterValue then
			local v57_ = self.manureToPick
			for v58_ = #self.splitAreas, 1, -1 do
				local v59_ = self.splitAreas[v58_]
				local v60_, v61_, v62_, v63_, v64_, v65_, v66_ = DensityMapHeightUtil.getLineByArea(v59_.start, v59_.width, v59_.height, false)
				local v67_, v68_ = DensityMapHeightUtil.tipToGroundAroundLine(nil, -v57_, self.fillTypeIndex, v60_, v61_, v62_, v63_, v64_, v65_, v66_, v66_, v59_.lineOffset, false, nil)
				v59_.lineOffset = v68_
				local v69_ = v57_ + v67_
				v57_ = math.max(v69_, 0)
				if v57_ <= 0 then
					break
				end
			end
			self.manureToPick = v57_
		end
		self:updateTotalFillLevel()
	end
end

-- Local values: visibleFillLevel, xs, _, zs, xw, _, zw, xh, _, zh
function ManureHeap:updateTotalFillLevel(force)
	local v72_
	if self.area.isAvailable then
		local v73_, _, v74_ = getWorldTranslation(self.area.start)
		local v75_, _, v76_ = getWorldTranslation(self.area.width)
		local v77_, _, v78_ = getWorldTranslation(self.area.height)
		v72_ = DensityMapHeightUtil.getFillLevelAtArea(self.fillTypeIndex, v73_, v74_, v75_, v76_, v77_, v78_)
	else
		v72_ = 0
	end
	if v72_ ~= self.lastVisibleFillLevel or force then
		self.fillLevels[self.fillTypeIndex] = v72_ + self.manureToDrop - self.manureToPick
		self.lastVisibleFillLevel = v72_
		self:onFillLevelChanged()
		self:raiseDirtyFlags(self.dirtyFlag)
	end
end

function ManureHeap:getIsFillTypeSupported(fillTypeIndex)
	return fillTypeIndex == self.fillTypeIndex
end

function ManureHeap:getFillLevel(fillTypeIndex)
	return fillTypeIndex ~= self.fillTypeIndex and 0 or self.fillLevels[fillTypeIndex]
end

function ManureHeap:getFillLevels()
	return self.fillLevels
end

function ManureHeap:getCapacity(fillTypeIndex)
	return fillTypeIndex ~= self.fillTypeIndex and 0 or self.capacity
end

-- Local values: oldFillLevel, delta, absDelta, _, func
function ManureHeap:setFillLevel(fillLevel, fillTypeIndex)
	if fillTypeIndex == self.fillTypeIndex then
		local v89_ = self.fillLevels[fillTypeIndex]
		local v90_ = self.capacity
		local v91_ = math.clamp(fillLevel, 0, v90_)
		local v92_ = v91_ - v89_
		local v93_ = math.abs(v92_)
		if v93_ > 0.1 then
			self.fillLevels[fillTypeIndex] = v91_
			self:onFillLevelChanged()
			if self.isServer then
				if v92_ > 0 then
					self.manureToDrop = self.manureToDrop + v93_
				else
					self.manureToPick = self.manureToPick + v93_
				end
				if self.manureToPick > self.manureToDrop then
					self.manureToPick = self.manureToPick - self.manureToDrop
					self.manureToDrop = 0
				else
					self.manureToDrop = self.manureToDrop - self.manureToPick
					self.manureToPick = 0
				end
				self:raiseActive()
				self:raiseDirtyFlags(self.dirtyFlag)
			end
			for _, v94_ in ipairs(self.fillLevelChangedListeners) do
				v94_(self.fillTypeIndex, v92_)
			end
		end
	end
end

-- Local values: fillLevel
function ManureHeap:onFillLevelChanged()
	local v96_ = self.fillLevels[self.fillTypeIndex]
	if self.fillPlane ~= nil then
		local v97_ = self.fillPlane
		local v98_ = v96_ / self.fillPlaneCapacity
		v97_:setState((math.min(v98_, 1)))
	end
end

-- Local values: newFillLevel
function ManureHeap:removeManure(absDelta)
	if self.isServer then
		local v101_ = self.fillLevels[self.fillTypeIndex] - absDelta
		self:setFillLevel(math.max(v101_, 0), self.fillTypeIndex)
	end
end

function ManureHeap:getFreeCapacity(fillTypeIndex)
	if fillTypeIndex ~= self.fillTypeIndex then
		return 0
	end
	local v104_ = self.capacity - self.fillLevels[self.fillTypeIndex]
	return math.max(v104_, 0)
end

function ManureHeap:getSupportedFillTypes()
	return self.fillTypes
end

-- Local values: node
function ManureHeap:onVehicleCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onLeave then
		if g_currentMission:getNodeObject(otherId) ~= nil then
			self:raiseActive()
			return
		end
	elseif onEnter and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		self:raiseActive()
	end
end

function ManureHeap:addUnloadingStation(station)
	self.unloadingStations[station] = station
end

function ManureHeap:removeUnloadingStation(station)
	self.unloadingStations[station] = nil
end

function ManureHeap:addLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = loadingStation
end

function ManureHeap:removeLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = nil
end

function ManureHeap:addFillLevelChangedListeners(func)
	table.addElement(self.fillLevelChangedListeners, func)
end

function ManureHeap:removeFillLevelChangedListeners(func)
	table.removeElement(self.fillLevelChangedListeners, func)
end

function ManureHeap.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Manure heap rootnode")
	schema:register(XMLValueType.BOOL, basePath .. "#isExtension", "Is extension", true)
	schema:register(XMLValueType.INT, basePath .. "#capacity", "Capacity", 20000)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Manure area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Manure area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Manure area height node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#activationTriggerNode", "Activation trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearArea#startNode", "Manure clear area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearArea#widthNode", "Manure clear area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearArea#heightNode", "Manure clear area height node")
	FillPlane.registerXMLPaths(schema, basePath .. ".fillPlane")
	schema:register(XMLValueType.INT, basePath .. ".fillPlane#capacity", "Capacity at which the fill plane is at the max. level", "same as heap capacity")
end

function ManureHeap.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#manureToDrop", "Manure that should be drop the visible heap", 0)
	schema:register(XMLValueType.INT, basePath .. "#manureToPick", "Manure that need to be picked from visible heap", 0)
end
