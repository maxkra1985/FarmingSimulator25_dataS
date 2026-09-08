FindOverlayLeaks = {}
FindOverlayLeaks.overlays = {}
FindOverlayLeaks.guiElements = {}
function FindOverlayLeaks.init()
	if StartParams.getIsSet("findOverlayLeaks") then
		local v_u_1_ = createImageOverlay
		function createImageOverlay(p2_, p3_, ...)
			-- upvalues: (copy) v_u_1_
			local v4_ = v_u_1_(p2_, ...)
			if v4_ ~= 0 then
				local v5_ = p3_ == nil and "" or " Slice id: " .. p3_
				FindOverlayLeaks.overlays[v4_] = p2_ .. v5_ .. "\nTrace:\n" .. debug.traceback()
			end
			return v4_
		end
		local v_u_6_ = GuiElement.new
		function GuiElement.new(...)
			-- upvalues: (copy) v_u_6_
			local v7_ = v_u_6_(...)
			FindOverlayLeaks.guiElements[v7_] = ClassUtil.getClassNameByObject(v7_) .. "\nTrace:\n" .. debug.traceback()
			return v7_
		end
		local v_u_8_ = GuiElement.delete
		function GuiElement.delete(p9_, ...)
			-- upvalues: (copy) v_u_8_
			FindOverlayLeaks.guiElements[p9_] = nil
			v_u_8_(p9_, ...)
		end
		local v_u_10_ = delete
		function delete(p11_)
			-- upvalues: (copy) v_u_10_
			v_u_10_(p11_)
			FindOverlayLeaks.overlays[p11_] = nil
		end
		printWarning("Warning: FindOverlayLeaks is active!")
	end
end
function FindOverlayLeaks.printUndeletedOverlays()
	if StartParams.getIsSet("findOverlayLeaks") then
		if next(FindOverlayLeaks.overlays) ~= nil then
			setFileLogPrefixTimestamp(false)
			printError("FindOverlayLeaks: Undeleted overlays\n\n")
			for _, v12_ in pairs(FindOverlayLeaks.overlays) do
				print(v12_)
				print("\n\n")
			end
			setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		end
		if next(FindOverlayLeaks.guiElements) ~= nil then
			setFileLogPrefixTimestamp(false)
			printError("FindOverlayLeaks: Undeleted gui elements\n\n")
			for _, v13_ in pairs(FindOverlayLeaks.guiElements) do
				print(v13_)
				print("\n\n")
			end
			setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		end
	end
end
