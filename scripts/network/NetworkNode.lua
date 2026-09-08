-- Local values: NetworkNode_mt
NetworkNode = {}
local NetworkNode_mt = Class(NetworkNode)
NetworkNode.LOCAL_STREAM_ID = 0
NetworkNode.PACKET_EVENT = 1
NetworkNode.PACKET_VEHICLE = 2
NetworkNode.PACKET_PLAYER = 3
NetworkNode.PACKET_SPLITSHAPES = 4
NetworkNode.PACKET_DENSITY_MAPS = 5
NetworkNode.PACKET_TERRAIN_DEFORM = 6
NetworkNode.PACKET_VOICE_CHAT = 7
NetworkNode.PACKET_PLACEABLE = 8
NetworkNode.PACKET_HANDTOOL = 9
NetworkNode.PACKET_TRAFFICSYSTEM = 10
NetworkNode.PACKET_OTHERS = 11
NetworkNode.NUM_PACKETS = 11
NetworkNode.CHANNEL_MAIN = 1
NetworkNode.CHANNEL_SECONDARY = 2
NetworkNode.CHANNEL_CHAT = 3
NetworkNode.CHANNEL_TERRAIN_DEFORMATION = 4
NetworkNode.OBJECT_SEND_NUM_BITS = 24

-- Upvalues: NetworkNode_mt
-- Local values: self, i, showGraphLabels, color
function NetworkNode.new(customMt)
	-- upvalues: (copy) NetworkNode_mt
	local v3_ = customMt or NetworkNode_mt
	local v4_ = setmetatable({}, v3_)
	v4_.objects = {}
	v4_.objectIds = {}
	v4_.activeObjects = {}
	v4_.activeObjectsNextFrame = {}
	v4_.removedObjects = {}
	v4_.dirtyObjects = {}
	v4_.lastUploadedKBs = 0
	v4_.lastUploadedKBsSmooth = 0
	v4_.maxUploadedKBs = 0
	v4_.serverFPS = 60
	v4_.graphData = {}
	v4_.graphData[NetworkNode.PACKET_EVENT] = {
		["color"] = {
			1,
			0,
			0,
			1
		},
		["title"] = "event"
	}
	v4_.graphData[NetworkNode.PACKET_VEHICLE] = {
		["color"] = {
			0,
			1,
			0,
			1
		},
		["title"] = "vehicle"
	}
	v4_.graphData[NetworkNode.PACKET_PLAYER] = {
		["color"] = {
			0,
			0,
			1,
			1
		},
		["title"] = "player"
	}
	v4_.graphData[NetworkNode.PACKET_SPLITSHAPES] = {
		["color"] = {
			1,
			1,
			0,
			1
		},
		["title"] = "split shapes"
	}
	v4_.graphData[NetworkNode.PACKET_DENSITY_MAPS] = {
		["color"] = {
			0.5,
			0.5,
			0,
			1
		},
		["title"] = "density maps"
	}
	v4_.graphData[NetworkNode.PACKET_TERRAIN_DEFORM] = {
		["color"] = {
			0.5,
			0.5,
			0.5,
			1
		},
		["title"] = "terrain deform"
	}
	v4_.graphData[NetworkNode.PACKET_VOICE_CHAT] = {
		["color"] = {
			1,
			0.5,
			0.5,
			1
		},
		["title"] = "voice chat"
	}
	v4_.graphData[NetworkNode.PACKET_PLACEABLE] = {
		["color"] = {
			1,
			0.2,
			0.2,
			1
		},
		["title"] = "placeable"
	}
	v4_.graphData[NetworkNode.PACKET_HANDTOOL] = {
		["color"] = {
			1,
			1,
			0.2,
			1
		},
		["title"] = "handTool"
	}
	v4_.graphData[NetworkNode.PACKET_TRAFFICSYSTEM] = {
		["color"] = {
			1,
			0.2,
			1,
			1
		},
		["title"] = "traffic system"
	}
	v4_.graphData[NetworkNode.PACKET_OTHERS] = {
		["color"] = {
			0,
			1,
			1,
			1
		},
		["title"] = "others"
	}
	v4_.packetGraphs = {}
	v4_.connectionPacketGraphs = {}
	v4_.packetBytes = {}
	for v5_ = 1, NetworkNode.NUM_PACKETS do
		local v6_ = v5_ == 1
		v4_.packetGraphs[v5_] = Graph.new(80, 0.4, 0.05, 0.55, 0.8, 0, 1000, v6_, "bytes (max)")
		local v7_ = v4_.graphData[v5_].color
		v4_.packetGraphs[v5_]:setColor(v7_[1], v7_[2], v7_[3], v7_[4])
		if v6_ then
			v4_.packetGraphs[v5_]:setHorizontalLine(1000, false, 1, 1, 1, 0.2)
			v4_.packetGraphs[v5_]:setBackgroundColor(0.2, 0.2, 0.2, 0.3)
		end
		v4_.packetBytes[v5_] = {}
		v4_.connectionPacketGraphs[v5_] = {}
	end
	v4_.showNetworkTraffic = false
	v4_.showNetworkTrafficClients = false
	v4_.showObjects = false
	v4_.updateDurationTimer = 0
	v4_.updateDurationFrames = 0
	v4_.updateDurationTotalTime = 0
	return v4_
