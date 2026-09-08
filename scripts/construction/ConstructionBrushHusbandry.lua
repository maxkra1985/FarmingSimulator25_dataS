-- Local values: ConstructionBrushHusbandry_mt
ConstructionBrushHusbandry = {}
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryCancelCreationEvent.lua")
local ConstructionBrushHusbandry_mt = Class(ConstructionBrushHusbandry, ConstructionBrushPlaceable)

-- Upvalues: ConstructionBrushHusbandry_mt
-- Local values: self
function ConstructionBrushHusbandry.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushHusbandry_mt
	return ConstructionBrushHusbandry:superClass().new(subclass_mt or ConstructionBrushHusbandry_mt, cursor)
end

function ConstructionBrushHusbandry:deactivate()
	if self.findPlaceableWithId ~= nil then
		g_client:getServerConnection():sendEvent(HusbandryCancelCreationEvent.new(self.findPlaceableWithId))
	end
	self.findPlaceableWithId = nil
	ConstructionBrushHusbandry:superClass().deactivate(self)
end

-- Local values: placeable
function ConstructionBrushHusbandry:update(dt)
	ConstructionBrushHusbandry:superClass().update(self, dt)
	if self.findPlaceableWithId ~= nil then
		local v7_ = NetworkUtil.getObject(self.findPlaceableWithId)
		if v7_ ~= nil and v7_:getIsSynchronized() then
			self.findPlaceableWithId = nil
			self:onCreatedPlaceableFound(v7_)
		end
	end
end

function ConstructionBrushHusbandry:onPlaceableCreated(errorCode, price, serverObjectId)
	ConstructionBrushHusbandry:superClass().onPlaceableCreated(self, errorCode, price, serverObjectId)
	if errorCode == BuyPlaceableEvent.STATE_SUCCESS then
		self.findPlaceableWithId = serverObjectId
	end
end

-- Local values: customizeFenceDialogCallback
function ConstructionBrushHusbandry:onCreatedPlaceableFound(placeable)
	if placeable.getHasCustomizableFence == nil or not placeable:getHasCustomizableFence() then
		self:onCustomizableFenceFinished(placeable)
	else
		YesNoDialog.show(function(p14_)
			-- upvalues: (copy) self, (copy) placeable
			if p14_ then
				self:onCustomizeFenceStart(placeable)
			else
				self:onCustomizableFenceFinished(placeable)
			end
		end, nil, string.namedFormat(g_i18n:getText("ui_construction_customizeFence"), "placeableName", self.placeable:getName()))
	end
end

-- Local values: fence, storeItem, brushClass, brush, startX, startY, startZ, endX, endY, endZ
function ConstructionBrushHusbandry:onCustomizeFenceStart(placeable)
	placeable:startFenceCustomization(nil)
	local v17_ = placeable:getFence()
	local v18_ = g_storeManager:getItemByXMLFilename(v17_.xmlFilename)
	local v19_ = g_constructionBrushTypeManager:getClassObjectByTypeName(v18_.brush.type).new(nil, self.cursor)
	v19_:setFenceParentObject(placeable)
	local v20_, v21_, v22_, v23_, v24_, v25_ = placeable:getCustomizeableSectionStartAndEndPositions()
	v19_:setSnapStartAndEndPositions(v20_, v21_, v22_, v23_, v24_, v25_)
	v19_:setFinishCallback(function(p26_)
		-- upvalues: (copy) self, (copy) placeable
		self:onFinishedCustomFence(p26_, placeable)
	end)
	v19_:setValidateCallback(function(p27_)
		-- upvalues: (copy) self, (copy) placeable
		self:validateFence(p27_, placeable)
	end)
	g_constructionScreen:setBrush(v19_, true)
end

function ConstructionBrushHusbandry:validateFence(finishedValidationFunc, placeable)
	MessageDialog.show(g_i18n:getText("ui_construction_fenceHusbandryValidating"))
	g_messageCenter:subscribeOneshot(HusbandryFenceValidateEvent, function(p30_)
		-- upvalues: (copy) finishedValidationFunc
		MessageDialog.hide()
		finishedValidationFunc(p30_)
		if not p30_ then
			InfoDialog.show(g_i18n:getText("ui_construction_fenceHusbandryFailed"))
		end
	end, nil)
	g_client:getServerConnection():sendEvent(HusbandryFenceValidateEvent.new(placeable))
end

-- Local values: success
function ConstructionBrushHusbandry:onFinishedCustomFence(statusCode, placeable)
	g_constructionScreen:setBrush(self, false)
	placeable:finishFenceCustomization(nil, statusCode == ConstructionBrushNewFence.STATUS.SUCCESS)
	self:onCustomizableFenceFinished(placeable)
end

-- Local values: createMeadowCallback
function ConstructionBrushHusbandry:onCustomizableFenceFinished(placeable)
	if placeable.getCanCreateMeadow ~= nil and placeable:getCanCreateMeadow() then
		YesNoDialog.show(function(p36_)
			-- upvalues: (copy) self, (copy) placeable
			g_constructionScreen:setBrush(self, false)
			placeable:createMeadow(p36_)
		end, nil, string.namedFormat(g_i18n:getText("ui_construction_createMeadow"), "placeableName", placeable:getName()))
	end
end
