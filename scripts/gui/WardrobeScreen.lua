-- Local values: WardrobeScreen_mt
WardrobeScreen = {}
local WardrobeScreen_mt = Class(WardrobeScreen, TabbedMenuWithDetails)
WardrobeScreen.CAMERA_FOV = 0.7155849933176751
WardrobeScreen.BACKGROUND_PATH = "data/store/ui/shop.i3d"
WardrobeScreen.LIGHTING_XML_PATH = "data/store/ui/wardrobe_lighting.xml"
function WardrobeScreen.register()
	WardrobeItemsFrame.register()
	WardrobeColorsFrame.register()
	WardrobeOutfitsFrame.register()
	WardrobeCharactersFrame.register()
	local v2_ = WardrobeScreen.new()
	g_gui:loadGui("dataS/gui/WardrobeScreen.xml", "WardrobeScreen", v2_)
	return v2_
end

-- Upvalues: WardrobeScreen_mt
-- Local values: self
function WardrobeScreen.new(target, custom_mt)
	-- upvalues: (copy) WardrobeScreen_mt
	local v5_ = TabbedMenuWithDetails.new(target, custom_mt or WardrobeScreen_mt)
	v5_.scenePrepared = false
	v5_.startRotY = 3.12413936106985
	v5_.characterPosition = { 14, 0.185, 35.5 }
	v5_.characterRotY = 3.490658503988659
	v5_.playerGraphics = nil
	v5_.needsBrandsInitialization = true
	v5_.defaultMenuButtonInfo = {}
	return v5_
end

-- Local values: newGui
function WardrobeScreen.createFromExistingGui(gui, guiName)
	WardrobeCharactersFrame.createFromExistingGui(g_gui.frames.wardrobeCharacters.target, "WardrobeCharactersFrame")
	WardrobeColorsFrame.createFromExistingGui(g_gui.frames.wardrobeColors.target, "WardrobeColorsFrame")
	WardrobeItemsFrame.createFromExistingGui(g_gui.frames.wardrobeItems.target, "WardrobeItemsFrame")
	WardrobeOutfitsFrame.createFromExistingGui(g_gui.frames.wardrobeOutfits.target, "WardrobeOutfitsFrame")
	local v8_ = WardrobeScreen.new()
	v8_.sceneRootNode = gui.sceneRootNode
	v8_.characterRootNode = gui.characterRootNode
	g_gui.guis[gui.name].target:delete()
	g_gui.guis[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, false)
	return v8_
end

-- Local values: playerStyle, _, config, _, preset
function WardrobeScreen:onOpen()
	WardrobeScreen:superClass().onOpen(self)
	self.isClosePending = false
	self.currentPlayerStyle = PlayerStyle.new()
	self.temporaryPlayerStyle = PlayerStyle.new()
	local v10_ = g_localPlayer.graphicsComponent:getStyle()
	if v10_ == nil then
		Logging.error("Player should not have a nil style!")
		printCallstack()
	end
	if not v10_:isValid() then
		Logging.warning("Selected style is invalid, reset to default style!")
		v10_ = PlayerStyle.defaultStyle(v10_)
	end
	self.currentPlayerStyle:copyFrom(v10_)
	self.currentPlayerStyle:loadConfigurationIfRequired()
	self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
	self:updatePagePlayerStyle()
	g_currentMission.environment:setCustomLighting(self.lighting)
	self.playerGraphics = HumanGraphicsComponent.new()
	self.playerGraphics:initialize()
	link(self.characterRootNode, self.playerGraphics.graphicsRootNode)
	self.playerGraphics:setModelYaw(self.characterRotY)
	self.isCharacterDirty = true
	self:updateBrandIcon()
	self.rotY = self.startRotY
	self.inputHorizontal = 0
	self.isDragging = false
	self.accumDraggingInput = 0
	self.lastInputMode = -1
	self.mouseDragActive = false
	self:registerActionEvents()
	self:updateInputGlyphs()
	self.previousCamera = g_cameraManager:getActiveCamera()
	g_cameraManager:setActiveCamera(self.camera)
	self:showContent(true)
	if self.needsBrandsInitialization then
		for _, v11_ in pairs(self.currentPlayerStyle.configs) do
			for _, v12_ in pairs(v11_.items) do
				if v12_.brandName ~= nil then
					v12_.brand = g_brandManager:getBrandByName(v12_.brandName)
					if v12_.brand ~= nil then
						v12_.brandName = nil
					end
				end
			end
		end
		self.needsBrandsInitialization = false
	end
