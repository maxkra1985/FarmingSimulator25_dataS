-- Local values: DebugSpline_mt
DebugSpline = {}
DebugSpline.EP_SPLINE_TIMES_TABLE = {}
local DebugSpline_mt = Class(DebugSpline, DebugElement)

-- Upvalues: DebugSpline_mt
-- Local values: self
function DebugSpline.new(customMt)
	-- upvalues: (copy) DebugSpline_mt
	local v3_ = DebugSpline:superClass().new(customMt or DebugSpline_mt)
	v3_.splineNodeId = nil
	v3_.splineBvCenter = { 0, 0, 0 }
	v3_.splineBVRadius = 1
	v3_.solid = false
	v3_.displayEPs = false
	v3_.alignToGround = false
	v3_.defaultText = nil
	v3_.userAttributesStr = nil
	v3_.closestCamSplineTime = 0
	v3_.closestCamPosX = 0
	v3_.closestCamPosY = 0
	v3_.closestCamPosZ = 0
	v3_:setTextClipDistance(50)
	return v3_
end

function DebugSpline:delete()
	setVisibility(self.splineNodeId, false)
end

-- Local values: camX, camY, camZ, distanceCamToBvCenter
function DebugSpline:getShouldBeUpdated()
	if self.clipDistance ~= nil then
		local v6_, v7_, v8_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		if MathUtil.vector3Length(v6_ - self.splineBvCenter[1], v7_ - self.splineBvCenter[2], v8_ - self.splineBvCenter[3]) > self.splineBVRadius + self.clipDistance then
			return false
		end
	end
	return true
end

-- Local values: dx, dy, dz
function DebugSpline:update(dt)
	if self.splineNodeId ~= nil then
		local v10_, v11_, v12_, v13_ = DebugSpline.getClosestSplinePosAndTimeToCamera(self.splineNodeId, self.splineLength)
		self.closestCamPosX = v10_
		self.closestCamPosY = v11_
		self.closestCamPosZ = v12_
		self.closestCamSplineTime = v13_
		if self.text == nil then
			local v14_, v15_, v16_ = getSplineDirection(self.splineNodeId, self.closestCamSplineTime)
			local v17_ = string.format
			local v18_ = getName(self.splineNodeId)
			local v19_ = self.splineNodeId
			local v20_ = self.splineLength
			local v21_ = getIsSplineClosed
			local v22_ = self.splineNodeId
			self.defaultText = v17_("\'%s\' (id=%d) \nl=%.2fm closed=%s numCVs=%d \nt=%.3f p=%.2fm d=%.3f %.3f %.3f%s", v18_, v19_, v20_, tostring(v21_(v22_)), getSplineNumOfCV(self.splineNodeId), self.closestCamSplineTime, self.closestCamSplineTime * self.splineLength, v14_, v15_, v16_, self.userAttributesStr or "")
		end
	end
end

-- Local values: camX, camY, camZ, eps, closestCamPosX, closestCamPosY, closestCamPosZ, closestCamSplineTime, splinePos, offsetSplineTime
function DebugSpline.getClosestSplinePosAndTimeToCamera(spline, splineLength)
	local v25_, v26_, v27_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v28_ = 0.01 / splineLength
	local v29_, v30_, v31_, v32_ = getClosestSplinePosition(spline, v25_, v26_, v27_, v28_)
	local v33_ = v32_ * splineLength
	if v33_ < 1 or splineLength - 1 < v33_ then
		local v34_ = splineLength / 3
		local v35_ = math.min(1, v34_) / splineLength
		local v36_ = 1 - v35_
		v32_ = math.clamp(v32_, v35_, v36_)
		v29_, v30_, v31_ = getSplinePosition(spline, v32_)
	end
	return v29_, v30_, v31_, v32_
end

function DebugSpline:getShouldBeDrawn()
	if g_gui == nil or not g_gui:getIsGuiVisible() then
		return (not self.clipDistance or DebugUtil.isPositionInCameraRange(self.closestCamPosX, self.closestCamPosY, self.closestCamPosZ, self.clipDistance)) and true or false
	else
		return false
	end
end

function DebugSpline:draw()
	DebugSpline.renderForNode(self.splineNodeId, self.color, self.text or self.defaultText, self.clipDistance, self.displayEPs, self.closestCamSplineTime, self.closestCamPosX, self.closestCamPosY, self.closestCamPosZ, self.textClipDistance)
end

