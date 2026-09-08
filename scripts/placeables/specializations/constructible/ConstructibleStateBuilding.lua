-- Local values: ConstructibleStateBuilding_mt
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

-- Upvalues: ConstructibleStateBuilding_mt
-- Local values: self
function ConstructibleStateBuilding.new(constructible, dirtyFlag, customMt)
	-- upvalues: (copy) ConstructibleStateBuilding_mt
	return ConstructibleState.new(constructible, dirtyFlag, customMt or ConstructibleStateBuilding_mt)
end

-- Local values: _, inputKey, fillTypeStr, fillType, amount, usagePerSecond, _, nodeKey, node, indexMin, indexMax, direction, mesh
function ConstructibleStateBuilding:load(xmlFile, key)
	ConstructibleStateBuilding:superClass().load(self, xmlFile, key)
	self.totalAmount = 0
	self.inputs = {}
	self.hasInputMaterials = true
	for _, v12_ in xmlFile:iterator(key .. ".input") do
		local v13_ = xmlFile:getValue(v12_ .. "#fillType")
		local v14_ = g_fillTypeManager:getFillTypeByName(v13_)
		if v14_ == nil then
			Logging.xmlWarning(xmlFile, "Unknown fillType \'%s\' in \'%s\'", v13_, v12_)
			break
		end
		if not self.constructible:getConstructibleSupportsFillType(v14_.index) then
			Logging.xmlWarning(xmlFile, "Filltype \'%s\' in \'%s\' not supported by storage", v14_.name, v12_)
			break
		end
		local v15_ = xmlFile:getValue(v12_ .. "#amount")
		local v16_ = xmlFile:getValue(v12_ .. "#usagePerHour") / 60 / 60
		self.totalAmount = self.totalAmount + v15_
		local v17_ = self.inputs
		local v18_ = {
			["fillType"] = v14_,
			["amount"] = v15_,
			["remainingAmount"] = v15_,
			["lastSyncedAmount"] = v15_,
			["usagePerSecond"] = v16_,
			["infoTableEntry"] = {
				["title"] = v14_.title,
				["text"] = g_i18n:formatVolume(v15_)
			}
		}
		table.insert(v17_, v18_)
	end
	self.meshes = {}
	for _, v19_ in xmlFile:iterator(key .. ".mesh") do
		local v20_ = xmlFile:getValue(v19_ .. "#node", nil, self.constructible.components, self.constructible.i3dMappings)
		if v20_ == nil then
			break
		end
		if not getHasClassId(v20_, ClassIds.SHAPE) then
			Logging.xmlError(xmlFile, "node \'%s\' at \'%s\' is not a shape", getName(v20_), v19_)
			break
		end
		if not getHasShaderParameter(v20_, "hideByIndex") then
			Logging.xmlError(xmlFile, "mesh \'%s\' at \'%s\' does not have required shader parameter \'hideByIndex\'", getName(v20_), v19_)
			break
		end
		local v21_ = xmlFile:getValue(v19_ .. "#indexMin", 0)
		local v22_ = xmlFile:getValue(v19_ .. "#indexMax")
		if v22_ == nil then
			v22_ = getUserAttribute(v20_, "hideByIndexMaxIndex")
			if v21_ == nil then
				Logging.xmlError(xmlFile, "Cannot retrieve indexMax from shape material and value is also not set in xml at \'%s\'", getName(v20_), v19_)
				break
			end
		end
		local v23_ = xmlFile:getValue(v19_ .. "#direction", 1)
		local v24_ = {
			["node"] = v20_,
			["childIndex"] = getChildIndex(v20_),
			["index"] = #self.meshes + 1,
			["indexMin"] = v21_,
			["indexMax"] = v22_,
			["direction"] = v23_,
			["lastValue"] = -1,
			["numBits"] = MathUtil.getNumRequiredBits(v22_)
		}
		self:setMeshProgress(v24_, 0)
		local v25_ = self.meshes
		table.insert(v25_, v24_)
	end
	self.infoBoxRequiredGoods = {
		["title"] = g_i18n:getText("infohud_requiredMaterialsNextStep"),
		["accentuate"] = true
	}
end

-- Local values: k, input, inputKey
function ConstructibleStateBuilding:saveToXMLFile(xmlFile, key, usedModNames)
	for v29_, v30_ in ipairs(self.inputs) do
		local v31_ = string.format("%s.state.input(%d)", key, v29_ - 1)
		xmlFile:setValue(v31_ .. "#fillType", v30_.fillType.name)
		xmlFile:setValue(v31_ .. "#remainingAmount", v30_.remainingAmount)
	end
end

-- Local values: _, inputKey, fillType, remainingAmount, _, input
function ConstructibleStateBuilding:loadFromXMLFile(xmlFile, key)
	for _, v35_ in xmlFile:iterator(key .. ".state.input") do
		local v36_ = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(v35_ .. "#fillType"))
		local v37_ = xmlFile:getValue(v35_ .. "#remainingAmount")
		for _, v38_ in ipairs(self.inputs) do
			if v38_.fillType == v36_ then
				self:updateRemainingAmount(v38_, v37_)
			end
		end
	end
end

-- Local values: _, input
function ConstructibleStateBuilding:isDone()
	for _, v40_ in ipairs(self.inputs) do
		if v40_.remainingAmount > 0 then
			return false
		end
	end
	return true
end

