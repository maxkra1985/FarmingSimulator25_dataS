-- Local values: registeredConsoleCommands, oldAddConsoleCommand, newAddConsoleCommand, oldRemoveConsoleCommand, newRemoveConsoleCommand, printTableRecursively
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
if setFileLogPrefixTimestamp == nil then
	function setFileLogPrefixTimestamp(_) end
end
local registeredConsoleCommands = {}
if addConsoleCommand ~= nil then
	local oldAddConsoleCommand = addConsoleCommand
	function addConsoleCommand(p3_, p4_, p5_, p6_, p7_, ...)
		-- upvalues: (copy) registeredConsoleCommands, (copy) oldAddConsoleCommand
		if registeredConsoleCommands[p3_] == nil then
			oldAddConsoleCommand(p3_, p4_, p5_, p6_, p7_, ...)
			local v8_
			if p7_ == nil then
				v8_ = nil
			else
				v8_ = string.split(p7_, ";")
				for v9_, v10_ in ipairs(v8_) do
					v8_[v9_] = string.trim(v10_)
				end
			end
			registeredConsoleCommands[p3_] = {
				["description"] = p4_,
				["arguments"] = v8_
			}
		else
			printError(string.format("Error: Failed to register console command \'%s. Command was already registered!", p3_))
		end
	end
end
if removeConsoleCommand ~= nil then
	local v_u_11_ = removeConsoleCommand
	function removeConsoleCommand(p12_, ...)
		-- upvalues: (copy) v_u_11_, (copy) registeredConsoleCommands
		v_u_11_(p12_, ...)
		registeredConsoleCommands[p12_] = nil
	end
