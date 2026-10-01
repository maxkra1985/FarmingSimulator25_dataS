InGameMapExtension = {}
InGameMapExtension.MOD_NAME = g_currentModName
InGameMapExtension.MOD_DIR = g_currentModDirectory
InGameMapExtension.GUI_ELEMENTS = g_currentModDirectory .. "gui/ui_elements.png"
local InGameMapExtension_mt = Class(InGameMapExtension)
function InGameMapExtension.new(precisionFarming, customMt)
	local self = setmetatable({}, customMt or InGameMapExtension_mt)
	local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local width, height = getNormalizedScreenValues(120 * uiScale, 6 * uiScale)
	self.gradientBackgroundElement = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, width, height)
	self.gradientBackgroundElement:setColor(0, 0, 0, 0.6)
	self.gradientElement = g_overlayManager:createOverlay("precisionFarming.gradient_red_green", 0, 0, width, height)
	self.labelPositionsByState = {}
	self.labelPositionsByState[IngameMapState.MINIMAP_ROUND] = { labelOffset = { getNormalizedScreenValues(0, 15 * uiScale) }, labelTextSize = { getNormalizedScreenValues(0, 15 * uiScale) }, gradientOffset = { getNormalizedScreenValues(0, 40 * uiScale) }, labelXAlignment = RenderText.ALIGN_CENTER, gradientXAlignment = RenderText.ALIGN_CENTER }
	self.labelPositionsByState[IngameMapState.MINIMAP_SQUARE] = { labelOffset = { getNormalizedScreenValues(18 * uiScale, 15 * uiScale) }, labelTextSize = { getNormalizedScreenValues(0, 15 * uiScale) }, gradientOffset = { getNormalizedScreenValues(0, 30 * uiScale) }, labelXAlignment = RenderText.ALIGN_LEFT, gradientXAlignment = RenderText.ALIGN_CENTER }
	self.labelPositionsByState[IngameMapState.MAP] = { labelOffset = { getNormalizedScreenValues(18 * uiScale, 15 * uiScale) }, labelTextSize = { getNormalizedScreenValues(0, 15 * uiScale) }, gradientOffset = { getNormalizedScreenValues(20 * uiScale, 20 * uiScale) }, labelXAlignment = RenderText.ALIGN_LEFT, gradientXAlignment = RenderText.ALIGN_LEFT }
	self.minimapSoilStateOverlay = createDensityMapVisualizationOverlay("soilStateOverlay", 1024, 1024)
	self.minimapSoilStateOverlayIsReady = nil
	self.minimapSoilStateOverlayIsReadyForDisplay = nil
	precisionFarming:registerVisualizationOverlay(self.minimapSoilStateOverlay)
	self.smoothedMapZoomLevel = 1
	self.smoothedMapZoomTargetLevel = 1
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self.precisionFarming = precisionFarming
	self.inGameMap = nil
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.onColorBlindModeChanged, self)
	return self
end
function InGameMapExtension:unloadMapData() end
function InGameMapExtension:delete()
	if self.minimapSoilStateOverlay ~= nil then
		delete(self.minimapSoilStateOverlay)
	end
	self.gradientElement:delete()
	self.gradientBackgroundElement:delete()
	g_messageCenter:unsubscribeAll(self)
