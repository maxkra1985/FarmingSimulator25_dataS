GS_IS_EDITOR = _G.getSelection ~= nil
GS_INPUT_HELP_MODE_AUTO = 1
GS_INPUT_HELP_MODE_KEYBOARD = 2
GS_INPUT_HELP_MODE_GAMEPAD = 3
GS_INPUT_HELP_MODE_TOUCH = 4
GS_PRIO_VERY_HIGH = 1
GS_PRIO_HIGH = 2
GS_PRIO_NORMAL = 3
GS_PRIO_LOW = 4
GS_PRIO_VERY_LOW = 5
GS_MONEY_EURO = 1
GS_MONEY_DOLLAR = 2
GS_MONEY_POUND = 3
function loadfile() end
function load()
	return nil, "invalid function"
end
function loadstring()
	return nil, "invalid function"
end
if setFileLogPrefixTimestamp == nil then
	function setFileLogPrefixTimestamp(addTimestamp) end
end
local registeredConsoleCommands = {}
if addConsoleCommand ~= nil then
	local oldAddConsoleCommand = addConsoleCommand
	local newAddConsoleCommand = function(name, description, funcName, funcTarget, argumentNames, ...)
		if registeredConsoleCommands[name] == nil then
			oldAddConsoleCommand(name, description, funcName, funcTarget, argumentNames, ...)
			local arguments = nil
			if argumentNames ~= nil then
				arguments = string.split(argumentNames, ";")
				for argIndex, argument in ipairs(arguments) do
					arguments[argIndex] = string.trim(argument)
				end
			end
			registeredConsoleCommands[name] = { description = description, arguments = arguments }
		else
			printError(string.format("Error: Failed to register console command '%s. Command was already registered!", name))
		end
	end
	addConsoleCommand = newAddConsoleCommand
end
if removeConsoleCommand ~= nil then
	local oldRemoveConsoleCommand = removeConsoleCommand
	local newRemoveConsoleCommand = function(name, ...)
		oldRemoveConsoleCommand(name, ...)
		registeredConsoleCommands[name] = nil
	end
	removeConsoleCommand = newRemoveConsoleCommand
