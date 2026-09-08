ImeSimulator = {}
ImeSimulator.IS_INITIALIZED = false
ImeSimulator.IS_ACTIVE = false
ImeSimulator.LAST_STRING = ""
ImeSimulator.IS_CLOSED = false
ImeSimulator.IS_CANCELED = false
ImeSimulator.MAX_CHARS = 0
ImeSimulator.BLOCKS_MAIN_THREAD = getPlatformId() == PlatformId.SWITCH
function ImeSimulator.init()
	if not ImeSimulator.IS_INITIALIZED then
		function imeIsSupported()
			Logging.devInfo("Reporting IME as available")
			return true
		end
		function imeAbort()
			Logging.devInfo("IME aborted")
			ImeSimulator.cancel()
		end
		function imeOpen(p1_, p2_, p3_, p4_, _, p5_, _, _, _, _)
			ImeSimulator.TITLE = p2_
			ImeSimulator.DESCRIPTION = p3_
			ImeSimulator.PLACEHOLDER = p4_
			ImeSimulator.LAST_STRING = p1_
			ImeSimulator.MAX_CHARS = p5_
			ImeSimulator.IS_ACTIVE = true
			return true
		end
		function imeIsComplete()
			return ImeSimulator.IS_CLOSED, ImeSimulator.IS_CANCELED
		end
		function imeGetLastString()
			return ImeSimulator.LAST_STRING
		end
		local v_u_6_ = update
		function update(p7_)
			-- upvalues: (copy) v_u_6_
			local v8_ = ImeSimulator.IS_ACTIVE
			if v8_ then
				v8_ = ImeSimulator.BLOCKS_MAIN_THREAD
			end
			if not v8_ then
				v_u_6_(p7_)
			end
			ImeSimulator.IS_CLOSED = false
			ImeSimulator.IS_CANCELED = false
		end
		local v_u_9_ = draw
		function draw()
			-- upvalues: (copy) v_u_9_
			v_u_9_()
			if ImeSimulator.IS_ACTIVE then
				new2DLayer()
				drawFilledRect(0, 0, 1, 1, 0, 0, 0, 1)
				drawFilledRect(0.2, 0.2, 0.6, 0.6, 0.2, 0.2, 0.2, 0.9)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(0.5, 0.76, 0.025, "IME Simulator")
				renderText(0.5, 0.7, 0.025, "Title: " .. ImeSimulator.TITLE)
				renderText(0.5, 0.67, 0.025, "Desc: " .. ImeSimulator.DESCRIPTION)
				renderText(0.5, 0.64, 0.025, "Placeholder: " .. ImeSimulator.PLACEHOLDER)
				renderText(0.5, 0.58, 0.025, "Text: " .. ImeSimulator.LAST_STRING)
				setTextAlignment(RenderText.ALIGN_LEFT)
			end
		end
		local v_u_10_ = keyEvent
		function keyEvent(p11_, p12_, p13_, p14_)
			-- upvalues: (copy) v_u_10_
			if ImeSimulator.IS_ACTIVE then
				if p14_ then
					local v15_ = utf8Strlen(ImeSimulator.LAST_STRING)
					if p12_ == Input.KEY_return then
						ImeSimulator.close()
						return
					end
					if p12_ == Input.KEY_esc then
						ImeSimulator.cancel()
						return
					end
					if p12_ == Input.KEY_backspace then
						if v15_ > 0 then
							ImeSimulator.LAST_STRING = utf8Substr(ImeSimulator.LAST_STRING, 0, v15_ - 1)
						end
						return
					end
					if getCanRenderUnicode(p11_) and (ImeSimulator.MAX_CHARS == 0 or v15_ < ImeSimulator.MAX_CHARS) then
						ImeSimulator.LAST_STRING = ImeSimulator.LAST_STRING .. unicodeToUtf8(p11_)
						return
					end
				end
			else
				v_u_10_(p11_, p12_, p13_, p14_)
			end
		end
		ImeSimulator.IS_INITIALIZED = true
		printWarning("\n\n  ##################   Warning: IME Simulator active!   ##################\n\n")
	end
end
function ImeSimulator.close()
	ImeSimulator.IS_CLOSED = true
	ImeSimulator.IS_CANCELED = false
	ImeSimulator.IS_ACTIVE = false
end
function ImeSimulator.cancel()
	ImeSimulator.IS_CLOSED = true
	ImeSimulator.IS_CANCELED = true
	ImeSimulator.IS_ACTIVE = false
end