end
function InGameMapExtension:update(dt)
	local valueMaps = self.precisionFarming:getValueMaps()
	local requiredValueMap = nil
	local requiredValueMapSelected = nil
	for i = 1, #valueMaps do
		local valueMap = valueMaps[i]
		local requireDisplay, isSelected = valueMap:getRequireMinimapDisplay()
		if requireDisplay then
			if requiredValueMap == nil then
				requiredValueMap = valueMap
				requiredValueMapSelected = isSelected
			else
				if requiredValueMapSelected then
					continue
				end
				if isSelected then
					requiredValueMapSelected = isSelected
					requiredValueMap = valueMap
				end
			end
		end
	end
	if requiredValueMap ~= nil then
		if self.inGameMap == nil or self.inGameMap.isVisible and self.inGameMap.state ~= IngameMapState.OFF then
			if self.minimapSoilStateOverlayIsReady == nil or self.minimapSoilStateOverlayIsReady == true then
				local requiredFilter = requiredValueMap:getMinimapValueFilter()
				requiredValueMap:getMinimapRequiresUpdate()
				local requiresUpdate = false
				if self.lastValueMap ~= requiredValueMap then
					self.minimapSoilStateOverlayIsReadyForDisplay = false
				end
				if self.lastValueMap ~= requiredValueMap or self.lastValueMapFilter ~= requiredFilter or requiresUpdate then
					local updateTimeLimit = requiredValueMap:getMinimapUpdateTimeLimit()
					if g_server == nil then
						updateTimeLimit = 0.15
					end
					requiredValueMap:buildOverlay(self.minimapSoilStateOverlay, requiredFilter, self.isColorBlindMode, true)
					generateDensityMapVisualizationOverlay(self.minimapSoilStateOverlay)
					self.minimapSoilStateOverlayIsReady = false
					requiredValueMap:setMinimapRequiresUpdate(false)
					self.lastValueMap = requiredValueMap
					self.lastValueMapFilter = requiredFilter
				end
			end
			if self.minimapSoilStateOverlayIsReady == false and getIsDensityMapVisualizationOverlayReady(self.minimapSoilStateOverlay) then
				self.minimapSoilStateOverlayIsReady = true
				self.minimapSoilStateOverlayIsReadyForDisplay = true
			end
			self.smoothedMapZoomTargetLevel = requiredValueMap:getMinimapZoomFactor()
		else
			self.minimapSoilStateOverlayIsReady = nil
			self.minimapSoilStateOverlayIsReadyForDisplay = false
			self.lastValueMap = nil
			self.lastValueMapFilter = nil
			self.smoothedMapZoomTargetLevel = 1
		end
	end
	if self.smoothedMapZoomLevel ~= self.smoothedMapZoomTargetLevel then
		local dir = math.sign(self.smoothedMapZoomTargetLevel - self.smoothedMapZoomLevel)
		local limit = dir == 1 and math.min or math.max
		self.smoothedMapZoomLevel = limit(self.smoothedMapZoomLevel + dt * 0.001 * dir * 2, self.smoothedMapZoomTargetLevel)
	end
end
function InGameMapExtension:updatePrecisionFarmingOverlays()
	if self.lastValueMap ~= nil then
		self.lastValueMap:setMinimapRequiresUpdate(true)
	end
end
function InGameMapExtension:onColorBlindModeChanged(isColorBlindMode)
	self.isColorBlindMode = isColorBlindMode
	self.minimapSoilStateOverlayIsReady = nil
	self.lastValueMap = nil
	self.lastValueMapFilter = nil
