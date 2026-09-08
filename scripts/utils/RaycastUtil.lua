RaycastUtil = {}

-- Local values: camX, camY, camZ, pickX, pickY, pickZ, dirX, dirY, dirZ
function RaycastUtil.getCameraPickingRay(cursorX, cursorY, cameraNode)
	local v4_, v5_, v6_ = getWorldTranslation(cameraNode)
	local v7_, v8_, v9_ = unProject(cursorX, cursorY, 1)
	local v10_ = v7_ - v4_
	local v11_ = v8_ - v5_
	local v12_ = v9_ - v6_
	local v13_, v14_, v15_ = MathUtil.vector3Normalize(v10_, v11_, v12_)
	return v4_, v5_, v6_, v13_, v14_, v15_
end

function RaycastUtil.raycastClosest(x, y, z, dx, dy, dz, maxDistance, collisionMask)
	RaycastUtil.closestId = nil
	local v24_ = RaycastUtil
	local v25_ = RaycastUtil
	local v26_ = RaycastUtil
	v24_.closestX = nil
	v25_.closestY = nil
	v26_.closestZ = nil
	raycastClosest(x, y, z, dx, dy, dz, maxDistance, "raycastClosestCallback", RaycastUtil, collisionMask)
	return RaycastUtil.closestId, RaycastUtil.closestX, RaycastUtil.closestY, RaycastUtil.closestZ, RaycastUtil.distance
end

function RaycastUtil.raycastClosestCallback(_, hitObjectId, x, y, z, distance)
	RaycastUtil.closestId = hitObjectId
	RaycastUtil.distance = distance
	local v32_ = RaycastUtil
	local v33_ = RaycastUtil
	local v34_ = RaycastUtil
	v32_.closestX = x
	v33_.closestY = y
	v34_.closestZ = z
end

-- Local values: dynamics, kinematics, statics, exact
function RaycastUtil.raycastBox(x, y, z, rx, ry, rz, ex, ey, ez, collisionMask)
	overlapBox(x, y, z, rx, ry, rz, ex, ey, ez, "boxOverlapCallback", RaycastUtil, collisionMask, true, true, true, true)
end

function RaycastUtil.boxOverlapCallback(_, hitObjectId, x, y, z, distance)
	log("BOX HIT", hitObjectId, x, y, z, distance)
end

-- Local values: dynamics, kinematics, statics, exact
function RaycastUtil.raycastSphere(x, y, z, radius, collisionMask)
	overlapSphere(x, y, z, radius, "sphereOverlapCallback", RaycastUtil, collisionMask, true, true, true, true)
end

function RaycastUtil.sphereOverlapCallback(_, hitObjectId, x, y, z, distance)
	log("SPHERE HIT", hitObjectId, x, y, z, distance)
end
