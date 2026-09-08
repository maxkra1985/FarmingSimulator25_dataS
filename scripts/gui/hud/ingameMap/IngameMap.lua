-- Local values: IngameMap_mt
IngameMap = {}
local IngameMap_mt = Class(IngameMap, HUDElement)
IngameMap.alpha = 1
IngameMap.alphaInc = 0.005
IngameMap.maxIconZoom = 1.4
IngameMap.DEFAULT_SORTING_PRIO = {
	MapHotspot.CATEGORY_FIELD,
	MapHotspot.CATEGORY_ANIMAL,
	MapHotspot.CATEGORY_MISSION,
	MapHotspot.CATEGORY_TOUR,
	MapHotspot.CATEGORY_STEERABLE,
	MapHotspot.CATEGORY_COMBINE,
	MapHotspot.CATEGORY_TRAILER,
	MapHotspot.CATEGORY_TOOL,
	MapHotspot.CATEGORY_UNLOADING,
	MapHotspot.CATEGORY_LOADING,
	MapHotspot.CATEGORY_PRODUCTION,
	MapHotspot.CATEGORY_SHOP,
	MapHotspot.CATEGORY_OTHER,
	MapHotspot.CATEGORY_AI,
	MapHotspot.CATEGORY_PLAYER
}

-- Upvalues: IngameMap_mt
-- Local values: self, _, layout, setDefaultValue, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category, filter, category
function IngameMap.new(customMt)
	-- upvalues: (copy) IngameMap_mt
	local v3_ = IngameMap:superClass().new(nil, nil, customMt or IngameMap_mt)
	v3_.overlay = v3_:createBackground()
	v3_.uiScale = 1
	v3_.isVisible = true
	v3_.clipHotspots = false
	v3_.fullScreenLayout = IngameMapLayoutFullscreen.new()
	v3_.layouts = {
		IngameMapLayoutNone.new(),
		IngameMapLayoutCircle.new(),
		IngameMapLayoutSquare.new(),
		IngameMapLayoutSquareLarge.new(),
		v3_.fullScreenLayout
	}
	v3_.state = 1
	v3_.numToggleStates = 4
	v3_.layout = v3_.layouts[v3_.state]
	v3_.mapOverlay = Overlay.new(nil, 0, 0, 1, 1)
	v3_.mapElement = HUDElement.new(v3_.mapOverlay)
	v3_:createComponents()
	for _, v4_ in ipairs(v3_.layouts) do
		v4_:createComponents(v3_)
	end
	v3_.filter = {}
	local v5_ = v3_.filter
	local v6_ = MapHotspot.CATEGORY_FIELD
	v5_[v6_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v6_)
	local v7_ = v3_.filter
	local v8_ = MapHotspot.CATEGORY_ANIMAL
	v7_[v8_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v8_)
	local v9_ = v3_.filter
	local v10_ = MapHotspot.CATEGORY_MISSION
	v9_[v10_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v10_)
	local v11_ = v3_.filter
	local v12_ = MapHotspot.CATEGORY_TOUR
	v11_[v12_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v12_)
	local v13_ = v3_.filter
	local v14_ = MapHotspot.CATEGORY_STEERABLE
	v13_[v14_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v14_)
	local v15_ = v3_.filter
	local v16_ = MapHotspot.CATEGORY_COMBINE
	v15_[v16_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v16_)
	local v17_ = v3_.filter
	local v18_ = MapHotspot.CATEGORY_TRAILER
	v17_[v18_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v18_)
	local v19_ = v3_.filter
	local v20_ = MapHotspot.CATEGORY_TOOL
	v19_[v20_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v20_)
	local v21_ = v3_.filter
	local v22_ = MapHotspot.CATEGORY_UNLOADING
	v21_[v22_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v22_)
	local v23_ = v3_.filter
	local v24_ = MapHotspot.CATEGORY_LOADING
	v23_[v24_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v24_)
	local v25_ = v3_.filter
	local v26_ = MapHotspot.CATEGORY_PRODUCTION
	v25_[v26_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v26_)
	local v27_ = v3_.filter
	local v28_ = MapHotspot.CATEGORY_OTHER
	v27_[v28_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v28_)
	local v29_ = v3_.filter
	local v30_ = MapHotspot.CATEGORY_SHOP
	v29_[v30_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v30_)
	local v31_ = v3_.filter
	local v32_ = MapHotspot.CATEGORY_AI
	v31_[v32_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v32_)
	local v33_ = v3_.filter
	local v34_ = MapHotspot.CATEGORY_PLAYER
	v33_[v34_] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), v34_)
	v3_.currentFilter = v3_.filter
	v3_:setWorldSize(2048, 2048)
	v3_.hotspots = {}
	v3_.selectedHotspot = nil
	v3_.mapExtensionOffsetX = 0.25
	v3_.mapExtensionOffsetZ = 0.25
	v3_.mapExtensionScaleFactor = 0.5
	v3_.allowToggle = true
	v3_.hotspotsDirty = true
	v3_.hotspotsRegular = {}
	v3_.hotspotsRenderLast = {}
	v3_.hotspotsPersistent = {}
	v3_.hotspotsPersistentRenderLast = {}
	v3_.hotspotsPostUpdate = {}
	v3_.topDownCamera = nil
	return v3_
