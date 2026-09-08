-- Local values: PalletUnloadTrigger_mt
PalletUnloadTrigger = {}
source("dataS/scripts/triggers/PalletUnloadTriggerActivatable.lua")
local PalletUnloadTrigger_mt = Class(PalletUnloadTrigger, UnloadTrigger)
UnloadTrigger.registerCustomTrigger("palletTrigger", PalletUnloadTrigger)
InitStaticObjectClass(PalletUnloadTrigger, "PalletUnloadTrigger")

function PalletUnloadTrigger.registerXMLPaths(schema, basePath)
	UnloadTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
	schema:register(XMLValueType.BOOL, basePath .. "#autoUnload", "Auto unload pallets", true)
	schema:register(XMLValueType.BOOL, basePath .. "#autoUnloadStrapped", "Auto unload pallets that are fasten with tension belts", false)
end

-- Upvalues: PalletUnloadTrigger_mt
-- Local values: self
function PalletUnloadTrigger.new(isServer, isClient, customMt)
	-- upvalues: (copy) PalletUnloadTrigger_mt
	local v7_ = UnloadTrigger.new(isServer, isClient, customMt or PalletUnloadTrigger_mt)
	v7_.triggerNode = nil
	v7_.activatable = PalletUnloadTriggerActivatable.new(v7_)
	v7_.isPlayerInRange = false
	v7_.isEnabled = true
	v7_.palletsInRange = {}
	v7_.vehiclesInRange = {}
	v7_.autoUnload = true
	v7_.autoUnloadStrapped = false
	return v7_
end

