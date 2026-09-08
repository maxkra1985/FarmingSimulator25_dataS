-- Local values: data, old, GameInfoDisplayMobile_mt, gameInfoDisplay, k, elem
local v1_
if GameInfoDisplayMobile == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.gameInfoDisplay
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["hud"] = v2_.hud,
		["uiScale"] = v2_.uiScale,
		["hudAtlasPath"] = v2_.hudAtlasPath,
		["controlHudAtlasPath"] = v2_.controlHudAtlasPath,
		["moneyUnit"] = v2_.moneyUnit,
		["missionInfo"] = v2_.missionInfo,
		["environment"] = v2_.environment
	}
	v2_:delete()
end
GameInfoDisplayMobile = {}
local data = Class(GameInfoDisplayMobile, HUDDisplayElement)
GameInfoDisplayMobile.HIDE_TIME = 500

-- Upvalues: GameInfoDisplayMobile_mt
-- Local values: backgroundOverlay, self
function GameInfoDisplayMobile.new(hud, hudAtlasPath, moneyUnit, controlHudAtlasPath)
	-- upvalues: (copy) data
	local v8_ = GameInfoDisplayMobile.createBackground()
	local v9_ = GameInfoDisplayMobile:superClass().new(v8_, nil, data)
	v9_.hud = hud
	v9_.uiScale = 1
	v9_.hudAtlasPath = hudAtlasPath
	v9_.controlHudAtlasPath = controlHudAtlasPath
	v9_.moneyUnit = moneyUnit
	v9_.vehicle = nil
	v9_.isRideable = false
	v9_.buttons = {}
	v9_.textElements = {}
	v9_:createMenuButton()
	v9_:createShopButton()
	v9_:createMapButton()
	v9_:createHelpButton()
	v9_:createWeatherElement()
	v9_:createMoneyElement()
	v9_:createFuelFitnessElement()
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, v9_.updateInsets, v9_)
	return v9_
end

function GameInfoDisplayMobile:setVehicle(vehicle)
	self.vehicle = vehicle
	if vehicle == nil then
		self.isRideable = false
	else
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
	end
	self.fuelFitnessElement:setVisible(vehicle ~= nil)
end

-- Local values: buttonOffsetX, buttonOffsetY, iconSizeX, iconSizeY, button, buttonWidth, basePosX, basePosY, baseWidth, baseHeight, anchorRight, anchorTop, posX, buttonPosX, posY
function GameInfoDisplayMobile:createButton(callbackFunc, iconSize, iconUVs, inputAction, refButton)
	local v18_ = getNormalizedScreenValues
	local v19_ = GameInfoDisplayMobile.POSITION.BUTTON_OFFSET
	local v20_, v21_ = v18_(unpack(v19_))
	local v22_, v23_ = getNormalizedScreenValues(unpack(iconSize))
	local v24_ = HUDButtonElement.new(self.hud, 0, 0)
	local v25_ = v24_:getWidth()
	local v26_, v27_ = self:getPosition()
	local v28_ = self:getWidth()
	local v29_ = self:getHeight()
	local v30_ = v26_ + v28_
	local v31_ = v27_ + v29_
	local v32_
	if refButton == nil then
		v32_ = v30_
	else
		v32_ = refButton:getPosition() + v20_
	end
	local v33_ = v32_ - v25_
	local v34_ = v31_ + v21_ - v24_:getHeight()
	v24_:setPosition(v33_, v34_)
	v24_:setIcon(self.controlHudAtlasPath, v22_, v23_, GuiUtils.getUVs(iconUVs))
	v24_:setAction(inputAction)
	v24_:addTouchHandler(callbackFunc, self)
	v24_.offsetX = v33_ - v30_
	v24_.offsetY = v34_ - v31_
	local v35_ = self.buttons
	table.insert(v35_, v24_)
	self:addChild(v24_)
	return v24_
end

-- Local values: posX
function GameInfoDisplayMobile:updateButtonPosition(button, refPosX, refPosY)
	button:setPosition(refPosX + button.offsetX * self.uiScale, nil)
end

-- Local values: iconSize, iconUVs
function GameInfoDisplayMobile:createMenuButton()
	local v40_ = GameInfoDisplayMobile.SIZE.ICON
	local v41_ = GameInfoDisplayMobile.UV.MENU
	self.menuButton = self:createButton(self.onOpenMenu, v40_, v41_, InputAction.MENU)
