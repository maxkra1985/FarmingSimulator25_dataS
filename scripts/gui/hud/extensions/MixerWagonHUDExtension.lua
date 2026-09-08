-- Local values: MixerWagonHUDExtension_mt
MixerWagonHUDExtension = {}
local MixerWagonHUDExtension_mt = Class(MixerWagonHUDExtension)

-- Upvalues: MixerWagonHUDExtension_mt
-- Local values: self, r, g, b, a, _, mixerWagonFillType, firstFilltype, fillType, icon, status
function MixerWagonHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) MixerWagonHUDExtension_mt
	local v4_ = customMt or MixerWagonHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_HIGH
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.backgroundTop = g_overlayManager:createOverlay("gui.hudExtension_top", 0, 0, 0, 0)
	v5_.backgroundTop:setColor(v7_, v8_, v9_, v10_)
	v5_.backgroundScale = g_overlayManager:createOverlay("gui.hudExtension_middle", 0, 0, 0, 0)
	v5_.backgroundScale:setColor(v7_, v8_, v9_, v10_)
	v5_.backgroundBottom = g_overlayManager:createOverlay("gui.hudExtension_bottom", 0, 0, 0, 0)
	v5_.backgroundBottom:setColor(v7_, v8_, v9_, v10_)
	v5_.bar = ThreePartOverlay.new()
	v5_.bar:setLeftPart("gui.progressbar_left", 0, 0)
	v5_.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	v5_.bar:setRightPart("gui.progressbar_right", 0, 0)
	v5_.marker = g_overlayManager:createOverlay("gui.tmr_marker", 0, 0, 0, 0)
	v5_.vehicle = vehicle
	v5_.mixerWagon = vehicle.spec_mixerWagon
	v5_.numFillTypes = #v5_.mixerWagon.mixerWagonFillTypes
	v5_.fillTypeStatus = {}
	for _, v11_ in ipairs(v5_.mixerWagon.mixerWagonFillTypes) do
		local v12_ = next(v11_.fillTypes)
		local v13_ = g_fillTypeManager:getFillTypeByIndex(v12_)
		if v13_ ~= nil then
			local v14_ = {
				["icon"] = Overlay.new(v13_.hudOverlayFilename, 0, 0, 0, 0),
				["fillLevel"] = 0,
				["minPercentage"] = v11_.minPercentage,
				["maxPercentage"] = v11_.maxPercentage
			}
			local v15_ = v5_.fillTypeStatus
			table.insert(v15_, v14_)
		end
	end
	v5_.badMixColor = {
		0.8069,
		0.0097,
		0.0097,
		1
	}
	v5_.title = utf8ToUpper(string.format("%s - %s", g_i18n:getText("info_mixingRatio"), vehicle:getFullName()))
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

-- Local values: _, status
function MixerWagonHUDExtension:delete()
	self.backgroundTop:delete()
	self.backgroundScale:delete()
	self.backgroundBottom:delete()
	self.marker:delete()
	self.bar:delete()
	for _, v17_ in ipairs(self.fillTypeStatus) do
		v17_.icon:delete()
	end
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height, barPartWidth, barPartHeight, iconWidth, iconHeight, _, status, markerWidth, markerHeight
function MixerWagonHUDExtension:storeScaledValues()
	local v19_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local _, v20_ = getNormalizedScreenValues(0, 26 * v19_)
	self.offsetTop = v20_
	local _, v21_ = getNormalizedScreenValues(0, 8 * v19_)
	self.offsetBottom = v21_
	local _, v22_ = getNormalizedScreenValues(0, 24 * v19_)
	self.heightPerFillType = v22_
	self.totalHeight = self.heightPerFillType * self.numFillTypes + self.offsetTop + self.offsetBottom
	local v23_, v24_ = getNormalizedScreenValues(330 * v19_, 6 * v19_)
	self.backgroundTop:setDimension(v23_, v24_)
	self.backgroundBottom:setDimension(v23_, v24_)
	self.backgroundScale:setDimension(v23_, self.totalHeight - 2 * v24_)
	local v25_, v26_ = getNormalizedScreenValues(14 * v19_, -19 * v19_)
	self.titleOffsetX = v25_
	self.titleOffsetY = v26_
	local _, v27_ = getNormalizedScreenValues(0, 12 * v19_)
	self.titleSize = v27_
	local v28_, v29_ = getNormalizedScreenValues(45 * v19_, 10 * v19_)
	self.barOffsetX = v28_
	self.barOffsetY = v29_
	local v30_, v31_ = getNormalizedScreenValues(3, 6)
	local v32_, _ = getNormalizedScreenValues(235 * v19_, 0)
	self.barMaxWidth = v32_
	self.barPartsWidth = 2 * v30_
	self.barPartHeight = v31_
	self.middlePartMaxWidth = self.barMaxWidth - self.barPartsWidth
	self.bar:setLeftPart(nil, v30_, v31_)
	self.bar:setMiddlePart(nil, self.middlePartMaxWidth, v31_)
	self.bar:setRightPart(nil, v30_, v31_)
	local v33_, v34_ = getNormalizedScreenValues(25 * v19_, 25 * v19_)
	for _, v35_ in ipairs(self.fillTypeStatus) do
		v35_.icon:setDimension(v33_, v34_)
	end
	local v36_, v37_ = getNormalizedScreenValues(11 * v19_, 2 * v19_)
	self.iconOffsetX = v36_
	self.iconOffsetY = v37_
	local v38_, v39_ = getNormalizedScreenValues(-5 * v19_, 8 * v19_)
	self.textOffsetX = v38_
	self.textOffsetY = v39_
	local _, v40_ = getNormalizedScreenValues(0, 12 * v19_)
	self.textSize = v40_
	local v41_, v42_ = getNormalizedScreenValues(11 * v19_, 11 * v19_)
	self.marker:setDimension(v41_, v42_)
