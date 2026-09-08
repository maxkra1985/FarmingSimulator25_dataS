-- Local values: CameraPath_mt
CameraPath = {}
local CameraPath_mt = Class(CameraPath)

-- Upvalues: CameraPath_mt
-- Local values: self
function CameraPath.new(posAnimCurve, rotAnimCurve, speedAnimCurve, speedScale, camera, maxTime, finishedCallback)
	-- upvalues: (copy) CameraPath_mt
	local v9_ = CameraPath_mt
	local v10_ = setmetatable({}, v9_)
	v10_.posAnimCurve = posAnimCurve
	v10_.rotAnimCurve = rotAnimCurve
	v10_.speedAnimCurve = speedAnimCurve
	v10_.speedScale = speedScale
	v10_.time = 0
	v10_.camera = camera
	v10_.overriddenCamera = nil
	v10_.maxTime = maxTime
	v10_.finishedCallback = finishedCallback
	g_cameraManager:addCamera(camera, nil, false)
	return v10_
end

function CameraPath:delete()
	g_cameraManager:removeCamera(self.camera)
	delete(self.camera)
end

-- Local values: rootNode, positionNodes, posAnimCurve, rotAnimCurve, speedAnimCurve, num, t, lastX, lastY, lastZ, i, node, x, y, z, rx, ry, rz, speed, _, _, dist, qx, qy, qz, qw, numSegments, segmentTimes, i, keyframe1, keyframe2, d, lastKfX, lastKfY, lastKfZ, segmentOffset, a, x, y, z, dist
function CameraPath.createFromI3D(filename, speedScale, camera)
	local v15_ = g_i3DManager:loadI3DFile(filename, false, false)
	local v16_ = getChild(v15_, "positions")
	if v16_ == 0 then
		printError("Error: failed to load camera path: " .. filename .. ". No positions found.")
		return nil
	end
	local v17_ = AnimCurve.new(catmullRomInterpolator3, 3)
	local v18_ = AnimCurve.new(quaternionInterpolator2, 3)
	local v19_ = AnimCurve.new(catmullRomInterpolator1, 3)
	local v20_ = nil
	local v21_ = nil
	local v22_ = nil
	local v23_ = 0
	for v24_ = 0, getNumOfChildren(v16_) - 1 do
		local v25_ = getChildAt(v16_, v24_)
		local v26_, v27_, v28_ = getTranslation(v25_)
		local v29_, v30_, v31_ = getRotation(v25_)
		local v32_, _, _ = getScale(v25_)
		if v24_ > 0 then
			v23_ = v23_ + MathUtil.vector3Length(v26_ - v20_, v27_ - v21_, v28_ - v22_)
		end
		v17_:addKeyframe({
			["time"] = v23_,
			["x"] = v26_,
			["y"] = v27_,
			["z"] = v28_
		})
		local v33_, v34_, v35_, v36_ = mathEulerToQuaternion(v29_, v30_, v31_)
		v18_:addKeyframe({
			["time"] = v23_,
			["x"] = v33_,
			["y"] = v34_,
			["z"] = v35_,
			["w"] = v36_
		})
		v19_:addKeyframe({
			["time"] = v23_,
			["v"] = v32_
		})
		v22_ = v28_
		v21_ = v27_
		v20_ = v26_
	end
	local v37_ = {}
	local v38_ = 0
	local v39_ = 32
	for v40_ = 1, #v17_.keyframes - 1 do
		local v41_ = v17_.keyframes[v40_]
		local v42_ = v17_.keyframes[v40_ + 1]
		local v43_, v44_, v45_ = v17_:getFromKeyframes(v41_, v42_, v40_, v40_ + 1, 1)
		local v46_ = (v40_ - 1) * 33 + 1
		v37_[v46_] = 0
		local v47_ = 0
		for v48_ = 1, 32 do
			local v49_, v50_, v51_ = v17_:getFromKeyframes(v41_, v42_, v40_, v40_ + 1, 1 - v48_ / 32)
			v47_ = v47_ + MathUtil.vector3Length(v49_ - v43_, v50_ - v44_, v51_ - v45_)
			v37_[v46_ + v48_] = v47_
			v45_ = v51_
			v44_ = v50_
			v43_ = v49_
		end
		v38_ = v38_ + v47_
		v17_.keyframes[v40_ + 1].time = v38_
		v18_.keyframes[v40_ + 1].time = v38_
		v19_.keyframes[v40_ + 1].time = v38_
	end
	v17_.segmentTimes = v37_
	v17_.numTimesPerKeyframe = v39_
	v18_.segmentTimes = v37_
	v18_.numTimesPerKeyframe = v39_
	v19_.segmentTimes = v37_
	v19_.numTimesPerKeyframe = v39_
	v17_.maxTime = v38_
	v18_.maxTime = v38_
	v19_.maxTime = v38_
	delete(v15_)
	return CameraPath.new(v17_, v18_, v19_, speedScale, camera, v38_)
end

-- Local values: speedScale, currentCamera
function CameraPath:update(dt)
	local v54_ = self.speedScale
	if self.speedAnimCurve ~= nil then
		v54_ = v54_ * self.speedAnimCurve:get(self.time)
	end
	self.time = self.time + dt * v54_
	self:placeCamera()
	local v55_ = g_cameraManager:getActiveCamera()
	if v55_ ~= self.camera then
		self.overriddenCamera = v55_
		g_cameraManager:setActiveCamera(self.camera)
	end
	if self.finishedCallback ~= nil and self.time > self.maxTime then
		self.finishedCallback()
	end
end

-- Local values: x, y, z, qx, qy, qz, qw
function CameraPath:placeCamera()
	local v57_, v58_, v59_ = self.posAnimCurve:get(self.time)
	local v60_, v61_, v62_, v63_ = self.rotAnimCurve:get(self.time)
	setTranslation(self.camera, v57_, v58_, v59_)
	setQuaternion(self.camera, v60_, v61_, v62_, v63_)
end

function CameraPath:activate()
	self:placeCamera()
	self.overriddenCamera = g_cameraManager:getActiveCamera()
	g_cameraManager:setActiveCamera(self.camera)
end

function CameraPath:deactivate()
	self.time = 0
	if self.overriddenCamera ~= nil then
		g_cameraManager:setActiveCamera(self.overriddenCamera)
	end
	g_currentMission:removeUpdateable(self)
end
