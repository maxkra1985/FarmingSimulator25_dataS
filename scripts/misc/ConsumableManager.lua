ConsumableManager = {}
ConsumableManager.DEFAULT_FILENAME = "data/objects/consumables/consumables.xml"
ConsumableManager.NUM_VARIATION_BITS = 9
ConsumableManager.MAX_NUM_VARIATIONS = 2 ^ ConsumableManager.NUM_VARIATION_BITS - 1
ConsumableManager.xmlSchemaConsumable = nil
ConsumableManager.xmlSchemaConsumables = nil
local ConsumableManager_mt = Class(ConsumableManager, AbstractManager)
function ConsumableManager.new(customMt)
	local self = AbstractManager.new(customMt or ConsumableManager_mt)
	self.types = {}
	self.typesByName = {}
	self.variations = {}
	self.variationsByName = {}
	self.sharedLoadRequestIds = {}
	self.modConsumablesToLoad = {}
	ConsumableManager.xmlSchemaConsumable = XMLSchema.new("consumable")
	ConsumableManager.registerConsumableXMLPaths(ConsumableManager.xmlSchemaConsumable)
	ConsumableManager.xmlSchemaConsumables = XMLSchema.new("consumables")
	ConsumableManager.registerConsumablesXMLPaths(ConsumableManager.xmlSchemaConsumables)
	return self
end
function ConsumableManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	ConsumableManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	local consumablesXMLFile = XMLFile.load("consumables", ConsumableManager.DEFAULT_FILENAME, ConsumableManager.xmlSchemaConsumables)
	if consumablesXMLFile ~= nil then
		for _, key in consumablesXMLFile:iterator("consumables.types.type") do
			local type = {}
			type.name = consumablesXMLFile:getValue(key .. "#name")
			type.title = consumablesXMLFile:getValue(key .. "#title")
			if type.name ~= nil then
				if type.title ~= nil then
					type.name = string.upper(type.name)
					table.insert(self.types, type)
					self.typesByName[type.name] = type
				else
					Logging.xmlWarning(consumablesXMLFile, "Failed to load consumable type from xml. (%s)", key)
				end
			end
		end
		for _, key in consumablesXMLFile:iterator("consumables.consumable") do
			local filename = consumablesXMLFile:getValue(key .. "#filename")
			if filename == nil then
				continue
			end
			filename = Utils.getFilename(filename, baseDirectory)
			self:loadConsumableVariationsFromXML(filename, nil, baseDirectory)
		end
		consumablesXMLFile:delete()
	end
	for i = #self.modConsumablesToLoad, 1, -1 do
		local modConsumablesToLoad = self.modConsumablesToLoad[i]
		self:loadConsumableVariationsFromXML(modConsumablesToLoad.xmlFilename, modConsumablesToLoad.customEnvironment, modConsumablesToLoad.baseDirectory)
		self.modConsumablesToLoad[i] = nil
	end
end
function ConsumableManager:unloadMapData()
	for _, consumableVariation in ipairs(self.variations) do
		if consumableVariation.node ~= nil then
			delete(consumableVariation.node)
		end
		if consumableVariation.consumingNode ~= nil then
			delete(consumableVariation.consumingNode)
		end
		if consumableVariation.tensionBeltNode == nil then
			continue
		end
		delete(consumableVariation.tensionBeltNode)
	end
	self.variations = {}
	for i = 1, #self.sharedLoadRequestIds do
		local sharedLoadRequestId = self.sharedLoadRequestIds[i]
		g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	end
	self.sharedLoadRequestIds = {}
	ConsumableManager:superClass().unloadMapData(self)
end
function ConsumableManager:addModConsumable(xmlFilename, customEnvironment, baseDirectory)
	table.insert(self.modConsumablesToLoad, { xmlFilename = xmlFilename, customEnvironment = customEnvironment, baseDirectory = baseDirectory })
