-- Local values: ChangeVehicleConfigEvent_mt
ChangeVehicleConfigEvent = {}
local ChangeVehicleConfigEvent_mt = Class(ChangeVehicleConfigEvent, Event)
InitStaticEventClass(ChangeVehicleConfigEvent, "ChangeVehicleConfigEvent")
function ChangeVehicleConfigEvent.emptyNew()
	-- upvalues: (copy) ChangeVehicleConfigEvent_mt
	return Event.new(ChangeVehicleConfigEvent_mt)
end

-- Local values: self
function ChangeVehicleConfigEvent.new(vehicle, vehicleBuyData)
	local v4_ = ChangeVehicleConfigEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.vehicleBuyData = vehicleBuyData
	return v4_
end

-- Local values: self
function ChangeVehicleConfigEvent.newServerToClient(successful)
	local v6_ = ChangeVehicleConfigEvent.emptyNew()
	v6_.successful = successful
	return v6_
end

function ChangeVehicleConfigEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.successful = streamReadBool(streamId)
	else
		self.vehicle = NetworkUtil.readNodeObject(streamId)
		self.vehicleBuyData = BuyVehicleData.new()
		self.vehicleBuyData:readStream(streamId, connection)
	end
	self:run(connection)
end

function ChangeVehicleConfigEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
		self.vehicleBuyData:writeStream(streamId, connection)
	else
		streamWriteBool(streamId, self.successful)
	end
end

-- Local values: success, vehicle, vehicleSystem, spec, i, implement, xmlFile, asyncCallbackFunction
function ChangeVehicleConfigEvent:run(connection)
	if connection:getIsServer() then
		g_workshopScreen:onVehicleChanged(self.successful)
	else
		local v_u_15_ = false
		local v_u_16_ = self.vehicle
		if v_u_16_ == nil or (not v_u_16_.isVehicleSaved or v_u_16_.getIsControlled ~= nil and v_u_16_:getIsControlled()) or not g_currentMission:getHasPlayerPermission("buyVehicle", connection) then
			connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(false))
		else
			local v_u_17_ = g_currentMission.vehicleSystem
			v_u_16_:setConfigurations(self.vehicleBuyData.configurations, self.vehicleBuyData.boughtConfigurations, self.vehicleBuyData.configurationData)
			if v_u_16_.setLicensePlatesData ~= nil and (v_u_16_.getHasLicensePlates ~= nil and v_u_16_:getHasLicensePlates()) then
				v_u_16_:setLicensePlatesData(self.vehicleBuyData.licensePlateData)
			end
			local v18_ = v_u_16_.spec_attacherJoints
			if v18_ ~= nil and v18_.attachedImplements ~= nil then
				for v19_ = #v18_.attachedImplements, 1, -1 do
					local v20_ = v18_.attachedImplements[v19_]
					if not v20_.object:getIsAdditionalAttachment() then
						v_u_16_:detachImplementByObject(v20_.object, true)
					end
				end
			end
			v_u_16_.isReconfigurating = true
			g_server:broadcastEvent(VehicleSetIsReconfiguratingEvent.new(v_u_16_), nil, nil, v_u_16_)
			local v_u_21_ = v_u_16_:getReloadXML()
			local function v_u_23_(_, p22_, _)
				-- upvalues: (ref) v_u_15_, (copy) self, (copy) v_u_16_, (copy) v_u_17_, (copy) v_u_21_, (copy) connection
				if #p22_ > 0 then
					v_u_15_ = true
					g_currentMission:addMoney(-self.vehicleBuyData.price, self.vehicleBuyData.ownerFarmId, MoneyType.SHOP_VEHICLE_BUY, true)
					v_u_16_:removeFromPhysics()
					v_u_16_:delete(true)
				else
					v_u_16_:addToPhysics()
					v_u_17_.vehicleByUniqueId[v_u_16_:getUniqueId()] = v_u_16_
				end
				v_u_21_:delete()
				connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(v_u_15_))
			end
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) v_u_17_, (copy) v_u_16_, (copy) v_u_21_, (copy) v_u_23_
				v_u_17_.vehicleByUniqueId[v_u_16_:getUniqueId()] = nil
				v_u_17_:loadFromXMLFile(v_u_21_, v_u_23_, nil, {})
			end)
		end
	end
end
