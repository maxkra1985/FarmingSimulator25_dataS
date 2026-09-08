-- Local values: GuiElement_mt, findFirstFocusableSearch, findLastFocusableSearch
GuiElement = {}
local GuiElement_mt = Class(GuiElement)
Gui.registerGuiElement("GuiElement", GuiElement)
GuiElement.SCREEN_ALIGN_LEFT = 1
GuiElement.SCREEN_ALIGN_CENTER = 2
GuiElement.SCREEN_ALIGN_RIGHT = 4
GuiElement.SCREEN_ALIGN_BOTTOM = 8
GuiElement.SCREEN_ALIGN_MIDDLE = 16
GuiElement.SCREEN_ALIGN_TOP = 32
GuiElement.SCREEN_ALIGN_XNONE = 64
GuiElement.SCREEN_ALIGN_YNONE = 128
GuiElement.ORIGIN_LEFT = 1
GuiElement.ORIGIN_CENTER = 2
GuiElement.ORIGIN_RIGHT = 4
GuiElement.ORIGIN_BOTTOM = 8
GuiElement.ORIGIN_MIDDLE = 16
GuiElement.ORIGIN_TOP = 32
GuiElement.MARGIN_LEFT = 1
GuiElement.MARGIN_TOP = 2
GuiElement.MARGIN_RIGHT = 3
GuiElement.MARGIN_BOTTOM = 4
GuiElement.FRAME_LEFT = 1
GuiElement.FRAME_TOP = 2
GuiElement.FRAME_RIGHT = 3
GuiElement.FRAME_BOTTOM = 4
GuiElement.FRAME_DEFAULT_COLOR = {
	1,
	1,
	1,
	1
}
GuiElement.SCROLL_SPEED_PIXEL_PER_MS = 0.005
GuiElement.debugOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")

-- Upvalues: GuiElement_mt
-- Local values: self
function GuiElement.new(target, custom_mt)
	-- upvalues: (copy) GuiElement_mt
	local v4_ = custom_mt or GuiElement_mt
	local v5_ = setmetatable({}, v4_)
	v5_:include(GuiMixin)
	v5_.elements = {}
	v5_.target = target
	v5_.profile = ""
	v5_.name = nil
	v5_.debugEnabled = false
	v5_.position = { 0, 0 }
	v5_.absPosition = { 0, 0 }
	v5_.size = { 1, 1 }
	v5_.absSize = { 1, 1 }
	v5_.sizeStr = "100% 100%"
	v5_.widthStr = nil
	v5_.heightStr = nil
	v5_.margin = {
		0,
		0,
		0,
		0
	}
	v5_.anchors = {
		0,
		1,
		0,
		1
	}
	v5_.anchorDeltas = {}
	v5_.pivot = { 0, 0 }
	v5_.absoluteSizeOffset = nil
	v5_.thinLineProtection = true
	v5_.disallowFlowCut = false
	v5_.visible = true
	v5_.disabled = false
	v5_.selected = false
	v5_.focused = false
	v5_.highlighted = false
	v5_.alpha = 1
	v5_.fadeInTime = 0
	v5_.fadeOutTime = 0
	v5_.fadeDirection = 0
	v5_.newLayer = false
	v5_.toolTipText = nil
	v5_.toolTipElementId = nil
	v5_.toolTipElement = nil
	v5_.layoutIgnore = false
	v5_.focusOnHighlight = false
	v5_.focusFallthrough = false
	v5_.clipping = false
	v5_.hotspot = nil
	v5_.hasFrame = false
	if v5_.hasFrame then
		v5_.frameThickness = {
			0,
			0,
			0,
			0
		}
		v5_.frameColors = {
			[GuiElement.FRAME_LEFT] = {
				1,
				1,
				1,
				1
			},
			[GuiElement.FRAME_TOP] = {
				1,
				1,
				1,
				1
			},
			[GuiElement.FRAME_RIGHT] = {
				1,
				1,
				1,
				1
			},
			[GuiElement.FRAME_BOTTOM] = {
				1,
				1,
				1,
				1
			}
		}
		v5_.frameOverlayVisible = {
			true,
			true,
			true,
			true
		}
	end
	v5_.updateChildrenState = true
	v5_.overlayState = GuiOverlay.STATE_NORMAL
	v5_.previousOverlayState = nil
	v5_.isSoundSuppressed = false
	v5_.soundDisabled = false
	v5_.handleFocus = true
	v5_.focusChangeData = {}
	v5_.focusId = nil
	return v5_
end

