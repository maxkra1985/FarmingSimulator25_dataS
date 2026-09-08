PlaceableShallowWaterSimulation = {}

function PlaceableShallowWaterSimulation.prerequisitesPresent(specializations)
	return true
end

function PlaceableShallowWaterSimulation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableShallowWaterSimulation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableShallowWaterSimulation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableShallowWaterSimulation)
end

function PlaceableShallowWaterSimulation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ShallowWaterSimulation")
	local v4_ = basePath .. ".shallowWaterSimulation"
	schema:register(XMLValueType.NODE_INDEX, v4_ .. ".waterPlane(?)#node", "water plane shape to add to the shallow water simulation")
	schema:register(XMLValueType.STRING, v4_ .. ".waterPlane(?)#materialName", "optional material name of a registered material to apply onto the shape, otherwise the material already present will be kept")
	schema:register(XMLValueType.NODE_INDEX, v4_ .. ".obstacle(?)#node", "Obstacle node")
	ObstacleType.registerXMLPath(schema, v4_ .. ".obstacle(?)#type", "Obstacle Type", "RECTANGLE", false)
	schema:register(XMLValueType.VECTOR_3, v4_ .. ".obstacle(?)#size", "Size of the obstacle in m", "1 1 1")
	schema:register(XMLValueType.VECTOR_TRANS, v4_ .. ".obstacle(?)#offset", "Offset of the obstacle in local space", "0 0 0")
	schema:setXMLSpecializationType()
end

-- Local values: spec, _, waterPlaneKey, waterPlane, materialName, waterSimMat, _, key, node, type, size, offset, xDir, _, zDir, rotY, obstacle
function PlaceableShallowWaterSimulation:onLoad(savegame)
	local v6_ = self.spec_shallowWaterSimulation
	if g_currentMission.shallowWaterSimulation == nil then
		return
	elseif self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		for _, v7_ in self.xmlFile:iterator("placeable.shallowWaterSimulation.waterPlane") do
			local v8_ = self.xmlFile:getValue(v7_ .. "#node", nil, self.components, self.i3dMappings)
			if v8_ ~= nil then
				local v9_ = self.xmlFile:getValue(v7_ .. "#materialName", nil)
				if v9_ ~= nil then
					local v10_ = g_materialManager:getBaseMaterialByName(v9_)
					if v10_ == nil then
						Logging.xmlError(self.xmlFile, "Unable to retrieve material %s for water plane %q at %q", v9_, getName(v8_), v7_)
					else
						setMaterial(v8_, v10_, 0)
					end
				end
				v6_.waterPlanes = v6_.waterPlanes or {}
				if g_currentMission.shallowWaterSimulation:addWaterPlane(v8_) then
					g_currentMission.shallowWaterSimulation:addAreaGeometry(v8_)
					local v11_ = v6_.waterPlanes
					table.insert(v11_, v8_)
				end
			end
		end
		for _, v12_ in self.xmlFile:iterator("placeable.shallowWaterSimulation.obstacle") do
			local v13_ = self.xmlFile:getValue(v12_ .. "#node", nil, self.components, self.i3dMappings)
			if v13_ == nil then
				Logging.xmlWarning(self.xmlFile, "Missing node for obstacle node \'%s\'", v12_)
			else
				local v14_ = ObstacleType.loadFromXMLFile(self.xmlFile, v12_ .. "#type") or ObstacleType.RECTANGLE
				local v15_ = self.xmlFile:getValue(v12_ .. "#size", "1 1 1", true)
				local v16_ = self.xmlFile:getValue(v12_ .. "#offset", nil, true)
				local v17_, _, v18_ = localDirectionToWorld(v13_, 0, 0, 1)
				local v19_ = MathUtil.getYRotationFromDirection(v17_, v18_)
				local v20_ = g_currentMission.shallowWaterSimulation:addObstacle(v13_, v15_[1], v15_[2], v15_[3], nil, nil, v16_, v19_, v14_)
				if v20_ ~= nil then
					v6_.obstacles = v6_.obstacles or {}
					local v21_ = v6_.obstacles
					table.insert(v21_, v20_)
				end
			end
		end
	end
end

-- Local values: spec, k, obstacle
function PlaceableShallowWaterSimulation:onFinalizePlacement()
	local v23_ = self.spec_shallowWaterSimulation
	if v23_.obstacles ~= nil then
		for v24_, v25_ in ipairs_reverse(v23_.obstacles) do
			if not getVisibility(v25_.node) then
				g_currentMission.shallowWaterSimulation:removeObstacle(v25_)
				table.remove(v23_.obstacles, v24_)
			end
		end
	end
end

-- Local values: spec, _, waterPlane, _, obstacle
function PlaceableShallowWaterSimulation:onDelete()
	local v27_ = self.spec_shallowWaterSimulation
	if v27_.waterPlanes ~= nil then
		for _, v28_ in ipairs(v27_.waterPlanes) do
			g_currentMission.shallowWaterSimulation:removeAreaGeometry(v28_)
			g_currentMission.shallowWaterSimulation:removeWaterPlane(v28_)
		end
		v27_.waterPlanes = nil
	end
	if v27_.obstacles ~= nil then
		for _, v29_ in ipairs(v27_.obstacles) do
			g_currentMission.shallowWaterSimulation:removeObstacle(v29_)
		end
		v27_.obstacles = nil
	end
end