end

-- Local values: iconSize, iconUVs
function GameInfoDisplayMobile:createShopButton()
	local v43_ = GameInfoDisplayMobile.SIZE.ICON
	local v44_ = GameInfoDisplayMobile.UV.SHOP
	self.shopButton = self:createButton(self.onOpenShop, v43_, v44_, InputAction.TOGGLE_STORE, self.menuButton)
end

-- Local values: iconSize, iconUVs
function GameInfoDisplayMobile:createMapButton()
	local v46_ = GameInfoDisplayMobile.SIZE.ICON
	local v47_ = GameInfoDisplayMobile.UV.MAP
	self.mapButton = self:createButton(self.onOpenMap, v46_, v47_, InputAction.TOGGLE_MAP, self.shopButton)
end

-- Local values: width, height, highlight, iconSize, iconUVs, basePosX, basePosY, anchorTop, anchorRight, offsetX, offsetY, posX, posY
function GameInfoDisplayMobile:createHelpButton()
	local v49_ = getNormalizedScreenValues
	local v50_ = GameInfoDisplayMobile.SIZE.BUTTON_HIGHLIGHT
	local v51_, v52_ = v49_(unpack(v50_))
	local v53_ = Overlay.new(self.hudAtlasPath, 0, 0, v51_, v52_)
	v53_:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BUTTON_HIGHLIGHT))
	self.helpHighlightElement = HUDElement.new(v53_)
	self:addChild(self.helpHighlightElement)
	self.helpHighlightElement:setVisible(false)
	local v54_ = GameInfoDisplayMobile.SIZE.ICON
	local v55_ = GameInfoDisplayMobile.UV.HELP
	self.helpButton = self:createButton(self.onOpenHelp, v54_, v55_, InputAction.TOGGLE_HELP, self.mapButton)
	local v56_, v57_ = self:getPosition()
	local v58_ = v57_ + self:getHeight()
	local v59_ = v56_ + self:getWidth()
	local v60_ = getNormalizedScreenValues
	local v61_ = GameInfoDisplayMobile.POSITION.BUTTON_HIGHLIGHT
	local v62_, v63_ = v60_(unpack(v61_))
	local v64_, v65_ = self.helpButton:getPosition()
	local v66_ = v64_ + v62_
	local v67_ = v65_ + v63_
	self.helpHighlightElement:setPosition(v66_, v67_)
	self.helpHighlightElement.offsetX = v66_ - v59_
	self.helpHighlightElement.offsetY = v67_ - v58_
end

-- Local values: sizeXLeft, sizeY, sizeXRight, _, posXLeft, overlayLeft, baseElement, posXMiddle, sizeXMiddle, overlayMiddle, posXRight, overlayRight
function GameInfoDisplayMobile:createBackgroundElements(posX, posY, sizeX)
	local v72_ = getNormalizedScreenValues
	local v73_ = GameInfoDisplayMobile.SIZE.BG_LEFT
	local v74_, v75_ = v72_(unpack(v73_))
	local v76_ = getNormalizedScreenValues
	local v77_ = GameInfoDisplayMobile.SIZE.BG_RIGHT
	local v78_, _ = v76_(unpack(v77_))
	local v79_ = Overlay.new(self.hudAtlasPath, posX, posY, v74_, v75_)
	v79_:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_LEFT))
	local v80_ = HUDElement.new(v79_)
	self:addChild(v80_)
	local v81_ = posX + v74_
	local v82_ = sizeX - v74_ - v78_
	local v83_ = Overlay.new(self.hudAtlasPath, v81_, posY, v82_, v75_)
	v83_:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_MIDDLE))
	v80_:addChild(HUDElement.new(v83_))
	local v84_ = v81_ + v82_
	local v85_ = Overlay.new(self.hudAtlasPath, v84_, posY, v78_, v75_)
	v85_:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_RIGHT))
	v80_:addChild(HUDElement.new(v85_))
	v80_.totalSize = sizeX
	return v80_
end

