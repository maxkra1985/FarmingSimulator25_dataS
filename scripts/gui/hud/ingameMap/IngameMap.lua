IngameMap = {}
local IngameMap_mt = Class(IngameMap, HUDElement)
IngameMap.alpha = 1
IngameMap.alphaInc = 0.005
IngameMap.maxIconZoom = 1.4
IngameMap.DEFAULT_SORTING_PRIO = { MapHotspot.CATEGORY_FIELD, MapHotspot.CATEGORY_ANIMAL, MapHotspot.CATEGORY_MISSION, MapHotspot.CATEGORY_TOUR, MapHotspot.CATEGORY_STEERABLE, MapHotspot.CATEGORY_COMBINE, MapHotspot.CATEGORY_TRAILER, MapHotspot.CATEGORY_TOOL, MapHotspot.CATEGORY_UNLOADING, MapHotspot.CATEGORY_LOADING, MapHotspot.CATEGORY_PRODUCTION, MapHotspot.CATEGORY_SHOP, MapHotspot.CATEGORY_OTHER, MapHotspot.CATEGORY_AI, MapHotspot.CATEGORY_PLAYER }
function IngameMap.new(customMt)
	local self = IngameMap:superClass().new(nil, nil, customMt or IngameMap_mt)
	self.overlay = self:createBackground()
	self.uiScale = 1
	self.isVisible = true
	self.clipHotspots = false
	self.fullScreenLayout = IngameMapLayoutFullscreen.new()
	self.layouts = { IngameMapLayoutNone.new(), IngameMapLayoutCircle.new(), IngameMapLayoutSquare.new(), IngameMapLayoutSquareLarge.new(), self.fullScreenLayout }
	self.state = 1
	self.numToggleStates = 4
	self.layout = self.layouts[self.state]
	self.mapOverlay = Overlay.new(nil, 0, 0, 1, 1)
	self.mapElement = HUDElement.new(self.mapOverlay)
	self:createComponents()
	for _, layout in ipairs(self.layouts) do
		layout:createComponents(self)
	end
	local setDefaultValue = function(filter, category)
		filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	end
	self.filter = {}
	local filter = self.filter
	local category = MapHotspot.CATEGORY_FIELD
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_ANIMAL
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_MISSION
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_TOUR
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_STEERABLE
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_COMBINE
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_TRAILER
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_TOOL
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_UNLOADING
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_LOADING
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_PRODUCTION
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_OTHER
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_SHOP
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_AI
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	local filter = self.filter
	local category = MapHotspot.CATEGORY_PLAYER
	filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
	self.currentFilter = self.filter
	self:setWorldSize(2048, 2048)
	self.hotspots = {}
	self.selectedHotspot = nil
	self.mapExtensionOffsetX = 0.25
	self.mapExtensionOffsetZ = 0.25
	self.mapExtensionScaleFactor = 0.5
	self.allowToggle = true
	self.hotspotsDirty = true
	self.hotspotsRegular = {}
	self.hotspotsRenderLast = {}
	self.hotspotsPersistent = {}
	self.hotspotsPersistentRenderLast = {}
	self.hotspotsPostUpdate = {}
	self.topDownCamera = nil
	return self
end
function IngameMap:delete()
	g_inputBinding:removeActionEventsByTarget(self)
	self.mapElement:delete()
	self:setSelectedHotspot(nil)
	for _, layout in ipairs(self.layouts) do
		layout:delete()
	end
	IngameMap:superClass().delete(self)
end
function IngameMap:setFullscreen(isFullscreen)
	if self.isFullscreen == isFullscreen then
		return
	else
		self.isFullscreen = isFullscreen
		local newLayout = self.layouts[self.state]
		if isFullscreen then
			newLayout = self.fullScreenLayout
		end
		self:setLayout(newLayout)
	end
end
function IngameMap:setLayout(layout)
	self.layout:deactivate()
	self.layout = layout
	self.layout:activate()
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, layout:getShowsToggleActionText())
	if self.layout:getShowsToggleAction() then
		self:updateInputGlyphs()
	end
	self:resetHotspotSorting()
end
function IngameMap:setCustomLayout(layout)
	local newLayout = layout or self.layouts[self.state]
	newLayout:setWorldSize(self.worldSizeX, self.worldSizeZ)
	newLayout:setMapExtensionSettings(self.mapExtensionScaleFactor, self.mapExtensionOffsetX, self.mapExtensionOffsetZ)
	self:setLayout(newLayout)
