TreeSaplingPallet = {}

function TreeSaplingPallet.prerequisitesPresent(specializations)
	return true
end
function TreeSaplingPallet.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("treeSaplingType", g_i18n:getText("configuration_treeType"), "treeSaplingPallet", VehicleConfigurationItemTreeSapling)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("TreeSaplingPallet")
	v1_:register(XMLValueType.INT, "vehicle.treeSaplingPallet#fillUnitIndex", "Index of the saplings fill unit", 1)
	v1_:register(XMLValueType.STRING, "vehicle.treeSaplingPallet#treeType", "Tree Type Name", "spruce1")
	v1_:register(XMLValueType.STRING, "vehicle.treeSaplingPallet#variationName", "Stage variation name to use", "DEFAULT")
	v1_:register(XMLValueType.FILENAME, "vehicle.treeSaplingPallet#filename", "Custom tree sapling i3d file")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.treeSaplingPallet.saplingNodes.saplingNode(?)#node", "Sapling link node")
	v1_:register(XMLValueType.BOOL, "vehicle.treeSaplingPallet.saplingNodes.saplingNode(?)#randomize", "Randomize rotation and scale of saplings", true)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.treeSaplingPallet.treeSaplingTypeConfigurations.treeSaplingTypeConfiguration(?).saplingNodes.saplingNode(?)#node", "Sapling link node")
	v1_:register(XMLValueType.BOOL, "vehicle.treeSaplingPallet.treeSaplingTypeConfigurations.treeSaplingTypeConfiguration(?).saplingNodes.saplingNode(?)#randomize", "Randomize rotation and scale of saplings", true)
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).treeSaplingPallet#treeTypeName", "Name of currently loaded tree type")
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).treeSaplingPallet#variationName", "Name of currently loaded tree stage variation")
end

function TreeSaplingPallet.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onTreeSaplingLoaded", TreeSaplingPallet.onTreeSaplingLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getTreeSaplingPalletType", TreeSaplingPallet.getTreeSaplingPalletType)
	SpecializationUtil.registerFunction(vehicleType, "setTreeSaplingPalletType", TreeSaplingPallet.setTreeSaplingPalletType)
	SpecializationUtil.registerFunction(vehicleType, "updateTreeSaplingVisuals", TreeSaplingPallet.updateTreeSaplingVisuals)
	SpecializationUtil.registerFunction(vehicleType, "updateTreeSaplingPalletNodes", TreeSaplingPallet.updateTreeSaplingPalletNodes)
end

function TreeSaplingPallet.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", TreeSaplingPallet.showInfo)
end

function TreeSaplingPallet.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreeSaplingPallet)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreeSaplingPallet)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", TreeSaplingPallet)
end

