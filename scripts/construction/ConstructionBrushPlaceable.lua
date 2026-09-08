-- Local values: ConstructionBrushPlaceable_mt
ConstructionBrushPlaceable = {}
local ConstructionBrushPlaceable_mt = Class(ConstructionBrushPlaceable, ConstructionBrush)
ConstructionBrushPlaceable.ERROR = {
	["NOT_ENOUGH_MONEY"] = 200,
	["NOT_ENOUGH_SLOTS"] = 201,
	["CANNOT_BE_BOUGHT"] = 202,
	["CANNOT_BE_PLACED_HERE"] = 203,
	["PLAYER_COLLISION"] = 204,
	["OBJECT_OVERLAP"] = 205,
	["DEFORM_FAILED"] = 206,
	["BLOCKED"] = 207
}
ConstructionBrushPlaceable.ERROR_MESSAGES = {
	[ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_SLOTS] = "ui_construction_notEnoughSlots",
	[ConstructionBrushPlaceable.ERROR.CANNOT_BE_BOUGHT] = "ui_construction_cannotBeBought",
	[ConstructionBrushPlaceable.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere",
	[ConstructionBrushPlaceable.ERROR.PLAYER_COLLISION] = "ui_construction_collidesWithPlayer",
	[ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP] = "ui_construction_overlapsWithObject",
	[ConstructionBrushPlaceable.ERROR.DEFORM_FAILED] = "ui_construction_deformationFailed",
	[ConstructionBrushPlaceable.ERROR.BLOCKED] = "ui_construction_deformationBlocked"
}
ConstructionBrushPlaceable.LAST_SNAPPING_STATE = false
ConstructionBrushPlaceable.DISPLACEMENT_COST_PER_M3 = 5
ConstructionBrushPlaceable.MAX_ACTIVE_VALIDATIONS = 2

-- Upvalues: ConstructionBrushPlaceable_mt
-- Local values: self
function ConstructionBrushPlaceable.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushPlaceable_mt
	local v4_ = ConstructionBrushPlaceable:superClass().new(subclass_mt or ConstructionBrushPlaceable_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsPrimaryAxis = true
	v4_.primaryAxisIsContinuous = false
	v4_.supportsTertiaryButton = true
	v4_.configurations = nil
	v4_.placeableHasConfigs = false
	v4_.supportsSecondaryAxis = false
	v4_.secondaryAxisIsContinuous = false
	v4_.placeable = nil
	v4_.isLoading = false
	v4_.isPlacing = false
	v4_.offsetY = 0
	v4_.inputHeight = 0
	v4_.displacementCosts = 0
	v4_.colorIndex = 1
	v4_.placingText = g_i18n:getText("ui_construction_placingItem")
	v4_.loadingText = g_i18n:getText("ui_construction_loadingItem")
	v4_.errorText = nil
	v4_.errorEndTime = 0
	v4_.freeMode = false
	v4_.activeValidationCount = 0
	v4_.supportsSnapping = true
	v4_.snappingActive = ConstructionBrushPlaceable.LAST_SNAPPING_STATE
	v4_.snappingAngleDeg = 7.5
	v4_.snappingSize = 0.25
	v4_.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
	return v4_
end

function ConstructionBrushPlaceable:delete()
	ConstructionBrushPlaceable:superClass().delete(self)
end

function ConstructionBrushPlaceable:activate()
	ConstructionBrushPlaceable:superClass().activate(self)
	self.cursor:setRotationEnabled(true)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
	self.offsetY = 0
	self.coolDownTimer = 0
	self:loadPlaceable()
end

function ConstructionBrushPlaceable:deactivate()
	self:unloadPlaceable()
	self.coolDownTimer = 0
	if self.cursor ~= nil then
		self.cursor:setIsWaterDetectionActive(false)
	end
	ConstructionBrushPlaceable:superClass().deactivate(self)
end

-- Local values: _, configs
function ConstructionBrushPlaceable:setPlaceableFilename(xmlFilename)
	if not self.isActive then
		self.placeableXMLFilename = xmlFilename
		self.storeItem = g_storeManager:getItemByXMLFilename(xmlFilename)
		self.placeableHasConfigs = false
		if self.storeItem.configurations ~= nil then
			for _, v10_ in pairs(self.storeItem.configurations) do
				if #v10_ > 1 then
					self.placeableHasConfigs = true
					return
				end
			end
		end
	end
end

function ConstructionBrushPlaceable:setParameters(filename)
	self:setPlaceableFilename(filename)
end

function ConstructionBrushPlaceable:copyState(from)
	self.freeMode = from.freeMode
end

function ConstructionBrushPlaceable:update(dt)
	ConstructionBrushPlaceable:superClass().update(self, dt)
	self:updateHeightFromInput(dt)
	if self.errorText ~= nil and self.errorEndTime < g_time then
		self.errorText = nil
	end
	if self.coolDownTimer > 0 then
		self.coolDownTimer = self.coolDownTimer - dt
	end
	self:updatePlaceablePosition()
end

function ConstructionBrushPlaceable:updateHeightFromInput(dt)
	self.offsetY = self.offsetY + self.inputHeight * dt * 0.005
	self.inputHeight = 0
end

-- Local values: degAngle, _
function ConstructionBrushPlaceable:getSnappedRotation(rotY)
	if self.snappingActive then
		local v21_ = MathUtil.snapValue(math.deg(rotY), self.snappingAngleDeg)
		rotY = math.rad(v21_)
	end
	if self.placeable ~= nil and self.placeable.getPlacementRotation ~= nil then
		local v22_, v23_
		v22_, rotY, v23_ = self.placeable:getPlacementRotation(0, rotY, 0)
	end
	return rotY
end

-- Local values: snapSize
function ConstructionBrushPlaceable:getSnappedPosition(x, y, z)
	if x == nil then
		return nil
	end
	if self.snappingActive then
		local v28_ = 1 / self.snappingSize
		local v29_ = x * v28_
		x = math.floor(v29_) / v28_
		local v30_ = z * v28_
		z = math.floor(v30_) / v28_
	end
	if self.placeable ~= nil and self.placeable.getPlacementPosition ~= nil then
		x, y, z = self.placeable:getPlacementPosition(x, y, z)
	end
	return x, y + self.offsetY, z
end

function ConstructionBrushPlaceable:getDisplacementCost()
	return self.displacementCosts
end

function ConstructionBrushPlaceable:getPrice()
	return g_currentMission.economyManager:getBuyPrice(self.storeItem) + self:getDisplacementCost()
end

-- Local values: x, y, z, rotY, err, message
function ConstructionBrushPlaceable:updatePlaceablePosition()
	if self.errorText == nil then
		if self.isPlacing then
			self.cursor:setMessage(self.placingText)
			return
		elseif self.isLoading then
			self.cursor:setMessage(self.loadingText)
			return
		elseif self.placeable == nil then
			self.cursor:setErrorMessage(g_i18n:getText("ui_construction_couldNotLoadItem"))
		else
			local v34_, v35_, v36_ = self.cursor:getPosition()
			local v37_ = self.cursor:getRotation()
			self.placeable:startPlacementCheck(v34_, v35_, v36_, v37_)
			local v38_, v39_, v40_ = self:getSnappedPosition(v34_, v35_, v36_)
			local v41_ = self:getSnappedRotation(v37_)
			if v38_ ~= nil then
				self.placeable:setPreviewPosition(v38_, v39_, v40_, 0, v41_, 0)
				local v42_, v43_ = self:verifyPlacement(v38_, v39_, v40_, v41_)
				if v42_ == nil then
					if self.displacementError == nil then
						self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
					else
						self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushPlaceable.ERROR_MESSAGES[self.displacementError]))
					end
				else
					if v43_ == nil then
						v43_ = g_i18n:getText(ConstructionBrushPlaceable.ERROR_MESSAGES[v42_] or ConstructionBrush.ERROR_MESSAGES[v42_])
					end
					self.cursor:setErrorMessage(v43_)
				end
			end
			setVisibility(self.placeable.rootNode, self.cursor.isVisible)
		end
	else
		self.cursor:setErrorMessage(self.errorText)
		return
	end
