-- Local values: I3DManager_mt, winterMask
I3DManager = {}
I3DManager.VERBOSE_LOADING = true
I3DManager.DEBUG_LOADING_CHECKS = {}
local I3DManager_mt = Class(I3DManager)

-- Upvalues: I3DManager_mt
-- Local values: self
function I3DManager.new(customMt)
	-- upvalues: (copy) I3DManager_mt
	local v3_ = customMt or I3DManager_mt
	local v4_ = setmetatable({}, v3_)
	addConsoleCommand("gsI3DLoadingDelaySet", "Sets loading delay for i3d files", "consoleCommandSetLoadingDelay", v4_, "minDelaySec; [maxDelaySec]; [minDelayCachedSec]; [maxDelayCachedSec]")
	addConsoleCommand("gsI3DCacheShow", "Show active i3d cache", "consoleCommandShowCache", v4_)
	addConsoleCommand("gsI3DPrintActiveLoadings", "Print active loadings", "consoleCommandPrintActiveLoadings", v4_)
	return v4_
end

-- Local values: loadingDelay
function I3DManager:init()
	local v6_ = StartParams.getValue
	local v7_ = tonumber(v6_("i3dLoadingDelay"))
	if v7_ ~= nil and v7_ > 0 then
		CaptionUtil.addText("- I3D Delay (" .. v7_ .. "ms)")
		self:setLoadingDelay(v7_ / 1000)
	end
	if StartParams.getIsSet("scriptDebug") then
		self:setupDebugLoading()
	end
end

-- Local values: profilePath, numSharedI3ds, data, i, filename, numRefs, posX, posY, _, item
function I3DManager:drawDebug()
	if I3DManager.showCache then
		local v8_ = getUserProfileAppPath()
		local v9_ = getNumOfSharedI3DFiles()
		local v10_ = table.create(v9_)
		for v11_ = 0, v9_ - 1 do
			local v12_, v13_ = getSharedI3DFilesData(v11_)
			local v14_ = {
				["filename"] = string.gsub(v12_, v8_, ""),
				["numRefs"] = v13_
			}
			table.insert(v10_, v14_)
		end
		table.sort(v10_, function(p15_, p16_)
			return p15_.filename < p16_.filename
		end)
		local v17_ = 0.01
		local v18_ = 0.99
		for _, v19_ in ipairs(v10_) do
			setTextAlignment(RenderText.ALIGN_LEFT)
			local v20_ = renderText
			local v21_ = v19_.numRefs
			v20_(v17_, v18_, 0.01, "Refcount: " .. tostring(v21_))
			local v22_ = renderText
			local v23_ = v17_ + 0.04
			local v24_ = v19_.filename
			v22_(v23_, v18_, 0.01, "File: " .. tostring(v24_))
			v18_ = v18_ - 0.011
			if v18_ < 0 then
				v17_ = v17_ + 0.3
				v18_ = 0.99
			end
		end
	end
end

-- Local values: node, sharedLoadRequestId, failedReason
function I3DManager:loadSharedI3DFile(filename, callOnCreate, addToPhysics)
	local v28_ = Utils.getNoNil(callOnCreate, false)
	local v29_ = Utils.getNoNil(addToPhysics, false)
	local v30_, v31_, v32_ = loadSharedI3DFile(filename, v29_, v28_, I3DManager.VERBOSE_LOADING)
	return v30_, v31_, v32_
end

-- Local values: arguments, sharedLoadRequestId
function I3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v40_ = filename ~= nil
	assert(v40_, "I3DManager:loadSharedI3DFileAsync - missing filename")
	local v41_ = asyncCallbackFunction ~= nil
	assert(v41_, "I3DManager:loadSharedI3DFileAsync - missing callback function")
	local v42_ = type(asyncCallbackFunction) == "function"
	assert(v42_, "I3DManager:loadSharedI3DFileAsync - Callback value is not a function")
	local v43_ = Utils.getNoNil(callOnCreate, false)
	local v44_ = Utils.getNoNil(addToPhysics, false)
	return streamSharedI3DFile(filename, "loadSharedI3DFileAsyncFinished", self, {
		["asyncCallbackFunction"] = asyncCallbackFunction,
		["asyncCallbackObject"] = asyncCallbackObject,
		["asyncCallbackArguments"] = asyncCallbackArguments
	}, v44_, v43_, I3DManager.VERBOSE_LOADING)