-- Local values: profile, pro, frameColors, color, fadeInTime, fadeOutTime
function GuiElement:loadFromXML(xmlFile, key)
	local v9_ = getXMLString(xmlFile, key .. "#profile")
	if v9_ ~= nil then
		self.profile = v9_
		self:loadProfile((g_gui:getProfile(v9_)))
	end
	self:setId(xmlFile, key)
	self.onCreateArgs = getXMLString(xmlFile, key .. "#onCreateArgs")
	self:addCallback(xmlFile, key .. "#onCreate", "onCreateCallback")
	self:addCallback(xmlFile, key .. "#onOpen", "onOpenCallback")
	self:addCallback(xmlFile, key .. "#onClose", "onCloseCallback")
	self:addCallback(xmlFile, key .. "#onDraw", "onDrawCallback")
	self.name = getXMLString(xmlFile, key .. "#name") or self.name
	self.pivot = string.getVector(getXMLString(xmlFile, key .. "#pivot"), 2) or self.pivot
	self.position = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#position"), self.position)
	self.sizeStr = getXMLString(xmlFile, key .. "#size") or self.sizeStr
	self.widthStr = getXMLString(xmlFile, key .. "#width") or self.widthStr
	self.heightStr = getXMLString(xmlFile, key .. "#height") or self.heightStr
	self.absoluteSizeOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#absoluteSizeOffset"), self.absoluteSizeOffset)
	self.margin = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#margin"), self.margin)
	self.anchors = string.getVector(getXMLString(xmlFile, key .. "#anchors"), 4) or self.anchors
	self.thinLineProtection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#thinLineProtection"), self.thinLineProtection)
	self.visible = Utils.getNoNil(getXMLBool(xmlFile, key .. "#visible"), self.visible)
	self.disabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disabled"), self.disabled)
	self.newLayer = Utils.getNoNil(getXMLBool(xmlFile, key .. "#newLayer"), self.newLayer)
	self.debugEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#debugEnabled"), self.debugEnabled)
	self.updateChildrenState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#updateChildrenState"), self.updateChildrenState)
	self.toolTipText = getXMLString(xmlFile, key .. "#toolTipText")
	self.toolTipElementId = getXMLString(xmlFile, key .. "#toolTipElementId")
	self.layoutIgnore = Utils.getNoNil(getXMLBool(xmlFile, key .. "#layoutIgnore"), self.layoutIgnore)
	self.clipping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#clipping"), self.clipping)
	self.hotspot = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#hotspot"), self.hotspot)
	self.handleFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#handleFocus"), self.handleFocus)
	self.soundDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#soundDisabled"), self.soundDisabled)
	self.focusOnHighlight = Utils.getNoNil(getXMLBool(xmlFile, key .. "#focusOnHighlight"), self.focusOnHighlight)
	self.focusFallthrough = Utils.getNoNil(getXMLBool(xmlFile, key .. "#focusFallthrough"), self.focusFallthrough)
	self.disallowFlowCut = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disallowFlowCut"), self.disallowFlowCut)
	self.hasFrame = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasFrame"), self.hasFrame)
	if self.hasFrame then
		self.frameThickness = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#frameThickness"), self.frameThickness)
		local v10_ = self.frameColors or {}
		local v11_ = getXMLString(xmlFile, key .. "#frameLeftColor")
		v10_[GuiElement.FRAME_LEFT] = GuiUtils.getColorArray(v11_, v10_[GuiElement.FRAME_LEFT])
		local v12_ = getXMLString(xmlFile, key .. "#frameTopColor")
		v10_[GuiElement.FRAME_TOP] = GuiUtils.getColorArray(v12_, v10_[GuiElement.FRAME_TOP])
		local v13_ = getXMLString(xmlFile, key .. "#frameRightColor")
		v10_[GuiElement.FRAME_RIGHT] = GuiUtils.getColorArray(v13_, v10_[GuiElement.FRAME_RIGHT])
		local v14_ = getXMLString(xmlFile, key .. "#frameBottomColor")
		v10_[GuiElement.FRAME_BOTTOM] = GuiUtils.getColorArray(v14_, v10_[GuiElement.FRAME_BOTTOM])
		self.frameColors = table.size(v10_) > 0 and v10_ and v10_ or nil
		self.frameOverlayVisible = self.frameOverlayVisible or {
			true,
			true,
			true,
			true
		}
	end
	local v15_ = getXMLFloat(xmlFile, key .. "#fadeInTime")
	if v15_ ~= nil then
		self.fadeInTime = v15_ * 1000
	end
	local v16_ = getXMLFloat(xmlFile, key .. "#fadeOutTime")
	if v16_ ~= nil then
		self.fadeOutTime = v16_ * 1000
	end
	if self.toolTipText ~= nil and self.toolTipText:sub(1, 6) == "$l10n_" then
		self.toolTipText = g_i18n:getText(self.toolTipText:sub(7), self.customEnvironment)
	end
	FocusManager:loadElementFromXML(xmlFile, key, self)
	self:resolveSizeString()
	self:verifyConfiguration()
end

-- Local values: frameColors, fadeInTime, fadeOutTime
function GuiElement:loadProfile(profile, applyProfile)
	self.name = profile:getValue("name", self.name)
	self.pivot = string.getVector(profile:getValue("pivot"), 2) or self.pivot
	self.position = GuiUtils.getNormalizedScreenValues(profile:getValue("position"), self.position)
	self.sizeStr = profile:getValue("size", self.sizeStr)
	self.widthStr = profile:getValue("width", self.widthStr)
	self.heightStr = profile:getValue("height", self.heightStr)
	self.absoluteSizeOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("absoluteSizeOffset"), self.absoluteSizeOffset)
	self.margin = GuiUtils.getNormalizedScreenValues(profile:getValue("margin"), self.margin)
	self.anchors = string.getVector(profile:getValue("anchors"), 4) or self.anchors
	self.visible = profile:getBool("visible", self.visible)
	self.disabled = profile:getBool("disabled", self.disabled)
	self.newLayer = profile:getBool("newLayer", self.newLayer)
	self.debugEnabled = profile:getBool("debugEnabled", self.debugEnabled)
	self.updateChildrenState = profile:getBool("updateChildrenState", self.updateChildrenState)
	self.toolTipText = profile:getValue("toolTipText", self.toolTipText)
	self.layoutIgnore = profile:getBool("layoutIgnore", self.layoutIgnore)
	self.thinLineProtection = profile:getBool("thinLineProtection", self.thinLineProtection)
	self.clipping = profile:getBool("clipping", self.clipping)
	self.focusOnHighlight = profile:getBool("focusOnHighlight", self.focusOnHighlight)
	self.focusFallthrough = profile:getBool("focusFallthrough", self.focusFallthrough)
	self.disallowFlowCut = profile:getBool("disallowFlowCut", self.disallowFlowCut)
	self.hotspot = GuiUtils.getNormalizedScreenValues(profile:getValue("hotspot"), self.hotspot)
	self.hasFrame = profile:getBool("hasFrame", self.hasFrame)
	if self.hasFrame then
		self.frameThickness = GuiUtils.getNormalizedScreenValues(profile:getValue("frameThickness"), self.frameThickness)
		local v20_ = self.frameColors or {}
		v20_[GuiElement.FRAME_LEFT] = GuiUtils.getColorArray(profile:getValue("frameLeftColor"), v20_[GuiElement.FRAME_LEFT])
		v20_[GuiElement.FRAME_TOP] = GuiUtils.getColorArray(profile:getValue("frameTopColor"), v20_[GuiElement.FRAME_TOP])
		v20_[GuiElement.FRAME_RIGHT] = GuiUtils.getColorArray(profile:getValue("frameRightColor"), v20_[GuiElement.FRAME_RIGHT])
		v20_[GuiElement.FRAME_BOTTOM] = GuiUtils.getColorArray(profile:getValue("frameBottomColor"), v20_[GuiElement.FRAME_BOTTOM])
		self.frameColors = table.size(v20_) > 0 and v20_ and v20_ or nil
		self.frameOverlayVisible = self.frameOverlayVisible or {
			true,
			true,
			true,
			true
		}
	end
	self.handleFocus = profile:getBool("handleFocus", self.handleFocus)
	self.soundDisabled = profile:getBool("soundDisabled", self.soundDisabled)
	local v21_ = profile:getValue("fadeInTime")
	if v21_ ~= nil then
		local v22_ = tonumber(v21_)
		if v22_ == nil then
			Logging.devWarning("Invalid fadeInTime format for profile \'%s\'", self.profile)
		else
			self.fadeInTime = v22_ * 1000
		end
	end
	local v23_ = profile:getValue("fadeOutTime")
	if v23_ ~= nil then
		local v24_ = tonumber(v23_)
		if v24_ == nil then
			Logging.devWarning("Invalid fadeOutTime format for profile \'%s\'", self.profile)
		else
			self.fadeOutTime = v24_ * 1000
		end
	end
	if applyProfile then
		self:resolveSizeString()
		self:fixThinLines()
		self:updateAbsolutePosition()
	end
