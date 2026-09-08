-- Local values: VehicleStateRecorder_mt
VehicleStateRecorder = {}
VehicleStateRecorder.currentInstance = nil
local VehicleStateRecorder_mt = Class(VehicleStateRecorder)

-- Upvalues: VehicleStateRecorder_mt
-- Local values: self
function VehicleStateRecorder.new(vehicle, name, duration, animationName)
	-- upvalues: (copy) VehicleStateRecorder_mt
	local v6_ = VehicleStateRecorder_mt
	local v_u_7_ = setmetatable({}, v6_)
	v_u_7_.vehicle = vehicle
	v_u_7_.name = name or animationName
	v_u_7_.duration = (duration or math.huge) * 1000
	if v_u_7_.name == nil then
		v_u_7_.name = "vehicleState_" .. getDate("%Y_%m_%d_%H_%M")
	end
	v_u_7_.nodeState = {}
	if animationName == nil then
		g_currentMission:addUpdateable(v_u_7_)
		v_u_7_.isActive = true
		v_u_7_.startTime = g_time
		v_u_7_:recordVehicle()
		Logging.info("Start vehicle state recording for \'%s\'", v_u_7_.vehicle.configFileNameClean)
		return v_u_7_
	end
	if VehicleStateRecorder.defaultRaiseEvent == nil then
		VehicleStateRecorder.defaultRaiseEvent = SpecializationUtil.raiseEvent
		function SpecializationUtil.raiseEvent(p8_, p9_, p10_, ...)
			-- upvalues: (copy) v_u_7_, (copy) animationName
			VehicleStateRecorder.defaultRaiseEvent(p8_, p9_, p10_, ...)
			if p8_ == v_u_7_.vehicle and p10_ == animationName then
				if p9_ == "onPlayAnimation" then
					if not v_u_7_.isActive then
						g_currentMission:addUpdateable(v_u_7_)
						v_u_7_.isActive = true
						v_u_7_.startTime = g_time
						v_u_7_:recordVehicle()
						Logging.info("Start vehicle state recording for \'%s\'", v_u_7_.vehicle.configFileNameClean)
						return
					end
				elseif p9_ == "onFinishAnimation" and v_u_7_.isActive then
					v_u_7_:finish()
				end
			end
		end
		return v_u_7_
	end
	Logging.warning("VehicleStateRecorder is already active. Only one recording at a time is supported.")
end

function VehicleStateRecorder:update(dt)
	if g_time - self.startTime > self.duration then
		self:finish()
	else
		self:recordVehicle()
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(1, 1, 1, 0.5)
		renderText(0.5, 0.03, 0.03, string.format("Vehicle State Recording for \'%s\' (%.1f sec)", self.vehicle.configFileNameClean, (g_time - self.startTime) * 0.001))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
	end
end

-- Local values: directory, filename, xmlFile, lineIndex, indexPath, states, key, i, state, stateKey, lastState
function VehicleStateRecorder:finish()
	Logging.info("Finish vehicle state recording for \'%s\' (%.1fsec)", self.vehicle.configFileNameClean, (g_time - (self.startTime or 0)) * 0.001)
	local v13_ = Utils.getDirectory(self.vehicle.configFileName)
	if string.startsWith(v13_, "data/") then
		v13_ = getAppBasePath() .. v13_
	end
	local v14_ = v13_ .. "giantsTools"
	createFolder(v14_)
	local v15_ = string.format(v14_ .. "/%s.xml", self.name)
	local v16_ = XMLFile.create("vehicleState", v15_, "vehicleState", nil)
	local v17_ = 0
	for v18_, v19_ in pairs(self.nodeState) do
		if #v19_ > 0 then
			local v20_ = string.format("vehicleState.node(%d)", v17_)
			v16_:setString(v20_ .. "#name", v19_[1].name)
			v16_:setString(v20_ .. "#className", v19_[1].className)
			v16_:setString(v20_ .. "#indexPath", v18_)
			for v21_, v22_ in ipairs(v19_) do
				local v23_ = string.format("%s.s(%d)", v20_, v21_ - 1)
				v16_:setFloat(v23_ .. "#t", v22_.time * 0.001)
				local v24_ = v19_[v21_ - 1]
				if v24_ == nil or (v24_.translation[1] ~= v22_.translation[1] or (v24_.translation[2] ~= v22_.translation[2] or v24_.translation[3] ~= v22_.translation[3])) then
					v16_:setString(v23_ .. "#tr", string.format("%.5f %.5f %.5f", v22_.translation[1], v22_.translation[2], v22_.translation[3]))
				end
				if v24_ == nil or (v24_.rotation[1] ~= v22_.rotation[1] or (v24_.rotation[2] ~= v22_.rotation[2] or v24_.rotation[3] ~= v22_.rotation[3])) then
					local v25_ = v23_ .. "#ro"
					local v26_ = string.format
					local v27_ = v22_.rotation[1]
					local v28_ = math.deg(v27_)
					local v29_ = v22_.rotation[2]
					local v30_ = math.deg(v29_)
					local v31_ = v22_.rotation[3]
					v16_:setString(v25_, v26_("%.4f %.4f %.4f", v28_, v30_, (math.deg(v31_))))
				end
				if v24_ == nil or v24_.visibility ~= v22_.visibility then
					v16_:setBool(v23_ .. "#vi", v22_.visibility)
				end
			end
			v17_ = v17_ + 1
		end
	end
	v16_:save()
	v16_:delete()
	Logging.info("Save recording to \'%s\'", v15_)
	g_currentMission:removeUpdateable(VehicleStateRecorder.currentInstance)
	if VehicleStateRecorder.defaultRaiseEvent ~= nil then
		SpecializationUtil.raiseEvent = VehicleStateRecorder.defaultRaiseEvent
		VehicleStateRecorder.defaultRaiseEvent = nil
	end