end

function WardrobeScreen:onClose()
	self:removeActionEvents()
	self:showContent(false)
	g_currentMission.environment:setCustomLighting(nil)
	g_cameraManager:setActiveCamera(self.previousCamera)
	if self.playerGraphics ~= nil then
		self.playerGraphics:delete()
		self.playerGraphics = nil
	end
	self:showLoadingDialog(false)
	self.isNewCharacter = false
	WardrobeScreen:superClass().onClose(self)
end

function WardrobeScreen:onDetailClosed(detailPage)
	if self.colorDetailCallback ~= nil and not self.isPoppingDetailSafely then
		self.colorDetailCallback(false)
		self.colorDetailCallback = nil
	end
end

-- Local values: style, savedStyle
function WardrobeScreen:updatePagePlayerStyle()
	local v16_ = self.temporaryPlayerStyle
	local v17_ = self.currentPlayerStyle
	self.pageCharacter:setPlayerStyle(v16_, v17_)
	self.pageHair:setPlayerStyle(v16_, v17_)
	self.pageBeard:setPlayerStyle(v16_, v17_)
	self.pageHeadgear:setPlayerStyle(v16_, v17_)
	self.pageFootwear:setPlayerStyle(v16_, v17_)
	self.pageTop:setPlayerStyle(v16_, v17_)
	self.pageBottom:setPlayerStyle(v16_, v17_)
	self.pageGloves:setPlayerStyle(v16_, v17_)
	self.pageGlasses:setPlayerStyle(v16_, v17_)
	self.pageColors:setPlayerStyle(v16_, v17_)
	self.pageOutfit:setPlayerStyle(v16_, v17_)
end

function WardrobeScreen:onGuiSetupFinished()
	WardrobeScreen:superClass().onGuiSetupFinished(self)
	self:initializePages()
	self:setupMenuPages()
end

function WardrobeScreen:initializePages()
	self.pageCharacter:initialize("face", self, "character_option_body", WardrobeScreen.SLICE_ID.CHARACTER)
	self.pageHair:initialize("hairStyle", self, "character_option_hairStyle", WardrobeScreen.SLICE_ID.HAIR)
	self.pageBeard:initialize("beard", self, "character_option_beardStyle", WardrobeScreen.SLICE_ID.BEARD)
	self.pageHeadgear:initialize("headgear", self, "character_option_headGear", WardrobeScreen.SLICE_ID.HEADGEAR)
	self.pageFootwear:initialize("footwear", self, "character_option_footwear", WardrobeScreen.SLICE_ID.FOOTWEAR)
	self.pageTop:initialize("top", self, "character_option_top", WardrobeScreen.SLICE_ID.TOP)
	self.pageBottom:initialize("bottom", self, "character_option_bottom", WardrobeScreen.SLICE_ID.BOTTOM)
	self.pageGloves:initialize("gloves", self, "character_option_gloves", WardrobeScreen.SLICE_ID.GLOVES)
	self.pageGlasses:initialize("glasses", self, "character_option_glasses", WardrobeScreen.SLICE_ID.GLASSES)
	self.pageOutfit:initialize(self, "character_option_outfits", WardrobeScreen.SLICE_ID.OUTFIT)
	self.pageColors:initialize(self)
end

