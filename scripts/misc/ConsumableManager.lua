-- Local values: ConsumableManager_mt
ConsumableManager = {}
ConsumableManager.DEFAULT_FILENAME = "data/objects/consumables/consumables.xml"
ConsumableManager.NUM_VARIATION_BITS = 9
ConsumableManager.MAX_NUM_VARIATIONS = 2 ^ ConsumableManager.NUM_VARIATION_BITS - 1
ConsumableManager.xmlSchemaConsumable = nil
ConsumableManager.xmlSchemaConsumables = nil
local ConsumableManager_mt = Class(ConsumableManager, AbstractManager)

-- Upvalues: ConsumableManager_mt
-- Local values: self
function ConsumableManager.new(customMt)
	-- upvalues: (copy) ConsumableManager_mt
	local v3_ = AbstractManager.new(customMt or ConsumableManager_mt)
	v3_.types = {}
	v3_.typesByName = {}
	v3_.variations = {}
	v3_.variationsByName = {}
	v3_.sharedLoadRequestIds = {}
	v3_.modConsumablesToLoad = {}
	ConsumableManager.xmlSchemaConsumable = XMLSchema.new("consumable")
	ConsumableManager.registerConsumableXMLPaths(ConsumableManager.xmlSchemaConsumable)
	ConsumableManager.xmlSchemaConsumables = XMLSchema.new("consumables")
	ConsumableManager.registerConsumablesXMLPaths(ConsumableManager.xmlSchemaConsumables)
	return v3_
end

-- Local values: consumablesXMLFile, _, key, type, _, key, filename, i, modConsumablesToLoad
function ConsumableManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	ConsumableManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	local v6_ = XMLFile.load("consumables", ConsumableManager.DEFAULT_FILENAME, ConsumableManager.xmlSchemaConsumables)
	if v6_ ~= nil then
		for _, v7_ in v6_:iterator("consumables.types.type") do
			local v8_ = {
				["name"] = v6_:getValue(v7_ .. "#name"),
				["title"] = v6_:getValue(v7_ .. "#title")
			}
			if v8_.name == nil or v8_.title == nil then
				Logging.xmlWarning(v6_, "Failed to load consumable type from xml. (%s)", v7_)
			else
				v8_.name = string.upper(v8_.name)
				local v9_ = self.types
				table.insert(v9_, v8_)
				self.typesByName[v8_.name] = v8_
			end
		end
		for _, v10_ in v6_:iterator("consumables.consumable") do
			local v11_ = v6_:getValue(v10_ .. "#filename")
			if v11_ ~= nil then
				self:loadConsumableVariationsFromXML(Utils.getFilename(v11_, baseDirectory), nil, baseDirectory)
			end
		end
		v6_:delete()
	end
	for v12_ = #self.modConsumablesToLoad, 1, -1 do
		local v13_ = self.modConsumablesToLoad[v12_]
		self:loadConsumableVariationsFromXML(v13_.xmlFilename, v13_.customEnvironment, v13_.baseDirectory)
		self.modConsumablesToLoad[v12_] = nil
	end
end

-- Local values: _, consumableVariation, i, sharedLoadRequestId
function ConsumableManager:unloadMapData()
	for _, v15_ in ipairs(self.variations) do
		if v15_.node ~= nil then
			delete(v15_.node)
		end
		if v15_.consumingNode ~= nil then
			delete(v15_.consumingNode)
		end
		if v15_.tensionBeltNode ~= nil then
			delete(v15_.tensionBeltNode)
		end
	end
	self.variations = {}
	for v16_ = 1, #self.sharedLoadRequestIds do
		local v17_ = self.sharedLoadRequestIds[v16_]
		g_i3DManager:releaseSharedI3DFile(v17_)
	end
	self.sharedLoadRequestIds = {}
	ConsumableManager:superClass().unloadMapData(self)
end

function ConsumableManager:addModConsumable(xmlFilename, customEnvironment, baseDirectory)
	local v22_ = self.modConsumablesToLoad
	table.insert(v22_, {
		["xmlFilename"] = xmlFilename,
		["customEnvironment"] = customEnvironment,
		["baseDirectory"] = baseDirectory
	})
end