-- Local values: r, g, b, a, x, y, z, dx, _dy, dz, offsetFactor, offset, numCVs, epIndex, nextSmallerEPIndex, nextLargerEPIndex, epIndex, splineTime
function DebugSpline.renderForNode(splineNodeId, color, text, clipDistance, displayEPs, closestCamSplineTime, closestCamPosX, closestCamPosY, closestCamPosZ, textClipDistance)
	if closestCamSplineTime == nil then
		closestCamPosX, closestCamPosY, closestCamPosZ, closestCamSplineTime = DebugSpline.getClosestSplinePosAndTimeToCamera(splineNodeId, getSplineLength(splineNodeId))
	end
	if DebugUtil.isPositionInCameraRange(closestCamPosX, closestCamPosY, closestCamPosZ, clipDistance) then
		local v49_, v50_, v51_, v52_
		if color == nil then
			v49_ = 1
			v50_ = 1
			v51_ = 1
			v52_ = 1
		else
			v50_, v51_, v52_, v49_ = color:unpack()
		end
		local v53_, v54_, v55_ = getSplinePosition(splineNodeId, 0)
		drawDebugPoint(v53_, v54_, v55_, 0, 1, 0, 1, false)
		local v56_, v57_, v58_ = getSplinePosition(splineNodeId, 1)
		drawDebugPoint(v56_, v57_, v58_, 1, 0, 0, 1, false)
		if closestCamSplineTime > 0 and closestCamSplineTime < 1 then
			drawDebugPoint(closestCamPosX, closestCamPosY, closestCamPosZ, v50_, v51_, v52_, v49_, false)
		end
		if text ~= nil and (textClipDistance == nil or DebugUtil.isPositionInCameraRange(closestCamPosX, closestCamPosY, closestCamPosZ, textClipDistance)) then
			local v59_, _, v60_ = getSplineDirection(splineNodeId, closestCamSplineTime)
			local v61_ = MathUtil.getYRotationFromDirection(v59_ + 0.001, v60_) / 3.141592653589793
			local v62_ = getTextHeight(0.016, text) * v61_
			Utils.renderTextAtWorldPosition(closestCamPosX, closestCamPosY, closestCamPosZ, text, 0.016, v62_, v50_, v51_, v52_)
		end
		if displayEPs then
			local v63_ = getSplineNumOfCV(splineNodeId)
			for v64_ = 1, v63_ - 2 do
				local v65_, v66_, v67_ = getSplineEP(splineNodeId, v64_)
				drawDebugPoint(v65_, v66_, v67_, 1, 1, 1, 0.2, false)
				DebugSpline.EP_SPLINE_TIMES_TABLE[v64_] = getTimeAtSplineCV(splineNodeId, v64_)
			end
			local v68_ = -1
			local v69_ = math.huge
			for v70_ = 1, v63_ - 2 do
				if DebugSpline.EP_SPLINE_TIMES_TABLE[v70_] < closestCamSplineTime then
					if v68_ < v70_ then
						v68_ = v70_
					end
				elseif v70_ < v69_ then
					v69_ = v70_
				end
			end
			if v68_ ~= -1 then
				local v71_, v72_, v73_ = getSplineEP(splineNodeId, v68_)
				if textClipDistance == nil or DebugUtil.isPositionInCameraRange(v71_, v72_, v73_, textClipDistance) then
					Utils.renderTextAtWorldPosition(v71_, v72_, v73_, "EP " .. tostring(v68_), 0.012, 0.01, Color.PRESETS.LIGHTGRAY:unpack())
				end
			end
			if v69_ ~= math.huge then
				local v74_, v75_, v76_ = getSplineEP(splineNodeId, v69_)
				if textClipDistance == nil or DebugUtil.isPositionInCameraRange(v74_, v75_, v76_, textClipDistance) then
					Utils.renderTextAtWorldPosition(v74_, v75_, v76_, "EP " .. tostring(v69_), 0.012, 0.01, Color.PRESETS.LIGHTGRAY:unpack())
				end
			end
		end
	end
end

-- Local values: x, y, z, radius, userAttributesStr, uaIndex, value, name, uaType
function DebugSpline:createWithNode(spline, color, clipDistance, displayEPs)
	self.splineNodeId = spline
	if not getEffectiveVisibility(spline) then
		DebugUtil.setNodeEffectivelyVisible(spline)
	end
	local v82_, v83_, v84_, v85_ = getShapeWorldBoundingSphere(self.splineNodeId)
	self.splineBvCenter = { v82_, v83_, v84_ }
	self.splineBVRadius = v85_
	self.splineLength = getSplineLength(self.splineNodeId)
	local v86_ = nil
	for v87_ = 0, getNumOfUserAttributes(spline) - 1 do
		local v88_, v89_, v90_ = getUserAttributeByIndex(spline, v87_)
		if v90_ == UserAttributeType.FLOAT then
			v88_ = string.format("%.3f", v88_)
		elseif v90_ == UserAttributeType.INTEGER or v90_ == UserAttributeType.NODE_ID then
			v88_ = string.format("%d", v88_)
		end
		v86_ = (v86_ or "") .. string.format("\n%s=%s (%s)", v89_, v88_, EnumUtil.getName(UserAttributeType, v90_))
	end
	self.userAttributesStr = v86_
	if color ~= nil then
		self:setColor(color)
	end
	self.clipDistance = Utils.getNoNil(clipDistance, self.clipDistance)
	self.displayEPs = Utils.getNoNil(displayEPs, self.displayEPs)
	return self
end