end
function InGameMapExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(IngameMap, "loadMap", function(superFunc, inGameMap, ...)
		self.inGameMap = inGameMap
		superFunc(inGameMap, ...)
	end)
	pfModule:overwriteGameFunction(IngameMap, "drawFields", function(superFunc, ingameMap)
		superFunc(ingameMap)
		if not ingameMap.layout.supportPrecisionFarmingSoilStateOverlay then
			return
		else
			if not ingameMap.isFullscreen then
				if self.minimapSoilStateOverlayIsReadyForDisplay then
					local width, height = ingameMap.layout:getMapSize()
					local x, y = ingameMap.layout:getMapPosition()
					local px, py = ingameMap.layout:getMapPivot()
					px = px + x
					py = py + y
					x = x + width * 0.25
					y = y + height * 0.25
					px = px - x
					py = py - y
					setOverlayRotation(self.minimapSoilStateOverlay, ingameMap.layout:getMapRotation(), px, py)
					setOverlayColor(self.minimapSoilStateOverlay, 1, 1, 1, math.sqrt(ingameMap.layout:getMapAlpha()))
					renderOverlay(self.minimapSoilStateOverlay, x, y, width * 0.5, height * 0.5)
				end
				if self.lastValueMap ~= nil then
					local additionElement = self.lastValueMap:getMinimapAdditionalElement()
					if additionElement ~= nil then
						local x, y = self.lastValueMap:getMinimapAdditionalElementRealSize()
						if 0 < x and 0 < y then
							local width, height = ingameMap.layout:getMapSize()
							additionElement.width = x / ingameMap.worldSizeX * width * 0.5
							additionElement.height = y / ingameMap.worldSizeZ * height * 0.5
						end
						local background = ingameMap.layout.background
						if background ~= nil then
							local additionalElementLinkNode = self.lastValueMap:getMinimapAdditionalElementLinkNode()
							if additionalElementLinkNode ~= nil then
								local linkX, _, linkZ = getWorldTranslation(additionalElementLinkNode)
								local objectX = (linkX * 0.5 + ingameMap.worldCenterOffsetX) / ingameMap.worldSizeX
								local objectZ = (linkZ * 0.5 + ingameMap.worldCenterOffsetZ) / ingameMap.worldSizeZ
								local posX, posY, _, _ = ingameMap.layout:getMapObjectPosition(objectX, objectZ, additionElement.width, additionElement.height, 0, true)
								additionElement.x = posX
								additionElement.y = posY
							else
								additionElement.x = background.x + background.width * 0.5 - additionElement.width * 0.5
								additionElement.y = background.y + background.height * 0.5 - additionElement.height * 0.5
							end
						end
						additionElement:render()
					end
				end
			end
		end
	end)
	pfModule:overwriteGameFunction(IngameMap, "draw", function(superFunc, ingameMap)
		superFunc(ingameMap)
		if not ingameMap.isVisible then
			return
		end
		if not ingameMap.layout.supportPrecisionFarmingSoilStateOverlay then
			return
		end
		local width, height = ingameMap.layout:getMapSize()
		if width == 0 or height == 0 then
			return
		end
		if self.labelPositionsByState[ingameMap.state] == nil then
			return
		else
			if self.lastValueMap ~= nil then
				local background = ingameMap.layout.background
				if background ~= nil then
					local label = self.lastValueMap:getMinimapLabel()
					if label ~= nil then
						setTextAlignment(RenderText.ALIGN_LEFT)
						local positions = self.labelPositionsByState[ingameMap.state]
						local offsetX = positions.labelOffset[1]
						local offsetY = positions.labelOffset[2]
						local textSize = positions.labelTextSize[2]
						local align = positions.labelXAlignment
						local tx = background.x + offsetX
						local ty = background.y + background.height - offsetY - textSize
						if align == RenderText.ALIGN_CENTER then
							tx = background.x + background.width * 0.5
							setTextAlignment(RenderText.ALIGN_CENTER)
						end
						setTextColor(0, 0, 0, 1)
						renderText(tx, ty - 0.0015, textSize, label)
						setTextColor(1, 1, 1, 1)
						renderText(tx, ty, textSize, label)
						setTextAlignment(RenderText.ALIGN_LEFT)
					end
					local gradientSliceId = self.lastValueMap:getMinimapGradientSliceId(self.isColorBlindMode)
					local gradientLabel = self.lastValueMap:getMinimapGradientLabel()
					if gradientSliceId ~= nil and gradientLabel ~= nil then
						local positions = self.labelPositionsByState[ingameMap.state]
						local gradientBackgroundElement = self.gradientBackgroundElement
						local gradientElement = self.gradientElement
						gradientBackgroundElement:setPosition(background.x + positions.gradientOffset[1], background.y + positions.gradientOffset[2])
						if positions.gradientXAlignment == RenderText.ALIGN_CENTER then
							gradientBackgroundElement:setPosition(background.x + background.width * 0.5 - gradientBackgroundElement.width * 0.5, nil)
						end
						gradientBackgroundElement:render()
						local x = gradientBackgroundElement.x + (gradientBackgroundElement.width - gradientElement.width) * 0.5
						local y = gradientBackgroundElement.y + (gradientBackgroundElement.height - gradientElement.height) * 0.5
						gradientElement:setPosition(x, y)
						gradientElement:setSliceId(gradientSliceId)
						gradientElement:render()
						setTextAlignment(RenderText.ALIGN_CENTER)
						local tx = gradientBackgroundElement.x + gradientBackgroundElement.width * 0.5
						local ty = gradientBackgroundElement.y + gradientBackgroundElement.height + positions.labelTextSize[2] * 0.3
						setTextColor(0, 0, 0, 1)
						renderText(tx, ty - 0.0015, positions.labelTextSize[2] * 0.85, gradientLabel)
						setTextColor(1, 1, 1, 1)
						renderText(tx, ty, positions.labelTextSize[2] * 0.85, gradientLabel)
					end
				end
			end
		end
	end)
	pfModule:overwriteGameFunction(IngameMapLayoutCircle, "updateScreenValues", function(superFunc, layout, ...)
		local oldWorldSizeFactor = layout.worldSizeFactor
		layout.worldSizeFactor = oldWorldSizeFactor * self.smoothedMapZoomLevel
		superFunc(layout, ...)
		layout.worldSizeFactor = oldWorldSizeFactor
	end)
	pfModule:overwriteGameFunction(IngameMapLayoutSquare, "updateScreenValues", function(superFunc, layout, ...)
		local oldWorldSizeFactor = layout.worldSizeFactor
		layout.worldSizeFactor = oldWorldSizeFactor * self.smoothedMapZoomLevel
		superFunc(layout, ...)
		layout.worldSizeFactor = oldWorldSizeFactor
	end)
	pfModule:overwriteGameFunction(IngameMapLayout, "new", function(superFunc, ...)
		local _self = superFunc(...)
		_self.supportPrecisionFarmingSoilStateOverlay = true
		return _self
	end)
	pfModule:overwriteGameFunction(IngameMapLayoutPartialscreen, "new", function(superFunc, ...)
		local _self = superFunc(...)
		_self.supportPrecisionFarmingSoilStateOverlay = false
		return _self
	end)
end
