-- Local values: IngameMapElement_mt
IngameMapElement = {}
local IngameMapElement_mt = Class(IngameMapElement, GuiElement)
Gui.registerGuiElement("InGameMap", IngameMapElement)
IngameMapElement.CURSOR_SPEED_FACTOR = 0.0006
IngameMapElement.BORDER_SCROLL_THRESHOLD = 0.03
IngameMapElement.MAP_ZOOM_SHOW_NAMES = Platform.isMobile and 0.5 or 0.8

-- Upvalues: IngameMapElement_mt
-- Local values: self
function IngameMapElement.new(target, custom_mt)
	-- upvalues: (copy) IngameMapElement_mt
	local v4_ = GuiElement.new(target, custom_mt or IngameMapElement_mt)
	v4_.ingameMap = nil
	v4_.cursorId = nil
	v4_.inputMode = GS_INPUT_HELP_MODE_GAMEPAD
	v4_.terrainSize = 0
	v4_.mapAlpha = 1
	v4_.zoomMin = 1
	v4_.zoomMax = 8
	v4_.zoomDefault = Platform.ingameMap.zoomDefault
	v4_.mapCenterX = 0.5
	v4_.mapCenterY = 0.5
	v4_.mapZoom = v4_.zoomDefault
	v4_.accumHorizontalInput = 0
	v4_.accumVerticalInput = 0
	v4_.accumZoomInput = 0
	v4_.useMouse = false
	v4_.resetMouseNextFrame = false
	v4_.cursorDeadzones = {}
	v4_.limitMapWidth = false
	v4_.limitCursorMovement = false
	v4_.mapMovementLocked = false
	v4_.zoomSpeedFactor = Platform.ingameMap.zoomSpeedFactor
	v4_.dragStartDistance = Platform.ingameMap.dragStartDistance
	v4_.minDragDistanceX = v4_.dragStartDistance * g_pixelSizeX
	v4_.minDragDistanceY = v4_.dragStartDistance * g_pixelSizeY
	v4_.hasDragged = false
	v4_.minimalHotspotSize = getNormalizedScreenValues(9, 1)
	v4_.isHotspotSelectionActive = true
	v4_.isCursorAvailable = true
	v4_.cursorOffsetX = 0
	v4_.cursorOffsetY = 0
	v4_.originalMapCenterX = 0.5
	v4_.originalMapCenterY = 0.5
	v4_.isPinching = false
	v4_.isTouchPickingRotation = false
	v4_.lastInputPosX = {}
	v4_.lastInputPosY = {}
	v4_.lastInputIndex = 0
	return v4_
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
		printWarning("Warning: CursorId \'" .. self.cursorId .. "\' not found for \'" .. self.target.name .. "\'!")
	end
end

function IngameMapElement:addCursorDeadzone(screenX, screenY, width, height)
	local v20_ = self.cursorDeadzones
	table.insert(v20_, {
		screenX,
		screenY,
		width,
		height
	})
end

function IngameMapElement:clearCursorDeadzones()
	self.cursorDeadzones = {}
end

-- Local values: _, zone
function IngameMapElement:isInputInDeadzones(inputScreenX, inputScreenY)
	for _, v25_ in pairs(self.cursorDeadzones) do
		if GuiUtils.checkOverlayOverlap(inputScreenX, inputScreenY, v25_[1], v25_[2], v25_[3], v25_[4]) then
			return true
		end
	end
	return false
end