end
function ConsumableManager:loadConsumableVariationsFromXML(xmlFilename, customEnvironment, baseDirectory)
	Logging.devInfo("Loading Consumable from '%s'", xmlFilename)
	local xmlFile = XMLFile.load("Consumable", xmlFilename, ConsumableManager.xmlSchemaConsumable)
	if xmlFile ~= nil then
		for _, key in xmlFile:iterator("consumable.consumableVariation") do
			if ConsumableManager.MAX_NUM_VARIATIONS <= #self.variations then
				Logging.xmlWarning(xmlFile, "Max. num consumables variations reached, skip loading of '%s'", key)
			else
				local consumableVariation = {}
				consumableVariation.type = xmlFile:getValue(key .. "#type")
				if consumableVariation.type == nil then
					Logging.xmlWarning(xmlFile, "Missing type in '%s'", key)
				else
					consumableVariation.name = xmlFile:getValue(key .. "#name")
					if consumableVariation.name == nil then
						Logging.xmlWarning(xmlFile, "Missing name in '%s'", key)
					else
						if customEnvironment ~= nil then
							consumableVariation.name = customEnvironment .. "." .. consumableVariation.name
						end
						consumableVariation.price = xmlFile:getValue(key .. "#price", 0)
						consumableVariation.title = xmlFile:getValue(key .. "#title", nil, customEnvironment)
						if consumableVariation.title == nil then
							Logging.xmlWarning(xmlFile, "Missing title in '%s'", key)
						else
							consumableVariation.unitText = xmlFile:getValue(key .. "#unitText", nil, customEnvironment, false)
							consumableVariation.capacity = xmlFile:getValue(key .. "#capacity", 1)
							consumableVariation.filename = xmlFile:getValue(key .. ".object#filename")
							if consumableVariation.filename ~= nil then
								consumableVariation.filename = Utils.getFilename(consumableVariation.filename, baseDirectory)
								if consumableVariation.filename ~= nil then
									local nodePath = xmlFile:getValue(key .. ".object#node")
									if nodePath ~= nil then
										local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(consumableVariation.filename, false, false, self.consumableI3DFileLoaded, self, { consumableVariation, nodePath, "node" })
										table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
									end
								end
							end
							consumableVariation.consumingFilename = xmlFile:getValue(key .. ".consumingObject#filename")
							if consumableVariation.consumingFilename ~= nil then
								consumableVariation.consumingFilename = Utils.getFilename(consumableVariation.consumingFilename, baseDirectory)
								if consumableVariation.consumingFilename ~= nil then
									local consumingNodePath = xmlFile:getValue(key .. ".consumingObject#node")
									if consumingNodePath ~= nil then
										local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(consumableVariation.consumingFilename, false, false, self.consumableI3DFileLoaded, self, { consumableVariation, consumingNodePath, "consumingNode" })
										table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
									end
								end
							end
							consumableVariation.tensionBeltFilename = xmlFile:getValue(key .. ".tensionBeltObject#filename")
							if consumableVariation.tensionBeltFilename ~= nil then
								consumableVariation.tensionBeltFilename = Utils.getFilename(consumableVariation.tensionBeltFilename, baseDirectory)
								if consumableVariation.tensionBeltFilename ~= nil then
									local tensionBeltNodePath = xmlFile:getValue(key .. ".tensionBeltObject#node")
									if tensionBeltNodePath ~= nil then
										local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(consumableVariation.tensionBeltFilename, false, false, self.consumableI3DFileLoaded, self, { consumableVariation, tensionBeltNodePath, "tensionBeltNode" })
										table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
									end
								end
							end
							consumableVariation.metaData = {}
							for _, valueKey in xmlFile:iterator(key .. ".metaData.value") do
								local name = xmlFile:getValue(valueKey .. "#name")
								if name ~= nil then
									local valueStr = xmlFile:getValue(valueKey .. "#value")
									if valueStr == nil then
										continue
									end
									local value = nil
									if valueStr:contains(" ") then
										value = string.getVector(valueStr)
									else
										value = tonumber(valueStr) or valueStr
									end
									if value ~= nil then
										consumableVariation.metaData[name] = value
									else
										Logging.xmlWarning(xmlFile, "Invalid value in '%s'", valueKey)
									end
								else
									Logging.xmlWarning(xmlFile, "Missing name in '%s'", valueKey)
								end
							end
							consumableVariation.shaderParameters = {}
							for _, paramKey in xmlFile:iterator(key .. ".shaderParameter") do
								local name = xmlFile:getValue(paramKey .. "#name")
								if name ~= nil then
									local shaderParameter = {}
									shaderParameter.name = name
									shaderParameter.materialSlotName = xmlFile:getValue(paramKey .. "#materialSlotName")
									shaderParameter.value = xmlFile:getValue(paramKey .. "#value", nil, true)
									if shaderParameter.value ~= nil then
										table.insert(consumableVariation.shaderParameters, shaderParameter)
									else
										Logging.xmlWarning(xmlFile, "Invalid value in '%s'", paramKey)
									end
								else
									Logging.xmlWarning(xmlFile, "Missing name in '%s'", paramKey)
								end
							end
							if self.variationsByName[consumableVariation.name] == nil then
								table.insert(self.variations, consumableVariation)
								consumableVariation.index = #self.variations
								self.variationsByName[consumableVariation.name] = consumableVariation
							else
								Logging.xmlWarning(xmlFile, "Consumable with name '%s' already registered", consumableVariation.name)
							end
						end
					end
				end
			end
		end
		xmlFile:delete()
	end
