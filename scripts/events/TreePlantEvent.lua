-- Local values: TreePlantEvent_mt
TreePlantEvent = {}
local TreePlantEvent_mt = Class(TreePlantEvent, Event)
InitStaticEventClass(TreePlantEvent, "TreePlantEvent")
function TreePlantEvent.emptyNew()
	-- upvalues: (copy) TreePlantEvent_mt
	return Event.new(TreePlantEvent_mt)
end

-- Local values: self
function TreePlantEvent.new(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeFileId, isGrowing, price, farmId)
	local v15_ = TreePlantEvent.emptyNew()
	v15_.treeType = treeType
	v15_.x = x
	v15_.y = y
	v15_.z = z
	v15_.rx = rx
	v15_.ry = ry
	v15_.rz = rz
	v15_.growthStateI = growthStateI
	v15_.variationIndex = variationIndex
	v15_.splitShapeFileId = splitShapeFileId
	v15_.isGrowing = isGrowing
	v15_.price = price or 0
	v15_.farmId = farmId or 0
	return v15_
end

-- Local values: treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, isGrowing, price, farmId, serverSplitShapeFileId, treeTypeDesc, nodeId, splitShapeFileId
function TreePlantEvent:readStream(streamId, connection)
	local v18_ = streamReadUInt8(streamId)
	local v19_ = streamReadFloat32(streamId)
	local v20_ = streamReadFloat32(streamId)
	local v21_ = streamReadFloat32(streamId)
	local v22_ = streamReadFloat32(streamId)
	local v23_ = streamReadFloat32(streamId)
	local v24_ = streamReadFloat32(streamId)
	local v25_ = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
	local v26_ = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
	if connection:getIsServer() then
		local v27_ = streamReadInt32(streamId)
		local v28_ = g_treePlantManager:getTreeTypeDescFromIndex(v18_)
		if v28_ ~= nil then
			local v29_, v30_ = g_treePlantManager:loadTreeNode(v28_, v19_, v20_, v21_, v22_, v23_, v24_, v25_, v26_, -1)
			setSplitShapesFileIdMapping(v30_, v27_)
			g_treePlantManager:addClientTree(v27_, v29_)
		end
	else
		local v31_ = streamReadBool(streamId)
		local v32_ = streamReadInt32(streamId)
		local v33_ = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		g_treePlantManager:plantTree(v18_, v19_, v20_, v21_, v22_, v23_, v24_, v25_, v26_, v31_)
		if v32_ > 0 then
			g_currentMission:addMoney(-v32_, v33_, MoneyType.SHOP_PROPERTY_BUY, true)
			return
		end
	end
end

function TreePlantEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.treeType)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	streamWriteFloat32(streamId, self.rx)
	streamWriteFloat32(streamId, self.ry)
	streamWriteFloat32(streamId, self.rz)
	streamWriteUIntN(streamId, self.growthStateI, TreePlantManager.STAGE_NUM_BITS)
	streamWriteUIntN(streamId, self.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
	if connection:getIsServer() then
		streamWriteBool(streamId, self.isGrowing)
		streamWriteInt32(streamId, self.price)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteInt32(streamId, self.splitShapeFileId)
	end
end

function TreePlantEvent:run(connection)
	printError("Error: TreePlantEvent is not allowed to be executed on a local client")
end
