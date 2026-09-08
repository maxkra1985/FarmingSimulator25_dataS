-- Local values: getNamespace, debugFunctionDrawLastTriggerCallbacks, debugFunctionDrawLastTriggerCallbacksElementId, string_len
if StartParams.getIsSet("scriptDebug") then
	WrapFunctions = {}
	WrapFunctions.SCRIPT_BINDING_PATH = "../tools/studio/Farming_Simulator_25_Dev.xml"
	WrapFunctions.ignore = {}
	WrapFunctions.backups = {}
	local function getNamespace(p1_)
		local v2_ = nil
		if string.contains(p1_, ":", true) then
			local v3_ = string.split
			v2_, p1_ = unpack(v3_(p1_, ":"))
		elseif string.contains(p1_, ".", true) then
			local v4_ = string.split
			v2_, p1_ = unpack(v4_(p1_, "."))
		end
		return p1_, v2_ and _G[v2_] or _G
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
		-- upvalues: (copy) getNamespace
		local v6_ = select("#", ...)
		if v6_ == 0 then
			printError("Error: no function names given\nUsage: gsFunctionWrap functionName <functionName2> ...")
		else
			for v7_ = 1, v6_ do
				local v8_ = select(v7_, ...)
				local v9_, v10_ = getNamespace(v8_)
				local v11_, v12_ = WrapFunctions.wrapFunction(v9_, v10_, v8_)
				if v11_ then
					print(string.format("%q %s", v8_, v12_))
				else
					printError("Error: " .. string.format("%q %s", v8_, v12_))
				end
			end
		end
	end
	function WrapFunctions.consoleCommandFunctionWrapClass(_, ...)
		local v13_ = select("#", ...)
		if v13_ == 0 then
			printError("Error: no function names given\nUsage: gsFunctionWrapClass ClassName <ClassName2> ...")
		else
			for v14_ = 1, v13_ do
				local v15_ = select(v14_, ...)
				local v16_, v17_ = WrapFunctions.wrapClass(v15_)
				if v16_ then
					print(v17_)
				else
					printError("Error: " .. v17_)
				end
			end
		end
	end
	function WrapFunctions.consoleCommandFunctionWrapEngine()
		local v18_ = WrapFunctions.wrapEngineFunctions()
		print(string.format("Wrapped %d functions in profiling zones", v18_))
	end
	function WrapFunctions.consoleCommandFunctionWrapEngineCategory(_, ...)
		if select("#", ...) == 0 then
			printError("Error: no function names given\nUsage: gsFunctionWrapEngineCategory CategoryName <CategoryName2> ...")
		else
			local v19_ = WrapFunctions.wrapEngineFunctions(...)
			print(string.format("Wrapped %d functions in profiling zones", v19_))
		end
	end
	function WrapFunctions.consoleCommandFunctionUnwrap()
		local v20_ = WrapFunctions.unwrapAll()
		if v20_ == 0 then
			printWarning("Warning: no functions to unwrap, use one of the gsFunctionWrap* console commands to wrap function(s) in profiling zones")
		else
			print(string.format("unwrapped %d functions", v20_))
		end
	end
	function WrapFunctions.consoleCommandFunctionVisualize()
		WrapFunctions.customWrappersPhysics()
	end
	local string_len = nil
	local v_u_22_ = nil
	local function v23_()
		-- upvalues: (ref) v_u_22_, (ref) string_len
		if v_u_22_ then
			g_debugManager:removeElementById(v_u_22_)
			v_u_22_ = nil
			return "Disabled drawing of trigger callbacks"
		else
			if string_len == nil then
				return "No draw function defined"
			end
			v_u_22_ = g_debugManager:addElement(string_len)
			return "Enabled drawing of trigger callbacks"
		end
	end
	WrapFunctions.consoleCommandDrawTriggerCallbacks = v23_
	
