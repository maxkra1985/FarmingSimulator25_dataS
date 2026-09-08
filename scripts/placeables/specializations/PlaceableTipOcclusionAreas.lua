PlaceableTipOcclusionAreas = {}

function PlaceableTipOcclusionAreas.prerequisitesPresent(specializations)
	return true
end

function PlaceableTipOcclusionAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadTipOcclusionArea", PlaceableTipOcclusionAreas.loadTipOcclusionArea)
	SpecializationUtil.registerFunction(placeableType, "updateTipOcclusionAreas", PlaceableTipOcclusionAreas.updateTipOcclusionAreas)
end

function PlaceableTipOcclusionAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTipOcclusionAreas)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTipOcclusionAreas)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTipOcclusionAreas)
end

function PlaceableTipOcclusionAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("TipOcclusionAreas")
	schema:register(XMLValueType.FLOAT, basePath .. ".tipOcclusionUpdateArea#sizeX", "Size X")
	schema:register(XMLValueType.FLOAT, basePath .. ".tipOcclusionUpdateArea#sizeZ", "Size Z")
	schema:register(XMLValueType.FLOAT, basePath .. ".tipOcclusionUpdateArea#centerX", "Center position X", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".tipOcclusionUpdateArea#centerZ", "Center position Z", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".tipOcclusionUpdateAreas.tipOcclusionUpdateArea(?)#startNode", "Start node of tipOcclusion update area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".tipOcclusionUpdateAreas.tipOcclusionUpdateArea(?)#endNode", "End node of tipOcclusion update area")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, sizeX, sizeZ, centerX, centerZ, area
function PlaceableTipOcclusionAreas:onLoad(savegame)
	local v_u_6_ = self.spec_tipOcclusionAreas
	local v_u_7_ = self.xmlFile
	v_u_6_.updateTipOcclusionAreasOnDelete = false
	v_u_6_.areas = {}
	v_u_7_:iterate("placeable.tipOcclusionUpdateAreas.tipOcclusionUpdateArea", function(_, p8_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v9_ = {}
		if self:loadTipOcclusionArea(v_u_7_, p8_, v9_) then
			local v10_ = v_u_6_.areas
			table.insert(v10_, v9_)
		end
	end)
	if v_u_7_:hasProperty("placeable.tipOcclusionUpdateArea") then
		local v11_ = v_u_7_:getValue("placeable.tipOcclusionUpdateArea#sizeX")
		local v12_ = v_u_7_:getValue("placeable.tipOcclusionUpdateArea#sizeZ")
		if v11_ ~= nil and v12_ ~= nil then
			local v13_ = v_u_7_:getValue("placeable.tipOcclusionUpdateArea#centerX", 0)
			local v14_ = v_u_7_:getValue("placeable.tipOcclusionUpdateArea#centerZ", 0)
			local v15_ = {
				["center"] = {}
			}
			v15_.center.x = v13_
			v15_.center.z = v14_
			v15_.size = {}
			v15_.size.x = v11_
			v15_.size.z = v12_
			local v16_ = v_u_6_.areas
			table.insert(v16_, v15_)
		end
	end
end

-- Local values: spec
function PlaceableTipOcclusionAreas:onDelete()
	if self.isServer and not self.isReloading then
		local v18_ = self.spec_tipOcclusionAreas
		if v18_.updateTipOcclusionAreasOnDelete then
			self:updateTipOcclusionAreas()
			v18_.updateTipOcclusionAreasOnDelete = false
		end
	end
end

-- Local values: startNode, endNode, startX, _, startZ, endX, _, endZ, sizeX, sizeZ
function PlaceableTipOcclusionAreas:loadTipOcclusionArea(xmlFile, key, area)
	local v23_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	local v24_ = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
	if v23_ == nil then
		Logging.xmlWarning(xmlFile, "Missing tip occlusion update area start node for \'%s\'", key)
		return false
	end
	if v24_ == nil then
		Logging.xmlWarning(xmlFile, "Missing tip occlusion update area end node for \'%s\'", key)
		return false
	end
	local v25_, _, v26_ = localToLocal(v23_, self.rootNode, 0, 0, 0)
	local v27_, _, v28_ = localToLocal(v24_, self.rootNode, 0, 0, 0)
	local v29_ = v27_ - v25_
	local v30_ = math.abs(v29_)
	local v31_ = v28_ - v26_
	local v32_ = math.abs(v31_)
	area.center = {}
	area.center.x = (v27_ + v25_) * 0.5
	area.center.z = (v28_ + v26_) * 0.5
	area.size = {}
	area.size.x = v30_
	area.size.z = v32_
	area.startNode = v23_
	area.endNode = v24_
	return true
end

-- Local values: missionInfo, spec
function PlaceableTipOcclusionAreas:onFinalizePlacement()
	if self.isServer then
		local v34_ = g_currentMission.missionInfo
		if not (self.isLoadedFromSavegame and (v34_.isValid and (v34_:getIsTipCollisionValid(g_currentMission) and v34_:getIsPlacementCollisionValid(g_currentMission)))) then
			self:updateTipOcclusionAreas()
		end
		self.spec_tipOcclusionAreas.updateTipOcclusionAreasOnDelete = true
	end
end

-- Local values: spec, _, area, x, z, sizeX, sizeZ, x1, _, z1, x2, _, z2, x3, _, z3, x4, _, z4, minX, maxX, minZ, maxZ
function PlaceableTipOcclusionAreas:updateTipOcclusionAreas()
	if self.isServer then
		local v36_ = self.spec_tipOcclusionAreas
		for _, v37_ in pairs(v36_.areas) do
			local v38_ = v37_.center.x
			local v39_ = v37_.center.z
			local v40_ = v37_.size.x
			local v41_ = v37_.size.z
			local v42_, _, v43_ = localToWorld(self.rootNode, v38_ + v40_ * 0.5, 0, v39_ + v41_ * 0.5)
			local v44_, _, v45_ = localToWorld(self.rootNode, v38_ - v40_ * 0.5, 0, v39_ + v41_ * 0.5)
			local v46_, _, v47_ = localToWorld(self.rootNode, v38_ + v40_ * 0.5, 0, v39_ - v41_ * 0.5)
			local v48_, _, v49_ = localToWorld(self.rootNode, v38_ - v40_ * 0.5, 0, v39_ - v41_ * 0.5)
			local v50_ = math.min(v42_, v44_, v46_, v48_)
			local v51_ = math.max(v42_, v44_, v46_, v48_)
			local v52_ = math.min(v43_, v45_, v47_, v49_)
			local v53_ = math.max(v43_, v45_, v47_, v49_)
			g_densityMapHeightManager:setCollisionMapAreaDirty(v50_, v52_, v51_, v53_, true)
		end
	end
end
