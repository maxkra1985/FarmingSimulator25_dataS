-- Local values: HelplineExtension_mt
HelplineExtension = {}
HelplineExtension.MOD_NAME = g_currentModName
HelplineExtension.MOD_DIR = g_currentModDirectory
HelplineExtension.GUI_EXT_XML = g_currentModDirectory .. "gui/HelpFrameSeedRateExtension.xml"
local HelplineExtension_mt = Class(HelplineExtension)

-- Upvalues: HelplineExtension_mt
-- Local values: self
function HelplineExtension.new(pfModule, customMt)
	-- upvalues: (copy) HelplineExtension_mt
	local v4_ = customMt or HelplineExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.pfModule = pfModule
	return v5_
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
	local v7_ = not g_currentMission.hud:isInGameMessageVisible()
	if v7_ then
		v7_ = not g_gui:getIsGuiVisible()
	end
	return v7_
end

function HelplineExtension:onFirstTimeRun()
	YesNoDialog.show(self.onFirstTimeRunDialog, self, g_i18n:getText("precisionFarming_firstStart", HelplineExtension.MOD_NAME))
end

function HelplineExtension:onFirstTimeRunDialog(yes)
	if yes then
		self:openHelpMenu(1)
	end
end

-- Local values: helpLinePage
function HelplineExtension:openHelpMenu(offsetIndex)
	if g_gui.currentGuiName ~= "InGameMenu" then
		g_gui:showGui("InGameMenu")
	end
	if g_currentMission ~= nil then
		local v12_ = g_inGameMenu.pageHelpLine
		g_inGameMenu:openHelpLine(1, 1)
		v12_:openPage(1, offsetIndex, HelplineExtension.MOD_NAME)
	end
end

function HelplineExtension:fillSeedRateRows(contentBox, template)
	if self.pfModule.seedRateMap ~= nil then
		self.pfModule.seedRateMap:createHelpMenuSeedRateTable(contentBox, template)
	end
end
function HelplineExtension.overwriteGameFunctions(p_u_16_, p17_)
	p17_:overwriteGameFunction(InGameMenuHelpFrame, "updateContents", function(p18_, p19_, p20_)
		-- upvalues: (copy) p_u_16_, (copy) p_u_16_
		p18_(p19_, p20_)
		if #p20_.paragraphs > 0 then
			local v21_ = p20_.paragraphs[#p20_.paragraphs]
			if v21_.text == "$l10n_helpText_07_part03" and v21_.customEnvironment == HelplineExtension.MOD_NAME then
				p_u_16_:fillSeedRateRows(p19_.helpLineContentBox, p_u_16_.precisionFarmingSeedRateRowTemplate)
			end
		end
	end)
	p17_:overwriteGameFunction(InGameMenuHelpFrame, "onFrameOpen", function(p22_, p23_)
		-- upvalues: (copy) p_u_16_
		if p_u_16_.precisionFarmingSeedRateContainer == nil then
			p_u_16_.precisionFarmingSeedRateContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/HelpFrameSeedRateExtension.xml", p23_, p23_.elements[1])
			p_u_16_.precisionFarmingSeedRateContainer:unlinkElement()
			p_u_16_.precisionFarmingSeedRateContainer:setVisible(false)
			p_u_16_.precisionFarmingSeedRateRowTemplate = p_u_16_.precisionFarmingSeedRateContainer.elements[1]
		end
		p22_(p23_)
	end)
end