end
function ConsumableManager:consumableI3DFileLoaded(i3dNode, failedReason, arguments)
	local consumableVariation = arguments[1]
	local nodePath = arguments[2]
	local name = arguments[3]
	if i3dNode ~= nil and i3dNode ~= 0 then
		local node = I3DUtil.indexToObject(i3dNode, nodePath, nil, nil)
		if node ~= nil then
			setTranslation(node, 0, 0, 0)
			setRotation(node, 0, 0, 0)
			unlink(node)
			consumableVariation[name] = node
		else
			printWarning(string.format("Warning: Unable to find consumable object '%s' for '%s'", nodePath, consumableVariation.name))
		end
		delete(i3dNode)
	end
end
function ConsumableManager:getConsumableMeshByIndex(index, addTensionBeltMesh)
	local consumableVariation = self.variations[index]
	if consumableVariation == nil then
		return nil
	elseif consumableVariation.node ~= nil then
		local mesh = clone(consumableVariation.node, false, false, false)
		if addTensionBeltMesh and consumableVariation.tensionBeltNode ~= nil then
			local tensionBeltMesh = clone(consumableVariation.tensionBeltNode, false, false, false)
			link(mesh, tensionBeltMesh)
			return mesh, tensionBeltMesh
		end
		return mesh, nil
	else
		return nil, nil
	end
end
function ConsumableManager:getConsumableConsumingMeshByIndex(index)
	local consumableVariation = self.variations[index]
	if consumableVariation == nil then
		return nil
	elseif consumableVariation.node ~= nil then
		local clonedNode = clone(consumableVariation.consumingNode or consumableVariation.node, false, false, false)
		for _, shaderParameter in ipairs(consumableVariation.shaderParameters) do
			if shaderParameter.materialSlotName ~= nil then
				I3DUtil.setMaterialSlotShaderParameterRec(clonedNode, shaderParameter.materialSlotName, shaderParameter.name, shaderParameter.value[1], shaderParameter.value[2], shaderParameter.value[3], shaderParameter.value[4])
			else
				I3DUtil.setShaderParameterRec(clonedNode, shaderParameter.name, shaderParameter.value[1], shaderParameter.value[2], shaderParameter.value[3], shaderParameter.value[4])
			end
		end
		return clonedNode
	else
		return nil
	end
end
function ConsumableManager:getConsumableVariationIndexByName(name, customEnvironment)
	local consumableVariation = nil
	if customEnvironment ~= nil then
		consumableVariation = self.variationsByName[customEnvironment .. "." .. name]
	end
	if consumableVariation == nil then
		consumableVariation = self.variationsByName[name]
	end
	if consumableVariation == nil then
		return 0
	else
		return consumableVariation.index
	end
