-- Local values: params
StartParams = {}
local params = {}

-- Upvalues: params
-- Local values: argValues, currentKey, _, arg
function StartParams.init(args)
	-- upvalues: (copy) params
	local v3_ = args:split(" ")
	local v4_ = "exe"
	for _, v5_ in pairs(v3_) do
		if v5_:startsWith("-") then
			v4_ = string.sub(v5_, 2)
			params[v4_] = ""
		else
			if params[v4_] == nil then
				params[v4_] = ""
			end
			if params[v4_] ~= "" then
				params[v4_] = params[v4_] .. " "
			end
			params[v4_] = params[v4_] .. v5_
		end
	end
	StartParams.printAll()
end

-- Upvalues: params
function StartParams.getValue(name)
	-- upvalues: (copy) params
	return params[name]
end

-- Upvalues: params
function StartParams.getIsSet(name)
	-- upvalues: (copy) params
	return params[name] ~= nil
end

-- Upvalues: params
function StartParams.setValue(name, value)
	-- upvalues: (copy) params
	params[name] = value
end
function StartParams.printAll()
	-- upvalues: (copy) params
	log("Used Start Parameters:")
	for v10_, v11_ in pairs(params) do
		log("  ", v10_, v11_)
	end
end
