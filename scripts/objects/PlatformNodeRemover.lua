-- Local values: name, id
PlatformNodeRemover = {}
PlatformNodeRemover.NODES = {}
PlatformNodeRemover.ATTRIBUTES = {}
for v1_, v2_ in pairs(PlatformId) do
	PlatformNodeRemover.ATTRIBUTES[v2_] = string.upper("removeOn" .. v1_)
end

-- Local values: attributeName, numUserAttributes, i, doRemoveNode, userAttributeName, upperName
function PlatformNodeRemover.onCreate(_, node)
	local v4_ = PlatformNodeRemover.ATTRIBUTES[getPlatformId()]
	for v5_ = 0, getNumOfUserAttributes(node) - 1 do
		local v6_, v7_ = getUserAttributeByIndex(node, v5_)
		if string.upper(v7_) == v4_ and (type(v6_) == "boolean" and v6_) then
			local v8_ = PlatformNodeRemover.NODES
			table.insert(v8_, node)
		end
	end
	if getUserAttribute(node, "netflixExclusive") == true and not Platform.isNetflix then
		local v9_ = PlatformNodeRemover.NODES
		table.insert(v9_, node)
	end
end
function PlatformNodeRemover.reset()
	PlatformNodeRemover.NODES = {}
end
function PlatformNodeRemover.removeNodes()
	for _, v10_ in ipairs(PlatformNodeRemover.NODES) do
		Logging.devInfo("PlatformNodeRemover: Removed node \'%s\'", getName(v10_))
		delete(v10_)
	end
	PlatformNodeRemover.reset()
end