end

-- Local values: _, layout
function IngameMap:delete()
	g_inputBinding:removeActionEventsByTarget(self)
	self.mapElement:delete()
	self:setSelectedHotspot(nil)
	for _, v36_ in ipairs(self.layouts) do
		v36_:delete()
	end
	IngameMap:superClass().delete(self)
end

-- Local values: newLayout
function IngameMap:setFullscreen(isFullscreen)
	if self.isFullscreen ~= isFullscreen then
		self.isFullscreen = isFullscreen
		local v39_ = self.layouts[self.state]
		if isFullscreen then
			v39_ = self.fullScreenLayout
		end
		self:setLayout(v39_)
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

-- Local values: newLayout
function IngameMap:setCustomLayout(layout)
	local v44_ = layout or self.layouts[self.state]
	v44_:setWorldSize(self.worldSizeX, self.worldSizeZ)
	v44_:setMapExtensionSettings(self.mapExtensionScaleFactor, self.mapExtensionOffsetX, self.mapExtensionOffsetZ)
	self:setLayout(v44_)
end

function IngameMap:toggleSize(state, force)
	if state == nil then
		self.state = self.state % self.numToggleStates + 1
	else
		local v47_ = self.numToggleStates
		local v48_ = math.min(state, v47_)
		self.state = math.max(v48_, 1)
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
	if guiTopDownCamera == nil then
		if self.state ~= self.previousLayout then
			self:toggleSize(self.previousLayout, true)
		end
	else
		self.previousLayout = self.state
		if self.state ~= IngameMapState.MINIMAP_ROUND then
			self:toggleSize(IngameMapState.MINIMAP_ROUND, true)
			return
		end
	end
end

function IngameMap:resetSettings()
	if self.overlay ~= nil then
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
	local v60_ = g_inputBinding
	local v61_ = self.toggleMapSizeEventId
	if isVisible then
		isVisible = self.layout:getShowsToggleActionText()
	end
	v60_:setActionEventActive(v61_, isVisible)
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

-- Local values: _, eventId
function IngameMap:registerInput()
	local _, v68_ = g_inputBinding:registerActionEvent(InputAction.TOGGLE_MAP_SIZE, self, self.onToggleMapSize, false, true, false, true)
	self.toggleMapSizeEventId = v68_
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.layout:getShowsToggleActionText())
	g_inputBinding:setActionEventTextPriority(self.toggleMapSizeEventId, GS_PRIO_VERY_LOW)
end

-- Local values: _, layout
function IngameMap:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeX = worldSizeX
	self.worldSizeZ = worldSizeZ
	self.worldCenterOffsetX = self.worldSizeX * 0.5
	self.worldCenterOffsetZ = self.worldSizeZ * 0.5
	for _, v72_ in ipairs(self.layouts) do
		v72_:setWorldSize(worldSizeX, worldSizeZ)
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

-- Local values: i, spot
function IngameMap:getHotspotIndex(hotspot)
	for v84_, v85_ in ipairs(self.hotspots) do
		if v85_ == hotspot then
			return v84_
		end
	end
	return -1
end

