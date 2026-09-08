TestI3DManager = {}
function TestI3DManager.init()
	local v1_ = TestI3DManager
	v1_.file = "data/vehicles/fendt/vario900/vario900.i3d"
	v1_.sharedLoadRequestIds = {}
end

function TestI3DManager.update(dt) end
function TestI3DManager.draw()
	g_i3DManager:drawDebug()
end

function TestI3DManager.mouseEvent(posX, posY, isDown, isUp, button) end

-- Local values: self, sharedLoadRequestId, sharedLoadRequestId
function TestI3DManager.keyEvent(unicode, sym, modifier, isDown)
	if not isDown then
		local v4_ = TestI3DManager
		if sym == Input.KEY_m then
			local v5_ = g_i3DManager:loadSharedI3DFileAsync(v4_.file, false, false, v4_.finishedLoading, TestI3DManager, {
				["file"] = v4_.file
			})
			local v6_ = v4_.sharedLoadRequestIds
			table.insert(v6_, v5_)
			return
		end
		if sym == Input.KEY_n then
			local v7_ = table.remove(v4_.sharedLoadRequestIds, 1)
			if v7_ ~= nil then
				g_i3DManager:releaseSharedI3DFile(v7_)
				return
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
