-- Local values: NetflixSigninScreen_mt
NetflixSigninScreen = {}
local NetflixSigninScreen_mt = Class(NetflixSigninScreen, ScreenElement)
function NetflixSigninScreen.register()
	local v2_ = NetflixSigninScreen.new()
	g_gui:loadGui("dataS/gui/GamepadSigninScreen.xml", "NetflixSigninScreen", v2_)
	return v2_
end

-- Upvalues: NetflixSigninScreen_mt
-- Local values: self
function NetflixSigninScreen.new(target, custom_mt)
	-- upvalues: (copy) NetflixSigninScreen_mt
	return NetflixSigninScreen:superClass().new(target, custom_mt or NetflixSigninScreen_mt)
end

-- Local values: newGui
function NetflixSigninScreen.createFromExistingGui(gui, guiName)
	local v7_ = NetflixSigninScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v7_)
	return v7_
end

function NetflixSigninScreen:onCreate() end

function NetflixSigninScreen:onOpen()
	g_isSignedIn = false
	startMenuMusic()
	self.logo:setImageFilename("dataS/menu/main_logo_en.png")
	self.startText:setText("")
end

function NetflixSigninScreen:onClose() end

function NetflixSigninScreen:update(dt)
	NetflixSigninScreen:superClass().update(self, dt)
	if getIsUserSignedIn() then
		g_isSignedIn = true
		loadUserSettings(g_gameSettings)
		self:changeScreen(MainScreen)
	end
end