-- Local values: xmlFile, _, key, consumableVariation, nodePath, sharedLoadRequestId, consumingNodePath, sharedLoadRequestId, tensionBeltNodePath, sharedLoadRequestId, _, valueKey, name, valueStr, value, _, paramKey, name, shaderParameter
function ConsumableManager:loadConsumableVariationsFromXML(xmlFilename, customEnvironment, baseDirectory)
	Logging.devInfo("Loading Consumable from \'%s\'", xmlFilename)
	local v27_ = XMLFile.load("Consumable", xmlFilename, ConsumableManager.xmlSchemaConsumable)
	if v27_ ~= nil then
		for _, v28_ in v27_:iterator("consumable.consumableVariation") do
			if #self.variations >= ConsumableManager.MAX_NUM_VARIATIONS then
				Logging.xmlWarning(v27_, "Max. num consumables variations reached, skip loading of \'%s\'", v28_)
			else
				local v29_ = {
					["type"] = v27_:getValue(v28_ .. "#type")
				}
				if v29_.type == nil then
					Logging.xmlWarning(v27_, "Missing type in \'%s\'", v28_)
				else
					v29_.name = v27_:getValue(v28_ .. "#name")
					if v29_.name == nil then
						Logging.xmlWarning(v27_, "Missing name in \'%s\'", v28_)
					else
						if customEnvironment ~= nil then
							v29_.name = customEnvironment .. "." .. v29_.name
						end
						v29_.price = v27_:getValue(v28_ .. "#price", 0)
						v29_.title = v27_:getValue(v28_ .. "#title", nil, customEnvironment)
						if v29_.title == nil then
							Logging.xmlWarning(v27_, "Missing title in \'%s\'", v28_)
						else
							v29_.unitText = v27_:getValue(v28_ .. "#unitText", nil, customEnvironment, false)
							v29_.capacity = v27_:getValue(v28_ .. "#capacity", 1)
							v29_.filename = v27_:getValue(v28_ .. ".object#filename")
							if v29_.filename ~= nil then
								v29_.filename = Utils.getFilename(v29_.filename, baseDirectory)
								if v29_.filename ~= nil then
									local v30_ = v27_:getValue(v28_ .. ".object#node")
									if v30_ ~= nil then
										local v31_ = g_i3DManager:loadSharedI3DFileAsync(v29_.filename, false, false, self.consumableI3DFileLoaded, self, { v29_, v30_, "node" })
										local v32_ = self.sharedLoadRequestIds
										table.insert(v32_, v31_)
									end
								end
							end
							v29_.consumingFilename = v27_:getValue(v28_ .. ".consumingObject#filename")
							if v29_.consumingFilename ~= nil then
								v29_.consumingFilename = Utils.getFilename(v29_.consumingFilename, baseDirectory)
								if v29_.consumingFilename ~= nil then
									local v33_ = v27_:getValue(v28_ .. ".consumingObject#node")
									if v33_ ~= nil then
										local v34_ = g_i3DManager:loadSharedI3DFileAsync(v29_.consumingFilename, false, false, self.consumableI3DFileLoaded, self, { v29_, v33_, "consumingNode" })
										local v35_ = self.sharedLoadRequestIds
										table.insert(v35_, v34_)
									end
								end
							end
							v29_.tensionBeltFilename = v27_:getValue(v28_ .. ".tensionBeltObject#filename")
							if v29_.tensionBeltFilename ~= nil then
								v29_.tensionBeltFilename = Utils.getFilename(v29_.tensionBeltFilename, baseDirectory)
								if v29_.tensionBeltFilename ~= nil then
									local v36_ = v27_:getValue(v28_ .. ".tensionBeltObject#node")
									if v36_ ~= nil then
										local v37_ = g_i3DManager:loadSharedI3DFileAsync(v29_.tensionBeltFilename, false, false, self.consumableI3DFileLoaded, self, { v29_, v36_, "tensionBeltNode" })
										local v38_ = self.sharedLoadRequestIds
										table.insert(v38_, v37_)
									end
								end
							end
							v29_.metaData = {}
							for _, v39_ in v27_:iterator(v28_ .. ".metaData.value") do
								local v40_ = v27_:getValue(v39_ .. "#name")
								if v40_ == nil then
									Logging.xmlWarning(v27_, "Missing name in \'%s\'", v39_)
								else
									local v41_ = v27_:getValue(v39_ .. "#value")
									if v41_ ~= nil then
										local v42_
										if v41_:contains(" ") then
											v42_ = string.getVector(v41_)
										else
											v42_ = tonumber(v41_) or v41_
										end
										if v42_ == nil then
											Logging.xmlWarning(v27_, "Invalid value in \'%s\'", v39_)
										else
											v29_.metaData[v40_] = v42_
										end
									end
								end
							end
							v29_.shaderParameters = {}
							for _, v43_ in v27_:iterator(v28_ .. ".shaderParameter") do
								local v44_ = v27_:getValue(v43_ .. "#name")
								if v44_ == nil then
									Logging.xmlWarning(v27_, "Missing name in \'%s\'", v43_)
								else
									local v45_ = {
										["name"] = v44_,
										["materialSlotName"] = v27_:getValue(v43_ .. "#materialSlotName"),
										["value"] = v27_:getValue(v43_ .. "#value", nil, true)
									}
									if v45_.value == nil then
										Logging.xmlWarning(v27_, "Invalid value in \'%s\'", v43_)
									else
										local v46_ = v29_.shaderParameters
										table.insert(v46_, v45_)
									end
								end
							end
							if self.variationsByName[v29_.name] == nil then
								local v47_ = self.variations
								table.insert(v47_, v29_)
								v29_.index = #self.variations
								self.variationsByName[v29_.name] = v29_
							else
								Logging.xmlWarning(v27_, "Consumable with name \'%s\' already registered", v29_.name)
							end
						end
					end
				end
			end
		end
		v27_:delete()
	end