end

-- Local values: _, object, _, connections, connection, graph, i
function NetworkNode:delete()
	g_debugManager:removeDrawable(self)
	for _, v9_ in pairs(self.objects) do
		self:unregisterObject(v9_, true)
		v9_:delete()
	end
	self.objects = {}
	self.objectIds = {}
	self.activeObjects = {}
	self.activeObjectsNextFrame = {}
	self.removedObjects = {}
	self.dirtyObjects = {}
	for _, v10_ in pairs(self.connectionPacketGraphs) do
		for v11_, v12_ in pairs(v10_) do
			v12_:delete()
			v10_[v11_] = nil
		end
	end
	for v13_ = 1, NetworkNode.NUM_PACKETS do
		self.packetGraphs[v13_]:delete()
	end
end

function NetworkNode:setNetworkListener(listener)
	self.networkListener = listener
end

function NetworkNode:update(dt) end

-- Local values: id, object, activeObjects, _, object, startTime, _, object, _, object
function NetworkNode:updateActiveObjects(dt)
	for v18_, _ in pairs(self.removedObjects) do
		self.activeObjects[v18_] = nil
		self.activeObjectsNextFrame[v18_] = nil
		self.removedObjects[v18_] = nil
	end
	local v19_ = self.activeObjects
	if self.showObjects then
		for _, v20_ in pairs(v19_) do
			local v21_ = getTimeSec()
			if v20_.recieveUpdates then
				v20_:update(dt)
			end
			v20_.profilerUpdateCounter = (v20_.profilerUpdateCounter or 0) + (getTimeSec() - v21_)
		end
		self.updateDurationTimer = self.updateDurationTimer + dt
		self.updateDurationFrames = self.updateDurationFrames + 1
		if self.updateDurationTimer >= 1000 then
			self.updateDurationTotalTime = 0
			for _, v22_ in pairs(v19_) do
				v22_.profilerUpdateTime = v22_.profilerUpdateCounter * 1000 / self.updateDurationFrames
				v22_.profilerUpdateCounter = 0
				self.updateDurationTotalTime = self.updateDurationTotalTime + v22_.profilerUpdateTime
			end
			self.updateDurationTimer = 0
			self.updateDurationFrames = 0
			return
		end
	else
		for _, v23_ in pairs(v19_) do
			if v23_.recieveUpdates then
				v23_:update(dt)
			end
		end
	end
end

-- Local values: i, activeObjects, serverId, object, id, oldObject
function NetworkNode:updateActiveObjectsTick(dt)
	for v26_ = #self.dirtyObjects, 1, -1 do
		self.dirtyObjects[v26_] = nil
	end
	local v27_ = self.activeObjects
	for v28_, v29_ in pairs(v27_) do
		if v29_.recieveUpdates then
			v29_:updateTick(dt)
		end
		if v29_.dirtyMask ~= 0 then
			v29_.lastServerId = v29_._serverId or v28_
			local v30_ = self.dirtyObjects
			table.insert(v30_, v29_)
		end
		local v31_ = self.objectIds[v29_]
		self.activeObjects[v31_] = nil
		if v29_.recieveUpdates and self.activeObjectsNextFrame[v31_] == nil then
			v29_:updateEnd(dt)
		end
	end
	local v32_ = self.activeObjects
	self.activeObjects = self.activeObjectsNextFrame
	self.activeObjectsNextFrame = v32_
	return self.dirtyObjects