end
function IngameMap:toggleSize(state, force)
	if state ~= nil then
		self.state = math.max(math.min(state, self.numToggleStates), 1)
	else
		self.state = self.state % self.numToggleStates + 1
	end
	g_gameSettings:setValue("ingameMapState", self.state)
	self:setLayout(self.layouts[self.state])
end
function IngameMap:turnSmall()
	if self.state == IngameMapState.MAP then
		self:toggleSize(IngameMapState.MINIMAP_SQUARE, true)
	end
end
function IngameMap:setTopDownCamera(guiTopDownCamera)
	self.topDownCamera = guiTopDownCamera
	if guiTopDownCamera ~= nil then
		self.previousLayout = self.state
		if self.state ~= IngameMapState.MINIMAP_ROUND then
			self:toggleSize(IngameMapState.MINIMAP_ROUND, true)
		end
	elseif self.state ~= self.previousLayout then
		self:toggleSize(self.previousLayout, true)
	end
end
function IngameMap:resetSettings()
	if self.overlay == nil then
		return
	else
		self:setSelectedHotspot(nil)
	end
end
function IngameMap:getHeight()
	return self.layout:getHeight()
end
function IngameMap:getRequiredHeight()
	return self:getHeight()
end
function IngameMap:getIsLarge()
	return self.state == IngameMapState.MAP
end
function IngameMap:setAllowToggle(isAllowed)
	self.allowToggle = isAllowed
end
function IngameMap:setIsVisible(isVisible)
	self.isVisible = isVisible
	g_inputBinding:setActionEventActive(self.toggleMapSizeEventId, isVisible and self.layout:getShowsToggleActionText())
end
function IngameMap:onToggleMapSize()
	if self.allowToggle and (not g_gui:getIsGuiVisible() or g_gui:getIsOverlayGuiVisible()) then
		self:toggleSize()
	end
end
function IngameMap:loadMap(filename, worldSizeX, worldSizeZ, fieldColor, grassFieldColor)
	self.mapElement:delete()
	self:setWorldSize(worldSizeX, worldSizeZ)
	self.mapOverlay = Overlay.new(filename, 0, 0, 1, 1)
	self.mapElement = HUDElement.new(self.mapOverlay)
	self:addChild(self.mapElement)
	self:setScale(self.uiScale)
end
function IngameMap:registerInput()
	local _, eventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_MAP_SIZE, self, self.onToggleMapSize, false, true, false, true)
	self.toggleMapSizeEventId = eventId
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.layout:getShowsToggleActionText())
	g_inputBinding:setActionEventTextPriority(self.toggleMapSizeEventId, GS_PRIO_VERY_LOW)
end
function IngameMap:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeX = worldSizeX
	self.worldSizeZ = worldSizeZ
	self.worldCenterOffsetX = self.worldSizeX * 0.5
	self.worldCenterOffsetZ = self.worldSizeZ * 0.5
	for _, layout in ipairs(self.layouts) do
		layout:setWorldSize(worldSizeX, worldSizeZ)
	end
end
function IngameMap:setHasUnreadMessages(hasMessages)
	self.layout:setHasUnreadMessages(hasMessages)
end
function IngameMap:addMapHotspot(mapHotspot)
	table.addElement(self.hotspots, mapHotspot)
	self:sortHotspots()
	self:resetHotspotSorting()
	mapHotspot:addRenderStateChangedListener(self)
	return mapHotspot
end
function IngameMap:removeMapHotspot(mapHotspot)
	if mapHotspot ~= nil then
		table.removeElement(self.hotspots, mapHotspot)
		if self.selectedHotspot == mapHotspot then
			self:setSelectedHotspot(nil)
		end
		if g_currentMission ~= nil and g_currentMission.currentMapTargetHotspot == mapHotspot then
			g_currentMission:setMapTargetHotspot(nil)
		end
		mapHotspot:removeRenderStateChangedListener(self)
		self:resetHotspotSorting()
	end
end
function IngameMap:onMapHotspotRenderStateChanged(hotspot)
	self:resetHotspotSorting()
end
function IngameMap:setSelectedHotspot(hotspot)
	if self.selectedHotspot ~= nil then
		self.selectedHotspot:setSelected(false)
	end
	self.selectedHotspot = hotspot
	if self.selectedHotspot ~= nil then
		self.selectedHotspot:setSelected(true)
	end
