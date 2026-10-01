ConstructionBrushHusbandry = {}
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryCancelCreationEvent.lua")
local ConstructionBrushHusbandry_mt = Class(ConstructionBrushHusbandry, ConstructionBrushPlaceable)
function ConstructionBrushHusbandry.new(subclass_mt, cursor)
	local self = ConstructionBrushHusbandry:superClass().new(subclass_mt or ConstructionBrushHusbandry_mt, cursor)
	return self
end
function ConstructionBrushHusbandry:deactivate()
	if self.findPlaceableWithId ~= nil then
		g_client:getServerConnection():sendEvent(HusbandryCancelCreationEvent.new(self.findPlaceableWithId))
	end
	self.findPlaceableWithId = nil
	ConstructionBrushHusbandry:superClass().deactivate(self)
end
function ConstructionBrushHusbandry:update(dt)
	ConstructionBrushHusbandry:superClass().update(self, dt)
	if self.findPlaceableWithId ~= nil then
		local placeable = NetworkUtil.getObject(self.findPlaceableWithId)
		if placeable ~= nil and placeable:getIsSynchronized() then
			self.findPlaceableWithId = nil
			self:onCreatedPlaceableFound(placeable)
		end
	end
end
function ConstructionBrushHusbandry:onPlaceableCreated(errorCode, price, serverObjectId)
	ConstructionBrushHusbandry:superClass().onPlaceableCreated(self, errorCode, price, serverObjectId)
	if errorCode == BuyPlaceableEvent.STATE_SUCCESS then
		self.findPlaceableWithId = serverObjectId
	end
end
function ConstructionBrushHusbandry:onCreatedPlaceableFound(placeable)
	if placeable.getHasCustomizableFence ~= nil and placeable:getHasCustomizableFence() then
		local customizeFenceDialogCallback = function(yes)
			if yes then
				self:onCustomizeFenceStart(placeable)
			else
				self:onCustomizableFenceFinished(placeable)
			end
		end
		YesNoDialog.show(customizeFenceDialogCallback, nil, string.namedFormat(g_i18n:getText("ui_construction_customizeFence"), "placeableName", self.placeable:getName()))
		return
	end
	self:onCustomizableFenceFinished(placeable)
end
function ConstructionBrushHusbandry:onCustomizeFenceStart(placeable)
	placeable:startFenceCustomization(nil)
	local fence = placeable:getFence()
	local storeItem = g_storeManager:getItemByXMLFilename(fence.xmlFilename)
	local brushClass = g_constructionBrushTypeManager:getClassObjectByTypeName(storeItem.brush.type)
	local brush = brushClass.new(nil, self.cursor)
	brush:setFenceParentObject(placeable)
	local startX, startY, startZ, endX, endY, endZ = placeable:getCustomizeableSectionStartAndEndPositions()
	brush:setSnapStartAndEndPositions(startX, startY, startZ, endX, endY, endZ)
	brush:setFinishCallback(function(statusCode)
		self:onFinishedCustomFence(statusCode, placeable)
	end)
	brush:setValidateCallback(function(finishedValidationFunc)
		self:validateFence(finishedValidationFunc, placeable)
	end)
	g_constructionScreen:setBrush(brush, true)
end
function ConstructionBrushHusbandry:validateFence(finishedValidationFunc, placeable)
	MessageDialog.show(g_i18n:getText("ui_construction_fenceHusbandryValidating"))
	g_messageCenter:subscribeOneshot(HusbandryFenceValidateEvent, function(success)
		MessageDialog.hide()
		finishedValidationFunc(success)
		if not success then
			InfoDialog.show(g_i18n:getText("ui_construction_fenceHusbandryFailed"))
		end
	end, nil)
	g_client:getServerConnection():sendEvent(HusbandryFenceValidateEvent.new(placeable))
end
function ConstructionBrushHusbandry:onFinishedCustomFence(statusCode, placeable)
	g_constructionScreen:setBrush(self, false)
	local success = statusCode == ConstructionBrushNewFence.STATUS.SUCCESS
	placeable:finishFenceCustomization(nil, success)
	self:onCustomizableFenceFinished(placeable)
end
function ConstructionBrushHusbandry:onCustomizableFenceFinished(placeable)
	if placeable.getCanCreateMeadow ~= nil and placeable:getCanCreateMeadow() then
		local createMeadowCallback = function(yes)
			g_constructionScreen:setBrush(self, false)
			placeable:createMeadow(yes)
		end
		YesNoDialog.show(createMeadowCallback, nil, string.namedFormat(g_i18n:getText("ui_construction_createMeadow"), "placeableName", placeable:getName()))
	end
end