-- Local values: classTable, numWrapped, k, v, zoneName
function WrapFunctions.wrapClass(className, trackMemory)
		local v26_ = _G[className]
		if v26_ == nil then
			return false, string.format("No global class %q", className)
		end
		local v27_ = 0
		for v28_, v29_ in pairs(v26_) do
			if type(v29_) == "function" then
				local v30_ = className .. "." .. v28_
				if WrapFunctions.wrapFunction(v28_, v26_, v30_, trackMemory) then
					v27_ = v27_ + 1
				end
			end
		end
		return true, string.format("Wrapped %d functions for %q in profiling zones", v27_, className)
	end
	function WrapFunctions.wrapEngineFunctions(...)
		-- upvalues: (copy) getNamespace
		local v31_ = loadXMLFile("scriptBinding", WrapFunctions.SCRIPT_BINDING_PATH)
		if v31_ == 0 then
			return 0
		end
		print(string.format("WrapFunctions.wrapEngineFunctions(): loading script biding from %s", WrapFunctions.SCRIPT_BINDING_PATH))
		local v32_ = nil
		for v33_ = 1, select("#", ...) do
			v32_ = v32_ or {}
			v32_[string.upper(select(v33_, ...))] = true
		end
		if v32_ then
			print("   limit to categories: " .. table.concatKeys(v32_, ", "))
		end
		local v34_ = 0
		for v35_ = 0, getXMLNumOfElements(v31_, "scriptBinding.function") - 1 do
			local v36_ = "scriptBinding.function(" .. v35_ .. ")"
			local v37_ = getXMLString(v31_, v36_ .. "#name")
			local v38_ = getXMLString(v31_, v36_ .. "#category") or "NoCategory"
			local v39_ = string.gsub(string.upper(v38_), " ", "")
			if WrapFunctions.ignore[v37_] == nil and (not v32_ or v32_[v39_] ~= nil) then
				local v40_, v41_ = getNamespace(v37_)
				local v42_ = string.format("%s (%s)", v37_, v38_)
				if WrapFunctions.wrapFunction(v40_, v41_, v42_) then
					v34_ = v34_ + 1
				end
			end
		end
		delete(v31_)
		return v34_
	end
	