end
function ConsumableManager:getConsumableVariationNameByIndex(index)
	local consumableVariation = self.variations[index]
	if consumableVariation == nil then
		return "UNKNOWN"
	else
		return consumableVariation.name
	end
end
function ConsumableManager:getConsumableVariationCapacityAndUnitByIndex(index)
	local consumableVariation = self.variations[index]
	if consumableVariation ~= nil then
		return consumableVariation.capacity, consumableVariation.unitText
	else
		return nil, nil
	end
end
function ConsumableManager:getConsumableVariationShaderParameterByIndex(index)
	local consumableVariation = self.variations[index]
	if consumableVariation == nil then
		return nil
	else
		return consumableVariation.shaderParameters
	end
end
function ConsumableManager:getConsumableVariationMetaDataByIndex(index)
	local consumableVariation = self.variations[index]
	if consumableVariation == nil then
		return nil
	else
		return consumableVariation.metaData
	end
end
function ConsumableManager:getConsumableVariationsByType(typeName)
	local variations = {}
	local indexToVariationIndex = {}
	for variationIndex, consumableVariation in ipairs(self.variations) do
		if consumableVariation.type == typeName then
			table.insert(variations, consumableVariation.title)
			indexToVariationIndex[#variations] = variationIndex
		end
	end
	return variations, indexToVariationIndex
end
function ConsumableManager:getConsumableVariationPriceByIndex(index)
	local consumableVariation = self.variations[index]
	if consumableVariation == nil then
		return nil
	else
		return consumableVariation.price
	end
end
function ConsumableManager:getTypeTitle(typeName)
	local type = self.typesByName[typeName]
	if type == nil then
		return nil
	else
		return type.title or typeName
	end
end
function ConsumableManager.registerConsumableXMLPaths(schema)
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?)#type", "Name of the consumable type")
	schema:register(XMLValueType.FLOAT, "consumable.consumableVariation(?)#price", "Price per unit", 0)
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?)#name", "Name of the consumable itself (to be refered on vehicles)")
	schema:register(XMLValueType.L10N_STRING, "consumable.consumableVariation(?)#title", "Name of the consumable itself (to be shown in the UI)")
	schema:register(XMLValueType.FLOAT, "consumable.consumableVariation(?)#capacity", "Capacity of one unit from this type (to be shown in the UI)", 1)
	schema:register(XMLValueType.L10N_STRING, "consumable.consumableVariation(?)#unitText", "Unit text for the UI")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).object#filename", "Path to i3d file which contains the object")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).object#node", "Path to the object node inside of the i3d file")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).consumingObject#filename", "Path to i3d file which contains the object (in consuming state)")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).consumingObject#node", "Path to the object node inside of the i3d file (in consuming state)")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).tensionBeltObject#filename", "Path to i3d file which contains the object (tension belt mesh)")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).tensionBeltObject#node", "Path to the object node inside of the i3d file (tension belt mesh)")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).metaData.value(?)#name", "Name of the value")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).metaData.value(?)#value", "Value")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).shaderParameter(?)#name", "Name of the shader parameter to so on the objects")
	schema:register(XMLValueType.STRING, "consumable.consumableVariation(?).shaderParameter(?)#materialSlotName", "Material slot name which should receive the shader parameter (if not set, it will be applied to all materials)")
	schema:register(XMLValueType.VECTOR_4, "consumable.consumableVariation(?).shaderParameter(?)#value", "Value")
end
function ConsumableManager.registerConsumablesXMLPaths(schema)
	schema:register(XMLValueType.STRING, "consumables.types.type(?)#name", "Name of the consumable type")
	schema:register(XMLValueType.L10N_STRING, "consumables.types.type(?)#title", "Name of the type to be shown in the UI")
	schema:register(XMLValueType.STRING, "consumables.consumable(?)#filename", "Path to consumable xml file")
end
g_consumableManager = ConsumableManager.new()
