ImeSimulator = {}
ImeSimulator.IS_INITIALIZED = false
ImeSimulator.IS_ACTIVE = false
ImeSimulator.LAST_STRING = ""
ImeSimulator.IS_CLOSED = false
ImeSimulator.IS_CANCELED = false
ImeSimulator.MAX_CHARS = 0
ImeSimulator.BLOCKS_MAIN_THREAD = getPlatformId() == PlatformId.SWITCH
function ImeSimulator.init()
	if ImeSimulator.IS_INITIALIZED then
		return
	else
		local imeIsSupported_new = function()
			Logging.devInfo("Reporting IME as available")
			return true
		end
		imeIsSupported = imeIsSupported_new
		local imeAbort_new = function()
			Logging.devInfo("IME aborted")
			ImeSimulator.cancel()
		end
		imeAbort = imeAbort_new
		local imeOpen_new = function(text, title, description, placeholder, keyboardType, maxCharacters, left, top, width, height)
			ImeSimulator.TITLE = title
			ImeSimulator.DESCRIPTION = description
			ImeSimulator.PLACEHOLDER = placeholder
			ImeSimulator.LAST_STRING = text
			ImeSimulator.MAX_CHARS = maxCharacters
			ImeSimulator.IS_ACTIVE = true
			return true
		end
		imeOpen = imeOpen_new
		local imeIsComplete_new = function()
			return ImeSimulator.IS_CLOSED, ImeSimulator.IS_CANCELED
		end
		imeIsComplete = imeIsComplete_new
		local imeGetLastString_new = function()
			return ImeSimulator.LAST_STRING
		end
		imeGetLastString = imeGetLastString_new
		local oldUpdate = update
		local update_new = function(dt)
			local blockUpdateLoop = ImeSimulator.IS_ACTIVE and ImeSimulator.BLOCKS_MAIN_THREAD
			if not blockUpdateLoop then
				oldUpdate(dt)
			end
			ImeSimulator.IS_CLOSED = false
			ImeSimulator.IS_CANCELED = false
		end
		update = update_new
		local oldDraw = draw
		local draw_new = function()
			oldDraw()
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
		draw = draw_new
		local oldKeyEvent = keyEvent
		local keyEvent_new = function(unicode, sym, modifier, isDown)
			if ImeSimulator.IS_ACTIVE then
				if isDown then
					local len = utf8Strlen(ImeSimulator.LAST_STRING)
					if sym == Input.KEY_return then
						ImeSimulator.close()
						return
					end
					if sym == Input.KEY_esc then
						ImeSimulator.cancel()
						return
					end
					if sym == Input.KEY_backspace then
						if 0 < len then
							ImeSimulator.LAST_STRING = utf8Substr(ImeSimulator.LAST_STRING, 0, len - 1)
						end
						return
					end
					if getCanRenderUnicode(unicode) and (ImeSimulator.MAX_CHARS == 0 or len < ImeSimulator.MAX_CHARS) then
						ImeSimulator.LAST_STRING = ImeSimulator.LAST_STRING .. unicodeToUtf8(unicode)
					end
				end
			else
				oldKeyEvent(unicode, sym, modifier, isDown)
			end
		end
		keyEvent = keyEvent_new
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