-- Local values: currentIndex, visitedCount, hotspot, category
function IngameMap:cycleVisibleHotspot(currentHotspot, categoriesHash, direction)
	local v90_ = self:getHotspotIndex(currentHotspot) + direction
	local v91_ = (v90_ < 1 or #self.hotspots < v90_) and (direction > 0 and 1 or #self.hotspots) or v90_
	local v92_ = self.hotspots[v91_]
	local v93_ = 0
	while v93_ < #self.hotspots do
		local v94_ = v92_:getCategory()
		if (v92_:getIsVisible() or g_localPlayer:getCurrentVehicle() == v92_.vehicle and v92_.vehicle ~= nil) and (self.currentFilter[v94_] and categoriesHash[v94_]) then
			break
		end
		v93_ = v93_ + 1
		local v95_ = v91_ + direction
		v91_ = #self.hotspots < v95_ and 1 or (v95_ < 1 and #self.hotspots or v95_)
		v92_ = self.hotspots[v91_]
	end
	if v93_ < #self.hotspots then
		return v92_
	else
		return nil
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

-- Local values: _, hotspot, isVisible, category, isPersistent, isRenderLast
function IngameMap:updateHotspotSorting(dt)
	if self.hotspotsDirty then
		self.hotspotsDirty = false
		for _, v98_ in pairs(self.hotspots) do
			if v98_.postUpdate ~= nil then
				local v99_ = self.hotspotsPostUpdate
				table.insert(v99_, v98_)
			end
			if v98_:getIsVisible() then
				local v100_ = v98_:getCategory()
				if self.currentFilter[v100_] then
					local v101_ = v98_:getIsPersistent()
					local v102_ = v98_:getRenderLast()
					if v101_ then
						if v102_ then
							local v103_ = self.hotspotsPersistentRenderLast
							table.insert(v103_, v98_)
						else
							local v104_ = self.hotspotsPersistent
							table.insert(v104_, v98_)
						end
					elseif v102_ then
						local v105_ = self.hotspotsRenderLast
						table.insert(v105_, v98_)
					else
						local v106_ = self.hotspotsRegular
						table.insert(v106_, v98_)
					end
				end
			end
		end
	end
end

function IngameMap:updateBlinkingHotspotAlpha(dt)
	local v107_ = IngameMap
	local v108_ = g_time / 200
	local v109_ = math.sin(v108_)
	v107_.alpha = math.abs(v109_)
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
	if category == nil then
		return false
	else
		return self.filter[category]
	end
end

function IngameMap:applyCustomFilter(filter)
	self.currentFilter = filter
	self:resetHotspotSorting()
end

-- Local values: prio, category
function IngameMap:applyCustomHotspotSortingOrder(sortingPrio)
	local v124_ = sortingPrio or IngameMap.DEFAULT_SORTING_PRIO
	self.sortingOrder = {}
	for v125_, v126_ in ipairs(v124_) do
		self.sortingOrder[v126_] = v125_
	end
	self:sortHotspots()
	self:resetHotspotSorting()
end

-- Local values: sortingOrder
function IngameMap:sortHotspots()
	if self.sortingOrder == nil then
		self:applyCustomHotspotSortingOrder(nil)
	end
	local v_u_128_ = self.sortingOrder
	table.sort(self.hotspots, function(p129_, p130_)
		-- upvalues: (copy) v_u_128_
		local v131_ = v_u_128_[p129_:getCategory()]
		local v132_ = v_u_128_[p130_:getCategory()]
		if v131_ == nil then
			return false
		else
			return v132_ == nil and true or v131_ < v132_
		end
	end)
end

function IngameMap:restoreDefaultFilter()
	self.currentFilter = self.filter
	self:resetHotspotSorting()
end

-- Local values: filter, k, _
function IngameMap:createCustomFilter(default)
	local v136_ = {}
	for v137_, _ in pairs(self.filter) do
		v136_[v137_] = default
	end
	return v136_
end

function IngameMap:update(dt)
	self:updateBlinkingHotspotAlpha(dt)
	self:updatePlayerPosition()
	self.layout:setPlayerPosition(self.normalizedPlayerPosX, self.normalizedPlayerPosZ, self.playerRotation)
	self.layout:setPlayerVelocity(self.playerVelocity or 0)
end

-- Local values: _, hotspot
function IngameMap:postUpdate(dt)
	self:updateHotspotSorting()
	self.layout:postUpdate(dt)
	for _, v142_ in ipairs(self.hotspotsPostUpdate) do
		v142_:postUpdate(dt)
	end
end

function IngameMap:updateInputGlyphs()
	self.toggleMapSizeGlyph:setAction(InputAction.TOGGLE_MAP_SIZE)
end

-- Local values: playerPosX, _, playerPosZ, localPlayer
function IngameMap:updatePlayerPosition()
	local v145_ = 0
	local v146_ = 0
	local v147_ = g_localPlayer
	self.playerRotation = 0
	self.playerVelocity = 0
	if self.topDownCamera == nil then
		if v147_ ~= nil then
			local v148_
			v145_, v148_, v146_ = v147_:getPosition()
			self.playerRotation = v147_:getYaw()
			self.playerVelocity = v147_:getSpeed()
		end
	else
		local v149_, v150_, v151_
		v145_, v149_, v146_, v150_, v151_ = self.topDownCamera:determineMapPosition()
		self.playerRotation = v150_
		self.playerVelocity = v151_
	end
	local v152_ = (v145_ + self.worldCenterOffsetX) / self.worldSizeX
	self.normalizedPlayerPosX = math.clamp(v152_, 0, 1)
	local v153_ = (v146_ + self.worldCenterOffsetZ) / self.worldSizeZ
	self.normalizedPlayerPosZ = math.clamp(v153_, 0, 1)
end

-- Local values: width, height
function IngameMap:draw()
	if self.isVisible then
		local v155_, v156_ = self.layout:getMapSize()
		if v155_ ~= 0 and v156_ ~= 0 then
			self.mapElement:setDimension(v155_, v156_)
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
	else
		return
	end
end

-- Local values: mapOverlayGenerator, overlay, width, height, x, y, px, py, posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4
function IngameMap:drawFields()
	local v158_ = g_currentMission.mapOverlayGenerator
	if v158_ ~= nil then
		local v159_ = v158_:getFieldsOverlay()
		if v159_ ~= nil then
			local v160_, v161_ = self.layout:getMapSize()
			local v162_, v163_ = self.layout:getMapPosition()
			local v164_, v165_ = self.layout:getMapPivot()
			local v166_ = v164_ + v162_
			local v167_ = v165_ + v163_
			local v168_ = v162_ + v160_ * self.mapExtensionOffsetX
			local v169_ = v163_ + v161_ * self.mapExtensionOffsetZ
			local v170_ = v166_ - v168_
			local v171_ = v167_ - v169_
			local v172_ = v160_ * self.mapExtensionScaleFactor
			local v173_ = v161_ * self.mapExtensionScaleFactor
			if self.clipX1 ~= nil then
				local v174_, v175_, v176_, v177_, v178_, v179_, v180_, v181_
				v168_, v169_, v172_, v173_, v174_, v175_, v176_, v177_, v178_, v179_, v180_, v181_ = Overlay.getClippingUVs(Overlay.DEFAULT_UVS, v168_, v169_, v172_, v173_, self.clipX1, self.clipY1, self.clipX2, self.clipY2)
				if v174_ == nil then
					return
				end
				setOverlayUVs(v159_, v174_, v175_, v176_, v177_, v178_, v179_, v180_, v181_)
			end
			setOverlayRotation(v159_, self.layout:getMapRotation(), v170_, v171_)
			local v182_ = setOverlayColor
			local v183_ = self.layout:getMapAlpha()
			v182_(v159_, 1, 1, 1, (math.sqrt(v183_)))
			renderOverlay(v159_, v168_, v169_, v172_, v173_)
			if self.clipX1 ~= nil then
				local v184_ = setOverlayUVs
				local v185_ = Overlay.DEFAULT_UVS
				v184_(v159_, unpack(v185_))
			end
		end
	end
end

-- Local values: width, height
function IngameMap:drawMapOnly()
	local v187_, v188_ = self.layout:getMapSize()
	self.mapElement:setDimension(v187_, v188_)
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

-- Local values: rotation, renderString
function IngameMap:drawPlayersCoordinates()
	local v191_ = self.playerRotation - 3.141592653589793
	local v192_ = math.abs(v191_)
	local v193_ = math.deg(v192_)
	local v194_ = string.format("%.1f\194\176, %d, %d", v193_, self.normalizedPlayerPosX * self.worldSizeX, self.normalizedPlayerPosZ * self.worldSizeZ)
	self.layout:drawCoordinates(v194_)
end

-- Local values: missionDynamicInfo, color
function IngameMap:drawLatencyToServer()
	local v196_ = g_currentMission.missionDynamicInfo
	if g_client ~= nil and (g_client.currentLatency ~= nil and (v196_.isMultiplayer and v196_.isClient)) then
		local v197_
		if g_client.currentLatency <= 50 then
			v197_ = IngameMap.COLOR.LATENCY_GOOD
		elseif g_client.currentLatency < 100 then
			v197_ = IngameMap.COLOR.LATENCY_MEDIUM
		else
			v197_ = IngameMap.COLOR.LATENCY_BAD
		end
		local v198_ = self.layout
		local v199_ = string.format
		local v200_ = g_client.currentLatency
		v198_:drawLatency(v199_("%dms", (math.max(v200_, 10))), v197_)
	end
end

-- Local values: smallIconVariation, zoom, scale
function IngameMap:drawPointsOfInterest()
	local v202_ = self.layout:getShowSmallIconVariation()
	if v202_ then
		v202_ = not Platform.isMobile
	end
	self:drawHotspots(self.hotspotsRegular, v202_)
	if #self.hotspotsRenderLast > 0 then
		new2DLayer()
		self:drawHotspots(self.hotspotsRenderLast, v202_)
	end
	if self.selectedHotspot ~= nil then
		local v203_ = self.layout:getIconZoom()
		local v204_ = self.uiScale * v203_
		self:drawHotspot(self.selectedHotspot, v202_, v204_)
	end
end

-- Local values: smallIconVariation
function IngameMap:drawPersistentPointsOfInterest()
	local v206_ = self.layout:getShowSmallIconVariation()
	self:drawHotspots(self.hotspotsPersistent, v206_)
	if #self.hotspotsPersistentRenderLast > 0 then
		new2DLayer()
		self:drawHotspots(self.hotspotsPersistentRenderLast, v206_)
	end
end

-- Local values: zoom, scale, _, hotspot
function IngameMap:drawHotspots(hotspots, smallVersion)
	local v210_ = self.layout:getIconZoom()
	local v211_ = self.uiScale * v210_
	for _, v212_ in ipairs(hotspots) do
		if v212_ ~= self.selectedHotspot then
			self:drawHotspot(v212_, smallVersion, v211_)
		end
	end
end

-- Local values: layout, worldX, worldZ, rotation, objectX, objectZ, width, height, x, y, yRot, visible
function IngameMap:drawHotspot(hotspot, smallVersion, scale, doDebug)
	if hotspot == nil then
		return
	else
		local v217_ = self.layout
		local v218_, v219_ = hotspot:getWorldPosition()
		local v220_ = hotspot:getWorldRotation()
		local v221_ = (v218_ + self.worldCenterOffsetX) / self.worldSizeX * self.mapExtensionScaleFactor + self.mapExtensionOffsetX
		local v222_ = (v219_ + self.worldCenterOffsetZ) / self.worldSizeZ * self.mapExtensionScaleFactor + self.mapExtensionOffsetZ
		if hotspot.scale ~= scale then
			hotspot:setScale(scale)
		end
		local v223_, v224_ = hotspot:getDimension()
		local v225_, v226_, v227_, v228_ = v217_:getMapObjectPosition(v221_, v222_, v223_, v224_, v220_, hotspot:getIsPersistent())
		if v228_ then
			if not self.clipHotspots or (self.clipX1 == nil or v225_ >= self.clipX1 and (v225_ + v223_ <= self.clipX2 and (v226_ >= self.clipY1 and v226_ + v224_ <= self.clipY2))) then
				hotspot.lastScreenPositionX = v225_
				hotspot.lastScreenPositionY = v226_
				hotspot.lastScreenRotation = v227_
				hotspot.lastScreenLayout = v217_
				hotspot:render(v225_, v226_, v227_, smallVersion)
			end
		else
			return
		end
	end
end

function IngameMap:setScale(uiScale)
	IngameMap:superClass().setScale(self, uiScale, uiScale)
	self.uiScale = uiScale
	self:storeScaledValues(uiScale)
end

-- Local values: _, layout
function IngameMap:storeScaledValues(uiScale)
	for _, v233_ in ipairs(self.layouts) do
		v233_:storeScaledValues(self, uiScale)
	end
	local v234_, v235_ = self:scalePixelValuesToScreenVector(0, 15)
	self.helpAnchorOffsetX = v234_
	self.helpAnchorOffsetY = v235_
end

-- Local values: posX, posY
function IngameMap:getHelpAnchorPosition()
	if not self.isVisible then
		return 0, 0
	end
	local v237_, v238_ = self.layout:getPosition()
	return v237_ + self.layout:getWidth() * 0.5 + self.helpAnchorOffsetX, v238_ + self.layout:getHeight() + self.helpAnchorOffsetY
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

-- Local values: width, height, posX, posY, overlay
function IngameMap:createBackground()
	local v245_ = getNormalizedScreenValues
	local v246_ = IngameMap.SIZE.SELF
	local v247_, v248_ = v245_(unpack(v246_))
	local v249_, v250_ = self:getBackgroundPosition()
	local v251_ = g_overlayManager:createOverlay(IngameMap.SLICE_IDS.BACKGROUND_ROUND, v249_, v250_, v247_, v248_)
	v251_:setColor(0, 0, 0, 0.75)
	return v251_
end

-- Local values: baseX, baseY, width, height
function IngameMap:createComponents()
	local v253_, v254_ = self:getPosition()
	self:createToggleMapSizeGlyph(v253_, v254_, self:getWidth(), (self:getHeight()))
end

-- Local values: width, height, offX, offY, element, posX, posY
function IngameMap:createToggleMapSizeGlyph(baseX, baseY, baseWidth, baseHeight)
	local v258_ = getNormalizedScreenValues
	local v259_ = IngameMap.SIZE.INPUT_ICON
	local v260_, v261_ = v258_(unpack(v259_))
	local v262_ = getNormalizedScreenValues
	local v263_ = IngameMap.POSITION.INPUT_ICON
	local v264_, v265_ = v262_(unpack(v263_))
	local v266_ = InputGlyphElement.new(g_inputDisplayManager, v260_, v261_)
	v266_:setPosition(baseX + v264_, baseY + v265_)
	v266_:setKeyboardGlyphColor(IngameMap.COLOR.INPUT_ICON)
	v266_:setAction(InputAction.TOGGLE_MAP_SIZE)
	self.toggleMapSizeGlyph = v266_
	self:addChild(v266_)
end
IngameMap.MIN_MAP_WIDTH = Platform.isMobile and 600 or 300
IngameMap.MIN_MAP_HEIGHT = IngameMap.MIN_MAP_WIDTH
IngameMap.SIZE = {
	["MAP"] = { 236, 236 },
	["SELF"] = { 256, 256 },
	["INPUT_ICON"] = { 35, 35 }
}
IngameMap.TEXT_SIZE = {
	["GLYPH_TEXT"] = 16
}
IngameMap.POSITION = {
	["MAP"] = { 10, 10 },
	["MAP_LABEL"] = { 0, 3 },
	["INFO_TEXT"] = { 6, 12 },
	["INPUT_ICON"] = { 6, 6 }
}
IngameMap.SLICE_IDS = {
	["BACKGROUND_ROUND"] = "gui.minimapFrame",
	["BACKGROUND_SQUARE"] = "gui.colorPreset",
	["UNREAD_MESSAGES"] = "gui.newMessage",
	["UNREAD_MESSAGES_BG"] = "gui.gearBg",
	["NORTH_ARROW"] = "gui.tourdialogue_arrow"
}
IngameMap.COLOR = {
	["INPUT_ICON"] = {
		0.0003,
		0.5647,
		0.9822,
		0.8
	},
	["COORDINATES_TEXT"] = {
		1,
		1,
		1,
		1
	},
	["LATENCY_GOOD"] = {
		1,
		1,
		1,
		1
	},
	["LATENCY_MEDIUM"] = {
		0.9301,
		0.2874,
		0.013,
		1
	},
	["LATENCY_BAD"] = {
		0.8069,
		0.0097,
		0.0097,
		1
	}
}
