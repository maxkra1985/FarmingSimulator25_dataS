-- Local values: AnimationCache_mt
AnimationCache = {}
AnimationCache.CHARACTER = "CHARACTER"
AnimationCache.PEDESTRIAN = "PEDESTRIAN"
AnimationCache.VEHICLE_CHARACTER = "VEHICLE_CHARACTER"
local AnimationCache_mt = Class(AnimationCache)
function AnimationCache.new()
	-- upvalues: (copy) AnimationCache_mt
	local v2_ = AnimationCache_mt
	local v3_ = setmetatable({}, v2_)
	v3_.pendingLoadRequestIds = {}
	v3_.nameToFilename = {}
	v3_.nameToAnimationNode = {}
	return v3_
end

-- Local values: existingName, file, n, node, args, loadRequestId
function AnimationCache:load(name, filename)
	if self.nameToFilename[name] ~= nil then
		Logging.error("\'%s\' already exists in animation cache", name)
		return false
	end
	for v7_, v8_ in pairs(self.nameToFilename) do
		if v8_ == filename then
			self.nameToFilename[name] = filename
			for v9_, v10_ in pairs(self.nameToAnimationNode) do
				if v9_ == v7_ then
					self.nameToAnimationNode[name] = v10_
				end
			end
			return true
		end
	end
	self.nameToFilename[name] = filename
	local v11_ = {
		["name"] = name
	}
	local v12_ = g_i3DManager:loadI3DFileAsync(filename, false, false, self.onAnimationFileLoaded, self, v11_)
	v11_.loadRequestId = v12_
	self.pendingLoadRequestIds[v12_] = true
	return true
end

-- Local values: name, loadRequestId, filename, n, file
function AnimationCache:onAnimationFileLoaded(node, failedReason, args)
	local v16_ = args.name
	local v17_ = args.loadRequestId
	self.pendingLoadRequestIds[v17_] = nil
	if node == 0 then
		return
	else
		local v18_ = self.nameToFilename[v16_]
		if v18_ == nil then
			delete(node)
		else
			self.nameToAnimationNode[v16_] = node
			for v19_, v20_ in pairs(self.nameToFilename) do
				if v18_ == v20_ then
					self.nameToAnimationNode[v19_] = node
				end
			end
		end
	end
end

function AnimationCache:getNode(name)
	return self.nameToAnimationNode[name]
end

function AnimationCache:isLoaded(name)
	return self.nameToAnimationNode[name] ~= nil
end

-- Local values: name, filename, node, pendingLoadRequestId, _
function AnimationCache:delete()
	for v26_, _ in pairs(self.nameToFilename) do
		local v27_ = self.nameToAnimationNode[v26_]
		if v27_ ~= nil and entityExists(v27_) then
			delete(self.nameToAnimationNode[v26_])
		end
	end
	self.nameToFilename = {}
	for v28_, _ in pairs(self.pendingLoadRequestIds) do
		g_i3DManager:cancelStreamI3DFile(v28_)
	end
end
