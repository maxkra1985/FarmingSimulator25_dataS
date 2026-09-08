PlaceableAI = {}

function PlaceableAI.prerequisitesPresent(specializations)
	return true
end

function PlaceableAI.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "setObstacleActive", PlaceableAI.setObstacleActive)
	SpecializationUtil.registerFunction(placeableType, "loadAIUpdateArea", PlaceableAI.loadAIUpdateArea)
	SpecializationUtil.registerFunction(placeableType, "loadAISpline", PlaceableAI.loadAISpline)
	SpecializationUtil.registerFunction(placeableType, "loadAIObstacle", PlaceableAI.loadAIObstacle)
	SpecializationUtil.registerFunction(placeableType, "updateAIUpdateAreas", PlaceableAI.updateAIUpdateAreas)
end

function PlaceableAI.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAI)
	SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableAI)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAI)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableAI)
end

function PlaceableAI.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("AI")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.updateAreas.updateArea(?)#startNode", "Start node of ai update area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.updateAreas.updateArea(?)#endNode", "End node of ai update area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.splines.spline(?)#node", "Spline node or transform group containing splines. Spline direction not relevant")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.splines.spline(?)#maxWidth", "Maximum vehicle width supported by the spline")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.splines.spline(?)#maxHeight", "Maximum vehicle height supported by the spline")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.splines.spline(?)#maxTurningRadius", "Maximum vehicle turning supported by the spline")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.obstacles.obstacle(?)#node", "Node to be used for obstacle box", nil, true)
	schema:register(XMLValueType.VECTOR_3, basePath .. ".ai.obstacles.obstacle(?)#size", "Obstacle box size as x y z vector, required if node is not a rigid body")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".ai.obstacles.obstacle(?)#offset", "Obstacle box offset to node as x y z vector")
	schema:register(XMLValueType.INT, basePath .. ".ai.obstacles.obstacle(?).animatedObject#index", "Index of corresponding animated object in xml, can be used instead of \'saveId\'", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".ai.obstacles.obstacle(?).animatedObject#saveId", "SaveId of corresponding animated object in xml, can be used instead of \'index\'", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.obstacles.obstacle(?).animatedObject#startTime", "Normalized start time to activate obstacle", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.obstacles.obstacle(?).animatedObject#endTime", "Normalized end time to deactivate obstacle", nil, true)
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile
function PlaceableAI:onLoad(savegame)
	local v_u_6_ = self.spec_ai
	local v_u_7_ = self.xmlFile
	v_u_6_.updateAreaOnDelete = false
	v_u_6_.areas = {}
	v_u_7_:iterate("placeable.ai.updateAreas.updateArea", function(_, p8_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v9_ = {}
		if self:loadAIUpdateArea(v_u_7_, p8_, v9_) then
			local v10_ = v_u_6_.areas
			table.insert(v10_, v9_)
		end
	end)
	if not self.xmlFile:hasProperty("placeable.ai.updateAreas") then
		Logging.xmlWarning(self.xmlFile, "Missing ai update areas")
	end
	v_u_6_.splines = {}
	v_u_7_:iterate("placeable.ai.splines.spline", function(_, p11_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v12_ = {}
		if self:loadAISpline(v_u_7_, p11_, v12_) then
			local v13_ = v_u_6_.splines
			table.insert(v13_, v12_)
		end
	end)
	v_u_6_.obstacles = {}
	v_u_7_:iterate("placeable.ai.obstacles.obstacle", function(_, p14_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v15_ = {}
		if self:loadAIObstacle(v_u_7_, p14_, v15_) then
			local v16_ = v_u_6_.obstacles
			table.insert(v16_, v15_)
		end
	end)
end

-- Local values: spec, animatedObjects, obstacleIndex, obstacle, animatedObject
function PlaceableAI:onPostLoad(savegame)
	local v18_ = self.spec_ai
	if self.spec_animatedObjects == nil or (g_currentMission.aiSystem == nil or g_currentMission.aiSystem.navigationMap == nil) then
		::l2::
		return
	end
	local v19_ = self.spec_animatedObjects.animatedObjects
	for v20_, v_u_21_ in ipairs(v18_.obstacles) do
		local v22_
		if v_u_21_.animatedObjectIndex == nil then
			v22_ = self.spec_animatedObjects:getAnimatedObjectBySaveId(v_u_21_.animatedObjectSaveId)
			if v22_ == nil then
				Logging.warning("Placeable AI obstacle %d: AnimatedObject with saveId %q does not exist", v20_, v_u_21_.animatedObjectSaveId)
			else
				::l10::
				v_u_21_.animatedObject = v22_
				function v_u_21_.updateState(_, p23_, _)
					-- upvalues: (copy) v_u_21_, (copy) self
					if v_u_21_.animatedObjectTimeStart <= p23_ and p23_ <= v_u_21_.animatedObjectTimeEnd then
						if not v_u_21_.isActive then
							self:setObstacleActive(v_u_21_, true)
							return
						end
					elseif v_u_21_.isActive then
						self:setObstacleActive(v_u_21_, false)
					end
				end
				v22_.setAnimTime = Utils.appendedFunction(v22_.setAnimTime, v_u_21_.updateState)
			end
		else
			v22_ = v19_[v_u_21_.animatedObjectIndex]
			if v22_ ~= nil then
				goto l10
			end
			Logging.warning("Placeable AI obstacle %d: AnimatedObject with index %d does not exist", v20_, v_u_21_.animatedObjectIndex)
		end
	end
	goto l2
end

-- Local values: spec, _, spline, animatedObjects, _, obstacle
function PlaceableAI:onDelete()
	if self.isServer then
		local v25_ = self.spec_ai
		if v25_.updateAreaOnDelete then
			self:updateAIUpdateAreas()
		end
		if g_currentMission.aiSystem ~= nil then
			if v25_.splines ~= nil then
				for _, v26_ in pairs(v25_.splines) do
					g_currentMission.aiSystem:removeRoadSpline(v26_.splineNode)
				end
			end
			if self.spec_animatedObjects ~= nil and (g_currentMission.aiSystem.navigationMap ~= nil and self.spec_animatedObjects.animatedObjects ~= nil) then
				for _, v27_ in ipairs(v25_.obstacles) do
					if v27_.isActive then
						self:setObstacleActive(v27_, false)
					end
				end
			end
		end
	end
end

-- Local values: startNode, endNode, startX, _, startZ, endX, _, endZ, sizeX, sizeZ
function PlaceableAI:loadAIUpdateArea(xmlFile, key, area)
	local v32_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	local v33_ = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
	if v32_ == nil then
		Logging.xmlWarning(xmlFile, "Missing ai update area start node for \'%s\'", key)
		return false
	end
	if v33_ == nil then
		Logging.xmlWarning(xmlFile, "Missing ai update area end node for \'%s\'", key)
		return false
	end
	local v34_, _, v35_ = localToLocal(v32_, self.rootNode, 0, 0, 0)
	local v36_, _, v37_ = localToLocal(v33_, self.rootNode, 0, 0, 0)
	local v38_ = v36_ - v34_
	local v39_ = math.abs(v38_)
	local v40_ = v37_ - v35_
	local v41_ = math.abs(v40_)
	area.center = {}
	area.center.x = (v36_ + v34_) * 0.5
	area.center.z = (v37_ + v35_) * 0.5
	area.size = {}
	area.size.x = v39_
	area.size.z = v41_
	area.startNode = v32_
	area.endNode = v33_
	return true
end

-- Local values: splineNode, maxWidth, maxHeight, maxTurningRadius
function PlaceableAI:loadAISpline(xmlFile, key, spline)
	local v46_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v46_ == nil then
		Logging.xmlWarning(xmlFile, "Spline node does not exist in \'%s\'", key)
		return false
	end
	setVisibility(v46_, false)
	local v47_ = xmlFile:getValue(key .. "#maxWidth")
	local v48_ = xmlFile:getValue(key .. "#maxHeight")
	local v49_ = xmlFile:getValue(key .. "#maxTurningRadius")
	spline.splineNode = v46_
	spline.maxWidth = v47_
	spline.maxHeight = v48_
	spline.maxTurningRadius = v49_
	return true
end

function PlaceableAI:loadAIObstacle(xmlFile, key, obstacle)
	obstacle.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if obstacle.node == nil then
		Logging.xmlWarning(xmlFile, "Obstacle \'%s\' node does not exist", key)
		return false
	else
		obstacle.size = xmlFile:getValue(key .. "#size", "0 0 0", true)
		obstacle.offset = xmlFile:getValue(key .. "#offset", "0 0 0", true)
		if getRigidBodyType(obstacle.node) == RigidBodyType.NONE and obstacle.size[1] == 0 then
			Logging.xmlWarning(xmlFile, "Obstacle \'%s\' is not a rigid body and needs a size", key)
			return false
		else
			obstacle.animatedObjectSaveId = xmlFile:getValue(key .. ".animatedObject#saveId")
			if obstacle.animatedObjectSaveId == nil then
				obstacle.animatedObjectIndex = xmlFile:getValue(key .. ".animatedObject#index")
				if obstacle.animatedObjectIndex == nil then
					Logging.xmlWarning(xmlFile, "Obstacle \'%s\' does specify \'index\' or \'saveId\' attribute, one needs to be present to identify the animated object", key)
					return false
				end
			end
			obstacle.animatedObjectTimeStart = xmlFile:getValue(key .. ".animatedObject#startTime")
			obstacle.animatedObjectTimeEnd = xmlFile:getValue(key .. ".animatedObject#endTime")
			if obstacle.animatedObjectTimeStart == nil or obstacle.animatedObjectTimeEnd == nil then
				Logging.xmlWarning(xmlFile, "Obstacle \'%s\' is missing start or end time", key)
				return false
			elseif obstacle.animatedObjectTimeStart >= obstacle.animatedObjectTimeEnd then
				Logging.xmlWarning(xmlFile, "Obstacle \'%s\' start time need to be smaller than end time", key)
				return false
			else
				obstacle.isActive = false
				return true
			end
		end
	end
end

-- Local values: spec, missionInfo, _, spline, _, obstacle
function PlaceableAI:onFinalizePlacement()
	if self.isServer then
		local v55_ = self.spec_ai
		local v56_ = g_currentMission.missionInfo
		v55_.updateAreaOnDelete = true
		if not self.isLoadedFromSavegame or (not v56_.isValid or g_currentMission.placeableSystem.isReloadRunning) then
			self:updateAIUpdateAreas()
		end
		if g_currentMission.aiSystem ~= nil then
			for _, v57_ in ipairs(v55_.splines) do
				g_currentMission.aiSystem:addRoadSpline(v57_.splineNode, v57_.maxWidth, v57_.maxTurningRadius, v57_.maxHeight)
			end
			if g_currentMission.aiSystem.navigationMap ~= nil then
				for _, v58_ in ipairs(v55_.obstacles) do
					if v58_.animatedObject ~= nil then
						v58_.updateState(nil, v58_.animatedObject.animation.time)
					end
				end
			end
		end
	end
end

function PlaceableAI:setObstacleActive(obstacle, active)
	if g_currentMission.aiSystem ~= nil then
		if active then
			g_currentMission.aiSystem:addObstacle(obstacle.node, obstacle.offset[1], obstacle.offset[2], obstacle.offset[3], obstacle.size[1], obstacle.size[2], obstacle.size[3], 0, false)
		else
			g_currentMission.aiSystem:removeObstacle(obstacle.node)
		end
		obstacle.isActive = active
	end
end

-- Local values: spec, _, area, x, z, sizeX, sizeZ, x1, _, z1, x2, _, z2, x3, _, z3, x4, _, z4, minX, maxX, minZ, maxZ
function PlaceableAI:updateAIUpdateAreas()
	if self.isServer then
		local v62_ = self.spec_ai
		for _, v63_ in pairs(v62_.areas) do
			local v64_ = v63_.center.x
			local v65_ = v63_.center.z
			local v66_ = v63_.size.x
			local v67_ = v63_.size.z
			local v68_, _, v69_ = localToWorld(self.rootNode, v64_ + v66_ * 0.5, 0, v65_ + v67_ * 0.5)
			local v70_, _, v71_ = localToWorld(self.rootNode, v64_ - v66_ * 0.5, 0, v65_ + v67_ * 0.5)
			local v72_, _, v73_ = localToWorld(self.rootNode, v64_ + v66_ * 0.5, 0, v65_ - v67_ * 0.5)
			local v74_, _, v75_ = localToWorld(self.rootNode, v64_ - v66_ * 0.5, 0, v65_ - v67_ * 0.5)
			local v76_ = math.min(v68_, v70_, v72_, v74_)
			local v77_ = math.max(v68_, v70_, v72_, v74_)
			local v78_ = math.min(v69_, v71_, v73_, v75_)
			local v79_ = math.max(v69_, v71_, v73_, v75_)
			g_currentMission.aiSystem:setAreaDirty(v76_, v77_, v78_, v79_)
		end
	end
end
