-- Local values: ConstructionBrushDestruct_mt
ConstructionBrushDestruct = {}
local ConstructionBrushDestruct_mt = Class(ConstructionBrushDestruct, ConstructionBrush)
ConstructionBrushDestruct.OVERLAY_COLOR = { 1, 0.1, 0.1 }
ConstructionBrushDestruct.SELL_UNDO_TIMEOUT = 900000

-- Upvalues: ConstructionBrushDestruct_mt
-- Local values: self
function ConstructionBrushDestruct.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushDestruct_mt
	local v4_ = ConstructionBrushDestruct:superClass().new(subclass_mt or ConstructionBrushDestruct_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsPrimaryDragging = true
	v4_.requiredPermission = Farm.PERMISSION.SELL_PLACEABLE
	return v4_
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
end

function ConstructionBrushDestruct:deactivate()
	self.cursor:setSelectionMode(false)
	self:resetPlaceableSelection()
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushDestruct:superClass().deactivate(self)
end

function ConstructionBrushDestruct:update(dt)
	ConstructionBrushDestruct:superClass().update(self, dt)
	if self:hasPlayerPermission() then
		self:visualizeMouseOver()
	else
		self.cursor:setErrorMessage(g_i18n:getText("shop_messageNoPermissionGeneral"))
	end
end

-- Local values: storeItemNameCleaned
function ConstructionBrushDestruct:draw()
	if g_isDevelopmentVersion and (self.lastPlaceable ~= nil and self.lastPlaceable.configFileName ~= nil) then
		local v11_ = string.gsub(self.lastPlaceable.configFileName, getUserProfileAppPath(), "")
		renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, v11_)
	end
end

-- Local values: i, node
function ConstructionBrushDestruct:resetColoredNodes()
	for v13_ = #self.coloredNodes, 1, -1 do
		local v14_ = self.coloredNodes[v13_]
		if entityExists(v14_) then
			setShaderParameter(v14_, "placeableColorScale", 1, 1, 1, 0, false)
		end
		self.coloredNodes[v13_] = nil
	end
end

-- Local values: placeable, color, r, g, b, a, cursorHitNode, nodes, _, node, _, node, object, segment
function ConstructionBrushDestruct:visualizeMouseOver()
	table.clear(self.destructionPreviewNodes)
	local v16_ = self.cursor:getHitPlaceable()
	if v16_ == self.lastPlaceable and not self.perNodeMode then
		local v17_ = self.cursor:getHitObject()
		if v17_ ~= nil and v17_:isa(Fence) then
			if v17_.getAllowSegmentDeletion ~= nil and not v17_:getAllowSegmentDeletion() then
				return
			end
			local v18_ = v17_:getSegmentFromNode(self.cursor:getHitNode())
			if v18_ ~= nil and v18_:getCanBeModifiedByFarmId(g_localPlayer.farmId) then
				DebugShapeOutline.render(v18_.root, true)
			end
		end
	else
		self:resetPlaceableSelection()
		if v16_ ~= nil and g_localPlayer.farmId == v16_.ownerFarmId then
			self.lastPlaceable = v16_
			g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
			local v19_ = ConstructionBrushDestruct.OVERLAY_COLOR
			local v20_ = v19_[1]
			local v21_ = v19_[2]
			local v22_ = v19_[3]
			if v16_:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
				self:resetColoredNodes()
				local v23_ = v16_:previewNodeDestructionNodes(self.cursor:getHitNode(), self.destructionPreviewNodes)
				if v23_ ~= nil then
					for _, v24_ in ipairs(v23_) do
						if getHasClassId(v24_, ClassIds.SHAPE) and getHasShaderParameter(v24_, "placeableColorScale") then
							setShaderParameter(v24_, "placeableColorScale", v20_, v21_, v22_, 0.8, false)
							local v25_ = self.coloredNodes
							table.insert(v25_, v24_)
						end
					end
					if #self.coloredNodes == 0 then
						for _, v26_ in ipairs(v23_) do
							DebugShapeOutline.render(v26_, true)
						end
					end
				end
				self.perNodeMode = true
			else
				v16_:setOverlayColor(v20_, v21_, v22_, 0.8)
				self.perNodeMode = false
			end
		end
	end
