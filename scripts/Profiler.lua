Profiler = {}
Profiler.IS_INITIALIZED = false
Profiler.IS_READY = false
Profiler.IS_GRID_INITIALIZED = false
Profiler.IS_GRID_FINISHED = false
Profiler.IS_FINISHED = false
Profiler.IS_GPU_BENCHMARK_MODE = false
Profiler.MAP = ""
Profiler.MAP_FILENAME = ""
Profiler.OUTPUT_FILENAME = ""
Profiler.SAMPLING_GRID_SIZE = -1
Profiler.SAMPLING_CUSTOM_NODE = ""
Profiler.MAP_ROOT_NODE = {}
Profiler.PROFILING_ROOT_NODE = {}
Profiler.CURRENT_NODE_ID = 0
Profiler.NUM_NODES = 0
Profiler.GRID_CURRENT_X = 0
Profiler.GRID_CURRENT_Z = 0
Profiler.GRID_CURRENT_ROTATION = 0
Profiler.GRID_ROTATION_DELTA = 1.5707963267948966
Profiler.GRID_ROTATION_NUM_STEPS = 4
Profiler.CAMERA = nil
Profiler.FRAME_COUNT = 0
Profiler.INITIAL_FRAMES_PAUSED = 0
Profiler.STARTUP_FRAME_PAUSE = 500
Profiler.FRAMES_BETWEEN_SAMPLES = 20
Profiler.SAVEGAME_NUMBER = 3
Profiler.MAP_SIZE = 0
function Profiler.init()
	if Profiler.IS_INITIALIZED then
		return
	end
	if not StartParams.getIsSet("profilerStatsMap") then
		return
	end
	if not StartParams.getIsSet("profilerStatsOutputPath") then
		return
	end
	local v1_ = Profiler
	if StartParams.getIsSet("profilerStatsSavegameSlot") then
		local v2_ = StartParams.getValue
		v3_ = tonumber(v2_("profilerStatsSavegameSlot"))
		if v3_ then
			goto l9
		end
	end
	local v3_ = Profiler.SAVEGAME_NUMBER
	::l9::
	v1_.SAVEGAME_NUMBER = v3_
	Profiler.OUTPUT_DIRECTORY = StartParams.getValue("profilerStatsOutputPath")
	Profiler.IS_GPU_BENCHMARK_MODE = StartParams.getIsSet("profilerGpuBenchmarkMode")
	if Profiler.IS_GPU_BENCHMARK_MODE then
		Profiler.GRID_ROTATION_DELTA = 0.02617993877991494
		Profiler.GRID_ROTATION_NUM_STEPS = 240
		local v4_ = StartParams.getValue("gpuBenchmarkOutputFile")
		Profiler.OUTPUT_FILENAME = Profiler.OUTPUT_DIRECTORY .. "/" .. v4_
		if StartParams.getIsSet("profilerGpuBenchmarOnly6GBVram") then
			local v5_ = profilerGetCurrentGpuVRAM()
			if v5_ > 0 and v5_ < 5120 then
				Logging.info("Skip benchmark, " .. getGPUName() .. " do not have 6GB ore more VRAM ")
				profilerWriteGpuBenchmarkStats(Profiler.OUTPUT_FILENAME)
				doExit()
			end
		end
		if StartParams.getIsSet("gpuBenchmarkMinSpecsGpu") and profilerGetGpuPerformanceRating(getGPUName()) < profilerGetGpuPerformanceRating(StartParams.getValue("gpuBenchmarkMinSpecsGpu")) then
			Logging.info("Skip benchmark, " .. getGPUName() .. " is bellow the min specs GPU " .. StartParams.getValue("gpuBenchmarkMinSpecsGpu"))
			profilerWriteGpuBenchmarkStats(Profiler.OUTPUT_FILENAME)
			doExit()
			return
		end
	end
	if folderExists(Profiler.OUTPUT_DIRECTORY) then
		Profiler.MAP = StartParams.getValue("profilerStatsMap")
		Profiler.MAP_FILENAME = StartParams.getValue("profilerStatsMapFilename") or "default"
		local v6_
		if StartParams.getIsSet("profilerStatsSamplingGridSize") then
			local v7_ = StartParams.getValue
			local v8_ = tonumber(v7_("profilerStatsSamplingGridSize"))
			if v8_ == nil or v8_ <= 0 then
				Logging.error("Invalid \'profilerStatsSamplingGridSize\' parameter")
				return
			end
			local v9_ = math.huge
			local v10_ = nil
			for v11_ = 4, 15 do
				local v12_ = math.pow(2, v11_)
				local v13_ = v8_ - v12_
				local v14_ = math.abs(v13_)
				if v14_ < v9_ then
					v10_ = v12_
					v9_ = v14_
				end
			end
			if v9_ ~= 0 then
				Logging.warning("Grid size \'%s\' was not a power of 2, changed to \'%s\'!", v8_, v10_)
			end
			Profiler.SAMPLING_GRID_SIZE = v10_
			v6_ = true
		else
			v6_ = false
		end
		if StartParams.getIsSet("profilerStatsSamplingCustomNode") then
			Profiler.SAMPLING_CUSTOM_NODE = StartParams.getValue("profilerStatsSamplingCustomNode")
			v6_ = true
		end
		if v6_ then
			Profiler.CAMERA = createCamera("cameraProfiler", 1.0471975511965976, 1, 10000)
			g_cameraManager:addCamera(Profiler.CAMERA, nil, false)
			link(getRootNode(), Profiler.CAMERA)
			Logging.info("Profiler initialized successfully")
			Profiler.IS_INITIALIZED = true
		else
			Logging.error("Profiler needs \'profilerStatsSamplingGridSize\' or \'profilerStatsSamplingCustomNode\' parameter set")
		end
	else
		Logging.error("Unable to write to profilerStatsOutputPath %q. Is it an absolute path and does the directory exist?", getAppBasePath() .. Profiler.OUTPUT_DIRECTORY)
		return
	end
