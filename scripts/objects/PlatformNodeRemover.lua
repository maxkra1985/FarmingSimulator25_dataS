PlatformNodeRemover = {}
PlatformNodeRemover.NODES = {}
PlatformNodeRemover.ATTRIBUTES = {}
for name, id in pairs(PlatformId) do
	PlatformNodeRemover.ATTRIBUTES[id] = string.upper("removeOn" .. name)
end
function PlatformNodeRemover.onCreate(_, node)
	local attributeName = PlatformNodeRemover.ATTRIBUTES[getPlatformId()]
	local numUserAttributes = getNumOfUserAttributes(node)
	for i = 0, numUserAttributes - 1 do
		local doRemoveNode, userAttributeName = getUserAttributeByIndex(node, i)
		local upperName = string.upper(userAttributeName)
		if upperName == attributeName and (type(doRemoveNode) == "boolean" and doRemoveNode) then
			table.insert(PlatformNodeRemover.NODES, node)
		end
	end
	if getUserAttribute(node, "netflixExclusive") == true and not Platform.isNetflix then
		table.insert(PlatformNodeRemover.NODES, node)
	end
end
function PlatformNodeRemover.reset()
	PlatformNodeRemover.NODES = {}
end
function PlatformNodeRemover.removeNodes()
	for _, node in ipairs(PlatformNodeRemover.NODES) do
		Logging.devInfo("PlatformNodeRemover: Removed node '%s'", getName(node))
		delete(node)
	end
	PlatformNodeRemover.reset()
end