end
function IngameMap:getHotspotIndex(hotspot)
	for i, spot in ipairs(self.hotspots) do
		if spot == hotspot then
			return i
		end
	end
	return -1
end
function IngameMap:cycleVisibleHotspot(currentHotspot, categoriesHash, direction)
	local currentIndex = self:getHotspotIndex(currentHotspot) + direction
	local _v20 = 1
	if currentIndex < _v20 or #self.hotspots < currentIndex then
		currentIndex = _v20
	end
	local visitedCount = 0
	local hotspot = self.hotspots[currentIndex]
	while visitedCount < #self.hotspots do
		local category = hotspot:getCategory()
		if not hotspot:getIsVisible() then
			if g_localPlayer:getCurrentVehicle() ~= hotspot.vehicle or hotspot.vehicle == nil or not self.currentFilter[category] or not categoriesHash[category] then
				visitedCount = visitedCount + 1
				currentIndex = currentIndex + direction
				if #self.hotspots < currentIndex then
					currentIndex = 1
				elseif currentIndex < 1 then
					currentIndex = #self.hotspots
				end
				hotspot = self.hotspots[currentIndex]
				continue
			end
			if visitedCount < #self.hotspots then
				return hotspot
			else
				return nil
			end
		end
	end
end
function IngameMap:resetHotspotSorting()
	if not self.hotspotsDirty then
		table.clear(self.hotspotsRegular)
		table.clear(self.hotspotsPersistent)
		table.clear(self.hotspotsPersistentRenderLast)
		table.clear(self.hotspotsRenderLast)
		table.clear(self.hotspotsPostUpdate)
	end
	self.hotspotsDirty = true
end
function IngameMap:updateHotspotSorting(dt)
	if self.hotspotsDirty then
		self.hotspotsDirty = false
		for _, hotspot in pairs(self.hotspots) do
			if hotspot.postUpdate ~= nil then
				table.insert(self.hotspotsPostUpdate, hotspot)
			end
			local isVisible = hotspot:getIsVisible()
			if isVisible then
				local category = hotspot:getCategory()
				if self.currentFilter[category] then
					local isPersistent = hotspot:getIsPersistent()
					local isRenderLast = hotspot:getRenderLast()
					if isPersistent then
						if isRenderLast then
							table.insert(self.hotspotsPersistentRenderLast, hotspot)
						else
							table.insert(self.hotspotsPersistent, hotspot)
						end
					elseif isRenderLast then
						table.insert(self.hotspotsRenderLast, hotspot)
					else
						table.insert(self.hotspotsRegular, hotspot)
					end
				end
			end
		end
	end
end
function IngameMap:updateBlinkingHotspotAlpha(dt)
	IngameMap.alpha = math.abs(math.sin(g_time / 200))
end
function IngameMap:updateHotspotFilters() end
function IngameMap:setHotspotFilter(category, isActive)
	self:setDefaultFilterValue(category, isActive)
end
function IngameMap:toggleDefaultFilter(category)
	self:setDefaultFilterValue(category, not self:getDefaultFilterValue(category))
end
function IngameMap:setDefaultFilterValue(category, isActive)
	if category ~= nil then
		if isActive then
			g_gameSettings:setValue("ingameMapFilter", Utils.clearBit(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category))
		else
			g_gameSettings:setValue("ingameMapFilter", Utils.setBit(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category))
		end
		self.filter[category] = isActive
		self:resetHotspotSorting()
	end
end
function IngameMap:getDefaultFilterValue(category)
	if category ~= nil then
		return self.filter[category]
	else
		return false
	end
end
function IngameMap:applyCustomFilter(filter)
	self.currentFilter = filter
	self:resetHotspotSorting()
end
function IngameMap:applyCustomHotspotSortingOrder(sortingPrio)
	sortingPrio = sortingPrio or IngameMap.DEFAULT_SORTING_PRIO
	self.sortingOrder = {}
	for prio, category in ipairs(sortingPrio) do
		self.sortingOrder[category] = prio
	end
	self:sortHotspots()
	self:resetHotspotSorting()
