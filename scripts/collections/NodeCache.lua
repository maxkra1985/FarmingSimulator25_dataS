-- Local values: NodeCache_mt
NodeCache = {}
local NodeCache_mt = Class(NodeCache)

-- Upvalues: NodeCache_mt
-- Local values: self
function NodeCache.new(customMt)
	-- upvalues: (copy) NodeCache_mt
	local v3_ = customMt or NodeCache_mt
	local v4_ = setmetatable({}, v3_)
	v4_.templateNodes = {}
	v4_.cloneToTemplateIndex = {}
	v4_.templateIndexToBuffer = {}
	return v4_
end

-- Local values: templateIndex
function NodeCache:addTemplate(node)
	if table.hasElement(self.templateNodes, node) then
		Logging.error("NodeCache:addTemplate: Node %q (%d) already present in templates", getName(node), node)
		return
	elseif entityExists(node) then
		if getParent(node) == 0 then
			local v7_ = self.templateNodes
			table.insert(v7_, node)
			local v8_ = #self.templateNodes
			self.templateIndexToBuffer[v8_] = {}
			return v8_
		end
		Logging.error("NodeCache:addTemplate: Node %q (%d) is still linked", getName(node), node)
	else
		Logging.error("NodeCache:addTemplate: entity %d does not exist", node)
	end
end

-- Local values: clonedNode
function NodeCache:getNodeInstance(templateIndex)
	if #self.templateNodes < templateIndex then
		Logging.error("templateIndex %d out of bounds, only %d template node registered", templateIndex, #self.templateNodes)
		return nil
	end
	if #self.templateIndexToBuffer[templateIndex] > 0 then
		return table.remove(self.templateIndexToBuffer[templateIndex])
	end
	local v11_ = clone(self.templateNodes[templateIndex], false, false, false)
	self.cloneToTemplateIndex[v11_] = templateIndex
	return v11_
end

-- Local values: templateIndex
function NodeCache:returnNodeToCache(node)
	if entityExists(node) then
		local v14_ = self.cloneToTemplateIndex[node]
		if v14_ == nil then
			Logging.error("NodeCache:returnNodeToCache: Node %q (%d) is not a clone of a template", getName(node), node)
			return
		elseif getParent(node) == 0 then
			local v15_ = self.templateIndexToBuffer[v14_]
			table.insert(v15_, node)
		else
			Logging.error("NodeCache:returnNodeInstanceToBuffer: Node %q (%d) is still linked", getName(node), node)
		end
	else
		Logging.error("NodeCache:returnNodeToCache: entity %d does not exist", node)
		return
	end
end

-- Local values: meshIndex, buffer, _, mesh
function NodeCache:empty()
	for _, v17_ in ipairs(self.templateIndexToBuffer) do
		for _, v18_ in ipairs(v17_) do
			delete(v18_)
		end
		table.clear(v17_)
	end
	table.clear(self.cloneToTemplateIndex)
end

-- Local values: _, templateNode
function NodeCache:delete()
	self:empty()
	for _, v20_ in ipairs(self.templateNodes) do
		delete(v20_)
	end
	table.clear(self.templateNodes)
end

-- Local values: fontSize, index, templateNode
function NodeCache:drawDebug(screenX, screenY)
	local v24_ = screenX or 0.02
	local v25_ = screenY or 0.8
	setTextColor(1, 1, 1, 1)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(v24_, v25_, 0.015, "NodeCache")
	for v26_, v27_ in ipairs(self.templateNodes) do
		renderText(v24_, v25_ - v26_ * 0.015, 0.015, string.format("%s: %d", getName(v27_), #self.templateIndexToBuffer[v26_]))
	end
end
