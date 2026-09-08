-- Local values: ConsumableActivatable_mt
ConsumableActivatable = {}
ConsumableActivatable.TYPE_TEXTS = {}
ConsumableActivatable.TYPE_TEXTS.BALE_WRAP = "action_refillBaleWrap"
ConsumableActivatable.TYPE_TEXTS.BALE_NET = "action_refillBaleNet"
ConsumableActivatable.TYPE_TEXTS.BALE_TWINE = "action_refillBaleTwine"
ConsumableActivatable.TYPE_TEXTS.RICE_SAPLINGS = "action_refillBaleTwine"
local ConsumableActivatable_mt = Class(ConsumableActivatable)

-- Upvalues: ConsumableActivatable_mt
-- Local values: self
function ConsumableActivatable.new(vehicle)
	-- upvalues: (copy) ConsumableActivatable_mt
	local v3_ = ConsumableActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.vehicle = vehicle
	v4_.activateText = ""
	return v4_
end

-- Local values: spec, i, type
function ConsumableActivatable:getIsActivatable()
	if self.vehicle:getIsActiveForInput(true) then
		local v6_ = self.vehicle.spec_consumable
		for _, v7_ in ipairs(v6_.types) do
			if v7_.consumingFillLevel == 0 then
				return true
			end
		end
	end
	return false
end

-- Local values: spec, typeIndex, type, callback
function ConsumableActivatable:run()
	local v9_ = self.vehicle.spec_consumable
	for v_u_10_, v11_ in ipairs(v9_.types) do
		if v11_.consumingFillLevel == 0 then
			self.optionsTypeName = v11_.typeName
			local v12_, v13_ = g_consumableManager:getConsumableVariationsByType(v11_.typeName)
			self.options = v12_
			self.optionToVariationIndex = v13_
			OptionDialog.show(function(p14_)
				-- upvalues: (copy) self, (copy) v_u_10_
				if p14_ ~= nil then
					local v15_ = self.optionToVariationIndex[p14_]
					if v15_ ~= nil then
						ConsumableRefillEvent.sendEvent(self.vehicle, v_u_10_, v15_)
					end
				end
			end, g_i18n:getText("ui_consumableSelectType"), g_i18n:getText(ConsumableActivatable.TYPE_TEXTS[v11_.typeName]), self.options)
		end
	end
end

-- Local values: spec, i, type
function ConsumableActivatable:updateActivateText()
	local v17_ = self.vehicle.spec_consumable
	for _, v18_ in ipairs(v17_.types) do
		if v18_.consumingFillLevel == 0 then
			self.activateText = g_i18n:getText(ConsumableActivatable.TYPE_TEXTS[v18_.typeName])
		end
	end
end
