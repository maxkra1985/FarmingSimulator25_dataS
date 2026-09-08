-- Local values: Object_mt
Object = {}
local Object_mt = Class(Object)
InitStaticObjectClass(Object, "Object")
Object.nextObjectId = 1
Object.MAX_DIRTY_FLAG = 1073741824
function Object.resetObjectIds()
	local v2_ = g_server == nil and true or next(g_server.objects) == nil
	assert(v2_)
	Object.nextObjectId = 1
end

-- Upvalues: Object_mt
-- Local values: self
function Object.new(isServer, isClient, customMt)
	-- upvalues: (copy) Object_mt
	local v6_ = customMt or Object_mt
	local v7_ = setmetatable({}, v6_)
	v7_.id = Object.nextObjectId
	Object.nextObjectId = Object.nextObjectId + 1
	if g_isDevelopmentVersion and not isServer then
		v7_.id = math.random(9999, 99999999)
	end
	v7_.isRegistered = false
	v7_.isServer = isServer
	v7_.isClient = isClient
	v7_.ownerConnection = nil
	v7_.ownerFarmId = AccessHandler.EVERYONE
	v7_.recieveUpdates = isServer
	v7_.nextDirtyFlag = 1
	v7_.dirtyMask = 0
	v7_.deleteListeners = nil
	return v7_
end

-- Local values: _, listener
function Object:delete()
	if self.deleteListeners ~= nil then
		for _, v9_ in ipairs(self.deleteListeners) do
			local v10_ = v9_.callbackFunc
			if type(v10_) == "string" then
				v9_.object[v9_.callbackFunc](v9_.object, self)
			else
				local v11_ = v9_.callbackFunc
				if type(v11_) == "function" then
					v9_.callbackFunc(v9_.object, self)
				end
			end
		end
	end
	if self.isRegistered then
		self:unregister()
	end
end

function Object:register(alreadySent)
	if self.isServer then
		if g_server ~= nil then
			g_server:registerObject(self, alreadySent)
			return
		end
	elseif g_client ~= nil then
		g_client:registerObject(self, alreadySent)
	end
end

function Object:unregister(alreadySent)
	if self.isServer then
		if g_server ~= nil then
			g_server:unregisterObject(self, alreadySent)
			return
		end
	elseif g_client ~= nil then
		g_client:unregisterObject(self, alreadySent)
	end
end

function Object:raiseActive()
	if self.isServer then
		if g_server ~= nil then
			g_server:addObjectToUpdateLoop(self)
			return
		end
	elseif g_client ~= nil then
		g_client:addObjectToUpdateLoop(self)
	end
end

-- Local values: ownerFarmId
function Object:readStream(streamId, connection, objectId)
	self:setOwnerFarmId(streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS), true)
end

function Object:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function Object:readUpdateStream(streamId, timestamp, connection) end

function Object:writeUpdateStream(streamId, dirtyMask, dirtyMask) end

function Object:getIsDelayedLoaded()
	local v22_
	if self.postWriteStream == nil then
		v22_ = false
	else
		v22_ = self.postReadStream ~= nil
	end
	return v22_
end

function Object:update(dt) end

function Object:updateTick(dt) end

function Object:updateEnd(dt) end

function Object:draw() end

function Object:setOwnerConnection(connection)
	if self.isServer then
		self.ownerConnection = connection
	else
		printError("Error: setOwner only allowed on Server")
	end
end

function Object:getOwnerConnection()
	return self.ownerConnection
end

function Object:onGhostRemove() end

function Object:onGhostAdd() end

function Object:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	return skipCount * 0.5
end

-- Local values: nextFlag
function Object:getNextDirtyFlag()
	if self.nextDirtyFlag > Object.MAX_DIRTY_FLAG then
		self.nextDirtyFlag = Object.MAX_DIRTY_FLAG
		Logging.devWarning("Object:getNextDirtyFlag(), too many dirty flags")
		if g_isDevelopmentVersion then
			printCallstack()
		end
	end
	local v28_ = self.nextDirtyFlag
	self.nextDirtyFlag = self.nextDirtyFlag * 2
	return v28_
end

function Object:raiseDirtyFlags(flag)
	local v31_ = self.dirtyMask
	self.dirtyMask = bit32.bor(v31_, flag)
end

function Object:clearDirtyFlags(flag)
	local v34_ = self.dirtyMask
	local v35_ = bit32.bnot(flag)
	self.dirtyMask = bit32.band(v34_, v35_)
end

function Object:clearDirtyMask()
	self.dirtyMask = 0
end

function Object:onMissionStarted(isNewSavegame) end

function Object:setOwnerFarmId(farmId, noEventSend)
	if self.ownerFarmId ~= farmId then
		self.ownerFarmId = farmId
		if self.isServer and (noEventSend == nil or not noEventSend) then
			g_server:broadcastEvent(ObjectFarmChangeEvent.new(self, farmId), nil, nil, self)
		end
	end
end

function Object:getOwnerFarmId()
	return self.ownerFarmId
end

-- Local values: _, listener
function Object:addDeleteListener(object, callbackFunc)
	local v44_ = callbackFunc == nil and "onDeleteObject" or callbackFunc
	self.deleteListeners = self.deleteListeners or {}
	for _, v45_ in ipairs(self.deleteListeners) do
		if v45_.object == object and v45_.callbackFunc == v44_ then
			return
		end
	end
	local v46_ = self.deleteListeners
	table.insert(v46_, {
		["object"] = object,
		["callbackFunc"] = v44_
	})
end

-- Local values: i, listener
function Object:removeDeleteListener(object, callbackFunc)
	if self.deleteListeners ~= nil then
		local v50_ = callbackFunc == nil and "onDeleteObject" or callbackFunc
		for v51_, v52_ in ipairs(self.deleteListeners) do
			if v52_.object == object and v52_.callbackFunc == v50_ then
				table.remove(self.deleteListeners, v51_)
				return
			end
		end
	end
end