end

-- Local values: refTextSize, ping, download, upload, packetLoss
function NetworkNode:drawConnectionNetworkStats(connection, posX, posY, textSize)
	if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
		return false
	end
	local v37_ = getCorrectTextSize(0.01)
	if not connection.isConnected then
		renderText(posX, posY, textSize, "Not connected")
		return false
	end
	local v38_, v39_, v40_, v41_ = netGetConnectionStats(connection.streamId)
	if v38_ == nil then
		v38_ = 0
		v39_ = 0
		v40_ = 0
		v41_ = 0
	end
	if connection.pingSmooth == nil then
		connection.pingSmooth = v38_
		connection.downloadSmooth = v39_
		connection.uploadSmooth = v40_
		connection.packetLossSmooth = v41_
	end
	connection.pingSmooth = connection.pingSmooth + (v38_ - connection.pingSmooth) * 0.2
	connection.downloadSmooth = connection.downloadSmooth + (v39_ - connection.downloadSmooth) * 0.2
	connection.uploadSmooth = connection.uploadSmooth + (v40_ - connection.uploadSmooth) * 0.2
	connection.packetLossSmooth = connection.packetLossSmooth + (v41_ - connection.packetLossSmooth) * 0.2
	local v42_ = connection.pingSmooth
	local v43_ = connection.downloadSmooth
	local v44_ = connection.uploadSmooth
	local v45_ = connection.packetLossSmooth
	renderText(posX, posY, textSize, string.format("%dms", v42_))
	renderText(posX + 0.016 * (textSize / v37_), posY, textSize, string.format("w:%2d", connection.lastSeqSent - connection.highestAckedSeq))
	renderText(posX + 0.029 * (textSize / v37_), posY, textSize, string.format("d:%4.2fkb/s", v43_ / 1024))
	renderText(posX + 0.061 * (textSize / v37_), posY, textSize, string.format("u:%4.2fkb/s", v44_ / 1024))
	renderText(posX + 0.093 * (textSize / v37_), posY, textSize, string.format("loss:%4.2f%%", v45_ * 100))
	renderText(posX + 0.126 * (textSize / v37_), posY, textSize, string.format("comp:%.2f%%", 1 / connection.compressionRatio * 100))
	return true
end

function NetworkNode:getObjectPacketType(object)
	if object == nil then
		return NetworkNode.PACKET_OTHERS
	elseif object:isa(Vehicle) then
		return NetworkNode.PACKET_VEHICLE
	elseif object:isa(Player) then
		return NetworkNode.PACKET_PLAYER
	elseif object:isa(Placeable) then
		return NetworkNode.PACKET_PLACEABLE
	elseif object:isa(HandTool) then
		return NetworkNode.PACKET_HANDTOOL
	elseif object:isa(TrafficSystem) then
		return NetworkNode.PACKET_TRAFFICSYSTEM
	else
		return NetworkNode.PACKET_OTHERS
	end
end

-- Local values: key, value
function NetworkNode:getPacketTypeName(packetType)
	for v48_, v49_ in pairs(Network) do
		if v49_ == packetType then
			return v48_
		end
	end
	return "TYPE_UNKNOWN"
end

-- Local values: endOffset, readNumBits, objectInfo
function NetworkNode:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, name, object)
	local v55_ = streamGetReadOffset(streamId) - (startOffset + 32)
	if v55_ ~= numBits then
		local v56_
		if object == nil then
			v56_ = ""
		else
			v56_ = ": " .. object.className
			if object.configFileName ~= nil then
				v56_ = v56_ .. " (" .. object.configFileName .. ")"
			end
		end
		printError("Error: Not all bits read in object " .. name .. " (" .. v55_ .. " vs " .. numBits .. ")" .. v56_)
	end
end

