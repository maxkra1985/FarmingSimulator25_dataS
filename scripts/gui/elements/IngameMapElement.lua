IngameMapElement = {}
local IngameMapElement_mt = Class(IngameMapElement, GuiElement)
Gui.registerGuiElement("InGameMap", IngameMapElement)
IngameMapElement.CURSOR_SPEED_FACTOR = 0.0006
IngameMapElement.BORDER_SCROLL_THRESHOLD = 0.03
IngameMapElement.MAP_ZOOM_SHOW_NAMES = Platform.isMobile and 0.5 or 0.8
function IngameMapElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or IngameMapElement_mt)
	self.ingameMap = nil
	self.cursorId = nil
	self.inputMode = GS_INPUT_HELP_MODE_GAMEPAD
	self.terrainSize = 0
	self.mapAlpha = 1
	self.zoomMin = 1
	self.zoomMax = 8
	self.zoomDefault = Platform.ingameMap.zoomDefault
	self.mapCenterX = 0.5
	self.mapCenterY = 0.5
	self.mapZoom = self.zoomDefault
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0
	self.accumZoomInput = 0
	self.useMouse = false
	self.resetMouseNextFrame = false
	self.cursorDeadzones = {}
	self.limitMapWidth = false
	self.limitCursorMovement = false
	self.mapMovementLocked = false
	self.zoomSpeedFactor = Platform.ingameMap.zoomSpeedFactor
	self.dragStartDistance = Platform.ingameMap.dragStartDistance
	self.minDragDistanceX = self.dragStartDistance * g_pixelSizeX
	self.minDragDistanceY = self.dragStartDistance * g_pixelSizeY
	self.hasDragged = false
	self.minimalHotspotSize = getNormalizedScreenValues(9, 1)
	self.isHotspotSelectionActive = true
	self.isCursorAvailable = true
	self.cursorOffsetX = 0
	self.cursorOffsetY = 0
	self.originalMapCenterX = 0.5
	self.originalMapCenterY = 0.5
	self.isPinching = false
	self.isTouchPickingRotation = false
	self.lastInputPosX = {}
	self.lastInputPosY = {}
	self.lastInputIndex = 0
	return self
end
function IngameMapElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)
	self.ingameMap = nil
	IngameMapElement:superClass().delete(self)
end
function IngameMapElement:loadFromXML(xmlFile, key)
	IngameMapElement:superClass().loadFromXML(self, xmlFile, key)
	self.cursorId = getXMLString(xmlFile, key .. "#cursorId")
	self.mapAlpha = getXMLFloat(xmlFile, key .. "#mapAlpha") or self.mapAlpha
	self.limitMapWidth = Utils.getNoNil(getXMLBool(xmlFile, key .. "#limitMapWidth"), self.limitMapWidth)
	self.limitCursorMovement = Utils.getNoNil(getXMLBool(xmlFile, key .. "#limitCursorMovement"), self.limitCursorMovement)
	self:addCallback(xmlFile, key .. "#onDrawPreIngameMap", "onDrawPreIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMap", "onDrawPostIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMapHotspots", "onDrawPostIngameMapHotspotsCallback")
	self:addCallback(xmlFile, key .. "#onClickHotspot", "onClickHotspotCallback")
	self:addCallback(xmlFile, key .. "#onClickMap", "onClickMapCallback")
end
function IngameMapElement:loadProfile(profile, applyProfile)
	IngameMapElement:superClass().loadProfile(self, profile, applyProfile)
	self.mapAlpha = profile:getNumber("mapAlpha", self.mapAlpha)
	self.limitMapWidth = profile:getBool("limitMapWidth", self.limitMapWidth)
	self.limitCursorMovement = profile:getBool("limitCursorMovement", self.limitCursorMovement)
end
function IngameMapElement:copyAttributes(src)
	IngameMapElement:superClass().copyAttributes(self, src)
	self.mapZoom = src.mapZoom
	self.mapAlpha = src.mapAlpha
	self.cursorId = src.cursorId
	self.limitMapWidth = src.limitMapWidth
	self.limitCursorMovement = src.limitCursorMovement
	self.onDrawPreIngameMapCallback = src.onDrawPreIngameMapCallback
	self.onDrawPostIngameMapCallback = src.onDrawPostIngameMapCallback
	self.onDrawPostIngameMapHotspotsCallback = src.onDrawPostIngameMapHotspotsCallback
	self.onClickHotspotCallback = src.onClickHotspotCallback
	self.onClickMapCallback = src.onClickMapCallback
