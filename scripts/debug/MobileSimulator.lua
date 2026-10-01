MobileSimulator = {}
MobileSimulator.NOTCH_STATE_OFF = 0
MobileSimulator.NOTCH_STATE_LEFT = 1
MobileSimulator.NOTCH_STATE_RIGHT = 2
MobileSimulator.NOTCH_STATE_BOTH = 3
MobileSimulator.SIGNED_IN = true
MobileSimulator.NOTCH_STATE = MobileSimulator.NOTCH_STATE_OFF
MobileSimulator.NOTCH_WIDTH = 0.03694581280788178
MobileSimulator.NOTCH_HEIGHT = 0.5573333333333333
MobileSimulator.INSET_LEFT = 0.04926108374384237
MobileSimulator.INSET_RIGHT = 0.04926108374384237
MobileSimulator.INSET_BOTTOM = 0
MobileSimulator.INSET_TOP = 0
MobileSimulator.INSETS = { [MobileSimulator.NOTCH_STATE_OFF] = { 0, 0, 0, 0 }, [MobileSimulator.NOTCH_STATE_LEFT] = { MobileSimulator.INSET_LEFT, 0, 0, 0 }, [MobileSimulator.NOTCH_STATE_RIGHT] = { 0, MobileSimulator.INSET_RIGHT, 0, 0 }, [MobileSimulator.NOTCH_STATE_BOTH] = { MobileSimulator.INSET_LEFT, MobileSimulator.INSET_RIGHT, 0, 0 } }
function MobileSimulator.init()
	local self = MobileSimulator
	function userSignout()
		MobileSimulator.SIGNED_IN = false
		Logging.devInfo("MobileSimulator - Signed out!")
	end
	function requestUserSignin()
		MobileSimulator.SIGNED_IN = true
		Logging.devInfo("MobileSimulator - Signed in!")
	end
	function getIsUserSignedIn()
		return MobileSimulator.SIGNED_IN
	end
	local oldKeyEvent = keyEvent
	function keyEvent(unicode, sym, modifier, isDown)
		if isDown and sym == Input.KEY_1 then
			MobileSimulator.SIGNED_IN = not MobileSimulator.SIGNED_IN
			Logging.devInfo("MobileSimulator - Signed in state: %s", MobileSimulator.SIGNED_IN)
		end
		oldKeyEvent(unicode, sym, modifier, isDown)
	end
	local oldDraw = draw
	function draw()
		oldDraw()
		new2DLayer()
		if self.NOTCH_STATE ~= self.NOTCH_STATE_OFF then
			local posX = 0 - self.NOTCH_WIDTH
			if self.NOTCH_STATE == self.NOTCH_STATE_RIGHT then
				posX = 1 - self.NOTCH_WIDTH
			end
			local posY = 0.5 - self.NOTCH_HEIGHT * 0.5
			local width = self.NOTCH_WIDTH
			local height = self.NOTCH_HEIGHT
			drawFilledRectRound(posX, posY, width * 2, height, 1, 0, 0, 0, 1)
		end
		local left, right, top, bottom = getSafeFrameInsets()
		top = 1 - top - 2 / g_pixelSizeY
		right = 1 - right
		left = left + 2 / g_pixelSizeX
		drawLine2D(left, 0, left, 1, 2 * g_pixelSizeX, 1, 0, 0, 1)
		drawLine2D(left, top, right, top, 2 * g_pixelSizeY, 1, 0, 0, 1)
		drawLine2D(right, 0, right, 1, 2 * g_pixelSizeX, 1, 0, 0, 1)
		drawLine2D(left, bottom, right, bottom, 2 * g_pixelSizeY, 1, 0, 0, 1)
	end
	function getSafeFrameInsets()
		local insets = MobileSimulator.INSETS[self.NOTCH_STATE]
		return insets[1], insets[2], insets[3], insets[4]
	end
	if GS_IS_NETFLIX_VERSION then
		function showNetflixButton()
			log("NETFLIX: showNetflixButton")
		end
		function hideNetflixButton()
			log("NETFLIX: hideNetflixButton")
		end
	end
	addConsoleCommand("gsMobileSimulatorToggleNotch", "mobile simulator toggle notch", "toggleNotch", MobileSimulator)
	printWarning("\n\n  ##################   Warning: Mobile Simulator active!   ##################\n\n")
end
function MobileSimulator.toggleNotch()
	MobileSimulator.NOTCH_STATE = MobileSimulator.NOTCH_STATE + 1
	if 3 < MobileSimulator.NOTCH_STATE then
		MobileSimulator.NOTCH_STATE = MobileSimulator.NOTCH_STATE_OFF
	end
end
