Pallet = {}
function Pallet.prerequisitesPresent(specializations)
	return true
end
function Pallet.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("Pallet")
	schema:register(XMLValueType.INT, "vehicle.pallet#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet#node", "Root visual pallet node")
	schema:register(XMLValueType.NODE_INDICES, "vehicle.pallet#linkNode", "Link node for externally loaded visual pallet (can be multiple link nodes separated by space)")
	schema:register(XMLValueType.FILENAME, "vehicle.pallet#filename", "Path to visual pallet i3d file to load", "$data/objects/pallets/shared/euroPallet/euroPallet.i3d")
	schema:register(XMLValueType.FILENAME, "vehicle.pallet.texture(?)#diffuse", "Path to the diffuse texture to use (if multiple are defined it will switch between them randomly)")
	schema:register(XMLValueType.INT, "vehicle.pallet.content(?)#fillUnitIndex", "Fill unit index for this content", "pallet#fillUnitIndex")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#node", "Object node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#tensionBeltNode", "Object used for tension belt calculations")
	schema:register(XMLValueType.BOOL, "vehicle.pallet.content(?).object(?)#useAsTensionBeltMesh", "Flag for toggling object node being used as tension belt node", true)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?)#startNode", "Start node of the strap")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?)#endNode", "End node of the strap")
	schema:register(XMLValueType.STRING, "vehicle.pallet.straps.strap(?)#tensionBeltType", "Type of the tension belt to use", "basic")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?).intersectionNode(?)#node", "Intersection node")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.pallet.sounds", "unload")
	schema:setXMLSpecializationType()
	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local key = "vehicles.vehicle(?).pallet"
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).pallet" .. "#age", "Random age of the pallet [0-1]")
end
function Pallet.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onPalletI3DFileLoaded", Pallet.onPalletI3DFileLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getInfoBoxTitle", Pallet.getInfoBoxTitle)
	SpecializationUtil.registerFunction(vehicleType, "collectPalletTensionBeltNodes", Pallet.collectPalletTensionBeltNodes)
	SpecializationUtil.registerFunction(vehicleType, "setPalletTensionBeltNodesDirty", Pallet.setPalletTensionBeltNodesDirty)
	SpecializationUtil.registerFunction(vehicleType, "updatePalletStraps", Pallet.updatePalletStraps)
end
function Pallet.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMeshNodes", Pallet.getMeshNodes)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadComponentFromXML", Pallet.loadComponentFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoLoadSize", Pallet.getAutoLoadSize)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "autoLoad", Pallet.autoLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowInVehiclesOverview", Pallet.getShowInVehiclesOverview)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Pallet.getCanBeReset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Pallet.getIsMapHotspotVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitEmptyOnReset", Pallet.getFillUnitEmptyOnReset)
end
function Pallet.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", Pallet)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pallet)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Pallet)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Pallet)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Pallet)
end
function Pallet:onPreLoad(savegame)
	self.isPallet = true
	self.allowsInput = false
