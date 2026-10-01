ConstructibleStateBuilding = {}
local ConstructibleStateBuilding_mt = Class(ConstructibleStateBuilding, ConstructibleState)
function ConstructibleStateBuilding.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".mesh(?)#node", "")
	schema:register(XMLValueType.INT, basePath .. ".mesh(?)#indexMin", "")
	schema:register(XMLValueType.INT, basePath .. ".mesh(?)#indexMax", "")
	schema:register(XMLValueType.INT, basePath .. ".mesh(?)#direction", "")
	schema:register(XMLValueType.STRING, basePath .. ".input(?)#fillType", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#amount", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#usagePerHour", "")
end
function ConstructibleStateBuilding.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".state.input(?)#fillType", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".state.input(?)#remainingAmount", "")
end
function ConstructibleStateBuilding.new(constructible, dirtyFlag, customMt)
	local self = ConstructibleState.new(constructible, dirtyFlag, customMt or ConstructibleStateBuilding_mt)
	return self
end
function ConstructibleStateBuilding:load(xmlFile, key)
	ConstructibleStateBuilding:superClass().load(self, xmlFile, key)
	self.totalAmount = 0
	self.inputs = {}
	self.hasInputMaterials = true
	for _, inputKey in xmlFile:iterator(key .. ".input") do
		local fillTypeStr = xmlFile:getValue(inputKey .. "#fillType")
		local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
		if fillType == nil then
			Logging.xmlWarning(xmlFile, "Unknown fillType '%s' in '%s'", fillTypeStr, inputKey)
			break
		end
		if not self.constructible:getConstructibleSupportsFillType(fillType.index) then
			Logging.xmlWarning(xmlFile, "Filltype '%s' in '%s' not supported by storage", fillType.name, inputKey)
			break
		end
		local amount = xmlFile:getValue(inputKey .. "#amount")
		local usagePerSecond = xmlFile:getValue(inputKey .. "#usagePerHour") / 60 / 60
		self.totalAmount = self.totalAmount + amount
		table.insert(self.inputs, { fillType = fillType, amount = amount, remainingAmount = amount, lastSyncedAmount = amount, usagePerSecond = usagePerSecond, infoTableEntry = { title = fillType.title, text = g_i18n:formatVolume(amount) } })
	end
	self.meshes = {}
	for _, nodeKey in xmlFile:iterator(key .. ".mesh") do
		local node = xmlFile:getValue(nodeKey .. "#node", nil, self.constructible.components, self.constructible.i3dMappings)
		if node == nil then
			break
		end
		if not getHasClassId(node, ClassIds.SHAPE) then
			Logging.xmlError(xmlFile, "node '%s' at '%s' is not a shape", getName(node), nodeKey)
			break
		end
		if not getHasShaderParameter(node, "hideByIndex") then
			Logging.xmlError(xmlFile, "mesh '%s' at '%s' does not have required shader parameter 'hideByIndex'", getName(node), nodeKey)
			break
		end
		local indexMin = xmlFile:getValue(nodeKey .. "#indexMin", 0)
		local indexMax = xmlFile:getValue(nodeKey .. "#indexMax")
		if indexMax == nil then
			indexMax = getUserAttribute(node, "hideByIndexMaxIndex")
			if indexMin == nil then
				Logging.xmlError(xmlFile, "Cannot retrieve indexMax from shape material and value is also not set in xml at '%s'", getName(node), nodeKey)
				break
			end
		end
		local direction = xmlFile:getValue(nodeKey .. "#direction", 1)
		local mesh = { node = node, indexMin = indexMin, indexMax = indexMax, direction = direction }
		mesh.childIndex = getChildIndex(node)
		mesh.index = #self.meshes + 1
		mesh.lastValue = -1
		mesh.numBits = MathUtil.getNumRequiredBits(indexMax)
		self:setMeshProgress(mesh, 0)
		table.insert(self.meshes, mesh)
	end
	self.infoBoxRequiredGoods = { title = g_i18n:getText("infohud_requiredMaterialsNextStep"), accentuate = true }
end
function ConstructibleStateBuilding:saveToXMLFile(xmlFile, key, usedModNames)
	for k, input in ipairs(self.inputs) do
		local inputKey = string.format("%s.state.input(%d)", key, k - 1)
		xmlFile:setValue(inputKey .. "#fillType", input.fillType.name)
		xmlFile:setValue(inputKey .. "#remainingAmount", input.remainingAmount)
	end
end
function ConstructibleStateBuilding:loadFromXMLFile(xmlFile, key)
	for _, inputKey in xmlFile:iterator(key .. ".state.input") do
		local fillType = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(inputKey .. "#fillType"))
		local remainingAmount = xmlFile:getValue(inputKey .. "#remainingAmount")
		for _, input in ipairs(self.inputs) do
			if input.fillType == fillType then
				self:updateRemainingAmount(input, remainingAmount)
			end
		end
	end
