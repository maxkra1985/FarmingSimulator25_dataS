GameLoadingCancelSimulator = {}
GameLoadingCancelSimulator.ACTIVE = false
function GameLoadingCancelSimulator.init()
	local v1_ = StartParams.getValue("gameLoadingCancelSimulator")
	if v1_ ~= nil then
		GameLoadingCancelSimulator.ACTIVE = true
		StartParams.setValue("autoStartSavegameId", 1)
		local v_u_2_ = tonumber(v1_) or 1
		local v_u_3_ = v_u_2_
		local v_u_4_ = 0
		local v_u_5_ = 0
		function cancel()
			-- upvalues: (ref) v_u_2_, (ref) v_u_4_, (ref) v_u_5_
			v_u_2_ = v_u_2_ + 1
			v_u_4_ = 0
			g_mpLoadingScreen:cancelLoading(false)
			local v6_ = collectgarbage("count")
			collectgarbage("collect")
			local v7_ = collectgarbage("count")
			log(string.format(" -- CANCEL (%d) -- Collected %.1f kB -- Increase: %.1f kB", v_u_2_, v6_ - v7_, v7_ - v_u_5_))
			v_u_5_ = v7_
			if g_pendingRestartData == nil then
				autoStartLocalSavegame(1)
			end
		end
		local v_u_8_ = AsyncTaskManager.runLambda
		function AsyncTaskManager.runLambda(p9_, p10_)
			-- upvalues: (ref) v_u_4_, (copy) v_u_8_, (ref) v_u_2_
			v_u_4_ = v_u_4_ + 1
			v_u_8_(p9_, p10_)
			if v_u_2_ < v_u_4_ then
				cancel()
			end
		end
		local v_u_11_ = draw
		function draw()
			-- upvalues: (copy) v_u_11_, (copy) v_u_3_, (ref) v_u_2_, (ref) v_u_4_
			v_u_11_()
			local v12_ = string.format("GameLoadingCancelSimulator\nStart Step: %d\nCancel Step: %d\nCurrent Step: %d", v_u_3_, v_u_2_, v_u_4_)
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextColor(0, 0, 0, 1)
			renderText(0.5, 0.5, 0.05, v12_)
			setTextColor(1, 1, 1, 1)
			renderText(0.5 + 2 * g_pixelSizeX, 0.5 + 2 * g_pixelSizeY, 0.05, v12_)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
		local v_u_13_ = doRestart
		function doRestart(p14_, p15_)
			-- upvalues: (copy) v_u_13_, (ref) v_u_2_
			v_u_13_(p14_, p15_)
			g_pendingRestartData.args = string.format("-gameLoadingCancelSimulator %d", v_u_2_)
		end
	end
end