end
function IngameMapElement:onGuiSetupFinished()
	IngameMapElement:superClass().onGuiSetupFinished(self)
	if self.cursorId ~= nil then
		if self.target[self.cursorId] ~= nil then
			self.cursorElement = self.target[self.cursorId]
			return
		end
		printWarning("Warning: CursorId '" .. self.cursorId .. "' not found for '" .. self.target.name .. "'!")
	end
end
function IngameMapElement:addCursorDeadzone(screenX, screenY, width, height)
	table.insert(self.cursorDeadzones, { screenX, screenY, width, height })
end
function IngameMapElement:clearCursorDeadzones()
	self.cursorDeadzones = {}
end
function IngameMapElement:isInputInDeadzones(inputScreenX, inputScreenY)
	for _, zone in pairs(self.cursorDeadzones) do
		if GuiUtils.checkOverlayOverlap(inputScreenX, inputScreenY, zone[1], zone[2], zone[3], zone[4]) then
			return true
		end
	end
	return false
end
function IngameMapElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = IngameMapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
		self.lastInputIndex = 0
		local index = 0
		if not GS_IS_CONSOLE_VERSION and (isDown or isUp or posX ~= self.lastInputPosX[index] or posY ~= self.lastInputPosY[index]) then
			self.useMouse = true
			if self.cursorElement then
				self.cursorElement:setVisible(false)
			end
			self.isCursorActive = false
		end
		if Platform.isMobile and (self.useMouse and isDown) then
			self.lastInputPosX[index] = posX
			self.lastInputPosY[index] = posY
		end
		if not eventUsed and (isDown and (button == Input.MOUSE_BUTTON_LEFT and not self:isInputInDeadzones(posX, posY))) then
			eventUsed = true
			if not self.inputDown then
				self.inputDown = true
			end
		end
		if self.inputDown and self.lastInputPosX[index] ~= nil then
			local distX = self.lastInputPosX[index] - posX
			local distY = posY - self.lastInputPosY[index]
			if self.isFixedHorizontal then
				distX = 0
			end
			if self.minDragDistanceX < math.abs(distX) or self.minDragDistanceY < math.abs(distY) then
				local factorX = -distX
				self:moveCenter(factorX, distY)
				self.hasDragged = true
			end
		end
		if isUp and button == Input.MOUSE_BUTTON_LEFT then
			if not eventUsed and (self.inputDown and not self.hasDragged) then
				local localX, localY = self:getLocalPosition(posX, posY)
				local isHotspotSelectionActive = self.isHotspotSelectionActive
				self:onClickMap(localX, localY)
				if isHotspotSelectionActive then
					self:selectHotspotAt(posX, posY)
				end
				eventUsed = true
			end
			self.inputDown = false
			self.hasDragged = false
		end
		self.lastInputPosX[index] = posX
		self.lastInputPosY[index] = posY
	end
	return eventUsed
end
function IngameMapElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() then
		eventUsed = IngameMapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
		self.lastInputIndex = touchId
		if isDown or isUp or posX ~= self.lastInputPosX[touchId] or posY ~= self.lastInputPosY[touchId] then
			if self.cursorElement then
				self.cursorElement:setVisible(false)
			end
			self.isCursorActive = false
		end
		if isDown then
			self.lastInputPosX[touchId] = posX
			self.lastInputPosY[touchId] = posY
		end
		if not eventUsed and (isDown and not self:isInputInDeadzones(posX, posY)) then
			eventUsed = true
			if not self.inputDown then
				self.inputDown = true
			end
		end
		if self.inputDown and self.lastInputPosX[touchId] ~= nil then
			local distX = self.lastInputPosX[touchId] - posX
			local distY = posY - self.lastInputPosY[touchId]
			if self.isFixedHorizontal then
				distX = 0
			end
			if self.isTouchPickingRotation then
				local aiButton = self.target.buttonConfirmAITarget
				local clickInButton = GuiUtils.checkOverlayOverlap(posX, posY, aiButton.absPosition[1], aiButton.absPosition[2], aiButton.size[1], aiButton.size[2])
				if not clickInButton then
					local localX, localY = self:getLocalPosition(posX, posY)
					self:onClickMap(localX, localY)
				end
			elseif self.minDragDistanceX < math.abs(distX) or self.minDragDistanceY < math.abs(distY) then
				local factorX = -distX
				self:moveCenter(factorX, distY)
				self.hasDragged = true
			end
		end
		if isUp then
			if not eventUsed and (self.inputDown and not self.hasDragged) then
				local localX, localY = self:getLocalPosition(posX, posY)
				local isHotspotSelectionActive = self.isHotspotSelectionActive
				self:onClickMap(localX, localY)
				if isHotspotSelectionActive then
					self:selectHotspotAt(posX, posY)
				end
				eventUsed = true
			end
			self.inputDown = false
			self.hasDragged = false
		end
		self.lastInputPosX[touchId] = posX
		self.lastInputPosY[touchId] = posY
	end
	return eventUsed