-- Local values: index, distX, distY, factorX, factorY, localX, localY, isHotspotSelectionActive
function IngameMapElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = IngameMapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
		self.lastInputIndex = 0
		local v33_ = 0
		if not GS_IS_CONSOLE_VERSION and (isDown or (isUp or (posX ~= self.lastInputPosX[v33_] or posY ~= self.lastInputPosY[v33_]))) then
			self.useMouse = true
			if self.cursorElement then
				self.cursorElement:setVisible(false)
			end
			self.isCursorActive = false
		end
		if Platform.isMobile and (self.useMouse and isDown) then
			self.lastInputPosX[v33_] = posX
			self.lastInputPosY[v33_] = posY
		end
		if not eventUsed and (isDown and (button == Input.MOUSE_BUTTON_LEFT and not self:isInputInDeadzones(posX, posY))) then
			eventUsed = true
			if not self.inputDown then
				self.inputDown = true
			end
		end
		if self.inputDown and self.lastInputPosX[v33_] ~= nil then
			local v34_ = self.lastInputPosX[v33_] - posX
			local v35_ = posY - self.lastInputPosY[v33_]
			local v36_ = self.isFixedHorizontal and 0 or v34_
			if math.abs(v36_) > self.minDragDistanceX or math.abs(v35_) > self.minDragDistanceY then
				self:moveCenter(-v36_, v35_)
				self.hasDragged = true
			end
		end
		if isUp and button == Input.MOUSE_BUTTON_LEFT then
			if not eventUsed and (self.inputDown and not self.hasDragged) then
				local v37_, v38_ = self:getLocalPosition(posX, posY)
				local v39_ = self.isHotspotSelectionActive
				self:onClickMap(v37_, v38_)
				if v39_ then
					self:selectHotspotAt(posX, posY)
					eventUsed = true
				else
					eventUsed = true
				end
			end
			self.inputDown = false
			self.hasDragged = false
		end
		self.lastInputPosX[v33_] = posX
		self.lastInputPosY[v33_] = posY
	end
	return eventUsed
end

-- Local values: distX, distY, aiButton, clickInButton, localX, localY, factorX, factorY, localX, localY, isHotspotSelectionActive
function IngameMapElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() then
		eventUsed = IngameMapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
		self.lastInputIndex = touchId
		if isDown or (isUp or (posX ~= self.lastInputPosX[touchId] or posY ~= self.lastInputPosY[touchId])) then
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
			local v47_ = self.lastInputPosX[touchId] - posX
			local v48_ = posY - self.lastInputPosY[touchId]
			local v49_ = self.isFixedHorizontal and 0 or v47_
			if self.isTouchPickingRotation then
				local v50_ = self.target.buttonConfirmAITarget
				if not GuiUtils.checkOverlayOverlap(posX, posY, v50_.absPosition[1], v50_.absPosition[2], v50_.size[1], v50_.size[2]) then
					local v51_, v52_ = self:getLocalPosition(posX, posY)
					self:onClickMap(v51_, v52_)
				end
			elseif math.abs(v49_) > self.minDragDistanceX or math.abs(v48_) > self.minDragDistanceY then
				self:moveCenter(-v49_, v48_)
				self.hasDragged = true
			end
		end
		if isUp then
			if not eventUsed and (self.inputDown and not self.hasDragged) then
				local v53_, v54_ = self:getLocalPosition(posX, posY)
				local v55_ = self.isHotspotSelectionActive
				self:onClickMap(v53_, v54_)
				if v55_ then
					self:selectHotspotAt(posX, posY)
					eventUsed = true
				else
					eventUsed = true
				end
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

-- Local values: cursor
function IngameMapElement:unlockMapMovement()
	self.mapMovementLocked = false
	if not Platform.isMobile then
		self.cursorOffsetX = 0
		self.cursorOffsetY = 0
		local v58_ = self.cursorElement
		v58_.absPosition[1] = self.originalMapCenterX - v58_.absSize[1] * 0.5
		v58_.absPosition[2] = self.originalMapCenterY - v58_.absSize[2] * 0.5
	end
end

