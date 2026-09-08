AutoLoadable = {}

function AutoLoadable.prerequisitesPresent(self)
	return true
end

function AutoLoadable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAutoLoadIsSupported", AutoLoadable.getAutoLoadIsSupported)
	SpecializationUtil.registerFunction(vehicleType, "getAutoLoadIsAllowed", AutoLoadable.getAutoLoadIsAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getAutoLoadBoundingBox", AutoLoadable.getAutoLoadBoundingBox)
	SpecializationUtil.registerFunction(vehicleType, "getAutoLoadSize", AutoLoadable.getAutoLoadSize)
	SpecializationUtil.registerFunction(vehicleType, "autoLoad", AutoLoadable.autoLoad)
end

function AutoLoadable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadable)
end

-- Local values: spec
function AutoLoadable:onLoad(savegame)
	if self.isServer then
		self.spec_autoLoadable.isSupported = true
	end
end

-- Local values: spec
function AutoLoadable:getAutoLoadIsSupported()
	return self.spec_autoLoadable.isSupported
end

function AutoLoadable.getAutoLoadIsAllowed(self)
	return true
end

-- Local values: size, sizeX, sizeY, sizeZ
function AutoLoadable:getAutoLoadSize()
	local v6_ = self.size
	return v6_.width, v6_.height, v6_.length
end

-- Local values: size, x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ
function AutoLoadable:getAutoLoadBoundingBox()
	local v8_ = self.size
	local v9_, v10_, v11_ = localToWorld(self.rootNode, v8_.widthOffset, v8_.heightOffset, v8_.lengthOffset)
	local v12_, v13_, v14_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
	local v15_, v16_, v17_ = localDirectionToWorld(self.rootNode, 0, 1, 0)
	return v9_, v10_, v11_, v12_, v13_, v14_, v15_, v16_, v17_, v8_.width * 0.5, v8_.height * 0.5, v8_.length * 0.5
end

-- Local values: size, mountPosX, mountPosY, mountPosZ, mountRotX, mountRotY, mountRotZ
function AutoLoadable:autoLoad(autoLoader, node, posX, posZ, sizeX, sizeZ)
	local v23_ = self.size
	self:mountKinematic(autoLoader, node, posX + v23_.widthOffset + v23_.width * 0.5, v23_.heightOffset, posZ + v23_.lengthOffset + v23_.height * 0.5, 0, 0, 0)
	return true
end