end

-- Local values: asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments
function I3DManager:loadSharedI3DFileAsyncFinished(nodeId, failedReason, arguments)
	arguments.asyncCallbackFunction(arguments.asyncCallbackObject, nodeId, failedReason, arguments.asyncCallbackArguments)
end

-- Local values: node
function I3DManager:loadI3DFile(filename, callOnCreate, addToPhysics)
	local v51_ = Utils.getNoNil(callOnCreate, false)
	local v52_ = Utils.getNoNil(addToPhysics, false)
	return loadI3DFile(filename, v52_, v51_, I3DManager.VERBOSE_LOADING)
end

-- Local values: arguments, loadRequestId
function I3DManager:loadI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v60_ = filename ~= nil
	assert(v60_, "I3DManager:loadI3DFileAsync - missing filename")
	local v61_ = asyncCallbackFunction ~= nil
	assert(v61_, "I3DManager:loadI3DFileAsync - missing callback function")
	local v62_ = type(asyncCallbackFunction) == "function"
	assert(v62_, "I3DManager:loadI3DFileAsync - Callback value is not a function")
	local v63_ = Utils.getNoNil(callOnCreate, false)
	local v64_ = Utils.getNoNil(addToPhysics, false)
	return streamI3DFile(filename, "loadSharedI3DFileFinished", self, {
		["asyncCallbackFunction"] = asyncCallbackFunction,
		["asyncCallbackObject"] = asyncCallbackObject,
		["asyncCallbackArguments"] = asyncCallbackArguments
	}, v64_, v63_, I3DManager.VERBOSE_LOADING)
end

-- Local values: asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments
function I3DManager:loadSharedI3DFileFinished(nodeId, failedReason, arguments)
	arguments.asyncCallbackFunction(arguments.asyncCallbackObject, nodeId, failedReason, arguments.asyncCallbackArguments)
end

function I3DManager:cancelStreamI3DFile(loadingRequestId)
	if loadingRequestId == nil then
		Logging.error("I3DManager:cancelStreamedI3dFile - loadingRequestId is nil")
		printCallstack()
	else
		cancelStreamI3DFile(loadingRequestId)
	end
end

function I3DManager:releaseSharedI3DFile(sharedLoadRequestId, warnIfInvalid)
	if sharedLoadRequestId == nil then
		Logging.error("I3DManager:releaseSharedI3DFile - sharedLoadRequestId is nil")
		printCallstack()
	else
		local v71_ = Utils.getNoNil(warnIfInvalid, false)
		local _ = g_isDevelopmentVersion
		releaseSharedI3DFile(sharedLoadRequestId, v71_)
	end
end

function I3DManager:pinSharedI3DFileInCache(filename)
	if filename == nil then
		Logging.error("I3DManager:pinSharedI3DFileInCache - Filename is nil")
		printCallstack()
	elseif getSharedI3DFileRefCount(filename) < 0 then
		pinSharedI3DFileInCache(filename, true)
		return
	end
end

function I3DManager:unpinSharedI3DFileInCache(filename)
	if filename == nil then
		Logging.error("I3DManager:unpinSharedI3DFileInCache - filename is nil")
		printCallstack()
	else
		unpinSharedI3DFileInCache(filename)
	end
end

-- Local values: numSharedI3ds, i, filename, numRefs
function I3DManager:clearEntireSharedI3DFileCache(verbose)
	if verbose == true then
		local v75_ = getNumOfSharedI3DFiles()
		Logging.devInfo("I3DManager: Deleting %s shared i3d files", v75_)
		for v76_ = 0, v75_ - 1 do
			local v77_, v78_ = getSharedI3DFilesData(v76_)
			Logging.devWarning("    NumRef: %d - File: %s", v78_, v77_)
		end
	end
	Logging.devInfo("I3DManager: Deleted shared i3d files")
	clearEntireSharedI3DFileCache()
end