end
function Pallet:onLoad(savegame)
	local spec = self.spec_pallet
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.pallet#fillUnitIndex", 1)
	spec.node = self.xmlFile:getValue("vehicle.pallet#node", nil, self.components, self.i3dMappings)
	if spec.node ~= nil and not getHasClassId(spec.node, ClassIds.SHAPE) then
		Logging.xmlWarning(self.xmlFile, "Pallet node must be a shape in 'vehicle.pallet#node'")
		spec.node = nil
	end
	spec.nodes = { spec.node }
	spec.tensionBeltNodes = { spec.node }
	spec.linkNodes = self.xmlFile:getValue("vehicle.pallet#linkNode", nil, self.components, self.i3dMappings, true)
	if 0 < #spec.linkNodes then
		spec.filename = self.xmlFile:getValue("vehicle.pallet#filename", "$data/objects/pallets/shared/euroPallet/euroPallet.i3d", self.baseDirectory)
		if spec.filename ~= nil then
			spec.sharedLoadRequestId = self:loadSubSharedI3DFile(spec.filename, true, true, self.onPalletI3DFileLoaded, self)
		end
	end
	spec.textures = {}
	for _, key in self.xmlFile:iterator("vehicle.pallet.texture") do
		local texture = {}
		texture.diffuse = self.xmlFile:getValue(key .. "#diffuse", nil, self.baseDirectory)
		if texture.diffuse == nil then
			continue
		end
		table.insert(spec.textures, texture)
	end
	if savegame ~= nil then
		spec.palletAge = savegame.xmlFile:getValue(savegame.key .. ".pallet#age")
	end
	if spec.palletAge == nil then
		if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
			spec.palletAge = math.random()
		else
			spec.palletAge = 0
		end
	end
	spec.contents = {}
	for _, contentKey in self.xmlFile:iterator("vehicle.pallet.content") do
		local content = {}
		content.objects = {}
		content.fillUnitIndex = self.xmlFile:getValue(contentKey .. "#fillUnitIndex", spec.fillUnitIndex)
		for index, key in self.xmlFile:iterator(contentKey .. ".object") do
			local object = {}
			object.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
			if object.node == nil then
				continue
			end
			object.useAsTensionBeltMesh = self.xmlFile:getValue(key .. "#useAsTensionBeltMesh", true)
			if object.useAsTensionBeltMesh then
				local tensionBeltNode = self.xmlFile:getValue(key .. "#tensionBeltNode", nil, self.components, self.i3dMappings)
				if tensionBeltNode ~= nil then
					if getShapeIsCPUMesh(tensionBeltNode) then
						object.tensionBeltNode = tensionBeltNode
					else
						Logging.xmlWarning(self.xmlFile, "Shape '%s' defined in '%s' does not have 'CPU-Mesh' flag set. Ignoring this node", getName(tensionBeltNode), key .. "#tensionBeltNode")
					end
				elseif not getShapeIsCPUMesh(object.node) then
					Logging.xmlWarning(self.xmlFile, "Shape '%s' defined in '%s' does not have 'CPU-Mesh' flag set. Either set the flag on the mesh or add a custom tension belt node using xml attribute '#tensionBeltNode'", getName(object.node), key .. "#node")
				end
			end
			object.isActive = false
			setVisibility(object.node, object.isActive)
			table.insert(content.objects, object)
		end
		if 0 < #content.objects then
			content.numObjects = #content.objects
			table.insert(spec.contents, content)
		end
	end
	spec.straps = {}
	for _, key in self.xmlFile:iterator("vehicle.pallet.straps.strap") do
		local strap = {}
		strap.startNode = self.xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
		strap.endNode = self.xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
		if strap.startNode ~= nil then
			if strap.endNode ~= nil then
				local tensionBeltType = self.xmlFile:getValue(key .. "#tensionBeltType", "basic")
				strap.beltData = g_tensionBeltManager:getBeltData(tensionBeltType)
				if strap.beltData ~= nil then
					strap.intersectionNodes = {}
					for _, intersectionKey in self.xmlFile:iterator(key .. ".intersectionNode") do
						local intersectionNode = self.xmlFile:getValue(intersectionKey .. "#node", nil, self.components, self.i3dMappings)
						if intersectionNode == nil then
							continue
						end
						table.insert(strap.intersectionNodes, intersectionNode)
					end
					table.insert(spec.straps, strap)
				else
					Logging.xmlWarning(self.xmlFile, "Invalid tension belt type '%s' defined for strap", tensionBeltType)
				end
			else
				Logging.xmlWarning(self.xmlFile, "Invalid strap definition. Both start and end node must be defined")
			end
		end
	end
	spec.strapMeshes = {}
	spec.tensionBeltMeshes = {}
	spec.tensionBeltMeshesDirty = true
	if self.isClient then
		spec.samples = {}
		spec.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.pallet.sounds", "unload", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
	self.dynamicMountForkXLimit = 0.01
	self.dynamicMountForkYLimit = 0.1