end
function consoleCommandListCommands()
	-- upvalues: (copy) registeredConsoleCommands
	local v13_ = {}
	local v14_ = 0
	for v17_, _ in pairs(registeredConsoleCommands) do
		v13_[#v13_ + 1] = v17_
		local v16_ = registeredConsoleCommands[v17_]
		if v16_.arguments ~= nil then
			local v17_ = string.format("%s %s", v17_, table.concat(v16_.arguments, ", "))
		end
		local v18_ = string.len(v17_)
		v14_ = math.max(v14_, v18_)
	end
	table.sort(v13_)
	setFileLogPrefixTimestamp(false)
	for _, v22_ in ipairs(v13_) do
		local v20_ = registeredConsoleCommands[v22_]
		local v21_ = registeredConsoleCommands[v22_]
		if v21_.arguments ~= nil then
			local v22_ = string.format("%s %s", v22_, table.concat(v21_.arguments, ", "))
		end
		local v23_ = v22_ .. string.rep(" ", v14_ - string.len(v22_))
		print(string.format("%s   %s", v23_, v20_.description))
	end
	print(string.format("# Listed %d script-based console commands. Use \'help\' to get all commands", #v13_))
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
function consoleCommandSearchCommands(p24_)
	-- upvalues: (copy) registeredConsoleCommands
	local v25_ = {}
	local v26_ = {}
	if p24_ == nil or p24_ == "" then
		return "Error: no search string given"
	end
	local v27_ = string.upper(p24_)
	for v28_, _ in pairs(registeredConsoleCommands) do
		if string.contains(string.upper(v28_), v27_) then
			if v26_[v28_] == nil then
				local v29_ = registeredConsoleCommands[v28_]
				if v29_ == nil then
					printError("No command with name %q", v28_)
				else
					table.insert(v25_, { v28_, v29_ })
					v26_[v28_] = true
				end
			end
		end
	end
	for v30_, v31_ in pairs(registeredConsoleCommands) do
		if string.contains(string.upper(v31_.description), v27_) then
			if v26_[v30_] == nil then
				local v32_ = registeredConsoleCommands[v30_]
				if v32_ == nil then
					printError("No command with name %q", v30_)
				else
					table.insert(v25_, { v30_, v32_ })
					v26_[v30_] = true
				end
			end
		end
	end
	for v33_, v34_ in pairs(registeredConsoleCommands) do
		if v34_.arguments ~= nil then
			for _, v35_ in ipairs(v34_.arguments) do
				if string.contains(string.upper(v35_), v27_) then
					if v26_[v33_] == nil then
						local v36_ = registeredConsoleCommands[v33_]
						if v36_ == nil then
							printError("No command with name %q", v33_)
						else
							table.insert(v25_, { v33_, v36_ })
							v26_[v33_] = true
						end
					end
				end
			end
		end
	end
	if #v25_ == 0 then
		return "Error: no results\nTry a different search term or use \'help\' to list all commands"
	end
	setFileLogPrefixTimestamp(false)
	for _, v37_ in ipairs(v25_) do
		local v38_ = v37_[1]
		local v39_ = v37_[2].arguments == nil and "" or (" " .. table.concat(v37_[2].arguments, ", ") or "")
		local v40_ = v37_[2].description
		print(v38_ .. v39_ .. "\n        " .. v40_)
	end
	print(string.format("Listed %d script-defined console commands for search \'%s\'. Use \'help\' to get all available commands", #v25_, v27_))
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
if addConsoleCommand ~= nil then
	addConsoleCommand("gsScriptCommandsList", "Lists script-based console commands. Use \'help\' to get all commands", "consoleCommandListCommands", nil)
	addConsoleCommand("gsSearch", "Searches for script-based console commands containing the given string (name and description). Use \'help\' to get all commands", "consoleCommandSearchCommands", nil)
end
function log(...)
	local v41_ = ""
	for v42_ = 1, select("#", ...) do
		local v43_ = select
		v41_ = v41_ .. " " .. tostring(v43_(v42_, ...))
	end
	print(v41_)
end
local function v_u_54_(p44_, p45_, p46_, p47_)
	-- upvalues: (copy) v_u_54_
	local v48_ = p45_ or "  "
	local v49_ = p46_ or 0
	local v50_ = p47_ or 3
	if v50_ >= v49_ then
		local v51_ = ""
		for v52_, v53_ in pairs(p44_) do
			print(v48_ .. tostring(v52_) .. " :: " .. tostring(v53_))
			if type(v53_) == "table" then
				v_u_54_(v53_, v48_ .. "    ", v49_ + 1, v50_)
			end
		end
		return v51_
	end
end

-- Upvalues: printTableRecursively
function print_r(tbl, depth)
	-- upvalues: (copy) v_u_54_
	if tbl == nil then
		print("table: nil")
		return
	elseif type(tbl) == "table" then
		if next(tbl) == nil then
			print("table: empty")
		else
			setFileLogPrefixTimestamp(false)
			v_u_54_(tbl, "  ", 0, depth or 5)
			setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		end
	else
		print("table: no such table")
		return
	end
end
function printf(p57_, ...)
	print(string.format(p57_, ...))
end

-- Local values: currentIndex, iterator
function ipairs_reverse(list)
	if type(list) ~= "table" then
		error(string.format("invalid argument #1 (%s) to \'ipairs_reverse\' (table expected)", (type(list))), 2)
	end
	local v_u_59_ = #list
	return function()
		-- upvalues: (ref) v_u_59_, (copy) list
		if v_u_59_ < 1 then
			return nil
		end
		local v60_ = list[v_u_59_]
		if v60_ == nil then
			return nil
		end
		v_u_59_ = v_u_59_ - 1
		return v_u_59_ + 1, v60_
	end
end

-- Local values: length, currentIndex, numIterations, iterator
function ipairs_randomStart(list)
	if type(list) ~= "table" then
		error(string.format("invalid argument #1 (%s) to \'ipairs_randomStart\' (table expected)", (type(list))), 2)
	end
	local v_u_62_ = #list
	local v_u_63_ = 0
	local v_u_64_ = v_u_62_ <= 1 and 0 or math.random(0, v_u_62_ - 1)
	return function()
		-- upvalues: (ref) v_u_63_, (copy) v_u_62_, (ref) v_u_64_, (copy) list
		if v_u_63_ == v_u_62_ then
			return nil
		else
			v_u_63_ = v_u_63_ + 1
			v_u_64_ = v_u_64_ + 1
			if v_u_62_ < v_u_64_ then
				v_u_64_ = 1
			end
			local v65_ = list[v_u_64_]
			if v65_ == nil then
				return nil
			else
				return v_u_64_, v65_
			end
		end
	end
end

-- Local values: length, index, iterator
function iteratePointList2D(pointList2D)
	local v_u_67_ = pointList2D:getNumPoints()
	local v_u_68_ = 1
	return function()
		-- upvalues: (ref) v_u_68_, (copy) v_u_67_, (copy) pointList2D
		if v_u_68_ > v_u_67_ then
			return nil
		end
		local v69_, v70_ = pointList2D:get(v_u_68_ - 1)
		v_u_68_ = v_u_68_ + 1
		return v_u_68_ - 1, v69_, v70_
	end
end

-- Local values: length, index, iterator
function iteratePointList2DLines(pointList2D)
	local v_u_72_ = pointList2D:getNumPoints()
	local v_u_73_ = 1
	return function()
		-- upvalues: (ref) v_u_73_, (copy) v_u_72_, (copy) pointList2D
		if v_u_73_ >= v_u_72_ then
			return nil
		end
		local v74_, v75_ = pointList2D:get(v_u_73_ - 1)
		local v76_, v77_ = pointList2D:get(v_u_73_)
		v_u_73_ = v_u_73_ + 1
		return v74_, v75_, v76_, v77_
	end
end

function assertWithCallstack(expression, message)
	if not expression then
		if message == nil or type(message) ~= "string" then
			printError("Error: assertion failed!")
		else
			printError("Error: assertion failed: " .. message)
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

-- Local values: newX, newY
function getNormalizedScreenValues(x, y)
	if x == nil or y == nil then
		printCallstack()
	end
	return x / g_referenceScreenWidth * g_aspectScaleX, y / g_referenceScreenHeight * g_aspectScaleY
end

function getCorrectTextSize(size)
	if g_aspectScaleY == nil then
		return size
	else
		return size * g_aspectScaleY
	end
end

-- Local values: loadedFovY, delta
function calculateFovY(defaultFovy)
	if GS_IS_EDITOR then
		return defaultFovy
	end
	local v87_ = defaultFovy + (g_gameSettings:getValue(GameSettings.SETTING.FOV_Y) - g_fovYDefault)
	local v88_ = g_fovYMin
	local v89_ = g_fovYMax
	return math.clamp(v87_, v88_, v89_)
end
if GS_IS_EDITOR then
	RainSimWeatherType = RainSimWeatherType or {
		["DEFAULT"] = 1,
		["RAIN"] = 2,
		["SNOW"] = 3,
		["HAIL"] = 4
	}
	getUserName = getUserName or function(...)
		return ""
	end
	getUserId = getUserId or function(...)
		return ""
	end
	reportUser = reportUser or function(_, _, _, _, ...) end
	addConsoleCommand = addConsoleCommand or function(_, _, _, _, _, _, ...)
		return true
	end
	removeConsoleCommand = removeConsoleCommand or function(_, ...) end
	executeConsoleCommand = executeConsoleCommand or function(_, _, ...) end
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
	setFileLogPrefixTimestamp = setFileLogPrefixTimestamp or function(_, ...) end
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
