Pallet = {}

function Pallet.prerequisitesPresent(self)
	return true
end
function Pallet.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Pallet")
	v1_:register(XMLValueType.INT, "vehicle.pallet#fillUnitIndex", "Fill unit index", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pallet#node", "Root visual pallet node")
	v1_:register(XMLValueType.NODE_INDICES, "vehicle.pallet#linkNode", "Link node for externally loaded visual pallet (can be multiple link nodes separated by space)")
	v1_:register(XMLValueType.FILENAME, "vehicle.pallet#filename", "Path to visual pallet i3d file to load", "$data/objects/pallets/shared/euroPallet/euroPallet.i3d")
	v1_:register(XMLValueType.FILENAME, "vehicle.pallet.texture(?)#diffuse", "Path to the diffuse texture to use (if multiple are defined it will switch between them randomly)")
	v1_:register(XMLValueType.INT, "vehicle.pallet.content(?)#fillUnitIndex", "Fill unit index for this content", "pallet#fillUnitIndex")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#node", "Object node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#tensionBeltNode", "Object used for tension belt calculations")
	v1_:register(XMLValueType.BOOL, "vehicle.pallet.content(?).object(?)#useAsTensionBeltMesh", "Flag for toggling object node being used as tension belt node", true)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?)#startNode", "Start node of the strap")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?)#endNode", "End node of the strap")
	v1_:register(XMLValueType.STRING, "vehicle.pallet.straps.strap(?)#tensionBeltType", "Type of the tension belt to use", "basic")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?).intersectionNode(?)#node", "Intersection node")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.pallet.sounds", "unload")
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).pallet#age", "Random age of the pallet [0-1]")
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