-- Local values: oldFunc, id, wrapper
function WrapFunctions.wrapFunction(name, namespace, zoneName, trackMemory)
		local v47_ = namespace or _G
		local v_u_48_ = zoneName or name
		local v_u_49_ = v47_[name]
		if type(v_u_49_) ~= "function" then
			return false, "not a function"
		end
		local v50_ = tostring(v47_) .. name
		if WrapFunctions.backups[v50_] ~= nil then
			printWarning(string.format("Warning: %q is already wrapped, ignoring", name))
			return false, "already wrapped"
		end
		WrapFunctions.backups[v50_] = { name, v47_, v_u_49_ }
		if trackMemory then
			WrapFunctions.memoryAllocations[v_u_48_] = WrapFunctions.memoryAllocations[v_u_48_] or 0
		end
		v47_[name] = function(...)
			-- upvalues: (copy) trackMemory, (ref) v_u_48_, (copy) v_u_49_
			local v51_
			if trackMemory then
				collectgarbage("collect")
				v51_ = collectgarbage("count")
			else
				v51_ = nil
			end
			RemoteProfiler.zoneBeginN(v_u_48_)
			local v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_, v67_, v68_ = v_u_49_(...)
			RemoteProfiler.zoneEnd()
			if trackMemory then
				collectgarbage("collect")
				local v69_ = collectgarbage("count") - v51_
				WrapFunctions.memoryAllocations[v_u_48_] = WrapFunctions.memoryAllocations[v_u_48_] + v69_
			end
			if v68_ == nil then
				if v67_ == nil then
					if v66_ == nil then
						if v65_ == nil then
							if v64_ == nil then
								if v63_ == nil then
									if v62_ == nil then
										if v61_ == nil then
											if v60_ == nil then
												if v59_ == nil then
													if v58_ == nil then
														if v57_ == nil then
															if v56_ == nil then
																if v55_ == nil then
																	if v54_ == nil then
																		if v53_ == nil then
																			if v52_ == nil then
																				return nil
																			else
																				return v52_
																			end
																		else
																			return v52_, v53_
																		end
																	else
																		return v52_, v53_, v54_
																	end
																else
																	return v52_, v53_, v54_, v55_
																end
															else
																return v52_, v53_, v54_, v55_, v56_
															end
														else
															return v52_, v53_, v54_, v55_, v56_, v57_
														end
													else
														return v52_, v53_, v54_, v55_, v56_, v57_, v58_
													end
												else
													return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_
												end
											else
												return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_
											end
										else
											return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_
										end
									else
										return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_
									end
								else
									return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_
								end
							else
								return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_
							end
						else
							return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_
						end
					else
						return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_
					end
				else
					return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_, v67_
				end
			else
				return v52_, v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_, v67_, v68_
			end
		end
		return true, "wrapped in profiling zone"
	end
	function WrapFunctions.unwrapAll()
		local v70_ = table.size(WrapFunctions.backups)
		for _, v71_ in pairs(WrapFunctions.backups) do
			local v72_, v73_, v74_ = unpack(v71_)
			v73_[v72_] = v74_
		end
		WrapFunctions.backups = {}
		return v70_
	end
	local v_u_75_ = nil
	local function v132_()
		-- upvalues: (ref) string_len, (ref) v_u_75_
		local v_u_76_ = {}
		string_len = DebugFunction.new(nil, function()
			-- upvalues: (copy) v_u_76_
			setTextColor(1, 1, 1, 1)
			for v77_, v78_ in ipairs(v_u_76_) do
				renderText(0.2, 0.72 + v77_ * 0.012, 0.012, v78_)
			end
		end)
		local v_u_79_ = addTrigger
		function addTrigger(p80_, p_u_81_, p_u_82_, p83_, p_u_84_)
			-- upvalues: (copy) v_u_76_, (copy) v_u_79_
			if not getHasTrigger(p80_) then
				Logging.warning("addTrigger() shape %q does not have \'trigger\' flag set", I3DUtil.getNodePath(p80_))
				printCallstack()
			end
			local v85_ = p_u_84_ or (p_u_82_[p_u_81_] or _G[p_u_81_])
			if type(v85_) ~= "function" then
				Logging.error("Unable to access given trigger callback function %q", p_u_81_)
				printCallstack()
			end
			local v86_ = ClassUtil.getClassNameByObject(p_u_82_) or (ClassUtil.getClassName(p_u_82_) or "")
			local v_u_87_ = "TriggerCallback for \'" .. getName(p80_) .. "\' " .. v86_ .. ":" .. p_u_81_
			local v88_ = {}
			local function v102_(_, p89_, p90_, p91_, p92_, p93_, ...)
				-- upvalues: (ref) v_u_76_, (copy) p_u_84_, (copy) v_u_87_, (copy) p_u_82_, (copy) p_u_81_
				local v94_ = p91_ and "onEnter" or (p92_ and "onLeave" or (p93_ and "onStay" or "unknown"))
				local v95_ = entityExists(p89_) and (I3DUtil.getNodePath(p89_, nil, true) or "<triggerDeleted>") or "<triggerDeleted>"
				local v96_ = entityExists(p90_) and (I3DUtil.getNodePath(p90_, nil, true) or "<nodeDeleted>") or "<nodeDeleted>"
				local v97_ = string.format("uli %d: trig: %s(%d) shape: %s(%d) %s ", g_updateLoopIndex, v95_, p89_, v96_, p90_, v94_)
				local v98_ = v96_ .. " (" .. p90_ .. ") " .. v94_
				local v99_ = v_u_76_
				table.insert(v99_, 1, v97_)
				if #v_u_76_ > 15 then
					table.remove(v_u_76_)
				end
				if p_u_84_ == nil then
					RemoteProfiler.zoneBeginN(v_u_87_)
					RemoteProfiler.zoneText(v98_)
					local v100_ = p_u_82_[p_u_81_](p_u_82_, p89_, p90_, p91_, p92_, p93_, ...)
					RemoteProfiler.zoneEnd()
					return v100_
				else
					RemoteProfiler.zoneBeginN(v_u_87_)
					RemoteProfiler.zoneText(v98_)
					local v101_ = p_u_84_(p_u_82_, p89_, p90_, p91_, p92_, p93_, ...)
					RemoteProfiler.zoneEnd()
					return v101_
				end
			end
			v88_.callbackFunc_inj = v102_
			if p_u_84_ == nil then
				return v_u_79_(p80_, "callbackFunc_inj", v88_, p83_)
			else
				return v_u_79_(p80_, "callbackFunc_inj", v88_, p83_, v102_)
			end
		end
		v_u_75_ = string.len
		local function v104_(p103_)
			-- upvalues: (ref) v_u_75_
			if type(p103_) == "number" then
				p103_ = tostring(p103_) or p103_
			end
			if v_u_75_(p103_) ~= utf8Strlen(p103_) then
				Logging.warning("string.len used on a string containing utf-8 characters: %s", p103_)
				printCallstack()
			end
			return v_u_75_(p103_)
		end
		string.len = v104_
		local v_u_105_ = string.sub
		local function v109_(p106_, p107_, p108_)
			-- upvalues: (ref) v_u_75_, (copy) v_u_105_
			if type(p106_) == "number" then
				p106_ = tostring(p106_) or p106_
			end
			if v_u_75_(p106_) ~= utf8Strlen(p106_) then
				Logging.warning("string.sub used on a string containing utf-8 characters: %s", p106_)
				printCallstack()
			end
			return v_u_105_(p106_, p107_, p108_)
		end
		string.sub = v109_
		local v_u_110_ = string.upper
		function string.upper(p111_)
			-- upvalues: (copy) v_u_110_
			if type(p111_) == "number" then
				p111_ = tostring(p111_) or p111_
			end
			if v_u_110_(p111_) ~= utf8ToUpper(p111_) then
				Logging.warning("string.upper used on a string containing utf-8 characters: %s", p111_)
				printCallstack()
			end
			return v_u_110_(p111_)
		end
		local v_u_112_ = string.lower
		function string.lower(p113_)
			-- upvalues: (copy) v_u_112_
			if type(p113_) == "number" then
				p113_ = tostring(p113_) or p113_
			end
			if v_u_112_(p113_) ~= utf8ToLower(p113_) then
				Logging.warning("string.lower used on a string containing utf-8 characters: %s", p113_)
				printCallstack()
			end
			return v_u_112_(p113_)
		end
		local v_u_114_ = createImageOverlay
		function createImageOverlay(p115_)
			-- upvalues: (copy) v_u_114_
			local v116_ = v_u_114_(p115_)
			if v116_ ~= 0 and (debug ~= nil and debug.traceback ~= nil) then
				setName(v116_, getName(v116_) .. "\n" .. debug.traceback(nil, 2))
			end
			return v116_
		end
		local v_u_117_ = createSample
		function createSample(p118_)
			-- upvalues: (copy) v_u_117_
			local v119_ = v_u_117_(p118_)
			if v119_ ~= 0 and (debug ~= nil and debug.traceback ~= nil) then
				setName(v119_, getName(v119_) .. "\n" .. debug.traceback(nil, 2))
			end
			return v119_
		end
		local v_u_120_ = loadSample
		function loadSample(p121_, p122_, ...)
			-- upvalues: (copy) v_u_120_
			local v123_ = v_u_120_(p121_, p122_, ...)
			if v123_ then
				setName(p121_, p122_ .. getName(p121_))
			end
			return v123_
		end
		local v_u_124_ = loadXMLFile
		function loadXMLFile(p125_, p126_)
			-- upvalues: (copy) v_u_124_
			return v_u_124_(string.format("%s - %s%s", p125_, p126_, debug and "\n" .. debug.traceback(nil, 2) or ""), p126_)
		end
		local v_u_127_ = loadXMLFileFromMemory
		function loadXMLFileFromMemory(p128_, p129_)
			-- upvalues: (copy) v_u_127_
			return v_u_127_(string.format("%s%s", p128_, debug and "\n" .. debug.traceback(nil, 2) or ""), p129_)
		end
		local v_u_130_ = fileExists
		function fileExists(p131_)
			-- upvalues: (copy) v_u_130_
			if string.endsWith(p131_, ".dds") or string.endsWith(p131_, ".png") then
				Logging.warning("\'fileExists\' called on texture file which might not exist with the specific extension on a different platform, use \'textureFileExists\' instead")
				printCallstack()
			elseif string.endsWith(p131_, ".ogg") or (string.endsWith(p131_, ".wav") or string.endsWith(p131_, ".gls")) then
				Logging.warning("\'fileExists\' called on audio file which might not exist with the specific extension on a different platform, use \'audioFileExists\' instead")
				printCallstack()
			end
			return v_u_130_(p131_)
		end
	end
	WrapFunctions.customWrappers = v132_
	function WrapFunctions.customWrappersPhysics()
		local function v_u_151_(p133_, p134_, p135_, p136_, p137_, p138_, p139_, p140_, p141_, p142_, p143_, p144_, p145_, p146_, p147_)
			local v148_, v149_, v150_ = MathUtil.crossProduct(p136_, p137_, p138_, p139_, p140_, p141_)
			DebugUtil.drawDebugPlane(p133_, p134_, p135_, v148_, v149_, v150_, p139_, p140_, p141_, p142_, p143_, p144_, p145_, p146_, p147_)
		end
		local v_u_152_ = findAndRemoveSplitShapeAttachments
		function findAndRemoveSplitShapeAttachments(p153_, p154_, p155_, p156_, p157_, p158_, p159_, p160_, p161_, p162_, p163_, p164_)
			-- upvalues: (copy) v_u_151_, (copy) v_u_152_
			v_u_151_(p153_, p154_, p155_, p156_, p157_, p158_, p159_, p160_, p161_, p163_, p164_, 1, 0, 0, 0.5)
			return v_u_152_(p153_, p154_, p155_, p156_, p157_, p158_, p159_, p160_, p161_, p162_, p163_, p164_)
		end
		local v_u_165_ = findSplitShape
		function findSplitShape(p166_, p167_, p168_, p169_, p170_, p171_, p172_, p173_, p174_, p175_, p176_)
			-- upvalues: (copy) v_u_151_, (copy) v_u_165_
			v_u_151_(p166_, p167_, p168_, p169_, p170_, p171_, p172_, p173_, p174_, p175_, p176_, 1, 0, 0, 0.5)
			local v177_, v178_, v179_, v180_, v181_ = v_u_165_(p166_, p167_, p168_, p169_, p170_, p171_, p172_, p173_, p174_, p175_, p176_)
			if v177_ == nil or v177_ == 0 then
				Utils.renderTextAtWorldPosition(p166_, p167_, p168_, "findSplitShape nil", 0.02)
				return v177_, v178_, v179_, v180_, v181_
			else
				Utils.renderTextAtWorldPosition(p166_, p167_, p168_, string.format("findSplitShape shape:%s minY:%.3f maxY:%.3f minZ:%.3f maxZ:%.3f", v177_, v178_, v179_, v180_, v181_), 0.02)
				return v177_, v178_, v179_, v180_, v181_
			end
		end
		local v_u_182_ = testSplitShape
		function testSplitShape(p183_, p184_, p185_, p186_, p187_, p188_, p189_, p190_, p191_, p192_, p193_, p194_)
			-- upvalues: (copy) v_u_151_, (copy) v_u_182_
			v_u_151_(p184_, p185_, p186_, p187_, p188_, p189_, p190_, p191_, p192_, p193_, p194_, 0, 1, 0, 0.5)
			local v195_, v196_, v197_, v198_ = v_u_182_(p183_, p184_, p185_, p186_, p187_, p188_, p189_, p190_, p191_, p192_, p193_, p194_)
			if v195_ then
				Utils.renderTextAtWorldPosition(p184_, p185_, p186_, string.format("testSplitShape shape:%s minY:%.3f maxY:%.3f minZ:%.3f maxZ:%.3f", p183_, v195_, v196_, v197_, v198_), 0.02)
				return v195_, v196_, v197_, v198_
			else
				Utils.renderTextAtWorldPosition(p184_, p185_, p186_, "testSplitShape nil", 0.02)
				return v195_, v196_, v197_, v198_
			end
		end
		local v_u_199_ = raycastClosest
		function raycastClosest(p200_, p201_, p202_, p203_, p204_, p205_, p206_, p207_, p208_, p209_)
			-- upvalues: (copy) v_u_199_
			if not DebugUtil.isPositionInCameraRange(p200_, p201_, p202_, 3) then
				drawDebugArrow(p200_, p201_, p202_, p203_ * p206_, p204_ * p206_, p205_ * p206_, 0.3, 0.3, 0.3, 0.8, 0, 0, true)
			end
			local v210_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p209_, v210_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v210_))
				printCallstack()
			end
			return v_u_199_(p200_, p201_, p202_, p203_, p204_, p205_, p206_, p207_, p208_, p209_)
		end
		local v_u_211_ = raycastClosestAsync
		function raycastClosestAsync(p212_, p213_, p214_, p215_, p216_, p217_, p218_, p219_, p220_, p221_)
			-- upvalues: (copy) v_u_211_
			if not DebugUtil.isPositionInCameraRange(p212_, p213_, p214_, 3) then
				drawDebugArrow(p212_, p213_, p214_, p215_ * p218_, p216_ * p218_, p217_ * p218_, 0.3, 0.3, 0.3, 1, 1, 1, true)
			end
			local v222_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p221_, v222_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v222_))
				printCallstack()
			end
			return v_u_211_(p212_, p213_, p214_, p215_, p216_, p217_, p218_, p219_, p220_, p221_)
		end
		local v_u_223_ = raycastAll
		function raycastAll(p224_, p225_, p226_, p227_, p228_, p229_, p230_, p231_, p232_, p233_)
			-- upvalues: (copy) v_u_223_
			if not DebugUtil.isPositionInCameraRange(p224_, p225_, p226_, 3) then
				drawDebugArrow(p224_, p225_, p226_, p227_ * p230_, p228_ * p230_, p229_ * p230_, 0.3, 0.3, 0.3, 0, 0.8, 0, true)
			end
			local v234_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p233_, v234_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v234_))
				printCallstack()
			end
			return v_u_223_(p224_, p225_, p226_, p227_, p228_, p229_, p230_, p231_, p232_, p233_)
		end
		local v_u_235_ = raycastAllAsync
		function raycastAllAsync(p236_, p237_, p238_, p239_, p240_, p241_, p242_, p243_, p244_, p245_)
			-- upvalues: (copy) v_u_235_
			if not DebugUtil.isPositionInCameraRange(p236_, p237_, p238_, 3) then
				drawDebugArrow(p236_, p237_, p238_, p239_ * p242_, p240_ * p242_, p241_ * p242_, 0.3, 0.3, 0.3, 0.1, 1, 0.1, true)
			end
			local v246_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p245_, v246_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v246_))
				printCallstack()
			end
			return v_u_235_(p236_, p237_, p238_, p239_, p240_, p241_, p242_, p243_, p244_, p245_)
		end
		local v_u_247_ = overlapBox
		function overlapBox(p248_, p249_, p250_, p251_, p252_, p253_, p254_, p255_, p256_, p257_, p258_, p259_, ...)
			-- upvalues: (copy) v_u_247_
			DebugBox.new():createFromOverlapBoxParameters(p248_, p249_, p250_, p251_, p252_, p253_, p254_, p255_, p256_):setText("overlapBox"):addToManager(nil, 1000, 50)
			local v260_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p259_, v260_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v260_))
				printCallstack()
			end
			return v_u_247_(p248_, p249_, p250_, p251_, p252_, p253_, p254_, p255_, p256_, p257_, p258_, p259_, ...)
		end
		local v_u_261_ = overlapBoxAsync
		function overlapBoxAsync(p262_, p263_, p264_, p265_, p266_, p267_, p268_, p269_, p270_, p271_, p272_, p273_, ...)
			-- upvalues: (copy) v_u_261_
			DebugBox.new():createFromOverlapBoxParameters(p262_, p263_, p264_, p265_, p266_, p267_, p268_, p269_, p270_):setText("overlapBoxAsync"):addToManager(nil, 1000, 50)
			local v274_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p273_, v274_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v274_))
				printCallstack()
			end
			return v_u_261_(p262_, p263_, p264_, p265_, p266_, p267_, p268_, p269_, p270_, p271_, p272_, p273_, ...)
		end
		local v_u_275_ = overlapSphere
		function overlapSphere(p276_, p277_, p278_, p279_, p280_, p281_, p282_, ...)
			-- upvalues: (copy) v_u_275_
			DebugSphere.new():createWithWorldPos(p276_, p277_, p278_, p279_):setText("overlapSphere"):addToManager(nil, 1000, 50)
			local v283_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p282_, v283_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v283_))
				printCallstack()
			end
			return v_u_275_(p276_, p277_, p278_, p279_, p280_, p281_, p282_, ...)
		end
		local v_u_284_ = overlapSphereAsync
		function overlapSphereAsync(p285_, p286_, p287_, p288_, p289_, p290_, p291_, ...)
			-- upvalues: (copy) v_u_284_
			DebugSphere.new():createWithWorldPos(p285_, p286_, p287_, p288_):setText("overlapSphereAsync"):addToManager(nil, 1000, 50)
			local v292_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p291_, v292_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v292_))
				printCallstack()
			end
			return v_u_284_(p285_, p286_, p287_, p288_, p289_, p290_, p291_, ...)
		end
		local v_u_293_ = overlapCylinder
		function overlapCylinder(p294_, p295_, p296_, p297_, p298_, p299_, p300_, p301_, p302_, ...)
			-- upvalues: (copy) v_u_293_
			DebugCylinder.new():createWithWorldPos(p294_, p295_, p296_, p297_, p298_, p299_):setText("overlapCylinder"):addToManager(nil, 1000, 50)
			local v303_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p302_, v303_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v303_))
				printCallstack()
			end
			return v_u_293_(p294_, p295_, p296_, p297_, p298_, p299_, p300_, p301_, p302_, ...)
		end
		local v_u_304_ = overlapCylinderAsync
		function overlapCylinderAsync(p305_, p306_, p307_, p308_, p309_, p310_, p311_, p312_, p313_, ...)
			-- upvalues: (copy) v_u_304_
			DebugCylinder.new():createWithWorldPos(p305_, p306_, p307_, p308_, p309_, p310_):setText("overlapCylinder"):addToManager(nil, 1000, 50)
			local v314_ = nil or CollisionFlag.TERRAIN_DISPLACEMENT
			if bit32.btest(p313_, v314_) then
				Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(v314_))
				printCallstack()
			end
			return v_u_304_(p305_, p306_, p307_, p308_, p309_, p310_, p311_, p312_, p313_, ...)
		end
	end
	local function v376_()
		-- upvalues: (ref) v_u_75_
		print("Injected network functions with bounds checks and stats collection")
		local v_u_315_ = false
		local v_u_316_ = {}
		local v_u_317_ = 0
		local v_u_318_ = {}
		local v_u_319_ = {}
		local v336_ = {
			["toggleCollection"] = function()
				-- upvalues: (ref) v_u_315_
				v_u_315_ = not v_u_315_
				log("networkStatsCollectionEnabled", v_u_315_)
			end,
			["resetStats"] = function(_, _)
				-- upvalues: (ref) v_u_316_, (ref) v_u_317_, (ref) v_u_318_, (ref) v_u_319_
				v_u_316_ = {}
				v_u_317_ = 0
				v_u_318_ = {}
				v_u_319_ = {}
				print("reset network stats")
			end,
			["printStats"] = function(_, p320_)
				-- upvalues: (ref) v_u_316_, (ref) v_u_317_, (ref) v_u_319_, (ref) v_u_318_
				local v321_ = {}
				for v325_, v323_ in pairs(v_u_316_) do
					if p320_ then
						local v324_ = string.findLast(v325_, ":") - 1
						local v325_ = string.sub(v325_, 1, v324_)
					end
					v321_[v325_] = (v321_[v325_] or 0) + v323_
				end
				local v326_ = {}
				for v327_, v328_ in pairs(v321_) do
					table.insert(v326_, { v327_, v328_ })
				end
				table.sort(v326_, function(p329_, p330_)
					return p329_[2] > p330_[2]
				end)
				print("")
				setFileLogPrefixTimestamp(false)
				print("total bits send by function (integer, float and string network stream functions only):")
				for _, v331_ in ipairs(v326_) do
					local v332_ = v331_[2]
					print(string.format("%10d %.3f%% %s", v332_, v332_ / v_u_317_ * 100, v331_[1]))
				end
				print("")
				print("max value send by function (number network stream functions only)")
				for v333_, v334_ in pairs(v_u_319_) do
					local v335_ = v_u_318_[v333_]
					print(string.format("%s, %d/%d, %.2f%%", v333_, v334_, v335_, v334_ / v335_ * 100))
				end
				setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
			end
		}
		addConsoleCommand("gsNetworkStatsPrint", "print network traffic stats", "printStats", v336_, "[groupByFunction=false]")
		addConsoleCommand("gsNetworkStatsReset", "reset network traffic stats", "resetStats", v336_)
		addConsoleCommand("gsNetworkStatsToggle", "toggle network traffic stats collection", "toggleCollection", v336_)
		local function v_u_343_(p337_, p338_, p339_)
			-- upvalues: (ref) v_u_315_, (ref) v_u_316_, (ref) v_u_317_, (ref) v_u_318_, (ref) v_u_319_
			if v_u_315_ then
				local v340_ = string.format("%s:%s:%d", debug.info(3, "snl"))
				if string.contains(v340_, "NetworkUtil") then
					v340_ = string.format("%s:%s:%d", debug.info(4, "snl"))
				end
				v_u_316_[v340_] = (v_u_316_[v340_] or 0) + p337_
				v_u_317_ = v_u_317_ + p337_
				if p338_ ~= nil and type(p338_) == "number" then
					v_u_318_[v340_] = p339_
					local v341_ = v_u_319_
					local v342_ = v_u_319_[v340_] or 0
					v341_[v340_] = math.max(v342_, p338_)
				end
			end
		end
		local v_u_344_ = streamWriteInt16
		function streamWriteInt16(p345_, p346_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_344_
			if p346_ ~= nil and (p346_ > 32767 or p346_ < -65536) then
				Logging.error("value %d out of bounds", p346_)
				printCallstack()
			end
			v_u_343_(16, p346_, 32767)
			return v_u_344_(p345_, p346_)
		end
		local v_u_347_ = streamWriteInt32
		function streamWriteInt32(p348_, p349_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_347_
			if p349_ ~= nil and (p349_ > 2147483647 or p349_ < -2147483648) then
				Logging.error("value %d out of bounds", p349_)
				printCallstack()
			end
			v_u_343_(32, p349_, 2147483647)
			return v_u_347_(p348_, p349_)
		end
		local v_u_350_ = streamWriteInt8
		function streamWriteInt8(p351_, p352_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_350_
			if p352_ ~= nil and (p352_ > 127 or p352_ < -128) then
				Logging.error("value %d out of bounds", p352_)
				printCallstack()
			end
			v_u_343_(8, p352_, 127)
			return v_u_350_(p351_, p352_)
		end
		local v_u_353_ = streamWriteIntN
		function streamWriteIntN(p354_, p355_, p356_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_353_
			if p355_ ~= nil and (p356_ ~= nil and (2 ^ (p356_ - 1) - 1 < p355_ or p355_ < -2 ^ (p356_ - 1))) then
				Logging.error("value %d out of bounds (%d bits, %d max)", p355_, p356_, 2 ^ (p356_ - 1) - 1)
				printCallstack()
			end
			v_u_343_(p356_, p355_, 2 ^ (p356_ - 1) - 1)
			return v_u_353_(p354_, p355_, p356_)
		end
		local v_u_357_ = streamWriteUInt16
		function streamWriteUInt16(p358_, p359_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_357_
			if p359_ ~= nil and (p359_ > 65535 or p359_ < 0) then
				Logging.error("value %d out of bounds", p359_)
				printCallstack()
			end
			v_u_343_(16, p359_, 65535)
			return v_u_357_(p358_, p359_)
		end
		local v_u_360_ = streamWriteUInt32
		function streamWriteUInt32(p361_, p362_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_360_
			if p362_ ~= nil and (p362_ > 4294967295 or p362_ < 0) then
				Logging.error("value %d out of bounds", p362_)
				printCallstack()
			end
			v_u_343_(32, p362_, 4294967295)
			return v_u_360_(p361_, p362_)
		end
		local v_u_363_ = streamWriteUInt8
		function streamWriteUInt8(p364_, p365_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_363_
			if p365_ ~= nil and (p365_ > 255 or p365_ < 0) then
				Logging.error("value %d out of bounds", p365_)
				printCallstack()
			end
			v_u_343_(8, p365_, 255)
			return v_u_363_(p364_, p365_)
		end
		local v_u_366_ = streamWriteUIntN
		function streamWriteUIntN(p367_, p368_, p369_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_366_
			if p368_ ~= nil and (p369_ ~= nil and (2 ^ p369_ - 1 < p368_ or p368_ < 0)) then
				Logging.error("value %d out of bounds (%d bits, %d max)", p368_, p369_, 2 ^ p369_ - 1)
				printCallstack()
			end
			v_u_343_(p369_, p368_, 2 ^ p369_ - 1)
			return v_u_366_(p367_, p368_, p369_)
		end
		local v_u_370_ = streamWriteFloat32
		function streamWriteFloat32(p371_, p372_)
			-- upvalues: (copy) v_u_343_, (copy) v_u_370_
			v_u_343_(32, p372_, 1000000000)
			return v_u_370_(p371_, p372_)
		end
		local v_u_373_ = streamWriteString
		function streamWriteString(p374_, p375_)
			-- upvalues: (copy) v_u_343_, (ref) v_u_75_, (copy) v_u_373_
			v_u_343_((v_u_75_ or string.len)(p375_) * 8)
			return v_u_373_(p374_, p375_)
		end
	end
	WrapFunctions.customWrappersNetwork = v376_
	function WrapFunctions.customWrappersXML()
		print("Injected XML functions checks")
		local v_u_377_ = setXMLInt
		function setXMLInt(p378_, p379_, p380_)
			-- upvalues: (copy) v_u_377_
			if p380_ ~= nil then
				if p380_ > 2147483647 or p380_ < -2147483648 then
					Logging.xmlError(p378_, "value %d out of bounds", p380_)
					printCallstack()
				end
				if not MathUtil.isInt(p380_) and math.abs(p380_) < 100 then
					Logging.xmlError(p378_, "float %.3f value written as int, is this intentional?", p380_)
					printCallstack()
				end
			end
			return v_u_377_(p378_, p379_, p380_)
		end
		local v_u_381_ = setXMLUInt
		function setXMLUInt(p382_, p383_, p384_)
			-- upvalues: (copy) v_u_381_
			if p384_ ~= nil then
				if p384_ < 0 then
					Logging.xmlError(p382_, "negative value %f passed to setXMLUInt for %q", p384_, p383_)
					printCallstack()
				end
				if not MathUtil.isInt(p384_) and p384_ < 100 then
					Logging.xmlError(p382_, "float %.3f value written as int in %q, is this intentional?", p384_, p383_)
					printCallstack()
				end
			end
			return v_u_381_(p382_, p383_, p384_)
		end
		local v_u_385_ = getXMLBool
		function getXMLBool(p386_, p387_)
			-- upvalues: (copy) v_u_385_
			local v388_ = getXMLString(p386_, p387_)
			if v388_ ~= nil and (v388_ ~= "true" and v388_ ~= "false") then
				Logging.xmlError(p386_, "trying to load malformed xml boolean value %q from %q", v388_, p387_)
				printCallstack()
			end
			return v_u_385_(p386_, p387_)
		end
		local v_u_389_ = getXMLInt
		function getXMLInt(p390_, p391_)
			-- upvalues: (copy) v_u_389_
			local v392_ = getXMLString(p390_, p391_)
			if v392_ ~= nil then
				local v393_ = tonumber(v392_)
				if v393_ == nil then
					Logging.xmlError(p390_, "trying to load malformed xml number value %q from %q", v392_, p391_)
					printCallstack()
				elseif not MathUtil.isInt(v393_) then
					Logging.xmlError(p390_, "trying to load float value %q as integer from %q in %q", v392_, p391_)
					printCallstack()
				end
			end
			return v_u_389_(p390_, p391_)
		end
		local v_u_394_ = getXMLUInt
		function getXMLUInt(p395_, p396_)
			-- upvalues: (copy) v_u_394_
			local v397_ = getXMLString(p395_, p396_)
			if v397_ ~= nil then
				local v398_ = tonumber(v397_)
				if v398_ == nil then
					Logging.xmlError(p395_, "trying to load malformed xml number value %q from %q in %q", v397_, p396_)
					printCallstack()
				elseif not MathUtil.isInt(v398_) then
					Logging.xmlError(p395_, "trying to load float value %q as integer from %q in %q", v397_, p396_)
					printCallstack()
				end
			end
			return v_u_394_(p395_, p396_)
		end
		local v_u_399_ = getXMLFloat
		function getXMLFloat(p400_, p401_)
			-- upvalues: (copy) v_u_399_
			local v402_ = getXMLString(p400_, p401_)
			if v402_ ~= nil and tonumber(v402_) == nil then
				Logging.xmlError(p400_, "trying to load malformed xml number value %q from %q", v402_, p401_)
				printCallstack()
			end
			return v_u_399_(p400_, p401_)
		end
	end
end
