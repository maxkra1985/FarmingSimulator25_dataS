-- Local values: BoatyardStateBuilding_mt
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

-- Upvalues: BoatyardStateBuilding_mt
-- Local values: self
function BoatyardStateBuilding.new(boatyard, customMt)
	-- upvalues: (copy) BoatyardStateBuilding_mt
	return BoatyardState.new(boatyard, customMt or BoatyardStateBuilding_mt)
end

function BoatyardStateBuilding:load(xmlFile, key)
	BoatyardStateBuilding:superClass().load(self, xmlFile, key)
	self.meshId = xmlFile:getValue(key .. "#meshId")
	self.totalAmount = 0
	self.inputs = {}
	self.hasInputMaterials = true
	xmlFile:iterate(key .. ".input", function(_, p11_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v12_ = xmlFile:getValue(p11_ .. "#fillType")
		local v13_ = g_fillTypeManager:getFillTypeByName(v12_)
		if v13_ == nil then
			Logging.xmlWarning(xmlFile, "Unknown fillType \'%s\' in \'%s\'", v12_, p11_)
			return
		elseif self.boatyard.spec_boatyard.storage:getIsFillTypeSupported(v13_.index) then
			local v14_ = xmlFile:getValue(p11_ .. "#amount")
			local v15_ = xmlFile:getValue(p11_ .. "#usagePerHour") / 60 / 60
			self.totalAmount = self.totalAmount + v14_
			local v16_ = self.inputs
			local v17_ = {
				["fillType"] = v13_,
				["amount"] = v14_,
				["remainingAmount"] = v14_,
				["lastSyncedAmount"] = v14_,
				["usagePerSecond"] = v15_,
				["infoTableEntry"] = {
					["title"] = v13_.title,
					["text"] = g_i18n:formatVolume(v14_)
				}
			}
			table.insert(v16_, v17_)
		else
			Logging.xmlWarning(xmlFile, "Filltype \'%s\' in \'%s\' not supported by storage", v13_.name, p11_)
		end
	end)
	self.infoBoxRequiredGoods = {
		["title"] = g_i18n:getText("infohud_requiredMaterialsNextStep"),
		["accentuate"] = true
	}
end

function BoatyardStateBuilding:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setSortedTable(key .. ".state.input", self.inputs, function(p21_, p22_)
		-- upvalues: (copy) xmlFile
		xmlFile:setValue(p21_ .. "#fillType", p22_.fillType.name)
		xmlFile:setValue(p21_ .. "#remainingAmount", p22_.remainingAmount)
	end)
end

function BoatyardStateBuilding:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".state.input", function(_, p26_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v27_ = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(p26_ .. "#fillType"))
		local v28_ = xmlFile:getValue(p26_ .. "#remainingAmount")
		for _, v29_ in ipairs(self.inputs) do
			if v29_.fillType == v27_ then
				self:updateRemainingAmount(v29_, v28_)
			end
		end
	end)
end

-- Local values: _, input
function BoatyardStateBuilding:isDone()
	for _, v31_ in ipairs(self.inputs) do
		if v31_.remainingAmount > 0 then
			return false
		end
	end
	return true
end

-- Local values: i, input
function BoatyardStateBuilding:onReadStream(streamId, connection)
	for _, v34_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v34_, streamReadFloat32(streamId))
	end
end

-- Local values: i, input
function BoatyardStateBuilding:onWriteStream(streamId, connection)
	for _, v37_ in ipairs(self.inputs) do
		streamWriteFloat32(streamId, v37_.remainingAmount)
	end
end

-- Local values: i, input
function BoatyardStateBuilding:onReadUpdateStream(streamId, timestamp, connection)
	for _, v40_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v40_, streamReadFloat32(streamId))
	end
end

-- Local values: i, input
function BoatyardStateBuilding:onWriteUpdateStream(streamId, connection, dirtyMask)
	for _, v43_ in ipairs(self.inputs) do
		streamWriteFloat32(streamId, v43_.remainingAmount)
	end
end

function BoatyardStateBuilding:raiseActive()
	return self.hasInputMaterials
end

function BoatyardStateBuilding:getPlaySound()
	return self.hasInputMaterials
end

-- Local values: usedAmount, i, input, amount, delta
function BoatyardStateBuilding:update(dt)
	self.hasInputMaterials = false
	local v48_ = 0
	for _, v49_ in ipairs(self.inputs) do
		v48_ = v48_ + (v49_.amount - v49_.remainingAmount)
		if v49_.remainingAmount > 0 then
			local v50_ = v49_.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale)
			local v51_ = self.boatyard:removeFillLevel(v49_.fillType.index, v50_)
			if v51_ > 0 then
				self.hasInputMaterials = true
				self:updateRemainingAmount(v49_, v49_.remainingAmount - v51_)
				local v52_ = v49_.remainingAmount - v49_.lastSyncedAmount
				if math.abs(v52_) > v49_.amount / 100 or (v49_.remainingAmount <= 0.01 or v49_.remainingAmount == v49_.amount) then
					self.boatyard:raiseDirtyFlags(self.dirtyFlag)
					v49_.lastSyncedAmount = v49_.remainingAmount
				end
			end
		end
	end
	self.boatyard:setMeshProgress(self.meshId, v48_ / self.totalAmount)
	BoatyardStateBuilding:superClass().update(self, dt)
end

-- Local values: i, input
function BoatyardStateBuilding:deactivate()
	self.boatyard:setMeshProgress(self.meshId, 1)
	for _, v54_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v54_, v54_.amount)
	end
	BoatyardStateBuilding:superClass().deactivate(self)
end

-- Local values: i, input
function BoatyardStateBuilding:updateInfo(infoTable)
	local v57_ = self.infoBoxRequiredGoods
	table.insert(infoTable, v57_)
	for _, v58_ in ipairs(self.inputs) do
		if v58_.remainingAmount > 0.01 then
			local v59_ = v58_.infoTableEntry
			table.insert(infoTable, v59_)
		end
	end
end

function BoatyardStateBuilding:updateRemainingAmount(input, amount)
	local v62_ = amount < 0.01 and 0 or amount
	input.remainingAmount = math.max(0, v62_)
	input.infoTableEntry.text = g_i18n:formatVolume(input.remainingAmount)
end
