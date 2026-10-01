if not StartParams.getIsSet("scriptDebug") then
	return
else
	WrapFunctions = {}
	WrapFunctions.SCRIPT_BINDING_PATH = "../tools/studio/Farming_Simulator_25_Dev.xml"
	WrapFunctions.ignore = {}
	WrapFunctions.backups = {}
	local getNamespace = function(functionNameStr)
		local namespaceStr = nil
		if string.contains(functionNameStr, ":", true) then
			namespaceStr, functionNameStr = unpack(string.split(functionNameStr, ":"))
		elseif string.contains(functionNameStr, ".", true) then
			namespaceStr, functionNameStr = unpack(string.split(functionNameStr, "."))
		end
		local namespaceTbl = namespaceStr and _G[namespaceStr] or _G
		return functionNameStr, namespaceTbl
	end
	function WrapFunctions.init()
		printWarning("Warning: function profiling / wrapping active")
		addConsoleCommand("gsFunctionWrap", "Wrap a global function with a profiling zone", "consoleCommandFunctionWrap", WrapFunctions)
		addConsoleCommand("gsFunctionWrapClass", "Wrap all functions with profiling zones", "consoleCommandFunctionWrapClass", WrapFunctions)
		addConsoleCommand("gsFunctionWrapEngine", "Wrap all engine functions with profiling zones", "consoleCommandFunctionWrapEngine", WrapFunctions)
		addConsoleCommand("gsFunctionWrapEngineCategory", "Wrap all global functions of a specific category with profiling zones", "consoleCommandFunctionWrapEngineCategory", WrapFunctions)
		addConsoleCommand("gsFunctionUnwrap", "Unwrap all functions", "consoleCommandFunctionUnwrap", WrapFunctions)
		addConsoleCommand("gsFunctionWrapVisualize", "Enable custom visualization for overlaps, raycasts, etc", "consoleCommandFunctionVisualize", WrapFunctions)
		addConsoleCommand("gsFunctionDrawTriggerCallbacks", "Draw last performed trigger callbacks on screen", "consoleCommandDrawTriggerCallbacks", WrapFunctions)
		WrapFunctions.memoryAllocations = {}
		WrapFunctions.customWrappers()
		WrapFunctions.customWrappersNetwork()
		WrapFunctions.customWrappersXML()
	end
	function WrapFunctions.consoleCommandFunctionWrap(_, ...)
		local numArgs = select("#", ...)
		if numArgs == 0 then
			printError("Error: no function names given\nUsage: gsFunctionWrap functionName <functionName2> ...")
		else
			for i = 1, numArgs do
				local funcName = select(i, ...)
				local functionNameOnly, namespaceTbl = getNamespace(funcName)
				local success, statusMessage = WrapFunctions.wrapFunction(functionNameOnly, namespaceTbl, funcName)
				if success then
					print(string.format("%q %s", funcName, statusMessage))
				else
					printError("Error: " .. string.format("%q %s", funcName, statusMessage))
				end
			end
		end
	end
	function WrapFunctions.consoleCommandFunctionWrapClass(_, ...)
		local numArgs = select("#", ...)
		if numArgs == 0 then
			printError("Error: no function names given\nUsage: gsFunctionWrapClass ClassName <ClassName2> ...")
		else
			for i = 1, numArgs do
				local className = select(i, ...)
				local success, statusMessage = WrapFunctions.wrapClass(className)
				if success then
					print(statusMessage)
				else
					printError("Error: " .. statusMessage)
				end
			end
		end
	end
	function WrapFunctions.consoleCommandFunctionWrapEngine()
		local numWrapped = WrapFunctions.wrapEngineFunctions()
		print(string.format("Wrapped %d functions in profiling zones", numWrapped))
	end
	function WrapFunctions.consoleCommandFunctionWrapEngineCategory(_, ...)
		local numArgs = select("#", ...)
		if numArgs == 0 then
			printError("Error: no function names given\nUsage: gsFunctionWrapEngineCategory CategoryName <CategoryName2> ...")
		else
			local numWrapped = WrapFunctions.wrapEngineFunctions(...)
			print(string.format("Wrapped %d functions in profiling zones", numWrapped))
		end
	end
	function WrapFunctions.consoleCommandFunctionUnwrap()
		local num = WrapFunctions.unwrapAll()
		if num == 0 then
			printWarning("Warning: no functions to unwrap, use one of the gsFunctionWrap* console commands to wrap function(s) in profiling zones")
		else
			print(string.format("unwrapped %d functions", num))
		end
	end
	function WrapFunctions.consoleCommandFunctionVisualize()
		WrapFunctions.customWrappersPhysics()
	end
	local debugFunctionDrawLastTriggerCallbacks = nil
	local debugFunctionDrawLastTriggerCallbacksElementId = nil
	function WrapFunctions.consoleCommandDrawTriggerCallbacks()
		if debugFunctionDrawLastTriggerCallbacksElementId then
			g_debugManager:removeElementById(debugFunctionDrawLastTriggerCallbacksElementId)
			debugFunctionDrawLastTriggerCallbacksElementId = nil
			return "Disabled drawing of trigger callbacks"
		elseif debugFunctionDrawLastTriggerCallbacks ~= nil then
			debugFunctionDrawLastTriggerCallbacksElementId = g_debugManager:addElement(debugFunctionDrawLastTriggerCallbacks)
			return "Enabled drawing of trigger callbacks"
		else
			return "No draw function defined"
		end
	end
	function WrapFunctions.wrapClass(className, trackMemory)
		local classTable = _G[className]
		if classTable == nil then
			return false, string.format("No global class %q", className)
		else
			local numWrapped = 0
			for k, v in pairs(classTable) do
				if type(v) == "function" then
					local zoneName = className .. "." .. k
					if WrapFunctions.wrapFunction(k, classTable, zoneName, trackMemory) then
						numWrapped = numWrapped + 1
					end
				end
			end
			return true, string.format("Wrapped %d functions for %q in profiling zones", numWrapped, className)
		end
	end
	function WrapFunctions.wrapEngineFunctions(...)
		local xml = loadXMLFile("scriptBinding", WrapFunctions.SCRIPT_BINDING_PATH)
		if xml == 0 then
			return 0
		else
			print(string.format("WrapFunctions.wrapEngineFunctions(): loading script biding from %s", WrapFunctions.SCRIPT_BINDING_PATH))
			local categoryFilter = nil
			for i = 1, select("#", ...) do
				categoryFilter = categoryFilter or {}
				local normalizedCategory = string.upper(select(i, ...))
				categoryFilter[normalizedCategory] = true
			end
			if categoryFilter then
				print("   limit to categories: " .. table.concatKeys(categoryFilter, ", "))
			end
			local numWrapped = 0
			for i = 0, getXMLNumOfElements(xml, "scriptBinding.function") - 1 do
				local key = "scriptBinding.function(" .. i .. ")"
				local functionName = getXMLString(xml, key .. "#name")
				local functionCategory = getXMLString(xml, key .. "#category") or "NoCategory"
				local functionCategoryNoramlized = string.gsub(string.upper(functionCategory), " ", "")
				if WrapFunctions.ignore[functionName] == nil and (not categoryFilter or categoryFilter[functionCategoryNoramlized] ~= nil) then
					local functionNameOnly, namespaceTbl = getNamespace(functionName)
					functionName = string.format("%s (%s)", functionName, functionCategory)
					if WrapFunctions.wrapFunction(functionNameOnly, namespaceTbl, functionName) then
						numWrapped = numWrapped + 1
					end
				end
			end
			delete(xml)
			return numWrapped
		end
	end
	function WrapFunctions.wrapFunction(name, namespace, zoneName, trackMemory)
		namespace = namespace or _G
		zoneName = zoneName or name
		local oldFunc = namespace[name]
		if type(oldFunc) ~= "function" then
			return false, "not a function"
		end
		local id = tostring(namespace) .. name
		if WrapFunctions.backups[id] ~= nil then
			printWarning(string.format("Warning: %q is already wrapped, ignoring", name))
			return false, "already wrapped"
		else
			WrapFunctions.backups[id] = { name, namespace, oldFunc }
			if trackMemory then
				WrapFunctions.memoryAllocations[zoneName] = WrapFunctions.memoryAllocations[zoneName] or 0
			end
			local wrapper = function(...)
				local mem = nil
				if trackMemory then
					collectgarbage("collect")
					mem = collectgarbage("count")
				end
				RemoteProfiler.zoneBeginN(zoneName)
				local ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16, ret17 = oldFunc(...)
				RemoteProfiler.zoneEnd()
				if trackMemory then
					collectgarbage("collect")
					mem = collectgarbage("count") - mem
					WrapFunctions.memoryAllocations[zoneName] = WrapFunctions.memoryAllocations[zoneName] + mem
				end
				if ret17 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16, ret17
				elseif ret16 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16
				elseif ret15 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15
				elseif ret14 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14
				elseif ret13 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13
				elseif ret12 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12
				elseif ret11 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11
				elseif ret10 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10
				elseif ret9 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9
				elseif ret8 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8
				elseif ret7 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6, ret7
				elseif ret6 ~= nil then
					return ret1, ret2, ret3, ret4, ret5, ret6
				elseif ret5 ~= nil then
					return ret1, ret2, ret3, ret4, ret5
				elseif ret4 ~= nil then
					return ret1, ret2, ret3, ret4
				elseif ret3 ~= nil then
					return ret1, ret2, ret3
				elseif ret2 ~= nil then
					return ret1, ret2
				elseif ret1 ~= nil then
					return ret1
				else
					return nil
				end
			end
			namespace[name] = wrapper
			return true, "wrapped in profiling zone"
		end
	end
	function WrapFunctions.unwrapAll()
		local num = table.size(WrapFunctions.backups)
		for _, triple in pairs(WrapFunctions.backups) do
			local funcName, env, oldFunc = unpack(triple)
			env[funcName] = oldFunc
		end
		WrapFunctions.backups = {}
		return num
	end
	local string_len = nil
	function WrapFunctions.customWrappers()
		local lastCallbacks = {}
		local addHistoryEntry = function(str)
			table.insert(lastCallbacks, 1, str)
			if 15 < #lastCallbacks then
				table.remove(lastCallbacks)
			end
		end
		debugFunctionDrawLastTriggerCallbacks = DebugFunction.new(nil, function()
			setTextColor(1, 1, 1, 1)
			for index, callbackStr in ipairs(lastCallbacks) do
				renderText(0.2, 0.72 + index * 0.012, 0.012, callbackStr)
			end
		end)
		local engine_addTrigger = addTrigger
		local new_addTrigger = function(shapeId, callbackFunctionName, callbackTarget, reportOnStay, callbackFunction)
			if not getHasTrigger(shapeId) then
				Logging.warning("addTrigger() shape %q does not have 'trigger' flag set", I3DUtil.getNodePath(shapeId))
				printCallstack()
			end
			if type(callbackFunction or callbackTarget[callbackFunctionName] or _G[callbackFunctionName]) ~= "function" then
				Logging.error("Unable to access given trigger callback function %q", callbackFunctionName)
				printCallstack()
			end
			local callbackTargetName = ClassUtil.getClassNameByObject(callbackTarget) or ClassUtil.getClassName(callbackTarget) or ""
			local profilingZoneName = "TriggerCallback for '" .. getName(shapeId) .. "' " .. callbackTargetName .. ":" .. callbackFunctionName
			local callbackTarget_inj = {}
			local callbackFunc_inj = function(_, triggerId, otherId, onEnter, onLeave, onStay, ...)
				if onEnter then
					local changeString = "onEnter"
				elseif onLeave then
					changeString = "onLeave"
				else
					changeString = onStay and "onStay" or "unknown"
				end
				local triggerName = entityExists(triggerId) and I3DUtil.getNodePath(triggerId, nil, true) or "<triggerDeleted>"
				local otherName = entityExists(otherId) and I3DUtil.getNodePath(otherId, nil, true) or "<nodeDeleted>"
				local debugString = string.format("uli %d: trig: %s(%d) shape: %s(%d) %s ", g_updateLoopIndex, triggerName, triggerId, otherName, otherId, changeString)
				local zoneText = otherName .. " (" .. otherId .. ") " .. changeString
				table.insert(lastCallbacks, 1, debugString)
				if 15 < #lastCallbacks then
					table.remove(lastCallbacks)
				end
				if callbackFunction ~= nil then
					RemoteProfiler.zoneBeginN(profilingZoneName)
					RemoteProfiler.zoneText(zoneText)
					local ret = callbackFunction(callbackTarget, triggerId, otherId, onEnter, onLeave, onStay, ...)
					RemoteProfiler.zoneEnd()
					return ret
				else
					RemoteProfiler.zoneBeginN(profilingZoneName)
					RemoteProfiler.zoneText(zoneText)
					local ret = callbackTarget[callbackFunctionName](callbackTarget, triggerId, otherId, onEnter, onLeave, onStay, ...)
					RemoteProfiler.zoneEnd()
					return ret
				end
			end
			callbackTarget_inj.callbackFunc_inj = callbackFunc_inj
			if callbackFunction ~= nil then
				return engine_addTrigger(shapeId, "callbackFunc_inj", callbackTarget_inj, reportOnStay, callbackFunc_inj)
			else
				return engine_addTrigger(shapeId, "callbackFunc_inj", callbackTarget_inj, reportOnStay)
			end
		end
		addTrigger = new_addTrigger
		string_len = string.len
		local new_string_len = function(str)
			str = type(str) == "number" and tostring(str) or str
			if string_len(str) ~= utf8Strlen(str) then
				Logging.warning("string.len used on a string containing utf-8 characters: %s", str)
				printCallstack()
			end
			return string_len(str)
		end
		string.len = new_string_len
		local string_sub = string.sub
		local new_string_sub = function(str, s, e)
			str = type(str) == "number" and tostring(str) or str
			if string_len(str) ~= utf8Strlen(str) then
				Logging.warning("string.sub used on a string containing utf-8 characters: %s", str)
				printCallstack()
			end
			return string_sub(str, s, e)
		end
		string.sub = new_string_sub
		local string_upper = string.upper
		local new_string_upper = function(str)
			str = type(str) == "number" and tostring(str) or str
			if string_upper(str) ~= utf8ToUpper(str) then
				Logging.warning("string.upper used on a string containing utf-8 characters: %s", str)
				printCallstack()
			end
			return string_upper(str)
		end
		string.upper = new_string_upper
		local string_lower = string.lower
		local new_string_lower = function(str)
			str = type(str) == "number" and tostring(str) or str
			if string_lower(str) ~= utf8ToLower(str) then
				Logging.warning("string.lower used on a string containing utf-8 characters: %s", str)
				printCallstack()
			end
			return string_lower(str)
		end
		string.lower = new_string_lower
		local engine_createImageOverlay = createImageOverlay
		local new_createImageOverlay = function(filename)
			local overlayId = engine_createImageOverlay(filename)
			if overlayId ~= 0 and (debug ~= nil and debug.traceback ~= nil) then
				setName(overlayId, getName(overlayId) .. "\n" .. debug.traceback(nil, 2))
			end
			return overlayId
		end
		createImageOverlay = new_createImageOverlay
		local engine_createSample = createSample
		local new_createSample = function(sampleName)
			local sampleId = engine_createSample(sampleName)
			if sampleId ~= 0 and (debug ~= nil and debug.traceback ~= nil) then
				setName(sampleId, getName(sampleId) .. "\n" .. debug.traceback(nil, 2))
			end
			return sampleId
		end
		createSample = new_createSample
		local engine_loadSample = loadSample
		local new_loadSample = function(sampleId, sampleFilename, ...)
			local success = engine_loadSample(sampleId, sampleFilename, ...)
			if success then
				setName(sampleId, sampleFilename .. getName(sampleId))
			end
			return success
		end
		loadSample = new_loadSample
		local engine_loadXMLFile = loadXMLFile
		local new_loadXMLFile = function(objectName, filename)
			local newObjectName = string.format("%s - %s%s", objectName, filename, debug and "\n" .. debug.traceback(nil, 2) or "")
			return engine_loadXMLFile(newObjectName, filename)
		end
		loadXMLFile = new_loadXMLFile
		local engine_loadXMLFileFromMemory = loadXMLFileFromMemory
		local new_loadXMLFileFromMemory = function(objectName, xmlString)
			local newObjectName = string.format("%s%s", objectName, debug and "\n" .. debug.traceback(nil, 2) or "")
			return engine_loadXMLFileFromMemory(newObjectName, xmlString)
		end
		loadXMLFileFromMemory = new_loadXMLFileFromMemory
		local engine_fileExists = fileExists
		local new_fileExists = function(filePath)
			if string.endsWith(filePath, ".dds") or string.endsWith(filePath, ".png") then
				Logging.warning("'fileExists' called on texture file which might not exist with the specific extension on a different platform, use 'textureFileExists' instead")
				printCallstack()
			else
				if string.endsWith(filePath, ".ogg") or string.endsWith(filePath, ".wav") or string.endsWith(filePath, ".gls") then
					Logging.warning("'fileExists' called on audio file which might not exist with the specific extension on a different platform, use 'audioFileExists' instead")
					printCallstack()
				end
			end
			return engine_fileExists(filePath)
		end
		fileExists = new_fileExists
	end
	function WrapFunctions.customWrappersPhysics()
		local checkMask = function(actual, disallowed)
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(actual, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
		end
		local debugSplitFindTest = function(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, r, g, b, a)
			local zx, zy, zz = MathUtil.crossProduct(nx, ny, nz, yx, yy, yz)
			DebugUtil.drawDebugPlane(x, y, z, zx, zy, zz, yx, yy, yz, cutSizeY, cutSizeZ, r, g, b, a)
		end
		local engineFindAndRemoveSplitShapeAttachments = findAndRemoveSplitShapeAttachments
		local newFindAndRemoveSplitShapeAttachments = function(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeX, cutSizeY, cutSizeZ)
			debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, 1, 0, 0, 0.5)
			local removedAttachment = engineFindAndRemoveSplitShapeAttachments(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeX, cutSizeY, cutSizeZ)
			return removedAttachment
		end
		findAndRemoveSplitShapeAttachments = newFindAndRemoveSplitShapeAttachments
		local engineFindSplitShape = findSplitShape
		local newFindSplitShape = function(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
			debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, 1, 0, 0, 0.5)
			local shape, minY, maxY, minZ, maxZ = engineFindSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
			if shape ~= nil and shape ~= 0 then
				Utils.renderTextAtWorldPosition(x, y, z, string.format("findSplitShape shape:%s minY:%.3f maxY:%.3f minZ:%.3f maxZ:%.3f", shape, minY, maxY, minZ, maxZ), 0.02)
				return shape, minY, maxY, minZ, maxZ
			end
			Utils.renderTextAtWorldPosition(x, y, z, "findSplitShape nil", 0.02)
			return shape, minY, maxY, minZ, maxZ
		end
		findSplitShape = newFindSplitShape
		local engineTestSplitShape = testSplitShape
		local newTestSplitShape = function(splitShape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
			debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, 0, 1, 0, 0.5)
			local minY, maxY, minZ, maxZ = engineTestSplitShape(splitShape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
			if minY then
				Utils.renderTextAtWorldPosition(x, y, z, string.format("testSplitShape shape:%s minY:%.3f maxY:%.3f minZ:%.3f maxZ:%.3f", splitShape, minY, maxY, minZ, maxZ), 0.02)
				return minY, maxY, minZ, maxZ
			else
				Utils.renderTextAtWorldPosition(x, y, z, "testSplitShape nil", 0.02)
				return minY, maxY, minZ, maxZ
			end
		end
		testSplitShape = newTestSplitShape
		local engineRaycastClosest = raycastClosest
		local newRaycastClosest = function(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
			if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
				drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 0.8, 0, 0, true)
			end
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineRaycastClosest(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
		end
		raycastClosest = newRaycastClosest
		local engineRaycastAsyncClosest = raycastClosestAsync
		local newRaycastClosestAsync = function(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
			if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
				drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 1, 1, 1, true)
			end
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineRaycastAsyncClosest(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
		end
		raycastClosestAsync = newRaycastClosestAsync
		local engineRaycastAll = raycastAll
		local newRaycastAll = function(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
			if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
				drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 0, 0.8, 0, true)
			end
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineRaycastAll(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
		end
		raycastAll = newRaycastAll
		local engineRaycastAllAsync = raycastAllAsync
		local newRaycastAllAsync = function(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
			if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
				drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 0.1, 1, 0.1, true)
			end
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineRaycastAllAsync(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
		end
		raycastAllAsync = newRaycastAllAsync
		local engineOverlapBox = overlapBox
		local newOverlapBox = function(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
			local debugBox = DebugBox.new()
			debugBox:createFromOverlapBoxParameters(x, y, z, rx, ry, rz, ex, ey, ez):setText("overlapBox"):addToManager(nil, 1000, 50)
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineOverlapBox(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
		end
		overlapBox = newOverlapBox
		local engineOverlapBoxAsync = overlapBoxAsync
		local newOverlapBoxAsync = function(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
			local debugBox = DebugBox.new()
			debugBox:createFromOverlapBoxParameters(x, y, z, rx, ry, rz, ex, ey, ez):setText("overlapBoxAsync"):addToManager(nil, 1000, 50)
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineOverlapBoxAsync(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
		end
		overlapBoxAsync = newOverlapBoxAsync
		local engineOverlapSphere = overlapSphere
		local newOverlapSphere = function(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
			local debugSphere = DebugSphere.new()
			debugSphere:createWithWorldPos(x, y, z, radius):setText("overlapSphere"):addToManager(nil, 1000, 50)
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineOverlapSphere(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
		end
		overlapSphere = newOverlapSphere
		local engineOverlapSphereAsync = overlapSphereAsync
		local newOverlapSphereAsync = function(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
			local debugSphere = DebugSphere.new()
			debugSphere:createWithWorldPos(x, y, z, radius):setText("overlapSphereAsync"):addToManager(nil, 1000, 50)
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return engineOverlapSphereAsync(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
		end
		overlapSphereAsync = newOverlapSphereAsync
		local overlapCylinder_engine = overlapCylinder
		local overlapCylinder_new = function(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
			local debugCylinder = DebugCylinder.new()
			debugCylinder:createWithWorldPos(x, y, z, radius, height, axis):setText("overlapCylinder"):addToManager(nil, 1000, 50)
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return overlapCylinder_engine(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
		end
		overlapCylinder = overlapCylinder_new
		local overlapCylinderAsync_engine = overlapCylinderAsync
		local overlapCylinderAsync_new = function(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
			local debugCylinder = DebugCylinder.new()
			debugCylinder:createWithWorldPos(x, y, z, radius, height, axis):setText("overlapCylinder"):addToManager(nil, 1000, 50)
			local disallowed = nil
			disallowed = disallowed or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(collisionMask, disallowed) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
				printCallstack()
			end
			return overlapCylinderAsync_engine(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
		end
		overlapCylinderAsync = overlapCylinderAsync_new
	end
	function WrapFunctions.customWrappersNetwork()
		print("Injected network functions with bounds checks and stats collection")
		local networkStatsCollectionEnabled = false
		local networkStatsNumBits = {}
		local networkStatsNumBitsTotal = 0
		local networkStatsMaxVal = {}
		local networkStatsMaxSentVal = {}
		local target = {}
		function target.toggleCollection()
			networkStatsCollectionEnabled = not networkStatsCollectionEnabled
			log("networkStatsCollectionEnabled", networkStatsCollectionEnabled)
		end
		function target.resetStats(_, groupByFunction)
			networkStatsNumBits = {}
			networkStatsNumBitsTotal = 0
			networkStatsMaxVal = {}
			networkStatsMaxSentVal = {}
			print("reset network stats")
		end
		function target.printStats(_, groupByFunction)
			local filtered = {}
			for trace, numBits in pairs(networkStatsNumBits) do
				if groupByFunction then
					local trace = string.sub(trace, 1, string.findLast(trace, ":") - 1)
				end
				filtered[trace] = (filtered[trace] or 0) + numBits
			end
			local sorted = {}
			for trace, numBits in pairs(filtered) do
				table.insert(sorted, { trace, numBits })
			end
			table.sort(sorted, function(a, b)
				return b[2] < a[2]
			end)
			print("")
			setFileLogPrefixTimestamp(false)
			print("total bits send by function (integer, float and string network stream functions only):")
			for _, traceAndBits in ipairs(sorted) do
				local bits = traceAndBits[2]
				print(string.format("%10d %.3f%% %s", bits, bits / networkStatsNumBitsTotal * 100, traceAndBits[1]))
			end
			print("")
			print("max value send by function (number network stream functions only)")
			for trace, maxValSent in pairs(networkStatsMaxSentVal) do
				local maxVal = networkStatsMaxVal[trace]
				print(string.format("%s, %d/%d, %.2f%%", trace, maxValSent, maxVal, maxValSent / maxVal * 100))
			end
			setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		end
		addConsoleCommand("gsNetworkStatsPrint", "print network traffic stats", "printStats", target, "[groupByFunction=false]")
		addConsoleCommand("gsNetworkStatsReset", "reset network traffic stats", "resetStats", target)
		addConsoleCommand("gsNetworkStatsToggle", "toggle network traffic stats collection", "toggleCollection", target)
		local storeStats = function(bits, value, maxValue)
			if not networkStatsCollectionEnabled then
				return
			else
				local trace = string.format("%s:%s:%d", debug.info(3, "snl"))
				if string.contains(trace, "NetworkUtil") then
					trace = string.format("%s:%s:%d", debug.info(4, "snl"))
				end
				networkStatsNumBits[trace] = (networkStatsNumBits[trace] or 0) + bits
				networkStatsNumBitsTotal = networkStatsNumBitsTotal + bits
				if value ~= nil and type(value) == "number" then
					networkStatsMaxVal[trace] = maxValue
					networkStatsMaxSentVal[trace] = math.max(networkStatsMaxSentVal[trace] or 0, value)
				end
			end
		end
		local engineStreamWriteInt16 = streamWriteInt16
		local newStreamWriteInt16 = function(streamId, value)
			if value ~= nil and (32767 < value or value < -65536) then
				Logging.error("value %d out of bounds", value)
				printCallstack()
			end
			storeStats(16, value, 32767)
			return engineStreamWriteInt16(streamId, value)
		end
		streamWriteInt16 = newStreamWriteInt16
		local engineStreamWriteInt32 = streamWriteInt32
		local newStreamWriteInt32 = function(streamId, value)
			if value ~= nil and (2147483647 < value or value < -2147483648) then
				Logging.error("value %d out of bounds", value)
				printCallstack()
			end
			storeStats(32, value, 2147483647)
			return engineStreamWriteInt32(streamId, value)
		end
		streamWriteInt32 = newStreamWriteInt32
		local engineStreamWriteInt8 = streamWriteInt8
		local newStreamWriteInt8 = function(streamId, value)
			if value ~= nil and (127 < value or value < -128) then
				Logging.error("value %d out of bounds", value)
				printCallstack()
			end
			storeStats(8, value, 127)
			return engineStreamWriteInt8(streamId, value)
		end
		streamWriteInt8 = newStreamWriteInt8
		local engineStreamWriteIntN = streamWriteIntN
		local newStreamWriteIntN = function(streamId, value, numBits)
			if value ~= nil and (numBits ~= nil and (2 ^ (numBits - 1) - 1 < value or value < -2 ^ (numBits - 1))) then
				Logging.error("value %d out of bounds (%d bits, %d max)", value, numBits, 2 ^ (numBits - 1) - 1)
				printCallstack()
			end
			storeStats(numBits, value, 2 ^ (numBits - 1) - 1)
			return engineStreamWriteIntN(streamId, value, numBits)
		end
		streamWriteIntN = newStreamWriteIntN
		local engineStreamWriteUInt16 = streamWriteUInt16
		local newStreamWriteUInt16 = function(streamId, value)
			if value ~= nil and (65535 < value or value < 0) then
				Logging.error("value %d out of bounds", value)
				printCallstack()
			end
			storeStats(16, value, 65535)
			return engineStreamWriteUInt16(streamId, value)
		end
		streamWriteUInt16 = newStreamWriteUInt16
		local engineStreamWriteUInt32 = streamWriteUInt32
		local newStreamWriteUInt32 = function(streamId, value)
			if value ~= nil and (4294967295 < value or value < 0) then
				Logging.error("value %d out of bounds", value)
				printCallstack()
			end
			storeStats(32, value, 4294967295)
			return engineStreamWriteUInt32(streamId, value)
		end
		streamWriteUInt32 = newStreamWriteUInt32
		local engineStreamWriteUInt8 = streamWriteUInt8
		local newStreamWriteUInt8 = function(streamId, value)
			if value ~= nil and (255 < value or value < 0) then
				Logging.error("value %d out of bounds", value)
				printCallstack()
			end
			storeStats(8, value, 255)
			return engineStreamWriteUInt8(streamId, value)
		end
		streamWriteUInt8 = newStreamWriteUInt8
		local engineStreamWriteUIntN = streamWriteUIntN
		local newStreamWriteUIntN = function(streamId, value, numBits)
			if value ~= nil and (numBits ~= nil and (2 ^ numBits - 1 < value or value < 0)) then
				Logging.error("value %d out of bounds (%d bits, %d max)", value, numBits, 2 ^ numBits - 1)
				printCallstack()
			end
			storeStats(numBits, value, 2 ^ numBits - 1)
			return engineStreamWriteUIntN(streamId, value, numBits)
		end
		streamWriteUIntN = newStreamWriteUIntN
		local engineStreamWriteFloat32 = streamWriteFloat32
		local newStreamWriteFloat32 = function(streamId, value)
			storeStats(32, value, 1000000000)
			return engineStreamWriteFloat32(streamId, value)
		end
		streamWriteFloat32 = newStreamWriteFloat32
		local engineStreamWriteString = streamWriteString
		local newStreamWriteString = function(streamId, value)
			storeStats((string_len or string.len)(value) * 8)
			return engineStreamWriteString(streamId, value)
		end
		streamWriteString = newStreamWriteString
	end
	function WrapFunctions.customWrappersXML()
		print("Injected XML functions checks")
		local engine_setXMLInt = setXMLInt
		local new_setXMLInt = function(xmlFile, path, value)
			if value ~= nil then
				if 2147483647 < value or value < -2147483648 then
					Logging.xmlError(xmlFile, "value %d out of bounds", value)
					printCallstack()
				end
				if not MathUtil.isInt(value) and math.abs(value) < 100 then
					Logging.xmlError(xmlFile, "float %.3f value written as int, is this intentional?", value)
					printCallstack()
				end
			end
			return engine_setXMLInt(xmlFile, path, value)
		end
		setXMLInt = new_setXMLInt
		local engine_setXMLUInt = setXMLUInt
		local new_setXMLUInt = function(xmlFile, path, value)
			if value ~= nil then
				if value < 0 then
					Logging.xmlError(xmlFile, "negative value %f passed to setXMLUInt for %q", value, path)
					printCallstack()
				end
				if not MathUtil.isInt(value) and value < 100 then
					Logging.xmlError(xmlFile, "float %.3f value written as int in %q, is this intentional?", value, path)
					printCallstack()
				end
			end
			return engine_setXMLUInt(xmlFile, path, value)
		end
		setXMLUInt = new_setXMLUInt
		local engine_getXMLBool = getXMLBool
		local new_getXMLBool = function(xmlFile, path)
			local strVal = getXMLString(xmlFile, path)
			if strVal ~= nil and (strVal ~= "true" and strVal ~= "false") then
				Logging.xmlError(xmlFile, "trying to load malformed xml boolean value %q from %q", strVal, path)
				printCallstack()
			end
			return engine_getXMLBool(xmlFile, path)
		end
		getXMLBool = new_getXMLBool
		local engine_getXMLInt = getXMLInt
		local new_getXMLInt = function(xmlFile, path)
			local strVal = getXMLString(xmlFile, path)
			if strVal ~= nil then
				local numberVal = tonumber(strVal)
				if numberVal == nil then
					Logging.xmlError(xmlFile, "trying to load malformed xml number value %q from %q", strVal, path)
					printCallstack()
				elseif not MathUtil.isInt(numberVal) then
					Logging.xmlError(xmlFile, "trying to load float value %q as integer from %q", strVal, path)
					printCallstack()
				end
			end
			return engine_getXMLInt(xmlFile, path)
		end
		getXMLInt = new_getXMLInt
		local engine_getXMLUInt = getXMLUInt
		local new_getXMLUInt = function(xmlFile, path)
			local strVal = getXMLString(xmlFile, path)
			if strVal ~= nil then
				local numberVal = tonumber(strVal)
				if numberVal == nil then
					Logging.xmlError(xmlFile, "trying to load malformed xml number value %q from %q", strVal, path)
					printCallstack()
				elseif not MathUtil.isInt(numberVal) then
					Logging.xmlError(xmlFile, "trying to load float value %q as integer from %q", strVal, path)
					printCallstack()
				end
			end
			return engine_getXMLUInt(xmlFile, path)
		end
		getXMLUInt = new_getXMLUInt
		local engine_getXMLFloat = getXMLFloat
		local new_getXMLFloat = function(xmlFile, path)
			local strVal = getXMLString(xmlFile, path)
			if strVal ~= nil and tonumber(strVal) == nil then
				Logging.xmlError(xmlFile, "trying to load malformed xml number value %q from %q", strVal, path)
				printCallstack()
			end
			return engine_getXMLFloat(xmlFile, path)
		end
		getXMLFloat = new_getXMLFloat
	end
end