end
function IngameMapElement:lockMapMovement()
	self.mapMovementLocked = true
end
function IngameMapElement:unlockMapMovement()
	self.mapMovementLocked = false
	if not Platform.isMobile then
		self.cursorOffsetX = 0
		self.cursorOffsetY = 0
		local cursor = self.cursorElement
		cursor.absPosition[1] = self.originalMapCenterX - cursor.absSize[1] * 0.5
		cursor.absPosition[2] = self.originalMapCenterY - cursor.absSize[2] * 0.5
	end
end
function IngameMapElement:moveCenter(x, y)
	local width, height = self.ingameMap.fullScreenLayout:getMapSize()
	if Platform.isMobile then
		local maxCenterOffsetX = (width - self.ingameMap.fullScreenLayout.width) * 0.5
		local maxCenterOffsetY = (height - 1) * 0.5
		self.mapCenterX = math.clamp(self.mapCenterX + x, self.originalMapCenterX - maxCenterOffsetX, self.originalMapCenterX + maxCenterOffsetX)
		self.mapCenterY = math.clamp(self.mapCenterY + y, self.originalMapCenterY - maxCenterOffsetY, self.originalMapCenterY + maxCenterOffsetY)
	else
		self.mapCenterX = math.clamp(self.mapCenterX + x, width * -0.5 + self.originalMapCenterX, width * 0.5 + self.originalMapCenterX)
		if self.limitCursorMovement then
			local minValue = self.absPosition[2] + self.absSize[2] - height * 0.5
			local maxValue = self.absPosition[2] + height * 0.5
			self.mapCenterY = math.clamp(self.mapCenterY + y, minValue, maxValue)
		else
			self.mapCenterY = math.clamp(self.mapCenterY + y, height * -0.5 + self.originalMapCenterY, height * 0.5 + self.originalMapCenterY)
		end
	end
	self.ingameMap.fullScreenLayout:setMapCenter(self.mapCenterX, self.mapCenterY)
end
function IngameMapElement:panToHotspot(hotspot, extraOffsetX)
	if hotspot ~= nil then
		if Platform.isMobile then
			local hotspotX, hotspotY = self:worldToScreenPos(hotspot:getWorldPosition())
			local cursorOffsetX = -hotspotX + self.mapCenterX + self.originalMapCenterX
			local cursorOffsetY = -hotspotY + self.mapCenterY + self.originalMapCenterY
			self.cursorOffsetX = cursorOffsetX - self.mapCenterX
			self.cursorOffsetY = cursorOffsetY - self.mapCenterY
			return
		end
		local ingameMap = self.ingameMap
		local hotspotX, hotspotY = hotspot:getWorldPosition()
		local objectX = (hotspotX + ingameMap.worldCenterOffsetX) / ingameMap.worldSizeX * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX
		local objectZ = (hotspotY + ingameMap.worldCenterOffsetZ) / ingameMap.worldSizeZ * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetZ
		hotspotX, hotspotY = ingameMap.layout:getMapObjectPosition(objectX, objectZ, 0, 0)
		local offsetX = self.originalMapCenterX - hotspotX
		local offsetY = self.originalMapCenterY - hotspotY
		self:moveCenter(offsetX, offsetY)
	end
