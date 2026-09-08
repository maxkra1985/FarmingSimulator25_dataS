-- Local values: TargetedFunction_mt
TargetedFunction = {}
local TargetedFunction_mt = Class(TargetedFunction)
function TargetedFunction.new(p2_, p3_, ...)
	-- upvalues: (copy) TargetedFunction_mt
	local v4_ = TargetedFunction_mt
	local v5_ = setmetatable({}, v4_)
	v5_.targetFunction = p2_
	v5_.targetObject = p3_
	v5_.arguments = table.pack(...)
	return v5_
end

function TargetedFunction:delete()
	self.targetFunction = nil
	self.targetObject = nil
end

function TargetedFunction.resolveListener(targetFunction, targetObject)
	if type(targetFunction) == "function" then
		return TargetedFunction.new(targetFunction, targetObject)
	else
		return targetFunction
	end
end
function TargetedFunction.unpackCombinedArguments(p9_, ...)
	local v10_ = table.getListUnion
	local v11_ = p9_.arguments
	local v12_ = table.pack
	return table.unpack(v10_(v11_, v12_(...)))
end
function TargetedFunction.invoke(p13_, ...)
	if p13_.targetObject then
		if p13_.arguments.n == 0 then
			return p13_.targetFunction(p13_.targetObject, ...)
		else
			return p13_.targetFunction(p13_.targetObject, p13_:unpackCombinedArguments(...))
		end
	elseif p13_.arguments.n == 0 then
		return p13_.targetFunction(...)
	else
		return p13_.targetFunction(p13_:unpackCombinedArguments(...))
	end
end
function TargetedFunction_mt.__call(p14_, ...)
	return p14_:invoke(...)
end