-- Local values: sizeX, sizeY, basePosX, posX, posY, separatorSizeX, separatorSizeY, separatorOffsetX, separatorOffsetY, separatorOverlay, seasonOverlayUVs, i, uvs, seasonIconSizeX, seasonIconSizeY, seasonOffsetX, seasonOffsetY, seasonOverlay, seasonElement, _, textSize, monthOffsetX, monthOffsetY, colorWhite, monthDrawFunc, timeIconSizeX, timeIconSizeY, timeOffsetX, timeOffsetY, timeOverlay, timeElement, _, timeTextSize, timeTextOffsetX, timeTextOffsetY, timeTextSpacingOffsetX, _, timeDrawFunc
function GameInfoDisplayMobile:createWeatherElement()
	local v87_ = getNormalizedScreenValues
	local v88_ = GameInfoDisplayMobile.POSITION.WEATHER
	local v89_, v90_ = v87_(unpack(v88_))
	self.weatherOffsetX = v89_
	self.weatherOffsetY = v90_
	local v91_ = getNormalizedScreenValues
	local v92_ = GameInfoDisplayMobile.SIZE.WEATHER
	local v93_, v94_ = v91_(unpack(v92_))
	local v95_ = self:getPosition()
	local v96_ = self.weatherOffsetX
	local v97_ = math.max(v95_, v96_)
	local v98_ = 1 + self.weatherOffsetY - v94_
	self.weatherElement = self:createBackgroundElements(v97_, v98_, v93_)
	local v99_ = getNormalizedScreenValues
	local v100_ = GameInfoDisplayMobile.SIZE.WEATHER_SEPARATOR
	local v101_, v102_ = v99_(unpack(v100_))
	local v103_ = getNormalizedScreenValues
	local v104_ = GameInfoDisplayMobile.POSITION.WEATHER_SEPARATOR
	local v105_, v106_ = v103_(unpack(v104_))
	local v107_ = Overlay.new(self.hudAtlasPath, v97_ + v105_, v98_ + v106_, v101_, v102_)
	v107_:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	self.weatherElement:addChild(HUDElement.new(v107_))
	local v_u_108_ = {}
	for v109_, v110_ in pairs(GameInfoDisplayMobile.UV.SEASON_ICON) do
		v_u_108_[v109_] = GuiUtils.getUVs(v110_)
	end
	local v111_ = getNormalizedScreenValues
	local v112_ = GameInfoDisplayMobile.SIZE.SEASON_ICON
	local v113_, v114_ = v111_(unpack(v112_))
	local v115_ = getNormalizedScreenValues
	local v116_ = GameInfoDisplayMobile.POSITION.SEASON_ICON
	local v117_, v118_ = v115_(unpack(v116_))
	local v119_ = Overlay.new(self.controlHudAtlasPath, v97_ + v117_, v98_ + v118_, v113_, v114_)
	v119_:setUVs(v_u_108_[1])
	local v_u_120_ = HUDElement.new(v119_)
	self.weatherElement:addChild(v_u_120_)
	local _, v_u_121_ = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.MONTH_TEXT)
	local v122_ = getNormalizedScreenValues
	local v123_ = GameInfoDisplayMobile.POSITION.MONTH_TEXT
	local v_u_124_, v_u_125_ = v122_(unpack(v123_))
	local v_u_126_ = {
		1,
		1,
		1,
		1
	}
	local v127_ = self.textElements
	table.insert(v127_, function()
		-- upvalues: (copy) v_u_120_, (copy) v_u_108_, (copy) self, (copy) v_u_124_, (copy) v_u_125_, (copy) v_u_121_, (copy) v_u_126_
		v_u_120_:setUVs(v_u_108_[self.environment.currentSeason])
		local v128_ = g_i18n:formatDayInPeriod(nil, nil, true)
		local v129_, v130_ = self.weatherElement:getPosition()
		local v131_ = v129_ + v_u_124_ * self.uiScale
		local v132_ = v130_ + v_u_125_ * self.uiScale
		GameInfoDisplayMobile.drawText(v131_, v132_, v_u_121_ * self.uiScale, true, RenderText.ALIGN_LEFT, v_u_126_, v128_)
	end)
	local v133_ = getNormalizedScreenValues
	local v134_ = GameInfoDisplayMobile.SIZE.TIME_ICON
	local v135_, v136_ = v133_(unpack(v134_))
	local v137_ = getNormalizedScreenValues
	local v138_ = GameInfoDisplayMobile.POSITION.TIME_ICON
	local v139_, v140_ = v137_(unpack(v138_))
	local v141_ = Overlay.new(self.controlHudAtlasPath, v97_ + v139_, v98_ + v140_, v135_, v136_)
	v141_:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.TIME))
	local v142_ = HUDElement.new(v141_)
	self.weatherElement:addChild(v142_)
	local _, v_u_143_ = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.TIME_TEXT)
	local v144_ = getNormalizedScreenValues
	local v145_ = GameInfoDisplayMobile.POSITION.TIME_TEXT
	local v_u_146_, v_u_147_ = v144_(unpack(v145_))
	local v148_ = getNormalizedScreenValues
	local v149_ = GameInfoDisplayMobile.POSITION.TIME_TEXT_OFFSET
	local v_u_150_, _ = v148_(unpack(v149_))
	local v151_ = self.textElements
	table.insert(v151_, function()
		-- upvalues: (copy) self, (copy) v_u_146_, (copy) v_u_147_, (copy) v_u_150_, (copy) v_u_143_, (copy) v_u_126_
		local v152_ = self.environment.dayTime / 3600000
		local v153_ = math.floor(v152_)
		local v154_ = (v152_ - v153_) * 60
		local v155_ = math.floor(v154_)
		local v156_ = string.format("%02d", v153_)
		local v157_ = string.format("%02d", v155_)
		local v158_, v159_ = self.weatherElement:getPosition()
		local v160_ = v158_ + v_u_146_ * self.uiScale
		local v161_ = v159_ + v_u_147_ * self.uiScale
		GameInfoDisplayMobile.drawText(v160_ - v_u_150_ * self.uiScale, v161_, v_u_143_ * self.uiScale, true, RenderText.ALIGN_RIGHT, v_u_126_, v156_)
		GameInfoDisplayMobile.drawText(v160_, v161_, v_u_143_ * self.uiScale, true, RenderText.ALIGN_CENTER, v_u_126_, ":")
		GameInfoDisplayMobile.drawText(v160_ + v_u_150_ * self.uiScale, v161_, v_u_143_ * self.uiScale, true, RenderText.ALIGN_LEFT, v_u_126_, v157_)
	end)