end
function IngameMapElement:copySettingsFromElement(element)
	local fullScreenLayout = self.ingameMap.fullScreenLayout
	self.mapZoom = element.mapZoom
	self.mapCenterX = element.mapCenterX
	self.mapCenterY = element.mapCenterY
	fullScreenLayout:setMapZoom(self.mapZoom)
	fullScreenLayout:setMapCenter(self.mapCenterX, self.mapCenterY)
end
function IngameMapElement:zoom(direction, zoomTarget)
	if not Platform.ingameMap.canZoom then
		return
	else
		local targetX, targetZ = self:localToWorldPos(self:getLocalPointerTarget())
		local width, height = self.ingameMap.fullScreenLayout:getMapSize()
		local oldZoom = self.mapZoom
		local speed = self.zoomSpeedFactor * direction * width
		if zoomTarget ~= nil then
			self.mapZoom = math.clamp(zoomTarget, self.zoomMin, self.zoomMax)
		else
			self.mapZoom = math.clamp(self.mapZoom + speed, self.zoomMin, self.zoomMax)
		end
		self.ingameMap.fullScreenLayout:setMapZoom(self.mapZoom)
		self:moveCenter(0, 0)
		if oldZoom ~= self.mapZoom then
			local newTargetX, newTargetZ = self:localToWorldPos(self:getLocalPointerTarget())
			local diffX = newTargetX - targetX
			local diffZ = newTargetZ - targetZ
			local dx = diffX / self.terrainSize * 0.5 * width
			local dy = -diffZ / self.terrainSize * 0.5 * height
			self.cursorOffsetX = self.cursorOffsetX + dx
			self.cursorOffsetY = self.cursorOffsetY + dy
			local mapLayout = self.ingameMap.fullScreenLayout
			local centerX = mapLayout.mapCenterX
			local centerY = mapLayout.mapCenterY
			self:moveCenter(dx, dy)
			local newCenterX = mapLayout.mapCenterX
			local newCenterY = mapLayout.mapCenterY
			if direction < 0 then
				self.cursorOffsetX = self.cursorOffsetX - newCenterX + centerX + dx
				self.cursorOffsetY = self.cursorOffsetY - newCenterY + centerY + dy
			end
		end
	end
end
function IngameMapElement:setLockedToBorder(yOffset, height)
	self.yOffset = yOffset
	self.height = height
	self.lockedToBorder = true
end
function IngameMapElement:update(dt)
	IngameMapElement:superClass().update(self, dt)
	self.inputMode = g_inputBinding:getLastInputMode()
	if not g_gui:getIsDialogVisible() and not self.alreadyClosed then
		local zoomFactor = self.accumZoomInput
		if not self.isPinching then
			zoomFactor = math.clamp(zoomFactor, -1, 1)
		end
		if zoomFactor ~= 0 then
			self:zoom(zoomFactor * -0.015 * dt)
		end
		if self.cursorElement ~= nil then
			self.isCursorActive = self.inputMode == GS_INPUT_HELP_MODE_GAMEPAD
			self.cursorElement:setVisible(self.isCursorAvailable and self.isCursorActive)
			self:updateCursor(self.accumHorizontalInput, -self.accumVerticalInput, dt)
			self.useMouse = false
		end
	end
	self:resetFrameInputState()
end
function IngameMapElement:resetFrameInputState()
	self.accumZoomInput = 0
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0
	if self.resetMouseNextFrame then
		self.useMouse = false
		self.resetMouseNextFrame = false
	end
	if Platform.isMobile and self.isPinching then
		self.cursorElement.absPosition[1] = self.originalMapCenterX + self.cursorOffsetX
		self.cursorElement.absPosition[2] = self.originalMapCenterY + self.cursorOffsetY
		self.isPinching = false
	end
end
function IngameMapElement:draw(clipX1, clipY1, clipX2, clipY2)
	self:raiseCallback("onDrawPreIngameMapCallback", self, self.ingameMap)
	self.ingameMap:drawMapOnly()
	self:raiseCallback("onDrawPostIngameMapCallback", self, self.ingameMap)
	self.ingameMap:drawHotspotsOnly()
	self:raiseCallback("onDrawPostIngameMapHotspotsCallback", self, self.ingameMap)
	IngameMapElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