-- Local values: width, height, maxCenterOffsetX, maxCenterOffsetY, minValue, maxValue
function IngameMapElement:moveCenter(x, y)
	local v62_, v63_ = self.ingameMap.fullScreenLayout:getMapSize()
	if Platform.isMobile then
		local v64_ = (v62_ - self.ingameMap.fullScreenLayout.width) * 0.5
		local v65_ = (v63_ - 1) * 0.5
		local v66_ = self.mapCenterX + x
		local v67_ = self.originalMapCenterX - v64_
		local v68_ = self.originalMapCenterX + v64_
		self.mapCenterX = math.clamp(v66_, v67_, v68_)
		local v69_ = self.mapCenterY + y
		local v70_ = self.originalMapCenterY - v65_
		local v71_ = self.originalMapCenterY + v65_
		self.mapCenterY = math.clamp(v69_, v70_, v71_)
	else
		local v72_ = self.mapCenterX + x
		local v73_ = v62_ * -0.5 + self.originalMapCenterX
		local v74_ = v62_ * 0.5 + self.originalMapCenterX
		self.mapCenterX = math.clamp(v72_, v73_, v74_)
		if self.limitCursorMovement then
			local v75_ = self.absPosition[2] + self.absSize[2] - v63_ * 0.5
			local v76_ = self.absPosition[2] + v63_ * 0.5
			local v77_ = self.mapCenterY + y
			self.mapCenterY = math.clamp(v77_, v75_, v76_)
		else
			local v78_ = self.mapCenterY + y
			local v79_ = v63_ * -0.5 + self.originalMapCenterY
			local v80_ = v63_ * 0.5 + self.originalMapCenterY
			self.mapCenterY = math.clamp(v78_, v79_, v80_)
		end
	end
	self.ingameMap.fullScreenLayout:setMapCenter(self.mapCenterX, self.mapCenterY)
end

-- Local values: hotspotX, hotspotY, cursorOffsetX, cursorOffsetY, ingameMap, hotspotX, hotspotY, objectX, objectZ, offsetX, offsetY
function IngameMapElement:panToHotspot(hotspot, extraOffsetX)
	if hotspot ~= nil then
		if Platform.isMobile then
			local v83_, v84_ = self:worldToScreenPos(hotspot:getWorldPosition())
			local v85_ = -v83_ + self.mapCenterX + self.originalMapCenterX
			local v86_ = -v84_ + self.mapCenterY + self.originalMapCenterY
			self.cursorOffsetX = v85_ - self.mapCenterX
			self.cursorOffsetY = v86_ - self.mapCenterY
			return
		end
		local v87_ = self.ingameMap
		local v88_, v89_ = hotspot:getWorldPosition()
		local v90_ = (v88_ + v87_.worldCenterOffsetX) / v87_.worldSizeX * v87_.mapExtensionScaleFactor + v87_.mapExtensionOffsetX
		local v91_ = (v89_ + v87_.worldCenterOffsetZ) / v87_.worldSizeZ * v87_.mapExtensionScaleFactor + v87_.mapExtensionOffsetZ
		local v92_, v93_ = v87_.layout:getMapObjectPosition(v90_, v91_, 0, 0)
		self:moveCenter(self.originalMapCenterX - v92_, self.originalMapCenterY - v93_)
	end
end

-- Local values: fullScreenLayout
function IngameMapElement:copySettingsFromElement(element)
	local v96_ = self.ingameMap.fullScreenLayout
	self.mapZoom = element.mapZoom
	local v97_ = element.mapCenterX
	local v98_ = element.mapCenterY
	self.mapCenterX = v97_
	self.mapCenterY = v98_
	v96_:setMapZoom(self.mapZoom)
	v96_:setMapCenter(self.mapCenterX, self.mapCenterY)
end

-- Local values: targetX, targetZ, width, height, oldZoom, speed, newTargetX, newTargetZ, diffX, diffZ, dx, dy, mapLayout, centerX, centerY, newCenterX, newCenterY
function IngameMapElement:zoom(direction, zoomTarget)
	if Platform.ingameMap.canZoom then
		local v102_, v103_ = self:localToWorldPos(self:getLocalPointerTarget())
		local v104_, v105_ = self.ingameMap.fullScreenLayout:getMapSize()
		local v106_ = self.mapZoom
		local v107_ = self.zoomSpeedFactor * direction * v104_
		if zoomTarget == nil then
			local v108_ = self.mapZoom + v107_
			local v109_ = self.zoomMin
			local v110_ = self.zoomMax
			self.mapZoom = math.clamp(v108_, v109_, v110_)
		else
			local v111_ = self.zoomMin
			local v112_ = self.zoomMax
			self.mapZoom = math.clamp(zoomTarget, v111_, v112_)
		end
		self.ingameMap.fullScreenLayout:setMapZoom(self.mapZoom)
		self:moveCenter(0, 0)
		if v106_ ~= self.mapZoom then
			local v113_, v114_ = self:localToWorldPos(self:getLocalPointerTarget())
			local v115_ = v113_ - v102_
			local v116_ = v114_ - v103_
			local v117_ = v115_ / self.terrainSize * 0.5 * v104_
			local v118_ = -v116_ / self.terrainSize * 0.5 * v105_
			self.cursorOffsetX = self.cursorOffsetX + v117_
			self.cursorOffsetY = self.cursorOffsetY + v118_
			local v119_ = self.ingameMap.fullScreenLayout
			local v120_ = v119_.mapCenterX
			local v121_ = v119_.mapCenterY
			self:moveCenter(v117_, v118_)
			local v122_ = v119_.mapCenterX
			local v123_ = v119_.mapCenterY
			if direction < 0 then
				self.cursorOffsetX = self.cursorOffsetX - v122_ + v120_ + v117_
				self.cursorOffsetY = self.cursorOffsetY - v123_ + v121_ + v118_
			end
		end
	end
