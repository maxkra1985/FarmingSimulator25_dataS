VectorTest = {}
function VectorTest.test_eulerToDirection()
	local directionX = nil
	local directionY = nil
	local directionZ = nil
	directionX, directionY, directionZ = MathUtil.eulerToDirection(0, 1.5707963267948966)
	Assert.areRoughlyEqual(directionX, 0)
	Assert.areRoughlyEqual(directionY, -1)
	Assert.areRoughlyEqual(directionZ, 0)
	directionX, directionY, directionZ = MathUtil.eulerToDirection(0, -1.5707963267948966)
	Assert.areRoughlyEqual(directionX, 0)
	Assert.areRoughlyEqual(directionY, 1)
	Assert.areRoughlyEqual(directionZ, 0)
	directionX, directionY, directionZ = MathUtil.eulerToDirection(1.5707963267948966, 0)
	Assert.areRoughlyEqual(directionX, 1)
	Assert.areRoughlyEqual(directionY, 0)
	Assert.areRoughlyEqual(directionZ, 0)
	directionX, directionY, directionZ = MathUtil.eulerToDirection(-1.5707963267948966, 0)
	Assert.areRoughlyEqual(directionX, -1)
	Assert.areRoughlyEqual(directionY, 0)
	Assert.areRoughlyEqual(directionZ, 0)
	directionX, directionY, directionZ = MathUtil.eulerToDirection(0, 0)
	Assert.areRoughlyEqual(directionX, 0)
	Assert.areRoughlyEqual(directionY, 0)
	Assert.areRoughlyEqual(directionZ, 1)
	directionX, directionY, directionZ = MathUtil.eulerToDirection(3.141592653589793, 0)
	Assert.areRoughlyEqual(directionX, 0)
	Assert.areRoughlyEqual(directionY, 0)
	Assert.areRoughlyEqual(directionZ, -1)
	local testNode = createTransformGroup("test")
	for pitch = -3.141592653589793, 3.141592653589793, 0.2617993877991494 do
		for yaw = -3.141592653589793, 3.141592653589793, 0.2617993877991494 do
			setWorldRotation(testNode, pitch, yaw, 0)
			directionX, directionY, directionZ = MathUtil.eulerToDirection(yaw, pitch)
			local nodeDirectionX, nodeDirectionY, nodeDirectionZ = localDirectionToWorld(testNode, 0, 0, 1)
			Assert.areRoughlyEqual(directionX, nodeDirectionX)
			Assert.areRoughlyEqual(directionY, nodeDirectionY)
			Assert.areRoughlyEqual(directionZ, nodeDirectionZ)
		end
	end
	delete(testNode)
end
