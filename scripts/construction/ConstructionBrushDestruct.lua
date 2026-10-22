ConstructionBrushDestruct = {}
local ConstructionBrushDestruct_mt = Class(ConstructionBrushDestruct, ConstructionBrush)
ConstructionBrushDestruct.OVERLAY_COLOR = { 1, 0.1, 0.1 }
ConstructionBrushDestruct.SELL_UNDO_TIMEOUT = 900000
function ConstructionBrushDestruct.new(subclass_mt, cursor)
	local self = ConstructionBrushDestruct:superClass().new(subclass_mt or ConstructionBrushDestruct_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.supportsTertiaryButton = true
	self.requiredPermission = Farm.PERMISSION.SELL_PLACEABLE
	self.deleteWholeSegment = true
	return self
end
function ConstructionBrushDestruct:delete()
	ConstructionBrushDestruct:superClass().delete(self)
end
function ConstructionBrushDestruct:activate()
	ConstructionBrushDestruct:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
	self.cursor:setSelectionMode(true)
	self.coloredNodes = {}
	self.destructionPreviewNodes = {}
	self.hoveredDeletableFence = nil
end
function ConstructionBrushDestruct:deactivate()
	self.cursor:setSelectionMode(false)
	self:resetPlaceableSelection()
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushDestruct:superClass().deactivate(self)
end
function ConstructionBrushDestruct:update(dt)
	ConstructionBrushDestruct:superClass().update(self, dt)
	if not self:hasPlayerPermission() then
		self.cursor:setErrorMessage(g_i18n:getText("shop_messageNoPermissionGeneral"))
	else
		self:visualizeMouseOver()
	end
end
function ConstructionBrushDestruct:draw()
	if g_isDevelopmentVersion and (self.lastPlaceable ~= nil and self.lastPlaceable.configFileName ~= nil) then
		local storeItemNameCleaned = string.gsub(self.lastPlaceable.configFileName, getUserProfileAppPath(), "")
		renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
	end
end
function ConstructionBrushDestruct:resetColoredNodes()
	for i = #self.coloredNodes, 1, -1 do
		local node = self.coloredNodes[i]
		if entityExists(node) then
			setShaderParameter(node, "placeableColorScale", 1, 1, 1, 0, false)
		end
		self.coloredNodes[i] = nil
	end
end
function ConstructionBrushDestruct:visualizeMouseOver()
	table.clear(self.destructionPreviewNodes)
	local placeable = self.cursor:getHitPlaceable()
	if placeable ~= self.lastPlaceable or self.perNodeMode then
		self:resetPlaceableSelection()
		self:setHoveredDeletableFence(nil)
		if placeable ~= nil and g_localPlayer.farmId == placeable.ownerFarmId then
			self.lastPlaceable = placeable
			g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
			local color = ConstructionBrushDestruct.OVERLAY_COLOR
			local r = color[1]
			local g = color[2]
			local b = color[3]
			local a = 0.8
			if placeable:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
				self:resetColoredNodes()
				local cursorHitNode = self.cursor:getHitNode()
				local nodes = placeable:previewNodeDestructionNodes(cursorHitNode, self.destructionPreviewNodes)
				if nodes ~= nil then
					for _, node in ipairs(nodes) do
						if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
							setShaderParameter(node, "placeableColorScale", r, g, b, 0.8, false)
							table.insert(self.coloredNodes, node)
						end
					end
					if #self.coloredNodes == 0 then
						for _, node in ipairs(nodes) do
							DebugShapeOutline.render(node, true, true)
						end
					end
				end
				self.perNodeMode = true
			else
				placeable:setOverlayColor(r, g, b, 0.8)
				self.perNodeMode = false
			end
		end
		return
	end
	local hoveredFence = self:visualizeFenceMouseOver(self.cursor:getHitNode())
	self:setHoveredDeletableFence(hoveredFence)
end
function ConstructionBrushDestruct:visualizeFenceMouseOver(hitNode)
	local segment = self:getDeletableFenceSegment(hitNode)
	if segment == nil then
		return nil
	end
	if self.deleteWholeSegment then
		DebugShapeOutline.render(segment.root, true, true)
		return segment.fence
	end
	local panelNode = segment:getDeletablePanelFromNode(hitNode)
	if panelNode == nil then
		return nil
	else
		DebugShapeOutline.render(panelNode, true, true)
		local hitPart = segment:getSegmentPartFromNode(hitNode)
		if hitPart ~= nil and hitPart ~= panelNode then
			DebugShapeOutline.render(hitPart, true, true)
		end
		return segment.fence
	end
end
function ConstructionBrushDestruct:getDeletableFenceSegment(hitNode)
	local object = self.cursor:getHitObject()
	if object == nil or not object:isa(Fence) then
		return nil
	end
	if object.getAllowSegmentDeletion ~= nil and not object:getAllowSegmentDeletion() then
		return nil
	end
	local segment = object:getSegmentFromNode(hitNode)
	if segment == nil or not segment:getCanBeModifiedByFarmId(g_localPlayer.farmId) or not segment:getCanBeDeleted() then
		return nil
	end
	return segment
end
function ConstructionBrushDestruct:setHoveredDeletableFence(fence)
	if fence ~= self.hoveredDeletableFence then
		self.hoveredDeletableFence = fence
		self:setInputTextDirty()
	end
end
function ConstructionBrushDestruct:onButtonPrimary(isDown, isDrag, isUp)
	if isUp then
		self.lastDragPlaceable = nil
		return
	end
	if not self:hasPlayerPermission() then
		return
	end
	local placeable = self.cursor:getHitPlaceable()
	if placeable ~= nil and (g_localPlayer.farmId == placeable.ownerFarmId and (self.lastDragPlaceable == nil or placeable == self.lastDragPlaceable)) then
		if placeable:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
			if isDown then
				self.lastDragPlaceable = placeable
			end
			if placeable.getConfirmDestruction ~= nil and placeable:getConfirmDestruction() then
				local callbackFunc = function(yes)
					if yes then
						self:destroyNodeInPlaceable(placeable)
					end
				end
				YesNoDialog.show(callbackFunc, nil, g_i18n:getText("ui_constructionDeleteConfirmationRiceField"), nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
				return
			end
			self:destroyNodeInPlaceable(placeable)
			return
		elseif isDown then
			local canBeSold, warning = placeable:canBeSold()
			local price, forFullPrice = placeable:getSellPrice()
			local callbackFunc = function(yes)
				if yes then
					g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable, false, forFullPrice))
				end
			end
			if warning ~= nil then
				if canBeSold then
					YesNoDialog.show(callbackFunc, nil, warning, nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
					return
				else
					InfoDialog.show(warning, nil, nil, nil, g_i18n:getText("button_back"), InputAction.MENU_BACK)
					return
				end
			end
			local text = string.format(g_i18n:getText("ui_constructionSellConfirmation"), placeable:getName(), g_i18n:formatMoney(price, 0, true, true))
			YesNoDialog.show(callbackFunc, nil, text)
			return
		end
	end
	if self:getAllowFenceDeletionInput(isDown, isDrag) then
		self:requestFenceDeletion(self.deleteWholeSegment)
	end
end
function ConstructionBrushDestruct:onButtonTertiary()
	self.deleteWholeSegment = not self.deleteWholeSegment
	self:setInputTextDirty()
end
function ConstructionBrushDestruct:getAllowFenceDeletionInput(isDown, isDrag)
	if isDown then
		return true
	else
		return isDrag and not self.deleteWholeSegment
	end
end
function ConstructionBrushDestruct:requestFenceDeletion(wholeSegment)
	if not self:hasPlayerPermission() then
		return
	end
	if self.awaitingFenceSegmentDeletion then
		return
	end
	local hitNode = self.cursor:getHitNode()
	local segment = self:getDeletableFenceSegment(hitNode)
	if segment == nil then
		return
	end
	local partNode = nil
	local childIndex = nil
	if wholeSegment then
		partNode, childIndex = segment:getSegmentPartFromNode(hitNode)
	else
		partNode, childIndex = segment:getDeletablePanelFromNode(hitNode)
	end
	if partNode == nil then
		return
	else
		local fence = segment.fence
		local hitX, hitY, hitZ = getWorldTranslation(partNode)
		self.awaitingFenceSegmentDeletion = true
		g_messageCenter:subscribeOneshot(FenceRequestDeleteSegmentPartEvent, function(success)
			local placeable = fence.parentObject
			local placeableExists = false
			if placeable ~= nil then
				placeableExists = false
				if placeable.rootNode ~= nil then
					placeableExists = entityExists(placeable.rootNode)
				end
			end
			if success and (placeableExists and placeable.playDestroySound ~= nil) then
				placeable:playDestroySound(true)
			end
			self.awaitingFenceSegmentDeletion = false
		end)
		local event = FenceRequestDeleteSegmentPartEvent.newClientToServer(fence.parentObject, segment.id, childIndex, hitX, hitY, hitZ, wholeSegment)
		g_client:getServerConnection():sendEvent(event)
	end
end
function ConstructionBrushDestruct:destroyNodeInPlaceable(placeable)
	local didDestroy, destroyPlaceable = placeable:performNodeDestruction(self.cursor:getHitNode())
	if didDestroy and placeable.playDestroySound ~= nil then
		placeable:playDestroySound(true)
	end
	if destroyPlaceable then
		g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable, true, true, false))
	end
end
function ConstructionBrushDestruct:resetPlaceableSelection()
	self:resetColoredNodes()
	if self.lastPlaceable ~= nil then
		if self.lastPlaceable.rootNode ~= nil and (entityExists(self.lastPlaceable.rootNode) and not self.perNodeMode) then
			self.lastPlaceable:setOverlayColor(1, 1, 1, 0)
		end
		self.lastPlaceable = nil
		g_messageCenter:unsubscribeAll(self)
	end
end
function ConstructionBrushDestruct:onPlaceableDestroyed(state, sellPrice)
	if self.lastPlaceable ~= nil then
		self:resetPlaceableSelection()
	end
end
function ConstructionBrushDestruct:getButtonPrimaryText()
	if self.hoveredDeletableFence == nil then
		return "$l10n_input_CONSTRUCTION_REMOVE"
	elseif self.deleteWholeSegment then
		return "$l10n_action_fenceDeleteWholeSegment"
	else
		return "$l10n_action_fenceDeleteSinglePanel"
	end
end
function ConstructionBrushDestruct:getButtonTertiaryText()
	if self.hoveredDeletableFence == nil then
		return nil
	else
		return "$l10n_action_fenceSwitchDeleteMode"
	end
end