-- Local values: i, input, meshIndex, mesh, hideByIndexValue, progress
function ConstructibleStateBuilding:onReadStream(streamId, connection)
	for _, v43_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v43_, streamReadFloat32(streamId))
	end
	for _, v44_ in ipairs(self.meshes) do
		local v45_ = streamReadUIntN(streamId, v44_.numBits)
		local v46_ = MathUtil.inverseLerp(v44_.indexMax, v44_.indexMin, v45_)
		if v44_.direction == -1 then
			v46_ = 1 - v46_
		end
		self:setMeshProgress(v44_, v46_)
	end
end

-- Local values: i, input, meshIndex, mesh
function ConstructibleStateBuilding:onWriteStream(streamId, connection)
	for _, v49_ in ipairs(self.inputs) do
		streamWriteFloat32(streamId, v49_.remainingAmount)
	end
	for _, v50_ in ipairs(self.meshes) do
		streamWriteUIntN(streamId, v50_.lastValue, v50_.numBits)
	end
end

-- Local values: i, input, meshIndex, mesh, hideByIndexValue, progress
function ConstructibleStateBuilding:onReadUpdateStream(streamId, timestamp, connection)
	for _, v53_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v53_, streamReadFloat32(streamId))
	end
	for _, v54_ in ipairs(self.meshes) do
		local v55_ = streamReadUIntN(streamId, v54_.numBits)
		local v56_ = MathUtil.inverseLerp(v54_.indexMax, v54_.indexMin, v55_)
		if v54_.direction == -1 then
			v56_ = 1 - v56_
		end
		self:setMeshProgress(v54_, v56_)
	end
end

-- Local values: i, input, _, mesh
function ConstructibleStateBuilding:onWriteUpdateStream(streamId, connection, dirtyMask)
	for _, v59_ in ipairs(self.inputs) do
		streamWriteFloat32(streamId, v59_.remainingAmount)
	end
	for _, v60_ in ipairs(self.meshes) do
		streamWriteUIntN(streamId, v60_.lastValue, v60_.numBits)
	end
end

function ConstructibleStateBuilding:raiseActive()
	return self.hasInputMaterials
end

function ConstructibleStateBuilding:getPlaySound()
	return self.hasInputMaterials
end

-- Local values: usedAmount, i, input, amount, delta, _, mesh
function ConstructibleStateBuilding:update(dt)
	self.hasInputMaterials = false
	local v65_ = 0
	for _, v66_ in ipairs(self.inputs) do
		v65_ = v65_ + (v66_.amount - v66_.remainingAmount)
		if v66_.remainingAmount > 0 then
			local v67_ = v66_.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale)
			local v68_ = self.constructible:removeConstructibleFillLevel(v66_.fillType.index, v67_)
			if v68_ > 0 then
				self.hasInputMaterials = true
				self:updateRemainingAmount(v66_, v66_.remainingAmount - v68_)
				local v69_ = v66_.remainingAmount - v66_.lastSyncedAmount
				if math.abs(v69_) > v66_.amount / 100 or (v66_.remainingAmount <= 0.01 or v66_.remainingAmount == v66_.amount) then
					self.constructible:raiseDirtyFlags(self.dirtyFlag)
					v66_.lastSyncedAmount = v66_.remainingAmount
				end
			end
		end
	end
	for _, v70_ in ipairs(self.meshes) do
		self:setMeshProgress(v70_, v65_ / self.totalAmount)
	end
	ConstructibleStateBuilding:superClass().update(self, dt)
end

-- Local values: i, input, _, mesh
function ConstructibleStateBuilding:deactivate()
	for _, v72_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v72_, v72_.amount)
	end
	for _, v73_ in ipairs(self.meshes) do
		self:setMeshProgress(v73_, 1)
	end
	ConstructibleStateBuilding:superClass().deactivate(self)
end

-- Local values: i, input, _, mesh
function ConstructibleStateBuilding:reset()
	for _, v75_ in ipairs(self.inputs) do
		self:updateRemainingAmount(v75_, v75_.amount)
	end
	for _, v76_ in ipairs(self.meshes) do
		self:setMeshProgress(v76_, 0)
	end
	ConstructibleStateBuilding:superClass().reset(self)
end

-- Local values: i, input
function ConstructibleStateBuilding:updateInfo(infoTable)
	local v79_ = self.infoBoxRequiredGoods
	table.insert(infoTable, v79_)
	for _, v80_ in ipairs(self.inputs) do
		if v80_.remainingAmount > 0.01 then
			local v81_ = v80_.infoTableEntry
			table.insert(infoTable, v81_)
		end
	end
end

function ConstructibleStateBuilding:updateRemainingAmount(input, amount)
	local v84_ = amount < 0.01 and 0 or amount
	input.remainingAmount = math.max(0, v84_)
	local v85_ = input.infoTableEntry
	local v86_ = g_i18n
	local v87_ = input.remainingAmount
	v85_.text = v86_:formatVolume((math.ceil(v87_)))
end

-- Local values: hideByIndexValue, node
function ConstructibleStateBuilding:setMeshProgress(mesh, percentage)
	if mesh ~= nil then
		if mesh.direction == -1 then
			percentage = 1 - percentage
		end
		local v91_ = MathUtil.lerp(mesh.indexMax, mesh.indexMin, percentage)
		local v92_ = math.round(v91_)
		if v92_ ~= mesh.lastValue then
			local v93_ = mesh.node
			setVisibility(v93_, percentage ~= 0)
			mesh.lastValue = v92_
			setShaderParameter(v93_, "hideByIndex", v92_, 0, 0, 0, false)
			if self.constructible.isServer then
				self.constructible:raiseDirtyFlags(self.dirtyFlag)
			end
		end
	end
end