end

-- Local values: pro
function GuiElement:applyProfile(profileName, blockSizeUpdate, ignoreSameProfile)
	if profileName and (ignoreSameProfile ~= true or profileName ~= self.profile) then
		local v29_ = g_gui:getProfile(profileName)
		if v29_ ~= nil then
			self.profile = profileName
			self:loadProfile(v29_, not blockSizeUpdate)
		end
	end
end

-- Local values: resolveFunc, sizes, i, str, isXVariable
function GuiElement:resolveSizeString()
	local v31_ = string.split(self.sizeStr, " ")
	local function v38_(p32_, p33_)
		-- upvalues: (copy) self
		local v34_ = p33_ and 1 or 2
		if string.find(p32_, "%%") == nil then
			self.size[v34_] = GuiUtils.getNormalizedValue(p32_, p33_) or self.size[v34_]
		else
			local v35_ = string.gsub(p32_, "%%", "")
			local v36_ = tonumber(v35_)
			if v36_ == nil then
				Logging.warning("GuiElement:resolveSizeString: String %s could not be converted to a number", v36_)
				return false
			end
			local v37_ = v36_ / 100
			if self.parent == nil then
				self.size[v34_] = 1 - (self.absoluteSizeOffset and (self.absoluteSizeOffset[v34_] or 0) or 0)
			else
				self.size[v34_] = v37_ * self.parent.size[v34_] - (self.absoluteSizeOffset and (self.absoluteSizeOffset[v34_] or 0) or 0)
			end
		end
		return true
	end
	for v39_, v40_ in pairs(v31_) do
		if not v38_(v40_, v39_ % 2 == 1) then
			break
		end
	end
	if self.widthStr ~= nil then
		v38_(self.widthStr, true)
	end
	if self.heightStr ~= nil then
		v38_(self.heightStr, false)
	end
	self:updateAnchorDeltas()
end

-- Local values: i
function GuiElement:delete()
	for v42_ = #self.elements, 1, -1 do
		self.elements[v42_].parent = nil
		self.elements[v42_]:delete()
	end
	table.clear(self.elements)
	if self.parent ~= nil then
		self.parent:removeElement(self)
	end
	FocusManager:removeElement(self)
end

-- Local values: ret, i, clonedChild
function GuiElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	local v48_ = self.new()
	if parent ~= nil then
		parent:addElement(v48_)
	end
	v48_:copyAttributes(self)
	for v49_ = 1, #self.elements do
		local v50_ = self.elements[v49_]:clone(v48_, includeId, suppressOnCreate, true)
		if includeId then
			v50_.id = self.elements[v49_].id
		end
	end
	if not blockFocusHandlingReload then
		v48_:reloadFocusHandling(true)
	end
	if not suppressOnCreate then
		v48_:raiseCallback("onCreateCallback", v48_, v48_.onCreateArgs)
	end
	return v48_
end

function GuiElement:copyAttributes(src)
	self.name = src.name
	self.typeName = src.typeName
	self.newLayer = src.newLayer
	self.debugEnabled = src.debugEnabled
	self.visible = src.visible
	self.focused = src.focused
	self.disabled = src.disabled
	self.selected = src.selected
	self.highlighted = src.highlighted
	self.size = table.clone(src.size)
	local v53_
	if src.absoluteSizeOffset then
		v53_ = table.clone(src.absoluteSizeOffset) or nil
	else
		v53_ = nil
	end
	self.absoluteSizeOffset = v53_
	self.margin = table.clone(src.margin)
	self.onCreateCallback = src.onCreateCallback
	self.onCreateArgs = src.onCreateArgs
	self.onCloseCallback = src.onCloseCallback
	self.onOpenCallback = src.onOpenCallback
	self.onDrawCallback = src.onDrawCallback
	self.target = src.target
	self.profile = src.profile
	self.fadeInTime = src.fadeInTime
	self.fadeOutTime = src.fadeOutTime
	self.alpha = src.alpha
	self.fadeDirection = src.fadeDirection
	self.updateChildrenState = src.updateChildrenState
	self.toolTipElementId = src.toolTipElementId
	self.toolTipText = src.toolTipText
	self.handleFocus = src.handleFocus
	self.clipping = src.clipping
	self.focusOnHighlight = src.focusOnHighlight
	self.focusFallthrough = src.focusFallthrough
	self.disallowFlowCut = src.disallowFlowCut
	self.ignoreLayout = src.ignoreLayout
	self.soundDisabled = src.soundDisabled
	self.hasFrame = src.hasFrame
	if self.hasFrame then
		self.frameThickness = table.clone(src.frameThickness)
		local v54_
		if src.frameColors == nil then
			v54_ = nil
		else
			v54_ = table.clone(src.frameColors, math.huge) or nil
		end
		self.frameColors = v54_
		self.frameOverlayVisible = table.clone(src.frameOverlayVisible)
	end
	self.focusId = src.focusId
	self.focusChangeData = table.clone(src.focusChangeData)
	self.isAlwaysFocusedOnOpen = src.isAlwaysFocusedOnOpen
	self.position = table.clone(src.position)
	self.absPosition = table.clone(src.absPosition)
	self.absSize = table.clone(src.absSize)
	self.anchors = table.clone(src.anchors)
	self.anchorDeltas = table.clone(src.anchorDeltas)
	self.pivot = table.clone(src.pivot)
	if src.hotspot ~= nil then
		self.hotspot = table.clone(src.hotspot)
	end