end

-- Local values: price, enoughMoney, enoughSlots, canBuy, message, canBePlaced, placingFailedMessage, hasOverlap, node, isPlayer
function ConstructionBrushPlaceable:verifyPlacement(x, y, z, rotY)
	if not self:hasPlayerPermission() then
		return ConstructionBrush.ERROR.NO_PERMISSION
	end
	local v49_ = self:getPrice() <= g_currentMission:getMoney()
	local v50_ = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)
	if not v49_ then
		return ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_MONEY
	end
	if not v50_ then
		return ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_SLOTS
	end
	local v51_, v52_ = self.placeable:canBuy()
	if not v51_ then
		return ConstructionBrushPlaceable.ERROR.CANNOT_BE_BOUGHT, v52_
	end
	local v53_, v54_ = self.placeable:getCanBePlacedAt(x, y, z, g_currentMission:getFarmId())
	if not v53_ then
		return ConstructionBrushPlaceable.ERROR.CANNOT_BE_PLACED_HERE, v54_
	end
	if self.placeable.getIsOnOwnedFarmland ~= nil and not self.placeable:getIsOnOwnedFarmland(x, y, z, rotY) then
		return ConstructionBrush.ERROR.LAND_UNOWNED
	end
	if self.placeable.getHasOverlapWithZones ~= nil and self.placeable:getHasOverlapWithZones(g_currentMission.restrictedZones, x, y, z, rotY) then
		return ConstructionBrush.ERROR.RESTRICTED_ZONE
	end
	if self.placeable.getHasOverlapWithPlaces ~= nil then
		if self.placeable:getHasOverlapWithPlaces(g_currentMission.storeSpawnPlaces, x, y, z, rotY) then
			return ConstructionBrush.ERROR.STORE_PLACE
		end
		if self.placeable:getHasOverlapWithPlaces(g_currentMission.loadSpawnPlaces, x, y, z, rotY) then
			return ConstructionBrush.ERROR.SPAWN_PLACE
		end
	end
	if not self.freeMode and self.placeable.getHasOverlap ~= nil then
		local v55_, v56_ = self.placeable:getHasOverlap(x, y, z, rotY)
		if v55_ then
			if v56_ == nil or g_currentMission.players[v56_] == nil then
				return ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP
			else
				return ConstructionBrushPlaceable.ERROR.PLAYER_COLLISION
			end
		end
	end
	if not self.freeMode and (self.placeable.getRequiresLeveling ~= nil and (self.placeable:getRequiresLeveling() and self.activeValidationCount < ConstructionBrushPlaceable.MAX_ACTIVE_VALIDATIONS)) then
		self.terrainValidationPending = true
		self.activeValidationCount = self.activeValidationCount + 1
		self.placeable:applyDeformation(true, function(...)
			-- upvalues: (copy) self
			self:onTerrainValidationFinished(...)
		end)
	end
	if self.freeMode then
		self.displacementCosts = 0
	end
	return nil
