PlaceableBuyable = {}
source("dataS/scripts/placeables/specializations/activatables/BuyBuildingActivatable.lua")

function PlaceableBuyable.prerequisitesPresent(specializations)
	return true
end

function PlaceableBuyable.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onBuyingTriggerCallback", PlaceableBuyable.onBuyingTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "setIsBuyingTriggerActive", PlaceableBuyable.setIsBuyingTriggerActive)
	SpecializationUtil.registerFunction(placeableType, "buyRequest", PlaceableBuyable.buyRequest)
	SpecializationUtil.registerFunction(placeableType, "getHasBuyingTrigger", PlaceableBuyable.getHasBuyingTrigger)
end

function PlaceableBuyable.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableBuyable.setOwnerFarmId)
end

function PlaceableBuyable.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBuyable)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBuyable)
end

function PlaceableBuyable.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Buyable")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".buyable.trigger#node", "Buying trigger", nil, false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".buyable.marker#node", "Marker node", nil, false)
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableBuyable:onLoad(savegame)
	local v7_ = self.spec_buyable
	v7_.activatable = BuyBuildingActivatable.new(self)
	v7_.triggerNode = self.xmlFile:getValue("placeable.buyable.trigger#node", nil, self.components, self.i3dMappings)
	if v7_.triggerNode ~= nil then
		addTrigger(v7_.triggerNode, "onBuyingTriggerCallback", self)
	end
	v7_.markerNode = self.xmlFile:getValue("placeable.buyable.marker#node", nil, self.components, self.i3dMappings)
	v7_.isTriggerActive = true
end

-- Local values: spec
function PlaceableBuyable:onDelete()
	local v9_ = self.spec_buyable
	g_currentMission.activatableObjectsSystem:removeActivatable(v9_.activatable)
	v9_.activatable = nil
	if v9_.markerNode ~= nil then
		g_currentMission:removeTriggerMarker(v9_.markerNode)
	end
	if v9_.triggerNode ~= nil then
		removeTrigger(v9_.triggerNode)
	end
end

-- Local values: spec
function PlaceableBuyable:getHasBuyingTrigger()
	return self.spec_buyable.triggerNode ~= nil
end

-- Local values: spec
function PlaceableBuyable:setIsBuyingTriggerActive(isActive)
	local v13_ = self.spec_buyable
	v13_.isTriggerActive = isActive
	if v13_.markerNode ~= nil then
		setVisibility(v13_.markerNode, isActive)
		if isActive then
			g_currentMission:addTriggerMarker(v13_.markerNode)
			return
		end
		g_currentMission:removeTriggerMarker(v13_.markerNode)
	end
end

-- Local values: spec
function PlaceableBuyable:onBuyingTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
		local v18_ = self.spec_buyable
		if onEnter and v18_.isTriggerActive then
			if Platform.gameplay.autoActivateTrigger and v18_.activatable:getIsActivatable() then
				v18_.activatable:run()
				return
			end
			g_currentMission.activatableObjectsSystem:addActivatable(v18_.activatable)
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v18_.activatable)
		end
	end
end

-- Local values: playerFarmId, price, farmlandId, farmland, placeable, buyingEventCallback, dialogCallback
function PlaceableBuyable:buyRequest(requestCallback, target)
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		local v_u_22_ = g_currentMission:getFarmId()
		local v23_ = self:getPrice()
		if self.buysFarmland then
			local v24_ = self:getFarmlandId()
			local v25_ = g_farmlandManager:getFarmlandById(v24_)
			if v25_ ~= nil and g_farmlandManager:getFarmlandOwner(v24_) ~= v_u_22_ then
				v23_ = v23_ + v25_.price * self.buysFarmlandPriceScale
			end
		end
		local function v_u_28_(p26_)
			-- upvalues: (copy) self
			if p26_ ~= nil then
				local v27_ = BuyExistingPlaceableEvent.DIALOG_MESSAGES[p26_]
				if v27_ ~= nil then
					InfoDialog.show(g_i18n:getText(v27_.text), nil, nil, v27_.dialogType)
				end
			end
			g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
			self:onBuy()
		end
		YesNoDialog.show(function(p29_)
			-- upvalues: (copy) v_u_28_, (copy) self, (copy) v_u_22_, (copy) requestCallback, (copy) target
			if p29_ then
				g_messageCenter:subscribe(BuyExistingPlaceableEvent, v_u_28_)
				g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self, v_u_22_))
			end
			if requestCallback ~= nil then
				if target ~= nil then
					target:requestCallback(p29_)
					return
				end
				requestCallback(p29_)
			end
		end, nil, string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(v23_, 0, true)))
	end
end

function PlaceableBuyable:setOwnerFarmId(superFunc, farmId, noEventSend)
	superFunc(self, farmId, noEventSend)
	self:setIsBuyingTriggerActive(farmId == AccessHandler.EVERYONE)
end