-- Local values: rootPagePredicate, colorPagePredicate, orderedDefaultPages, i, pageDef, page, predicate, sliceId
function WardrobeScreen:setupMenuPages()
	local function v21_()
		-- upvalues: (copy) self
		return not self:getIsDetailMode()
	end
	local v22_ = {
		{ self.pageCharacter, v21_, WardrobeScreen.SLICE_ID.CHARACTER },
		{ self.pageHair, v21_, WardrobeScreen.SLICE_ID.HAIR },
		{ self.pageBeard, v21_, WardrobeScreen.SLICE_ID.BEARD },
		{ self.pageOutfit, v21_, WardrobeScreen.SLICE_ID.OUTFIT },
		{ self.pageTop, v21_, WardrobeScreen.SLICE_ID.TOP },
		{ self.pageBottom, v21_, WardrobeScreen.SLICE_ID.BOTTOM },
		{ self.pageFootwear, v21_, WardrobeScreen.SLICE_ID.FOOTWEAR },
		{ self.pageHeadgear, v21_, WardrobeScreen.SLICE_ID.HEADGEAR },
		{ self.pageGloves, v21_, WardrobeScreen.SLICE_ID.GLOVES },
		{ self.pageGlasses, v21_, WardrobeScreen.SLICE_ID.GLASSES },
		{ self.pageColors, function()
				-- upvalues: (copy) self
				return self:getIsDetailMode()
			end, WardrobeScreen.SLICE_ID.HEADGEAR }
	}
	for v23_, v24_ in ipairs(v22_) do
		local v25_, v26_, v27_ = unpack(v24_)
		self:registerPage(v25_, v23_, v26_)
		self:addPageTab(v25_, nil, nil, v27_)
	end
	self:rebuildTabList()
end

-- Local values: onButtonPagePreviousFunction, onButtonPageNextFunction
function WardrobeScreen:setupMenuButtonInfo()
	WardrobeScreen:superClass().setupMenuButtonInfo(self)
	local v29_ = self:makeSelfCallback(self.onPagePrevious)
	local v30_ = self:makeSelfCallback(self.onPageNext)
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK,
		["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		["callback"] = self.clickBackCallback
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = v30_
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = v29_
	}
	self.defaultMenuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[3]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = self.clickBackCallback,
		[InputAction.MENU_PAGE_PREV] = v29_,
		[InputAction.MENU_PAGE_NEXT] = v30_
	}
end

function WardrobeScreen:setNextOpenIsNewCharacter()
	self.isNewCharacter = true
end

-- Local values: style, callback
function WardrobeScreen:onButtonBack()
	if not self.isClosePending then
		self.isClosePending = true
		self:showLoadingDialog(true)
		local v33_ = self.currentPlayerStyle
		if not v33_:isValid() then
			Logging.warning("Selected style is invalid, reset to default style!")
			self.currentPlayerStyle:copyFrom(PlayerStyle.defaultStyle(v33_))
		end
		g_localPlayer:setStyleAsync(self.currentPlayerStyle, false, function(_)
			-- upvalues: (copy) self
			g_gameSettings:setLastPlayerStyle(self.currentPlayerStyle)
			g_gameSettings:save()
			self:exitMenu()
		end, false)
	end
end

-- Local values: cb
function WardrobeScreen:update(dt)
	WardrobeScreen:superClass().update(self, dt)
	if self.isCharacterDirty then
		self:updateCharacter()
		self.isCharacterDirty = false
	end
	if self.updateAnimationCallback ~= nil and not self.updateAnimationCallback(dt) then
		self.updateAnimationCallback = nil
		if self.updateAnimationFinishedCallback ~= nil then
			local v36_ = self.updateAnimationFinishedCallback
			self.updateAnimationFinishedCallback = nil
			v36_()
		end
	end
	if self.playerGraphics ~= nil then
		self.playerGraphics:defaultAllParameters()
		self.playerGraphics:update(dt)
	end
	self:updateInput(dt)
	self:updateCamera(dt)
end

function WardrobeScreen:updateCamera(dt)
	if self.rotateNode ~= nil then
		setRotation(self.rotateNode, 0, self.rotY, 0)
	end
end

function WardrobeScreen:showContent(show)
	if show then
		self.header:setVisible(true)
		self.buttonsPanel:setVisible(true)
		self.background:setVisible(true)
		setVisibility(self.sceneRootNode, true)
	else
		self.header:setVisible(false)
		self.buttonsPanel:setVisible(false)
		self.background:setVisible(false)
		setVisibility(self.sceneRootNode, false)
	end