end

function ConstructionBrushPlaceable:onTerrainValidationFinished(errorCode, displacedVolume, blockedObjectName)
	self.activeValidationCount = self.activeValidationCount - 1
	self.terrainValidationPending = false
	if errorCode == TerrainDeformation.STATE_CANCELLED then
		return
	elseif errorCode == TerrainDeformation.STATE_SUCCESS then
		self.displacementCosts = displacedVolume * ConstructionBrushPlaceable.DISPLACEMENT_COST_PER_M3
		self.displacementError = nil
		return
	else
		self.displacementCosts = 0
		if errorCode == TerrainDeformation.STATE_FAILED_BLOCKED then
			self.displacementError = ConstructionBrushPlaceable.ERROR.BLOCKED
			return
		elseif errorCode == TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT then
			self.displacementError = ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP
			return
		elseif errorCode == TerrainDeformation.STATE_FAILED_TO_DEFORM then
			self.displacementError = ConstructionBrushPlaceable.ERROR.DEFORM_FAILED
		end
	end
end

function ConstructionBrushPlaceable:loadPlaceable(data)
	if self.placeableXMLFilename == nil then
		Logging.warning("Placeable brush has no placeable set")
		return
	elseif self.storeItem == nil then
		Logging.warning("Placeable brush has undefined placeable storeitem")
	else
		self.isLoading = true
		if data == nil then
			data = PlaceableLoadingData.new()
			data:setPosition(0, -500, 0)
			data:setRotation(0, 0, 0)
		end
		data:setStoreItem(self.storeItem)
		if data ~= nil then
			data:setRotation(0, self.cursor:getRotation(), 0)
		end
		data:load(self.loadedPlaceable, self)
		data:setPropertyState(PlaceablePropertyState.CONSTRUCTION_PREVIEW)
		data:setOwnerFarmId(g_localPlayer.farmId)
		data:setIsRegistered(false)
	end