end
function consoleCommandListCommands()
	local getNameWithArguments = function(commandName)
		local commandData = registeredConsoleCommands[commandName]
		if commandData.arguments ~= nil then
			commandName = string.format("%s %s", commandName, table.concat(commandData.arguments, ", "))
		end
		return commandName
	end
	local sortedNames = {}
	local maxNameLength = 0
	for name, data in pairs(registeredConsoleCommands) do
		sortedNames[#sortedNames + 1] = name
		local commandName = name
		local commandData = registeredConsoleCommands[commandName]
		if commandData.arguments ~= nil then
			commandName = string.format("%s %s", commandName, table.concat(commandData.arguments, ", "))
		end
		local nameLen = string.len(commandName)
		maxNameLength = math.max(maxNameLength, nameLen)
	end
	table.sort(sortedNames)
	setFileLogPrefixTimestamp(false)
	for _, name in ipairs(sortedNames) do
		local commandData = registeredConsoleCommands[name]
		local commandName = name
		local commandData = registeredConsoleCommands[commandName]
		if commandData.arguments ~= nil then
			commandName = string.format("%s %s", commandName, table.concat(commandData.arguments, ", "))
		end
		local nameWithArguments = commandName
		local paddedName = nameWithArguments .. string.rep(" ", maxNameLength - string.len(nameWithArguments))
		print(string.format("%s   %s", paddedName, commandData.description))
	end
	print(string.format("# Listed %d script-based console commands. Use 'help' to get all commands", #sortedNames))
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
function consoleCommandSearchCommands(searchStr)
	local results = {}
	local resultsLookup = {}
	if searchStr == nil or searchStr == "" then
		return "Error: no search string given"
	end
	searchStr = string.upper(searchStr)
	local addCommandToResults = function(commandName)
		if resultsLookup[commandName] ~= nil then
			return
		end
		local commandData = registeredConsoleCommands[commandName]
		if commandData == nil then
			printError("No command with name %q", commandName)
		else
			table.insert(results, { commandName, commandData })
			resultsLookup[commandName] = true
		end
	end
	for name, commandData in pairs(registeredConsoleCommands) do
		if string.contains(string.upper(name), searchStr) then
			if resultsLookup[name] ~= nil then
				continue
			end
			local commandData = registeredConsoleCommands[name]
			if commandData == nil then
				printError("No command with name %q", name)
			else
				table.insert(results, { name, commandData })
				resultsLookup[name] = true
			end
		end
	end
	for name, commandData in pairs(registeredConsoleCommands) do
		if string.contains(string.upper(commandData.description), searchStr) then
			if resultsLookup[name] ~= nil then
				continue
			end
			local commandData = registeredConsoleCommands[name]
			if commandData == nil then
				printError("No command with name %q", name)
			else
				local _ = { name, commandData }
				table.insert(results, _)
				resultsLookup[name] = true
			end
		end
	end
	for name, commandData in pairs(registeredConsoleCommands) do
		if commandData.arguments == nil then
			continue
		end
		for _, argument in ipairs(commandData.arguments) do
			if string.contains(string.upper(argument), searchStr) then
				if resultsLookup[name] ~= nil then
					continue
				end
				local commandData = registeredConsoleCommands[name]
				if commandData == nil then
					printError("No command with name %q", name)
				else
					table.insert(results, { name, commandData })
					resultsLookup[name] = true
				end
			end
		end
	end
	if #results == 0 then
		return "Error: no results\nTry a different search term or use 'help' to list all commands"
	else
		setFileLogPrefixTimestamp(false)
		for _, nameAndData in ipairs(results) do
			local name = nameAndData[1]
			local arguments = nameAndData[2].arguments ~= nil and " " .. table.concat(nameAndData[2].arguments, ", ") or ""
			local desc = nameAndData[2].description
			print(name .. arguments .. "\n        " .. desc)
		end
		print(string.format("Listed %d script-defined console commands for search '%s'. Use 'help' to get all available commands", #results, searchStr))
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		return
	end
end
if addConsoleCommand ~= nil then
	addConsoleCommand("gsScriptCommandsList", "Lists script-based console commands. Use 'help' to get all commands", "consoleCommandListCommands", nil)
	addConsoleCommand("gsSearch", "Searches for script-based console commands containing the given string (name and description). Use 'help' to get all commands", "consoleCommandSearchCommands", nil)
end
function log(...)
	local str = ""
	for i = 1, select("#", ...) do
		str = str .. " " .. tostring(select(i, ...))
	end
	print(str)
end
local function printTableRecursively(inputTable, inputIndent, depth, maxDepth)
	inputIndent = inputIndent or "  "
	depth = depth or 0
	maxDepth = maxDepth or 3
	if maxDepth < depth then
		return
	else
		local debugString = ""
		for i, j in pairs(inputTable) do
			print(inputIndent .. tostring(i) .. " :: " .. tostring(j))
			if type(j) == "table" then
				printTableRecursively(j, inputIndent .. "    ", depth + 1, maxDepth)
			end
		end
		return debugString
	end
end
function print_r(tbl, depth)
	if tbl == nil then
		print("table: nil")
	elseif type(tbl) ~= "table" then
		print("table: no such table")
	elseif next(tbl) == nil then
		print("table: empty")
	else
		setFileLogPrefixTimestamp(false)
		printTableRecursively(tbl, "  ", 0, depth or 5)
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	end
end
function printf(formatText, ...)
	print(string.format(formatText, ...))
end
function ipairs_reverse(list)
	if type(list) ~= "table" then
		error(string.format("invalid argument #1 (%s) to 'ipairs_reverse' (table expected)", type(list)), 2)
	end
	local currentIndex = #list
	local iterator = function()
		if currentIndex < 1 then
			return nil
		end
		local value = list[currentIndex]
		if value == nil then
			return nil
		else
			currentIndex = currentIndex - 1
			return currentIndex + 1, value
		end
	end
	return iterator
end
function ipairs_randomStart(list)
	if type(list) ~= "table" then
		error(string.format("invalid argument #1 (%s) to 'ipairs_randomStart' (table expected)", type(list)), 2)
	end
	local length = #list
	local currentIndex = 0
	local numIterations = 0
	if 1 < length then
		currentIndex = math.random(0, length - 1)
	end
	local iterator = function()
		if numIterations == length then
			return nil
		end
		numIterations = numIterations + 1
		currentIndex = currentIndex + 1
		if length < currentIndex then
			currentIndex = 1
		end
		local value = list[currentIndex]
		if value == nil then
			return nil
		else
			return currentIndex, value
		end
	end
	return iterator
end
function iteratePointList2D(pointList2D)
	local length = pointList2D:getNumPoints()
	local index = 1
	local iterator = function()
		if index <= length then
			local x, z = pointList2D:get(index - 1)
			index = index + 1
			return index - 1, x, z
		else
			return nil
		end
	end
	return iterator
end
function iteratePointList2DLines(pointList2D)
	local length = pointList2D:getNumPoints()
	local index = 1
	local iterator = function()
		if index < length then
			local x1, z1 = pointList2D:get(index - 1)
			local x2, z2 = pointList2D:get(index)
			index = index + 1
			return x1, z1, x2, z2
		else
			return nil
		end
	end
	return iterator
end
function assertWithCallstack(expression, message)
	if not expression then
		if message ~= nil then
			if type(message) == "string" then
				printError("Error: assertion failed: " .. message)
			else
				printError("Error: assertion failed!")
			end
		end
		printCallstack()
		error("Assertion failed")
	end
end
function registerObjectClassName(object, className)
	if g_currentMission ~= nil then
		g_currentMission.objectsToClassName[object] = className
	end
end
function unregisterObjectClassName(object)
	if g_currentMission ~= nil then
		g_currentMission.objectsToClassName[object] = nil
	end
end
function getNormalizedScreenValues(x, y)
	if x == nil or y == nil then
		printCallstack()
	end
	local newX = x / g_referenceScreenWidth * g_aspectScaleX
	local newY = y / g_referenceScreenHeight * g_aspectScaleY
	return newX, newY
end
function getCorrectTextSize(size)
	if g_aspectScaleY == nil then
		return size
	else
		return size * g_aspectScaleY
	end
end
function calculateFovY(defaultFovy)
	if GS_IS_EDITOR then
		return defaultFovy
	else
		local loadedFovY = g_gameSettings:getValue(GameSettings.SETTING.FOV_Y)
		local delta = loadedFovY - g_fovYDefault
		return math.clamp(defaultFovy + delta, g_fovYMin, g_fovYMax)
	end
end
if GS_IS_EDITOR then
	RainSimWeatherType = RainSimWeatherType
	getUserName = getUserName or function(...)
		return ""
	end
	getUserId = getUserId or function(...)
		return ""
	end
	reportUser = reportUser or function(uniqueUserId, platformUserId, platformId, reason, ...) end
	addConsoleCommand = addConsoleCommand or function(commandName, description, functionName, target, targetArgumentNames, excludeFromHistory, ...)
		return true
	end
	removeConsoleCommand = removeConsoleCommand or function(commandName, ...) end
	executeConsoleCommand = executeConsoleCommand or function(consoleCommandName, excludeFromHistory, ...) end
	getAppBasePath = getAppBasePath or function()
		return getGameBasePath() or ""
	end
	getUserProfileAppPath = getUserProfileAppPath or function()
		return g_userProfilePath or ""
	end
	getEngineRevision = getEngineRevision or function()
		return ""
	end
	getTotalSystemMemory = getTotalSystemMemory or function()
		return 16384
	end
	setFileLogPrefixTimestamp = setFileLogPrefixTimestamp or function(prefixTimestamp, ...) end
	enableDevelopmentControls = enableDevelopmentControls or function() end
	startFrameRepeatMode = startFrameRepeatMode or function()
		return false
	end
	endFrameRepeatMode = endFrameRepeatMode or function()
		return false
	end
	forceEndFrameRepeatMode = forceEndFrameRepeatMode or function() end
	enterCpuBoostMode = enterCpuBoostMode or function() end
	leaveCpuBoostMode = leaveCpuBoostMode or function() end
	get3dResolutionScaling = get3dResolutionScaling or function()
		return 1
	end
	centerHeadTracking = centerHeadTracking or function() end
	getScreenAspectRatio = getScreenAspectRatio or function()
		return g_screenAspectRatio
	end
end
if getHasGamepadAxisForceFeedback == nil then
	function getHasGamepadAxisForceFeedback(axisNumber, gamepadIndex)
		return false
	end
end
if setGamepadAxisForceFeedback == nil then
	function setGamepadAxisForceFeedback(axisNumber, gamepadIndex, force, position) end
end
