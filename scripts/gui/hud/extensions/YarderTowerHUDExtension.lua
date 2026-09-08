-- Local values: YarderTowerHUDExtension_mt
YarderTowerHUDExtension = {}
local YarderTowerHUDExtension_mt = Class(YarderTowerHUDExtension)

-- Upvalues: YarderTowerHUDExtension_mt
-- Local values: self, r, g, b, a
function YarderTowerHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) YarderTowerHUDExtension_mt
	local v4_ = customMt or YarderTowerHUDExtension_mt
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
	v5_.iconCarriage = g_overlayManager:createOverlay("gui.icon_carriage", 0, 0, 0, 0)
	v5_.iconPlayer = g_overlayManager:createOverlay("gui.icon_position", 0, 0, 0, 0)
	v5_.iconPosition = g_overlayManager:createOverlay("gui.icon_position", 0, 0, 0, 0)
	v5_.iconTree = g_overlayManager:createOverlay("gui.icon_tree", 0, 0, 0, 0)
	v5_.iconYarder = g_overlayManager:createOverlay("gui.icon_yarder", 0, 0, 0, 0)
	v5_.text = string.format("%s - %s", g_i18n:getText("ui_yarder"), vehicle:getName())
	v5_.vehicle = vehicle
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function YarderTowerHUDExtension:delete()
	self.backgroundTop:delete()
	self.backgroundScale:delete()
	self.backgroundBottom:delete()
	self.iconCarriage:delete()
	self.iconPlayer:delete()
	self.iconPosition:delete()
	self.iconTree:delete()
	self.iconYarder:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height
function YarderTowerHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local _, v14_ = getNormalizedScreenValues(0, 77 * v13_)
	self.totalHeight = v14_
	local v15_, v16_ = getNormalizedScreenValues(330 * v13_, 6 * v13_)
	self.backgroundTop:setDimension(v15_, v16_)
	self.backgroundBottom:setDimension(v15_, v16_)
	self.backgroundScale:setDimension(v15_, self.totalHeight - 2 * v16_)
	local v17_, v18_ = getNormalizedScreenValues(20 * v13_, 20 * v13_)
	self.iconCarriage:setDimension(v17_, v18_)
	local v19_, v20_ = getNormalizedScreenValues(6 * v13_, 5 * v13_)
	self.iconPosition:setDimension(v19_, v20_)
	local v21_, v22_ = getNormalizedScreenValues(10 * v13_, 9 * v13_)
	self.iconPlayer:setDimension(v21_, v22_)
	local v23_, v24_ = getNormalizedScreenValues(20 * v13_, 9 * v13_)
	self.iconTree:setDimension(v23_, v24_)
	local v25_, v26_ = getNormalizedScreenValues(290 * v13_, 45 * v13_)
	self.iconYarder:setDimension(v25_, v26_)
	local v27_, v28_ = getNormalizedScreenValues(8 * v13_, 5 * v13_)
	self.yarderOffsetX = v27_
	self.yarderOffsetY = v28_
	local _, v29_ = getNormalizedScreenValues(0 * v13_, 8 * v13_)
	self.playerOffsetY = v29_
	self.playerMinOffsetX = getNormalizedScreenValues(33 * v13_, 0 * v13_)
	self.playerMaxOffsetX = getNormalizedScreenValues(258 * v13_, 0 * v13_)
	local _, v30_ = getNormalizedScreenValues(0 * v13_, 48 * v13_)
	self.positionOffsetY = v30_
	self.positionMinOffsetX = getNormalizedScreenValues(30 * v13_, 0 * v13_)
	self.positionMaxOffsetX = getNormalizedScreenValues(266 * v13_, 0 * v13_)
	local _, v31_ = getNormalizedScreenValues(0 * v13_, 29 * v13_)
	self.carriageOffsetY = v31_
	self.carriageMinOffsetX = getNormalizedScreenValues(28 * v13_, 0 * v13_)
	self.carriageMaxOffsetX = getNormalizedScreenValues(253 * v13_, 0 * v13_)
	local v32_, v33_ = getNormalizedScreenValues(14 * v13_, 58 * v13_)
	self.textOffsetX = v32_
	self.textOffsetY = v33_
	local _, v34_ = getNormalizedScreenValues(0, 12 * v13_)
	self.textSize = v34_
end

-- Local values: isPlayerInRange, isLoaded, playerPosition, carriagePosition, followModeState, followModeLocalPlayer, targetPosition, positionOffsetX, playerOffsetX, carriageOffsetX, treePosX, treePosY
function YarderTowerHUDExtension:draw(inputHelpDisplay, posX, posY)
	self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
	self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
	self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
	self.backgroundTop:render()
	self.backgroundScale:render()
	self.backgroundBottom:render()
	local v38_ = self.backgroundBottom.y
	local v39_, v40_, v41_, v42_, v43_, v44_, v45_ = self.vehicle:getYarderStatusInfo()
	self.iconYarder:setPosition(posX + self.yarderOffsetX, v38_ + self.yarderOffsetY)
	self.iconYarder:render()
	if v45_ ~= nil then
		local v46_ = self.iconPosition
		local v47_ = g_time * 0.0075
		v46_:setColor(nil, nil, nil, math.sin(v47_) * 0.25 + 0.5)
		local v48_ = MathUtil.lerp(self.positionMinOffsetX, self.positionMaxOffsetX, v45_)
		self.iconPosition:setPosition(posX + v48_, v38_ + self.positionOffsetY)
		self.iconPosition:render()
	end
	if v39_ then
		if v43_ == YarderTower.FOLLOW_MODE_ME and v44_ then
			local v49_ = self.iconPlayer
			local v50_ = g_time * 0.0075
			v49_:setColor(nil, nil, nil, math.sin(v50_) * 0.25 + 0.5)
		else
			self.iconPlayer:setColor(nil, nil, nil, 1)
		end
		local v51_ = MathUtil.lerp(self.playerMinOffsetX, self.playerMaxOffsetX, v41_)
		self.iconPlayer:setPosition(posX + v51_, v38_ + self.playerOffsetY)
		self.iconPlayer:render()
	end
	local v52_ = MathUtil.lerp(self.carriageMinOffsetX, self.carriageMaxOffsetX, v42_)
	self.iconCarriage:setPosition(posX + v52_, v38_ + self.carriageOffsetY)
	self.iconCarriage:render()
	if v40_ then
		local v53_ = self.iconCarriage.x + self.iconCarriage.width * 0.5 - self.iconTree.width * 0.5
		local v54_ = self.iconCarriage.y - self.iconTree.height
		self.iconTree:setPosition(v53_, v54_)
		self.iconTree:render()
	end
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	renderText(posX + self.textOffsetX, v38_ + self.textOffsetY, self.textSize, self.text)
	setTextBold(false)
	return v38_
end

function YarderTowerHUDExtension:getHeight()
	return self.totalHeight
end