end
function Pallet:onPostLoad(savegame)
	local spec = self.spec_pallet
	if 0 < #spec.nodes then
		for _, node in ipairs(spec.nodes) do
			local materialId = getMaterial(node, 0)
			local numTextures = #spec.textures
			if 0 < numTextures then
				if numTextures == 1 then
					materialId = setMaterialDiffuseMapFromFile(materialId, spec.textures[1].diffuse, true, true, false)
				else
					local alpha = spec.palletAge * (numTextures - 1)
					local index1 = math.floor(alpha)
					local index2 = math.ceil(alpha)
					materialId = setMaterialDiffuseMapFromFile(materialId, spec.textures[index1 + 1].diffuse, true, true, false)
					materialId = setMaterialCustomMapFromFile(materialId, spec.textures[index2 + 1].diffuse, "mCustomDiffuse", true, true, false)
					materialId = setMaterialCustomParameter(materialId, "blendScale", alpha - index1, 0, 0, 0, false)
				end
				setMaterial(node, materialId, 0)
			end
		end
	end
end
function Pallet:onDelete()
	local spec = self.spec_pallet
	if self.isClient then
		g_soundManager:deleteSamples(spec.samples)
	end
	if spec.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
		spec.sharedLoadRequestId = nil
	end
	g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
end
function Pallet:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_pallet
	xmlFile:setValue(key .. "#age", spec.palletAge)
end
function Pallet:loadComponentFromXML(superFunc, component, xmlFile, key, rootPosition, i)
	if not Platform.gameplay.hasDynamicPallets and getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
		setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
	end
	return superFunc(self, component, xmlFile, key, rootPosition, i)
end
function Pallet:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_pallet
	for i = 1, #spec.contents do
		local content = spec.contents[i]
		if content.fillUnitIndex == fillUnitIndex then
			local fillLevelPct = self:getFillUnitFillLevelPercentage(fillUnitIndex)
			local visibleIndex = math.floor(content.numObjects * fillLevelPct)
			if visibleIndex == 0 and fillLevelPct then
				visibleIndex = 1
			end
			for j = 1, #content.objects do
				local object = content.objects[j]
				local isActive = j <= visibleIndex
				if object.isActive == isActive then
					continue
				end
				local unloading = object.isActive and not isActive
				if unloading and self.isClient then
					g_soundManager:playSample(spec.samples.unload)
				end
				object.isActive = isActive
				setVisibility(object.node, object.isActive)
				self:setPalletTensionBeltNodesDirty()
			end
		end
	end
end
function Pallet:getMeshNodes(superFunc)
	local spec = self.spec_pallet
	if spec.tensionBeltMeshesDirty then
		spec.tensionBeltMeshes = {}
		self:collectPalletTensionBeltNodes(spec.tensionBeltMeshes)
		spec.tensionBeltMeshesDirty = false
	end
	if 0 < #spec.tensionBeltMeshes then
		return spec.tensionBeltMeshes
	else
		return superFunc(self)
	end
end
function Pallet:collectPalletTensionBeltNodes(nodes)
	local spec = self.spec_pallet
	if 0 < #spec.tensionBeltNodes then
		for _, node in ipairs(spec.tensionBeltNodes) do
			table.insert(nodes, node)
		end
	end
	for i = 1, #spec.contents do
		local content = spec.contents[i]
		for j = 1, #content.objects do
			local object = content.objects[j]
			if object.isActive and object.useAsTensionBeltMesh then
				table.insert(nodes, object.tensionBeltNode or object.node)
			end
		end
	end
	if self.spec_tensionBeltObject ~= nil then
		for _, meshNode in ipairs(self.spec_tensionBeltObject.meshNodes) do
			table.insert(nodes, meshNode)
		end
	end
end
function Pallet:setPalletTensionBeltNodesDirty()
	self.spec_pallet.tensionBeltMeshesDirty = true
