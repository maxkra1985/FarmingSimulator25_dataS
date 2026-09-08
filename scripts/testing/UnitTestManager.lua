UnitTestManager = {}
UnitTestManager.UNIT_TESTS_DIRECTORY = "dataS/scripts/testing/unitTests/"
UnitTestManager.TEST_FUNCTION_PREFIX = "test_"
function UnitTestManager.testAll()
	executeConsoleCommand("debuggerPopups false", true)
	local v1_ = Assert.doErrorOnFail
	local v2_ = Assert.doCallstackOnFail
	Assert.doErrorOnFail = true
	Assert.doCallstackOnFail = false
	print("\n Beginning unit tests:")
	local v3_ = Files.new(UnitTestManager.UNIT_TESTS_DIRECTORY)
	local v4_ = 0
	local v5_ = 0
	local v6_ = 0
	for _, v7_ in pairs(v3_.files) do
		if not v7_.isDirectory then
			local v8_, v9_ = Utils.getFilenameInfo(v7_.filename)
			if v9_ == "lua" then
				source(UnitTestManager.UNIT_TESTS_DIRECTORY .. v7_.filename)
				local v10_ = _G[v8_]
				local v11_ = #v8_ - 4
				local v12_ = string.sub(v8_, 1, v11_)
				local v13_ = UnitTestManager.testClass(v12_, v10_)
				v4_ = v4_ + 1
				if v13_ then
					v5_ = v5_ + 1
				else
					v6_ = v6_ + 1
				end
			else
				Logging.warning("Cannot test non-lua file: %s", v7_.filename)
			end
		end
	end
	(v6_ <= 0 and UnitTestManager.logTotalSuccess or UnitTestManager.logTotalFailure)(v4_, v5_, v6_)
	Assert.doErrorOnFail = v1_
	Assert.doCallstackOnFail = v2_
end

-- Local values: startTime, totalRunFunctionsCount, passedFunctionsCount, failedFunctionsCount, memberName, member, functionName, status, succeeded, logFunction
function UnitTestManager.testClass(className, class)
	print(string.format("  Testing %s class: ", className))
	local v16_ = getTimeSec()
	local v17_ = 0
	local v18_ = 0
	local v19_ = 0
	for v20_, v21_ in pairs(class) do
		if type(v21_) == "function" and string.startsWith(v20_, UnitTestManager.TEST_FUNCTION_PREFIX) then
			local v22_ = #UnitTestManager.TEST_FUNCTION_PREFIX + 1
			local v_u_23_ = string.sub(v20_, v22_)
			if xpcall(v21_, function(p24_)
				-- upvalues: (copy) v_u_23_
				UnitTestManager.logFunctionFailure(v_u_23_, p24_)
			end) then
				UnitTestManager.logFunctionSuccess(v_u_23_)
				v17_ = v17_ + 1
			else
				v19_ = v19_ + 1
			end
			v18_ = v18_ + 1
		end
	end
	local v25_ = v19_ <= 0
	(v25_ and UnitTestManager.logClassSuccess or UnitTestManager.logClassFailure)(v18_, className, v17_, v19_, (getTimeSec() - v16_) * 1000)
	return v25_
end

function UnitTestManager.logTotalSuccess(totalRunClassesCount, passedClassesCount, failedClassesCount)
	print(string.format("\226\156\148 Finished %d class tests. (%d passed, %d failed)\n", totalRunClassesCount, passedClassesCount, failedClassesCount))
end

function UnitTestManager.logTotalFailure(totalRunClassesCount, passedClassesCount, failedClassesCount)
	printError(string.format("\226\157\140 Finished %d class tests. (%d passed, %d failed)\n", totalRunClassesCount, passedClassesCount, failedClassesCount))
end

function UnitTestManager.logClassSuccess(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount, elapsedMilliSeconds)
	print(string.format("  \226\156\148 Finished %d tests for %s class in %dms. (%d passed, %d failed)\n", totalRunFunctionsCount, className, elapsedMilliSeconds, passedFunctionsCount, failedFunctionsCount))
end

function UnitTestManager.logClassFailure(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount, elapsedMilliSeconds)
	printError(string.format("  \226\157\140 Finished %d tests for %s class in %dms. (%d passed, %d failed)\n", totalRunFunctionsCount, className, elapsedMilliSeconds, passedFunctionsCount, failedFunctionsCount))
end

function UnitTestManager.logFunctionSuccess(functionName)
	print(string.format("     \226\156\148 %s passed", functionName))
end

function UnitTestManager.logFunctionFailure(functionName, message)
	printError(string.format("     \226\157\140 %s failed: ", functionName))
	print("       " .. message)
	printCallstack()
end
