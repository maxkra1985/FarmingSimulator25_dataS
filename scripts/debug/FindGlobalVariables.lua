-- Local values: allowlist
g_globalsNameCheckDisabled = false
local v_u_1_ = {
	["io"] = true,
	["modOnCreate"] = true,
	["debug"] = true,
	["masterServerConnectFront"] = true,
	["masterServerConnectBack"] = true,
	["masterServerAddServer"] = true,
	["masterServerAddServerModStart"] = true,
	["masterServerAddServerMod"] = true,
	["masterServerAddServerModEnd"] = true,
	["masterServerRequestConnectionToServer"] = true,
	["netConnect"] = true
}
local v2_ = _G
setmetatable(v2_, {
	["__newindex"] = function(p3_, p4_, p5_)
		-- upvalues: (copy) v_u_1_
		if not g_globalsNameCheckDisabled and (type(p4_) == "string" and (type(p5_) ~= "function" and (v_u_1_[p4_] == nil and (p4_ < "A" or p4_ > "Z")))) and not string.startsWith(p4_, "g_") then
			printWarning("Warning: Global variable name does not match naming convention: " .. p4_)
			printCallstack()
		end
		rawset(p3_, p4_, p5_)
	end
})
printWarning("\n\n  ##################   Warning: Globals name check active!   ##################\n\n")
