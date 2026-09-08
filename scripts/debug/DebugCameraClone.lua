-- Local values: DebugCameraClone_mt
DebugCameraClone = {}
DebugCameraClone.MAX_CAMERAS = 16
local DebugCameraClone_mt = Class(DebugCameraClone, Object)
InitStaticObjectClass(DebugCameraClone, "DebugCameraClone")

-- Upvalues: DebugCameraClone_mt
-- Local values: self, i, data
function DebugCameraClone.new(isServer, isClient, customMt)
	-- upvalues: (copy) DebugCameraClone_mt
	local v5_ = Object.new(isServer, isClient, customMt or DebugCameraClone_mt)
	if isServer then
		v5_.cameras = {}
		for v6_ = 0, DebugCameraClone.MAX_CAMERAS + 1 do
			v5_.cameras[v6_] = {
				["x"] = 0,
				["y"] = 0,
				["z"] = 0,
				["qx"] = 0,
				["qy"] = 0,
				["qz"] = 0,
				["qw"] = 1,
				["fovY"] = 1.0471975511965976,
				["nearClip"] = 0.1,
				["farClip"] = 5000
			}
		end
	end
	v5_.interpolatorPosition = InterpolatorPosition.new(0, 0, 0)
	v5_.interpolatorQuaternion = InterpolatorQuaternion.new(0, 0, 0, 1)
	v5_.interpolatorTime = InterpolationTime.new(1.2)
	v5_.fovY = 1.0471975511965976
	v5_.nearClip = 0.1
	v5_.farClip = 5000
	v5_.dirtyFlag = v5_:getNextDirtyFlag()
	v5_.camera = createCamera("DebugCameraClone", 1.0471975511965976, 1, 10000)
	local v7_ = StartParams.getValue
	v5_.cameraIndex = tonumber(v7_("debugCameraCloneIndex"))
	g_cameraManager:addCamera(v5_.camera, nil, false)
	v5_.connectionToCameraIndex = {}
	v5_.lastCamera = g_cameraManager:getActiveCamera()
	addConsoleCommand("gsDebugCameraCloneSetIndex", "Sets the camera clone index", "consoleCommandSetCameraCloneIndex", v5_)
	return v5_
end

function DebugCameraClone:delete()
	removeConsoleCommand("gsDebugCameraCloneSetIndex")
end

-- Local values: x, y, z, qx, qy, qz, qw, fovY, nearClip, farClip, clientIndex, index, clientStreamId, data
function DebugCameraClone:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local v11_ = streamReadFloat32(streamId)
			local v12_ = streamReadFloat32(streamId)
			local v13_ = streamReadFloat32(streamId)
			local v14_ = streamReadFloat32(streamId)
			local v15_ = streamReadFloat32(streamId)
			local v16_ = streamReadFloat32(streamId)
			local v17_ = streamReadFloat32(streamId)
			local v18_ = streamReadFloat32(streamId)
			local v19_ = streamReadFloat32(streamId)
			local v20_ = streamReadFloat32(streamId)
			self.interpolatorPosition:setTargetPosition(v11_, v12_, v13_)
			self.interpolatorQuaternion:setTargetQuaternion(v14_, v15_, v16_, v17_)
			self.interpolatorTime:startNewPhaseNetwork()
			self.fovY = v18_
			self.nearClip = v19_
			self.farClip = v20_
			return
		end
	else
		local v21_ = 1
		for v22_, v23_ in ipairs(g_server.clients) do
			if v23_ == streamId then
				v21_ = v22_
				break
			end
		end
		if streamReadBool(streamId) then
			self.connectionToCameraIndex[connection] = streamReadUIntN(streamId, 5)
		else
			self.connectionToCameraIndex[connection] = nil
		end
		local v24_ = self.cameras[v21_]
		v24_.x = streamReadFloat32(streamId)
		v24_.y = streamReadFloat32(streamId)
		v24_.z = streamReadFloat32(streamId)
		v24_.qx = streamReadFloat32(streamId)
		v24_.qy = streamReadFloat32(streamId)
		v24_.qz = streamReadFloat32(streamId)
		v24_.qw = streamReadFloat32(streamId)
		v24_.fovY = streamReadFloat32(streamId)
		v24_.nearClip = streamReadFloat32(streamId)
		v24_.farClip = streamReadFloat32(streamId)
	end
end

