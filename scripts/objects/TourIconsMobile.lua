-- Local values: TourIconsMobile_mt
TourIconsMobile = {}
local TourIconsMobile_mt = Class(TourIconsMobile)

-- Local values: tourIcons
function TourIconsMobile:onCreate(id)
	local v3_ = TourIconsMobile.new(id)
	g_currentMission:addUpdateable(v3_)
	g_currentMission.tourIconsBase = v3_
end

-- Upvalues: TourIconsMobile_mt
-- Local values: self, num, i, tourIconTriggerId, tourIconId, tourIcon, plowLevelMaxValue, limeLevelMaxValue
function TourIconsMobile.new(id)
	-- upvalues: (copy) TourIconsMobile_mt
	local v5_ = TourIconsMobile_mt
	local v6_ = setmetatable({}, v5_)
	v6_.me = id
	local v7_ = getNumOfChildren(v6_.me)
	v6_.tourIcons = {}
	for v8_ = 0, v7_ - 1 do
		local v9_ = getChildAt(v6_.me, v8_)
		local v10_ = getChildAt(v9_, 0)
		addTrigger(v9_, "triggerCallback", v6_)
		setVisibility(v10_, false)
		local v11_ = v6_.tourIcons
		table.insert(v11_, {
			["tourIconTriggerId"] = v9_,
			["tourIconId"] = v10_
		})
	end
	v6_.visible = false
	v6_.mapHotspot = nil
	v6_.currentTourIconNumber = 1
	v6_.alpha = 0.25
	v6_.alphaDirection = 1
	v6_.startTourDialog = false
	v6_.startTourDialogDelay = 0
	v6_.permanentMessageDelay = 0
	v6_.isPaused = false
	v6_.pauseTime = 0
	v6_.soldStuffAtGrainElevator = false
	local v12_ = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
	local v13_ = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
	v6_.plowLevelMaxValue = v12_
	v6_.limeLevelMaxValue = v13_
	local v14_, v15_ = getNormalizedScreenValues(0, 28)
	_ = v14_
	v6_.permanentTextSize = v15_
	return v6_
end

-- Local values: _, tourIcon
function TourIconsMobile:delete()
	g_currentMission:removeUpdateable(self)
	for _, v17_ in pairs(self.tourIcons) do
		removeTrigger(v17_.tourIconTriggerId)
	end
	if self.me ~= 0 then
		delete(self.me)
		self.me = 0
	end
end

function TourIconsMobile:showTourDialog()
	YesNoDialog.show(self.reactToDialog, self, g_i18n:getText("tour_text_start"), "")
end

function TourIconsMobile:reactToDialog(yes)
	if yes then
		self.visible = true
		self:activateNextIcon()
		if g_currentMission.helpIconsBase ~= nil then
			g_currentMission.helpIconsBase:showHelpIcons(false, true)
			return
		end
	else
		self.visible = false
		InfoDialog.show(g_i18n:getText("tour_mobile_abort"))
		self:delete()
	end
end

function TourIconsMobile:update(dt)
	if not g_currentMission.missionInfo.isValid and (g_server ~= nil and (self.initDone == nil and g_currentMission:getIsTourSupported())) then
		self.initDone = true
		g_currentMission:fadeScreen(-1, 3000, function()
			-- upvalues: (copy) self
			self.canStart = true
		end, self)
		Logging.devWarning("TourIconsMobile:update not yet implemented with new polygon system")
	end
	if self.startTourDialog and self.canStart then
		self.startTourDialogDelay = self.startTourDialogDelay - dt
		if self.startTourDialogDelay < 0 then
			self.startTourDialog = false
			self:showTourDialog()
		end
	end
	if g_gui:getIsGuiVisible() then
		return
	elseif self.queuedMessage == nil then
		if self.isPaused then
			if self.pauseTime > 0 then
				self.pauseTime = self.pauseTime - dt
			else
				self.pauseTime = 0
				self.isPaused = false
				self:activateNextIcon()
			end
		end
		if self.visible and not self.isPaused then
			if self.currentTourIconNumber == 2 then
				if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourCombine and g_currentMission.tourVehicles.tourCombine:getActionControllerDirection() < 0) then
					self.pauseTime = 2000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 4 then
				if g_currentMission.tourVehicles.tourCombine:getIsTurnedOn() and g_currentMission.tourVehicles.tourCombine:getIsAIActive() then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 5 then
				if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 6 then
				if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTractor1:getActionControllerDirection() < 0) then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 8 then
				if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor2 then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 9 then
				if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor2 and g_currentMission.tourVehicles.tourSowingMachine.rootVehicle == g_currentMission.tourVehicles.tourTractor2) then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 11 then
				if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 13 then
				if g_currentMission.tourVehicles.tourCultivator.rootVehicle == g_currentMission.tourVehicles.tourCultivator then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 14 then
				if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer.rootVehicle == g_currentMission.tourVehicles.tourTractor1) then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 15 then
				if g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) > 800) then
					self.pauseTime = 1000
					self.isPaused = true
					return
				end
			elseif self.currentTourIconNumber == 17 and (g_localPlayer:getCurrentVehicle() ~= nil and (g_localPlayer:getCurrentVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) <= 2)) then
				self.pauseTime = 1000
				self.isPaused = true
			end
		end
	else
		g_currentMission.hud.ingameMap:toggleSize(IngameMapMobile.STATE_HIDDEN, true)
		InfoDialog.show(self.queuedMessage)
		self.queuedMessage = nil
	end