-- Local values: spec, _, key, texture, _, contentKey, content, index, key, object, tensionBeltNode, _, key, strap, tensionBeltType, _, intersectionKey, intersectionNode
function Pallet:onLoad(savegame)
	local v8_ = self.spec_pallet
	v8_.fillUnitIndex = self.xmlFile:getValue("vehicle.pallet#fillUnitIndex", 1)
	v8_.node = self.xmlFile:getValue("vehicle.pallet#node", nil, self.components, self.i3dMappings)
	if v8_.node ~= nil and not getHasClassId(v8_.node, ClassIds.SHAPE) then
		Logging.xmlWarning(self.xmlFile, "Pallet node must be a shape in \'vehicle.pallet#node\'")
		v8_.node = nil
	end
	v8_.nodes = { v8_.node }
	v8_.tensionBeltNodes = { v8_.node }
	v8_.linkNodes = self.xmlFile:getValue("vehicle.pallet#linkNode", nil, self.components, self.i3dMappings, true)
	if #v8_.linkNodes > 0 then
		v8_.filename = self.xmlFile:getValue("vehicle.pallet#filename", "$data/objects/pallets/shared/euroPallet/euroPallet.i3d", self.baseDirectory)
		if v8_.filename ~= nil then
			v8_.sharedLoadRequestId = self:loadSubSharedI3DFile(v8_.filename, true, true, self.onPalletI3DFileLoaded, self)
		end
	end
	v8_.textures = {}
	for _, v9_ in self.xmlFile:iterator("vehicle.pallet.texture") do
		local v10_ = {
			["diffuse"] = self.xmlFile:getValue(v9_ .. "#diffuse", nil, self.baseDirectory)
		}
		if v10_.diffuse ~= nil then
			local v11_ = v8_.textures
			table.insert(v11_, v10_)
		end
	end
	if savegame ~= nil then
		v8_.palletAge = savegame.xmlFile:getValue(savegame.key .. ".pallet#age")
	end
	if v8_.palletAge == nil then
		if self.propertyState == VehiclePropertyState.SHOP_CONFIG then
			v8_.palletAge = 0
		else
			v8_.palletAge = math.random()
		end
	end
	v8_.contents = {}
	for _, v12_ in self.xmlFile:iterator("vehicle.pallet.content") do
		local v13_ = {
			["objects"] = {},
			["fillUnitIndex"] = self.xmlFile:getValue(v12_ .. "#fillUnitIndex", v8_.fillUnitIndex)
		}
		for _, v14_ in self.xmlFile:iterator(v12_ .. ".object") do
			local v15_ = {
				["node"] = self.xmlFile:getValue(v14_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v15_.node ~= nil then
				v15_.useAsTensionBeltMesh = self.xmlFile:getValue(v14_ .. "#useAsTensionBeltMesh", true)
				if v15_.useAsTensionBeltMesh then
					local v16_ = self.xmlFile:getValue(v14_ .. "#tensionBeltNode", nil, self.components, self.i3dMappings)
					if v16_ == nil then
						if not getShapeIsCPUMesh(v15_.node) then
							Logging.xmlWarning(self.xmlFile, "Shape \'%s\' defined in \'%s\' does not have \'CPU-Mesh\' flag set. Either set the flag on the mesh or add a custom tension belt node using xml attribute \'#tensionBeltNode\'", getName(v15_.node), v14_ .. "#node")
						end
					elseif getShapeIsCPUMesh(v16_) then
						v15_.tensionBeltNode = v16_
					else
						Logging.xmlWarning(self.xmlFile, "Shape \'%s\' defined in \'%s\' does not have \'CPU-Mesh\' flag set. Ignoring this node", getName(v16_), v14_ .. "#tensionBeltNode")
					end
				end
				v15_.isActive = false
				setVisibility(v15_.node, v15_.isActive)
				local v17_ = v13_.objects
				table.insert(v17_, v15_)
			end
		end
		if #v13_.objects > 0 then
			v13_.numObjects = #v13_.objects
			local v18_ = v8_.contents
			table.insert(v18_, v13_)
		end
	end
	v8_.straps = {}
	for _, v19_ in self.xmlFile:iterator("vehicle.pallet.straps.strap") do
		local v20_ = {
			["startNode"] = self.xmlFile:getValue(v19_ .. "#startNode", nil, self.components, self.i3dMappings),
			["endNode"] = self.xmlFile:getValue(v19_ .. "#endNode", nil, self.components, self.i3dMappings)
		}
		if v20_.startNode == nil or v20_.endNode == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid strap definition. Both start and end node must be defined")
		else
			local v21_ = self.xmlFile:getValue(v19_ .. "#tensionBeltType", "basic")
			v20_.beltData = g_tensionBeltManager:getBeltData(v21_)
			if v20_.beltData == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid tension belt type \'%s\' defined for strap", v21_)
			else
				v20_.intersectionNodes = {}
				for _, v22_ in self.xmlFile:iterator(v19_ .. ".intersectionNode") do
					local v23_ = self.xmlFile:getValue(v22_ .. "#node", nil, self.components, self.i3dMappings)
					if v23_ ~= nil then
						local v24_ = v20_.intersectionNodes
						table.insert(v24_, v23_)
					end
				end
				local v25_ = v8_.straps
				table.insert(v25_, v20_)
			end
		end
	end
	v8_.strapMeshes = {}
	v8_.tensionBeltMeshes = {}
	v8_.tensionBeltMeshesDirty = true
	if self.isClient then
		v8_.samples = {}
		v8_.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.pallet.sounds", "unload", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
	self.dynamicMountForkXLimit = 0.01
	self.dynamicMountForkYLimit = 0.1
end

-- Local values: spec, _, node, materialId, numTextures, alpha, index1, index2
function Pallet:onPostLoad(savegame)
	local v27_ = self.spec_pallet
	if #v27_.nodes > 0 then
		for _, v28_ in ipairs(v27_.nodes) do
			local v29_ = getMaterial(v28_, 0)
			local v30_ = #v27_.textures
			if v30_ > 0 then
				local v31_
				if v30_ == 1 then
					v31_ = setMaterialDiffuseMapFromFile(v29_, v27_.textures[1].diffuse, true, true, false)
				else
					local v32_ = v27_.palletAge * (v30_ - 1)
					local v33_ = math.floor(v32_)
					local v34_ = math.ceil(v32_)
					local v35_ = setMaterialDiffuseMapFromFile(v29_, v27_.textures[v33_ + 1].diffuse, true, true, false)
					local v36_ = setMaterialCustomMapFromFile(v35_, v27_.textures[v34_ + 1].diffuse, "mCustomDiffuse", true, true, false)
					v31_ = setMaterialCustomParameter(v36_, "blendScale", v32_ - v33_, 0, 0, 0, false)
				end
				setMaterial(v28_, v31_, 0)
			end
		end
	end
end

-- Local values: spec
function Pallet:onDelete()
	local v38_ = self.spec_pallet
	if self.isClient then
		g_soundManager:deleteSamples(v38_.samples)
	end
	if v38_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v38_.sharedLoadRequestId)
		v38_.sharedLoadRequestId = nil
	end
	g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
end

-- Local values: spec
function Pallet:saveToXMLFile(xmlFile, key, usedModNames)
	local v42_ = self.spec_pallet
	xmlFile:setValue(key .. "#age", v42_.palletAge)
end

function Pallet:loadComponentFromXML(superFunc, component, xmlFile, key, rootPosition, i)
	if not Platform.gameplay.hasDynamicPallets and getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
		setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
	end
	return superFunc(self, component, xmlFile, key, rootPosition, i)
end

-- Local values: spec, i, content, fillLevelPct, visibleIndex, j, object, isActive, unloading
function Pallet:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v52_ = self.spec_pallet
	for v53_ = 1, #v52_.contents do
		local v54_ = v52_.contents[v53_]
		if v54_.fillUnitIndex == fillUnitIndex then
			local v55_ = self:getFillUnitFillLevelPercentage(fillUnitIndex)
			local v56_ = v54_.numObjects * v55_
			local v57_ = math.floor(v56_)
			local v58_ = v57_ == 0 and v55_ and 1 or v57_
			for v59_ = 1, #v54_.objects do
				local v60_ = v54_.objects[v59_]
				local v61_ = v59_ <= v58_
				if v60_.isActive ~= v61_ then
					local v62_ = v60_.isActive
					if v62_ then
						v62_ = not v61_
					end
					if v62_ and self.isClient then
						g_soundManager:playSample(v52_.samples.unload)
					end
					v60_.isActive = v61_
					setVisibility(v60_.node, v60_.isActive)
					self:setPalletTensionBeltNodesDirty()
				end
			end
		end
	end
end

-- Local values: spec
function Pallet:getMeshNodes(superFunc)
	local v65_ = self.spec_pallet
	if v65_.tensionBeltMeshesDirty then
		v65_.tensionBeltMeshes = {}
		self:collectPalletTensionBeltNodes(v65_.tensionBeltMeshes)
		v65_.tensionBeltMeshesDirty = false
	end
	if #v65_.tensionBeltMeshes > 0 then
		return v65_.tensionBeltMeshes
	else
		return superFunc(self)
	end
end

-- Local values: spec, _, node, i, content, j, object, _, meshNode
function Pallet:collectPalletTensionBeltNodes(nodes)
	local v68_ = self.spec_pallet
	if #v68_.tensionBeltNodes > 0 then
		for _, v69_ in ipairs(v68_.tensionBeltNodes) do
			table.insert(nodes, v69_)
		end
	end
	for v70_ = 1, #v68_.contents do
		local v71_ = v68_.contents[v70_]
		for v72_ = 1, #v71_.objects do
			local v73_ = v71_.objects[v72_]
			if v73_.isActive and v73_.useAsTensionBeltMesh then
				local v74_ = v73_.tensionBeltNode or v73_.node
				table.insert(nodes, v74_)
			end
		end
	end
	if self.spec_tensionBeltObject ~= nil then
		for _, v75_ in ipairs(self.spec_tensionBeltObject.meshNodes) do
			table.insert(nodes, v75_)
		end
	end
end

function Pallet:setPalletTensionBeltNodesDirty()
	self.spec_pallet.tensionBeltMeshesDirty = true
end

-- Local values: spec, i, shapes, _, strap, tensionBelt, _, node, x, y, z, dirX, dirY, dirZ, _, shapeId, beltShapeId, _, beltLength, directLength, i, node1, node2
function Pallet:updatePalletStraps()
	local v78_ = self.spec_pallet
	for v79_ = #v78_.strapMeshes, 1, -1 do
		delete(v78_.strapMeshes[v79_])
		v78_.strapMeshes[v79_] = nil
	end
	local v80_ = self:getMeshNodes()
	for _, v81_ in ipairs(v78_.straps) do
		local v82_ = TensionBeltGeometryConstructor.new()
		v82_:setWidth(v81_.beltData.width)
		v82_:setMaterial(v81_.beltData.material.materialId)
		v82_:setUVscale(v81_.beltData.material.uvScale)
		v82_:setMaxEdgeLength(0.1)
		v82_:setFixedPoints(v81_.startNode, v81_.endNode)
		v82_:setGeometryBias(0.005)
		v82_:setLinkNode(v81_.startNode)
		for _, v83_ in pairs(v81_.intersectionNodes) do
			local v84_, v85_, v86_ = getWorldTranslation(v83_)
			local v87_, v88_, v89_ = localDirectionToWorld(v83_, 1, 0, 0)
			v82_:addIntersectionPoint(v84_, v85_, v86_, v87_, v88_, v89_)
		end
		for _, v90_ in ipairs(v80_) do
			v82_:addShape(v90_, -100, 100, -100, 100)
		end
		local v91_, _, v92_ = v82_:finalize()
		local v93_ = 0
		for v94_ = 1, #v81_.intersectionNodes - 1 do
			local v95_ = v81_.intersectionNodes[v94_]
			local v96_ = v81_.intersectionNodes[v94_ + 1]
			v93_ = v93_ + calcDistanceFrom(v95_, v96_)
		end
		local v97_
		if #v81_.intersectionNodes > 0 then
			v97_ = v93_ + calcDistanceFrom(v81_.startNode, v81_.intersectionNodes[1]) + calcDistanceFrom(v81_.intersectionNodes[#v81_.intersectionNodes], v81_.endNode)
		else
			v97_ = calcDistanceFrom(v81_.startNode, v81_.endNode)
		end
		if v92_ < v97_ + 0.025 then
			delete(v91_)
		else
			local v98_ = v78_.strapMeshes
			table.insert(v98_, v91_)
		end
	end
end

-- Local values: spec, palletNode, i, linkNode, tensionBeltNode, additionalPalletNode, tensionBeltNode
function Pallet:onPalletI3DFileLoaded(node, failedReason)
	if failedReason == LoadI3DFailedReason.NONE then
		local v102_ = self.spec_pallet
		local v103_ = getChildAt(node, 0)
		if getHasClassId(v103_, ClassIds.SHAPE) then
			for v104_, v105_ in ipairs(v102_.linkNodes) do
				if v104_ == 1 then
					link(v105_, v103_)
					local v106_ = v102_.nodes
					table.insert(v106_, v103_)
					local v107_ = getChildAt(v103_, 0)
					if v107_ ~= 0 then
						local v108_ = v102_.tensionBeltNodes
						table.insert(v108_, v107_)
					end
				else
					local v109_ = clone(v103_, false, false, false)
					link(v105_, v109_)
					local v110_ = v102_.nodes
					table.insert(v110_, v109_)
					local v111_ = getChildAt(v109_, 0)
					if v111_ ~= 0 then
						local v112_ = v102_.tensionBeltNodes
						table.insert(v112_, v111_)
					end
				end
			end
		end
		delete(node)
	end
end

function Pallet.getInfoBoxTitle(self)
	return g_i18n:getText("infohud_pallet")
end

-- Local values: size, sizeX, sizeY, sizeZ
function Pallet:getAutoLoadSize(superFunc)
	local v114_ = self.size
	return v114_.length, v114_.height, v114_.width
end

-- Local values: mountPosX, mountPosY, mountPosZ, mountRotX, mountRotY, mountRotZ
function Pallet:autoLoad(superFunc, autoLoader, node, posX, posZ, sizeX, sizeZ)
	self:mountKinematic(autoLoader, node, posX + sizeX * 0.5, 0, posZ + sizeZ * 0.5, 0, 1.5707963267948966, 0)
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
