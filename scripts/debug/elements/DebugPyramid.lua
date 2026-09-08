-- Local values: DebugPyramid_mt
DebugPyramid = {}
local DebugPyramid_mt = Class(DebugPyramid, DebugBox)
DebugPyramid.STATIC_CALL_POSITIONS_TABLE = {
	Vector3.new(-0.5, -0.5, -0.5),
	Vector3.new(0.5, -0.5, -0.5),
	Vector3.new(0.5, -0.5, 0.5),
	Vector3.new(-0.5, -0.5, 0.5),
	Vector3.new(0, 0.5, 0)
}

-- Upvalues: DebugPyramid_mt
-- Local values: self
function DebugPyramid.new(customMt)
	-- upvalues: (copy) DebugPyramid_mt
	local v3_ = DebugPyramid:superClass().new(customMt or DebugPyramid_mt)
	v3_.cornerPositions = nil
	return v3_
end

function DebugPyramid:draw()
	DebugPyramid.renderAtPosition(self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ, self.color, self.solid, self.text, self.textSize, self.drawFaces, self.cornerPositions)
end

-- Local values: r, g, b, a, pos, offset, sx, sy, sz, dirNx, dirNy, dirNz, normX, normY, normZ, upNx, upNy, upNz, norSx, norSy, norSz, upSx, upSy, upSz, dirSx, dirSy, dirSz, toWorld, point01, point02, point03, point04, point05, axisXEnd, axisZEnd
function DebugPyramid.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces, positions)
	local v23_, v24_, v25_, v26_
	if color == nil then
		v23_ = 1
		v24_ = 1
		v25_ = 1
		v26_ = 1
	else
		v25_, v24_, v26_, v23_ = color:unpack()
	end
	local v27_ = solid == nil and true or solid
	local v28_ = positions or DebugPyramid.STATIC_CALL_POSITIONS_TABLE
	local v_u_29_
	if x == nil or (y == nil or z == nil) then
		v_u_29_ = vector.zero
	else
		v_u_29_ = vector.create(x, y, z)
	end
	local v30_ = (sizeX == nil or not sizeX) and 1 or sizeX
	local v31_ = (sizeY == nil or not sizeY) and 1 or sizeY
	local v32_ = (sizeZ == nil or not sizeZ) and 1 or sizeZ
	local v33_, v34_, v35_ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
	local v36_, v37_, v38_ = MathUtil.crossProduct(upX, upY, upZ, v33_, v34_, v35_)
	local v39_, v40_, v41_ = MathUtil.vector3Normalize(v36_, v37_, v38_)
	local v42_, v43_, v44_ = MathUtil.crossProduct(v33_, v34_, v35_, v39_, v40_, v41_)
	local v45_, v46_, v47_ = MathUtil.vector3Normalize(v42_, v43_, v44_)
	local v_u_48_ = v39_ * v30_
	local v_u_49_ = v40_ * v30_
	local v_u_50_ = v41_ * v30_
	local v_u_51_ = v45_ * v31_
	local v_u_52_ = v46_ * v31_
	local v_u_53_ = v47_ * v31_
	local v_u_54_ = v33_ * v32_
	local v_u_55_ = v34_ * v32_
	local v_u_56_ = v35_ * v32_
	local function v61_(p57_)
		-- upvalues: (ref) v_u_29_, (copy) v_u_48_, (copy) v_u_51_, (copy) v_u_54_, (copy) v_u_49_, (copy) v_u_52_, (copy) v_u_55_, (copy) v_u_50_, (copy) v_u_53_, (copy) v_u_56_
		local v58_ = v_u_29_.x + p57_.x * v_u_48_ + p57_.y * v_u_51_ + p57_.z * v_u_54_
		local v59_ = v_u_29_.y + p57_.x * v_u_49_ + p57_.y * v_u_52_ + p57_.z * v_u_55_
		local v60_ = v_u_29_.z + p57_.x * v_u_50_ + p57_.y * v_u_53_ + p57_.z * v_u_56_
		return vector.create(v58_, v59_, v60_)
	end
	local v62_ = v61_(v28_[1])
	local v63_ = v61_(v28_[2])
	local v64_ = v61_(v28_[3])
	local v65_ = v61_(v28_[4])
	local v66_ = v61_(v28_[5])
	drawDebugLineVector(v62_, v25_, v24_, v26_, v63_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v63_, v25_, v24_, v26_, v64_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v64_, v25_, v24_, v26_, v65_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v65_, v25_, v24_, v26_, v62_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v62_, v25_, v24_, v26_, v66_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v63_, v25_, v24_, v26_, v66_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v64_, v25_, v24_, v26_, v66_, v25_, v24_, v26_, v27_)
	drawDebugLineVector(v65_, v25_, v24_, v26_, v66_, v25_, v24_, v26_, v27_)
	if drawFaces then
		drawDebugTriangleVector(v62_, v63_, v64_, v25_, v24_, v26_, 0.1, v27_)
		drawDebugTriangleVector(v62_, v64_, v65_, v25_, v24_, v26_, 0.1, v27_)
		drawDebugTriangleVector(v62_, v66_, v63_, v25_, v24_, v26_, 0.3, v27_)
		drawDebugTriangleVector(v63_, v66_, v64_, v25_, v24_, v26_, 0.5, v27_)
		drawDebugTriangleVector(v64_, v66_, v65_, v25_, v24_, v26_, 0.4, v27_)
		drawDebugTriangleVector(v65_, v66_, v62_, v25_, v24_, v26_, 0.7, v27_)
	end
	local v67_ = v_u_29_ + (v63_ - v62_)
	local v68_ = v_u_29_ + (v65_ - v62_)
	drawDebugLineVector(v_u_29_, 1, 0, 0, v67_, 1, 0, 0, v27_)
	drawDebugLineVector(v_u_29_, 0, 1, 0, v66_, 0, 1, 0, v27_)
	drawDebugLineVector(v_u_29_, 0, 0, 1, v68_, 0, 0, 1, v27_)
	if text ~= nil then
		Utils.renderTextAtWorldPosition(v66_.x, v66_.y, v66_.z, text, textSize or 0.016, nil, v25_, v24_, v26_, v23_)
	end
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugPyramid.renderAtNode(node, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v78_, v79_, v80_ = getWorldTranslation(node)
	local v81_, v82_, v83_ = localDirectionToWorld(node, 0, 1, 0)
	local v84_, v85_, v86_ = localDirectionToWorld(node, 0, 0, 1)
	DebugPyramid.renderAtPosition(v78_, v79_, v80_, v81_, v82_, v83_, v84_, v85_, v86_, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugPyramid.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v99_, v100_, v101_ = localToWorld(node, offsetX, offsetY, offsetZ)
	local v102_, v103_, v104_ = localDirectionToWorld(node, 0, 1, 0)
	local v105_, v106_, v107_ = localDirectionToWorld(node, 0, 0, 1)
	DebugPyramid.renderAtPosition(v99_, v100_, v101_, v102_, v103_, v104_, v105_, v106_, v107_, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end

-- Local values: offsetX, offsetY, offsetZ, x, y, z, sizeX, sizeY, sizeZ, dirX, dirY, dirZ, upX, upY, upZ
function DebugPyramid.renderWithStartAndEndNode(nodeStart, nodeEnd, color, solid, text, textSize, drawFaces)
	local v115_, v116_, v117_ = localToLocal(nodeEnd, nodeStart, 0, 0, 0)
	local v118_, v119_, v120_ = localToWorld(nodeStart, v115_ * 0.5, v116_ * 0.5, v117_ * 0.5)
	local v121_ = math.abs(v115_)
	local v122_ = math.abs(v116_)
	local v123_ = math.abs(v117_)
	local v124_, v125_, v126_ = localDirectionToWorld(nodeStart, 0, 0, 1)
	local v127_, v128_, v129_ = localDirectionToWorld(nodeStart, 0, 1, 0)
	DebugPyramid.renderAtPosition(v118_, v119_, v120_, v127_, v128_, v129_, v124_, v125_, v126_, v121_ / 2, v122_ / 2, v123_ / 2, color, solid, text, textSize, drawFaces)
end