end

-- Local values: placeable, callbackFunc, canBeSold, warning, price, forFullPrice, callbackFunc, text, object, hitNode, segment
function ConstructionBrushDestruct:onButtonPrimary(isDown, isDrag, isUp)
	if isUp then
		self.lastDragPlaceable = nil
		return
	elseif self:hasPlayerPermission() then
		local v_u_31_ = self.cursor:getHitPlaceable()
		if v_u_31_ == nil or (g_localPlayer.farmId ~= v_u_31_.ownerFarmId or self.lastDragPlaceable ~= nil and v_u_31_ ~= self.lastDragPlaceable) then
			if isDown and not isDrag then
				local v32_ = self.cursor:getHitObject()
				if v32_ ~= nil and v32_:isa(Fence) then
					if self.awaitingFenceSegmentDeletion then
						return
					end
					if v32_.getAllowSegmentDeletion ~= nil and not v32_:getAllowSegmentDeletion() then
						return
					end
					local v33_ = v32_:getSegmentFromNode((self.cursor:getHitNode()))
					if v33_ ~= nil and v33_:getCanBeModifiedByFarmId(g_localPlayer.farmId) then
						self.awaitingFenceSegmentDeletion = true
						g_messageCenter:subscribeOneshot(FenceDeleteSegmentEvent, function(p34_, _)
							-- upvalues: (copy) self
							if p34_ ~= nil and p34_.playDestroySound ~= nil then
								p34_:playDestroySound(true)
							end
							self.awaitingFenceSegmentDeletion = false
						end)
						g_client:getServerConnection():sendEvent(FenceDeleteSegmentEvent.new(v32_.parentObject, v33_.id))
					end
				end
			end
		else
			if v_u_31_:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
				if isDown then
					self.lastDragPlaceable = v_u_31_
				end
				if v_u_31_.getConfirmDestruction == nil or not v_u_31_:getConfirmDestruction() then
					self:destroyNodeInPlaceable(v_u_31_)
				else
					YesNoDialog.show(function(p35_)
						-- upvalues: (copy) self, (copy) v_u_31_
						if p35_ then
							self:destroyNodeInPlaceable(v_u_31_)
						end
					end, nil, g_i18n:getText("ui_constructionDeleteConfirmationRiceField"), nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
				end
			end
			if isDown then
				local v36_, v37_ = v_u_31_:canBeSold()
				local v38_, v_u_39_ = v_u_31_:getSellPrice()
				local function v41_(p40_)
					-- upvalues: (copy) v_u_31_, (copy) v_u_39_
					if p40_ then
						g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(v_u_31_, false, v_u_39_))
					end
				end
				if v37_ == nil then
					local v42_ = string.format(g_i18n:getText("ui_constructionSellConfirmation"), v_u_31_:getName(), g_i18n:formatMoney(v38_, 0, true, true))
					YesNoDialog.show(v41_, nil, v42_)
					return
				elseif v36_ then
					YesNoDialog.show(v41_, nil, v37_, nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
				else
					InfoDialog.show(v37_, nil, nil, nil, g_i18n:getText("button_back"), InputAction.MENU_BACK)
				end
			end
		end
	end
end

-- Local values: didDestroy, destroyPlaceable
function ConstructionBrushDestruct:destroyNodeInPlaceable(placeable)
	local v45_, v46_ = placeable:performNodeDestruction(self.cursor:getHitNode())
	if v45_ and placeable.playDestroySound ~= nil then
		placeable:playDestroySound(true)
	end
	if v46_ then
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
	return "$l10n_input_CONSTRUCTION_REMOVE"
end
