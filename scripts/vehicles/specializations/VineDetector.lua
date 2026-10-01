VineDetector = {}
function VineDetector.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("VineDetector")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.vineDetector.raycast#node", "Raycast node")
	schema:register(XMLValueType.FLOAT, "vehicle.vineDetector.raycast#maxDistance", "Max raycast distance", 1)
	schema:setXMLSpecializationType()
end
function VineDetector.prerequisitesPresent(specializations)
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
function VineDetector:onLoad(savegame)
	local spec = self.spec_vineDetector
	spec.raycast = {}
	spec.raycast.node = self.xmlFile:getValue("vehicle.vineDetector.raycast#node", nil, self.components, self.i3dMappings)
	if spec.raycast.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing vine detector raycast node")
	end
	spec.raycast.maxDistance = self.xmlFile:getValue("vehicle.vineDetector.raycast#maxDistance", 1)
	spec.raycast.vineNode = nil
	spec.raycast.isRaycasting = false
	spec.raycast.firstHitPosition = { 0, 0, 0 }
	spec.raycast.currentHitPosition = { 0, 0, 0 }
	spec.raycast.currentHitDistance = 0
	spec.raycast.currentNode = nil
	spec.isVineDetectionActive = false
end
function VineDetector:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_vineDetector
	if self.isServer and spec.raycast.node ~= nil then
		if self:getCanStartVineDetection() then
			spec.isVineDetectionActive = true
			if not spec.raycast.isRaycasting then
				spec.raycast.isRaycasting = true
				local x, y, z = getWorldTranslation(spec.raycast.node)
				local dx, dy, dz = localDirectionToWorld(spec.raycast.node, 0, -1, 0)
				raycastAllAsync(x, y, z, dx, dy, dz, spec.raycast.maxDistance, "raycastCallbackVineDetection", self, CollisionFlag.STATIC_OBJECT)
			end
		elseif spec.isVineDetectionActive then
			self:clearCurrentVinePlaceable()
			self:finishedVineDetection()
			spec.isVineDetectionActive = false
		end
	end
end
function VineDetector:raycastCallbackVineDetection(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
	if hitActorId ~= 0 then
		if VehicleDebug.state == VehicleDebug.DEBUG then
			DebugGizmo.renderAtPositionSimple(x, y, z, string.format("hitActorId %s (%s); hitShape %s (%s)", getName(hitActorId), hitActorId, getName(hitShapeId), hitShapeId))
		end
		local spec = self.spec_vineDetector
		if not spec.raycast.isRaycasting then
			self:cancelVineDetection()
			return false
		end
		local placeable = g_currentMission.vineSystem:getPlaceable(hitActorId)
		if not self:getIsValidVinePlaceable(placeable) or g_currentMission.nodeToObject[hitActorId] == self then
			if isLast then
				self:clearCurrentVinePlaceable()
				self:finishedVineDetection()
				return false
			else
				return true
			end
		end
		if self:handleVinePlaceable(hitActorId, placeable, x, y, z, distance) then
			self:finishedVineDetection()
			return false
		elseif isLast then
			self:finishedVineDetection()
			return false
		else
			return true
		end
	end
	self:clearCurrentVinePlaceable()
	self:finishedVineDetection()
end
function VineDetector:finishedVineDetection()
	local spec = self.spec_vineDetector
	spec.raycast.isRaycasting = false
end
function VineDetector:getCanStartVineDetection()
	return true
end
function VineDetector:getFirstVineHitPosition()
	local spec = self.spec_vineDetector
	local raycast = spec.raycast
	return raycast.firstHitPosition[1], raycast.firstHitPosition[2], raycast.firstHitPosition[3]
end
function VineDetector:getCurrentVineHitPosition()
	local spec = self.spec_vineDetector
	local raycast = spec.raycast
	return raycast.currentHitPosition[1], raycast.currentHitPosition[2], raycast.currentHitPosition[3]
end
function VineDetector:getCurrentVineHitDistance()
	return self.spec_vineDetector.raycast.currentHitDistance
end
function VineDetector:clearCurrentVinePlaceable()
	local spec = self.spec_vineDetector
	local raycast = spec.raycast
	raycast.currentNode = nil
	raycast.placeable = nil
end
function VineDetector:cancelVineDetection()
	local spec = self.spec_vineDetector
	local raycast = spec.raycast
	raycast.currentNode = nil
	raycast.placeable = nil
	self:finishedVineDetection()
end
function VineDetector:getIsValidVinePlaceable(vinePlaceable)
	if vinePlaceable == nil then
		return false
	else
		return true
	end
end
function VineDetector:handleVinePlaceable(node, placeable, x, y, z, distance)
	local spec = self.spec_vineDetector
	local raycast = spec.raycast
	if raycast.currentNode ~= node then
		raycast.firstHitPosition[1] = x
		raycast.firstHitPosition[2] = y
		raycast.firstHitPosition[3] = z
	end
	raycast.currentNode = node
	raycast.currentHitPosition[1] = x
	raycast.currentHitPosition[2] = y
	raycast.currentHitPosition[3] = z
	raycast.currentHitDistance = distance
	raycast.placeable = placeable
	return true
end
