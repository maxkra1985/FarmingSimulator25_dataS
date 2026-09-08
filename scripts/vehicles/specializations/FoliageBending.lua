FoliageBending = {}
FoliageBending.BENDING_NODE_XML_KEY = "vehicle.foliageBending.bendingNode(?)"

function FoliageBending.prerequisitesPresent(specializations)
	return true
end
function FoliageBending.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("FoliageBending")
	local v2_ = FoliageBending.BENDING_NODE_XML_KEY
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#node", "Bending node")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#minX", "Min. width")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#maxX", "Max. width")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#minZ", "Min. length")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#maxZ", "Max. length")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#yOffset", "Y translation offset")
	v1_:setXMLSpecializationType()
end
function FoliageBending.postInitSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("FoliageBending")
	for _, v4_ in pairs(g_vehicleConfigurationManager:getConfigurations()) do
		local v5_ = v4_.configurationKey .. "(?)"
		v3_:setXMLSharedRegistration("foliageBendingModifier", v5_)
		v3_:register(XMLValueType.INT, v5_ .. ".foliageBendingModifier(?)#index", "Bending node index")
		v3_:register(XMLValueType.VECTOR_N, v5_ .. ".foliageBendingModifier(?)#indices", "Bending node indices")
		v3_:register(XMLValueType.FLOAT, v5_ .. ".foliageBendingModifier(?)#minX", "Min. width")
		v3_:register(XMLValueType.FLOAT, v5_ .. ".foliageBendingModifier(?)#maxX", "Max. width")
		v3_:register(XMLValueType.FLOAT, v5_ .. ".foliageBendingModifier(?)#minZ", "Min. length")
		v3_:register(XMLValueType.FLOAT, v5_ .. ".foliageBendingModifier(?)#maxZ", "Max. length")
		v3_:register(XMLValueType.FLOAT, v5_ .. ".foliageBendingModifier(?)#yOffset", "Y translation offset")
		v3_:register(XMLValueType.BOOL, v5_ .. ".foliageBendingModifier(?)#isActive", "Bending node is active", true)
		v3_:register(XMLValueType.BOOL, v5_ .. ".foliageBendingModifier(?)#overwrite", "Overwrite the bending node values and do not use the max values", true)
		v3_:resetXMLSharedRegistration("foliageBendingModifier", v5_)
	end
	v3_:setXMLSpecializationType()
end

function FoliageBending.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBendingNodeFromXML", FoliageBending.loadBendingNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBendingNodeModifierFromXML", FoliageBending.loadBendingNodeModifierFromXML)
	SpecializationUtil.registerFunction(vehicleType, "activateBendingNodes", FoliageBending.activateBendingNodes)
	SpecializationUtil.registerFunction(vehicleType, "deactivateBendingNodes", FoliageBending.deactivateBendingNodes)
	SpecializationUtil.registerFunction(vehicleType, "getFoliageBendingNodeByIndex", FoliageBending.getFoliageBendingNodeByIndex)
end

function FoliageBending.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", FoliageBending)
end

