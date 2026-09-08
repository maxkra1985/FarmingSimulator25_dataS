-- Local values: InGameMapExtension_mt
InGameMapExtension = {}
InGameMapExtension.MOD_NAME = g_currentModName
InGameMapExtension.MOD_DIR = g_currentModDirectory
InGameMapExtension.GUI_ELEMENTS = g_currentModDirectory .. "gui/ui_elements.png"
local InGameMapExtension_mt = Class(InGameMapExtension)

-- Upvalues: InGameMapExtension_mt
-- Local values: self, uiScale, width, height
function InGameMapExtension.new(precisionFarming, customMt)
	-- upvalues: (copy) InGameMapExtension_mt
	local v4_ = customMt or InGameMapExtension_mt
	local v5_ = setmetatable({}, v4_)
	local v6_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v7_, v8_ = getNormalizedScreenValues(120 * v6_, 6 * v6_)
	v5_.gradientBackgroundElement = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, v7_, v8_)
	v5_.gradientBackgroundElement:setColor(0, 0, 0, 0.6)
	v5_.gradientElement = g_overlayManager:createOverlay("precisionFarming.gradient_red_green", 0, 0, v7_, v8_)
	v5_.labelPositionsByState = {}
	v5_.labelPositionsByState[IngameMapState.MINIMAP_ROUND] = {
		["labelOffset"] = { getNormalizedScreenValues(0, 15 * v6_) },
		["labelTextSize"] = { getNormalizedScreenValues(0, 15 * v6_) },
		["gradientOffset"] = { getNormalizedScreenValues(0, 40 * v6_) },
		["labelXAlignment"] = RenderText.ALIGN_CENTER,
		["gradientXAlignment"] = RenderText.ALIGN_CENTER
	}
	v5_.labelPositionsByState[IngameMapState.MINIMAP_SQUARE] = {
		["labelOffset"] = { getNormalizedScreenValues(18 * v6_, 15 * v6_) },
		["labelTextSize"] = { getNormalizedScreenValues(0, 15 * v6_) },
		["gradientOffset"] = { getNormalizedScreenValues(0, 30 * v6_) },
		["labelXAlignment"] = RenderText.ALIGN_LEFT,
		["gradientXAlignment"] = RenderText.ALIGN_CENTER
	}
	v5_.labelPositionsByState[IngameMapState.MAP] = {
		["labelOffset"] = { getNormalizedScreenValues(18 * v6_, 15 * v6_) },
		["labelTextSize"] = { getNormalizedScreenValues(0, 15 * v6_) },
		["gradientOffset"] = { getNormalizedScreenValues(20 * v6_, 20 * v6_) },
		["labelXAlignment"] = RenderText.ALIGN_LEFT,
		["gradientXAlignment"] = RenderText.ALIGN_LEFT
	}
	v5_.minimapSoilStateOverlay = createDensityMapVisualizationOverlay("soilStateOverlay", 1024, 1024)
	v5_.minimapSoilStateOverlayIsReady = nil
	v5_.minimapSoilStateOverlayIsReadyForDisplay = nil
	precisionFarming:registerVisualizationOverlay(v5_.minimapSoilStateOverlay)
	v5_.smoothedMapZoomLevel = 1
	v5_.smoothedMapZoomTargetLevel = 1
	v5_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	v5_.precisionFarming = precisionFarming
	v5_.inGameMap = nil
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], v5_.onColorBlindModeChanged, v5_)
	return v5_
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

