-- Local values: TreeGrowEvent_mt
TreeGrowEvent = {}
local TreeGrowEvent_mt = Class(TreeGrowEvent, Event)
InitStaticEventClass(TreeGrowEvent, "TreeGrowEvent")
function TreeGrowEvent.emptyNew()
	-- upvalues: (copy) TreeGrowEvent_mt
	return Event.new(TreeGrowEvent_mt)
end

-- Local values: self
function TreeGrowEvent.new(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeFileId, oldSplitShapeFileId)
	local v13_ = TreeGrowEvent.emptyNew()
	v13_.treeType = treeType
	v13_.x = x
	v13_.y = y
	v13_.z = z
	v13_.rx = rx
	v13_.ry = ry
	v13_.rz = rz
	v13_.growthStateI = growthStateI
	v13_.variationIndex = variationIndex
	v13_.splitShapeFileId = splitShapeFileId
	v13_.oldSplitShapeFileId = oldSplitShapeFileId
	return v13_
end

-- Local values: treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, serverSplitShapeFileId, oldServerSplitShapeFileId, oldNodeId, treeTypeDesc, nodeId, splitShapeFileId
function TreeGrowEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local v16_ = streamReadUInt8(streamId)
		local v17_ = streamReadFloat32(streamId)
		local v18_ = streamReadFloat32(streamId)
		local v19_ = streamReadFloat32(streamId)
		local v20_ = streamReadFloat32(streamId)
		local v21_ = streamReadFloat32(streamId)
		local v22_ = streamReadFloat32(streamId)
		local v23_ = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
		local v24_ = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
		local v25_ = streamReadInt32(streamId)
		local v26_ = streamReadInt32(streamId)
		local v27_ = g_treePlantManager:getClientTree(v26_)
		if v27_ ~= nil then
			delete(v27_)
			g_treePlantManager:removeClientTree(v25_)
		end
		local v28_ = g_treePlantManager:getTreeTypeDescFromIndex(v16_)
		if v28_ ~= nil then
			local v29_, v30_ = g_treePlantManager:loadTreeNode(v28_, v17_, v18_, v19_, v20_, v21_, v22_, v23_, v24_, -1)
			setSplitShapesFileIdMapping(v30_, v25_)
			g_treePlantManager:addClientTree(v25_, v29_)
		end
	end
end

function TreeGrowEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.treeType)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.rx)
		streamWriteFloat32(streamId, self.ry)
		streamWriteFloat32(streamId, self.rz)
		streamWriteUIntN(streamId, self.growthStateI, TreePlantManager.STAGE_NUM_BITS)
		streamWriteUIntN(streamId, self.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
		streamWriteInt32(streamId, self.splitShapeFileId)
		streamWriteInt32(streamId, self.oldSplitShapeFileId)
	end
end

function TreeGrowEvent:run(connection)
	printError("Error: TreeGrowEvent is not allowed to be executed on a local client")
end
