ConstructionBrushOrchard = {}
local ConstructionBrushOrchard_mt = Class(ConstructionBrushOrchard, ConstructionBrushNewFence)
ConstructionBrushOrchard.DEFAULT_ROW_SPACING = 5
function ConstructionBrushOrchard.new(subclass_mt, cursor)
	local self = ConstructionBrushOrchard:superClass().new(subclass_mt or ConstructionBrushOrchard_mt, cursor)
	self.isFenceMode = false
	self.boundaryEditor = OrchardBoundaryEditor.new(self)
	return self
end
function ConstructionBrushOrchard:delete()
	ConstructionBrushOrchard:superClass().delete(self)
	self.boundaryEditor:delete()
end
function ConstructionBrushOrchard:activate()
	ConstructionBrushOrchard:superClass().activate(self)
	self.isFenceMode = false
	self.boundaryEditor:activate()
end
function ConstructionBrushOrchard:deactivate()
	self.boundaryEditor:deactivate()
	ConstructionBrushOrchard:superClass().deactivate(self)
end
function ConstructionBrushOrchard:initFence()
	ConstructionBrushOrchard:superClass().initFence(self)
	if self.currentSegment ~= nil then
		self.currentSegment:delete()
		self.currentSegment = nil
	end
end
function ConstructionBrushOrchard:releasePlaceable()
	if self.boundaryEditor:getIsBuilding() then
		self.fenceParentObject = nil
		self.fence = nil
		self:setInputTextDirty()
	else
		ConstructionBrushOrchard:superClass().releasePlaceable(self)
	end
end
function ConstructionBrushOrchard:canCancel()
	if self.isFenceMode then
		return ConstructionBrushOrchard:superClass().canCancel(self)
	else
		return self.boundaryEditor:getCanCancel()
	end
end
function ConstructionBrushOrchard:toggleFenceMode()
	if self.boundaryEditor:getIsBusy() or self.fence == nil then
		return
	end
	self.isFenceMode = not self.isFenceMode
	self.boundaryEditor:resetBoundary()
	self.boundaryEditor:clearVisualization()
	if self.currentSegment ~= nil then
		self.currentSegment:delete()
		self.currentSegment = nil
	end
	self.parallelSnappingSegment = nil
	self:setInputTextDirty()
end
function ConstructionBrushOrchard:getOrchardBuildPlaceable()
	if self.fence == nil or self.templateId == nil then
		return nil
	end
	return self.fenceParentObject
end
function ConstructionBrushOrchard:getOrchardBuildTemplateId()
	return self.templateId
end
function ConstructionBrushOrchard:getOrchardRowSpacing()
	local spacing = nil
	local metadata = self.fence:getSegmentTemplateById(self.templateId)
	if metadata ~= nil then
		if metadata.parallelSnapping ~= nil then
			spacing = metadata.parallelSnapping.snapDistance
		end
		if spacing == nil then
			spacing = metadata.boundingCheckWidth or metadata.maxWidth
		end
	end
	if spacing == nil or spacing <= 0 then
		spacing = ConstructionBrushOrchard.DEFAULT_ROW_SPACING
	end
	return spacing
end
function ConstructionBrushOrchard:getOrchardPanelLength()
	local metadata = self.fence:getSegmentTemplateById(self.templateId)
	if metadata == nil or metadata.panels == nil or #metadata.panels == 0 then
		return nil
	end
	return metadata.panels[#metadata.panels].length
end
function ConstructionBrushOrchard:getOrchardPricePerMeter()
	return self.storeItem.price
end
function ConstructionBrushOrchard:update(dt)
	if self.isFenceMode then
		self.boundaryEditor:updateInactive()
		ConstructionBrushOrchard:superClass().update(self, dt)
	else
		if self.doFindPlaceable then
			self.fenceParentObject = self:findPlaceable()
			self:setInputTextDirty()
			if self.fenceParentObject ~= nil then
				self:initFence()
				self.doFindPlaceable = false
			end
		end
		self.boundaryEditor:update(dt)
	end
end
function ConstructionBrushOrchard:onButtonPrimary()
	if self.boundaryEditor:getIsBuilding() then
		return
	elseif self.isFenceMode then
		ConstructionBrushOrchard:superClass().onButtonPrimary(self)
	else
		self.boundaryEditor:onButtonPrimary()
	end
end
function ConstructionBrushOrchard:onButtonSecondary()
	if self.boundaryEditor:getIsBuilding() then
		return
	elseif self.isFenceMode then
		ConstructionBrushOrchard:superClass().onButtonSecondary(self)
	else
		self.boundaryEditor:onButtonSecondary()
	end
end
function ConstructionBrushOrchard:onButtonTertiary()
	if self.boundaryEditor:getIsBuilding() then
		return
	elseif self.isFenceMode then
		ConstructionBrushOrchard:superClass().onButtonTertiary(self)
	else
		self.boundaryEditor:onButtonTertiary()
	end
end
function ConstructionBrushOrchard:onButtonFourth()
	self:toggleFenceMode()
end
function ConstructionBrushOrchard:onAxisPrimary(inputValue)
	if not self.isFenceMode then
		return
	else
		ConstructionBrushOrchard:superClass().onAxisPrimary(self, inputValue)
	end
end
function ConstructionBrushOrchard:onAxisSecondary(inputValue)
	if not self.isFenceMode then
		return
	else
		ConstructionBrushOrchard:superClass().onAxisSecondary(self, inputValue)
	end
end
function ConstructionBrushOrchard:cancel()
	if self.isFenceMode then
		ConstructionBrushOrchard:superClass().cancel(self)
	else
		self.boundaryEditor:cancel()
	end
end
function ConstructionBrushOrchard:getButtonPrimaryText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return ConstructionBrushOrchard:superClass().getButtonPrimaryText(self)
	else
		return self.boundaryEditor:getButtonPrimaryText()
	end
end
function ConstructionBrushOrchard:getButtonSecondaryText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return ConstructionBrushOrchard:superClass().getButtonSecondaryText(self)
	else
		return self.boundaryEditor:getButtonSecondaryText()
	end
end
function ConstructionBrushOrchard:getButtonTertiaryText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return ConstructionBrushOrchard:superClass().getButtonTertiaryText(self)
	else
		return self.boundaryEditor:getButtonTertiaryText()
	end
end
function ConstructionBrushOrchard:getButtonFourthText()
	if self.fence == nil then
		return nil
	elseif self.isFenceMode then
		return g_i18n:getText("action_orchardBrushSwitchToLayout")
	else
		return g_i18n:getText("action_orchardBrushSwitchToFence")
	end
end
function ConstructionBrushOrchard:getAxisPrimaryText()
	if not self.isFenceMode then
		return nil
	else
		return ConstructionBrushOrchard:superClass().getAxisPrimaryText(self)
	end
end
function ConstructionBrushOrchard:getAxisSecondaryText()
	if not self.isFenceMode then
		return nil
	else
		return ConstructionBrushOrchard:superClass().getAxisSecondaryText(self)
	end
end