end

-- Local values: consumableVariation, nodePath, name, node
function ConsumableManager:consumableI3DFileLoaded(i3dNode, failedReason, arguments)
	local v50_ = arguments[1]
	local v51_ = arguments[2]
	local v52_ = arguments[3]
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v53_ = I3DUtil.indexToObject(i3dNode, v51_, nil, nil)
		if v53_ == nil then
			printWarning(string.format("Warning: Unable to find consumable object \'%s\' for \'%s\'", v51_, v50_.name))
		else
			setTranslation(v53_, 0, 0, 0)
			setRotation(v53_, 0, 0, 0)
			unlink(v53_)
			v50_[v52_] = v53_
		end
		delete(i3dNode)
	end
end

-- Local values: consumableVariation, mesh, tensionBeltMesh
function ConsumableManager:getConsumableMeshByIndex(index, addTensionBeltMesh)
	local v57_ = self.variations[index]
	if v57_ == nil then
		return nil
	end
	if v57_.node == nil then
		return nil, nil
	end
	local v58_ = clone(v57_.node, false, false, false)
	if not addTensionBeltMesh or v57_.tensionBeltNode == nil then
		return v58_, nil
	end
	local v59_ = clone(v57_.tensionBeltNode, false, false, false)
	link(v58_, v59_)
	return v58_, v59_
end

-- Local values: consumableVariation, clonedNode, _, shaderParameter
function ConsumableManager:getConsumableConsumingMeshByIndex(index)
	local v62_ = self.variations[index]
	if v62_ == nil then
		return nil
	end
	if v62_.node == nil then
		return nil
	end
	local v63_ = clone(v62_.consumingNode or v62_.node, false, false, false)
	for _, v64_ in ipairs(v62_.shaderParameters) do
		if v64_.materialSlotName == nil then
			I3DUtil.setShaderParameterRec(v63_, v64_.name, v64_.value[1], v64_.value[2], v64_.value[3], v64_.value[4])
		else
			I3DUtil.setMaterialSlotShaderParameterRec(v63_, v64_.materialSlotName, v64_.name, v64_.value[1], v64_.value[2], v64_.value[3], v64_.value[4])
		end
	end
	return v63_
end

-- Local values: consumableVariation
function ConsumableManager:getConsumableVariationIndexByName(name, customEnvironment)
	local v68_
	if customEnvironment == nil then
		v68_ = nil
	else
		v68_ = self.variationsByName[customEnvironment .. "." .. name]
	end
	if v68_ == nil then
		v68_ = self.variationsByName[name]
	end
	return v68_ == nil and 0 or v68_.index
end

-- Local values: consumableVariation
function ConsumableManager:getConsumableVariationNameByIndex(index)
	local v71_ = self.variations[index]
	return v71_ == nil and "UNKNOWN" or v71_.name
end

-- Local values: consumableVariation
function ConsumableManager:getConsumableVariationCapacityAndUnitByIndex(index)
	local v74_ = self.variations[index]
	if v74_ == nil then
		return nil, nil
	else
		return v74_.capacity, v74_.unitText
	end
end

-- Local values: consumableVariation
function ConsumableManager:getConsumableVariationShaderParameterByIndex(index)
	local v77_ = self.variations[index]
	if v77_ == nil then
		return nil
	else
		return v77_.shaderParameters
	end
end

-- Local values: consumableVariation
function ConsumableManager:getConsumableVariationMetaDataByIndex(index)
	local v80_ = self.variations[index]
	if v80_ == nil then
		return nil
	else
		return v80_.metaData
	end
end

-- Local values: variations, indexToVariationIndex, variationIndex, consumableVariation
function ConsumableManager:getConsumableVariationsByType(typeName)
	local v83_ = {}
	local v84_ = {}
	for v85_, v86_ in ipairs(self.variations) do
		if v86_.type == typeName then
			local v87_ = v86_.title
			table.insert(v83_, v87_)
			v84_[#v83_] = v85_
		end
	end
	return v83_, v84_
end

-- Local values: consumableVariation
function ConsumableManager:getConsumableVariationPriceByIndex(index)
	local v90_ = self.variations[index]
	if v90_ == nil then
		return nil
	else
		return v90_.price
	end
end

-- Local values: type
function ConsumableManager:getTypeTitle(typeName)
	local v93_ = self.typesByName[typeName]
	if v93_ == nil then
		return nil
	else
		return v93_.title or typeName
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
