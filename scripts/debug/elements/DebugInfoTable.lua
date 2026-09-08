-- Local values: DebugInfoTable_mt
DebugInfoTable = {}
local DebugInfoTable_mt = Class(DebugInfoTable, DebugElement)

-- Upvalues: DebugInfoTable_mt
-- Local values: self
function DebugInfoTable.new(customMt)
	-- upvalues: (copy) DebugInfoTable_mt
	local v3_ = DebugInfoTable:superClass().new(customMt or DebugInfoTable_mt)
	v3_.rotX = 0
	v3_.rotY = 0
	v3_.rotZ = 0
	v3_.size = 0.25
	v3_.information = nil
	v3_.text = nil
	v3_.alignToGround = false
	return v3_
end

function DebugInfoTable:draw()
	DebugInfoTable.renderAtPosition(self.x, self.y, self.z, self.information, self.rotX, self.rotY, self.rotZ, self.size, self.color)
end

-- Local values: yOffset, i, info, title, content, j, pair, key, value, lineSize
function DebugInfoTable.renderAtPosition(x, y, z, information, rx, ry, rz, size, color)
	setTextDepthTestEnabled(false)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	if color ~= nil then
		setTextColor(color:unpack())
	end
	setTextBold(false)
	if rx == nil then
		ry = DebugUtil.getYRotatationToCamera(x, y, z)
		rx = 0
		rz = 0
	end
	local v14_ = size or 0.5
	local v15_ = 0
	for v16_ = #information, 1, -1 do
		local v17_ = information[v16_]
		local v18_ = v17_.title
		local v19_ = v17_.content
		for v20_ = #v19_, 1, -1 do
			local v21_ = v19_[v20_]
			local v22_ = v21_.name
			local v23_ = v21_.value
			if v21_.color ~= nil then
				setTextColor(v21_.color:unpack())
			end
			local v24_ = v14_ * (v21_.sizeFactor or 1)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText3D(x, y + v15_, z, rx, ry, rz, v24_, v22_)
			setTextAlignment(RenderText.ALIGN_LEFT)
			if type(v23_) == "number" then
				renderText3D(x, y + v15_, z, rx, ry, rz, v24_, " " .. string.format("%.4f", v23_))
			else
				renderText3D(x, y + v15_, z, rx, ry, rz, v24_, " " .. tostring(v23_))
			end
			if v21_.color ~= nil then
				setTextColor(color:unpack())
			end
			v15_ = v15_ + v24_
		end
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		renderText3D(x, y + v15_, z, rx, ry, rz, v14_, v18_)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		v15_ = v15_ + 2 * v14_
	end
	setTextDepthTestEnabled(true)
end

-- Local values: x, y, z
function DebugInfoTable.renderAtNode(node, information, size, color)
	local v29_, v30_, v31_ = getWorldTranslation(node)
	DebugInfoTable.renderAtPosition(v29_, v30_, v31_, information, nil, nil, nil, size, color)
end

-- Local values: x, y, z, rotX, rotY, rotZ
function DebugInfoTable:createWithNode(node, information, size)
	local v36_, v37_, v38_ = getWorldTranslation(node)
	local v39_, v40_, v41_ = getWorldRotation(node)
	self:createWithWorldPosAndRot(v36_, v37_, v38_, v39_, v40_, v41_, information, size)
	return self
end

-- Local values: x, y, z, cx, cy, cz, dirX, _, dirZ, rotY
function DebugInfoTable:createWithNodeToCamera(node, information, yOffset, size)
	local v47_, v48_, v49_ = localToWorld(node, 0, yOffset or 0, 0)
	local v50_, v51_, v52_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v53_, _, v54_ = MathUtil.vector3Normalize(v50_ - v47_, v51_ - v48_, v52_ - v49_)
	self:createWithWorldPosAndRot(v47_, v48_, v49_, 0, MathUtil.getYRotationFromDirection(v53_, v54_), 0, information, size or 0.05)
	return self
end

function DebugInfoTable:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, information, size)
	self.x = x
	self.y = y
	self.z = z
	self.rotX = rotX
	self.rotY = rotY
	self.rotZ = rotZ
	self.information = information
	self.size = (size or 0.05) * 2.5
	return self
end