end

-- Local values: snapAngle
function ConstructionBrushPlaceable:loadedPlaceable(placeable, loadingState, args)
	self.isLoading = false
	self.loadingPlaceable = nil
	if loadingState == PlaceableLoadingState.ERROR then
		Logging.warning("Failed to load placeable")
		if placeable ~= nil then
			placeable:delete()
		end
		return
	elseif placeable == nil then
		Logging.warning("Failed to load placeable")
		return
	elseif self.isActive then
		if placeable.setColor ~= nil then
			placeable:setColor(self.colorIndex)
		end
		if self.cursor ~= nil then
			if placeable.getRotationSnapAngle ~= nil then
				local v65_ = placeable:getRotationSnapAngle()
				if v65_ ~= 0 then
					self.cursor:setSnapAngle(v65_)
				end
			end
			if placeable.getIsPlacedOnWater ~= nil and placeable:getIsPlacedOnWater() then
				self.cursor:setIsWaterDetectionActive(true)
			end
		end
		self:setInputTextDirty()
		self.placeable = placeable
	else
		placeable:delete()
	end
end

function ConstructionBrushPlaceable:unloadPlaceable()
	if self.placeable ~= nil then
		self.placeable:delete()
		self.placeable = nil
		self.isLoading = false
		self.isPlacing = false
	end
	if self.loadingPlaceable ~= nil then
		self.loadingPlaceable:delete()
	end
	if self.cursor ~= nil then
		self.cursor:setSnapAngle(nil)
	end
end

-- Local values: displacementCosts, modifyingTerrain, realignToTerrainAfterLeveing, x, y, z, rotY, err, data
function ConstructionBrushPlaceable:onButtonPrimary()
	if self.coolDownTimer > 0 then
		return
	elseif self.placeable == nil then
		return
	elseif self.isLoading or (self.isPlacing or self.displacementError ~= nil) then
		return
	else
		local v68_ = self:getDisplacementCost()
		local v69_ = not self.freeMode
		local v70_ = (self.placeable.getRequiresRealignAfterLeveling == nil or self.placeable:getRequiresRealignAfterLeveling()) and true or false
		local v71_, v72_, v73_ = self.cursor:getPosition()
		local v74_ = self.cursor:getRotation()
		self.placeable:startPlacementCheck(v71_, v72_, v73_, v74_)
		local v75_, v76_, v77_ = self:getSnappedPosition(v71_, v72_, v73_)
		local v78_ = self:getSnappedRotation(v74_)
		if v75_ ~= nil then
			if self:verifyPlacement(v75_, v76_, v77_, v78_) == nil then
				self.isPlacing = true
				local v79_ = BuyPlaceableData.new()
				v79_:setStoreItem(self.storeItem)
				v79_:setConfigurations(self.configurations or {})
				v79_:setConfigurationData(self.configurationData)
				v79_:setPosition(v75_, v76_, v77_)
				v79_:setRotation(0, v78_, 0)
				v79_:setIsFreeOfCharge(false)
				v79_:setOwnerFarmId(g_localPlayer.farmId)
				v79_:setDisplacementCosts(v68_)
				v79_:setModifyTerrain(v69_)
				v79_:setRealignToTerrainAfterLeveling(v70_)
				v79_:updatePrice()
				g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
				g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(v79_))
				if self.placeable.playPlaceSound ~= nil then
					self.placeable:playPlaceSound()
				end
				return true
			end
		end
	end
