-- Local values: ListItemElement_mt
ListItemElement = {}
local ListItemElement_mt = Class(ListItemElement, BitmapElement)
Gui.registerGuiElement("ListItem", ListItemElement)

-- Upvalues: ListItemElement_mt
-- Local values: self
function ListItemElement.new(target, custom_mt)
	-- upvalues: (copy) ListItemElement_mt
	local v4_ = BitmapElement.new(target, custom_mt or ListItemElement_mt)
	v4_.mouseEntered = false
	v4_.allowSelected = true
	v4_.autoSelectChildren = false
	v4_.handleFocus = false
	v4_.hideSelection = false
	v4_.alternateChildren = false
	v4_.alternateBackgroundColor = nil
	v4_.attributes = {}
	return v4_
end

function ListItemElement:loadFromXML(xmlFile, key)
	ListItemElement:superClass().loadFromXML(self, xmlFile, key)
	self.allowSelected = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSelected"), self.allowSelected)
	self.autoSelectChildren = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoSelectChildren"), self.autoSelectChildren)
	self.alternateChildren = Utils.getNoNil(getXMLBool(xmlFile, key .. "#alternateChildren"), self.alternateChildren)
	self.hideSelection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideSelection"), self.hideSelection)
	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
end

function ListItemElement:loadProfile(profile, applyProfile)
	ListItemElement:superClass().loadProfile(self, profile, applyProfile)
	self.allowSelected = profile:getBool("allowSelected", self.allowSelected)
	self.autoSelectChildren = profile:getBool("autoSelectChildren", self.autoSelectChildren)
	self.alternateChildren = profile:getBool("alternateChildren", self.alternateChildren)
	self.hideSelection = profile:getBool("hideSelection", self.hideSelection)
	if not self.alternateBackgroundLoaded then
		self.backgroundColor = table.clone(GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL))
		self.alternateBackgroundColor = GuiUtils.getColorArray(profile:getValue("alternateBackgroundColor"))
		self.alternateBackgroundLoaded = true
	end
end

function ListItemElement:copyAttributes(src)
	ListItemElement:superClass().copyAttributes(self, src)
	self.allowSelected = src.allowSelected
	self.isSectionHeader = src.isSectionHeader
	self.autoSelectChildren = src.autoSelectChildren
	self.hideSelection = src.hideSelection
	self.backgroundColor = src.backgroundColor
	self.alternateChildren = src.alternateChildren
	self.alternateBackgroundColor = src.alternateBackgroundColor
	self.alternateBackgroundLoaded = src.alternateBackgroundLoaded
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback
	self.onClickCallback = src.onClickCallback
end

function ListItemElement:onClose()
	ListItemElement:superClass().onClose(self)
	self:reset()
end

-- Local values: clone
function ListItemElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	local v19_ = ListItemElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
	v19_:findAllAttributes()
	return v19_
end

function ListItemElement:setSelected(selected)
	local v22_ = ListItemElement:superClass().setSelected
	local v23_ = selected and not self.hideSelection
	if v23_ then
		v23_ = self.allowSelected
	end
	v22_(self, v23_)
end

function ListItemElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsVisible() then
		eventUsed = ListItemElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
		if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot) then
			if self.mouseEntered then
				self.mouseEntered = false
				if self.handleFocus then
					self:raiseCallback("onLeaveCallback", self)
				end
			end
			self.mouseDown = false
			if self.handleFocus and self:getIsHighlighted() then
				FocusManager:unsetHighlight(self)
			end
		else
			if not (isDown or isUp) then
				if self.handleFocus then
					FocusManager:setHighlight(self)
				end
				if not self.mouseEntered then
					self.mouseEntered = true
					if self.handleFocus then
						self:raiseCallback("onFocusCallback", self)
					end
				end
			end
			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				self.mouseDown = true
				eventUsed = self:raiseCallback("onClickCallback", self)
			end
			if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.mouseDown) then
				self.mouseDown = false
				return eventUsed
			end
		end
	end
	return eventUsed
end

function ListItemElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsVisible() then
		eventUsed = ListItemElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) and true or eventUsed
		if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot) then
			if self.touchEntered then
				self.touchEntered = false
				if self.handleFocus then
					self:raiseCallback("onLeaveCallback", self)
				end
			end
			self.touchDown = false
			if self.handleFocus and self:getIsHighlighted() then
				FocusManager:unsetHighlight(self)
			end
		else
			if not (isDown or isUp) then
				if self.handleFocus then
					FocusManager:setHighlight(self)
				end
				if not self.touchEntered then
					self.touchEntered = true
					if self.handleFocus then
						self:raiseCallback("onFocusCallback", self)
					end
				end
			end
			if isDown then
				self.touchDown = true
				eventUsed = self:raiseCallback("onClickCallback", self)
			end
			if isUp and self.touchDown then
				self.touchDown = false
				return eventUsed
			end
		end
	end
	return eventUsed
end

function ListItemElement:onGuiSetupFinished()
	ListItemElement:superClass().onGuiSetupFinished(self)
	self:findAllAttributes()
end

function ListItemElement:getFocusTarget(incomingDirection, moveDirection)
	if self.autoSelectChildren then
		return ListItemElement:superClass().getFocusTarget(self, incomingDirection, moveDirection)
	else
		return self
	end
end

-- Local values: search
function ListItemElement:findAllAttributes()
	local function v_u_47_(p43_)
		-- upvalues: (copy) self, (copy) v_u_47_
		for v44_ = 1, #p43_ do
			local v45_ = p43_[v44_]
			local v46_ = p43_[v44_].name
			if v46_ ~= nil then
				self.attributes[v46_] = v45_
			end
			v_u_47_(v45_.elements)
		end
	end
	v_u_47_(self.elements)
end

function ListItemElement:getAttribute(name)
	return self.attributes[name]
end

-- Local values: alternatingChild
function ListItemElement:setAlternating(isAlternate)
	if self.alternateBackgroundColor == nil then
		return
	elseif self.alternateChildren then
		local v52_ = self:getAttribute("alternating")
		if v52_ ~= nil then
			if isAlternate then
				local v53_ = GuiOverlay.STATE_NORMAL
				local v54_ = self.alternateBackgroundColor
				v52_:setImageColor(v53_, unpack(v54_))
				return
			end
			local v55_ = GuiOverlay.STATE_NORMAL
			local v56_ = self.backgroundColor
			v52_:setImageColor(v55_, unpack(v56_))
		end
		return
	elseif isAlternate then
		local v57_ = GuiOverlay.STATE_NORMAL
		local v58_ = self.alternateBackgroundColor
		self:setImageColor(v57_, unpack(v58_))
	else
		local v59_ = GuiOverlay.STATE_NORMAL
		local v60_ = self.backgroundColor
		self:setImageColor(v59_, unpack(v60_))
	end
end