end

-- Local values: _, elem, toolTipElement
function GuiElement:onGuiSetupFinished()
	for _, v56_ in ipairs(self.elements) do
		v56_:onGuiSetupFinished()
	end
	if self.toolTipElementId ~= nil then
		local v57_ = self.target:getDescendantById(self.toolTipElementId)
		if v57_ ~= nil then
			self.toolTipElement = v57_
			return
		end
		Logging.warning("toolTipElementId \'%s\' not found for \'%s\'!", self.toolTipElementId, self.target.name)
	end
end

function GuiElement:toggleFrameSide(sideIndex, isVisible)
	if self.hasFrame then
		self.frameOverlayVisible[sideIndex] = isVisible
	end
end

-- Local values: x, y, width, height, frameLeft, frameRight, frameTop, frameBottom, left, top, right, bottom
function GuiElement:updateFramePosition()
	local v62_ = self.absPosition
	local v63_, v64_ = unpack(v62_)
	local v65_ = self.absSize
	local v66_, v67_ = unpack(v65_)
	local v68_ = g_pixelSizeX
	local v69_ = math.max(v66_, v68_)
	local v70_ = g_pixelSizeY
	local v71_ = math.max(v67_, v70_)
	if self.frameBounds == nil then
		self.frameBounds = {
			{},
			{},
			{},
			{}
		}
	end
	local v72_ = GuiElement.FRAME_LEFT
	local v73_ = GuiElement.FRAME_RIGHT
	local v74_ = GuiElement.FRAME_TOP
	local v75_ = GuiElement.FRAME_BOTTOM
	local v76_ = self.frameBounds[v72_]
	v76_.x = v63_
	v76_.y = v64_
	v76_.width = self.frameThickness[v72_]
	v76_.height = v71_
	local v77_ = self.frameBounds[v74_]
	v77_.x = v63_
	v77_.y = v64_ + v71_ - self.frameThickness[v74_]
	v77_.width = v69_
	v77_.height = self.frameThickness[v74_]
	local v78_ = self.frameBounds[v73_]
	v78_.x = v63_ + v69_ - self.frameThickness[v73_]
	v78_.y = v64_
	v78_.width = self.frameThickness[v73_]
	v78_.height = v71_
	local v79_ = self.frameBounds[v75_]
	v79_.x = v63_
	v79_.y = v64_
	v79_.width = v69_
	v79_.height = self.frameThickness[v75_]
	self:cutFrameBordersHorizontal(self.frameBounds[v72_], self.frameBounds[v74_], true)
	self:cutFrameBordersHorizontal(self.frameBounds[v72_], self.frameBounds[v75_], true)
	self:cutFrameBordersHorizontal(self.frameBounds[v73_], self.frameBounds[v74_], false)
	self:cutFrameBordersHorizontal(self.frameBounds[v73_], self.frameBounds[v75_], false)
	self:cutFrameBordersVertical(self.frameBounds[v75_], self.frameBounds[v72_], true)
	self:cutFrameBordersVertical(self.frameBounds[v75_], self.frameBounds[v73_], true)
	self:cutFrameBordersVertical(self.frameBounds[v74_], self.frameBounds[v72_], false)
	self:cutFrameBordersVertical(self.frameBounds[v74_], self.frameBounds[v73_], false)
end

function GuiElement:cutFrameBordersHorizontal(verticalPart, horizontalPart, isLeft)
	if verticalPart.width > horizontalPart.height then
		if isLeft then
			horizontalPart.x = horizontalPart.x + verticalPart.width
		end
		horizontalPart.width = horizontalPart.width - verticalPart.width
	end
end

function GuiElement:cutFrameBordersVertical(horizontalPart, verticalPart, isBottom)
	if horizontalPart.width >= verticalPart.height then
		if isBottom then
			verticalPart.y = verticalPart.y + horizontalPart.height
		end
		verticalPart.height = verticalPart.height - horizontalPart.height
	end
end

-- Local values: orgMinX, orgMinY, orgMaxX, orgMaxY, parentWidth, parentHeight, anchorPosOriginal_X1, anchorPosOriginal_X2, anchorPosOriginal_Y1, anchorPosOriginal_Y2, posX, posY, i
function GuiElement:updateAnchorDeltas(updateChildren)
	local v88_, v89_, v90_, v91_ = self:getParentOriginalBorders()
	local v92_ = v90_ - v88_
	local v93_ = v91_ - v89_
	local v94_ = v88_ + v92_ * self.anchors[1]
	local v95_ = v88_ + v92_ * self.anchors[2]
	local v96_ = v89_ + v93_ * self.anchors[3]
	local v97_ = v89_ + v93_ * self.anchors[4]
	local v98_ = v88_ + self.pivot[1] * (v92_ - self.size[1]) + self.position[1]
	local v99_ = v89_ + self.pivot[2] * (v93_ - self.size[2]) + self.position[2]
	self.anchorDeltas[1] = -v94_ + v98_
	self.anchorDeltas[2] = -v96_ + v99_
	self.anchorDeltas[3] = -v95_ + (v98_ + self.size[1])
	self.anchorDeltas[4] = -v97_ + (v99_ + self.size[2])
	if updateChildren then
		for v100_ = 1, #self.elements do
			self.elements[v100_]:updateAnchorDeltas()
		end
	end
end

-- Local values: i, v
function GuiElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if eventUsed == nil then
		eventUsed = false
	end
	if self.visible then
		for v108_ = #self.elements, 1, -1 do
			local v109_ = self.elements[v108_]
			if v109_ ~= nil and v109_:mouseEvent(posX, posY, isDown, isUp, button, eventUsed) then
				eventUsed = true
			end
		end
	end
	return eventUsed
end

-- Local values: i, v
function GuiElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if eventUsed == nil then
		eventUsed = false
	end
	if self.visible then
		for v117_ = #self.elements, 1, -1 do
			if self.elements[v117_]:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed) then
				eventUsed = true
			end
		end
	end
	return eventUsed
end

function GuiElement:inputEvent(action, value, eventUsed)
	local v122_
	if eventUsed then
		v122_ = eventUsed
	else
		v122_ = self.parent
		if v122_ then
			v122_ = self.parent:inputEvent(action, value, eventUsed)
		end
		if v122_ == nil then
			v122_ = false
		end
	end
	return v122_