end

function IngameMapElement:setLockedToBorder(yOffset, height)
	self.yOffset = yOffset
	self.height = height
	self.lockedToBorder = true
end

-- Local values: zoomFactor
function IngameMapElement:update(dt)
	IngameMapElement:superClass().update(self, dt)
	self.inputMode = g_inputBinding:getLastInputMode()
	if not (g_gui:getIsDialogVisible() or self.alreadyClosed) then
		local v129_ = self.accumZoomInput
		if not self.isPinching then
			v129_ = math.clamp(v129_, -1, 1)
		end
		if v129_ ~= 0 then
			self:zoom(v129_ * -0.015 * dt)
		end
		if self.cursorElement ~= nil then
			self.isCursorActive = self.inputMode == GS_INPUT_HELP_MODE_GAMEPAD
			local v130_ = self.cursorElement
			local v131_ = self.isCursorAvailable
			if v131_ then
				v131_ = self.isCursorActive
			end
			v130_:setVisible(v131_)
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

-- Local values: speed, diffX, diffY, oldX, oldY, newX, newY, cursorSize, _, width, maxOffset, cursor
function IngameMapElement:updateCursor(deltaX, deltaY, dt)
	if self.cursorElement ~= nil then
		local v145_ = IngameMapElement.CURSOR_SPEED_FACTOR
		local v146_ = deltaX * v145_ * dt / g_screenAspectRatio
		local v147_ = deltaY * v145_ * dt
		if Platform.isMobile or self.mapMovementLocked then
			local v148_ = v146_ - self.cursorOffsetX
			local v149_ = v147_ - self.cursorOffsetY
			local v150_ = self.mapCenterX
			local v151_ = self.mapCenterY
			if not self.mapMovementLocked then
				self:moveCenter(-v148_, -v149_)
			end
			local v152_ = self.mapCenterX
			local v153_ = self.mapCenterY
			local v154_ = self.cursorElement.absSize
			local _, v155_ = self.ingameMap.fullScreenLayout:getMapSize()
			self.cursorOffsetX = v150_ - v152_ - v148_
			local v156_ = self.cursorOffsetX
			local v157_ = v155_ * 0.5 - v154_[1] * 0.5
			local v158_ = math.min(v156_, v157_)
			local v159_ = -v155_ * 0.5 + v154_[1] * 0.5
			self.cursorOffsetX = math.max(v158_, v159_)
			self.cursorOffsetY = v151_ - v153_ - v149_
			local v160_ = self.cursorOffsetY
			local v161_ = 0.5 - v154_[2] * 0.5
			local v162_ = math.min(v160_, v161_)
			local v163_ = -0.5 + v154_[2] * 0.5
			self.cursorOffsetY = math.max(v162_, v163_)
			if not Platform.isMobile and self.mapMovementLocked then
				local v164_ = 250
				local v165_ = self.cursorOffsetX
				local v166_ = -250 * g_pixelSizeScaledX
				local v167_ = v164_ * g_pixelSizeScaledX
				self.cursorOffsetX = math.clamp(v165_, v166_, v167_)
				local v168_ = self.cursorOffsetY
				local v169_ = -250 * g_pixelSizeScaledY
				local v170_ = v164_ * g_pixelSizeScaledY
				self.cursorOffsetY = math.clamp(v168_, v169_, v170_)
			end
			local v171_ = self.cursorElement
			v171_.absPosition[1] = self.originalMapCenterX - self.cursorOffsetX - v171_.absSize[1] * 0.5
			v171_.absPosition[2] = self.originalMapCenterY - self.cursorOffsetY - v171_.absSize[2] * 0.5
			return
		end
		self:moveCenter(-v146_, -v147_)
	end