end

-- Local values: x, y, z, h
function TourIconsMobile:makeIconVisible(tourIconId)
	setVisibility(tourIconId, true)
	local v25_, v26_, v27_ = getWorldTranslation(tourIconId)
	if self.mapHotspot == nil then
		self.mapHotspot = TourHotspot.new()
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
	self.mapHotspot:setWorldPosition(v25_, v27_)
	if getTerrainHeightAtWorldPos(g_terrainNode, v25_, v26_, v27_) < v26_ then
		g_currentMission:setMapTargetHotspot(self.mapHotspot)
		g_currentMission.disableMapTargetHotspotHiding = true
	else
		g_currentMission:setMapTargetHotspot(nil)
		g_currentMission.disableMapTargetHotspotHiding = false
	end
end

-- Local values: object
function TourIconsMobile:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v32_ = g_currentMission:getNodeObject(otherId)
	if v32_ ~= nil and (v32_:isa(Vehicle) and (onEnter and (self.tourIcons[self.currentTourIconNumber] ~= nil and (self.tourIcons[self.currentTourIconNumber].tourIconTriggerId == triggerId and getVisibility(self.tourIcons[self.currentTourIconNumber].tourIconId))))) then
		self:activateNextIcon()
	end
end

-- Local values: i, tourIcon, title, text
function TourIconsMobile:activateNextIcon()
	for v34_ = 1, self.currentTourIconNumber do
		local v35_ = self.tourIcons[v34_]
		if getVisibility(v35_.tourIconId) then
			setVisibility(v35_.tourIconId, false)
			setCollisionFilterMask(v35_.tourIconTriggerId, 0)
		end
	end
	if self.tourIcons[self.currentTourIconNumber + 1] == nil then
		if self.mapHotspot ~= nil then
			g_currentMission:removeMapHotspot(self.mapHotspot)
			self.mapHotspot:delete()
			self.mapHotspot = nil
		end
		if g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_ICONS) and g_currentMission.helpIconsBase ~= nil then
			g_currentMission.helpIconsBase:showHelpIcons(true, true)
		end
		self.visible = false
		g_messageCenter:publish(MessageType.GUIDED_TOUR_FINISHED)
		self:delete()
	else
		self:makeIconVisible(self.tourIcons[self.currentTourIconNumber + 1].tourIconId)
	end
	local v36_ = g_i18n:getText("ui_tour")
	local v37_ = ""
	if self.currentTourIconNumber == 1 then
		v37_ = g_i18n:getText("tour_mobile_part01_activate")
	elseif self.currentTourIconNumber == 2 then
		v37_ = g_i18n:getText("tour_mobile_part01_drive")
	elseif self.currentTourIconNumber == 3 then
		v37_ = g_i18n:getText("tour_mobile_part01_helper")
	elseif self.currentTourIconNumber == 4 then
		v37_ = g_i18n:getText("tour_mobile_part01_finished")
	elseif self.currentTourIconNumber == 5 then
		v37_ = g_i18n:getText("tour_mobile_part02_activate")
	elseif self.currentTourIconNumber == 6 then
		v37_ = g_i18n:getText("tour_mobile_part02_drive")
	elseif self.currentTourIconNumber == 7 then
		v37_ = g_i18n:getText("tour_mobile_part02_finished")
	elseif self.currentTourIconNumber == 8 then
		v37_ = g_i18n:getText("tour_mobile_part03_attach")
	elseif self.currentTourIconNumber == 9 then
		v37_ = g_i18n:getText("tour_mobile_part03_activateDrive")
	elseif self.currentTourIconNumber == 10 then
		v37_ = g_i18n:getText("tour_mobile_part03_finished")
	elseif self.currentTourIconNumber == 11 then
		v37_ = g_i18n:getText("tour_mobile_part04_driveToYard")
	elseif self.currentTourIconNumber == 12 then
		v37_ = g_i18n:getText("tour_mobile_part04_detach")
	elseif self.currentTourIconNumber == 13 then
		v37_ = g_i18n:getText("tour_mobile_part04_attachTrailer")
	elseif self.currentTourIconNumber == 14 then
		v37_ = g_i18n:getText("tour_mobile_part04_driveToHarvester")
	elseif self.currentTourIconNumber == 15 then
		v37_ = g_i18n:getText("tour_mobile_part04_driveToSellpoint")
	elseif self.currentTourIconNumber == 16 then
		v37_ = g_i18n:getText("tour_mobile_part04_Unload")
	elseif self.currentTourIconNumber == 17 then
		v37_ = g_i18n:getText("tour_mobile_end")
	end
	if g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle().setCruiseControlState ~= nil then
		g_localPlayer:getCurrentVehicle():setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
	end
	if g_gui:getIsGuiVisible() then
		self.queuedMessage = {
			["title"] = v36_,
			["text"] = v37_
		}
	else
		g_currentMission.hud.ingameMap:toggleSize(IngameMapMobile.STATE_HIDDEN, true)
		InfoDialog.show(v37_)
	end
	self.currentTourIconNumber = self.currentTourIconNumber + 1
	self.permanentMessageDelay = 250
end