end

function WardrobeScreen:showLoadingDialog(show)
	self.loadingAnimation:setVisible(show)
end

function WardrobeScreen:runAnimation(duration, tick, finish)
	self.animationTime = duration
	function self.updateAnimationCallback(p46_)
		-- upvalues: (copy) self, (copy) duration, (copy) tick
		self.animationTime = self.animationTime - p46_
		local v47_ = 1 - self.animationTime / duration
		local v48_ = math.max(v47_, 0)
		tick((math.min(v48_, 1)))
		return self.animationTime > 0
	end
	self.updateAnimationFinishedCallback = finish
end

function WardrobeScreen:fadeOut(cb)
	self:runAnimation(150, function(_)
		-- upvalues: (copy) self
		self.fadeElement:setImageColor(nil, 0, 0, 0, Tween.CURVE.EASE_IN())
	end, cb)
end

function WardrobeScreen:fadeIn(cb)
	self:runAnimation(150, function(_)
		-- upvalues: (copy) self
		self.fadeElement:setImageColor(nil, 0, 0, 0, 1 - Tween.CURVE.EASE_OUT())
	end, cb)
end

function WardrobeScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self.sceneRootNode = createTransformGroup("CharacterArea")
	self.characterRootNode = createTransformGroup("CaracterRootNode")
	link(getRootNode(), self.sceneRootNode)
	link(self.sceneRootNode, self.characterRootNode)
	setTranslation(self.sceneRootNode, 0, -100, 100)
	setVisibility(self.sceneRootNode, false)
	setTranslation(self.characterRootNode, self.characterPosition[1], self.characterPosition[2], self.characterPosition[3])
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(WardrobeScreen.BACKGROUND_PATH, false, true, self.onLoadedWardrobeScene, self, nil)
	g_currentMission:startLoadingTask()
	self.hasLoadingTask = true
end

-- Local values: cameraTargetNode, dofSettings, xmlFile
function WardrobeScreen:onLoadedWardrobeScene(node, failedReason, args)
	removeFromPhysics(node)
	link(self.sceneRootNode, node)
	addToPhysics(node)
	self.rotY = self.startRotY
	self.rotateNode = createTransformGroup("rotateNode")
	link(self.characterRootNode, self.rotateNode)
	setWorldRotation(self.rotateNode, 0, self.rotY, 0)
	local v56_ = createTransformGroup("finalCameraPosNode")
	link(self.rotateNode, v56_)
	setTranslation(v56_, -1.35, 0.8, 0)
	setRotation(v56_, -0.13962634015954636, 0.9599310885968813, 0)
	local v57_ = g_depthOfFieldManager:createInfo(0.75, 2, 0.3, 3, 7, false)
	self.camera = createCamera("camera_ccscreen", WardrobeScreen.CAMERA_FOV, 2, 10000)
	g_cameraManager:addCamera(self.camera, nil, false, nil, v57_, false)
	link(v56_, self.camera)
	setTranslation(self.camera, 0, 0, 4)
	self.lighting = LightingStatic.new()
	local v58_ = XMLFile.load("wardrobeLighting", WardrobeScreen.LIGHTING_XML_PATH)
	self.lighting:load(v58_, "lighting", g_currentMission.baseDirectory)
	v58_:delete()
	self.scenePrepared = true
	if self.hasLoadingTask then
		g_currentMission:finishLoadingTask()
		self.hasLoadingTask = nil
	end
end

function WardrobeScreen:unloadMapData()
	if self.sceneRootNode ~= nil then
		delete(self.sceneRootNode)
		self.sceneRootNode = nil
		self.rotateNode = nil
		self.characterRootNode = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	if self.lighting ~= nil then
		self.lighting:delete()
		self.lighting = nil
	end
	if self.hasLoadingTask then
		g_currentMission:finishLoadingTask()
		self.hasLoadingTask = nil
	end
	if self.camera ~= nil then
		g_cameraManager:removeCamera(self.camera)
	end
	self.scenePrepared = false