function IngameMapElement:onOpen()
	IngameMapElement:superClass().onOpen(self)
	if self.cursorElement ~= nil then
		self.cursorElement:setVisible(false)
	end
	self.isCursorActive = false
	if self.largestSize == nil then
		self.largestSize = self.size
	end
	self.ingameMap:setFullscreen(true)
	if Platform.ingameMap.resetZoomOnOpen then
		self:zoom(0)
	end
end
function IngameMapElement:onClose()
	IngameMapElement:superClass().onClose(self)
	self:removeActionEvents()
	self.ingameMap:setFullscreen(false)
end
function IngameMapElement:reset()
	IngameMapElement:superClass().reset(self)
	self.mapCenterX = 0.5
	self.mapCenterY = 0.5
	self.mapZoom = self.zoomDefault
end
function IngameMapElement:updateCursor(deltaX, deltaY, dt)
	if self.cursorElement ~= nil then
		local speed = IngameMapElement.CURSOR_SPEED_FACTOR
		local diffX = deltaX * speed * dt / g_screenAspectRatio
		local diffY = deltaY * speed * dt
		if Platform.isMobile or self.mapMovementLocked then
			diffX = diffX - self.cursorOffsetX
			diffY = diffY - self.cursorOffsetY
			local oldX = self.mapCenterX
			local oldY = self.mapCenterY
			if not self.mapMovementLocked then
				self:moveCenter(-diffX, -diffY)
			end
			local newX = self.mapCenterX
			local newY = self.mapCenterY
			local cursorSize = self.cursorElement.absSize
			local _, width = self.ingameMap.fullScreenLayout:getMapSize()
			self.cursorOffsetX = oldX - newX - diffX
			self.cursorOffsetX = math.max(math.min(self.cursorOffsetX, width * 0.5 - cursorSize[1] * 0.5), -width * 0.5 + cursorSize[1] * 0.5)
			self.cursorOffsetY = oldY - newY - diffY
			self.cursorOffsetY = math.max(math.min(self.cursorOffsetY, 0.5 - cursorSize[2] * 0.5), -0.5 + cursorSize[2] * 0.5)
			if not Platform.isMobile and self.mapMovementLocked then
				local maxOffset = 250
				self.cursorOffsetX = math.clamp(self.cursorOffsetX, -250 * g_pixelSizeScaledX, maxOffset * g_pixelSizeScaledX)
				self.cursorOffsetY = math.clamp(self.cursorOffsetY, -250 * g_pixelSizeScaledY, maxOffset * g_pixelSizeScaledY)
			end
			local cursor = self.cursorElement
			cursor.absPosition[1] = self.originalMapCenterX - self.cursorOffsetX - cursor.absSize[1] * 0.5
			cursor.absPosition[2] = self.originalMapCenterY - self.cursorOffsetY - cursor.absSize[2] * 0.5
			return
		end
		self:moveCenter(-diffX, -diffY)
	end
end
function IngameMapElement:selectHotspotAt(posX, posY)
	if self.isHotspotSelectionActive then
		self.ingameMap:updateHotspotSorting()
		local sortedHotspots = self.ingameMap.hotspotsSorted
		if sortedHotspots ~= nil then
			local playerHotspot = self:getPlayerHotspot(sortedHotspots[true])
			local prioritizePlayerHotspot = not Platform.isMobile or playerHotspot:getVehicle() ~= nil
			if not self:selectHotspotFrom(sortedHotspots[prioritizePlayerHotspot], posX, posY) and prioritizePlayerHotspot then
				self:selectHotspotFrom(sortedHotspots[false], posX, posY)
			end
			return
		end
		self:selectHotspotFrom(self.ingameMap.hotspots, posX, posY)
	end
end
function IngameMapElement:selectHotspotFrom(hotspots, posX, posY)
	local minDistance = math.huge
	local minHotspot = nil
	for i = #hotspots, 1, -1 do
		local hotspot = hotspots[i]
		if self.ingameMap.filter[hotspot:getCategory()] and hotspot:getIsVisible() then
			local isInRange, distance = hotspot:hasMouseOverlap(posX, posY)
			if isInRange then
				if minHotspot == nil then
					minDistance = distance
					minHotspot = hotspot
				elseif hotspot:getSortingValue() >= minHotspot:getSortingValue() then
					minDistance = distance
					minHotspot = hotspot
				else
					if distance < minDistance then
						minDistance = distance
						minHotspot = hotspot
					end
				end
			end
		end
	end
	if minHotspot ~= nil then
		self:raiseCallback("onClickHotspotCallback", self, minHotspot)
		return true
	else
		return false
	end