-- Local values: triggerNodeKey, colMask
function PalletUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	if not PalletUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
		return false
	end
	local v15_ = xmlNode .. "#triggerNode"
	self.triggerNode = xmlFile:getValue(v15_, nil, components, i3dMappings)
	if self.triggerNode == nil then
		Logging.xmlError(xmlFile, "Pallet trigger %q not specified!", v15_)
		return false
	end
	local v16_ = getCollisionFilterMask(self.triggerNode)
	local v17_ = CollisionFlag.VEHICLE
	if bit32.band(v17_, v16_) == 0 then
		Logging.xmlError(xmlFile, "Invalid collision mask for pallet trigger \'%s\'. %s needs to be set!", v15_, CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
		return false
	end
	addTrigger(self.triggerNode, "palletTriggerCallback", self)
	self.autoUnload = xmlFile:getValue(xmlNode .. "#autoUnload", self.autoUnload)
	self.autoUnloadStrapped = xmlFile:getValue(xmlNode .. "#autoUnloadStrapped", self.autoUnloadStrapped)
	return true
end

-- Local values: _, pallet
function PalletUnloadTrigger:delete()
	if self.triggerNode ~= nil and self.triggerNode ~= 0 then
		removeTrigger(self.triggerNode)
		self.triggerNode = 0
	end
	if self.palletsInRange ~= nil then
		for _, v19_ in ipairs(self.palletsInRange) do
			if v19_.removeDeleteListener ~= nil then
				v19_:removeDeleteListener(self, "onObjectDeleted")
			end
		end
		table.clear(self.palletsInRange)
	end
	if self.vehiclesInRange ~= nil then
		table.clear(self.vehiclesInRange)
	end
	PalletUnloadTrigger:superClass().delete(self)
end

function PalletUnloadTrigger:update(dt)
	PalletUnloadTrigger:superClass().update(self, dt)
	if self.isServer and next(self.palletsInRange) ~= nil then
		self:unloadPallets()
		if next(self.palletsInRange) ~= nil then
			self:raiseActive()
		end
	end
end

-- Local values: mission, accessHandler, _, pallet, fillUnits, fillUnitIndex, _, fillTypeIndex, fillLevel, isAllowed, used
function PalletUnloadTrigger:unloadPallets(farmId)
	if self.isServer then
		local v24_ = g_currentMission
		local v25_ = v24_.accessHandler
		for _, v26_ in ipairs(self.palletsInRange) do
			if farmId == nil or v25_:canFarmAccess(farmId, v26_) then
				local v27_ = v26_:getFillUnits()
				for v28_, _ in pairs(v27_) do
					local v29_ = v26_:getFillUnitFillType(v28_)
					if v29_ ~= FillType.UNKNOWN and self:getIsFillTypeSupported(v29_) then
						local v30_ = v26_:getFillUnitFillLevel(v28_)
						if v30_ > 0 then
							local v31_ = true
							if v26_.dynamicMountType ~= nil and v26_.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
								if self.autoUnloadStrapped then
									v26_:unmountDynamic()
								else
									v31_ = false
									if self.isServer then
										self:raiseActive()
									end
								end
							end
							if v31_ then
								if v26_.getPalletUnloadTriggerExtraSellPrice ~= nil and (self.target ~= nil and self.target.moneyChangeType ~= nil) then
									v24_:addMoney(v26_:getPalletUnloadTriggerExtraSellPrice(), v26_:getOwnerFarmId(), self.target.moneyChangeType, true)
								end
								local v32_ = self:addFillUnitFillLevel(v26_:getOwnerFarmId(), v28_, v30_, v29_, ToolType.UNDEFINED)
								v26_:addFillUnitFillLevel(v26_:getOwnerFarmId(), v28_, -v32_, v29_, ToolType.UNDEFINED)
								if v26_:getFillUnitFillLevel(v28_) < 1 then
									v26_:delete()
								end
							end
						end
					end
				end
			end
		end
	else
		g_client:getServerConnection():sendEvent(PalletUnloadTriggerEvent.new(self))
	end
end

-- Local values: mission
function PalletUnloadTrigger:updateActivatableObject()
	local v34_ = g_currentMission
	if self.isPlayerInRange or next(self.vehiclesInRange) ~= nil then
		v34_.activatableObjectsSystem:addActivatable(self.activatable)
	else
		v34_.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

function PalletUnloadTrigger:onObjectDeleted(object)
	table.removeElement(self.palletsInRange, object)
	self.vehiclesInRange[object] = nil
end

-- Local values: mission, object, fillUnits, fillUnitIndex, _, fillTypeIndex
function PalletUnloadTrigger:palletTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 then
		local v40_ = g_currentMission:getNodeObject(otherId)
		if v40_ ~= nil and (v40_.isPallet and v40_.getFillUnits ~= nil) then
			if onEnter then
				local v41_ = v40_:getFillUnits()
				for v42_, _ in pairs(v41_) do
					local v43_ = v40_:getFillUnitFillType(v42_)
					if v43_ ~= FillType.UNKNOWN and (self:getIsFillTypeSupported(v43_) and v40_:getFillUnitFillLevel(v42_) > 0) then
						table.addElement(self.palletsInRange, v40_)
						v40_:addDeleteListener(self, "onObjectDeleted")
					end
				end
				if self.autoUnload and self.isServer then
					self:unloadPallets()
				end
			else
				table.removeElement(self.palletsInRange, v40_)
				v40_:removeDeleteListener(self, "onObjectDeleted")
			end
		end
		if not self.autoUnload then
			if v40_ == nil then
				if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
					if onEnter then
						self.isPlayerInRange = true
					else
						self.isPlayerInRange = false
					end
				end
			elseif v40_:isa(Vehicle) then
				if onEnter then
					if self.vehiclesInRange[v40_] == nil then
						self.vehiclesInRange[v40_] = 0
						v40_:addDeleteListener(self, "onObjectDeleted")
					end
					self.vehiclesInRange[v40_] = self.vehiclesInRange[v40_] + 1
				elseif self.vehiclesInRange[v40_] ~= nil then
					self.vehiclesInRange[v40_] = self.vehiclesInRange[v40_] - 1
					if self.vehiclesInRange[v40_] == 0 then
						self.vehiclesInRange[v40_] = nil
						v40_:removeDeleteListener(self, "onObjectDeleted")
					end
				end
			end
		end
		self:updateActivatableObject()
	end
end

function PalletUnloadTrigger:getNeedRaiseActive()
	return false
end
