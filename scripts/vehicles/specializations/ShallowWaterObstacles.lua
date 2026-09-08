ShallowWaterObstacles = {}
ShallowWaterObstacles.OBSTACLE_NODE_XML_KEY = "vehicle.shallowWaterObstacle.obstacleNode(?)"

function ShallowWaterObstacles.prerequisitesPresent(specializations)
	return true
end
function ShallowWaterObstacles.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ShallowWaterObstacles")
	local v2_ = ShallowWaterObstacles.OBSTACLE_NODE_XML_KEY
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#node", "Obstacle node")
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#directionNode", "Node that is used as reference for the moving direction", "Same as #node")
	v1_:register(XMLValueType.VECTOR_3, v2_ .. "#size", "Size of the obstacle in m", "1 1 1")
	v1_:register(XMLValueType.VECTOR_TRANS, v2_ .. "#offset", "Offset of the obstacle in local space", "0 0 0")
	v1_:setXMLSpecializationType()
end

function ShallowWaterObstacles.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadObstacleNodeFromXML", ShallowWaterObstacles.loadObstacleNodeFromXML)
end

function ShallowWaterObstacles.registerEventListeners(vehicleType)
	if Platform.hasShallowWaterSimulation then
		SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ShallowWaterObstacles)
		SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ShallowWaterObstacles)
		SpecializationUtil.registerEventListener(vehicleType, "onDelete", ShallowWaterObstacles)
	end
end

-- Local values: spec, _, key, obstacleNode
function ShallowWaterObstacles:onPostLoad(savegame)
	local v6_ = self.spec_shallowWaterObstacles
	v6_.obstacleNodes = {}
	for _, v7_ in self.xmlFile:iterator("vehicle.shallowWaterObstacle.obstacleNode") do
		local v8_ = {}
		if self:loadObstacleNodeFromXML(self.xmlFile, v7_, v8_) then
			local v9_ = v6_.obstacleNodes
			table.insert(v9_, v8_)
			v8_.vehicle = self
			v8_.index = #v6_.obstacleNodes
		end
	end
	if #v6_.obstacleNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", ShallowWaterObstacles)
		SpecializationUtil.removeEventListener(self, "onDelete", ShallowWaterObstacles)
		v6_.obstacleNodes = nil
	end
end

-- Local values: spec, _, obstacleNode
function ShallowWaterObstacles:onLoadFinished(savegame)
	if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
		local v11_ = self.spec_shallowWaterObstacles
		for _, v12_ in ipairs(v11_.obstacleNodes) do
			v12_.shallowWaterObstacle = g_currentMission.shallowWaterSimulation:addObstacle(v12_.node, v12_.size[1], v12_.size[2], v12_.size[3], ShallowWaterObstacles.getShallowWaterParameters, v12_, v12_.offset)
		end
	end
end

-- Local values: spec, _, obstacleNode
function ShallowWaterObstacles:onDelete()
	local v14_ = self.spec_shallowWaterObstacles
	if v14_.obstacleNodes ~= nil then
		for _, v15_ in ipairs(v14_.obstacleNodes) do
			if v15_.shallowWaterObstacle ~= nil then
				g_currentMission.shallowWaterSimulation:removeObstacle(v15_.shallowWaterObstacle)
				v15_.shallowWaterObstacle = nil
			end
		end
	end
end

-- Local values: node
function ShallowWaterObstacles:loadObstacleNodeFromXML(xmlFile, key, obstacleNode)
	local v20_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v20_ == nil then
		Logging.xmlWarning(xmlFile, "Missing node for obstacle node \'%s\'", key)
		return false
	end
	obstacleNode.node = v20_
	obstacleNode.directionNode = xmlFile:getValue(key .. "#directionNode", v20_, self.components, self.i3dMappings)
	obstacleNode.size = xmlFile:getValue(key .. "#size", "1 1 1", true)
	obstacleNode.offset = xmlFile:getValue(key .. "#offset", nil, true)
	obstacleNode.lastWorldPosition = { 0, 0 }
	return true
end

-- Local values: velocity, wx, _, wz, dx, dz, length, hdx, _, hdz, yRot
function ShallowWaterObstacles.getShallowWaterParameters(obstacleNode)
	local v22_ = obstacleNode.vehicle.lastSignedSpeed * 1000
	local v23_, _, v24_ = getWorldTranslation(obstacleNode.node)
	local v25_ = v23_ - obstacleNode.lastWorldPosition[1]
	local v26_ = v24_ - obstacleNode.lastWorldPosition[2]
	local v27_ = MathUtil.vector2Length(v25_, v26_)
	local v28_, v29_
	if v27_ > 0 then
		v28_ = v25_ / v27_
		v29_ = v26_ / v27_
	else
		v28_ = 0
		v29_ = 0
	end
	local v30_ = obstacleNode.lastWorldPosition
	local v31_ = obstacleNode.lastWorldPosition
	v30_[1] = v23_
	v31_[2] = v24_
	local v32_, _, v33_ = localDirectionToWorld(obstacleNode.directionNode, 0, 0, 1)
	local v34_ = MathUtil.getYRotationFromDirection(v32_, v33_)
	return v28_ * v22_, v29_ * v22_, v34_
end