-- Local values: valueMaps, requiredValueMap, requiredValueMapSelected, i, valueMap, requireDisplay, isSelected, requiredFilter, requiresUpdate, updateTimeLimit, dir, limit
function InGameMapExtension:update(dt)
	local v12_ = self.precisionFarming:getValueMaps()
	local v13_ = nil
	local v14_ = nil
	for v15_ = 1, #v12_ do
		local v16_ = v12_[v15_]
		local v17_, v18_ = v16_:getRequireMinimapDisplay()
		if v17_ then
			if v13_ == nil then
				v14_ = v18_
				v13_ = v16_
			elseif not v14_ and v18_ then
				v14_ = v18_
				v13_ = v16_
			end
		end
	end
	if v13_ == nil or self.inGameMap ~= nil and (not self.inGameMap.isVisible or self.inGameMap.state == IngameMapState.OFF) then
		self.minimapSoilStateOverlayIsReady = nil
		self.minimapSoilStateOverlayIsReadyForDisplay = false
		self.lastValueMap = nil
		self.lastValueMapFilter = nil
		self.smoothedMapZoomTargetLevel = 1
	else
		if self.minimapSoilStateOverlayIsReady == nil or self.minimapSoilStateOverlayIsReady == true then
			local v19_ = v13_:getMinimapValueFilter()
			local v20_ = v13_:getMinimapRequiresUpdate() or g_server == nil
			if self.lastValueMap ~= v13_ then
				self.minimapSoilStateOverlayIsReadyForDisplay = false
			end
			if self.lastValueMap ~= v13_ or (self.lastValueMapFilter ~= v19_ or v20_) then
				v13_:getMinimapUpdateTimeLimit()
				local _ = g_server == nil
				v13_:buildOverlay(self.minimapSoilStateOverlay, v19_, self.isColorBlindMode, true)
				generateDensityMapVisualizationOverlay(self.minimapSoilStateOverlay)
				self.minimapSoilStateOverlayIsReady = false
				v13_:setMinimapRequiresUpdate(false)
				self.lastValueMap = v13_
				self.lastValueMapFilter = v19_
			end
		end
		if self.minimapSoilStateOverlayIsReady == false and getIsDensityMapVisualizationOverlayReady(self.minimapSoilStateOverlay) then
			self.minimapSoilStateOverlayIsReady = true
			self.minimapSoilStateOverlayIsReadyForDisplay = true
		end
		self.smoothedMapZoomTargetLevel = v13_:getMinimapZoomFactor()
	end
	if self.smoothedMapZoomLevel ~= self.smoothedMapZoomTargetLevel then
		local v21_ = self.smoothedMapZoomTargetLevel - self.smoothedMapZoomLevel
		local v22_ = math.sign(v21_)
		self.smoothedMapZoomLevel = (v22_ == 1 and math.min or math.max)(self.smoothedMapZoomLevel + dt * 0.001 * v22_ * 2, self.smoothedMapZoomTargetLevel)
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
	pfModule:overwriteGameFunction(IngameMap, "loadMap", function(p28_, p29_, ...)
		-- upvalues: (copy) self
		self.inGameMap = p29_
		p28_(p29_, ...)
	end)
	pfModule:overwriteGameFunction(IngameMap, "drawFields", function(p30_, p31_)
		-- upvalues: (copy) self
		p30_(p31_)
		if p31_.layout.supportPrecisionFarmingSoilStateOverlay then
			if not p31_.isFullscreen then
				if self.minimapSoilStateOverlayIsReadyForDisplay then
					local v32_, v33_ = p31_.layout:getMapSize()
					local v34_, v35_ = p31_.layout:getMapPosition()
					local v36_, v37_ = p31_.layout:getMapPivot()
					local v38_ = v36_ + v34_
					local v39_ = v37_ + v35_
					local v40_ = v34_ + v32_ * 0.25
					local v41_ = v35_ + v33_ * 0.25
					local v42_ = v38_ - v40_
					local v43_ = v39_ - v41_
					setOverlayRotation(self.minimapSoilStateOverlay, p31_.layout:getMapRotation(), v42_, v43_)
					local v44_ = setOverlayColor
					local v45_ = self.minimapSoilStateOverlay
					local v46_ = p31_.layout:getMapAlpha()
					v44_(v45_, 1, 1, 1, (math.sqrt(v46_)))
					renderOverlay(self.minimapSoilStateOverlay, v40_, v41_, v32_ * 0.5, v33_ * 0.5)
				end
				if self.lastValueMap ~= nil then
					local v47_ = self.lastValueMap:getMinimapAdditionalElement()
					if v47_ ~= nil then
						local v48_, v49_ = self.lastValueMap:getMinimapAdditionalElementRealSize()
						if v48_ > 0 and v49_ > 0 then
							local v50_, v51_ = p31_.layout:getMapSize()
							v47_.width = v48_ / p31_.worldSizeX * v50_ * 0.5
							v47_.height = v49_ / p31_.worldSizeZ * v51_ * 0.5
						end
						local v52_ = p31_.layout.background
						if v52_ ~= nil then
							local v53_ = self.lastValueMap:getMinimapAdditionalElementLinkNode()
							if v53_ == nil then
								v47_.x = v52_.x + v52_.width * 0.5 - v47_.width * 0.5
								v47_.y = v52_.y + v52_.height * 0.5 - v47_.height * 0.5
							else
								local v54_, _, v55_ = getWorldTranslation(v53_)
								local v56_ = (v54_ * 0.5 + p31_.worldCenterOffsetX) / p31_.worldSizeX
								local v57_ = (v55_ * 0.5 + p31_.worldCenterOffsetZ) / p31_.worldSizeZ
								local v58_, v59_, _, _ = p31_.layout:getMapObjectPosition(v56_, v57_, v47_.width, v47_.height, 0, true)
								v47_.x = v58_
								v47_.y = v59_
							end
						end
						v47_:render()
					end
				end
			end
		end
	end)
	pfModule:overwriteGameFunction(IngameMap, "draw", function(p60_, p61_)
		-- upvalues: (copy) self
		p60_(p61_)
		if p61_.isVisible then
			if p61_.layout.supportPrecisionFarmingSoilStateOverlay then
				local v62_, v63_ = p61_.layout:getMapSize()
				if v62_ == 0 or v63_ == 0 then
					return
				elseif self.labelPositionsByState[p61_.state] ~= nil then
					if self.lastValueMap ~= nil then
						local v64_ = p61_.layout.background
						if v64_ ~= nil then
							local v65_ = self.lastValueMap:getMinimapLabel()
							if v65_ ~= nil then
								setTextAlignment(RenderText.ALIGN_LEFT)
								local v66_ = self.labelPositionsByState[p61_.state]
								local v67_ = v66_.labelOffset[1]
								local v68_ = v66_.labelOffset[2]
								local v69_ = v66_.labelTextSize[2]
								local v70_ = v66_.labelXAlignment
								local v71_ = v64_.x + v67_
								local v72_ = v64_.y + v64_.height - v68_ - v69_
								if v70_ == RenderText.ALIGN_CENTER then
									v71_ = v64_.x + v64_.width * 0.5
									setTextAlignment(RenderText.ALIGN_CENTER)
								end
								setTextColor(0, 0, 0, 1)
								renderText(v71_, v72_ - 0.0015, v69_, v65_)
								setTextColor(1, 1, 1, 1)
								renderText(v71_, v72_, v69_, v65_)
								setTextAlignment(RenderText.ALIGN_LEFT)
							end
							local v73_ = self.lastValueMap:getMinimapGradientSliceId(self.isColorBlindMode)
							local v74_ = self.lastValueMap:getMinimapGradientLabel()
							if v73_ ~= nil and v74_ ~= nil then
								local v75_ = self.labelPositionsByState[p61_.state]
								local v76_ = self.gradientBackgroundElement
								local v77_ = self.gradientElement
								v76_:setPosition(v64_.x + v75_.gradientOffset[1], v64_.y + v75_.gradientOffset[2])
								if v75_.gradientXAlignment == RenderText.ALIGN_CENTER then
									v76_:setPosition(v64_.x + v64_.width * 0.5 - v76_.width * 0.5, nil)
								end
								v76_:render()
								v77_:setPosition(v76_.x + (v76_.width - v77_.width) * 0.5, v76_.y + (v76_.height - v77_.height) * 0.5)
								v77_:setSliceId(v73_)
								v77_:render()
								setTextAlignment(RenderText.ALIGN_CENTER)
								local v78_ = v76_.x + v76_.width * 0.5
								local v79_ = v76_.y + v76_.height + v75_.labelTextSize[2] * 0.3
								setTextColor(0, 0, 0, 1)
								renderText(v78_, v79_ - 0.0015, v75_.labelTextSize[2] * 0.85, v74_)
								setTextColor(1, 1, 1, 1)
								renderText(v78_, v79_, v75_.labelTextSize[2] * 0.85, v74_)
							end
						end
					end
				end
			else
				return
			end
		else
			return
		end
	end)
	pfModule:overwriteGameFunction(IngameMapLayoutCircle, "updateScreenValues", function(p80_, p81_, ...)
		-- upvalues: (copy) self
		local v82_ = p81_.worldSizeFactor
		p81_.worldSizeFactor = v82_ * self.smoothedMapZoomLevel
		p80_(p81_, ...)
		p81_.worldSizeFactor = v82_
	end)
	pfModule:overwriteGameFunction(IngameMapLayoutSquare, "updateScreenValues", function(p83_, p84_, ...)
		-- upvalues: (copy) self
		local v85_ = p84_.worldSizeFactor
		p84_.worldSizeFactor = v85_ * self.smoothedMapZoomLevel
		p83_(p84_, ...)
		p84_.worldSizeFactor = v85_
	end)
	pfModule:overwriteGameFunction(IngameMapLayout, "new", function(p86_, ...)
		local v87_ = p86_(...)
		v87_.supportPrecisionFarmingSoilStateOverlay = true
		return v87_
	end)
	pfModule:overwriteGameFunction(IngameMapLayoutPartialscreen, "new", function(p88_, ...)
		local v89_ = p88_(...)
		v89_.supportPrecisionFarmingSoilStateOverlay = false
		return v89_
	end)
end
