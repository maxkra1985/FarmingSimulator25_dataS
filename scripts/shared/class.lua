function Class(...)
	local v1_ = select("#", ...)
	local v2_ = select(1, ...)
	local v_u_3_
	if v1_ > 1 then
		v_u_3_ = select(2, ...)
		if v_u_3_ == nil then
			printError("Error: Given base class is not defined")
			printCallstack()
		end
	else
		v_u_3_ = nil
	end
	local v_u_4_ = v2_ or {}
	local v_u_5_ = {
		["__metatable"] = v_u_4_,
		["__index"] = v_u_4_
	}
	if v_u_3_ ~= nil then
		setmetatable(v_u_4_, {
			["__index"] = v_u_3_
		})
	end
	
-- Upvalues: members
function v_u_4_:class()
		-- upvalues: (ref) v_u_4_
		return v_u_4_
	end
	
-- Upvalues: baseClass
function v_u_4_:superClass()
		-- upvalues: (ref) v_u_3_
		return v_u_3_
	end
	
-- Upvalues: members
-- Local values: curClass
function v_u_4_:isa(other)
		-- upvalues: (ref) v_u_4_
		local v7_ = v_u_4_
		while v7_ ~= nil do
			if v7_ == other then
				return true
			end
			v7_ = v7_:superClass()
		end
		return false
	end
	v_u_4_.new = v_u_4_.new or function(_, p8_)
		-- upvalues: (copy) v_u_5_
		local v9_ = v_u_5_
		return setmetatable(p8_ or {}, v9_)
	end
	v_u_4_.copy = v_u_4_.copy or function(p10_, ...)
		local v11_ = p10_.new(...)
		for v12_, v13_ in pairs(p10_) do
			v11_[v12_] = v13_
		end
		return v11_
	end
	return v_u_5_
end
