PrecisionFarmingGUI = {}
PrecisionFarmingGUI.MOD_NAME = g_currentModName
PrecisionFarmingGUI.MOD_DIR = g_currentModDirectory

-- Local values: newElement, xmlFile
function PrecisionFarmingGUI.loadAdditionalGUI(filename, parentTarget, parentElement)
	local v4_ = nil
	local v5_ = loadXMLFile("Temp", PrecisionFarmingGUI.MOD_DIR .. filename)
	if v5_ ~= nil and v5_ ~= 0 then
		if parentElement ~= nil then
			g_gui:loadProfileSet(v5_, "GUI.GuiProfiles", g_gui.presets)
			g_gui:loadGuiRec(v5_, "GUI", parentElement, parentTarget)
			v4_ = parentElement.elements[#parentElement.elements]
			v4_:updateAbsolutePosition()
			parentTarget:exposeControlsAsFields()
			parentTarget:onGuiSetupFinished()
		end
		delete(v5_)
	end
	return v4_
end
function PrecisionFarmingGUI.initializeGUI()
	g_gui:loadProfiles(PrecisionFarmingGUI.MOD_DIR .. "gui/guiProfiles.xml")
	g_overlayManager:addTextureConfigFile(PrecisionFarmingGUI.MOD_DIR .. "gui/ui_elements.xml", "precisionFarming")
	g_overlayManager:addTextureConfigFile(PrecisionFarmingGUI.MOD_DIR .. "gui/helplinePrecisionFarmingSmall.xml", "precisionFarmingHelplineSmall")
end
if g_gui ~= nil then
	PrecisionFarmingGUI.initializeGUI()
end
