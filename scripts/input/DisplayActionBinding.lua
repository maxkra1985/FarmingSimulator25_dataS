-- Local values: DisplayActionBinding_mt
DisplayActionBinding = {}
local DisplayActionBinding_mt = Class(DisplayActionBinding)

-- Upvalues: DisplayActionBinding_mt
-- Local values: self
function DisplayActionBinding.new(action, displayName, isPositive, bindings)
	-- upvalues: (copy) DisplayActionBinding_mt
	local v5_ = DisplayActionBinding_mt
	local v6_ = setmetatable({}, v5_)
	v6_.action = action
	v6_.displayName = displayName
	v6_.isPositive = isPositive
	v6_.columnTexts = {}
	v6_.columnBindings = {}
	return v6_
end

function DisplayActionBinding:setBindingDisplay(binding, text, column)
	self.columnTexts[column] = text
	self.columnBindings[column] = binding
end

-- Local values: bindingsText, col, binding
function DisplayActionBinding:toString()
	local v12_ = ""
	for v13_, v14_ in pairs(self.columnBindings) do
		v12_ = v12_ .. "(" .. tostring(v13_) .. ": " .. tostring(v14_) .. ")"
	end
	local v15_ = string.format
	local v16_ = self.displayName
	local v17_ = tostring(v16_)
	local v18_ = self.action
	local v19_ = tostring(v18_)
	local v20_ = self.isPositive
	return v15_("[DisplayActionBinding: displayName=%s, action=%s, isPositive=%s, columnTexts=%s, columnBindings=%s]", v17_, v19_, tostring(v20_), table.concat(self.columnTexts, "|"), v12_)
end
DisplayActionBinding_mt.__tostring = DisplayActionBinding.toString