end

function GuiElement:inputReleaseEvent(action, eventUsed)
	local v126_
	if eventUsed then
		v126_ = eventUsed
	else
		v126_ = self.parent
		if v126_ then
			v126_ = self.parent:inputReleaseEvent(action, eventUsed)
		end
		if v126_ == nil then
			v126_ = false
		end
	end
	return v126_
end

-- Local values: i, v
function GuiElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if eventUsed == nil then
		eventUsed = false
	end
	if self.visible then
		for v133_ = #self.elements, 1, -1 do
			if self.elements[v133_]:keyEvent(unicode, sym, modifier, isDown, eventUsed) then
				eventUsed = true
			end
		end
	end
	return eventUsed
end

-- Local values: _, child
function GuiElement:update(dt)
	if self.fadeDirection ~= 0 then
		if self.fadeDirection > 0 then
			self:setAlpha(self.alpha + self.fadeDirection * (dt / self.fadeInTime))
		else
			self:setAlpha(self.alpha + self.fadeDirection * (dt / self.fadeOutTime))
		end
	end
	for _, v136_ in ipairs(self.elements) do
		if v136_:getIsActiveNonRec() then
			v136_:update(dt)
		end
	end
end

-- Local values: xLeft, yTop, xRight, yBottom, i, child, i, frame, color, size, y
function GuiElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self.newLayer then
		new2DLayer()
	end
	local v142_, v143_, v144_, v145_ = self:getClipArea(clipX1, clipY1, clipX2, clipY2)
	self:raiseCallback("onDrawCallback", self)
	if self.debugEnabled or g_uiDebugEnabled then
		if self.hotspot == nil then
			drawFilledRect(self.absPosition[1] - g_pixelSizeX, self.absPosition[2] - g_pixelSizeY, self.absSize[1] + 2 * g_pixelSizeX, g_pixelSizeY, 1, 0, 0, 1)
			drawFilledRect(self.absPosition[1] - g_pixelSizeX, self.absPosition[2] + self.absSize[2], self.absSize[1] + 2 * g_pixelSizeX, g_pixelSizeY, 1, 0, 0, 1)
			drawFilledRect(self.absPosition[1] - g_pixelSizeX, self.absPosition[2], g_pixelSizeX, self.absSize[2], 1, 0, 0, 1)
			drawFilledRect(self.absPosition[1] + self.absSize[1], self.absPosition[2], g_pixelSizeX, self.absSize[2], 1, 0, 0, 1)
		else
			local v146_ = self.absPosition[1] + self.hotspot[1]
			local v147_ = self.absPosition[2] + self.hotspot[2] + self.absSize[2]
			local v148_ = self.absPosition[1] + self.hotspot[3] + self.absSize[1]
			local v149_ = self.absPosition[2] + self.hotspot[4]
			drawLine2D(v146_, v149_, v148_, v149_, 2 * g_pixelSizeX, 1, 0, 1, 1)
			drawLine2D(v146_, v147_, v148_, v147_, 2 * g_pixelSizeX, 1, 0, 1, 1)
			drawLine2D(v146_, v149_, v146_, v147_, 2 * g_pixelSizeX, 1, 0, 1, 1)
			drawLine2D(v148_, v149_, v148_, v147_, 2 * g_pixelSizeX, 1, 0, 1, 1)
		end
	end
	for v150_ = 1, #self.elements do
		local v151_ = self.elements[v150_]
		if v151_:getIsVisibleNonRec() then
			v151_:draw(v151_:getClipArea(v142_, v143_, v144_, v145_))
		end
	end
	if self.hasFrame then
		for v152_ = 1, 4 do
			if self.frameOverlayVisible[v152_] then
				local v153_ = self.frameBounds[v152_]
				local v154_ = self.frameColors ~= nil and self.frameColors[v152_] or GuiElement.FRAME_DEFAULT_COLOR
				drawFilledRect(v153_.x, v153_.y, v153_.width, v153_.height, v154_[1], v154_[2], v154_[3], v154_[4], v142_, v143_, v144_, v145_)
			end
		end
	end
	if g_uiFocusDebugEnabled and (self.focusId ~= nil and self:canReceiveFocus()) then
		setTextColor(1, 0, 0, 1)
		local v155_ = self.absPosition[2] + self.absSize[2]
		local v156_ = renderText
		local v157_ = self.absPosition[1]
		local v158_ = v155_ - 0.008
		local v159_ = self.focusId
		local v160_ = tostring(v159_)
		local v161_ = ClassUtil.getClassNameByObject
		v156_(v157_, v158_, 0.008, " FocusId: " .. v160_ .. " " .. tostring(v161_(self)))
		local v162_ = renderText
		local v163_ = self.absPosition[1]
		local v164_ = v155_ - 0.016
		local v165_ = self.focusChangeData[FocusManager.TOP]
		v162_(v163_, v164_, 0.008, " T: " .. tostring(v165_))
		local v166_ = renderText
		local v167_ = self.absPosition[1]
		local v168_ = v155_ - 0.024
		local v169_ = self.focusChangeData[FocusManager.BOTTOM]
		v166_(v167_, v168_, 0.008, " B: " .. tostring(v169_))
		local v170_ = renderText
		local v171_ = self.absPosition[1]
		local v172_ = v155_ - 0.032
		local v173_ = self.focusChangeData[FocusManager.LEFT]
		v170_(v171_, v172_, 0.008, " L: " .. tostring(v173_))
		local v174_ = renderText
		local v175_ = self.absPosition[1]
		local v176_ = v155_ - 0.04
		local v177_ = self.focusChangeData[FocusManager.RIGHT]
		v174_(v175_, v176_, 0.008, " R: " .. tostring(v177_))
		setTextColor(1, 1, 1, 1)
	end
end

-- Local values: i, child
function GuiElement:onOpen()
	self:raiseCallback("onOpenCallback", self)
	for v179_ = 1, #self.elements do
		self.elements[v179_]:onOpen()
	end
end

-- Local values: i, child
function GuiElement:onClose()
	self:raiseCallback("onCloseCallback", self)
	for v181_ = 1, #self.elements do
		self.elements[v181_]:onClose()
	end
end

