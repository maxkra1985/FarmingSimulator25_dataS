CollectibleTarget = {}
local CollectibleTarget_mt = Class(CollectibleTarget)
function CollectibleTarget:onCreate(node)
	g_currentMission:addNonUpdateable(CollectibleTarget.new(node))
end
function CollectibleTarget.new(node)
	local self = setmetatable({}, CollectibleTarget_mt)
	self.node = node
	g_currentMission.collectiblesSystem:addCollectibleTarget(self)
	local isStaticMapTarget = g_currentMission.isLoadingMap and not Environment.getIsNodeInPlaceable(node)
	if not isStaticMapTarget then
		g_messageCenter:subscribe(MessageType.PLACEABLE_PRE_DELETE, self.onPlaceablePreDelete, self)
	end
	return self
end
function CollectibleTarget:delete()
	g_messageCenter:unsubscribeAll(self)
	g_currentMission:removeNonUpdateable(self)
	g_currentMission.collectiblesSystem:removeCollectibleTarget(self)
end
function CollectibleTarget:onPlaceablePreDelete(placeable, rootNode)
	if not entityExists(self.node) then
		return
	end
	if I3DUtil.getIsLinkedToNode(rootNode, self.node) then
		self:delete()
	end
end
