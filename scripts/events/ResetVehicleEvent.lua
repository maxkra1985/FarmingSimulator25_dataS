-- Local values: ResetVehicleEvent_mt
ResetVehicleEvent = {}
ResetVehicleEvent.STATE_SUCCESS = 0
ResetVehicleEvent.STATE_FAILED = 1
ResetVehicleEvent.STATE_NO_PERMISSION = 2
ResetVehicleEvent.STATE_IN_USE = 3
local ResetVehicleEvent_mt = Class(ResetVehicleEvent, Event)
InitStaticEventClass(ResetVehicleEvent, "ResetVehicleEvent")
function ResetVehicleEvent.emptyNew()
	-- upvalues: (copy) ResetVehicleEvent_mt
	return Event.new(ResetVehicleEvent_mt)
end

-- Local values: self
function ResetVehicleEvent.new(vehicle)
	local v3_ = ResetVehicleEvent.emptyNew()
	v3_.vehicle = vehicle
	return v3_
end

-- Local values: self
function ResetVehicleEvent.newServerToClient(state)
	local v5_ = ResetVehicleEvent.emptyNew()
	v5_.state = state
	return v5_
end

function ResetVehicleEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.state = streamReadUIntN(streamId, 2)
	else
		self.vehicle = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function ResetVehicleEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
	else
		streamWriteUIntN(streamId, self.state, 2)
	end
end

-- Local values: state, vehicle
function ResetVehicleEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(ResetVehicleEvent, self.state)
	else
		local v_u_14_ = ResetVehicleEvent.STATE_FAILED
		local v15_ = self.vehicle
		if v15_ ~= nil and (v15_.isVehicleSaved and v15_:getCanBeReset()) then
			if g_currentMission:getHasPlayerPermission("resetVehicle", connection, v15_:getOwnerFarmId()) then
				if v15_:getIsInUse(connection) then
					v_u_14_ = ResetVehicleEvent.STATE_IN_USE
				else
					if not v15_.isResetInProgress then
						v15_:reset(false, function(p16_)
							-- upvalues: (ref) v_u_14_, (copy) connection
							if p16_ then
								v_u_14_ = ResetVehicleEvent.STATE_SUCCESS
							end
							connection:sendEvent(ResetVehicleEvent.newServerToClient(v_u_14_))
						end)
						return
					end
					v_u_14_ = ResetVehicleEvent.STATE_IN_USE
				end
			else
				v_u_14_ = ResetVehicleEvent.STATE_NO_PERMISSION
			end
		end
		connection:sendEvent(ResetVehicleEvent.newServerToClient(v_u_14_))
	end
end