end
function Profiler.delete()
	if Profiler.CAMERA ~= nil then
		if g_cameraManager:getActiveCamera() == Profiler.CAMERA then
			g_cameraManager:setDefaultCamera()
		end
		g_cameraManager:removeCamera(Profiler.CAMERA)
		delete(Profiler.CAMERA)
		Profiler.CAMERA = nil
	end
end
function Profiler.startProfiler()
	if Profiler.IS_INITIALIZED then
		Logging.info("######################### Starting Profiler #########################")
		g_gui:setIsMultiplayer(false)
		g_gui:showGui("CareerScreen")
	end
end

-- Local values: mapName, profileName
function Profiler.setMapRootNode(node)
	Profiler.MAP_ROOT_NODE = node
	if Profiler.SAMPLING_CUSTOM_NODE ~= "" then
		Profiler.PROFILING_ROOT_NODE = getChild(node, Profiler.SAMPLING_CUSTOM_NODE)
		if Profiler.PROFILING_ROOT_NODE == 0 then
			Profiler.IS_INITIALIZED = false
			Logging.error("Profiler SamplingCustomNode \'%s\' not found", Profiler.SAMPLING_CUSTOM_NODE)
			return
		end
		Profiler.NUM_NODES = getNumOfChildren(Profiler.PROFILING_ROOT_NODE)
	end
	if Profiler.IS_GPU_BENCHMARK_MODE or not Profiler.IS_INITIALIZED then
		return
	elseif profilerStatsExportInit() then
		local v16_
		if g_currentMission == nil or g_currentMission.missionInfo == nil then
			v16_ = ""
		else
			local v17_ = g_currentMission.missionInfo.mapId
			v16_ = tostring(v17_)
		end
		local v18_ = Utils.getDirectoryName(getUserProfileAppPath())
		profilerStatsExportAddMetadata("map", v16_)
		local v19_ = profilerStatsExportAddMetadata
		local v20_ = g_currentMission.mapWidth
		v19_("mapWidth", (tostring(v20_)))
		local v21_ = profilerStatsExportAddMetadata
		local v22_ = g_currentMission.mapHeight
		v21_("mapHeight", (tostring(v22_)))
		profilerStatsExportAddMetadata("date", getDate("%Y-%m-%dT%H:%M:%SZ"))
		profilerStatsExportAddMetadata("revision", getEngineRevision())
		profilerStatsExportAddMetadata("defaultNodeType", "grid")
		profilerStatsExportAddMetadata("appName", v18_)
		Profiler.OUTPUT_FILENAME = Profiler.OUTPUT_DIRECTORY .. "/" .. getDate("%Y-%m-%d_%H-%M-%S") .. "_" .. v18_ .. "_" .. v16_ .. ".json"
	else
		Logging.error("Profiler stats export could not be initialized engine side")
		Profiler.IS_INITIALIZED = false
	end
