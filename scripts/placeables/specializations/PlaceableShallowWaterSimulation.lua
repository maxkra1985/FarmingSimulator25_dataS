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
	basePath = basePath .. ".shallowWaterSimulation"
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".waterPlane(?)#node", "water plane shape to add to the shallow water simulation")
	schema:register(XMLValueType.STRING, basePath .. ".waterPlane(?)#materialName", "optional material name of a registered material to apply onto the shape, otherwise the material already present will be kept")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".obstacle(?)#node", "Obstacle node")
	ObstacleType.registerXMLPath(schema, basePath .. ".obstacle(?)#type", "Obstacle Type", "RECTANGLE", false)
	schema:register(XMLValueType.VECTOR_3, basePath .. ".obstacle(?)#size", "Size of the obstacle in m", "1 1 1")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".obstacle(?)#offset", "Offset of the obstacle in local space", "0 0 0")
	schema:setXMLSpecializationType()
end
function PlaceableShallowWaterSimulation:onLoad(savegame)
	local spec = self.spec_shallowWaterSimulation
	if g_currentMission.shallowWaterSimulation == nil then
		return
	end
	if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		return
	end
	for _, waterPlaneKey in self.xmlFile:iterator("placeable.shallowWaterSimulation.waterPlane") do
		local waterPlane = self.xmlFile:getValue(waterPlaneKey .. "#node", nil, self.components, self.i3dMappings)
		if waterPlane == nil then
			continue
		end
		local materialName = self.xmlFile:getValue(waterPlaneKey .. "#materialName", nil)
		if materialName ~= nil then
			local waterSimMat = g_materialManager:getBaseMaterialByName(materialName)
			if waterSimMat == nil then
				Logging.xmlError(self.xmlFile, "Unable to retrieve material %s for water plane %q at %q", materialName, getName(waterPlane), waterPlaneKey)
			else
				setMaterial(waterPlane, waterSimMat, 0)
			end
		end
		spec.waterPlanes = spec.waterPlanes or {}
		if g_currentMission.shallowWaterSimulation:addWaterPlane(waterPlane) then
			g_currentMission.shallowWaterSimulation:addAreaGeometry(waterPlane)
			table.insert(spec.waterPlanes, waterPlane)
		end
	end
	for _, key in self.xmlFile:iterator("placeable.shallowWaterSimulation.obstacle") do
		local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		if node == nil then
			Logging.xmlWarning(self.xmlFile, "Missing node for obstacle node '%s'", key)
		else
			local type = ObstacleType.loadFromXMLFile(self.xmlFile, key .. "#type") or ObstacleType.RECTANGLE
			local size = self.xmlFile:getValue(key .. "#size", "1 1 1", true)
			local offset = self.xmlFile:getValue(key .. "#offset", nil, true)
			local xDir, _, zDir = localDirectionToWorld(node, 0, 0, 1)
			local rotY = MathUtil.getYRotationFromDirection(xDir, zDir)
			local obstacle = g_currentMission.shallowWaterSimulation:addObstacle(node, size[1], size[2], size[3], nil, nil, offset, rotY, type)
			if obstacle == nil then
				continue
			end
			spec.obstacles = spec.obstacles or {}
			table.insert(spec.obstacles, obstacle)
		end
	end
end
function PlaceableShallowWaterSimulation:onFinalizePlacement()
	local spec = self.spec_shallowWaterSimulation
	if spec.obstacles ~= nil then
		for k, obstacle in ipairs_reverse(spec.obstacles) do
			if getVisibility(obstacle.node) then
				continue
			end
			g_currentMission.shallowWaterSimulation:removeObstacle(obstacle)
			table.remove(spec.obstacles, k)
		end
	end
end
function PlaceableShallowWaterSimulation:onDelete()
	local spec = self.spec_shallowWaterSimulation
	if spec.waterPlanes ~= nil then
		for _, waterPlane in ipairs(spec.waterPlanes) do
			g_currentMission.shallowWaterSimulation:removeAreaGeometry(waterPlane)
			g_currentMission.shallowWaterSimulation:removeWaterPlane(waterPlane)
		end
		spec.waterPlanes = nil
	end
	if spec.obstacles ~= nil then
		for _, obstacle in ipairs(spec.obstacles) do
			g_currentMission.shallowWaterSimulation:removeObstacle(obstacle)
		end
		spec.obstacles = nil
	end
end
