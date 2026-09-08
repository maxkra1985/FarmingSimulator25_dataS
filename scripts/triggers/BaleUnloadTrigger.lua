-- Local values: BaleUnloadTrigger_mt
BaleUnloadTrigger = {}
local BaleUnloadTrigger_mt = Class(BaleUnloadTrigger, UnloadTrigger)
UnloadTrigger.registerCustomTrigger("baleTrigger", BaleUnloadTrigger)
InitStaticObjectClass(BaleUnloadTrigger, "BaleUnloadTrigger")

function BaleUnloadTrigger.registerXMLPaths(schema, basePath)
	UnloadTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
	schema:register(XMLValueType.FLOAT, basePath .. "#deleteLitersPerSecond", "Delete liters per second", 4000)
	FillTypeManager.registerConfigXMLFilltypes(schema, basePath)
end

-- Upvalues: BaleUnloadTrigger_mt
-- Local values: self
function BaleUnloadTrigger.new(isServer, isClient, customMt)
	-- upvalues: (copy) BaleUnloadTrigger_mt
	local v7_ = UnloadTrigger.new(isServer, isClient, customMt or BaleUnloadTrigger_mt)
	v7_.triggerNode = nil
	v7_.balesInTrigger = {}
	return v7_
end

function BaleUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	if not BaleUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
		return false
	end
	self.triggerNode = xmlFile:getValue(xmlNode .. "#triggerNode", nil, components, i3dMappings)
	if self.triggerNode == nil then
		Logging.xmlError(xmlFile, "Bale trigger \'%s\' not specified", xmlNode .. "#triggerNode")
		return false
	end
	if not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.DYNAMIC_OBJECT) then
		Logging.xmlError(xmlFile, "Bale trigger \'%s\' does not have Bit \'%d\' (%s) set", xmlNode .. "#triggerNode", CollisionFlag.getBit(CollisionFlag.DYNAMIC_OBJECT), "TRIGGER_DYNAMIC_OBJECT")
		return false
	end
	if Platform.gameplay.automaticBaleDrop and not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.VEHICLE) then
		Logging.xmlError(xmlFile, "Bale trigger \'%s\' does not have Bit \'%d\' (%s) set, which is required for automatic bale loader unloading", xmlNode .. "#triggerNode", CollisionFlag.getBit(CollisionFlag.VEHICLE), "TRIGGER_VEHICLE")
		return false
	end
	if self.isServer then
		addTrigger(self.triggerNode, "baleTriggerCallback", self)
	end
	self.deleteLitersPerMS = xmlFile:getValue(xmlNode .. "#deleteLitersPerSecond", 4000) / 1000
	return true
end

function BaleUnloadTrigger:delete()
	if self.isServer and self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
	end
	self.triggerNode = nil
	self.balesInTrigger = nil
	BaleUnloadTrigger:superClass().delete(self)
end

-- Local values: fillType
function BaleUnloadTrigger:getIsBaleSupportedByUnloadTrigger(bale)
	local v18_ = bale:getFillType()
	if self.supportedFillTypes == nil or self.supportedFillTypes[v18_] ~= nil then
		return self:getIsFillTypeAllowed(v18_) and (self:getIsFillTypeSupported(v18_) and self:getIsToolTypeAllowed(ToolType.BALE)) and true or false
	else
		return false
	end
end

-- Local values: index, bale, fillType, fillLevel, fillInfo, delta, baleOwnerFarmId, newFillLevel, total, _
function BaleUnloadTrigger:update(dt)
	BaleUnloadTrigger:superClass().update(self, dt)
	if self.isServer then
		for v21_, v22_ in ipairs(self.balesInTrigger) do
			if v22_ == nil or v22_.nodeId == 0 then
				table.remove(self.balesInTrigger, v21_)
				break
			end
			if v22_:getCanBeSold() and v22_.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
				local v23_ = v22_:getFillType()
				local v24_ = v22_:getFillLevel()
				local v25_ = v22_:getFillLevel()
				if self.deleteLitersPerMS ~= nil then
					v25_ = self.deleteLitersPerMS * dt
				end
				if v25_ > 0 then
					local v26_ = v22_:getOwnerFarmId()
					v22_:setFillLevel(v24_ - self:addFillUnitFillLevel(v26_, 1, v25_, v23_, ToolType.BALE, nil))
					if v22_:getFillLevel() < 0.01 then
						if v23_ == FillType.COTTON then
							local v27_, _ = g_farmManager:updateFarmStats(v26_, "soldCottonBales", 1)
							if v27_ ~= nil then
								g_achievementManager:tryUnlock("CottonBales", v27_)
							end
						end
						v22_:delete()
						table.remove(self.balesInTrigger, v21_)
						break
					end
				end
			end
		end
		if #self.balesInTrigger > 0 then
			self:raiseActive()
		end
	end
end

-- Local values: mission, object, index, bale
function BaleUnloadTrigger:baleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if self.isEnabled then
		local v32_ = g_currentMission:getNodeObject(otherId)
		if v32_ ~= nil then
			if v32_:isa(Bale) then
				if onEnter then
					if self:getIsBaleSupportedByUnloadTrigger(v32_) then
						self:raiseActive()
						table.addElement(self.balesInTrigger, v32_)
						return
					end
				elseif onLeave then
					for v33_, v34_ in ipairs(self.balesInTrigger) do
						if v34_ == v32_ then
							table.remove(self.balesInTrigger, v33_)
							return
						end
					end
					return
				end
			elseif v32_:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, v32_.specializations) then
				if onEnter then
					v32_:addBaleUnloadTrigger(self)
					return
				end
				if onLeave then
					v32_:removeBaleUnloadTrigger(self)
				end
			end
		end
	end
end