-- Local values: cameraIndex, data, camera, x, y, z, qx, qy, qz, qw, fovY, nearClip, farClip
function DebugCameraClone:writeUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local v28_ = g_cameraManager:getActiveCamera()
		local v29_, v30_, v31_ = getWorldTranslation(v28_)
		local v32_, v33_, v34_, v35_ = getWorldQuaternion(v28_)
		local v36_ = getFovY(v28_)
		local v37_ = getNearClip(v28_)
		local v38_ = getFarClip(v28_)
		if streamWriteBool(streamId, self.cameraIndex ~= nil) then
			streamWriteUIntN(streamId, self.cameraIndex, 5)
		end
		streamWriteFloat32(streamId, v29_)
		streamWriteFloat32(streamId, v30_)
		streamWriteFloat32(streamId, v31_)
		streamWriteFloat32(streamId, v32_)
		streamWriteFloat32(streamId, v33_)
		streamWriteFloat32(streamId, v34_)
		streamWriteFloat32(streamId, v35_)
		streamWriteFloat32(streamId, v36_)
		streamWriteFloat32(streamId, v37_)
		streamWriteFloat32(streamId, v38_)
	else
		local v39_ = self.connectionToCameraIndex[connection]
		local v40_ = self.cameras[v39_]
		if streamWriteBool(streamId, v40_ ~= nil) then
			streamWriteFloat32(streamId, v40_.x)
			streamWriteFloat32(streamId, v40_.y)
			streamWriteFloat32(streamId, v40_.z)
			streamWriteFloat32(streamId, v40_.qx)
			streamWriteFloat32(streamId, v40_.qy)
			streamWriteFloat32(streamId, v40_.qz)
			streamWriteFloat32(streamId, v40_.qw)
			streamWriteFloat32(streamId, v40_.fovY)
			streamWriteFloat32(streamId, v40_.nearClip)
			streamWriteFloat32(streamId, v40_.farClip)
			return
		end
	end
end

-- Local values: data, camera, camera, interpolationAlpha, x, y, z, qx, qy, qz, qw, x, _, z, _, player, a, _, c, distance, shouldHide
function DebugCameraClone:update(dt)
	self:raiseDirtyFlags(self.dirtyFlag)
	self:raiseActive()
	if self.isServer then
		local v43_ = self.cameras[0]
		local v44_ = g_cameraManager:getActiveCamera()
		local v45_, v46_, v47_ = getWorldTranslation(v44_)
		v43_.x = v45_
		v43_.y = v46_
		v43_.z = v47_
		local v48_, v49_, v50_, v51_ = getWorldQuaternion(v44_)
		v43_.qx = v48_
		v43_.qy = v49_
		v43_.qz = v50_
		v43_.qw = v51_
		v43_.fovY = getFovY(v44_)
		v43_.nearClip = getNearClip(v44_)
		v43_.farClip = getFarClip(v44_)
	end
	local v52_ = g_cameraManager:getActiveCamera()
	if v52_ ~= self.camera then
		self.lastCamera = v52_
	end
	if self.cameraIndex ~= nil then
		self.interpolatorTime:update(dt)
		local v53_ = self.interpolatorTime:getAlpha()
		local v54_, v55_, v56_ = self.interpolatorPosition:getInterpolatedValues(v53_)
		local v57_, v58_, v59_, v60_ = self.interpolatorQuaternion:getInterpolatedValues(v53_)
		setWorldTranslation(self.camera, v54_, v55_, v56_)
		setWorldQuaternion(self.camera, v57_, v58_, v59_, v60_)
		setFovY(self.camera, self.fovY)
		setNearClip(self.camera, self.nearClip)
		setFarClip(self.camera, self.farClip)
		g_cameraManager:setActiveCamera(self.camera)
	end
	local v61_, _, v62_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	for _, v63_ in pairs(g_currentMission.players) do
		if v63_ ~= g_localPlayer then
			local v64_, _, v65_ = getWorldTranslation(v63_.graphicsRootNode)
			local v66_ = MathUtil.vector2Length(v61_ - v64_, v62_ - v65_)
			local v67_
			if self.cameraIndex == nil then
				v67_ = false
			else
				v67_ = v66_ < 1
			end
			setVisibility(v63_.graphicsRootNode, not v67_)
		end
	end
end

function DebugCameraClone:consoleCommandSetCameraCloneIndex(index)
	local v70_ = tonumber(index)
	if v70_ ~= nil and (v70_ < 0 or DebugCameraClone.MAX_CAMERAS < v70_) then
		v70_ = nil
	end
	self.cameraIndex = v70_
	if self.lastCamera ~= nil and entityExists(self.lastCamera) then
		g_cameraManager:setActiveCamera(self.lastCamera)
	end
end