end

-- Local values: sizeX, sizeY, weatherPos, weatherWidth, posX, posY, moneyOverlayUVs, i, uvs, iconSizeX, iconSizeY, iconOffsetX, iconOffsetY, overlay, moneyElement, _, textSize, moneyOffsetX, moneyOffsetY, colorWhite, monthDrawFunc
function GameInfoDisplayMobile:createMoneyElement()
	local v163_ = getNormalizedScreenValues
	local v164_ = GameInfoDisplayMobile.SIZE.MONEY
	local v165_, v166_ = v163_(unpack(v164_))
	local v167_ = getNormalizedScreenValues
	local v168_ = GameInfoDisplayMobile.POSITION.MONEY
	local v169_, v170_ = v167_(unpack(v168_))
	self.moneyOffsetX = v169_
	self.moneyOffsetY = v170_
	local v171_ = self.weatherElement:getPosition() + self.weatherElement.totalSize + self.moneyOffsetX
	local v172_ = 1 + self.moneyOffsetY - v166_
	self.moneyElement = self:createBackgroundElements(v171_, v172_, v165_)
	local v_u_173_ = {}
	for v174_, v175_ in pairs(GameInfoDisplayMobile.UV.MONEY_ICON) do
		v_u_173_[v174_] = GuiUtils.getUVs(v175_)
	end
	local v176_ = getNormalizedScreenValues
	local v177_ = GameInfoDisplayMobile.SIZE.MONEY_ICON
	local v178_, v179_ = v176_(unpack(v177_))
	local v180_ = getNormalizedScreenValues
	local v181_ = GameInfoDisplayMobile.POSITION.MONEY_ICON
	local v182_, v183_ = v180_(unpack(v181_))
	local v184_ = Overlay.new(self.controlHudAtlasPath, v171_ + v182_, v172_ + v183_, v178_, v179_)
	v184_:setUVs(v_u_173_[1])
	local v_u_185_ = HUDElement.new(v184_)
	self.moneyElement:addChild(v_u_185_)
	local _, v_u_186_ = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.MONEY_TEXT)
	local v187_ = getNormalizedScreenValues
	local v188_ = GameInfoDisplayMobile.POSITION.MONEY_TEXT
	local v_u_189_, v_u_190_ = v187_(unpack(v188_))
	local v_u_191_ = {
		1,
		1,
		1,
		1
	}
	local v192_ = self.textElements
	table.insert(v192_, function()
		-- upvalues: (copy) v_u_185_, (copy) v_u_173_, (copy) self, (copy) v_u_189_, (copy) v_u_190_, (copy) v_u_186_, (copy) v_u_191_
		v_u_185_:setUVs(v_u_173_[self.moneyUnit])
		local v193_
		if g_localPlayer == nil then
			v193_ = "0"
		else
			local v194_ = g_farmManager:getFarmById(g_localPlayer.farmId)
			local v195_ = v194_.money
			if v195_ >= 100000000 then
				local v196_ = v195_ / 1000000
				local v197_ = math.min(v196_, 999999)
				v193_ = g_i18n:formatNumber(v197_, 2, true) .. " M"
			else
				v193_ = g_i18n:formatMoney(v194_.money, 0, false, true)
			end
		end
		local v198_, v199_ = v_u_185_:getPosition()
		local v200_ = v198_ + v_u_189_ * self.uiScale
		local v201_ = v199_ + v_u_190_ * self.uiScale
		GameInfoDisplayMobile.drawText(v200_, v201_, v_u_186_ * self.uiScale, true, RenderText.ALIGN_RIGHT, v_u_191_, v193_)
	end)
