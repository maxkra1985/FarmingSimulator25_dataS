-- Local values: ListenerList_mt
ListenerList = {}
local ListenerList_mt = Class(ListenerList)

-- Upvalues: ListenerList_mt
-- Local values: self
function ListenerList.new(ignoreFirstArgument)
	-- upvalues: (copy) ListenerList_mt
	local v3_ = ListenerList_mt
	local v4_ = setmetatable({}, v3_)
	v4_.listeners = {}
	v4_.ignoreFirstArgument = ignoreFirstArgument == true
	return v4_
end

-- Local values: listener
function ListenerList:registerListener(listenerFunction, targetObject)
	local v8_ = TargetedFunction.resolveListener(listenerFunction, targetObject)
	local v9_ = self.listeners
	table.insert(v9_, v8_)
end
function ListenerList.invoke(p10_, p11_, ...)
	if p10_.ignoreFirstArgument then
		for _, v12_ in ipairs(p10_.listeners) do
			v12_:invoke(...)
		end
	else
		for _, v13_ in ipairs(p10_.listeners) do
			v13_:invoke(p11_, ...)
		end
	end
end
function ListenerList_mt.__call(p14_, ...)
	return p14_:invoke(...)
end