-- Local values: _, v
function GuiElement:shouldFocusChange(direction)
	for _, v184_ in ipairs(self.elements) do
		if not v184_:shouldFocusChange(direction) then
			return false
		end
	end
	return true
end

function GuiElement:canReceiveFocus()
	return false
end

-- Local values: i, child
function GuiElement:onFocusLeave()
	self:setFocused(false, true)
	for v186_ = 1, #self.elements do
		self.elements[v186_]:onFocusLeave()
	end
	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText("")
	end
end

-- Local values: i, child
function GuiElement:onFocusEnter()
	self:setFocused(true, true)
	for v188_ = 1, #self.elements do
		self.elements[v188_]:onFocusEnter()
	end
	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText(self.toolTipText)
	end
end

-- Local values: i, child
function GuiElement:onFocusActivate()
	for v190_ = 1, #self.elements do
		local v191_ = self.elements[v190_]
		if v191_.handleFocus then
			v191_:onFocusActivate()
		end
	end
end

-- Local values: i, child
function GuiElement:onHighlight()
	self:setHighlighted(true, true)
	for v193_ = 1, #self.elements do
		self.elements[v193_]:onHighlight()
	end
	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText(self.toolTipText)
	end
	if self.focusOnHighlight then
		FocusManager:setFocus(self)
	end
end

-- Local values: i, child
function GuiElement:onHighlightRemove()
	self:setHighlighted(false, true)
	for v195_ = 1, #self.elements do
		self.elements[v195_]:onHighlightRemove()
	end
	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText("")
	end
end

function GuiElement:getHandleFocus()
	return self.handleFocus
end

function GuiElement:setHandleFocus(handleFocus)
	self.handleFocus = handleFocus
end

function GuiElement:addElement(element)
	if element.parent ~= nil then
		element.parent:removeElement(element)
	end
	local v201_ = self.elements
	table.insert(v201_, element)
	element.parent = self
end

-- Local values: i, child
function GuiElement:removeElement(element)
	for v204_ = 1, #self.elements do
		if self.elements[v204_] == element then
			table.remove(self.elements, v204_)
			element.parent = nil
			return
		end
	end
end

function GuiElement:unlinkElement()
	if self.parent ~= nil then
		self.parent:removeElement(self)
	end
end

-- Local values: minX, minY, maxX, maxY, anchorPos_X1, anchorPos_X2, anchorPos_Y1, anchorPos_Y2, i
function GuiElement:updateAbsolutePosition()
	if #self.anchorDeltas == 0 then
		self:updateAnchorDeltas()
	end
	local v207_, v208_, v209_, v210_ = self:getParentBorders()
	local v211_ = v207_ + (v209_ - v207_) * self.anchors[1]
	local v212_ = v207_ + (v209_ - v207_) * self.anchors[2]
	local v213_ = v208_ + (v210_ - v208_) * self.anchors[3]
	local v214_ = v208_ + (v210_ - v208_) * self.anchors[4]
	self.absPosition[1] = v211_ + self.anchorDeltas[1]
	self.absPosition[2] = v213_ + self.anchorDeltas[2]
	self.absSize[1] = v212_ + self.anchorDeltas[3] - self.absPosition[1]
	self.absSize[2] = v214_ + self.anchorDeltas[4] - self.absPosition[2]
	for v215_ = 1, #self.elements do
		self.elements[v215_]:updateAbsolutePosition()
	end
	if self.hasFrame then
		self:updateFramePosition()
	end
end

-- Local values: i
function GuiElement:reset()
	for v217_ = 1, #self.elements do
		self.elements[v217_]:reset()
	end
end

-- Local values: p
function GuiElement:isChildOf(element)
	if element == self then
		return false
	end
	local v220_ = self.parent
	while v220_ do
		if v220_ == self then
			return false
		end
		if v220_ == element then
			return true
		end
		v220_ = v220_.parent
	end
	return false
end

function GuiElement:getFocusTarget(incomingDirection, moveDirection)
	return self
end

function GuiElement:setPosition(x, y)
	self.position[1] = x or self.position[1]
	self.position[2] = y or self.position[2]
	self:updateAnchorDeltas()
	self:updateAbsolutePosition()
end

function GuiElement:move(dx, dy)
	self.position[1] = self.position[1] + dx
	self.position[2] = self.position[2] + dy
	self:updateAbsolutePosition()
end

-- Local values: xDif, yDif, i, child
function GuiElement:setAbsolutePosition(x, y)
	local v231_ = x or self.absPosition[1]
	local v232_ = y or self.absPosition[2]
	local v233_ = v231_ - self.absPosition[1]
	local v234_ = v232_ - self.absPosition[2]
	self.absPosition[1] = v231_
	self.absPosition[2] = v232_
	for v235_ = 1, #self.elements do
		local v236_ = self.elements[v235_]
		v236_:setAbsolutePosition(v236_.absPosition[1] + v233_, v236_.absPosition[2] + v234_)
	end
	if self.hasFrame then
		self:updateFramePosition()
	end
end

function GuiElement:setSize(x, y, updateChildAnchorDeltas)
	local v241_ = x or self.size[1]
	local v242_ = y or self.size[2]
	if self.thinLineProtection then
		if v241_ ~= 0 then
			local v243_ = g_pixelSizeX
			v241_ = math.max(v241_, v243_)
		end
		if v242_ ~= 0 then
			local v244_ = g_pixelSizeY
			v242_ = math.max(v242_, v244_)
		end
	end
	self.size[1] = v241_
	self.size[2] = v242_
	self:updateAnchorDeltas(updateChildAnchorDeltas)
	self:updateAbsolutePosition()
end

function GuiElement:setVisible(visible)
	self.visible = visible
end

function GuiElement:getIsVisible()
	if self.visible then
		return self.parent == nil and true or self.parent:getIsVisible()
	else
		return false
	end
end

function GuiElement:getIsVisibleNonRec()
	local v249_ = self.visible
	if v249_ then
		v249_ = self.alpha > 0
	end
	return v249_
end

-- Local values: _, child
function GuiElement:setDisabled(disabled, blockDelegate)
	self.disabled = disabled
	if self.updateChildrenState and not blockDelegate then
		for _, v253_ in pairs(self.elements) do
			v253_:setDisabled(disabled)
		end
	end
end

function GuiElement:getIsDisabled()
	return self.disabled
end

