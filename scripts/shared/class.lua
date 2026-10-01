function Class(...)
	local numParameters = select("#", ...)
	local members = select(1, ...)
	local baseClass = nil
	if 1 < numParameters then
		baseClass = select(2, ...)
		if baseClass == nil then
			printError("Error: Given base class is not defined")
			printCallstack()
		end
	end
	members = members or {}
	local mt = {}
	local __index = members
	mt.__metatable = members
	mt.__index = __index
	if baseClass ~= nil then
		setmetatable(members, { __index = baseClass })
	end
	local new = function(_, init)
		return setmetatable(init or {}, mt)
	end
	local copy = function(obj, ...)
		local newobj = obj.new(...)
		for n, v in pairs(obj) do
			newobj[n] = v
		end
		return newobj
	end
	function members:class()
		return members
	end
	function members:superClass()
		return baseClass
	end
	function members:isa(other)
		local curClass = members
		while curClass ~= nil do
			if curClass == other then
				return true
			end
			curClass = curClass:superClass()
		end
		return false
	end
	members.new = members.new or new
	members.copy = members.copy or copy
	return mt
end