-- Local values: spec, i, key, bendingNode, name, id, configDesc, key, _, modifierKey, _, modifier, _, modifierBendingNodeIndex, bendingNode
function FoliageBending:onPostLoad(savegame)
	local v9_ = self.spec_foliageBending
	v9_.bendingNodes = {}
	local v10_ = 0
	while true do
		local v11_ = string.format("vehicle.foliageBending.bendingNode(%d)", v10_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = {}
		if self:loadBendingNodeFromXML(self.xmlFile, v11_, v12_) then
			local v13_ = v9_.bendingNodes
			table.insert(v13_, v12_)
			v12_.index = #v9_.bendingNodes
		end
		v10_ = v10_ + 1
	end
	for v14_, v15_ in pairs(self.configurations) do
		local v16_ = g_vehicleConfigurationManager:getConfigurationDescByName(v14_)
		local v17_ = string.format("%s(%d).foliageBendingModifier", v16_.configurationKey, v15_ - 1)
		for _, v18_ in self.xmlFile:iterator(v17_) do
			self:loadBendingNodeModifierFromXML(self.xmlFile, v18_)
		end
	end
	if v9_.bendingModifiers ~= nil then
		for _, v19_ in ipairs(v9_.bendingModifiers) do
			for _, v20_ in ipairs(v19_.indices) do
				local v21_ = v9_.bendingNodes[v20_]
				if v21_ == nil then
					Logging.xmlWarning(self.xmlFile, "Undefined bendingNode index \'%d\' for bending modifier \'%s\'!", v20_, v19_.key)
				else
					if v19_.overwrite then
						v21_.minX = v19_.minX or v21_.minX
						v21_.maxX = v19_.maxX or v21_.maxX
						v21_.minZ = v19_.minZ or v21_.minZ
						v21_.maxZ = v19_.maxZ or v21_.maxZ
						v21_.yOffset = v19_.yOffset or v21_.yOffset
					else
						local v22_ = v21_.minX
						local v23_ = v19_.minX or v21_.minX
						v21_.minX = math.min(v22_, v23_)
						local v24_ = v21_.maxX
						local v25_ = v19_.maxX or v21_.maxX
						v21_.maxX = math.max(v24_, v25_)
						local v26_ = v21_.minZ
						local v27_ = v19_.minZ or v21_.minZ
						v21_.minZ = math.min(v26_, v27_)
						local v28_ = v21_.maxZ
						local v29_ = v19_.maxZ or v21_.maxZ
						v21_.maxZ = math.max(v28_, v29_)
						local v30_ = v21_.yOffset
						local v31_ = v19_.yOffset or v21_.yOffset
						v21_.yOffset = math.max(v30_, v31_)
					end
					if not v19_.isActive then
						v21_.isActive = false
					end
				end
			end
		end
		v9_.bendingModifiers = nil
	end
end

function FoliageBending:onDelete()
	self:deactivateBendingNodes()
end

-- Local values: node
function FoliageBending:loadBendingNodeFromXML(xmlFile, key, bendingNode)
	local v37_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v37_ == nil then
		v37_ = self.rootNode
	end
	bendingNode.node = v37_
	bendingNode.key = key
	bendingNode.minX = xmlFile:getValue(key .. "#minX", -1)
	bendingNode.maxX = xmlFile:getValue(key .. "#maxX", 1)
	bendingNode.minZ = xmlFile:getValue(key .. "#minZ", -1)
	bendingNode.maxZ = xmlFile:getValue(key .. "#maxZ", 1)
	bendingNode.yOffset = xmlFile:getValue(key .. "#yOffset", 0)
	bendingNode.isActive = true
	return true
end

-- Local values: modifier, spec
function FoliageBending:loadBendingNodeModifierFromXML(xmlFile, key)
	local v41_ = {
		["index"] = xmlFile:getValue(key .. "#index"),
		["indices"] = xmlFile:getValue(key .. "#indices", nil, true)
	}
	if v41_.index == nil and v41_.indices == nil then
		Logging.xmlWarning(self.xmlFile, "Missing bending node index for bending modifier \'%s\'", key)
	else
		v41_.indices = v41_.indices or {}
		if v41_.index ~= nil then
			local v42_ = v41_.indices
			local v43_ = v41_.index
			table.insert(v42_, v43_)
		end
		v41_.minX = xmlFile:getValue(key .. "#minX")
		v41_.maxX = xmlFile:getValue(key .. "#maxX")
		v41_.minZ = xmlFile:getValue(key .. "#minZ")
		v41_.maxZ = xmlFile:getValue(key .. "#maxZ")
		v41_.yOffset = xmlFile:getValue(key .. "#yOffset")
		v41_.isActive = xmlFile:getValue(key .. "#isActive", true)
		v41_.overwrite = xmlFile:getValue(key .. "#overwrite", true)
		local v44_ = self.spec_foliageBending
		if v44_.bendingModifiers == nil then
			v44_.bendingModifiers = {}
		end
		local v45_ = v44_.bendingModifiers
		table.insert(v45_, v41_)
	end
end

-- Local values: spec, _, bendingNode
function FoliageBending:activateBendingNodes()
	local v47_ = self.spec_foliageBending
	for _, v48_ in ipairs(v47_.bendingNodes) do
		if v48_.isActive and (v48_.id == nil and g_currentMission.foliageBendingSystem) then
			v48_.id = g_currentMission.foliageBendingSystem:createRectangle(v48_.minX, v48_.maxX, v48_.minZ, v48_.maxZ, v48_.yOffset, v48_.node)
		end
	end
end

-- Local values: spec, _, bendingNode
function FoliageBending:deactivateBendingNodes()
	local v50_ = self.spec_foliageBending
	if v50_.bendingNodes ~= nil then
		for _, v51_ in ipairs(v50_.bendingNodes) do
			if v51_.id ~= nil then
				g_currentMission.foliageBendingSystem:destroyObject(v51_.id)
				v51_.id = nil
			end
		end
	end
end

function FoliageBending:getFoliageBendingNodeByIndex(index)
	return self.spec_foliageBending.bendingNodes[index]
end

function FoliageBending:onActivate()
	self:activateBendingNodes()
end

function FoliageBending:onDeactivate()
	self:deactivateBendingNodes()
end
