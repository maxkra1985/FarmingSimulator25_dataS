-- Local values: ConstructionBrushSelect_mt
ConstructionBrushSelect = {}
local ConstructionBrushSelect_mt = Class(ConstructionBrushSelect, ConstructionBrush)
ConstructionBrushSelect.OVERLAY_COLOR = { 0.2, 0.4, 1 }

-- Upvalues: ConstructionBrushSelect_mt
-- Local values: self
function ConstructionBrushSelect.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushSelect_mt
	local v4_ = ConstructionBrushSelect:superClass().new(subclass_mt or ConstructionBrushSelect_mt, cursor)
	v4_.isSelector = true
	v4_.supportsPrimaryButton = true
	v4_.supportsTertiaryButton = true
	return v4_
end

function ConstructionBrushSelect:delete()
	ConstructionBrushSelect:superClass().delete(self)
end

function ConstructionBrushSelect:activate()
	ConstructionBrushSelect:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
	self.cursor:setSelectionMode(true)
	g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
end

function ConstructionBrushSelect:deactivate()
	if self.lastPlaceable ~= nil then
		if self.lastPlaceable.rootNode ~= nil and entityExists(self.lastPlaceable.rootNode) then
			self.lastPlaceable:setOverlayColor(0.2, 0.4, 1, 0)
		end
		self.lastPlaceable = nil
		self:setInputTextDirty()
	end
	self.pauseUpdates = false
	self.cursor:setSelectionMode(false)
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushSelect:superClass().deactivate(self)
end

function ConstructionBrushSelect:update(dt)
	ConstructionBrushSelect:superClass().update(self, dt)
	if self.lastPlaceable ~= nil and self.lastPlaceable.isDeleted then
		self.lastPlaceable = nil
		self.pauseUpdates = false
		self:setInputTextDirty()
	end
	if not self.pauseUpdates then
		self:visualizeMouseOver()
	end
end

-- Local values: storeItemNameCleaned
function ConstructionBrushSelect:draw()
	if g_isDevelopmentVersion and (self.lastPlaceable ~= nil and self.lastPlaceable.configFileName ~= nil) then
		local v11_ = string.gsub(self.lastPlaceable.configFileName, getUserProfileAppPath(), "")
		renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, v11_)
	end
end

-- Local values: placeable, color
function ConstructionBrushSelect:visualizeMouseOver()
	local v13_ = self.cursor:getHitPlaceable()
	if v13_ ~= self.lastPlaceable then
		if self.lastPlaceable ~= nil then
			if self.lastPlaceable.rootNode ~= nil then
				self.lastPlaceable:setOverlayColor(1, 1, 1, 0)
			end
			self.lastPlaceable = nil
			self:setInputTextDirty()
		end
		if v13_ ~= nil and v13_:getDestructionMethod() ~= Placeable.DESTRUCTION.PER_NODE then
			local v14_ = ConstructionBrushSelect.OVERLAY_COLOR
			v13_:setOverlayColor(v14_[1], v14_[2], v14_[3], 0.8)
			self.lastPlaceable = v13_
			self:setInputTextDirty()
		end
	end
end

-- Local values: callback
function ConstructionBrushSelect:onButtonPrimary()
	if self.lastPlaceable == nil or self.lastPlaceable.isDeleted then
		self.lastPlaceable = nil
		self.pauseUpdates = false
		self:setInputTextDirty()
	else
		self.pauseUpdates = true
		PlaceableInfoDialog.show(function(p16_)
			-- upvalues: (copy) self
			if p16_ then
				self.lastPlaceable = nil
				self:setInputTextDirty()
			end
			self.pauseUpdates = false
		end, self.lastPlaceable)
	end
end

function ConstructionBrushSelect:onButtonTertiary(constructionScreen)
	constructionScreen:onClickDestruct()
end

function ConstructionBrushSelect:onPlaceableDestroyed(state, sellPrice)
	if self.lastPlaceable ~= nil then
		self.lastPlaceable = nil
		self.pauseUpdates = false
		self:setInputTextDirty()
	end
end

function ConstructionBrushSelect:getButtonPrimaryText()
	return self.lastPlaceable ~= nil and "$l10n_button_select" or nil
end

function ConstructionBrushSelect:getButtonTertiaryText()
	return "$l10n_ui_demolitionModeEnter"
end
