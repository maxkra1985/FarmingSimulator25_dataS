HelplineExtension = {}
HelplineExtension.MOD_NAME = g_currentModName
HelplineExtension.MOD_DIR = g_currentModDirectory
HelplineExtension.GUI_EXT_XML = g_currentModDirectory .. "gui/HelpFrameSeedRateExtension.xml"
local HelplineExtension_mt = Class(HelplineExtension)
function HelplineExtension.new(pfModule, customMt)
	local self = setmetatable({}, customMt or HelplineExtension_mt)
	self.pfModule = pfModule
	return self
end
function HelplineExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return true
end
function HelplineExtension:delete()
	if self.precisionFarmingSeedRateContainer ~= nil then
		self.precisionFarmingSeedRateContainer:delete()
		self.precisionFarmingSeedRateContainer = nil
	end
end
function HelplineExtension:getAllowFirstTimeEvent()
	return not g_currentMission.hud:isInGameMessageVisible() and not g_gui:getIsGuiVisible()
end
function HelplineExtension:onFirstTimeRun()
	YesNoDialog.show(self.onFirstTimeRunDialog, self, g_i18n:getText("precisionFarming_firstStart", HelplineExtension.MOD_NAME))
end
function HelplineExtension:onFirstTimeRunDialog(yes)
	if yes then
		self:openHelpMenu(1)
	end
end
function HelplineExtension:openHelpMenu(offsetIndex)
	if g_gui.currentGuiName ~= "InGameMenu" then
		g_gui:showGui("InGameMenu")
	end
	if g_currentMission ~= nil then
		local helpLinePage = g_inGameMenu.pageHelpLine
		g_inGameMenu:openHelpLine(1, 1)
		helpLinePage:openPage(1, offsetIndex, HelplineExtension.MOD_NAME)
	end
end
function HelplineExtension:fillSeedRateRows(contentBox, template)
	if self.pfModule.seedRateMap ~= nil then
		self.pfModule.seedRateMap:createHelpMenuSeedRateTable(contentBox, template)
	end
end
function HelplineExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(InGameMenuHelpFrame, "updateContents", function(superFunc, _self, page)
		superFunc(_self, page)
		if 0 < #page.paragraphs then
			local lastParagraph = page.paragraphs[#page.paragraphs]
			if lastParagraph.text == "$l10n_helpText_07_part03" and lastParagraph.customEnvironment == HelplineExtension.MOD_NAME then
				helplineExtension:fillSeedRateRows(_self.helpLineContentBox, self.precisionFarmingSeedRateRowTemplate)
			end
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuHelpFrame, "onFrameOpen", function(superFunc, _self)
		if self.precisionFarmingSeedRateContainer == nil then
			self.precisionFarmingSeedRateContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/HelpFrameSeedRateExtension.xml", _self, _self.elements[1])
			self.precisionFarmingSeedRateContainer:unlinkElement()
			self.precisionFarmingSeedRateContainer:setVisible(false)
			self.precisionFarmingSeedRateRowTemplate = self.precisionFarmingSeedRateContainer.elements[1]
		end
		superFunc(_self)
	end)
end
