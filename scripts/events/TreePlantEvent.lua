TreePlantEvent = {}
local TreePlantEvent_mt = Class(TreePlantEvent, Event)
InitStaticEventClass(TreePlantEvent, "TreePlantEvent")
function TreePlantEvent.emptyNew()
	local self = Event.new(TreePlantEvent_mt)
	return self
end
function TreePlantEvent.new(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeFileId, isGrowing, price, farmId)
	local self = TreePlantEvent.emptyNew()
	self.treeType = treeType
	self.x = x
	self.y = y
	self.z = z
	self.rx = rx
	self.ry = ry
	self.rz = rz
	self.growthStateI = growthStateI
	self.variationIndex = variationIndex
	self.splitShapeFileId = splitShapeFileId
	self.isGrowing = isGrowing
	self.price = price or 0
	self.farmId = farmId or 0
	return self
end
function TreePlantEvent:readStream(streamId, connection)
	local treeType = streamReadUInt8(streamId)
	local x = streamReadFloat32(streamId)
	local y = streamReadFloat32(streamId)
	local z = streamReadFloat32(streamId)
	local rx = streamReadFloat32(streamId)
	local ry = streamReadFloat32(streamId)
	local rz = streamReadFloat32(streamId)
	local growthStateI = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
	local variationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
	if not connection:getIsServer() then
		local isGrowing = streamReadBool(streamId)
		local price = streamReadInt32(streamId)
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		g_treePlantManager:plantTree(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, isGrowing)
		if 0 < price then
			g_currentMission:addMoney(-price, farmId, MoneyType.SHOP_PROPERTY_BUY, true)
		end
	else
		local serverSplitShapeFileId = streamReadInt32(streamId)
		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(treeType)
		if treeTypeDesc ~= nil then
			local nodeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, -1)
			setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
			g_treePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
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