function NetworkNode:addPacketSize(connection, packetType, packetSizeInBytes)
	if self.showNetworkTraffic or self.showNetworkTrafficClients then
		self.packetBytes[packetType][connection] = (self.packetBytes[packetType][connection] or 0) + packetSizeInBytes
	end
end

-- Local values: packetBytesSum, connectionSum, i, connections, totalPacketBytes, connection, bytes, showGraphLabels, color, i
function NetworkNode:updatePacketStats(dt)
	if self.showNetworkTraffic or self.showNetworkTrafficClients then
		local v63_ = {}
		local v64_ = 0
		for v65_ = 1, NetworkNode.NUM_PACKETS do
			local v66_ = self.packetBytes[v65_]
			local v67_ = 0
			for v68_, v69_ in pairs(v66_) do
				if self.clientConnections ~= nil and self.clientConnections[v68_.streamId] == nil then
					v66_[v68_] = nil
					if self.connectionPacketGraphs[v65_][v68_] ~= nil then
						self.connectionPacketGraphs[v65_][v68_]:delete()
						self.connectionPacketGraphs[v65_][v68_] = nil
					end
				end
				if v66_[v68_] ~= nil then
					if self.connectionPacketGraphs[v65_][v68_] == nil then
						local v70_ = v65_ == 1
						self.connectionPacketGraphs[v65_][v68_] = Graph.new(80, 0, 0, 0.15, 0.25, 0, 7500, v70_, "bytes", nil, nil, nil, getCorrectTextSize(0.008))
						local v71_ = self.graphData[v65_].color
						self.connectionPacketGraphs[v65_][v68_]:setColor(v71_[1], v71_[2], v71_[3], v71_[4])
						if v70_ then
							self.connectionPacketGraphs[v65_][v68_]:setHorizontalLine(1000, false, 1, 1, 1, 0.3)
							self.connectionPacketGraphs[v65_][v68_]:setBackgroundColor(0.2, 0.2, 0.2, 0.3)
						end
					end
					if v63_[v68_] == nil then
						v63_[v68_] = 0
					end
					self.connectionPacketGraphs[v65_][v68_]:addValue(v63_[v68_] + v69_, v63_[v68_])
					v63_[v68_] = v63_[v68_] + v69_
					v66_[v68_] = 0
					v67_ = v67_ + v69_
				end
			end
			self.packetGraphs[v65_]:addValue(v64_ + v67_, v64_)
			v64_ = v64_ + v67_
		end
		for v72_ = 1, NetworkNode.NUM_PACKETS do
			local v73_ = self.packetGraphs[v72_]
			local v74_ = self.packetGraphs[v72_].maxValue
			v73_.maxValue = math.max(v74_, v64_)
		end
		self.lastUploadedKBs = v64_ / 1024 * 1000 / dt
	end
end

-- Local values: i, data
function NetworkNode:drawGraphLabels(x, y, textSize)
	for v79_ = 1, NetworkNode.NUM_PACKETS do
		local v80_ = self.graphData[v79_]
		local v81_ = setTextColor
		local v82_ = v80_.color
		v81_(unpack(v82_))
		renderText(x, y + (v79_ - 1) * textSize, textSize, v80_.title)
	end
	setTextColor(1, 1, 1, 1)
end