-- Local values: _, child
function GuiElement:setSelected(selected, blockDelegate)
	self.selected = selected
	if self.updateChildrenState and not blockDelegate then
		for _, v258_ in pairs(self.elements) do
			v258_:setSelected(selected)
		end
	end
end

function GuiElement:getIsSelected()
	return self.selected
end

-- Local values: _, child
function GuiElement:setFocused(focused, blockDelegate)
	self.focused = focused
	if self.updateChildrenState and not blockDelegate then
		for _, v263_ in pairs(self.elements) do
			v263_:setFocused(focused)
		end
	end
end

function GuiElement:getIsFocused()
	return self.focused
end

-- Local values: _, child
function GuiElement:setHighlighted(highlighted, blockDelegate)
	self.highlighted = highlighted
	if self.updateChildrenState and not blockDelegate then
		for _, v268_ in pairs(self.elements) do
			v268_:setHighlighted(highlighted)
		end
	end
end

function GuiElement:getIsHighlighted()
	return self.highlighted
end

function GuiElement:getOverlayState()
	if self:getIsDisabled() then
		return GuiOverlay.STATE_DISABLED
	elseif self:getIsSelected() then
		return GuiOverlay.STATE_SELECTED
	elseif self:getIsFocused() then
		return GuiOverlay.STATE_FOCUSED
	elseif self:getIsHighlighted() then
		return GuiOverlay.STATE_HIGHLIGHTED
	else
		return GuiOverlay.STATE_NORMAL
	end
end

function GuiElement:fadeIn(factor)
	if self.fadeInTime > 0 then
		self.fadeDirection = 1 * Utils.getNoNil(factor, 1)
		local v273_ = self.alpha
		self:setAlpha((math.max(v273_, 0.0001)))
	else
		self.fadeDirection = 0
		self:setAlpha(1)
	end
end

function GuiElement:fadeOut(factor)
	if self.fadeOutTime > 0 then
		self.fadeDirection = -1 * Utils.getNoNil(factor, 1)
	else
		self.fadeDirection = 0
		self:setAlpha(0)
	end
end

-- Local values: _, childElem
function GuiElement:setAlpha(alpha)
	if alpha ~= self.alpha then
		self.alpha = math.clamp(alpha, 0, 1)
		for _, v278_ in pairs(self.elements) do
			v278_:setAlpha(self.alpha)
		end
		if self.alpha == 1 or self.alpha == 0 then
			self.fadeDirection = 0
		end
	end
end

function GuiElement:getIsActive()
	local v280_ = not self.disabled
	if v280_ then
		v280_ = self:getIsVisible()
	end
	return v280_
end

function GuiElement:getIsActiveNonRec()
	local v282_ = not self.disabled
	if v282_ then
		v282_ = self:getIsVisibleNonRec()
	end
	return v282_
end

function GuiElement:getClipArea(clipX1, clipY1, clipX2, clipY2)
	if self.clipping then
		local v288_ = self.absPosition[1]
		clipX1 = math.max(clipX1 or 0, v288_)
		local v289_ = self.absPosition[2]
		clipY1 = math.max(clipY1 or 0, v289_)
		local v290_ = self.absPosition[1] + self.absSize[1]
		clipX2 = math.min(clipX2 or 1, v290_)
		local v291_ = self.absPosition[2] + self.absSize[2]
		clipY2 = math.min(clipY2 or 1, v291_)
	end
	return clipX1, clipY1, clipX2, clipY2
end

-- Local values: _, child
function GuiElement:setSoundSuppressed(doSuppress)
	self.isSoundSuppressed = doSuppress
	for _, v294_ in pairs(self.elements) do
		v294_:setSoundSuppressed(doSuppress)
	end
end

function GuiElement:getSoundSuppressed()
	return self.isSoundSuppressed
end

-- Local values: _, element
function GuiElement:findDescendantsRec(accumulator, rootElement, predicateFunction)
	if rootElement then
		for _, v300_ in ipairs(rootElement.elements) do
			self:findDescendantsRec(accumulator, v300_, predicateFunction)
			if not predicateFunction or predicateFunction(v300_) then
				table.insert(accumulator, v300_)
			end
		end
	end
end

-- Local values: descendants
function GuiElement:getDescendants(predicateFunction)
	local v303_ = {}
	self:findDescendantsRec(v303_, self, predicateFunction)
	return v303_
end

-- Local values: i
function GuiElement:setTarget(target, originalTarget, callOnCreate)
	for v308_ = 1, #self.elements do
		self.elements[v308_]:setTarget(target, originalTarget, callOnCreate)
	end
	if self.target == originalTarget then
		self.target = target
		if callOnCreate then
			self:raiseCallback("onCreateCallback", self, self.onCreateArgs)
		end
	end
end

-- Local values: element, res
function GuiElement:getFirstDescendant(predicateFunction)
	local v311_ = self:getDescendants(predicateFunction)
	local v312_
	if #v311_ > 0 then
		v312_ = v311_[1]
	else
		v312_ = nil
	end
	return v312_
end

-- Local values: element, findId
function GuiElement:getDescendantById(id)
	local v315_
	if id then
		v315_ = self:getFirstDescendant(function(p316_)
			-- upvalues: (copy) id
			local v317_ = p316_.id
			if v317_ then
				v317_ = p316_.id == id
			end
			return v317_
		end)
	else
		v315_ = nil
	end
	return v315_
end

-- Local values: element, findId
function GuiElement:getDescendantByName(name)
	local v320_
	if name then
		v320_ = self:getFirstDescendant(function(p321_)
			-- upvalues: (copy) name
			local v322_ = p321_.name
			if v322_ then
				v322_ = p321_.name == name
			end
			return v322_
		end)
	else
		v320_ = nil
	end
	return v320_
end

function GuiElement:setAnchor(x, y)
	return self:setAnchors(x, x, y, y)
end

function GuiElement:setAnchors(minX, maxX, minY, maxY)
	self.anchors[1] = minX or self.anchors[1]
	self.anchors[2] = maxX or self.anchors[2]
	self.anchors[3] = minY or self.anchors[3]
	self.anchors[4] = maxY or self.anchors[4]
	self:updateAnchorDeltas()
end

function GuiElement:setPivot(x, y)
	self.pivot[1] = x
	self.pivot[2] = y
	self:updateAnchorDeltas()
end

