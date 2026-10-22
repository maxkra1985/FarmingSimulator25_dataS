ConstructionBrushVineOrchard = {}
local ConstructionBrushVineOrchard_mt = Class(ConstructionBrushVineOrchard, ConstructionBrushFence)
ConstructionBrushVineOrchard.DEFAULT_ROW_SPACING = 3
ConstructionBrushVineOrchard.CURSOR_SIZE = 0.3
function ConstructionBrushVineOrchard.new(subclass_mt, cursor)
	local self = ConstructionBrushVineOrchard:superClass().new(subclass_mt or ConstructionBrushVineOrchard_mt, cursor)
	self.supportsFourthButton = true
	self.isFenceMode = false
	self.boundaryEditor = OrchardBoundaryEditor.new(self)
	return self
end
function ConstructionBrushVineOrchard:delete()
	ConstructionBrushVineOrchard:superClass().delete(self)
	self.boundaryEditor:delete()
end
function ConstructionBrushVineOrchard:activate()
	ConstructionBrushVineOrchard:superClass().activate(self)
	self.isFenceMode = false
	self.boundaryEditor:activate()
end
function ConstructionBrushVineOrchard:deactivate()
	self.boundaryEditor:deactivate()
	ConstructionBrushVineOrchard:superClass().deactivate(self)
end
function ConstructionBrushVineOrchard:releasePlaceable()
	if not self.boundaryEditor:getIsBuilding() then
		ConstructionBrushVineOrchard:superClass().releasePlaceable(self)
	else
		self:removePreview()
		self.fence = nil
		self:setInputTextDirty()
	end
end
function ConstructionBrushVineOrchard:canCancel()
	if self.isFenceMode then
		return ConstructionBrushVineOrchard:superClass().canCancel(self)
	else
		return self.boundaryEditor:getCanCancel()
	end
end
function ConstructionBrushVineOrchard:toggleFenceMode()
	if not self.boundaryEditor:getIsBusy() and self.fence ~= nil then
		self.isFenceMode = not self.isFenceMode
		self.boundaryEditor:resetBoundary()
		self.boundaryEditor:clearVisualization()
		self:removePreview()
		self.parallelSnappingSegment = nil
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
		self.cursor:setShapeSize(ConstructionBrushVineOrchard.CURSOR_SIZE)
		self:setInputTextDirty()
	end
end
function ConstructionBrushVineOrchard:removePreview()
	if self.fence ~= nil and self.fence:getPreviewSegment() ~= nil then
		self.fence:setPreviewSegment(nil)
	end
	self.attachmentPointSegment = nil
	self.attachmentPointSegmentReversed = nil
	if self.previewPole ~= nil then
		delete(self.previewPole)
		self.previewPole = nil
	end
	self:resetErrorOverlays()
end
function ConstructionBrushVineOrchard:getOrchardBuildPlaceable()
	return self.fence
end
function ConstructionBrushVineOrchard:getOrchardBuildTemplateId()
	return nil
end
function ConstructionBrushVineOrchard:getOrchardRowSpacing()
	local spacing = self.fence:getSnapDistance()
	if spacing == nil or spacing <= 0 then
		spacing = ConstructionBrushVineOrchard.DEFAULT_ROW_SPACING
	end
	return spacing
end
function ConstructionBrushVineOrchard:getOrchardPanelLength()
	return self.fence:getPanelLength()
end
function ConstructionBrushVineOrchard:getOrchardPricePerMeter()
	return self.storeItem.price
end
function ConstructionBrushVineOrchard:update(dt)
	if self.isFenceMode then
		self.boundaryEditor:updateInactive()
		ConstructionBrushVineOrchard:superClass().update(self, dt)
	else
		if self.doFindPlaceable then
			self.fence = self:findPlaceable()
			self:setInputTextDirty()
			if self.fence ~= nil then
				if self.fence:getHasParallelSnapping() then
					self.parallelSnappingEnabled = true
				end
				self.doFindPlaceable = false
			end
		end
		self.boundaryEditor:update(dt)
	end
end
function ConstructionBrushVineOrchard:onButtonPrimary()
	if self.boundaryEditor:getIsBuilding() then
		return
	elseif self.isFenceMode then
		ConstructionBrushVineOrchard:superClass().onButtonPrimary(self)
	else
		self.boundaryEditor:onButtonPrimary()
	end
end
function ConstructionBrushVineOrchard:onButtonSecondary()
	if self.boundaryEditor:getIsBuilding() then
		return
	elseif self.isFenceMode then
		ConstructionBrushVineOrchard:superClass().onButtonSecondary(self)
	else
		self.boundaryEditor:onButtonSecondary()
	end
end
function ConstructionBrushVineOrchard:onButtonTertiary()
	if self.boundaryEditor:getIsBuilding() then
		return
	elseif self.isFenceMode then
		ConstructionBrushVineOrchard:superClass().onButtonTertiary(self)
	else
		self.boundaryEditor:onButtonTertiary()
	end
end
function ConstructionBrushVineOrchard:onButtonFourth()
	self:toggleFenceMode()
end
function ConstructionBrushVineOrchard:cancel()
	if self.isFenceMode then
		ConstructionBrushVineOrchard:superClass().cancel(self)
	else
		self.boundaryEditor:cancel()
	end
end
function ConstructionBrushVineOrchard:getButtonPrimaryText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return ConstructionBrushVineOrchard:superClass().getButtonPrimaryText(self)
	else
		return self.boundaryEditor:getButtonPrimaryText()
	end
end
function ConstructionBrushVineOrchard:getButtonSecondaryText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return ConstructionBrushVineOrchard:superClass().getButtonSecondaryText(self)
	else
		return self.boundaryEditor:getButtonSecondaryText()
	end
end
function ConstructionBrushVineOrchard:getButtonTertiaryText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return ConstructionBrushVineOrchard:superClass().getButtonTertiaryText(self)
	else
		return self.boundaryEditor:getButtonTertiaryText()
	end
end
function ConstructionBrushVineOrchard:getButtonFourthText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return g_i18n:getText("action_orchardBrushSwitchToLayout")
	else
		return g_i18n:getText("action_orchardBrushSwitchToFence")
	end
end