end

-- Local values: i, component
function VehicleStateRecorder:recordVehicle()
	for v33_, v34_ in ipairs(self.vehicle.components) do
		local v35_ = v34_.node
		local v36_ = v33_ - 1
		self:recordNode(v35_, tostring(v36_), ">")
	end
end

-- Local values: x, y, z, rx, ry, rz, visibility, doRecordState, states, lastState, newState, className, classId, i, child, childPath
function VehicleStateRecorder:recordNode(node, indexPath, separator)
	if self.vehicle.i3dMappings[getName(node)] ~= nil then
		local v41_, v42_, v43_ = getTranslation(node)
		local v44_, v45_, v46_ = getRotation(node)
		local v47_ = getVisibility(node)
		local v48_ = false
		local v49_
		if self.nodeState[indexPath] == nil then
			self.nodeState[indexPath] = {}
			v49_ = true
		else
			local v50_ = self.nodeState[indexPath]
			local v51_ = v50_[#v50_]
			local v52_ = (v51_.translation[1] ~= v41_ or (v51_.translation[2] ~= v42_ or v51_.translation[3] ~= v43_)) and true or v48_
			local v53_ = (v51_.rotation[1] ~= v44_ or (v51_.rotation[2] ~= v45_ or v51_.rotation[3] ~= v46_)) and true or v52_
			v49_ = v51_.visibility ~= v47_ and true or v53_
		end
		if v49_ then
			local v54_ = {
				["translation"] = { v41_, v42_, v43_ },
				["rotation"] = { v44_, v45_, v46_ },
				["visibility"] = v47_,
				["time"] = g_time - self.startTime
			}
			if #self.nodeState[indexPath] == 0 then
				v54_.name = getName(node)
				for v55_, v56_ in pairs(ClassIds) do
					if getHasClassId(node, v56_) then
						v54_.className = v55_
						break
					end
				end
			end
			local v57_ = self.nodeState[indexPath]
			table.insert(v57_, v54_)
		end
	end
	for v58_ = 1, getNumOfChildren(node) do
		self:recordNode(getChildAt(node, v58_ - 1), indexPath .. (separator or "|") .. v58_ - 1)
	end
end

-- Local values: vehicle, selectedVehicle
function VehicleStateRecorder.consoleCommand(unusedSelf, name, duration)
	if VehicleStateRecorder.currentInstance == nil then
		if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
			local v61_ = g_localPlayer:getCurrentVehicle()
			local v62_ = v61_:getSelectedVehicle() or v61_
			VehicleStateRecorder.currentInstance = VehicleStateRecorder.new(v62_, name, duration)
			return
		end
	else
		VehicleStateRecorder.currentInstance:finish()
		VehicleStateRecorder.currentInstance = nil
	end
end

-- Local values: vehicle, selectedVehicle
function VehicleStateRecorder.consoleCommandAnimation(unusedSelf, animationName)
	if VehicleStateRecorder.currentInstance == nil then
		if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
			local v64_ = g_localPlayer:getCurrentVehicle()
			local v65_ = v64_:getSelectedVehicle() or v64_
			VehicleStateRecorder.currentInstance = VehicleStateRecorder.new(v65_, nil, nil, animationName)
			return
		end
	else
		VehicleStateRecorder.currentInstance:finish()
		VehicleStateRecorder.currentInstance = nil
	end
end
addConsoleCommand("gsVehicleRecordState", "Starts and stops vehicle state recording", "VehicleStateRecorder.consoleCommand", nil)
addConsoleCommand("gsVehicleRecordAnimation", "Turns on the state recording for the given animationName", "VehicleStateRecorder.consoleCommandAnimation", nil)