end
function ConstructibleStateBuilding:isDone()
	for _, input in ipairs(self.inputs) do
		if 0 < input.remainingAmount then
			return false
		end
	end
	return true
end
function ConstructibleStateBuilding:onReadStream(streamId, connection)
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, streamReadFloat32(streamId))
	end
	for meshIndex, mesh in ipairs(self.meshes) do
		local hideByIndexValue = streamReadUIntN(streamId, mesh.numBits)
		local progress = MathUtil.inverseLerp(mesh.indexMax, mesh.indexMin, hideByIndexValue)
		if mesh.direction == -1 then
			progress = 1 - progress
		end
		self:setMeshProgress(mesh, progress)
	end
end
function ConstructibleStateBuilding:onWriteStream(streamId, connection)
	for i, input in ipairs(self.inputs) do
		streamWriteFloat32(streamId, input.remainingAmount)
	end
	for meshIndex, mesh in ipairs(self.meshes) do
		streamWriteUIntN(streamId, mesh.lastValue, mesh.numBits)
	end
end
function ConstructibleStateBuilding:onReadUpdateStream(streamId, timestamp, connection)
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, streamReadFloat32(streamId))
	end
	for meshIndex, mesh in ipairs(self.meshes) do
		local hideByIndexValue = streamReadUIntN(streamId, mesh.numBits)
		local progress = MathUtil.inverseLerp(mesh.indexMax, mesh.indexMin, hideByIndexValue)
		if mesh.direction == -1 then
			progress = 1 - progress
		end
		self:setMeshProgress(mesh, progress)
	end
end
function ConstructibleStateBuilding:onWriteUpdateStream(streamId, connection, dirtyMask)
	for i, input in ipairs(self.inputs) do
		streamWriteFloat32(streamId, input.remainingAmount)
	end
	for _, mesh in ipairs(self.meshes) do
		streamWriteUIntN(streamId, mesh.lastValue, mesh.numBits)
	end
end
function ConstructibleStateBuilding:raiseActive()
	return self.hasInputMaterials
end
function ConstructibleStateBuilding:getPlaySound()
	return self.hasInputMaterials
end
function ConstructibleStateBuilding:update(dt)
	local usedAmount = 0
	self.hasInputMaterials = false
	for i, input in ipairs(self.inputs) do
		usedAmount = usedAmount + (input.amount - input.remainingAmount)
		if 0 < input.remainingAmount then
			local amount = input.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale)
			local delta = self.constructible:removeConstructibleFillLevel(input.fillType.index, amount)
			if 0 < delta then
				self.hasInputMaterials = true
				self:updateRemainingAmount(input, input.remainingAmount - delta)
				if input.amount / 100 < math.abs(input.remainingAmount - input.lastSyncedAmount) or input.remainingAmount <= 0.01 or input.remainingAmount == input.amount then
					self.constructible:raiseDirtyFlags(self.dirtyFlag)
					input.lastSyncedAmount = input.remainingAmount
				end
			end
		end
	end
	for _, mesh in ipairs(self.meshes) do
		self:setMeshProgress(mesh, usedAmount / self.totalAmount)
	end
	ConstructibleStateBuilding:superClass().update(self, dt)
end
function ConstructibleStateBuilding:deactivate()
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, input.amount)
	end
	for _, mesh in ipairs(self.meshes) do
		self:setMeshProgress(mesh, 1)
	end
	ConstructibleStateBuilding:superClass().deactivate(self)
end
function ConstructibleStateBuilding:reset()
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, input.amount)
	end
	for _, mesh in ipairs(self.meshes) do
		self:setMeshProgress(mesh, 0)
	end
	ConstructibleStateBuilding:superClass().reset(self)
end
function ConstructibleStateBuilding:updateInfo(infoTable)
	table.insert(infoTable, self.infoBoxRequiredGoods)
	for i, input in ipairs(self.inputs) do
		if 0.01 < input.remainingAmount then
			table.insert(infoTable, input.infoTableEntry)
		end
	end
end
function ConstructibleStateBuilding:updateRemainingAmount(input, amount)
	if amount < 0.01 then
		amount = 0
	end
	input.remainingAmount = math.max(0, amount)
	input.infoTableEntry.text = g_i18n:formatVolume(math.ceil(input.remainingAmount))
end
function ConstructibleStateBuilding:setMeshProgress(mesh, percentage)
	if mesh ~= nil then
		if mesh.direction == -1 then
			percentage = 1 - percentage
		end
		local hideByIndexValue = math.round(MathUtil.lerp(mesh.indexMax, mesh.indexMin, percentage))
		if hideByIndexValue ~= mesh.lastValue then
			local node = mesh.node
			setVisibility(node, percentage ~= 0)
			mesh.lastValue = hideByIndexValue
			setShaderParameter(node, "hideByIndex", hideByIndexValue, 0, 0, 0, false)
			if self.constructible.isServer then
				self.constructible:raiseDirtyFlags(self.dirtyFlag)
			end
		end
	end
end