end

-- Local values: sizeX, sizeY, moneyPos, moneyWidth, posX, posY, fuelOverlayUVs, i, uvs, iconSizeX, iconSizeY, iconOffsetX, iconOffsetY, overlay, _, uvs, fuelElement, fitnessUVs, _, textSize, fuelOffsetX, fuelOffsetY, colorWhite, fuelDrawFunc
function GameInfoDisplayMobile:createFuelFitnessElement()
	local v203_ = getNormalizedScreenValues
	local v204_ = GameInfoDisplayMobile.POSITION.FUEL
	local v205_, v206_ = v203_(unpack(v204_))
	self.fuelOffsetX = v205_
	self.fuelOffsetY = v206_
	local v207_ = getNormalizedScreenValues
	local v208_ = GameInfoDisplayMobile.SIZE.FUEL
	local v209_, v210_ = v207_(unpack(v208_))
	local v211_ = self.moneyElement:getPosition() + self.moneyElement.totalSize + self.fuelOffsetX
	local v212_ = 1 + self.fuelOffsetY - v210_
	self.fuelFitnessElement = self:createBackgroundElements(v211_, v212_, v209_)
	local v_u_213_ = {}
	for v214_, v215_ in pairs(GameInfoDisplayMobile.UV.FUEL_ICON) do
		v_u_213_[v214_] = GuiUtils.getUVs(v215_)
	end
	local v216_ = getNormalizedScreenValues
	local v217_ = GameInfoDisplayMobile.SIZE.FUEL_ICON
	local v218_, v219_ = v216_(unpack(v217_))
	local v220_ = getNormalizedScreenValues
	local v221_ = GameInfoDisplayMobile.POSITION.FUEL_ICON
	local v222_, v223_ = v220_(unpack(v221_))
	local v224_ = Overlay.new(self.controlHudAtlasPath, v211_ + v222_, v212_ + v223_, v218_, v219_)
	local _, v225_ = next(v_u_213_)
	v224_:setUVs(v225_)
	local v_u_226_ = HUDElement.new(v224_)
	self.fuelFitnessElement:addChild(v_u_226_)
	local v_u_227_ = GuiUtils.getUVs(GameInfoDisplayMobile.UV.HORSE)
	local _, v_u_228_ = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.FUEL_TEXT)
	local v229_ = getNormalizedScreenValues
	local v230_ = GameInfoDisplayMobile.POSITION.FUEL_TEXT
	local v_u_231_, v_u_232_ = v229_(unpack(v230_))
	local v_u_233_ = {
		1,
		1,
		1,
		1
	}
	local v234_ = self.textElements
	table.insert(v234_, function()
		-- upvalues: (copy) self, (copy) v_u_231_, (copy) v_u_232_, (copy) v_u_233_, (copy) v_u_228_, (copy) v_u_226_, (copy) v_u_227_, (copy) v_u_213_
		local v235_, v236_ = self.fuelFitnessElement:getPosition()
		local v237_ = v235_ + v_u_231_ * self.uiScale
		local v238_ = v236_ + v_u_232_ * self.uiScale
		if self.vehicle ~= nil then
			if self.isRideable then
				local v239_ = self.vehicle:getCluster():getRidingFactor() * 100
				local v240_ = math.floor(v239_)
				local v241_ = v_u_233_
				if v240_ <= 5 then
					v241_ = GameInfoDisplayMobile.COLOR.FUEL_EMPTY
				end
				GameInfoDisplayMobile.drawText(v237_, v238_, v_u_228_ * self.uiScale, true, RenderText.ALIGN_RIGHT, v241_, string.format("%d%%", v240_))
				v_u_226_:setUVs(v_u_227_)
				return
			end
			if self.vehicle.getConsumerFillUnitIndex ~= nil then
				local v242_ = self.vehicle:getConsumerFillUnitIndex(FillType.DIESEL) or (self.vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self.vehicle:getConsumerFillUnitIndex(FillType.METHANE))
				if v242_ ~= nil then
					local v243_ = g_fillTypeManager:getFillTypeNameByIndex(self.vehicle:getFillUnitFillType(v242_))
					local v244_ = MathUtil.round(self.vehicle:getFillUnitFillLevelPercentage(v242_) * 100)
					local v245_ = v_u_233_
					if v244_ <= 5 then
						v245_ = GameInfoDisplayMobile.COLOR.FUEL_EMPTY
					end
					GameInfoDisplayMobile.drawText(v237_, v238_, v_u_228_ * self.uiScale, true, RenderText.ALIGN_RIGHT, v245_, string.format("%d%%", v244_))
					v_u_226_:setUVs(v_u_213_[v243_])
				end
			end
		end
	end)