end
function IngameMapElement:getLocalPosition(posX, posY)
	local width, height = self.ingameMap.fullScreenLayout:getMapSize()
	local offX, offY = self.ingameMap.fullScreenLayout:getMapPosition()
	local x = nil
	local y = nil
	if Platform.isMobile then
		x = (posX - offX) / width
		y = (posY - offY) / height
		return x, y
	else
		x = ((posX - offX) / width - 0.25) * 2
		y = ((posY - offY) / height - 0.25) * 2
		return x, y
	end
end
function IngameMapElement:getLocalPointerTarget()
	if self.useMouse then
		return self:getLocalPosition(self.lastInputPosX[self.lastInputIndex], self.lastInputPosY[self.lastInputIndex])
	elseif self.cursorElement then
		local posX = self.cursorElement.absPosition[1] + self.cursorElement.size[1] * 0.5
		local posY = self.cursorElement.absPosition[2] + self.cursorElement.size[2] * 0.5
		return self:getLocalPosition(posX, posY)
	else
		return 0, 0
	end
end
function IngameMapElement:getPlayerHotspot(hotspots)
	if hotspots == nil then
		if self.ingameMap == nil then
			return nil
		end
		hotspots = self.ingameMap.hotspots
	end
	for _, hotspot in pairs(hotspots) do
		if hotspot:isa(PlayerHotspot) then
			return hotspot
		end
	end
	return nil
end
function IngameMapElement:onClickMap(localPosX, localPosY)
	local worldPosX, worldPosZ = self:localToWorldPos(localPosX, localPosY)
	self:raiseCallback("onClickMapCallback", self, worldPosX, worldPosZ)
end
function IngameMapElement:localToWorldPos(localPosX, localPosY)
	local worldPosX = localPosX * self.terrainSize
	local worldPosZ = -localPosY * self.terrainSize
	worldPosX = worldPosX - self.terrainSize * 0.5
	worldPosZ = worldPosZ + self.terrainSize * 0.5
	return worldPosX, worldPosZ
end
function IngameMapElement:worldToScreenPos(worldPosX, worldPosZ)
	local localPosX, localPosY = self:worldToLocalPos(worldPosX, worldPosZ)
	local map = self.ingameMap.fullScreenLayout
	local mapPosX, mapPosY = map:getMapPosition()
	local mapWidth, mapHeight = map:getMapSize()
	local screenPosX = mapPosX + localPosX * mapWidth
	local screenPosY = mapPosY + mapHeight - localPosY * mapHeight
	return screenPosX, screenPosY
end
function IngameMapElement:worldToLocalPos(worldPosX, worldPosZ)
	worldPosX = worldPosX + self.terrainSize * 0.5
	worldPosZ = worldPosZ + self.terrainSize * 0.5
	local localPosX = worldPosX / self.terrainSize
	local localPosY = worldPosZ / self.terrainSize
	return localPosX, localPosY
end
function IngameMapElement:isPointVisible(x, z) end
function IngameMapElement:setIngameMap(ingameMap)
	self.ingameMap = ingameMap
	if self.limitMapWidth and self.ingameMap ~= nil then
		self.ingameMap.fullScreenLayout:setMapWidth(self.absSize[1])
	end
end
function IngameMapElement:setTerrainSize(terrainSize)
	self.terrainSize = terrainSize
end
function IngameMapElement:setIsCursorAvailable(available)
	self.isCursorAvailable = available
end
function IngameMapElement:setCursorCenter(x, y)
	self.cursorElement:setPosition(x, y)
	local centerX = self.cursorElement.absPosition[1] + self.cursorElement.absSize[1] * 0.5
	local centerY = self.cursorElement.absPosition[2] + self.cursorElement.absSize[2] * 0.5
	if centerX ~= self.originalMapCenterX or centerY ~= self.originalMapCenterY then
		self.originalMapCenterX = centerX
		self.originalMapCenterY = centerY
		self.mapCenterX = self.originalMapCenterX
		self.mapCenterY = self.originalMapCenterY
		self.ingameMap.fullScreenLayout:setMapCenter(self.originalMapCenterX, self.originalMapCenterY)
	end