end
function IngameMap:sortHotspots()
	if self.sortingOrder == nil then
		self:applyCustomHotspotSortingOrder(nil)
	end
	local sortingOrder = self.sortingOrder
	table.sort(self.hotspots, function(hotspot1, hotspot2)
		local sortPrio1 = sortingOrder[hotspot1:getCategory()]
		local sortPrio2 = sortingOrder[hotspot2:getCategory()]
		if sortPrio1 == nil then
			return false
		elseif sortPrio2 == nil then
			return true
		else
			return sortPrio1 < sortPrio2
		end
	end)
end
function IngameMap:restoreDefaultFilter()
	self.currentFilter = self.filter
	self:resetHotspotSorting()
end
function IngameMap:createCustomFilter(default)
	local filter = {}
	for k, _ in pairs(self.filter) do
		filter[k] = default
	end
	return filter
end
function IngameMap:update(dt)
	self:updateBlinkingHotspotAlpha(dt)
	self:updatePlayerPosition()
	self.layout:setPlayerPosition(self.normalizedPlayerPosX, self.normalizedPlayerPosZ, self.playerRotation)
	self.layout:setPlayerVelocity(self.playerVelocity or 0)
end
function IngameMap:postUpdate(dt)
	self:updateHotspotSorting()
	self.layout:postUpdate(dt)
	for _, hotspot in ipairs(self.hotspotsPostUpdate) do
		hotspot:postUpdate(dt)
	end
end
function IngameMap:updateInputGlyphs()
	self.toggleMapSizeGlyph:setAction(InputAction.TOGGLE_MAP_SIZE)
end
function IngameMap:updatePlayerPosition()
	local playerPosX = 0
	local _ = 0
	local playerPosZ = 0
	local localPlayer = g_localPlayer
	self.playerRotation = 0
	self.playerVelocity = 0
	if self.topDownCamera ~= nil then
		playerPosX, _, playerPosZ, self.playerRotation, self.playerVelocity = self.topDownCamera:determineMapPosition()
	elseif localPlayer ~= nil then
		playerPosX, _, playerPosZ = localPlayer:getPosition()
		self.playerRotation = localPlayer:getYaw()
		self.playerVelocity = localPlayer:getSpeed()
	end
	self.normalizedPlayerPosX = math.clamp((playerPosX + self.worldCenterOffsetX) / self.worldSizeX, 0, 1)
	self.normalizedPlayerPosZ = math.clamp((playerPosZ + self.worldCenterOffsetZ) / self.worldSizeZ, 0, 1)
end
function IngameMap:draw()
	if not self.isVisible then
		return
	else
		local width, height = self.layout:getMapSize()
		if width == 0 or height == 0 then
			return
		end
		self.mapElement:setDimension(width, height)
		self.mapElement:setAlpha(self.layout:getMapAlpha())
		self.mapElement:setPosition(self.layout:getMapPosition())
		self.mapElement:setRotationPivot(self.layout:getMapPivot())
		self.mapElement:setRotation(self.layout:getMapRotation())
		self.layout:drawBefore()
		self.mapElement:draw()
		self:drawFields()
		self:drawPointsOfInterest()
		self.layout:drawAfter()
		self:drawPersistentPointsOfInterest()
		if self.layout:getShowsToggleAction() then
			self.toggleMapSizeGlyph:draw()
		end
		self:drawPlayersCoordinates()
		self:drawLatencyToServer()
	end
end
function IngameMap:drawFields()
	local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
	if mapOverlayGenerator == nil then
		return
	else
		local overlay = mapOverlayGenerator:getFieldsOverlay()
		if overlay ~= nil then
			local width, height = self.layout:getMapSize()
			local x, y = self.layout:getMapPosition()
			local px, py = self.layout:getMapPivot()
			px = px + x
			py = py + y
			x = x + width * self.mapExtensionOffsetX
			y = y + height * self.mapExtensionOffsetZ
			px = px - x
			py = py - y
			local posX = x
			local posY = y
			local sizeX = width * self.mapExtensionScaleFactor
			local sizeY = height * self.mapExtensionScaleFactor
			if self.clipX1 ~= nil then
				local u1 = nil
				local v1 = nil
				local u2 = nil
				local v2 = nil
				local u3 = nil
				local v3 = nil
				local u4 = nil
				local v4 = nil
				posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4 = Overlay.getClippingUVs(Overlay.DEFAULT_UVS, posX, posY, sizeX, sizeY, self.clipX1, self.clipY1, self.clipX2, self.clipY2)
				if u1 == nil then
					return
				end
				setOverlayUVs(overlay, u1, v1, u2, v2, u3, v3, u4, v4)
			end
			setOverlayRotation(overlay, self.layout:getMapRotation(), px, py)
			setOverlayColor(overlay, 1, 1, 1, math.sqrt(self.layout:getMapAlpha()))
			renderOverlay(overlay, posX, posY, sizeX, sizeY)
			if self.clipX1 ~= nil then
				setOverlayUVs(overlay, unpack(Overlay.DEFAULT_UVS))
			end
		end
	end
