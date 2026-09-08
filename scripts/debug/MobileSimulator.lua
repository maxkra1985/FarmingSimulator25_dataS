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
MobileSimulator.INSETS = {
	[MobileSimulator.NOTCH_STATE_OFF] = {
		0,
		0,
		0,
		0
	},
	[MobileSimulator.NOTCH_STATE_LEFT] = {
		MobileSimulator.INSET_LEFT,
		0,
		0,
		0
	},
	[MobileSimulator.NOTCH_STATE_RIGHT] = {
		0,
		MobileSimulator.INSET_RIGHT,
		0,
		0
	},
	[MobileSimulator.NOTCH_STATE_BOTH] = {
		MobileSimulator.INSET_LEFT,
		MobileSimulator.INSET_RIGHT,
		0,
		0
	}
}
function MobileSimulator.init()
	local v_u_1_ = MobileSimulator
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
	local v_u_2_ = keyEvent
	function keyEvent(p3_, p4_, p5_, p6_)
		-- upvalues: (copy) v_u_2_
		if p6_ and p4_ == Input.KEY_1 then
			MobileSimulator.SIGNED_IN = not MobileSimulator.SIGNED_IN
			Logging.devInfo("MobileSimulator - Signed in state: %s", MobileSimulator.SIGNED_IN)
		end
		v_u_2_(p3_, p4_, p5_, p6_)
	end
	local v_u_7_ = draw
	function draw()
		-- upvalues: (copy) v_u_7_, (copy) v_u_1_
		v_u_7_()
		new2DLayer()
		if v_u_1_.NOTCH_STATE ~= v_u_1_.NOTCH_STATE_OFF then
			local v8_ = 0 - v_u_1_.NOTCH_WIDTH
			if v_u_1_.NOTCH_STATE == v_u_1_.NOTCH_STATE_RIGHT then
				v8_ = 1 - v_u_1_.NOTCH_WIDTH
			end
			local v9_ = 0.5 - v_u_1_.NOTCH_HEIGHT * 0.5
			local v10_ = v_u_1_.NOTCH_WIDTH
			local v11_ = v_u_1_.NOTCH_HEIGHT
			drawFilledRectRound(v8_, v9_, v10_ * 2, v11_, 1, 0, 0, 0, 1)
		end
		local v12_, v13_, v14_, v15_ = getSafeFrameInsets()
		local v16_ = 1 - v14_ - 2 / g_pixelSizeY
		local v17_ = 1 - v13_
		local v18_ = v12_ + 2 / g_pixelSizeX
		drawLine2D(v18_, 0, v18_, 1, 2 * g_pixelSizeX, 1, 0, 0, 1)
		drawLine2D(v18_, v16_, v17_, v16_, 2 * g_pixelSizeY, 1, 0, 0, 1)
		drawLine2D(v17_, 0, v17_, 1, 2 * g_pixelSizeX, 1, 0, 0, 1)
		drawLine2D(v18_, v15_, v17_, v15_, 2 * g_pixelSizeY, 1, 0, 0, 1)
	end
	function getSafeFrameInsets()
		-- upvalues: (copy) v_u_1_
		local v19_ = MobileSimulator.INSETS[v_u_1_.NOTCH_STATE]
		return v19_[1], v19_[2], v19_[3], v19_[4]
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
	if MobileSimulator.NOTCH_STATE > 3 then
		MobileSimulator.NOTCH_STATE = MobileSimulator.NOTCH_STATE_OFF
	end
end