end

-- Local values: barBgColor, activeColor, badMixColor, maxWidth, title, totalFillLevel, i, mixerWagonFillType, fillTypePosY, fillTypeTextPosX, _, status, icon, percentage, scale, offsetX, color, text
function MixerWagonHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v46_ = HUD.COLOR.BACKGROUND_DARK
	local v47_ = HUD.COLOR.ACTIVE
	local v48_ = self.badMixColor
	self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
	self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
	self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
	self.backgroundTop:render()
	self.backgroundScale:render()
	self.backgroundBottom:render()
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	local v49_ = self.backgroundTop.width - 2 * self.titleOffsetX
	local v50_ = Utils.limitTextToWidth(self.title, self.titleSize, v49_, false, "...")
	renderText(posX + self.titleOffsetX, posY + self.titleOffsetY, self.titleSize, v50_)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	local v51_ = 0
	if self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) > 0 then
		for v52_, v53_ in ipairs(self.mixerWagon.mixerWagonFillTypes) do
			v51_ = v51_ + v53_.fillLevel
			self.fillTypeStatus[v52_].fillLevel = v53_.fillLevel
		end
	end
	local v54_ = posY - self.offsetTop
	local v55_ = posX + self.backgroundTop.width + self.textOffsetX
	for _, v56_ in ipairs(self.fillTypeStatus) do
		v54_ = v54_ - self.heightPerFillType
		local v57_ = v56_.icon
		v57_:setPosition(posX + self.iconOffsetX, v54_ + self.iconOffsetY)
		v57_:render()
		self.bar:setMiddlePart(nil, self.middlePartMaxWidth, nil)
		self.bar:setColor(v46_[1], v46_[2], v46_[3], v46_[4])
		self.bar:setPosition(posX + self.barOffsetX, v54_ + self.barOffsetY)
		self.bar:render()
		local v58_ = self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) <= 0 and 0 or v56_.fillLevel / v51_
		local v59_ = self.barMaxWidth * (v56_.maxPercentage - v56_.minPercentage) - self.barPartsWidth
		local v60_ = self.barMaxWidth * v56_.minPercentage
		local v61_
		if v56_.fillLevel > 0 and (self.vehicle:getFillUnitFillType(self.mixerWagon.fillUnitIndex) ~= FillType.FORAGE_MIXING or v56_.minPercentage <= v58_ and v58_ <= v56_.maxPercentage) then
			v61_ = v47_
		else
			v61_ = v48_
		end
		self.bar:setColor(v61_[1], v61_[2], v61_[3], v61_[4])
		self.bar:setMiddlePart(nil, v59_, nil)
		self.bar:setPosition(posX + self.barOffsetX + v60_, nil)
		self.bar:render()
		self.marker:setPosition(posX + self.barOffsetX + self.barMaxWidth * v58_ - self.marker.width * 0.5, self.bar.y - (self.marker.height - self.barPartHeight) * 0.5)
		self.marker:render()
		local v62_ = string.format("%d%%", v58_ * 100)
		renderText(v55_, v54_ + self.textOffsetY, self.textSize, v62_)
	end
	setTextBold(false)
	return self.backgroundBottom.y
end

function MixerWagonHUDExtension:getHeight()
	return self.totalHeight
end