end
function Profiler.setIsReady()
	Profiler.IS_READY = true
end

-- Local values: x, z, rotY, y, rotX, rotY, rotZ, node, x, y, z, rotX, rotY, rotZ, x, z, y
function Profiler.update(dt)
	if Profiler.IS_READY then
		setFramerateLimiter(false, Platform.defaultFrameLimit)
		if Profiler.IS_GRID_INITIALIZED then
			if Profiler.INITIAL_FRAMES_PAUSED <= Profiler.STARTUP_FRAME_PAUSE then
				Profiler.INITIAL_FRAMES_PAUSED = Profiler.INITIAL_FRAMES_PAUSED + 1
				return
			end
			if Profiler.IS_GRID_FINISHED or (Profiler.FRAME_COUNT <= Profiler.FRAMES_BETWEEN_SAMPLES or Profiler.SAMPLING_GRID_SIZE <= 0) then
				if Profiler.FRAME_COUNT > Profiler.FRAMES_BETWEEN_SAMPLES and Profiler.NUM_NODES > 0 then
					if Profiler.CURRENT_NODE_ID == Profiler.NUM_NODES then
						Profiler.finish()
					else
						if Profiler.CURRENT_NODE_ID > 0 and not Profiler.IS_GPU_BENCHMARK_MODE then
							local v23_, v24_, v25_ = getRotation(Profiler.CAMERA)
							profilerStatsExportAddSampleBegin()
							local v26_ = profilerStatsExportAddSampleData
							local v27_ = v23_ * 180 / 3.141592653589793
							v26_("rotX", (tostring(v27_)))
							local v28_ = profilerStatsExportAddSampleData
							local v29_ = v24_ * 180 / 3.141592653589793
							v28_("rotY", (tostring(v29_)))
							local v30_ = profilerStatsExportAddSampleData
							local v31_ = v25_ * 180 / 3.141592653589793
							v30_("rotZ", (tostring(v31_)))
							profilerStatsExportAddSampleData("type", "custom")
							profilerStatsExportAddSampleEnd()
						end
						local v32_ = getChildAt(Profiler.PROFILING_ROOT_NODE, Profiler.CURRENT_NODE_ID)
						local v33_, v34_, v35_ = getWorldTranslation(v32_)
						local v36_, v37_, v38_ = getWorldRotation(v32_)
						setTranslation(Profiler.CAMERA, v33_, v34_, v35_)
						setRotation(Profiler.CAMERA, v36_, v37_, v38_)
						Profiler.CURRENT_NODE_ID = Profiler.CURRENT_NODE_ID + 1
						Profiler.FRAME_COUNT = 0
					end
				elseif Profiler.IS_GRID_FINISHED and Profiler.NUM_NODES == 0 then
					Profiler.finish()
				else
					Profiler.FRAME_COUNT = Profiler.FRAME_COUNT + 1
				end
			end
			if not Profiler.IS_GPU_BENCHMARK_MODE then
				profilerStatsExportAddSampleBegin()
				local v39_ = profilerStatsExportAddSampleData
				local v40_ = Profiler.GRID_CURRENT_ROTATION * 90
				v39_("rotY", (tostring(v40_)))
				profilerStatsExportAddSampleEnd()
			end
			local v41_ = Profiler.GRID_CURRENT_X - Profiler.MAP_SIZE * 0.5
			local v42_ = Profiler.GRID_CURRENT_Z - Profiler.MAP_SIZE * 0.5
			local v43_ = Profiler.GRID_CURRENT_ROTATION * Profiler.GRID_ROTATION_DELTA
			if Profiler.IS_GPU_BENCHMARK_MODE then
				v41_ = v41_ + 5 * Profiler.GRID_CURRENT_ROTATION / Profiler.GRID_ROTATION_NUM_STEPS
				v42_ = v42_ + 5 * Profiler.GRID_CURRENT_ROTATION / Profiler.GRID_ROTATION_NUM_STEPS
				profilerGpuBenchmarkSample()
			end
			local v44_ = getTerrainHeightAtWorldPos(g_terrainNode, v41_, 0, v42_) + 1.8
			setTranslation(Profiler.CAMERA, v41_, v44_, v42_)
			setRotation(Profiler.CAMERA, 0, v43_, 0)
			Profiler.GRID_CURRENT_ROTATION = Profiler.GRID_CURRENT_ROTATION + 1
			if Profiler.GRID_CURRENT_ROTATION == Profiler.GRID_ROTATION_NUM_STEPS then
				Profiler.GRID_CURRENT_ROTATION = 0
				Profiler.GRID_CURRENT_X = Profiler.GRID_CURRENT_X + Profiler.SAMPLING_GRID_SIZE
				if Profiler.GRID_CURRENT_X > Profiler.MAP_SIZE then
					Profiler.GRID_CURRENT_X = Profiler.SAMPLING_GRID_SIZE * 0.5
					Profiler.GRID_CURRENT_Z = Profiler.GRID_CURRENT_Z + Profiler.SAMPLING_GRID_SIZE
					if Profiler.GRID_CURRENT_Z > Profiler.MAP_SIZE then
						if not Profiler.IS_GPU_BENCHMARK_MODE then
							profilerStatsExportAddSampleBegin()
							local v45_ = profilerStatsExportAddSampleData
							local v46_ = Profiler.GRID_CURRENT_ROTATION * 90
							v45_("rotY", (tostring(v46_)))
							profilerStatsExportAddSampleEnd()
						end
						Profiler.IS_GRID_FINISHED = true
					end
				end
				if Profiler.IS_GPU_BENCHMARK_MODE then
					Profiler.FRAME_COUNT = 0
					g_currentMission.environment:consoleCommandSetDayTime(8, true)
				end
			end
			if not Profiler.IS_GPU_BENCHMARK_MODE then
				Profiler.FRAME_COUNT = 0
				return
			end
		else
			g_cameraManager:setActiveCamera(Profiler.CAMERA)
			Profiler.MAP_SIZE = g_currentMission.mapHeight
			if Profiler.IS_GPU_BENCHMARK_MODE then
				Profiler.MAP_SIZE = Profiler.MAP_SIZE * 0.666
			end
			if Profiler.SAMPLING_GRID_SIZE > 0 then
				Profiler.GRID_CURRENT_X = Profiler.SAMPLING_GRID_SIZE * 0.5
				Profiler.GRID_CURRENT_Z = Profiler.SAMPLING_GRID_SIZE * 0.5
				local v47_ = Profiler.GRID_CURRENT_X - Profiler.MAP_SIZE * 0.5
				local v48_ = Profiler.GRID_CURRENT_Z - Profiler.MAP_SIZE * 0.5
				local v49_ = getTerrainHeightAtWorldPos(g_terrainNode, v47_, 0, v48_) + 1.8
				setTranslation(Profiler.CAMERA, v47_, v49_, v48_)
				setRotation(Profiler.CAMERA, 0, 0, 0)
				Profiler.IS_GRID_INITIALIZED = true
			end
			Profiler.IS_READY = true
		end
	end
end
function Profiler.finish()
	Profiler.IS_FINISHED = true
	if not Profiler.IS_GPU_BENCHMARK_MODE and profilerStatsExportFinalize(Profiler.OUTPUT_FILENAME) then
		Logging.info("saved profiler output to %q", getAppBasePath() .. Profiler.OUTPUT_FILENAME)
	end
	if Profiler.IS_GPU_BENCHMARK_MODE and profilerWriteGpuBenchmarkStats(Profiler.OUTPUT_FILENAME) then
		Logging.info("saved GPU benchmark output to %q", getAppBasePath() .. Profiler.OUTPUT_FILENAME)
	end
	Logging.info("######################### Profiler Finished #########################")
	doExit()
end