end

function ConstructionBrushPlaceable:onButtonTertiary()
	self.freeMode = not self.freeMode
	self:setInputTextDirty()
	if self.freeMode and not g_gameSettings:getValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING) then
		InfoDialog.show(g_i18n:getText("ui_constructionFreeModeWarning"))
		g_gameSettings:setValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING, true)
	end
end

function ConstructionBrushPlaceable:onButtonSnapping()
	self.snappingActive = not self.snappingActive
	ConstructionBrushPlaceable.LAST_SNAPPING_STATE = self.snappingActive
	self:setInputTextDirty()
end

-- Local values: colors
function ConstructionBrushPlaceable:onAxisPrimary(inputValue)
	if self.placeable == nil then
		return
	elseif self.placeable.getAvailableColors ~= nil then
		local v84_ = self.placeable:getAvailableColors()
		if #v84_ > 0 then
			self.colorIndex = self.colorIndex + inputValue
			if self.colorIndex > #v84_ then
				self.colorIndex = 1
			elseif self.colorIndex < 1 then
				self.colorIndex = #v84_
			end
			self.placeable:setColor(self.colorIndex)
		end
	end
end

function ConstructionBrushPlaceable:onAxisSecondary(inputValue)
	self.inputHeight = inputValue
end

-- Local values: errorText
function ConstructionBrushPlaceable:onPlaceableCreated(errorCode, price, serverObjectId)
	self.isPlacing = false
	local v89_ = nil
	if errorCode == BuyPlaceableEvent.STATE_SUCCESS then
		self.coolDownTimer = 500
	elseif errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
		v89_ = g_i18n:getText("ui_construction_couldNotLoadItem")
	elseif errorCode == BuyPlaceableEvent.STATE_NO_SPACE then
		v89_ = g_i18n:getText("ui_construction_spaceAlreadyOccupied")
	elseif errorCode == BuyPlaceableEvent.STATE_NO_PERMISSION then
		v89_ = g_i18n:getText("ui_construction_noBuildPermission")
	elseif errorCode == BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY then
		v89_ = g_i18n:getText("ui_construction_notEnoughMoney")
	elseif errorCode == BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED then
		v89_ = g_i18n:getText("ui_construction_deformationFailed")
	end
	if v89_ ~= nil then
		self.errorText = v89_
		self.errorEndTime = g_time + 3000
	end
	g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
end

function ConstructionBrushPlaceable:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE"
end

function ConstructionBrushPlaceable:getButtonTertiaryText()
	return string.format(g_i18n:getText("input_CONSTRUCTION_FREEMODE"), g_i18n:getText(self.freeMode and "ui_on" or "ui_off"))
end

function ConstructionBrushPlaceable:getAxisPrimaryText()
	return self.placeable ~= nil and (self.placeable.getHasColors ~= nil and self.placeable:getHasColors()) and "$l10n_input_CONSTRUCTION_CHANGE_COLOR" or nil
end

function ConstructionBrushPlaceable:getAxisSecondaryText()
	return "$l10n_input_CONSTRUCTION_HEIGHT"
end

function ConstructionBrushPlaceable:getButtonSnappingText()
	return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end