-- Local values: spec, treeSaplingTypeConfigurationId, baseKey, configItem, treeTypeDesc, variations, variation, _, _variation, nodeKey
function TreeSaplingPallet:onLoad(savegame)
	local v_u_8_ = self.spec_treeSaplingPallet
	local v9_ = self.configurations.treeSaplingType or 1
	local v10_ = string.format("vehicle.treeSaplingPallet.treeSaplingTypeConfigurations.treeSaplingTypeConfiguration(%d)", v9_ - 1)
	local v11_ = not self.xmlFile:hasProperty(v10_) and "vehicle.treeSaplingPallet" or v10_
	v_u_8_.saplingNodes = {}
	v_u_8_.fillUnitIndex = self.xmlFile:getValue("vehicle.treeSaplingPallet#fillUnitIndex", 1)
	v_u_8_.treeTypeName = self.xmlFile:getValue("vehicle.treeSaplingPallet#treeType", "spruce")
	v_u_8_.variationName = self.xmlFile:getValue("vehicle.treeSaplingPallet#variationName")
	v_u_8_.treeTypeFilename = self.xmlFile:getValue("vehicle.treeSaplingPallet#filename", nil, self.baseDirectory)
	local v12_ = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "treeSaplingType", v9_)
	if v12_ ~= nil then
		v_u_8_.fillUnitIndex = v12_.fillUnitIndex or v_u_8_.fillUnitIndex
		v_u_8_.treeTypeName = v12_.treeTypeName or v_u_8_.treeTypeName
		v_u_8_.variationName = v12_.variationName or v_u_8_.variationName
		v_u_8_.treeTypeFilename = v12_.treeTypeFilename or v_u_8_.treeTypeFilename
	end
	if savegame ~= nil then
		v_u_8_.treeTypeName = savegame.xmlFile:getValue(savegame.key .. ".treeSaplingPallet#treeTypeName", v_u_8_.treeTypeName)
		v_u_8_.variationName = savegame.xmlFile:getValue(savegame.key .. ".treeSaplingPallet#variationName", v_u_8_.variationName)
	end
	if v_u_8_.treeTypeFilename == nil then
		local v13_ = g_treePlantManager:getTreeTypeDescFromName(v_u_8_.treeTypeName)
		if v13_ ~= nil then
			local v14_ = v13_.stages[1]
			if v14_ ~= nil then
				local v15_ = nil
				for _, v16_ in ipairs(v14_) do
					if string.lower(v16_.name or "DEFAULT") == string.lower(v_u_8_.variationName or "DEFAULT") then
						v15_ = v16_
						break
					end
				end
				if v15_ ~= nil then
					v_u_8_.treeTypeFilename = v15_.palletFilename or v15_.filename
				end
			end
			v_u_8_.infoBoxLineTitle = g_i18n:getText("configuration_treeType", self.customEnvironment)
			v_u_8_.infoBoxLineValue = v13_.title
		end
	end
	if v_u_8_.treeTypeFilename ~= nil then
		local v17_ = v11_ .. ".saplingNodes.saplingNode"
		local v18_ = not self.xmlFile:hasProperty(v17_) and "vehicle.treeSaplingPallet.saplingNodes.saplingNode" or v17_
		self.xmlFile:iterate(v18_, function(_, p19_)
			-- upvalues: (copy) self, (copy) v_u_8_
			local v20_ = {
				["node"] = self.xmlFile:getValue(p19_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v20_.node ~= nil then
				if self.xmlFile:getValue(p19_ .. "#randomize", true) then
					setRotation(v20_.node, 0, math.random(0, 6.283185307179586), 0)
					setScale(v20_.node, 1, math.random(90, 110) / 100, 1)
				end
				local v21_ = v_u_8_.saplingNodes
				table.insert(v21_, v20_)
			end
		end)
	end
	self:updateTreeSaplingVisuals()
end

-- Local values: spec, _, saplingNode
function TreeSaplingPallet:onDelete()
	local v23_ = self.spec_treeSaplingPallet
	if v23_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v23_.sharedLoadRequestId)
		v23_.sharedLoadRequestId = nil
	end
	if v23_.saplingNodes ~= nil then
		for _, v24_ in ipairs(v23_.saplingNodes) do
			if v24_.saplingShape ~= nil then
				delete(v24_.saplingShape)
				v24_.saplingShape = nil
			end
		end
	end
end

-- Local values: spec
function TreeSaplingPallet:saveToXMLFile(xmlFile, key, usedModNames)
	local v28_ = self.spec_treeSaplingPallet
	if v28_.treeTypeName ~= nil then
		xmlFile:setValue(key .. "#treeTypeName", v28_.treeTypeName)
	end
	if v28_.variationName ~= nil then
		xmlFile:setValue(key .. "#variationName", v28_.variationName)
	end
end

-- Local values: spec
function TreeSaplingPallet:getTreeSaplingPalletType()
	local v30_ = self.spec_treeSaplingPallet
	return v30_.treeTypeName, v30_.variationName
end

-- Local values: spec
function TreeSaplingPallet:setTreeSaplingPalletType(treeTypeName, variationName)
	local v34_ = self.spec_treeSaplingPallet
	if treeTypeName ~= v34_.treeTypeName or v34_.variationName ~= variationName then
		v34_.treeTypeName = treeTypeName
		v34_.variationName = variationName
		self:updateTreeSaplingVisuals()
	end
end

-- Local values: spec
function TreeSaplingPallet:updateTreeSaplingVisuals()
	local v36_ = self.spec_treeSaplingPallet
	if v36_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v36_.sharedLoadRequestId)
		v36_.sharedLoadRequestId = nil
	end
	if v36_.treeTypeFilename ~= nil then
		if self.finishedLoading then
			v36_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v36_.treeTypeFilename, false, false, self.onTreeSaplingLoaded, self)
			return
		end
		v36_.sharedLoadRequestId = self:loadSubSharedI3DFile(v36_.treeTypeFilename, false, false, self.onTreeSaplingLoaded, self)
	end
end

-- Local values: shape, spec, _, saplingNode
function TreeSaplingPallet:onTreeSaplingLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		local v39_ = getChildAt(i3dNode, 0)
		local v40_ = self.spec_treeSaplingPallet
		for _, v41_ in ipairs(v40_.saplingNodes) do
			if v41_.saplingShape ~= nil then
				delete(v41_.saplingShape)
			end
			v41_.saplingShape = clone(v39_, false, false, false)
			link(v41_.node, v41_.saplingShape)
		end
		delete(i3dNode)
		self:updateTreeSaplingPalletNodes()
	end
end

-- Local values: spec, fillLevel, capacity, i, saplingNode
function TreeSaplingPallet:updateTreeSaplingPalletNodes()
	local v43_ = self.spec_treeSaplingPallet
	local v44_ = self:getFillUnitFillLevel(v43_.fillUnitIndex)
	local v45_ = self:getFillUnitCapacity(v43_.fillUnitIndex)
	for v46_ = 1, #v43_.saplingNodes do
		local v47_ = v43_.saplingNodes[v46_]
		setVisibility(v47_.node, v46_ <= MathUtil.round(v44_))
		I3DUtil.setShaderParameterRec(v47_.node, "hideByIndex", v45_ - v44_, 0, 0, 0)
	end
end

function TreeSaplingPallet:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	self:updateTreeSaplingPalletNodes()
end

-- Local values: spec
function TreeSaplingPallet:showInfo(superFunc, box)
	local v52_ = self.spec_treeSaplingPallet
	if v52_.infoBoxLineTitle ~= nil then
		box:addLine(v52_.infoBoxLineTitle, v52_.infoBoxLineValue)
	end
	superFunc(self, box)
end