end

-- Local values: callback, isDifferentCharacter
function WardrobeScreen:updateCharacter(isCreatingScene)
	if self.playerGraphics ~= nil and self.scenePrepared then
		self.loadingAnimation:setVisible(true)
		local function v64_(_, p62_, p63_)
			-- upvalues: (copy) self, (copy) isCreatingScene
			self:updateCharacterFinished(p62_, p63_, isCreatingScene)
		end
		local v65_ = self.playerGraphics.model.xmlFilename ~= self.temporaryPlayerStyle.xmlFilename
		if not self.temporaryPlayerStyle:isValid() then
			Logging.warning("Selected style is invalid, reset to default style!")
			self.temporaryPlayerStyle:copyFrom(PlayerStyle.defaultStyle(self.temporaryPlayerStyle))
		end
		self.playerGraphics:setStyleAsync(self.temporaryPlayerStyle, v64_, nil, nil, true)
		if v65_ then
			setVisibility(self.characterRootNode, false)
		end
		if g_currentMission ~= nil and g_currentMission.playerSystem ~= nil then
			g_gameSettings:setValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE, g_localPlayer.graphicsComponent:getStyle():getIsMale())
		end
	end
end

function WardrobeScreen:updateCharacterFinished(loadingState, loadedNewPlayerModel, isCreatingScene)
	if not loadedNewPlayerModel and loadingState == HumanModelLoadingState.OK then
		self.loadingAnimation:setVisible(false)
		setVisibility(self.characterRootNode, true)
	end
	self.loadingAnimation:setVisible(false)
	if loadingState == HumanModelLoadingState.OK then
		setVisibility(self.characterRootNode, true)
		self.playerGraphics:defaultAllParameters()
		self:updateBrandIcon()
		return
	elseif loadingState == HumanModelLoadingState.CANCELED then
		Logging.devInfo("Loading player model canceled")
	else
		Logging.error("Loading player model failed")
	end
end

-- Local values: brandImage, configName, fallbackConfigName, index, item
function WardrobeScreen:updateBrandIcon()
	local v70_ = nil
	local v71_ = self.currentPage.configName
	local v72_
	if self.currentPage:isa(WardrobeOutfitsFrame) then
		v71_ = "onepiece"
		v72_ = "top"
	else
		v72_ = nil
	end
	if v71_ ~= nil then
		local v73_ = self.temporaryPlayerStyle.configs[v71_].selectedItemIndex
		local v74_ = self.temporaryPlayerStyle.configs[v71_].items[v73_]
		if v74_ ~= nil and v74_.brandName ~= nil then
			v74_.brand = g_brandManager:getBrandByName(v74_.brandName)
			if v74_.brand ~= nil then
				v74_.brandName = nil
			end
		end
		if v74_ == nil or v74_.brand == nil then
			if v72_ ~= nil then
				local v75_ = self.temporaryPlayerStyle.configs[v72_].selectedItemIndex
				local v76_ = self.temporaryPlayerStyle.configs[v72_].items[v75_]
				if v76_ ~= nil and v76_.brand ~= nil then
					v70_ = v76_.brand.image
				end
			end
		else
			v70_ = v74_.brand.image
		end
	end
	self.brandIcon:setVisible(v70_ ~= nil)
	if v70_ ~= nil then
		self.brandIcon:setImageFilename(v70_)
	end
end

function WardrobeScreen:onItemSelectionStart()
	if self.temporaryPlayerStyle ~= nil then
		self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
		self.isCharacterDirty = true
	end
end

function WardrobeScreen:onItemSelectionChanged()
	self.isCharacterDirty = true
end

function WardrobeScreen:onItemSelectionConfirmed()
	self.currentPlayerStyle:copyFrom(self.temporaryPlayerStyle)
end

function WardrobeScreen:onItemSelectionCancelled()
	if self.temporaryPlayerStyle ~= nil then
		self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
		self.isCharacterDirty = true
	end
end

function WardrobeScreen:onItemShowColors(configName, item, itemsCallback)
	self.colorDetailCallback = itemsCallback
	self.pageColors:setConfigAndItem(configName, item)
	self:pushDetail(self.pageColors)