end

function GameInfoDisplayMobile.drawText(posX, posY, textSize, textBold, textAlign, color, text)
	setTextColor(color[1], color[2], color[3], color[4])
	setTextBold(textBold)
	setTextAlignment(textAlign)
	renderText(posX, posY, textSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
end

-- Local values: color
function GameInfoDisplayMobile:drawTextElement(textElement)
	textElement.updateFunc()
	local v254_ = textElement.color
	setTextColor(v254_[1], v254_[2], v254_[3], v254_[4])
	setTextBold(textElement.textBold)
	setTextAlignment(textElement.textAlign)
	renderText(textElement.posX, textElement.posY, textElement.textSize, textElement.text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
end

function GameInfoDisplayMobile:onOpenShop()
	if not g_sleepManager:getIsSleeping() then
		g_currentMission:onToggleStore()
	end
end

function GameInfoDisplayMobile:onOpenMap()
	if not g_sleepManager:getIsSleeping() then
		g_currentMission:onToggleMap()
	end
end

function GameInfoDisplayMobile:onOpenMenu()
	if not g_sleepManager:getIsSleeping() then
		g_currentMission:onToggleMenu()
	end
end

function GameInfoDisplayMobile:onOpenHelp()
	if not g_sleepManager:getIsSleeping() then
		g_currentMission:onToggleHelp()
	end
end

function GameInfoDisplayMobile:setMoneyUnit(moneyUnit)
	if moneyUnit ~= GS_MONEY_EURO and (moneyUnit ~= GS_MONEY_POUND and moneyUnit ~= GS_MONEY_DOLLAR) then
		moneyUnit = GS_MONEY_DOLLAR
	end
	self.moneyUnit = moneyUnit
end

function GameInfoDisplayMobile:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function GameInfoDisplayMobile:setEnvironment(environment)
	self.environment = environment
end

function GameInfoDisplayMobile:setMoneyVisible(isVisible) end

function GameInfoDisplayMobile:setTimeVisible(isVisible) end

function GameInfoDisplayMobile:setTemperatureVisible(isVisible) end

function GameInfoDisplayMobile:setWeatherVisible(isVisible) end

function GameInfoDisplayMobile:setDateVisible(isVisible) end

function GameInfoDisplayMobile:setTutorialVisible(isVisible) end

function GameInfoDisplayMobile:setTutorialProgress(progress) end

function GameInfoDisplayMobile:setHelpHighlighted(isHighlighted)
	self.isHelpHighlighted = isHighlighted
end

function GameInfoDisplayMobile:delete()
	g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
	GameInfoDisplayMobile:superClass().delete(self)
end

-- Local values: x, y, z, isHelpAvailable
function GameInfoDisplayMobile:update(dt)
	self:updateButtons()
	local v265_, v266_, v267_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v268_ = g_helpLineManager:getIsContextBasedHelpAvailable(v265_, v266_, v267_)
	self.helpHighlightElement:setVisible(self.helpButtonActive and v268_)
end

-- Local values: _, drawFuncs
function GameInfoDisplayMobile:draw()
	for _, v270_ in ipairs(self.textElements) do
		v270_()
	end
	GameInfoDisplayMobile:superClass().draw(self)
end

-- Local values: shopButtonWasActive, helpButtonWasActive, mapButtonWasActive, menuButtonWasActive, isGuiVisible
function GameInfoDisplayMobile:updateButtons()
	local _ = self.shopButtonActive
	local _ = self.helpButtonActive
	local _ = self.mapButtonActive
	local _ = self.menuButtonActive
	g_gui:getIsGuiVisible()
end

-- Local values: currentVisibility, posX, posY, width, height, refPosX, refPosY, buttonHighlight
function GameInfoDisplayMobile:setScale(uiScale)
	GameInfoDisplayMobile:superClass().setScale(self, uiScale, uiScale)
	local v274_ = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local v275_, v276_, v277_, v278_ = GameInfoDisplayMobile.getBackgroundPositionAndSize(uiScale)
	self:setPosition(v275_, v276_)
	self:setDimension(v277_, v278_)
	self:storeOriginalPosition()
	self:setVisible(v274_, false)
	local v279_ = v275_ + v277_
	local v280_ = v276_ + v278_
	self:updateButtonPosition(self.shopButton, v279_, v280_)
	self:updateButtonPosition(self.menuButton, v279_, v280_)
	self:updateButtonPosition(self.mapButton, v279_, v280_)
	self:updateButtonPosition(self.helpButton, v279_, v280_)
	local v281_ = self.helpHighlightElement
	v281_:setPosition(v279_ + v281_.offsetX * self.uiScale, nil)
end

function GameInfoDisplayMobile:updateInsets()
	self:setScale(self.uiScale)
end

-- Local values: offX, offY, _, sizeY, leftInset, rightInset, _, _, sizeX, posX, posY
function GameInfoDisplayMobile.getBackgroundPositionAndSize(scale)
	local v284_ = getNormalizedScreenValues
	local v285_ = GameInfoDisplayMobile.POSITION.BACKGROUND
	local v286_, v287_ = v284_(unpack(v285_))
	local v288_ = getNormalizedScreenValues
	local v289_ = GameInfoDisplayMobile.SIZE.BACKGROUND
	local _, v290_ = v288_(unpack(v289_))
	local v291_ = v286_ * scale
	local v292_, v293_, _, _ = getSafeFrameInsets()
	local v294_ = math.max(v292_, v291_)
	local v295_ = math.max(v293_, v291_)
	local v296_ = 1 - v294_ - v295_
	return v294_, 1 + v287_ * scale - v290_ * scale, v296_, v290_
end
function GameInfoDisplayMobile.createBackground()
	local v297_, v298_, v299_, v300_ = GameInfoDisplayMobile.getBackgroundPositionAndSize(1)
	return Overlay.new(nil, v297_, v298_, v299_, v300_)
end
GameInfoDisplayMobile.SIZE = {
	["BACKGROUND"] = { 1251, 106 },
	["BUTTON"] = { 106, 106 },
	["BUTTON_HIGHLIGHT"] = { 114, 114 },
	["ICON"] = { 84, 84 },
	["BG_LEFT"] = { 38, 75 },
	["BG_RIGHT"] = { 38, 75 },
	["BG_MIDDLE"] = { 34, 75 },
	["WEATHER"] = { 493, 75 },
	["WEATHER_SEPARATOR"] = { 2, 65 },
	["MONTH_TEXT"] = 54,
	["SEASON_ICON"] = { 65, 65 },
	["TIME_ICON"] = { 75, 75 },
	["TIME_TEXT"] = 54,
	["MONEY"] = { 390, 75 },
	["MONEY_ICON"] = { 75, 75 },
	["MONEY_TEXT"] = 54,
	["FUEL"] = { 262, 75 },
	["FUEL_ICON"] = { 75, 75 },
	["FUEL_TEXT"] = 54
}
GameInfoDisplayMobile.POSITION = {
	["BG_LEFT"] = { 38, 75 },
	["BG_RIGHT"] = { 38, 75 },
	["BG_MIDDLE"] = { 34, 75 },
	["BUTTON_OFFSET"] = { -25, -35 },
	["MENU"] = { -25, -35 },
	["SHOP"] = { -25, -35 },
	["MAP"] = { -25, -35 },
	["HELP"] = { -25, -35 },
	["BUTTON_HIGHLIGHT"] = { -4, -4 },
	["WEATHER"] = { 0, -35 },
	["WEATHER_SEPARATOR"] = { 232, 5 },
	["SEASON_ICON"] = { 10, 5 },
	["MONTH_TEXT"] = { 93, 18 },
	["TIME_ICON"] = { 246, 0 },
	["TIME_TEXT"] = { 400, 18 },
	["TIME_TEXT_OFFSET"] = { 5, 0 },
	["MONEY"] = { 15, -35 },
	["MONEY_ICON"] = { 5, 0 },
	["MONEY_TEXT"] = { 370, 18 },
	["FUEL"] = { 15, -35 },
	["FUEL_ICON"] = { 15, 0 },
	["FUEL_TEXT"] = { 242, 18 },
	["BACKGROUND"] = { 55, -1 }
}
local v301_ = GameInfoDisplayMobile
local v302_ = {
	["BUTTON_NORMAL"] = {
		132,
		908,
		106,
		106
	},
	["BUTTON_PRESSED"] = {
		238,
		908,
		106,
		106
	},
	["BUTTON_DISABLED"] = {
		344,
		908,
		106,
		106
	},
	["BUTTON_HIGHLIGHT"] = {
		801,
		904,
		114,
		114
	},
	["SHOP"] = {
		576,
		96,
		96,
		96
	},
	["MENU"] = {
		864,
		0,
		96,
		96
	},
	["MAP"] = {
		480,
		96,
		96,
		96
	},
	["HELP"] = {
		0,
		288,
		96,
		96
	},
	["BG_LEFT"] = {
		454,
		928,
		38,
		75
	},
	["BG_RIGHT"] = {
		526,
		928,
		38,
		75
	},
	["BG_MIDDLE"] = {
		498,
		928,
		34,
		75
	},
	["SEASON_ICON"] = {
		[Season.SPRING] = {
			960,
			48,
			48,
			48
		},
		[Season.SUMMER] = {
			960,
			96,
			48,
			48
		},
		[Season.AUTUMN] = {
			960,
			144,
			48,
			48
		},
		[Season.WINTER] = {
			960,
			0,
			48,
			48
		}
	},
	["TIME"] = {
		384,
		192,
		96,
		96
	},
	["MONEY_ICON"] = {
		[GS_MONEY_DOLLAR] = {
			480,
			192,
			96,
			96
		},
		[GS_MONEY_POUND] = {
			576,
			192,
			96,
			96
		},
		[GS_MONEY_EURO] = {
			672,
			192,
			96,
			96
		}
	},
	["FUEL_ICON"] = {
		["DIESEL"] = {
			288,
			192,
			96,
			96
		},
		["ELECTRICCHARGE"] = {
			768,
			192,
			96,
			96
		},
		["METHANE"] = {
			864,
			192,
			96,
			96
		}
	},
	["HORSE"] = {
		192,
		192,
		96,
		96
	}
}
v301_.UV = v302_
GameInfoDisplayMobile.COLOR = {
	["BACKGROUND"] = {
		1,
		1,
		1,
		0.5
	},
	["SEPARATOR"] = {
		1,
		1,
		1,
		0.5
	},
	["FUEL_EMPTY"] = {
		0.5029,
		0.0152,
		0.0152,
		1
	}
}
if v1_ ~= nil then
	local v303_ = GameInfoDisplayMobile.new(v1_.hud, v1_.hudAtlasPath, v1_.moneyUnit, v1_.controlHudAtlasPath)
	v303_:setVehicle(v1_.vehicle)
	v303_:setScale(v1_.uiScale)
	v303_:setMoneyUnit(v1_.moneyUnit)
	v303_:setMissionInfo(v1_.missionInfo)
	v303_:setEnvironment(v1_.environment)
	for v304_, v305_ in ipairs(g_currentMission.hud.displayComponents) do
		if v305_ == g_currentMission.hud.gameInfoDisplay then
			g_currentMission.hud.displayComponents[v304_] = v303_
			break
		end
	end
	g_currentMission.hud.gameInfoDisplay = v303_
	Logging.info("Reloaded")
end
