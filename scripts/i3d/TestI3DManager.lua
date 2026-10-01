TestI3DManager = {}
function TestI3DManager.init()
	local self = TestI3DManager
	self.file = "data/vehicles/fendt/vario900/vario900.i3d"
	self.sharedLoadRequestIds = {}
end
function TestI3DManager.update(dt) end
function TestI3DManager.draw()
	g_i3DManager:drawDebug()
end
function TestI3DManager.mouseEvent(posX, posY, isDown, isUp, button) end
function TestI3DManager.keyEvent(unicode, sym, modifier, isDown)
	if not isDown then
		local self = TestI3DManager
		if sym == Input.KEY_m then
			local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.file, false, false, self.finishedLoading, TestI3DManager, { file = self.file })
			table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
			return
		end
		if sym == Input.KEY_n then
			local sharedLoadRequestId = table.remove(self.sharedLoadRequestIds, 1)
			if sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
			end
		elseif sym == Input.KEY_q then
			restartApplication(false, "")
		end
	end
end
function TestI3DManager.finishedLoading(_, nodeId, failedReason, args)
	log("loaded", getName(nodeId))
	delete(nodeId)
end