end

function WardrobeScreen:onColorSelectionChanged()
	self.isCharacterDirty = true
end

function WardrobeScreen:onColorSelectionConfirmed(keepOpen)
	if not keepOpen then
		self.isPoppingDetailSafely = true
		self:popDetail()
		self.isPoppingDetailSafely = false
	end
	self.colorDetailCallback(true, keepOpen)
	self.currentPlayerStyle:copyFrom(self.temporaryPlayerStyle)
	if not keepOpen then
		self.colorDetailCallback = nil
	end
end

function WardrobeScreen:onColorSelectionCancelled(keepOpen)
	if not keepOpen then
		self.isPoppingDetailSafely = true
		self:popDetail()
		self.isPoppingDetailSafely = false
	end
	self.colorDetailCallback(false, keepOpen)
	if not keepOpen then
		self.colorDetailCallback = nil
	end
end

-- Local values: _
function WardrobeScreen:registerActionEvents()
	if self.eventIdLeftRightController ~= nil then
		g_inputBinding:removeActionEvent(self.eventIdLeftRightController)
	end
	local _, v91_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, true)
	self.eventIdLeftRightController = v91_
	self.lastInputMode = -1
	self:updateInputContext()
end

function WardrobeScreen:removeActionEvents()
	g_inputBinding:removeActionEvent(self.eventIdLeftRightController)
	self.eventIdLeftRightController = nil
end

function WardrobeScreen:updateInputGlyphs()
	self.rotateCameraGlyph:setActions({ InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE })
end

function WardrobeScreen:onCameraLeftRight(actionName, inputValue, callbackState, isAnalog)
	self.inputHorizontal = inputValue * -2
end

-- Local values: dx, dragValue
function WardrobeScreen:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if GuiUtils.checkOverlayOverlap(posX, posY, self.background.absPosition[1], self.background.absPosition[2], self.background.absSize[1], self.background.absSize[2]) then
			self.mouseDragActive = false
			return
		end
		if isDown then
			self.mouseDragActive = true
			self.lastMousePosX = posX
		end
		if isUp then
			self.mouseDragActive = false
		end
		if self.mouseDragActive then
			local v101_ = posX - self.lastMousePosX
			self.lastMousePosX = posX
			local v102_ = v101_ * 200
			self.inputHorizontal = self.inputHorizontal + v102_
		end
	end
end

-- Local values: value, rotSpeed
function WardrobeScreen:updateInput(dt)
	self:updateInputContext()
	if self.inputHorizontal ~= 0 then
		local v105_ = self.inputHorizontal
		self.inputHorizontal = 0
		local v106_ = 0.001 * dt
		self.rotY = self.rotY - v106_ * v105_
	end
	self.inputDragging = false
end

-- Local values: currentInputMode, isController
function WardrobeScreen:updateInputContext()
	local v108_ = g_inputBinding:getLastInputMode()
	if v108_ ~= self.lastInputMode then
		local v109_ = v108_ == GS_INPUT_HELP_MODE_GAMEPAD
		g_inputBinding:setActionEventActive(self.eventIdLeftRightController, v109_)
		self:updateInputGlyphs()
		self.lastInputMode = v108_
		self.isDragging = false
	end
end
WardrobeScreen.SLICE_ID = {
	["CHARACTER"] = "gui.wardrobe_character",
	["HAIR"] = "gui.wardrobe_hairstyles",
	["BEARD"] = "gui.wardrobe_beards",
	["HEADGEAR"] = "gui.wardrobe_headgear",
	["FOOTWEAR"] = "gui.wardrobe_shoes",
	["TOP"] = "gui.wardrobe_tops",
	["BOTTOM"] = "gui.wardrobe_bottoms",
	["GLOVES"] = "gui.wardrobe_gloves",
	["GLASSES"] = "gui.wardrobe_glasses",
	["ONEPIECE"] = "gui.wardrobe_onepieceSuits",
	["OUTFIT"] = "gui.wardrobe_outfits"
}