end
function IngameMap:drawMapOnly()
	local width, height = self.layout:getMapSize()
	self.mapElement:setDimension(width, height)
	self.mapElement:setAlpha(self.layout:getMapAlpha())
	self.mapElement:setPosition(self.layout:getMapPosition())
	self.mapElement:setRotationPivot(self.layout:getMapPivot())
	self.mapElement:setRotation(self.layout:getMapRotation())
	self.layout:drawBefore()
	self.mapElement:draw(self.clipX1, self.clipY1, self.clipX2, self.clipY2)
	self:drawFields()
	self.layout:drawAfter()
end
function IngameMap:drawHotspotsOnly()
	self:drawPointsOfInterest()
	self:drawPersistentPointsOfInterest()
end
function IngameMap:drawPlayersCoordinates()
	local rotation = math.deg(math.abs(self.playerRotation - 3.141592653589793))
	local renderString = string.format("%.1f\194\176, %d, %d", rotation, self.normalizedPlayerPosX * self.worldSizeX, self.normalizedPlayerPosZ * self.worldSizeZ)
	self.layout:drawCoordinates(renderString)
end
function IngameMap:drawLatencyToServer()
	local missionDynamicInfo = g_currentMission.missionDynamicInfo
	if g_client ~= nil and (g_client.currentLatency ~= nil and (missionDynamicInfo.isMultiplayer and missionDynamicInfo.isClient)) then
		local color = nil
		if g_client.currentLatency <= 50 then
			color = IngameMap.COLOR.LATENCY_GOOD
		elseif g_client.currentLatency < 100 then
			color = IngameMap.COLOR.LATENCY_MEDIUM
		else
			color = IngameMap.COLOR.LATENCY_BAD
		end
		self.layout:drawLatency(string.format("%dms", math.max(g_client.currentLatency, 10)), color)
	end
end
function IngameMap:drawPointsOfInterest()
	local smallIconVariation = self.layout:getShowSmallIconVariation() and not Platform.isMobile
	self:drawHotspots(self.hotspotsRegular, smallIconVariation)
	if 0 < #self.hotspotsRenderLast then
		new2DLayer()
		self:drawHotspots(self.hotspotsRenderLast, smallIconVariation)
	end
	if self.selectedHotspot ~= nil then
		local zoom = self.layout:getIconZoom()
		local scale = self.uiScale * zoom
		self:drawHotspot(self.selectedHotspot, smallIconVariation, scale)
	end
end
function IngameMap:drawPersistentPointsOfInterest()
	local smallIconVariation = self.layout:getShowSmallIconVariation()
	self:drawHotspots(self.hotspotsPersistent, smallIconVariation)
	if 0 < #self.hotspotsPersistentRenderLast then
		new2DLayer()
		self:drawHotspots(self.hotspotsPersistentRenderLast, smallIconVariation)
	end
end
function IngameMap:drawHotspots(hotspots, smallVersion)
	local zoom = self.layout:getIconZoom()
	local scale = self.uiScale * zoom
	for _, hotspot in ipairs(hotspots) do
		if hotspot == self.selectedHotspot then
			continue
		end
		self:drawHotspot(hotspot, smallVersion, scale)
	end
end
function IngameMap:drawHotspot(hotspot, smallVersion, scale, doDebug)
	if hotspot == nil then
		return
	end
	local layout = self.layout
	local worldX, worldZ = hotspot:getWorldPosition()
	local rotation = hotspot:getWorldRotation()
	local objectX = (worldX + self.worldCenterOffsetX) / self.worldSizeX * self.mapExtensionScaleFactor + self.mapExtensionOffsetX
	local objectZ = (worldZ + self.worldCenterOffsetZ) / self.worldSizeZ * self.mapExtensionScaleFactor + self.mapExtensionOffsetZ
	if hotspot.scale ~= scale then
		hotspot:setScale(scale)
	end
	local width, height = hotspot:getDimension()
	local x, y, yRot, visible = layout:getMapObjectPosition(objectX, objectZ, width, height, rotation, hotspot:getIsPersistent())
	if not visible then
		return
	elseif not (self.clipHotspots and (self.clipX1 ~= nil and (x < self.clipX1 or self.clipX2 < x + width or y < self.clipY1 or self.clipY2 < y + height))) then
		hotspot.lastScreenPositionX = x
		hotspot.lastScreenPositionY = y
		hotspot.lastScreenRotation = yRot
		hotspot.lastScreenLayout = layout
		hotspot:render(x, y, yRot, smallVersion)
	end