end
function Pallet:updatePalletStraps()
	local spec = self.spec_pallet
	for i = #spec.strapMeshes, 1, -1 do
		delete(spec.strapMeshes[i])
		spec.strapMeshes[i] = nil
	end
	local shapes = self:getMeshNodes()
	for _, strap in ipairs(spec.straps) do
		local tensionBelt = TensionBeltGeometryConstructor.new()
		tensionBelt:setWidth(strap.beltData.width)
		tensionBelt:setMaterial(strap.beltData.material.materialId)
		tensionBelt:setUVscale(strap.beltData.material.uvScale)
		tensionBelt:setMaxEdgeLength(0.1)
		tensionBelt:setFixedPoints(strap.startNode, strap.endNode)
		tensionBelt:setGeometryBias(0.005)
		tensionBelt:setLinkNode(strap.startNode)
		for _, node in pairs(strap.intersectionNodes) do
			local x, y, z = getWorldTranslation(node)
			local dirX, dirY, dirZ = localDirectionToWorld(node, 1, 0, 0)
			tensionBelt:addIntersectionPoint(x, y, z, dirX, dirY, dirZ)
		end
		for _, shapeId in ipairs(shapes) do
			tensionBelt:addShape(shapeId, -100, 100, -100, 100)
		end
		local beltShapeId, _, beltLength = tensionBelt:finalize()
		local directLength = 0
		for i = 1, #strap.intersectionNodes - 1 do
			local node1 = strap.intersectionNodes[i]
			local node2 = strap.intersectionNodes[i + 1]
			directLength = directLength + calcDistanceFrom(node1, node2)
		end
		if 0 < #strap.intersectionNodes then
			directLength = directLength + calcDistanceFrom(strap.startNode, strap.intersectionNodes[1])
			directLength = directLength + calcDistanceFrom(strap.intersectionNodes[#strap.intersectionNodes], strap.endNode)
		else
			directLength = calcDistanceFrom(strap.startNode, strap.endNode)
		end
		if beltLength < directLength + 0.025 then
			delete(beltShapeId)
		else
			table.insert(spec.strapMeshes, beltShapeId)
		end
	end
end
function Pallet:onPalletI3DFileLoaded(node, failedReason)
	if failedReason == LoadI3DFailedReason.NONE then
		local spec = self.spec_pallet
		local palletNode = getChildAt(node, 0)
		if getHasClassId(palletNode, ClassIds.SHAPE) then
			for i, linkNode in ipairs(spec.linkNodes) do
				if i == 1 then
					link(linkNode, palletNode)
					table.insert(spec.nodes, palletNode)
					local tensionBeltNode = getChildAt(palletNode, 0)
					if tensionBeltNode == 0 then
						continue
					end
					table.insert(spec.tensionBeltNodes, tensionBeltNode)
				else
					local additionalPalletNode = clone(palletNode, false, false, false)
					link(linkNode, additionalPalletNode)
					table.insert(spec.nodes, additionalPalletNode)
					local tensionBeltNode = getChildAt(additionalPalletNode, 0)
					if tensionBeltNode == 0 then
						continue
					end
					table.insert(spec.tensionBeltNodes, tensionBeltNode)
				end
			end
		end
		delete(node)
	end
end
function Pallet:getInfoBoxTitle()
	return g_i18n:getText("infohud_pallet")
end
function Pallet:getAutoLoadSize(superFunc)
	local size = self.size
	local sizeX = size.length
	local sizeY = size.height
	local sizeZ = size.width
	return sizeX, sizeY, sizeZ
end
function Pallet:autoLoad(superFunc, autoLoader, node, posX, posZ, sizeX, sizeZ)
	local mountPosX = posX + sizeX * 0.5
	local mountPosY = 0
	local mountPosZ = posZ + sizeZ * 0.5
	local mountRotX = 0
	local mountRotY = 1.5707963267948966
	local mountRotZ = 0
	self:mountKinematic(autoLoader, node, mountPosX, 0, mountPosZ, 0, 1.5707963267948966, 0)
	return true
end
function Pallet:getShowInVehiclesOverview(superFunc)
	return false
end
function Pallet:getCanBeReset(superFunc)
	return false
end
function Pallet:getIsMapHotspotVisible(superFunc)
	return false
end
function Pallet:getFillUnitEmptyOnReset(superFunc)
	return false
end
