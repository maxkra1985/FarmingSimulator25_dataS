VineDetector = {}
function VineDetector.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("VineDetector")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.vineDetector.raycast#node", "Raycast node")
	v1_:register(XMLValueType.FLOAT, "vehicle.vineDetector.raycast#maxDistance", "Max raycast distance", 1)
	v1_:setXMLSpecializationType()
end

function VineDetector.prerequisitesPresent(self)
	return true
end

function VineDetector.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "raycastCallbackVineDetection", VineDetector.raycastCallbackVineDetection)
	SpecializationUtil.registerFunction(vehicleType, "finishedVineDetection", VineDetector.finishedVineDetection)
	SpecializationUtil.registerFunction(vehicleType, "clearCurrentVinePlaceable", VineDetector.clearCurrentVinePlaceable)
	SpecializationUtil.registerFunction(vehicleType, "cancelVineDetection", VineDetector.cancelVineDetection)
	SpecializationUtil.registerFunction(vehicleType, "getIsValidVinePlaceable", VineDetector.getIsValidVinePlaceable)
	SpecializationUtil.registerFunction(vehicleType, "handleVinePlaceable", VineDetector.handleVinePlaceable)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartVineDetection", VineDetector.getCanStartVineDetection)
	SpecializationUtil.registerFunction(vehicleType, "getFirstVineHitPosition", VineDetector.getFirstVineHitPosition)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentVineHitPosition", VineDetector.getCurrentVineHitPosition)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentVineHitDistance", VineDetector.getCurrentVineHitDistance)
end

function VineDetector.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", VineDetector)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", VineDetector)
end

-- Local values: spec
function VineDetector:onLoad(savegame)
	local v5_ = self.spec_vineDetector
	v5_.raycast = {}
	v5_.raycast.node = self.xmlFile:getValue("vehicle.vineDetector.raycast#node", nil, self.components, self.i3dMappings)
	if v5_.raycast.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing vine detector raycast node")
	end
	v5_.raycast.maxDistance = self.xmlFile:getValue("vehicle.vineDetector.raycast#maxDistance", 1)
	v5_.raycast.vineNode = nil
	v5_.raycast.isRaycasting = false
	v5_.raycast.firstHitPosition = { 0, 0, 0 }
	v5_.raycast.currentHitPosition = { 0, 0, 0 }
	v5_.raycast.currentHitDistance = 0
	v5_.raycast.currentNode = nil
	v5_.isVineDetectionActive = false
end

-- Local values: spec, x, y, z, dx, dy, dz
function VineDetector:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v7_ = self.spec_vineDetector
	if self.isServer and v7_.raycast.node ~= nil then
		if self:getCanStartVineDetection() then
			v7_.isVineDetectionActive = true
			if not v7_.raycast.isRaycasting then
				v7_.raycast.isRaycasting = true
				local v8_, v9_, v10_ = getWorldTranslation(v7_.raycast.node)
				local v11_, v12_, v13_ = localDirectionToWorld(v7_.raycast.node, 0, -1, 0)
				raycastAllAsync(v8_, v9_, v10_, v11_, v12_, v13_, v7_.raycast.maxDistance, "raycastCallbackVineDetection", self, CollisionFlag.STATIC_OBJECT)
				return
			end
		elseif v7_.isVineDetectionActive then
			self:clearCurrentVinePlaceable()
			self:finishedVineDetection()
			v7_.isVineDetectionActive = false
		end
	end
end

-- Local values: spec, placeable
function VineDetector:raycastCallbackVineDetection(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
	if hitActorId == 0 then
		self:clearCurrentVinePlaceable()
		self:finishedVineDetection()
		return
	else
		if VehicleDebug.state == VehicleDebug.DEBUG then
			DebugGizmo.renderAtPositionSimple(x, y, z, string.format("hitActorId %s (%s); hitShape %s (%s)", getName(hitActorId), hitActorId, getName(hitShapeId), hitShapeId))
		end
		if self.spec_vineDetector.raycast.isRaycasting then
			local v22_ = g_currentMission.vineSystem:getPlaceable(hitActorId)
			if self:getIsValidVinePlaceable(v22_) and g_currentMission.nodeToObject[hitActorId] ~= self then
				if self:handleVinePlaceable(hitActorId, v22_, x, y, z, distance) then
					self:finishedVineDetection()
					return false
				end
				if not isLast then
					return true
				end
				self:finishedVineDetection()
				return false
			else
				if not isLast then
					return true
				end
				self:clearCurrentVinePlaceable()
				self:finishedVineDetection()
				return false
			end
		else
			self:cancelVineDetection()
			return false
		end
	end
end

-- Local values: spec
function VineDetector:finishedVineDetection()
	self.spec_vineDetector.raycast.isRaycasting = false
end

function VineDetector.getCanStartVineDetection(self)
	return true
end

-- Local values: spec, raycast
function VineDetector:getFirstVineHitPosition()
	local v25_ = self.spec_vineDetector.raycast
	return v25_.firstHitPosition[1], v25_.firstHitPosition[2], v25_.firstHitPosition[3]
end

-- Local values: spec, raycast
function VineDetector:getCurrentVineHitPosition()
	local v27_ = self.spec_vineDetector.raycast
	return v27_.currentHitPosition[1], v27_.currentHitPosition[2], v27_.currentHitPosition[3]
end

function VineDetector:getCurrentVineHitDistance()
	return self.spec_vineDetector.raycast.currentHitDistance
end

-- Local values: spec, raycast
function VineDetector:clearCurrentVinePlaceable()
	local v30_ = self.spec_vineDetector.raycast
	v30_.currentNode = nil
	v30_.placeable = nil
end

-- Local values: spec, raycast
function VineDetector:cancelVineDetection()
	local v32_ = self.spec_vineDetector.raycast
	v32_.currentNode = nil
	v32_.placeable = nil
	self:finishedVineDetection()
end

function VineDetector:getIsValidVinePlaceable(vinePlaceable)
	return vinePlaceable ~= nil
end

-- Local values: spec, raycast
function VineDetector:handleVinePlaceable(node, placeable, x, y, z, distance)
	local v41_ = self.spec_vineDetector.raycast
	if v41_.currentNode ~= node then
		local v42_ = v41_.firstHitPosition
		local v43_ = v41_.firstHitPosition
		local v44_ = v41_.firstHitPosition
		v42_[1] = x
		v43_[2] = y
		v44_[3] = z
	end
	v41_.currentNode = node
	local v45_ = v41_.currentHitPosition
	local v46_ = v41_.currentHitPosition
	local v47_ = v41_.currentHitPosition
	v45_[1] = x
	v46_[2] = y
	v47_[3] = z
	v41_.currentHitDistance = distance
	v41_.placeable = placeable
	return true
end
