BoatyardStateBuilding = {}
local BoatyardStateBuilding_mt = Class(BoatyardStateBuilding, BoatyardState)
function BoatyardStateBuilding.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".input(?)#fillType", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#amount", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#usagePerHour", "")
	schema:register(XMLValueType.STRING, basePath .. "#meshId", "")
end
function BoatyardStateBuilding.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".state.input(?)#fillType", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".state.input(?)#remainingAmount", "")
end
function BoatyardStateBuilding.new(boatyard, customMt)
	local self = BoatyardState.new(boatyard, customMt or BoatyardStateBuilding_mt)
	return self
end
function BoatyardStateBuilding:load(xmlFile, key)
	BoatyardStateBuilding:superClass().load(self, xmlFile, key)
	self.meshId = xmlFile:getValue(key .. "#meshId")
	self.totalAmount = 0
	self.inputs = {}
	self.hasInputMaterials = true
	xmlFile:iterate(key .. ".input", function(_, inputKey)
		local fillTypeStr = xmlFile:getValue(inputKey .. "#fillType")
		local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
		if fillType == nil then
			Logging.xmlWarning(xmlFile, "Unknown fillType '%s' in '%s'", fillTypeStr, inputKey)
		elseif not self.boatyard.spec_boatyard.storage:getIsFillTypeSupported(fillType.index) then
			Logging.xmlWarning(xmlFile, "Filltype '%s' in '%s' not supported by storage", fillType.name, inputKey)
		else
			local amount = xmlFile:getValue(inputKey .. "#amount")
			local usagePerSecond = xmlFile:getValue(inputKey .. "#usagePerHour") / 60 / 60
			self.totalAmount = self.totalAmount + amount
			table.insert(self.inputs, { fillType = fillType, amount = amount, remainingAmount = amount, lastSyncedAmount = amount, usagePerSecond = usagePerSecond, infoTableEntry = { title = fillType.title, text = g_i18n:formatVolume(amount) } })
		end
	end)
	self.infoBoxRequiredGoods = { title = g_i18n:getText("infohud_requiredMaterialsNextStep"), accentuate = true }
end
function BoatyardStateBuilding:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setSortedTable(key .. ".state.input", self.inputs, function(inputKey, input)
		xmlFile:setValue(inputKey .. "#fillType", input.fillType.name)
		xmlFile:setValue(inputKey .. "#remainingAmount", input.remainingAmount)
	end)
end
function BoatyardStateBuilding:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".state.input", function(index, inputKey)
		local fillType = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(inputKey .. "#fillType"))
		local remainingAmount = xmlFile:getValue(inputKey .. "#remainingAmount")
		for _, input in ipairs(self.inputs) do
			if input.fillType == fillType then
				self:updateRemainingAmount(input, remainingAmount)
			end
		end
	end)
end
function BoatyardStateBuilding:isDone()
	for _, input in ipairs(self.inputs) do
		if 0 < input.remainingAmount then
			return false
		end
	end
	return true
end
function BoatyardStateBuilding:onReadStream(streamId, connection)
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, streamReadFloat32(streamId))
	end
end
function BoatyardStateBuilding:onWriteStream(streamId, connection)
	for i, input in ipairs(self.inputs) do
		streamWriteFloat32(streamId, input.remainingAmount)
	end
end
function BoatyardStateBuilding:onReadUpdateStream(streamId, timestamp, connection)
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, streamReadFloat32(streamId))
	end
end
function BoatyardStateBuilding:onWriteUpdateStream(streamId, connection, dirtyMask)
	for i, input in ipairs(self.inputs) do
		streamWriteFloat32(streamId, input.remainingAmount)
	end
end
function BoatyardStateBuilding:raiseActive()
	return self.hasInputMaterials
end
function BoatyardStateBuilding:getPlaySound()
	return self.hasInputMaterials
end
function BoatyardStateBuilding:update(dt)
	local usedAmount = 0
	self.hasInputMaterials = false
	for i, input in ipairs(self.inputs) do
		usedAmount = usedAmount + (input.amount - input.remainingAmount)
		if 0 < input.remainingAmount then
			local amount = input.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale)
			local delta = self.boatyard:removeFillLevel(input.fillType.index, amount)
			if 0 < delta then
				self.hasInputMaterials = true
				self:updateRemainingAmount(input, input.remainingAmount - delta)
				if input.amount / 100 < math.abs(input.remainingAmount - input.lastSyncedAmount) or input.remainingAmount <= 0.01 or input.remainingAmount == input.amount then
					self.boatyard:raiseDirtyFlags(self.dirtyFlag)
					input.lastSyncedAmount = input.remainingAmount
				end
			end
		end
	end
	self.boatyard:setMeshProgress(self.meshId, usedAmount / self.totalAmount)
	BoatyardStateBuilding:superClass().update(self, dt)
end
function BoatyardStateBuilding:deactivate()
	self.boatyard:setMeshProgress(self.meshId, 1)
	for i, input in ipairs(self.inputs) do
		self:updateRemainingAmount(input, input.amount)
	end
	BoatyardStateBuilding:superClass().deactivate(self)
end
function BoatyardStateBuilding:updateInfo(infoTable)
	table.insert(infoTable, self.infoBoxRequiredGoods)
	for i, input in ipairs(self.inputs) do
		if 0.01 < input.remainingAmount then
			table.insert(infoTable, input.infoTableEntry)
		end
	end
end
function BoatyardStateBuilding:updateRemainingAmount(input, amount)
	if amount < 0.01 then
		amount = 0
	end
	input.remainingAmount = math.max(0, amount)
	input.infoTableEntry.text = g_i18n:formatVolume(input.remainingAmount)
end