end

-- Local values: sortedHotspots, playerHotspot, prioritizePlayerHotspot
function IngameMapElement:selectHotspotAt(posX, posY)
	if self.isHotspotSelectionActive then
		self.ingameMap:updateHotspotSorting()
		local v175_ = self.ingameMap.hotspotsSorted
		if v175_ ~= nil then
			local v176_ = self:getPlayerHotspot(v175_[true])
			local v177_ = not Platform.isMobile or v176_:getVehicle() ~= nil
			if not self:selectHotspotFrom(v175_[v177_], posX, posY) and v177_ then
				self:selectHotspotFrom(v175_[false], posX, posY)
			end
			return
		end
		self:selectHotspotFrom(self.ingameMap.hotspots, posX, posY)
	end
end

-- Local values: minDistance, minHotspot, i, hotspot, isInRange, distance
function IngameMapElement:selectHotspotFrom(hotspots, posX, posY)
	local v182_ = math.huge
	local v183_ = nil
	for v184_ = #hotspots, 1, -1 do
		local v185_ = hotspots[v184_]
		if self.ingameMap.filter[v185_:getCategory()] and v185_:getIsVisible() then
			local v186_, v187_ = v185_:hasMouseOverlap(posX, posY)
			if v186_ then
				if v183_ == nil then
					v183_ = v185_
					v182_ = v187_
				elseif v185_:getSortingValue() < v183_:getSortingValue() then
					if v187_ < v182_ then
						v183_ = v185_
						v182_ = v187_
					end
				else
					v183_ = v185_
					v182_ = v187_
				end
			end
		end
	end
	if v183_ == nil then
		return false
	end
	self:raiseCallback("onClickHotspotCallback", self, v183_)
	return true
end

-- Local values: width, height, offX, offY, x, y
function IngameMapElement:getLocalPosition(posX, posY)
	local v191_, v192_ = self.ingameMap.fullScreenLayout:getMapSize()
	local v193_, v194_ = self.ingameMap.fullScreenLayout:getMapPosition()
	if Platform.isMobile then
		return (posX - v193_) / v191_, (posY - v194_) / v192_
	else
		return ((posX - v193_) / v191_ - 0.25) * 2, ((posY - v194_) / v192_ - 0.25) * 2
	end
end

-- Local values: posX, posY
function IngameMapElement:getLocalPointerTarget()
	if self.useMouse then
		return self:getLocalPosition(self.lastInputPosX[self.lastInputIndex], self.lastInputPosY[self.lastInputIndex])
	elseif self.cursorElement then
		return self:getLocalPosition(self.cursorElement.absPosition[1] + self.cursorElement.size[1] * 0.5, self.cursorElement.absPosition[2] + self.cursorElement.size[2] * 0.5)
	else
		return 0, 0
	end
end

-- Local values: _, hotspot
function IngameMapElement:getPlayerHotspot(hotspots)
	if hotspots == nil then
		if self.ingameMap == nil then
			return nil
		end
		hotspots = self.ingameMap.hotspots
	end
	for _, v198_ in pairs(hotspots) do
		if v198_:isa(PlayerHotspot) then
			return v198_
		end
	end
	return nil
end

-- Local values: worldPosX, worldPosZ
function IngameMapElement:onClickMap(localPosX, localPosY)
	local v202_, v203_ = self:localToWorldPos(localPosX, localPosY)
	self:raiseCallback("onClickMapCallback", self, v202_, v203_)
end

-- Local values: worldPosX, worldPosZ
function IngameMapElement:localToWorldPos(localPosX, localPosY)
	local v207_ = localPosX * self.terrainSize
	local v208_ = -localPosY * self.terrainSize
	return v207_ - self.terrainSize * 0.5, v208_ + self.terrainSize * 0.5
end