-- Local values: mission, userManager, smoothAlpha, alpha, r, g, x, y, i, textSize, i, _, connection, posY, user, connections, startPosX, posX, posY, textSize, _, connection, hasGraph, packetType, graph, user, count, id, object, allObjects, _, object, sortByClassName, posX, posY, title, _, object, path, debugServerId, text, isActive, activeR, activeG, alpha
function NetworkNode:drawDebug()
	local v84_ = g_currentMission.userManager
	if self.showNetworkTraffic then
		self.lastUploadedKBsSmooth = self.lastUploadedKBsSmooth * 0.8 + self.lastUploadedKBs * 0.19999999999999996
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.01, 0.8, getCorrectTextSize(0.015), string.format("Game Data Upload %.2fkb/s ", self.lastUploadedKBsSmooth))
		local v85_ = self.serverFPS / 60
		local v86_ = math.clamp(v85_, 0, 1)
		local v87_ = 1 - v86_
		setTextColor(v87_, v86_, 0, 1)
		renderText(0.01, 0.82, getCorrectTextSize(0.015), string.format("Server: %d FPS", self.serverFPS))
		setTextColor(1, 1, 1, 1)
		self:drawGraphLabels(self.packetGraphs[1].left - 0.15, self.packetGraphs[1].bottom, getCorrectTextSize(0.02))
		for v88_ = 1, NetworkNode.NUM_PACKETS do
			self.packetGraphs[v88_]:draw()
		end
		local v89_ = getCorrectTextSize(0.014)
		if self.clientConnections == nil then
			if self.serverConnection ~= nil then
				self:drawConnectionNetworkStats(self.serverConnection, 0.01, 0.8 - v89_ * 1.1, v89_)
			end
		else
			local v90_ = 1
			for _, v91_ in pairs(self.clientConnections) do
				local v92_ = 0.78 - v90_ * v89_ * 1.1
				if self:drawConnectionNetworkStats(v91_, 0.01, v92_, v89_) then
					local v93_ = v84_:getUserByConnection(v91_)
					if v93_ ~= nil then
						renderText(0.255, v92_, v89_, v93_:getNickname())
					end
					v90_ = v90_ + 1
				end
			end
		end
	end
	if self.showNetworkTrafficClients and self.clientConnections ~= nil then
		local v94_ = self.clientConnections
		local v95_ = getCorrectTextSize(0.01)
		local v96_ = 0.04
		local v97_ = 0.7
		for _, v98_ in pairs(v94_) do
			local v99_ = false
			for v100_ = 1, NetworkNode.NUM_PACKETS do
				local v101_ = self.connectionPacketGraphs[v100_][v98_]
				if v101_ ~= nil then
					v101_.left = v96_
					v101_.bottom = v97_ + 0.015
					local v102_
					if v100_ == 1 then
						v102_ = v96_ == 0.04
					else
						v102_ = false
					end
					v101_.showLabels = v102_
					self.connectionPacketGraphs[v100_][v98_]:draw()
					v99_ = true
				end
			end
			if v99_ then
				self:drawConnectionNetworkStats(v98_, v96_, v97_, v95_)
				local v103_ = v84_:getUserByConnection(v98_)
				if v103_ ~= nil then
					renderText(v96_, v97_ - 0.011, v95_, v103_:getNickname())
				end
				v96_ = v96_ + 0.16
				if v96_ + 0.16 > 1 then
					v97_ = v97_ - 0.32
					v96_ = 0.04
				end
			end
		end
		self:drawGraphLabels(0.8, 0.1, getCorrectTextSize(0.02))
	end
	if self.showObjects then
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v104_ = 0
		for _, v105_ in pairs(self.activeObjects) do
			v104_ = v104_ + 1
			v105_.debugServerId = self.objectIds[v105_] or -1
		end
		local v106_ = {}
		for _, v107_ in pairs(self.objects) do
			v107_.debugServerId = self.objectIds[v107_] or -1
			local v108_ = v107_.debugClassName
			if not v108_ then
				local v109_ = ClassUtil.getClassNameByObject
				v108_ = tostring(v109_(v107_))
			end
			v107_.debugClassName = v108_
			table.insert(v106_, v107_)
		end
		local v_u_110_ = self.debugSortByClassName
		table.sort(v106_, function(p111_, p112_)
			-- upvalues: (copy) v_u_110_
			if v_u_110_ and p111_.debugClassName ~= p112_.debugClassName then
				return p111_.debugClassName < p112_.debugClassName
			else
				return p111_.debugServerId < p112_.debugServerId
			end
		end)
		local v113_ = 0.015
		local v114_ = string.format("Registered Objects: %d | Objects in update-loop: %d | Update time: %.3f ms", #v106_, v104_, self.updateDurationTotalTime)
		setTextColor(0, 0, 0, 1)
		renderText(v113_ + g_pixelSizeX, 0.98 + g_pixelSizeY, 0.013, v114_)
		setTextColor(1, 1, 1, 1)
		renderText(v113_, 0.98, 0.013, v114_)
		local v115_ = 0.96
		for _, v116_ in ipairs(v106_) do
			if v116_.networkDebugFilename == nil then
				local v117_ = v116_.configFileName or v116_.xmlFilename
				if v117_ == nil then
					v116_.networkDebugFilename = "<unknown file>"
				else
					v116_.networkDebugFilename = Utils.getFilenameFromPath(v117_)
				end
			end
			local v118_ = v116_.debugServerId
			local v119_ = tostring(v118_)
			local v120_ = string.format
			local v121_ = v116_.debugClassName
			local v122_ = v116_.networkDebugFilename
			local v123_ = v120_(" - %s - %s", v121_, (tostring(v122_)))
			local v124_ = self.activeObjects[v116_.debugServerId] ~= nil
			local v125_, v126_
			if v116_.profilerUpdateTime == nil then
				v125_ = 0.1254
				v126_ = 0.7647
			else
				v123_ = string.format("%s (%.3f ms)", v123_, v116_.profilerUpdateTime)
				local v127_ = v116_.profilerUpdateTime / 1
				v125_ = math.clamp(v127_, 0, 1)
				v126_ = 1 - v125_
			end
			setTextBold(v124_)
			setTextColor(0, 0, 0, 1)
			renderText(v113_ + g_pixelSizeX, v115_ + g_pixelSizeY, 0.01, v123_)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(v113_ + g_pixelSizeX, v115_ + g_pixelSizeY, 0.01, v119_)
			if v124_ then
				setTextColor(v125_, v126_, 0, 1)
			else
				setTextColor(1, 1, 1, 1)
			end
			renderText(v113_, v115_, 0.01, v119_)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(v113_, v115_, 0.01, v123_)
			v115_ = v115_ - 0.011
			if v115_ < 0 then
				v113_ = v113_ + 0.14
				v115_ = 0.96
			end
		end
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
	end
end

function NetworkNode:packetReceived(packetType, timestamp, streamId) end

function NetworkNode:getObject(id)
	return self.objects[id]
end

function NetworkNode:getObjectId(object)
	return self.objectIds[object]
end

function NetworkNode:addObject(object, id)
	self.objects[id] = object
	self.objectIds[object] = id
	self:addObjectToUpdateLoop(object)
	if self.networkListener ~= nil then
		self.networkListener:onObjectCreated(object)
	end
end

function NetworkNode:removeObject(object, id)
	self:removeObjectFromUpdateLoop(object)
	if self.networkListener ~= nil then
		self.networkListener:onObjectDeleted(object)
	end
	self.objects[id] = nil
	self.objectIds[object] = nil
end

-- Local values: id
function NetworkNode:addObjectToUpdateLoop(object)
	if object.isRegistered then
		local v140_ = self.objectIds[object]
		if v140_ ~= nil then
			self.activeObjects[v140_] = object
			self.activeObjectsNextFrame[v140_] = object
		end
	end
end

-- Local values: id
function NetworkNode:removeObjectFromUpdateLoop(object)
	local v143_ = self.objectIds[object]
	if v143_ ~= nil then
		self.removedObjects[v143_] = object
		self.activeObjects[v143_] = nil
		self.activeObjectsNextFrame[v143_] = nil
	end
end

function NetworkNode:registerObject(object, alreadySent) end

function NetworkNode:unregisterObject(object, alreadySent) end

function NetworkNode:consoleCommandToggleNetworkShowObjects(sortByClassName)
	self.showObjects = not self.showObjects
	self.debugSortByClassName = string.lower(sortByClassName or "true") == "true"
	if self.showObjects then
		g_debugManager:addDrawable(self)
	end
	local v146_ = self.showObjects
	return "NetworkShowObjects = " .. tostring(v146_)
end

function NetworkNode:consoleCommandToggleShowNetworkTraffic()
	self.showNetworkTraffic = not self.showNetworkTraffic
	if self.showNetworkTraffic then
		g_debugManager:addDrawable(self)
	end
	local v148_ = self.showNetworkTraffic
	return "ShowNetworkTraffic = " .. tostring(v148_)
end

function NetworkNode:consoleCommandToggleShowNetworkTrafficClients()
	self.showNetworkTrafficClients = not self.showNetworkTrafficClients
	if self.showNetworkTrafficClients then
		g_debugManager:addDrawable(self)
	end
	local v150_ = self.showNetworkTrafficClients
	return "ShowNetworkTrafficClients = " .. tostring(v150_)
end
