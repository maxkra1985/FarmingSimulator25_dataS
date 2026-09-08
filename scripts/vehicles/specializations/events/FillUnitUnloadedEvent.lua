-- Local values: FillUnitUnloadedEvent_mt
FillUnitUnloadedEvent = {}
local FillUnitUnloadedEvent_mt = Class(FillUnitUnloadedEvent, Event)
InitStaticEventClass(FillUnitUnloadedEvent, "FillUnitUnloadedEvent")
function FillUnitUnloadedEvent.emptyNew()
	-- upvalues: (copy) FillUnitUnloadedEvent_mt
	return Event.new(FillUnitUnloadedEvent_mt)
end

-- Local values: self
function FillUnitUnloadedEvent.new(object, pallet, showWarning, result)
	local v6_ = FillUnitUnloadedEvent.emptyNew()
	v6_.object = object
	v6_.pallet = pallet
	v6_.showWarning = showWarning
	v6_.result = result
	return v6_
end

-- Local values: paramsXZ, paramsY, x_rot, y_rot, z_rot, result
function FillUnitUnloadedEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	if streamReadBool(streamId) then
		self.pallet = NetworkUtil.readNodeObject(streamId)
		local v10_ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
		local v11_ = g_currentMission.vehicleYPosHighPrecisionCompressionParams
		self.x = NetworkUtil.readCompressedWorldPosition(streamId, v10_)
		self.y = NetworkUtil.readCompressedWorldPosition(streamId, v11_)
		self.z = NetworkUtil.readCompressedWorldPosition(streamId, v10_)
		local v12_ = NetworkUtil.readCompressedAngle(streamId)
		local v13_ = NetworkUtil.readCompressedAngle(streamId)
		local v14_ = NetworkUtil.readCompressedAngle(streamId)
		local v15_, v16_, v17_, v18_ = mathEulerToQuaternion(v12_, v13_, v14_)
		self.qx = v15_
		self.qy = v16_
		self.qz = v17_
		self.qw = v18_
	else
		self.showWarning = streamReadBool(streamId)
		local v19_ = streamReadUIntN(streamId, 2)
		if v19_ == 2 then
			self.result = true
		elseif v19_ == 1 then
			self.result = false
		end
	end
	self:run(connection)
end

-- Local values: paramsXZ, paramsY, component, x, y, z, x_rot, y_rot, z_rot
function FillUnitUnloadedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	if streamWriteBool(streamId, self.pallet ~= nil) then
		NetworkUtil.writeNodeObject(streamId, self.pallet)
		local v22_ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
		local v23_ = g_currentMission.vehicleYPosHighPrecisionCompressionParams
		local v24_ = self.pallet.components[1]
		local v25_, v26_, v27_ = getWorldTranslation(v24_.node)
		local v28_, v29_, v30_ = getWorldRotation(v24_.node)
		NetworkUtil.writeCompressedWorldPosition(streamId, v25_, v22_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v26_, v23_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v27_, v22_)
		NetworkUtil.writeCompressedAngle(streamId, v28_)
		NetworkUtil.writeCompressedAngle(streamId, v29_)
		NetworkUtil.writeCompressedAngle(streamId, v30_)
		return
	else
		streamWriteBool(streamId, self.showWarning == true)
		if self.result == nil then
			streamWriteUIntN(streamId, 0, 2)
		else
			streamWriteUIntN(streamId, self.result == true and 2 or 1, 2)
		end
	end
end

function FillUnitUnloadedEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.pallet ~= nil and self.pallet:getIsSynchronized() then
			if self.pallet.unmount ~= nil then
				self.pallet:unmount(true)
			end
			self.pallet:setWorldPositionQuaternion(self.x, self.y, self.z, self.qx, self.qy, self.qz, self.qw, 1, true)
			SpecializationUtil.raiseEvent(self.object, "onFillUnitUnloadPallet", self.pallet)
			return
		end
		if self.showWarning and self.object:getIsActiveForInput(true) then
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("fillUnit_unload_nospace"))
		end
		if self.result ~= nil then
			SpecializationUtil.raiseEvent(self.object, "onFillUnitUnloaded", self.result)
		end
	end
end
