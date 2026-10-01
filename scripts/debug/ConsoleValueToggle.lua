ConsoleValueToggle = {}
local ConsoleValueToggle_mt = Class(ConsoleValueToggle)
function ConsoleValueToggle.new(commandName, commandDescription, startingValue, outputFunctionOrString, argumentNames, excludeFromHistory)
	local self = setmetatable({}, ConsoleValueToggle_mt)
	self.value = startingValue ~= nil and startingValue or false
	self.commandName = commandName
	self.onEnabled = ListenerList.new()
	self.onDisabled = ListenerList.new()
	self.onDeleted = ListenerList.new()
	self.outputFunctionOrString = outputFunctionOrString or function(_, enabledString)
		return enabledString
	end
	addConsoleCommand(self.commandName, commandDescription, "consoleCommandToggleValue", self, argumentNames, excludeFromHistory)
	return self
end
function ConsoleValueToggle:delete()
	removeConsoleCommand(self.commandName)
	self.onDeleted()
end
function ConsoleValueToggle:consoleCommandToggleValue(...)
	if not self.value then
		self:enableValue(...)
	else
		self:disableValue(...)
	end
	if type(self.outputFunctionOrString) == "function" then
		return self.outputFunctionOrString(self.value, self.value and "enabled" or "disabled", ...)
	elseif type(self.outputFunctionOrString) == "string" then
		return self.outputFunctionOrString
	else
		return "Toggled"
	end
end
function ConsoleValueToggle:enableValue(...)
	if self.value then
		return
	else
		self.value = true
		self.onEnabled(...)
	end
end
function ConsoleValueToggle:disableValue(...)
	if not self.value then
		return
	else
		self.value = false
		self.onDisabled(...)
	end
end