end
function IngameMapElement:registerActionEvents()
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT, self, self.onHorizontalCursorInput, false, false, true, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_SCROLL_UP_DOWN, self, self.onVerticalCursorInput, false, false, true, true)
	g_inputBinding:registerActionEvent(InputAction.INGAMEMAP_ACCEPT, self, self.onAccept, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_OUT, self, self.onZoomInput, false, false, true, true, -1)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_IN, self, self.onZoomInput, false, false, true, true, 1)
	if g_touchHandler ~= nil then
		self.touchListenerPinch = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_PINCH, self.onPinchEvent, self)
	end
end
function IngameMapElement:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
	if g_touchHandler ~= nil then
		g_touchHandler:removeGestureListener(self.touchListenerPinch)
	end
end
function IngameMapElement:onHorizontalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() and not self.isFixedHorizontal then
		self.accumHorizontalInput = self.accumHorizontalInput + inputValue
		if 0.05 < math.abs(inputValue) then
			g_inGameMenu.pageMapOverview.lastInputTime = g_time
		end
	end
end
function IngameMapElement:onVerticalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() then
		self.accumVerticalInput = self.accumVerticalInput + inputValue
		if 0.05 < math.abs(inputValue) then
			g_inGameMenu.pageMapOverview.lastInputTime = g_time
		end
	end
end
function IngameMapElement:onAccept()
	if self.cursorElement then
		local cursorElement = self.cursorElement
		local posX = cursorElement.absPosition[1] + cursorElement.size[1] * 0.5
		local posY = cursorElement.absPosition[2] + cursorElement.size[2] * 0.5
		local localX, localY = self:getLocalPointerTarget()
		local isHotspotSelectionActive = self.isHotspotSelectionActive
		self:onClickMap(localX, localY)
		if isHotspotSelectionActive then
			self:selectHotspotAt(posX, posY)
		end
	end
end
function IngameMapElement:onZoomInput(_, inputValue, direction)
	if not self:isInputInDeadzones(g_lastMousePosX, g_lastMousePosY) or not self.useMouse then
		self.accumZoomInput = self.accumZoomInput - direction * inputValue
	end
end
function IngameMapElement:onPinchEvent(offset, pinchCenterX, pinchCenterY, distance)
	self.oldCursorX = self.cursorElement.absPosition[1]
	self.oldCursorY = self.cursorElement.absPosition[2]
	self.cursorElement.absPosition[1] = pinchCenterX
	self.cursorElement.absPosition[2] = pinchCenterY
	self.accumZoomInput = self.accumZoomInput + offset * 100
	self.isPinching = true
end
function IngameMapElement:checkAndResetMouse()
	local useMouse = self.useMouse
	if useMouse then
		self.resetMouseNextFrame = true
	end
	return useMouse
end
function IngameMapElement:setHotspotSelectionActive(isActive)
	self.isHotspotSelectionActive = isActive
end
function IngameMapElement:hasMouseOverlapWithTabHeader()
	local header = g_inGameMenu.header
	if header ~= nil then
		return GuiUtils.checkOverlayOverlap(g_lastMousePosX, g_lastMousePosY, header.absPosition[1], header.absPosition[2], header.absSize[1], header.absSize[2])
	else
		return false
	end
end
function IngameMapElement:setCenterToWorldPosition(worldPosX, worldPosY)
	local ingameMap = self.ingameMap
	local objectX = (worldPosX + ingameMap.worldCenterOffsetX) / ingameMap.worldSizeX * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX
	local objectZ = (worldPosY + ingameMap.worldCenterOffsetZ) / ingameMap.worldSizeZ * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetZ
	local x, y = ingameMap.layout:getMapObjectPosition(objectX, objectZ, 0, 0)
	local offsetX = self.originalMapCenterX - x
	local offsetY = self.originalMapCenterY - y
	self:moveCenter(offsetX, offsetY)
end