end
function IngameMap:setScale(uiScale)
	IngameMap:superClass().setScale(self, uiScale, uiScale)
	self.uiScale = uiScale
	self:storeScaledValues(uiScale)
end
function IngameMap:storeScaledValues(uiScale)
	for _, layout in ipairs(self.layouts) do
		layout:storeScaledValues(self, uiScale)
	end
	self.helpAnchorOffsetX, self.helpAnchorOffsetY = self:scalePixelValuesToScreenVector(0, 15)
end
function IngameMap:getHelpAnchorPosition()
	if not self.isVisible then
		return 0, 0
	else
		local posX, posY = self.layout:getPosition()
		posX = posX + self.layout:getWidth() * 0.5 + self.helpAnchorOffsetX
		posY = posY + self.layout:getHeight() + self.helpAnchorOffsetY
		return posX, posY
	end
end
function IngameMap:getBackgroundPosition()
	return g_safeFrameOffsetX, g_safeFrameOffsetY
end
function IngameMap:setMapClipArea(clipX1, clipY1, clipX2, clipY2)
	self.clipX1 = clipX1
	self.clipY1 = clipY1
	self.clipX2 = clipX2
	self.clipY2 = clipY2
end
function IngameMap:createBackground()
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.SELF))
	local posX, posY = self:getBackgroundPosition()
	local overlay = g_overlayManager:createOverlay(IngameMap.SLICE_IDS.BACKGROUND_ROUND, posX, posY, width, height)
	overlay:setColor(0, 0, 0, 0.75)
	return overlay
end
function IngameMap:createComponents()
	local baseX, baseY = self:getPosition()
	local width = self:getWidth()
	local height = self:getHeight()
	self:createToggleMapSizeGlyph(baseX, baseY, width, height)
end
function IngameMap:createToggleMapSizeGlyph(baseX, baseY, baseWidth, baseHeight)
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.INPUT_ICON))
	local offX, offY = getNormalizedScreenValues(unpack(IngameMap.POSITION.INPUT_ICON))
	local element = InputGlyphElement.new(g_inputDisplayManager, width, height)
	local posX = baseX + offX
	local posY = baseY + offY
	element:setPosition(posX, posY)
	element:setKeyboardGlyphColor(IngameMap.COLOR.INPUT_ICON)
	element:setAction(InputAction.TOGGLE_MAP_SIZE)
	self.toggleMapSizeGlyph = element
	self:addChild(element)
end
IngameMap.MIN_MAP_WIDTH = Platform.isMobile and 600 or 300
IngameMap.MIN_MAP_HEIGHT = IngameMap.MIN_MAP_WIDTH
IngameMap.SIZE = { MAP = { 236, 236 }, SELF = { 256, 256 }, INPUT_ICON = { 35, 35 } }
IngameMap.TEXT_SIZE = { GLYPH_TEXT = 16 }
IngameMap.POSITION = { MAP = { 10, 10 }, MAP_LABEL = { 0, 3 }, INFO_TEXT = { 6, 12 }, INPUT_ICON = { 6, 6 } }
IngameMap.SLICE_IDS = { BACKGROUND_ROUND = "gui.minimapFrame", BACKGROUND_SQUARE = "gui.colorPreset", UNREAD_MESSAGES = "gui.newMessage", UNREAD_MESSAGES_BG = "gui.gearBg", NORTH_ARROW = "gui.tourdialogue_arrow" }
IngameMap.COLOR = { INPUT_ICON = { 0.0003, 0.5647, 0.9822, 0.8 }, COORDINATES_TEXT = { 1, 1, 1, 1 }, LATENCY_GOOD = { 1, 1, 1, 1 }, LATENCY_MEDIUM = { 0.9301, 0.2874, 0.013, 1 }, LATENCY_BAD = { 0.8069, 0.0097, 0.0097, 1 } }
