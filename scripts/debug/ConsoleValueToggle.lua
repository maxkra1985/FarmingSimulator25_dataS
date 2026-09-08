-- Local values: ConsoleValueToggle_mt
ConsoleValueToggle = {}
local ConsoleValueToggle_mt = Class(ConsoleValueToggle)

-- Upvalues: ConsoleValueToggle_mt
-- Local values: self
function ConsoleValueToggle.new(commandName, commandDescription, startingValue, outputFunctionOrString, argumentNames, excludeFromHistory)
	-- upvalues: (copy) ConsoleValueToggle_mt
	local v8_ = ConsoleValueToggle_mt
	local v9_ = setmetatable({}, v8_)
	if startingValue == nil or not startingValue then
		startingValue = false
	end
	v9_.value = startingValue
	v9_.commandName = commandName
	v9_.onEnabled = ListenerList.new()
	v9_.onDisabled = ListenerList.new()
	v9_.onDeleted = ListenerList.new()
	v9_.outputFunctionOrString = outputFunctionOrString or function(_, p10_)
		return p10_
	end
	addConsoleCommand(v9_.commandName, commandDescription, "consoleCommandToggleValue", v9_, argumentNames, excludeFromHistory)
	return v9_
end

function ConsoleValueToggle:delete()
	removeConsoleCommand(self.commandName)
	self.onDeleted()
end
function ConsoleValueToggle.consoleCommandToggleValue(p12_, ...)
	if p12_.value then
		p12_:disableValue(...)
	else
		p12_:enableValue(...)
	end
	local v13_ = p12_.outputFunctionOrString
	if type(v13_) == "function" then
		return p12_.outputFunctionOrString(p12_.value, p12_.value and "enabled" or "disabled", ...)
	end
	local v14_ = p12_.outputFunctionOrString
	return type(v14_) ~= "string" and "Toggled" or p12_.outputFunctionOrString
end
function ConsoleValueToggle.enableValue(p15_, ...)
	if not p15_.value then
		p15_.value = true
		p15_.onEnabled(...)
	end
end
function ConsoleValueToggle.disableValue(p16_, ...)
	if p16_.value then
		p16_.value = false
		p16_.onDisabled(...)
	end
end