-- Local values: localPosX, localPosY, map, mapPosX, mapPosY, mapWidth, mapHeight, screenPosX, screenPosY
function IngameMapElement:worldToScreenPos(worldPosX, worldPosZ)
	local v212_, v213_ = self:worldToLocalPos(worldPosX, worldPosZ)
	local v214_ = self.ingameMap.fullScreenLayout
	local v215_, v216_ = v214_:getMapPosition()
	local v217_, v218_ = v214_:getMapSize()
	return v215_ + v212_ * v217_, v216_ + v218_ - v213_ * v218_
end

-- Local values: localPosX, localPosY
function IngameMapElement:worldToLocalPos(worldPosX, worldPosZ)
	local v222_ = worldPosX + self.terrainSize * 0.5
	local v223_ = worldPosZ + self.terrainSize * 0.5
	return v222_ / self.terrainSize, v223_ / self.terrainSize
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

-- Local values: centerX, centerY
function IngameMapElement:setCursorCenter(x, y)
	self.cursorElement:setPosition(x, y)
	local v233_ = self.cursorElement.absPosition[1] + self.cursorElement.absSize[1] * 0.5
	local v234_ = self.cursorElement.absPosition[2] + self.cursorElement.absSize[2] * 0.5
	if v233_ ~= self.originalMapCenterX or v234_ ~= self.originalMapCenterY then
		self.originalMapCenterX = v233_
		self.originalMapCenterY = v234_
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
	if not (self:checkAndResetMouse() or self.isFixedHorizontal) then
		self.accumHorizontalInput = self.accumHorizontalInput + inputValue
		if math.abs(inputValue) > 0.05 then
			g_inGameMenu.pageMapOverview.lastInputTime = g_time
		end
	end
end

function IngameMapElement:onVerticalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() then
		self.accumVerticalInput = self.accumVerticalInput + inputValue
		if math.abs(inputValue) > 0.05 then
			g_inGameMenu.pageMapOverview.lastInputTime = g_time
		end
	end
end

-- Local values: cursorElement, posX, posY, localX, localY, isHotspotSelectionActive
function IngameMapElement:onAccept()
	if self.cursorElement then
		local v242_ = self.cursorElement
		local v243_ = v242_.absPosition[1] + v242_.size[1] * 0.5
		local v244_ = v242_.absPosition[2] + v242_.size[2] * 0.5
		local v245_, v246_ = self:getLocalPointerTarget()
		local v247_ = self.isHotspotSelectionActive
		self:onClickMap(v245_, v246_)
		if v247_ then
			self:selectHotspotAt(v243_, v244_)
		end
	end
end

function IngameMapElement:onZoomInput(_, inputValue, direction)
	if not (self:isInputInDeadzones(g_lastMousePosX, g_lastMousePosY) and self.useMouse) then
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

-- Local values: useMouse
function IngameMapElement:checkAndResetMouse()
	local v256_ = self.useMouse
	if v256_ then
		self.resetMouseNextFrame = true
	end
	return v256_
end

function IngameMapElement:setHotspotSelectionActive(isActive)
	self.isHotspotSelectionActive = isActive
end

-- Local values: header
function IngameMapElement:hasMouseOverlapWithTabHeader()
	local v259_ = g_inGameMenu.header
	if v259_ == nil then
		return false
	else
		return GuiUtils.checkOverlayOverlap(g_lastMousePosX, g_lastMousePosY, v259_.absPosition[1], v259_.absPosition[2], v259_.absSize[1], v259_.absSize[2])
	end
end

-- Local values: ingameMap, objectX, objectZ, x, y, offsetX, offsetY
function IngameMapElement:setCenterToWorldPosition(worldPosX, worldPosY)
	local v263_ = self.ingameMap
	local v264_ = (worldPosX + v263_.worldCenterOffsetX) / v263_.worldSizeX * v263_.mapExtensionScaleFactor + v263_.mapExtensionOffsetX
	local v265_ = (worldPosY + v263_.worldCenterOffsetZ) / v263_.worldSizeZ * v263_.mapExtensionScaleFactor + v263_.mapExtensionOffsetZ
	local v266_, v267_ = v263_.layout:getMapObjectPosition(v264_, v265_, 0, 0)
	self:moveCenter(self.originalMapCenterX - v266_, self.originalMapCenterY - v267_)
end