function I3DManager:setLoadingDelay(minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
	local v83_ = minDelaySeconds or 0
	local v84_ = maxDelaySeconds or v83_
	local v85_ = minDelayCachedSeconds or v83_
	local v86_ = maxDelayCachedSeconds or v84_
	setStreamI3DFileDelay(v83_, v84_)
	setStreamSharedI3DFileDelay(v83_, v84_, v85_, v86_)
	Logging.info("Set new loading delay. MinDelay: %.2fs, MaxDelay: %.2fs, MinDelayCached: %.2fs, MaxDelayCached: %.2fs", v83_, v84_, v85_, v86_)
end

function I3DManager:consoleCommandSetLoadingDelay(minDelaySec, maxDelaySec, minDelayCachedSec, maxDelayCachedSec)
	local v92_ = tonumber(minDelaySec) or 0
	local v93_ = tonumber(maxDelaySec) or v92_
	self:setLoadingDelay(v92_, v93_, tonumber(minDelayCachedSec) or v92_, tonumber(maxDelayCachedSec) or v93_)
end

function I3DManager:consoleCommandShowCache()
	I3DManager.showCache = not I3DManager.showCache
	if g_debugManager ~= nil then
		if I3DManager.showCache then
			g_debugManager:addDrawable(self)
		else
			g_debugManager:removeDrawable(self)
		end
	end
	local v95_ = print
	local v96_ = I3DManager.showCache
	v95_("showCache=" .. tostring(v96_))
end

-- Local values: loadingRequestIds, k, loadingRequestId, progress, timeSec, filename, callback, target, args, text, sharedLoadingRequestIds, k, sharedLoadingRequestId, progress, timeSec, filename, callback, target, args, text
function I3DManager:consoleCommandPrintActiveLoadings()
	print("Non-Shared loading tasks:")
	local v97_ = getAllStreamI3DFileRequestIds()
	if #v97_ == 0 then
		print("none")
	else
		for _, v98_ in ipairs(v97_) do
			local v99_, v100_, v101_, v102_, v103_, v104_ = getStreamI3DFileProgressInfo(v98_)
			local v105_ = string.format("%03d: Progress: %s | Time %.3fs | File: %s | Callback: %s | Target: %s | Args: %s", v98_, v99_, v100_, v101_, v102_, tostring(v103_), (tostring(v104_)))
			print(v105_)
		end
	end
	print("")
	print("Shared loading tasks:")
	local v106_ = getAllSharedI3DFileRequestIds()
	if #v106_ == 0 then
		print("none")
	else
		for _, v107_ in ipairs(v106_) do
			local v108_, v109_, v110_, v111_, v112_, v113_ = getSharedI3DFileProgressInfo(v107_)
			local v114_ = string.format("%03d: Progress: %s | Time %.3fs | File: %s | Callback: %s | Target: %s | Args: %s", v107_, v108_, v109_, v110_, v111_, tostring(v112_), (tostring(v113_)))
			print(v114_)
		end
	end
end
g_i3DManager = I3DManager.new()

function I3DManager.addDebugLoadingCheck(name, checkFunc)
	if StartParams and StartParams.getIsSet("scriptDebug") then
		local v117_ = I3DManager.DEBUG_LOADING_CHECKS
		table.insert(v117_, {
			["checkFunc"] = checkFunc,
			["name"] = name
		})
	end
end

-- Local values: traceRequest, checkRequestIdIsValid, runDebugChecksOnNode, oldLoadI3DFile, loadI3DFile_injection, oldLoadSharedI3dFile, loadSharedI3DFile_injection, oldStreamI3DFile, streamI3DFile_injection, oldStreamSharedI3DFile, streamSharedI3DFile_inection, oldCancelStreamI3DFile, cancelStreamI3DFile_injection, oldReleaseSharedI3DFile, releaseSharedI3DFile_injection
function I3DManager:setupDebugLoading()
	printWarning("\n\n  ##################   Warning: I3D-Manager Debug checks are active!   ##################\n\n")
	self.debugTracingActive = StartParams.getIsSet("i3dTracing")
	if self.debugTracingActive then
		printWarning("\n\n  ##################   Warning: I3D-Manager Debug tracing is active !   ##################\n\n")
		self.debugPendingRequests = {}
	end
	local function v_u_124_(p119_, p120_, p121_, p122_)
		-- upvalues: (copy) self
		log(p119_, "requestId", p122_.loadRequestId, p122_.filename, "nodeId", p120_, "failedReason", I3DManager.getFailedReasonName(p121_), "updateLoopIndex", g_updateLoopIndex)
		local v123_ = p122_.loadRequestId
		print("    pendingRequestIds (including current callback): " .. table.concat(self.debugPendingRequests, " "))
		if not table.removeElement(self.debugPendingRequests, v123_) then
			printError(string.format("    Error: unable to remove requestId %d from pendingRequests, no pending request for this id", v123_))
		end
		if #self.debugPendingRequests == 0 then
			print("    no more pending requests")
		end
	end
	
-- Local values: numMatches, i
function I3DManager.checkRecursive(filename, node, delegate)
		local v128_ = 0
		if delegate(filename, node) then
			v128_ = v128_ + 1
		end
		for v129_ = 0, getNumOfChildren(node) - 1 do
			v128_ = v128_ + I3DManager.checkRecursive(filename, getChildAt(node, v129_), delegate)
		end
		return v128_
	end
	local function v_u_134_(p130_, p131_)
		if p131_ > 0 then
			for _, v132_ in ipairs(I3DManager.DEBUG_LOADING_CHECKS) do
				local v133_ = I3DManager.checkRecursive(p130_, p131_, v132_.checkFunc)
				if v133_ > 0 then
					Logging.devInfo("Finished \'%s\' check with %d matches for \'%s\'", v132_.name, v133_, p130_ or "")
				end
			end
		end
	end
	local v_u_135_ = loadI3DFile
	function loadI3DFile(p136_, ...)
		-- upvalues: (copy) v_u_135_, (copy) v_u_134_
		local v137_, _, _ = v_u_135_(p136_, ...)
		v_u_134_(p136_, v137_)
		return v137_
	end
	local v_u_138_ = loadSharedI3DFile
	function loadSharedI3DFile(p139_, ...)
		-- upvalues: (copy) v_u_138_, (copy) v_u_134_
		local v140_, v141_, v142_ = v_u_138_(p139_, ...)
		v_u_134_(p139_, v140_)
		return v140_, v141_, v142_
	end
	local v_u_143_ = streamI3DFile
	function streamI3DFile(p144_, p145_, p146_, p147_, ...)
		-- upvalues: (copy) v_u_143_, (copy) self
		local v148_ = {
			["target"] = p146_,
			["callbackFunc"] = p145_,
			["params"] = p147_,
			["filename"] = p144_
		}
		local v149_ = v_u_143_(p144_, "streamI3DCallback_injection", I3DManager, v148_, ...)
		if self.debugTracingActive then
			log("streamI3DFile", "requestId", v149_, p144_, "callback", v148_.callbackFunc, "updateLoopIndex", g_updateLoopIndex)
			v148_.filename = p144_
			v148_.loadRequestId = v149_
			local v150_ = self.debugPendingRequests
			table.insert(v150_, v149_)
		end
		return v149_
	end
	
-- Upvalues: self, checkRequestIdIsValid, runDebugChecksOnNode
-- Local values: target, callbackFunc, params
function I3DManager.streamI3DCallback_injection(_, nodeId, failedReason, arguments)
		-- upvalues: (copy) self, (copy) v_u_124_, (copy) v_u_134_
		local v154_ = arguments.target
		local v155_ = arguments.callbackFunc
		local v156_ = arguments.params or {}
		if self.debugTracingActive then
			v_u_124_("streamI3DCallback", nodeId, failedReason, arguments)
		end
		v_u_134_(arguments.filename, nodeId)
		v154_[v155_](v154_, nodeId, failedReason, v156_)
	end
	local v_u_157_ = streamSharedI3DFile
	function streamSharedI3DFile(p158_, p159_, p160_, p161_, ...)
		-- upvalues: (copy) v_u_157_, (copy) self
		local v162_ = {
			["target"] = p160_,
			["callbackFunc"] = p159_,
			["filename"] = p158_,
			["params"] = p161_
		}
		local v163_ = v_u_157_(p158_, "streamSharedI3DCallback_injection", I3DManager, v162_, ...)
		if self.debugTracingActive then
			log("streamSharedI3DFile", "requestId", v163_, p158_, "callback", v162_.callbackFunc, "updateLoopIndex", g_updateLoopIndex)
			v162_.filename = p158_
			v162_.loadRequestId = v163_
			local v164_ = self.debugPendingRequests
			table.insert(v164_, v163_)
		end
		return v163_
	end
	
-- Upvalues: self, checkRequestIdIsValid, runDebugChecksOnNode
-- Local values: target, callbackFunc, params
function I3DManager.streamSharedI3DCallback_injection(_, nodeId, failedReason, arguments)
		-- upvalues: (copy) self, (copy) v_u_124_, (copy) v_u_134_
		local v168_ = arguments.target
		local v169_ = arguments.callbackFunc
		local v170_ = arguments.params or {}
		if self.debugTracingActive then
			v_u_124_("streamSharedI3DCallback", nodeId, failedReason, arguments)
		end
		v_u_134_(arguments.filename, nodeId)
		v168_[v169_](v168_, nodeId, failedReason, v170_)
	end
	if self.debugTracingActive then
		local v_u_171_ = cancelStreamI3DFile
		function cancelStreamI3DFile(p172_)
			-- upvalues: (copy) self, (copy) v_u_171_
			log("cancelStreamI3DFile", p172_, "updateLoopIndex", g_updateLoopIndex)
			table.removeElement(self.debugPendingRequests, p172_)
			return v_u_171_(p172_)
		end
		local v_u_173_ = releaseSharedI3DFile
		function releaseSharedI3DFile(p174_, ...)
			-- upvalues: (copy) self, (copy) v_u_173_
			log("releaseSharedI3DFile", p174_, "updateLoopIndex", g_updateLoopIndex)
			if getSharedI3DFileProgressInfo(p174_) ~= "PROGRESS_UNKNOWN" then
				printWarning("    releaseSharedI3DFile while request was still pending, same effect as cancelStreamI3DFile")
				table.removeElement(self.debugPendingRequests, p174_)
			end
			return v_u_173_(p174_, ...)
		end
	end
end

-- Local values: failedReasonName, value
function I3DManager.getFailedReasonName(failedReason)
	for v176_, v177_ in pairs(LoadI3DFailedReason) do
		if v177_ == failedReason then
			return v176_
		end
	end
	return string.format("<undefined failedReason \'%d\'>", failedReason)
end
I3DManager.addDebugLoadingCheck("Directional-Lights", function(_, p178_)
	if not getHasClassId(p178_, ClassIds.LIGHT_SOURCE) or (g_currentMission == nil or (getLightType(p178_) ~= LightType.DIRECTIONAL or p178_ == g_currentMission.environment.lighting.sunLightId)) then
		return false
	end
	if getName(p178_) == "licensePlateCreationBoxLight" then
		return false
	end
	if getName(p178_) == "colorPickerOverlayDirectionalLight" then
		return false
	end
	Logging.devWarning("    Light-Check: Found directional light \'%s\'", I3DUtil.getNodePath(p178_))
	return true
end)
I3DManager.addDebugLoadingCheck("Collision mask check", function(_, p179_)
	if getHasClassId(p179_, ClassIds.SHAPE) and getHasCollision(p179_) then
		local v180_ = getRigidBodyType(p179_)
		if v180_ == RigidBodyType.NONE then
			return false
		end
		local v181_ = getCollisionFilterGroup(p179_)
		if v180_ ~= RigidBodyType.DYNAMIC then
			local v182_ = CollisionFlag.DYNAMIC_OBJECT
			if bit32.btest(v181_, v182_) and g_currentMission:getNodeObject(p179_) == nil then
				Logging.i3dWarning(p179_, "non-dynamic collision has \'DYNAMIC_OBJECT\' collision group bit set")
				return true
			end
		end
	end
	return false
end)
I3DManager.addDebugLoadingCheck("tip col properties", function(_, p183_)
	local v184_ = false
	if getHasClassId(p183_, ClassIds.SHAPE) then
		local v185_ = string.contains(string.upper(getName(p183_)), "TIPCOL")
		if v185_ then
			if not CollisionFlag.getHasGroupFlagSet(p183_, CollisionFlag.GROUND_TIP_BLOCKING) then
				Logging.devWarning("node is named tipcol but does not have %s set: %s", CollisionFlag.getBitAndName(CollisionFlag.GROUND_TIP_BLOCKING), I3DUtil.getNodePath(p183_))
				v184_ = true
			end
			if getRigidBodyType(p183_) ~= RigidBodyType.STATIC then
				Logging.devWarning("tip col not static %s", I3DUtil.getNodePath(p183_))
				v184_ = true
			end
		end
		if CollisionFlag.getHasGroupFlagSet(p183_, CollisionFlag.GROUND_TIP_BLOCKING) then
			if v185_ then
				local v186_ = getRigidBodyType(p183_)
				if v186_ ~= RigidBodyType.STATIC then
					Logging.devWarning("node %q has tip col flag but is not STATIC but %s", I3DUtil.getNodePath(p183_), EnumUtil.getName(RigidBodyType, v186_))
					v184_ = true
				end
				if getCollisionFilterMask(p183_) ~= 1 then
					Logging.devWarning("node %q has tip col flag mask is not 1", I3DUtil.getNodePath(p183_))
					v184_ = true
				end
				if CollisionFlag.getHasGroupFlagSet(p183_, CollisionFlag.STATIC_OBJECT) then
					Logging.devWarning("node %q has STATIC_OBJECT flag set", I3DUtil.getNodePath(p183_))
					v184_ = true
				end
			end
			for v187_ = 0, getNumOfUserAttributes(p183_) - 1 do
				local _, v188_, v189_ = getUserAttributeByIndex(p183_, v187_)
				if v188_ == "collisionHeight" and v189_ ~= UserAttributeType.FLOAT then
					Logging.devWarning("node %q has tip col flag with user attribute %q of wrong type %q. Only \'collisionHeight\' of type \'Float\' is supported", I3DUtil.getNodePath(p183_), v188_, EnumUtil.getName(UserAttributeType, v189_))
					v184_ = true
				end
			end
		end
	end
	return v184_
end)
I3DManager.addDebugLoadingCheck("LOD Checks", function(_, p190_)
	if not (getIsLODTransformGroup(p190_) and getVisibility(p190_)) then
		return false
	end
	local v191_ = false
	for _, v192_ in I3DUtil.iteratorChildren(p190_) do
		if not (getVisibility(v192_) or getHasClassId(v192_, ClassIds.SHAPE) and getIsNonRenderable(v192_)) then
			Logging.devWarning("LOD is hidden - Node: %s   NodeIndex: %s", I3DUtil.getNodePath(v192_), I3DUtil.getNodePathIndices(v192_))
			v191_ = true
		end
	end
	return v191_
end)
I3DManager.addDebugLoadingCheck("Occluder Checks", function(_, p193_)
	if getHasClassId(p193_, ClassIds.SHAPE) then
		local v194_ = getName(p193_)
		local v195_ = getIsOccluderMesh(p193_)
		local v196_ = string.contains(utf8ToUpper(v194_), "OCCLUDER")
		if v196_ or v195_ then
			local v197_ = false
			if v196_ and not v195_ then
				Logging.devWarning("Mesh is named occluder but does not have the occluder mesh flag set - Node: %s", I3DUtil.getNodePath(p193_))
				v197_ = true
			elseif not v196_ and v195_ then
				Logging.devWarning("Mesh has occluder flag set but is not named \'occluder\' - Node: %s", I3DUtil.getNodePath(p193_))
				v197_ = true
			end
			if v195_ then
				if not (getVisibility(p193_) and getVisibility(getParent(p193_))) then
					Logging.devWarning("Occluder mesh (or any of its parent nodes) is not visible and will not function. Use \'non-renderable\' flag for hiding the shape instead - Node: %s", I3DUtil.getNodePath(p193_))
					v197_ = true
				end
				local _, _, _, v198_ = getShapeBoundingSphere(p193_)
				if v198_ < 3 then
					Logging.devWarning("Occluder is very small and should probably be removed, bounding radius %.3f - Node: %s", v198_, I3DUtil.getNodePath(p193_))
					v197_ = true
				end
			end
			return v197_
		end
	end
	return false
end)
I3DManager.addDebugLoadingCheck("ScaledTrees", function(_, p199_)
	local v200_ = false
	if getHasClassId(p199_, ClassIds.MESH_SPLIT_SHAPE) then
		local v201_ = getParent(p199_)
		if v201_ ~= 0 then
			local v202_, v203_, v204_ = getScale(v201_)
			if v202_ ~= 1 or (v203_ ~= 1 or v204_ ~= 1) then
				Logging.devWarning("Scaled tree shape found - Node: %s (%s)", I3DUtil.getNodePath(p199_), I3DUtil.getNodePathIndices(p199_))
				v200_ = true
			end
		end
	end
	return v200_
end)
I3DManager.addDebugLoadingCheck("TerrainDecal", function(_, p205_)
	if not (getHasClassId(p205_, ClassIds.SHAPE) and getIsTerrainDecal(p205_)) then
		return false
	end
	local v206_
	if getIsNonRenderable(p205_) or not getIsRenderedInViewports(p205_) then
		v206_ = false
	else
		Logging.devWarning("Terrain decal without nonRenderable==true or getIsRenderedInViewports==false - Node: %s", I3DUtil.getNodePath(p205_))
		v206_ = true
	end
	if getRigidBodyType(p205_) ~= RigidBodyType.NONE then
		local v207_ = CollisionFlag.AI_BLOCKING
		local v208_ = CollisionFlag.PLACEMENT_BLOCKING
		local v209_ = CollisionFlag.CAMERA_BLOCKING
		local v210_ = CollisionFlag.GROUND_TIP_BLOCKING
		local v211_ = bit32.bor(v207_, v208_, v209_, v210_)
		local v212_ = getCollisionFilterGroup(p205_)
		local v213_ = bit32.bnot(v211_)
		if bit32.band(v212_, v213_) ~= 0 then
			Logging.devWarning("Terrain decal has collision enabled - Node: %s", I3DUtil.getNodePath(p205_))
			v206_ = true
		end
	end
	return v206_
end)
I3DManager.addDebugLoadingCheck("DecalLayerGrids", function(_, p214_)
	if not getHasClassId(p214_, ClassIds.SHAPE) or (getShapeDecalLayer(p214_) == 0 or not (string.contains(string.lower(getName(p214_)), "grid") or (string.contains(string.lower(getName(p214_)), "alphapart") or string.contains(string.lower(getName(p214_)), "alpha_decal")))) or string.contains(string.lower(getName(p214_)), "sticker") then
		return false
	end
	Logging.devWarning("Alpha part or grid node found with decal layer set to %d - Node: %s", getShapeDecalLayer(p214_), I3DUtil.getNodePath(p214_))
	return true
end)
local v_u_215_ = nil
I3DManager.addDebugLoadingCheck("SnowHeapsColAndVisCondition", function(_, p216_)
	-- upvalues: (ref) v_u_215_
	local v217_ = false
	if getHasClassId(p216_, ClassIds.SHAPE) then
		local v218_ = getMaterial(p216_, 0)
		if v218_ ~= 0 and string.contains(getMaterialCustomShaderFilename(v218_), "snowHeapShader") then
			if getRigidBodyType(p216_) ~= RigidBodyType.NONE then
				Logging.devWarning("Snow heap with collision found - Node: %s", I3DUtil.getNodePath(p216_))
				v217_ = true
			end
			if not (getVisibility(p216_) and getVisibility(getParent(p216_))) then
				Logging.devWarning("Snow heap hidden - Node: %s", I3DUtil.getNodePath(p216_))
				v217_ = true
			end
			local v219_ = v_u_215_
			if not v219_ then
				if g_currentMission then
					v219_ = (g_currentMission.environment.environmentMaskSystem:getWeatherMaskFromFlagName("WINTER") or {}).bitflag or nil
				else
					v219_ = nil
				end
			end
			v_u_215_ = v219_
			if v_u_215_ ~= nil then
				local v220_, _ = getVisibilityConditionWeatherMask(p216_)
				if v220_ ~= v_u_215_ then
					Logging.devWarning("Snow heap (or its parent) does not have weatherRequired mask \'WINTER\' (0x%x) set - Node: %s", v_u_215_, I3DUtil.getNodeNameAndIndexPath(p216_))
					v217_ = true
				end
			end
		end
	end
	return v217_
end)
