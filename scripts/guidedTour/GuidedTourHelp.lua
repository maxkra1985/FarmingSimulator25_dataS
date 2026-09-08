GuidedTourHelp = {}
function GuidedTourHelp.init()
	GuidedTourHelp.registerHelpProgress()
	GuidedTourHelp.registerHelpCalendar()
	GuidedTourHelp.registerHelpTime()
	GuidedTourHelp.registerHelpWeather()
	GuidedTourHelp.registerHelpBalance()
	GuidedTourHelp.registerHelpMiniMap()
	GuidedTourHelp.registerHelpFillLevels()
	GuidedTourHelp.registerHelpVehicleSelection()
end
function GuidedTourHelp.registerHelpProgress()
	local v1_ = {}
	local v_u_2_ = g_i18n:getText("introduction_tourProgress")
	function v1_.draw(_, p3_)
		-- upvalues: (copy) v_u_2_
		local v4_, v5_ = g_currentMission.hud.sideNotifications:getHelpAnchorPosition()
		IntroductionHelpHUDUtil.drawHelp(v4_, v5_, v_u_2_, IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT)
		IntroductionHelpHUDUtil.drawSkipMessage(p3_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpProgress", v1_, v1_.draw, nil)
end
function GuidedTourHelp.registerHelpFillLevels()
	local v6_ = {}
	local v_u_7_ = g_i18n:getText("introduction_tourFillLevelSeedType")
	function v6_.draw(_, p8_)
		-- upvalues: (copy) v_u_7_
		local v9_, v10_ = g_currentMission.hud.fillLevelsDisplay:getHelpAnchorPosition()
		IntroductionHelpHUDUtil.drawHelp(v9_, v10_, v_u_7_, IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT)
		IntroductionHelpHUDUtil.drawSkipMessage(p8_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpFillLevelsSeedType", v6_, v6_.draw, nil)
end
function GuidedTourHelp.registerHelpVehicleSelection()
	local v11_ = {}
	local v_u_12_ = g_i18n:getText("introduction_tourVehicleSelection")
	function v11_.draw(_, p13_)
		-- upvalues: (copy) v_u_12_
		local v14_, v15_ = g_currentMission.hud.inputHelp:getHelpAnchorPosition()
		IntroductionHelpHUDUtil.drawHelp(v14_, v15_, v_u_12_, IntroductionHelpHUDUtil.ARROW_POSITION_LEFT)
		IntroductionHelpHUDUtil.drawSkipMessage(p13_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpVehicleSelection", v11_, v11_.draw, nil)
end
function GuidedTourHelp.registerHelpCalendar()
	local v16_ = {}
	local v_u_17_ = g_i18n:getText("introduction_monthInfo")
	function v16_.draw(_, p18_)
		-- upvalues: (copy) v_u_17_
		local v19_, v20_ = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_CALENDAR)
		IntroductionHelpHUDUtil.drawHelp(v19_, v20_, v_u_17_, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
		IntroductionHelpHUDUtil.drawSkipMessage(p18_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpCalendar", v16_, v16_.draw, nil)
end
function GuidedTourHelp.registerHelpTime()
	local v21_ = {}
	local v_u_22_ = g_i18n:getText("introduction_timeInfo")
	function v21_.draw(_, p23_)
		-- upvalues: (copy) v_u_22_
		local v24_, v25_ = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_CLOCK)
		IntroductionHelpHUDUtil.drawHelp(v24_, v25_, v_u_22_, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
		IntroductionHelpHUDUtil.drawSkipMessage(p23_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpTime", v21_, v21_.draw, nil)
end
function GuidedTourHelp.registerHelpWeather()
	local v26_ = {}
	local v_u_27_ = g_i18n:getText("introduction_weather")
	function v26_.draw(_, p28_)
		-- upvalues: (copy) v_u_27_
		local v29_, v30_ = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_WEATHER)
		IntroductionHelpHUDUtil.drawHelp(v29_, v30_, v_u_27_, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
		IntroductionHelpHUDUtil.drawSkipMessage(p28_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpWeather", v26_, v26_.draw, nil)
end
function GuidedTourHelp.registerHelpBalance()
	local v31_ = {}
	local v_u_32_ = g_i18n:getText("introduction_balance")
	function v31_.draw(_, p33_)
		-- upvalues: (copy) v_u_32_
		local v34_, v35_ = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_MONEY)
		IntroductionHelpHUDUtil.drawHelp(v34_, v35_, v_u_32_, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
		IntroductionHelpHUDUtil.drawSkipMessage(p33_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpBalance", v31_, v31_.draw, nil)
end
function GuidedTourHelp.registerHelpMiniMap()
	local v36_ = {}
	local v_u_37_ = g_i18n:getText("introduction_openMinimap")
	function v36_.draw(_, p38_)
		-- upvalues: (copy) v_u_37_
		local v39_, v40_ = g_currentMission.hud.ingameMap:getHelpAnchorPosition()
		IntroductionHelpHUDUtil.drawHelp(v39_, v40_, v_u_37_, IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM)
		IntroductionHelpHUDUtil.drawSkipMessage(p38_)
	end
	g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpMiniMap", v36_, v36_.draw, nil)
end
