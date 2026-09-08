-- Local values: MilkingRobot_mt
MilkingRobot = {}
local MilkingRobot_mt = Class(MilkingRobot)

-- Upvalues: MilkingRobot_mt
-- Local values: self
function MilkingRobot.new(owner, baseDirectory, customMt)
	-- upvalues: (copy) MilkingRobot_mt
	local v5_ = customMt or MilkingRobot_mt
	local v6_ = setmetatable({}, v5_)
	v6_.owner = owner
	v6_.baseDirectory = baseDirectory
	return v6_
end

-- Local values: xmlFile, i3dFilename, arguments
function MilkingRobot:load(linkNode, filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArgs)
	local v13_ = XMLFile.load("milkingRobot", filename)
	if v13_ == nil then
		return false
	end
	local v14_ = Utils.getFilename(v13_:getString("milkingRobot.filename"), self.baseDirectory)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v14_, true, false, self.onI3DFileLoaded, self, {
		["xmlFile"] = v13_,
		["linkNode"] = linkNode,
		["asyncCallbackFunction"] = asyncCallbackFunction,
		["asyncCallbackObject"] = asyncCallbackObject,
		["asyncCallbackArgs"] = asyncCallbackArgs
	})
	return true
end

function MilkingRobot:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
end

function MilkingRobot:onI3DFileLoaded(node, failedReason, args)
	if node ~= 0 then
		link(args.linkNode, node)
		self.node = node
	end
	args.xmlFile:delete()
	args.asyncCallbackFunction(args.asyncCallbackObject, self, args.asyncCallbackArgs)
end

function MilkingRobot:finalizePlacement()
	if self.node ~= nil then
		addToPhysics(self.node)
	end
end