function GuiElement:fixThinLines()
	if self.thinLineProtection then
		if self.size[1] ~= 0 then
			local v335_ = self.size
			local v336_ = self.size[1]
			local v337_ = g_pixelSizeX
			v335_[1] = math.max(v336_, v337_)
		end
		if self.size[2] ~= 0 then
			local v338_ = self.size
			local v339_ = self.size[2]
			local v340_ = g_pixelSizeY
			v338_[2] = math.max(v339_, v340_)
		end
		self:updateAbsolutePosition()
	end
end

function GuiElement:getParentBorders()
	if self.parent == nil then
		return 0, 0, 1, 1
	else
		return self.parent:getBorders()
	end
end

-- Local values: minX, minY, maxX, maxY
function GuiElement:getBorders()
	return self.absPosition[1], self.absPosition[2], self.absPosition[1] + self.absSize[1], self.absPosition[2] + self.absSize[2]
end

function GuiElement:getParentOriginalBorders()
	if self.parent == nil then
		return 0, 0, 1, 1
	else
		return self.parent:getOriginalBorders()
	end
end

-- Local values: minX, minY, maxX, maxY
function GuiElement:getOriginalBorders()
	return self.position[1], self.position[2], self.position[1] + self.size[1], self.position[2] + self.size[2]
end

-- Local values: x, y
function GuiElement:getCenter()
	return self.absPosition[1] + self.absSize[1] * 0.5, self.absPosition[2] + self.absSize[2] * 0.5
end

function GuiElement:getAspectScale()
	return g_aspectScaleX, g_aspectScaleY
end

-- Local values: callbackName
function GuiElement:addCallback(xmlFile, key, funcName)
	local v350_ = getXMLString(xmlFile, key)
	if v350_ ~= nil then
		if self.target ~= nil then
			self[funcName] = self.target[v350_]
			return
		end
		self[funcName] = ClassUtil.getFunction(v350_)
	end
end

function GuiElement:setCallback(funcName, callbackName)
	if self.target == nil then
		self[funcName] = ClassUtil.getFunction(callbackName)
	else
		self[funcName] = self.target[callbackName]
	end
end
function GuiElement.raiseCallback(p354_, p355_, ...)
	if p354_[p355_] == nil then
		return nil
	elseif p354_.target == nil then
		return p354_[p355_](...)
	else
		return p354_[p355_](p354_.target, ...)
	end
end

-- Local values: len, varName, index, startI
function GuiElement.extractIndexAndNameFromID(elementId)
	local v357_ = elementId:len()
	local v358_ = nil
	if v357_ >= 4 and elementId:sub(v357_, v357_) == "]" then
		local v359_ = elementId:find("[", 1, true)
		if v359_ ~= nil and (v359_ > 1 and v359_ < v357_ - 1) then
			local v360_ = v359_ + 1
			local v361_ = v357_ - 1
			v358_ = tonumber(elementId:sub(v360_, v361_))
			if v358_ ~= nil then
				elementId = elementId:sub(1, v359_ - 1)
			end
		end
	end
	return v358_, elementId
end

-- Local values: id, valid, _, varName
function GuiElement:setId(xmlFile, key)
	local v365_ = getXMLString(xmlFile, key .. "#id")
	if v365_ ~= nil then
		local _, v366_ = GuiElement.extractIndexAndNameFromID(v365_)
		local v367_
		if v366_:find("[^%w_]") == nil then
			v367_ = true
		else
			printError("Error: Invalid gui element id " .. v365_)
			v367_ = false
		end
		if v367_ then
			self.id = v365_
		end
	end
end

function GuiElement:include(guiMixinType)
	guiMixinType.new():addTo(self)
end

function GuiElement:verifyConfiguration() end

-- Local values: e, trash, i
function GuiElement:reloadFocusHandling(reloadIds)
	if reloadIds then
		local function v_u_374_(p372_)
			-- upvalues: (copy) v_u_374_
			p372_.focusId = nil
			for v373_ = 1, #p372_.elements do
				v_u_374_(p372_.elements[v373_])
			end
		end
		self.focusId = nil
		for v375_ = 1, #self.elements do
			v_u_374_(self.elements[v375_])
		end
	end
	FocusManager:loadElementFromCustomValues(self)
end
local function v_u_380_(p376_, p377_)
	-- upvalues: (copy) v_u_380_
	if not p376_.focusFallthrough and (p376_:getIsVisibleNonRec() and (not p377_ or p376_:canReceiveFocus())) then
		return p376_
	end
	for v378_ = 1, #p376_.elements do
		if p376_.elements[v378_]:getIsVisibleNonRec() then
			local v379_ = v_u_380_(p376_.elements[v378_], p377_)
			if v379_ ~= nil then
				return v379_
			end
		end
	end
	return nil
end

-- Upvalues: findFirstFocusableSearch
-- Local values: element
function GuiElement:findFirstFocusable(checkReceiveFocus)
	-- upvalues: (copy) v_u_380_
	local v383_ = v_u_380_(self, checkReceiveFocus)
	if v383_ == nil then
		v383_ = self
	end
	return v383_
end
local function v_u_388_(p384_, p385_)
	-- upvalues: (copy) v_u_388_
	if not p384_.focusFallthrough and (p384_:getIsVisibleNonRec() and (not p385_ or p384_:canReceiveFocus())) then
		return p384_
	end
	for v386_ = #p384_.elements, 1, -1 do
		if p384_.elements[v386_]:getIsVisibleNonRec() then
			local v387_ = v_u_388_(p384_.elements[v386_], p385_)
			if v387_ ~= nil then
				return v387_
			end
		end
	end
	return nil
end

-- Upvalues: findLastFocusableSearch
-- Local values: element
function GuiElement:findLastFocusable(checkReceiveFocus)
	-- upvalues: (copy) v_u_388_
	local v391_ = v_u_388_(self, checkReceiveFocus)
	if v391_ == nil then
		v391_ = self
	end
	return v391_
end

function GuiElement:toString()
	local v393_ = string.format
	local v394_ = self.id
	local v395_ = tostring(v394_)
	local v396_ = self.focusId
	local v397_ = tostring(v396_)
	local v398_ = self.profile
	return v393_("[ID: %s, FocusID: %s, GuiProfile: %s, Position: %g, %g]", v395_, v397_, tostring(v398_), self.absPosition[1], self.absPosition[2])
end
