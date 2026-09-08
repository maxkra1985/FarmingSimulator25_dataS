-- Local values: CreditsScreen_mt
CreditsScreen = {}
CreditsScreen.TITLE = 0
CreditsScreen.TEXT = 1
CreditsScreen.SEPARATOR = 2
CreditsScreen.DISCLAIMER = 3
CreditsScreen.LIST_TEMPLATE_ELEMENT_NAME = {}
local CreditsScreen_mt = Class(CreditsScreen, ScreenElement)
function CreditsScreen.register()
	local v2_ = CreditsScreen.new()
	g_gui:loadGui("dataS/gui/CreditsScreen.xml", "CreditsScreen", v2_)
end

-- Upvalues: CreditsScreen_mt
-- Local values: self
function CreditsScreen.new(target, custom_mt)
	-- upvalues: (copy) CreditsScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or CreditsScreen_mt)
	v5_:setReturnScreenClass(MainScreen)
	return v5_
end

-- Local values: newGui
function CreditsScreen.createFromExistingGui(gui, guiName)
	local v8_ = CreditsScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

function CreditsScreen:onCreate(element)
	self.creditsTitleElement:unlinkElement()
	self.creditsTextElement:unlinkElement()
	self.creditsDisclaimerElement:unlinkElement()
	self:loadCredits()
	self.creditsStartY = self.creditsPlaceholder.absPosition[2]
end

-- Local values: mainContainerSize, _, item
function CreditsScreen:onOpen()
	CreditsScreen:superClass().onOpen(self)
	self.creditsPlaceholder:invalidateLayout(true)
	if Platform.isMobile then
		local v11_ = (g_screenWidth - self.sidebar.absSize[1] * g_screenWidth - 50) * g_pixelSizeX
		self.mainContainer.absSize[1] = v11_
		self.creditsVisibilityBox:setAnchors(0, 1 - (v11_ - self.creditsVisibilityBox.size[1]), 0.1, 0.9)
		self.mainContainer.absPosition[1] = 1 - v11_
		self.mainContainer:setAnchors(self.mainContainer.absPosition[1], 1, 0, 1)
		self.mainContainer:updateAbsolutePosition()
		if getPlatformId() == PlatformId.ANDROID then
			self.achievementsButton:setDisabled(not getIsUserSignedIn())
		end
	end
	if Platform.hasMainScreenLanguageSelection then
		self.changeLanguageButton:setVisible(true)
		self.buttonBox:invalidateLayout()
	end
	for _, v12_ in pairs(self.creditsElements) do
		v12_:setAlpha(0)
	end
	self.nextFadeInCreditsItemId = 1
	self.nextFadeOutCreditsItemId = 1
	self.creditsPlaceholder:setAbsolutePosition(self.creditsPlaceholder.absPosition[1], self.creditsStartY)
	if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "highlandsFishingPack"] == nil then
		self.backgroundImage:setImageFilename("shared/splash.png")
	else
		self.backgroundImage:setImageFilename("shared/splash_highlandsFishing.png")
	end
	self:updateTheme()
end

function CreditsScreen:delete()
	self.creditsTitleElement:delete()
	self.creditsTextElement:delete()
	self.creditsDisclaimerElement:delete()
	CreditsScreen:superClass().delete(self)
end

-- Local values: y, y
function CreditsScreen:update(dt)
	CreditsScreen:superClass().update(self, dt)
	self.creditsPlaceholder:setAbsolutePosition(self.creditsPlaceholder.absPosition[1], self.creditsPlaceholder.absPosition[2] + 0.00007 * dt)
	if self.nextFadeInCreditsItemId <= #self.creditsElements and self.creditsElements[self.nextFadeInCreditsItemId].absPosition[2] > self.creditsVisibilityBox.absPosition[2] then
		self.creditsElements[self.nextFadeInCreditsItemId]:fadeIn(1.2)
		self.nextFadeInCreditsItemId = self.nextFadeInCreditsItemId + 1
	end
	if self.nextFadeOutCreditsItemId <= #self.creditsElements then
		if self.creditsElements[self.nextFadeOutCreditsItemId].absPosition[2] > self.creditsVisibilityBox.absPosition[2] + self.creditsVisibilityBox.absSize[2] * 0.8 then
			self.creditsElements[self.nextFadeOutCreditsItemId]:fadeOut(4)
			self.nextFadeOutCreditsItemId = self.nextFadeOutCreditsItemId + 1
			return
		end
	else
		self:onClickBack()
	end
end

-- Local values: creditsTexts, i, _, creditsElem, newCreditsElem, height
function CreditsScreen:loadCredits()
	local v17_ = {}
	local v18_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Developed by"
	}
	table.insert(v17_, v18_)
	local v19_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "GIANTS Software GmbH"
	}
	table.insert(v17_, v19_)
	local v20_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v20_)
	local v21_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Executive Producer"
	}
	table.insert(v17_, v21_)
	local v22_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Christian Ammann"
	}
	table.insert(v17_, v22_)
	local v23_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v23_)
	local v24_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Chief Technical Officer"
	}
	table.insert(v17_, v24_)
	local v25_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Stefan Geiger"
	}
	table.insert(v17_, v25_)
	local v26_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v26_)
	local v27_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Creative Director"
	}
	table.insert(v17_, v27_)
	local v28_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Thomas Frey"
	}
	table.insert(v17_, v28_)
	local v29_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v29_)
	local v30_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Level Designer"
	}
	table.insert(v17_, v30_)
	local v31_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Renzo Th\195\182nen"
	}
	table.insert(v17_, v31_)
	local v32_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v32_)
	local v33_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Programmer"
	}
	table.insert(v17_, v33_)
	local v34_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Thomas Brunner"
	}
	table.insert(v17_, v34_)
	local v35_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v35_)
	local v36_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Gameplay Programmer"
	}
	table.insert(v17_, v36_)
	local v37_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Manuel Leithner"
	}
	table.insert(v17_, v37_)
	local v38_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v38_)
	local v39_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Tools Programmer"
	}
	table.insert(v17_, v39_)
	local v40_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Rudolf-Walter Kiss-Szak\195\161cs"
	}
	table.insert(v17_, v40_)
	local v41_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v41_)
	local v42_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Artist"
	}
	table.insert(v17_, v42_)
	local v43_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marc Schwegler"
	}
	table.insert(v17_, v43_)
	local v44_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v44_)
	local v45_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Studio Manager"
	}
	table.insert(v17_, v45_)
	local v46_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Luk\195\161\197\161 Ku\197\153e"
	}
	table.insert(v17_, v46_)
	local v47_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v47_)
	if Platform.isPlaystation then
		local v48_ = {
			["t"] = CreditsScreen.TITLE,
			["c"] = "Senior PlayStation\194\1745 Programmer"
		}
		table.insert(v17_, v48_)
		local v49_ = {
			["t"] = CreditsScreen.TEXT,
			["c"] = "Eddie Edwards"
		}
		table.insert(v17_, v49_)
		local v50_ = {
			["t"] = CreditsScreen.SEPARATOR
		}
		table.insert(v17_, v50_)
		local v51_ = {
			["t"] = CreditsScreen.TITLE,
			["c"] = "Senior Programmers"
		}
		table.insert(v17_, v51_)
	elseif Platform.isSwitch2 then
		local v52_ = {
			["t"] = CreditsScreen.TITLE,
			["c"] = "Senior Nintendo Switch 2 Programmer"
		}
		table.insert(v17_, v52_)
		local v53_ = {
			["t"] = CreditsScreen.TEXT,
			["c"] = "Eddie Edwards"
		}
		table.insert(v17_, v53_)
		local v54_ = {
			["t"] = CreditsScreen.SEPARATOR
		}
		table.insert(v17_, v54_)
		local v55_ = {
			["t"] = CreditsScreen.TITLE,
			["c"] = "Senior Programmers"
		}
		table.insert(v17_, v55_)
	else
		local v56_ = {
			["t"] = CreditsScreen.TITLE,
			["c"] = "Senior Programmers"
		}
		table.insert(v17_, v56_)
		local v57_ = {
			["t"] = CreditsScreen.TEXT,
			["c"] = "Eddie Edwards"
		}
		table.insert(v17_, v57_)
	end
	local v58_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "J\195\169r\195\180me Torche"
	}
	table.insert(v17_, v58_)
	local v59_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Olivier Four\195\169"
	}
	table.insert(v17_, v59_)
	local v60_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Samo Jordan"
	}
	table.insert(v17_, v60_)
	local v61_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v61_)
	local v62_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Programmers"
	}
	table.insert(v17_, v62_)
	local v63_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bao-Anh Dang-Vu"
	}
	table.insert(v17_, v63_)
	local v64_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bojan Kerec"
	}
	table.insert(v17_, v64_)
	local v65_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Gino van den Bergen"
	}
	table.insert(v17_, v65_)
	local v66_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jan Dellsperger"
	}
	table.insert(v17_, v66_)
	local v67_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Laura Jenkins"
	}
	table.insert(v17_, v67_)
	local v68_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Lukas Nussbaumer"
	}
	table.insert(v17_, v68_)
	local v69_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marius Hofmann"
	}
	table.insert(v17_, v69_)
	local v70_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Nicolas Wrobel"
	}
	table.insert(v17_, v70_)
	local v71_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Philipp J\195\164ger"
	}
	table.insert(v17_, v71_)
	local v72_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Travis Gesslein"
	}
	table.insert(v17_, v72_)
	local v73_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v73_)
	local v74_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Vehicle Integrator"
	}
	table.insert(v17_, v74_)
	local v75_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Stefan Maurus"
	}
	table.insert(v17_, v75_)
	local v76_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v76_)
	local v77_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Vehicle Integrators"
	}
	table.insert(v17_, v77_)
	local v78_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Arkadiusz Wodnicki"
	}
	table.insert(v17_, v78_)
	local v79_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Christian Wachter"
	}
	table.insert(v17_, v79_)
	local v80_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Daniel Witzel"
	}
	table.insert(v17_, v80_)
	local v81_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Niklas Schumacher"
	}
	table.insert(v17_, v81_)
	local v82_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Simon Nussel"
	}
	table.insert(v17_, v82_)
	local v83_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Stephan Bongartz"
	}
	table.insert(v17_, v83_)
	local v84_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v84_)
	local v85_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Associate Producer"
	}
	table.insert(v17_, v85_)
	local v86_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Horia Serban"
	}
	table.insert(v17_, v86_)
	local v87_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v87_)
	local v88_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Head of Art Brno"
	}
	table.insert(v17_, v88_)
	local v89_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tom\195\161\197\161 Dost\195\161l"
	}
	table.insert(v17_, v89_)
	local v90_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v90_)
	local v91_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Vehicle Artist"
	}
	table.insert(v17_, v91_)
	local v92_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jan Egon Preiss"
	}
	table.insert(v17_, v92_)
	local v93_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v93_)
	local v94_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Character Artists"
	}
	table.insert(v17_, v94_)
	local v95_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Roman Pelypenko"
	}
	table.insert(v17_, v95_)
	local v96_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v96_)
	local v97_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Head of Outsourcing"
	}
	table.insert(v17_, v97_)
	local v98_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Siddhant Patni"
	}
	table.insert(v17_, v98_)
	local v99_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v99_)
	local v100_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Technical Artists"
	}
	table.insert(v17_, v100_)
	local v101_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Evgeniy Zaitsev"
	}
	table.insert(v17_, v101_)
	local v102_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marta Stolarz"
	}
	table.insert(v17_, v102_)
	local v103_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v103_)
	local v104_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Artists"
	}
	table.insert(v17_, v104_)
	local v105_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Alberto L\195\179pez Toledo"
	}
	table.insert(v17_, v105_)
	local v106_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Anton Miroshnychenko"
	}
	table.insert(v17_, v106_)
	local v107_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Arthur Franchitto"
	}
	table.insert(v17_, v107_)
	local v108_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Carlo Tosini"
	}
	table.insert(v17_, v108_)
	local v109_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Daniel Beyer"
	}
	table.insert(v17_, v109_)
	local v110_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Felipe Juste"
	}
	table.insert(v17_, v110_)
	local v111_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Florian Busse"
	}
	table.insert(v17_, v111_)
	local v112_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Gabriel Hubli"
	}
	table.insert(v17_, v112_)
	local v113_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ivan Stanchev"
	}
	table.insert(v17_, v113_)
	local v114_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jakub Havel"
	}
	table.insert(v17_, v114_)
	local v115_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jakub Valehrach"
	}
	table.insert(v17_, v115_)
	local v116_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jan Dobrovoln\195\189"
	}
	table.insert(v17_, v116_)
	local v117_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "J\195\161n Ohajsk\195\189"
	}
	table.insert(v17_, v117_)
	local v118_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jozef Rolincin"
	}
	table.insert(v17_, v118_)
	local v119_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Justin Mitrache"
	}
	table.insert(v17_, v119_)
	local v120_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Katarzyna Krzyczkowska"
	}
	table.insert(v17_, v120_)
	local v121_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kenan Jusic"
	}
	table.insert(v17_, v121_)
	local v122_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kevin Ellersiek"
	}
	table.insert(v17_, v122_)
	local v123_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mahdi Dehghani"
	}
	table.insert(v17_, v123_)
	local v124_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maksim Povstugar"
	}
	table.insert(v17_, v124_)
	local v125_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maria Panfilova"
	}
	table.insert(v17_, v125_)
	local v126_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Miroslav Halfar"
	}
	table.insert(v17_, v126_)
	local v127_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maximilian Fr\195\182mter"
	}
	table.insert(v17_, v127_)
	local v128_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Natalia Tkach"
	}
	table.insert(v17_, v128_)
	local v129_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Oleksandr Pelypenko"
	}
	table.insert(v17_, v129_)
	local v130_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Philipp K\195\182rber"
	}
	table.insert(v17_, v130_)
	local v131_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Radek \197\160vec"
	}
	table.insert(v17_, v131_)
	local v132_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Rahul Narode"
	}
	table.insert(v17_, v132_)
	local v133_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ra\195\186l Arencibia"
	}
	table.insert(v17_, v133_)
	local v134_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Reinaldo Artidiello"
	}
	table.insert(v17_, v134_)
	local v135_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "\197\160t\196\155p\195\161n Ba\197\153ina"
	}
	table.insert(v17_, v135_)
	local v136_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Thomas Flachs"
	}
	table.insert(v17_, v136_)
	local v137_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tom\195\161\197\161 Protivansk\195\189"
	}
	table.insert(v17_, v137_)
	local v138_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Vanessa Weidmann"
	}
	table.insert(v17_, v138_)
	local v139_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Vilen Saatsazov"
	}
	table.insert(v17_, v139_)
	local v140_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Vladyslav Vershytskyi"
	}
	table.insert(v17_, v140_)
	local v141_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v141_)
	local v142_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Graphic Designer"
	}
	table.insert(v17_, v142_)
	local v143_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Sandra Meier"
	}
	table.insert(v17_, v143_)
	local v144_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v144_)
	local v145_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Graphic Designers"
	}
	table.insert(v17_, v145_)
	local v146_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Evelyn Eismann"
	}
	table.insert(v17_, v146_)
	local v147_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Katrin Huber"
	}
	table.insert(v17_, v147_)
	local v148_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mariana Borsari"
	}
	table.insert(v17_, v148_)
	local v149_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Michael Karg"
	}
	table.insert(v17_, v149_)
	local v150_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v150_)
	local v151_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Audio Designer"
	}
	table.insert(v17_, v151_)
	local v152_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Nils Heine"
	}
	table.insert(v17_, v152_)
	local v153_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v153_)
	local v154_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Audio Designers"
	}
	table.insert(v17_, v154_)
	local v155_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Andr\195\169 Sousa"
	}
	table.insert(v17_, v155_)
	local v156_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v156_)
	local v157_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "QA Analysts"
	}
	table.insert(v17_, v157_)
	local v158_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Adrien Br\195\188llmann"
	}
	table.insert(v17_, v158_)
	local v159_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Benjamin Neu\195\159inger"
	}
	table.insert(v17_, v159_)
	local v160_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Davide Nicol\195\178 Bertossio"
	}
	table.insert(v17_, v160_)
	local v161_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dominika Wojtulewicz"
	}
	table.insert(v17_, v161_)
	local v162_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jana Stephan"
	}
	table.insert(v17_, v162_)
	local v163_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kacper Walczak"
	}
	table.insert(v17_, v163_)
	local v164_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "L\195\169o Carrier"
	}
	table.insert(v17_, v164_)
	local v165_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Lo\195\175ck Ru\195\159"
	}
	table.insert(v17_, v165_)
	local v166_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marcel Renke"
	}
	table.insert(v17_, v166_)
	local v167_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marian Kysel"
	}
	table.insert(v17_, v167_)
	local v168_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mateusz Dziuba"
	}
	table.insert(v17_, v168_)
	local v169_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Oliver Kraus"
	}
	table.insert(v17_, v169_)
	local v170_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Petr Ochonsk\195\189"
	}
	table.insert(v17_, v170_)
	local v171_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mario Vortkamp"
	}
	table.insert(v17_, v171_)
	local v172_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Oliwier Ilin"
	}
	table.insert(v17_, v172_)
	local v173_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Vendula Toma\197\136ov\195\161"
	}
	table.insert(v17_, v173_)
	local v174_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v174_)
	local v175_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Head of Publishing"
	}
	table.insert(v17_, v175_)
	local v176_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Boris Stefan"
	}
	table.insert(v17_, v176_)
	local v177_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v177_)
	local v178_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Head of Marketing & PR"
	}
	table.insert(v17_, v178_)
	local v179_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Martin Rabl"
	}
	table.insert(v17_, v179_)
	local v180_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v180_)
	local v181_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "PR Manager"
	}
	table.insert(v17_, v181_)
	local v182_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Wolfgang Ebert"
	}
	table.insert(v17_, v182_)
	local v183_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v183_)
	local v184_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Content Marketing Manager"
	}
	table.insert(v17_, v184_)
	local v185_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dennis Reisdorf"
	}
	table.insert(v17_, v185_)
	local v186_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v186_)
	local v187_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Social Media & Brand Content Specialist"
	}
	table.insert(v17_, v187_)
	local v188_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "J\195\182rg Koonen"
	}
	table.insert(v17_, v188_)
	local v189_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v189_)
	local v190_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Release Manager"
	}
	table.insert(v17_, v190_)
	local v191_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Carlo Sarti"
	}
	table.insert(v17_, v191_)
	local v192_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v192_)
	local v193_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Distribution Operations Manager"
	}
	table.insert(v17_, v193_)
	local v194_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Anna Ru\195\159"
	}
	table.insert(v17_, v194_)
	local v195_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v195_)
	local v196_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Publishing Assistant"
	}
	table.insert(v17_, v196_)
	local v197_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Darren Cahill"
	}
	table.insert(v17_, v197_)
	local v198_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v198_)
	local v199_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Account Manager"
	}
	table.insert(v17_, v199_)
	local v200_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Martin Seidel"
	}
	table.insert(v17_, v200_)
	local v201_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v201_)
	local v202_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Technical Projects Coordinator"
	}
	table.insert(v17_, v202_)
	local v203_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jan-Hendrik Pfitzner"
	}
	table.insert(v17_, v203_)
	local v204_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v204_)
	local v205_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Community Managers"
	}
	table.insert(v17_, v205_)
	local v206_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Christoph Stumpfer"
	}
	table.insert(v17_, v206_)
	local v207_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kermit Ball"
	}
	table.insert(v17_, v207_)
	local v208_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Benjamin Galla"
	}
	table.insert(v17_, v208_)
	local v209_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Lars Malcharek"
	}
	table.insert(v17_, v209_)
	local v210_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v210_)
	local v211_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Customer Support Lead"
	}
	table.insert(v17_, v211_)
	local v212_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Christofer Zoltan"
	}
	table.insert(v17_, v212_)
	local v213_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v213_)
	local v214_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Customer Support Representatives"
	}
	table.insert(v17_, v214_)
	local v215_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Detlef B\195\182vers"
	}
	table.insert(v17_, v215_)
	local v216_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Nicholas Frazier"
	}
	table.insert(v17_, v216_)
	local v217_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v217_)
	local v218_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Web Developers"
	}
	table.insert(v17_, v218_)
	local v219_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Fabian Seitz"
	}
	table.insert(v17_, v219_)
	local v220_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marten Boessenkool"
	}
	table.insert(v17_, v220_)
	local v221_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Miroslav Mina\197\153\195\173k"
	}
	table.insert(v17_, v221_)
	local v222_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v222_)
	local v223_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Lead Video Artist"
	}
	table.insert(v17_, v223_)
	local v224_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Michael Schraut"
	}
	table.insert(v17_, v224_)
	local v225_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v225_)
	local v226_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Video Artist"
	}
	table.insert(v17_, v226_)
	local v227_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marco Riccardi"
	}
	table.insert(v17_, v227_)
	local v228_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Daniel Walker"
	}
	table.insert(v17_, v228_)
	local v229_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v229_)
	local v230_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Event Manager"
	}
	table.insert(v17_, v230_)
	local v231_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Claas Eilermann"
	}
	table.insert(v17_, v231_)
	local v232_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v232_)
	local v233_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Event Technician"
	}
	table.insert(v17_, v233_)
	local v234_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jonas Luh"
	}
	table.insert(v17_, v234_)
	local v235_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Simao Ramos"
	}
	table.insert(v17_, v235_)
	local v236_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v236_)
	local v237_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "HR Representative"
	}
	table.insert(v17_, v237_)
	local v238_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Petra Erlbacher"
	}
	table.insert(v17_, v238_)
	local v239_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v239_)
	local v240_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Office Managers"
	}
	table.insert(v17_, v240_)
	local v241_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ad\195\169la \197\160trajtov\195\161"
	}
	table.insert(v17_, v241_)
	local v242_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Chodon F\195\188rer-Rikyog"
	}
	table.insert(v17_, v242_)
	local v243_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jennifer Dradrach"
	}
	table.insert(v17_, v243_)
	local v244_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v244_)
	local v245_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Characters Voices"
	}
	table.insert(v17_, v245_)
	local v246_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Brian Burgess (Grandpa Walter)"
	}
	table.insert(v17_, v246_)
	local v247_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Simao Ramos (David)"
	}
	table.insert(v17_, v247_)
	local v248_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Cari Sholtens (Katie)"
	}
	table.insert(v17_, v248_)
	local v249_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Greg Gidney (Noah)"
	}
	table.insert(v17_, v249_)
	local v250_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Anthony Proctor (Helper Ben)"
	}
	table.insert(v17_, v250_)
	local v251_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "John Kennard (Alasdair)"
	}
	table.insert(v17_, v251_)
	local v252_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v252_)
	local v253_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Characters Writers"
	}
	table.insert(v17_, v253_)
	local v254_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dennis Reisdorf (Grandpa Walter, David)"
	}
	table.insert(v17_, v254_)
	local v255_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Erell Le Drezen (Katie)"
	}
	table.insert(v17_, v255_)
	local v256_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Lukas Schreiner (Noah, Helper Ben)"
	}
	table.insert(v17_, v256_)
	local v257_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jana Stephan (Helper Ben)"
	}
	table.insert(v17_, v257_)
	local v258_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Lena Falkenhagen (Guided Tour)"
	}
	table.insert(v17_, v258_)
	local v259_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jennifer Dradrach (Integration)"
	}
	table.insert(v17_, v259_)
	local v260_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v260_)
	local v261_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Radio & Music"
	}
	table.insert(v17_, v261_)
	local v262_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Audio Network GmbH"
	}
	table.insert(v17_, v262_)
	local v263_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v263_)
	local v264_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Music Composer"
	}
	table.insert(v17_, v264_)
	local v265_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mike Dwyer"
	}
	table.insert(v17_, v265_)
	local v266_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v266_)
	local v267_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Co-Publisher Japan/Asia"
	}
	table.insert(v17_, v267_)
	local v268_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "SEGA CORPORATION"
	}
	table.insert(v17_, v268_)
	local v269_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v269_)
	local v270_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Partner Relationship"
	}
	table.insert(v17_, v270_)
	local v271_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Takako Takusagawa"
	}
	table.insert(v17_, v271_)
	local v272_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Shun Takakuwa"
	}
	table.insert(v17_, v272_)
	local v273_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tomoaki Ishidao"
	}
	table.insert(v17_, v273_)
	local v274_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tsekin Lai"
	}
	table.insert(v17_, v274_)
	local v275_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ke Liang"
	}
	table.insert(v17_, v275_)
	local v276_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Sandy Lig"
	}
	table.insert(v17_, v276_)
	local v277_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v277_)
	local v278_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Project Management"
	}
	table.insert(v17_, v278_)
	local v279_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bing Lyu"
	}
	table.insert(v17_, v279_)
	local v280_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mio Yoshiba"
	}
	table.insert(v17_, v280_)
	local v281_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Yoshiaki Yamazaki"
	}
	table.insert(v17_, v281_)
	local v282_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v282_)
	local v283_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Operations"
	}
	table.insert(v17_, v283_)
	local v284_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Makoto Ito"
	}
	table.insert(v17_, v284_)
	local v285_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Susumu Ookoshi"
	}
	table.insert(v17_, v285_)
	local v286_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Yuki Sumida"
	}
	table.insert(v17_, v286_)
	local v287_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Weichen Lu"
	}
	table.insert(v17_, v287_)
	local v288_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v288_)
	local v289_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Product Marketing"
	}
	table.insert(v17_, v289_)
	local v290_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maika Nakasone"
	}
	table.insert(v17_, v290_)
	local v291_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Hiori Masuda"
	}
	table.insert(v17_, v291_)
	local v292_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tsuguharu Ishihara"
	}
	table.insert(v17_, v292_)
	local v293_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Hiroko Karube"
	}
	table.insert(v17_, v293_)
	local v294_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Masaya Santo"
	}
	table.insert(v17_, v294_)
	local v295_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v295_)
	local v296_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "PR + Publicity"
	}
	table.insert(v17_, v296_)
	local v297_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Chihiro Miki"
	}
	table.insert(v17_, v297_)
	local v298_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Keiko Yoshie"
	}
	table.insert(v17_, v298_)
	local v299_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ai Ogata"
	}
	table.insert(v17_, v299_)
	local v300_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Nana Yamaguchi"
	}
	table.insert(v17_, v300_)
	local v301_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tetsuhiro Kohira"
	}
	table.insert(v17_, v301_)
	local v302_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Rena Sakai"
	}
	table.insert(v17_, v302_)
	local v303_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Siyi Xiang"
	}
	table.insert(v17_, v303_)
	local v304_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Emi Shiobara"
	}
	table.insert(v17_, v304_)
	local v305_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v305_)
	local v306_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Japan Sales"
	}
	table.insert(v17_, v306_)
	local v307_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Katsutoshi Memezawa"
	}
	table.insert(v17_, v307_)
	local v308_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Tomohiko Hayashi"
	}
	table.insert(v17_, v308_)
	local v309_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Shuto Kobayashi"
	}
	table.insert(v17_, v309_)
	local v310_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Junichiro Suzuki"
	}
	table.insert(v17_, v310_)
	local v311_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Yusuke Ohashi"
	}
	table.insert(v17_, v311_)
	local v312_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Keiichi Oshima"
	}
	table.insert(v17_, v312_)
	local v313_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Toshiyuki Tanaka"
	}
	table.insert(v17_, v313_)
	local v314_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Masahiro Tanaka"
	}
	table.insert(v17_, v314_)
	local v315_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Shinya Oosaki"
	}
	table.insert(v17_, v315_)
	local v316_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Field Crew Service Co.,Ltd."
	}
	table.insert(v17_, v316_)
	local v317_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v317_)
	local v318_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Asia Sales"
	}
	table.insert(v17_, v318_)
	local v319_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Yoshinori Akiyama"
	}
	table.insert(v17_, v319_)
	local v320_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Takeyuki Iso"
	}
	table.insert(v17_, v320_)
	local v321_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kousuke Uenaka"
	}
	table.insert(v17_, v321_)
	local v322_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Youichiro Shimada"
	}
	table.insert(v17_, v322_)
	local v323_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Yuta Tamagami"
	}
	table.insert(v17_, v323_)
	local v324_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Yaoxuan Bai"
	}
	table.insert(v17_, v324_)
	local v325_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Melody Law Qui-Yi"
	}
	table.insert(v17_, v325_)
	local v326_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Hiroki Nagashima"
	}
	table.insert(v17_, v326_)
	local v327_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v327_)
	local v328_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "External QA"
	}
	table.insert(v17_, v328_)
	local v329_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Testronic"
	}
	table.insert(v17_, v329_)
	local v330_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v330_)
	local v331_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Chief Services Officer"
	}
	table.insert(v17_, v331_)
	local v332_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Erik Hittenhausen"
	}
	table.insert(v17_, v332_)
	local v333_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v333_)
	local v334_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Director of Operations"
	}
	table.insert(v17_, v334_)
	local v335_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Stephan Herbig"
	}
	table.insert(v17_, v335_)
	local v336_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v336_)
	local v337_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Business Development Account Director"
	}
	table.insert(v17_, v337_)
	local v338_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "El\197\188bieta Pustu\197\130"
	}
	table.insert(v17_, v338_)
	local v339_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v339_)
	local v340_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Senior QA Manager"
	}
	table.insert(v17_, v340_)
	local v341_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Pawe\197\130 Ko\197\130nierzak"
	}
	table.insert(v17_, v341_)
	local v342_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v342_)
	local v343_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "QA Manager"
	}
	table.insert(v17_, v343_)
	local v344_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Klaudia Mower"
	}
	table.insert(v17_, v344_)
	local v345_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Pawe\197\130 Marciniak"
	}
	table.insert(v17_, v345_)
	local v346_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v346_)
	local v347_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Functionality QA"
	}
	table.insert(v17_, v347_)
	local v348_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "QA Project Manager"
	}
	table.insert(v17_, v348_)
	local v349_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Sebastian Kurek"
	}
	table.insert(v17_, v349_)
	local v350_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v350_)
	local v351_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "QA Project Lead"
	}
	table.insert(v17_, v351_)
	local v352_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Micha\197\130 \197\154widzi\197\132ski"
	}
	table.insert(v17_, v352_)
	local v353_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v353_)
	local v354_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Associate QA Project Leads"
	}
	table.insert(v17_, v354_)
	local v355_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dawid Szeliga"
	}
	table.insert(v17_, v355_)
	local v356_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v356_)
	local v357_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Functionality QA Analysts"
	}
	table.insert(v17_, v357_)
	local v358_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maciej Jarczewski"
	}
	table.insert(v17_, v358_)
	local v359_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Pawe\197\130 Pielech"
	}
	table.insert(v17_, v359_)
	local v360_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v360_)
	local v361_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Functionality QA Senior Technicians"
	}
	table.insert(v17_, v361_)
	local v362_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bartosz Kryszan"
	}
	table.insert(v17_, v362_)
	local v363_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Joshua De\226\128\153Ath"
	}
	table.insert(v17_, v363_)
	local v364_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v364_)
	local v365_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Functionality QA Technicians"
	}
	table.insert(v17_, v365_)
	local v366_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bart\197\130omiej Drozd"
	}
	table.insert(v17_, v366_)
	local v367_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bartosz Cie\197\155lak"
	}
	table.insert(v17_, v367_)
	local v368_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Cosmin-George Pandichi"
	}
	table.insert(v17_, v368_)
	local v369_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Hayam Mansour"
	}
	table.insert(v17_, v369_)
	local v370_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jainal Panchal"
	}
	table.insert(v17_, v370_)
	local v371_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kamil Kaczor"
	}
	table.insert(v17_, v371_)
	local v372_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Krzysztof Goliniewski"
	}
	table.insert(v17_, v372_)
	local v373_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maciej Powa\197\130a"
	}
	table.insert(v17_, v373_)
	local v374_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Magdalena Dro\197\188y\197\132ska"
	}
	table.insert(v17_, v374_)
	local v375_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Maksymilian Zwirkowski"
	}
	table.insert(v17_, v375_)
	local v376_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Micha\197\130 Pielech"
	}
	table.insert(v17_, v376_)
	local v377_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Pawe\197\130 Bara\197\132ski"
	}
	table.insert(v17_, v377_)
	local v378_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Rafa\197\130 S\197\130owik"
	}
	table.insert(v17_, v378_)
	local v379_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ryszard Bartocha"
	}
	table.insert(v17_, v379_)
	local v380_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Sebastian Fuchs"
	}
	table.insert(v17_, v380_)
	local v381_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v381_)
	local v382_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compliance & Compatibility QA"
	}
	table.insert(v17_, v382_)
	local v383_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compliance and Compatibility Manager"
	}
	table.insert(v17_, v383_)
	local v384_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Iwona Szarzy\197\132ska"
	}
	table.insert(v17_, v384_)
	local v385_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v385_)
	local v386_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Senior Compliance and Compatibility Project Lead"
	}
	table.insert(v17_, v386_)
	local v387_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ma\197\130gorzata Twarogal"
	}
	table.insert(v17_, v387_)
	local v388_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v388_)
	local v389_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compliance QA"
	}
	table.insert(v17_, v389_)
	local v390_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compliance QA Lead"
	}
	table.insert(v17_, v390_)
	local v391_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Micha\197\130 Rad\197\130owski"
	}
	table.insert(v17_, v391_)
	local v392_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v392_)
	local v393_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Associate Compliance QA Lead"
	}
	table.insert(v17_, v393_)
	local v394_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Adrian Strzelecki"
	}
	table.insert(v17_, v394_)
	local v395_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dorian Geisler"
	}
	table.insert(v17_, v395_)
	local v396_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v396_)
	local v397_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compliance QA Analyst"
	}
	table.insert(v17_, v397_)
	local v398_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Agata Dylak-Str\196\133k"
	}
	table.insert(v17_, v398_)
	local v399_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Alicja Nosecka"
	}
	table.insert(v17_, v399_)
	local v400_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Aneta Majek"
	}
	table.insert(v17_, v400_)
	local v401_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jakub Neyman"
	}
	table.insert(v17_, v401_)
	local v402_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v402_)
	local v403_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compliance QA Technicians"
	}
	table.insert(v17_, v403_)
	local v404_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Agata Cywi\197\132ska"
	}
	table.insert(v17_, v404_)
	local v405_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Anandha Mohanan"
	}
	table.insert(v17_, v405_)
	local v406_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Damian Utrata"
	}
	table.insert(v17_, v406_)
	local v407_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Ganna Nasser"
	}
	table.insert(v17_, v407_)
	local v408_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Hakan Berk Soydan"
	}
	table.insert(v17_, v408_)
	local v409_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jainal Panchal"
	}
	table.insert(v17_, v409_)
	local v410_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "\197\129ukasz Seremet"
	}
	table.insert(v17_, v410_)
	local v411_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Martyna Jurczy\197\132ska"
	}
	table.insert(v17_, v411_)
	local v412_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Nikadzim Runtsou"
	}
	table.insert(v17_, v412_)
	local v413_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Pax Kibart"
	}
	table.insert(v17_, v413_)
	local v414_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Sanjeet Earnest"
	}
	table.insert(v17_, v414_)
	local v415_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Sodiq Adefila"
	}
	table.insert(v17_, v415_)
	local v416_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v416_)
	local v417_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "PC Compatibility QA"
	}
	table.insert(v17_, v417_)
	local v418_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Associate Compatibility QA Lead"
	}
	table.insert(v17_, v418_)
	local v419_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Micha\197\130 Soral"
	}
	table.insert(v17_, v419_)
	local v420_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v420_)
	local v421_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compatibility QA Analyst"
	}
	table.insert(v17_, v421_)
	local v422_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "\197\129ukasz \197\129aci\197\132ski"
	}
	table.insert(v17_, v422_)
	local v423_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v423_)
	local v424_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Compatibility QA Technicians"
	}
	table.insert(v17_, v424_)
	local v425_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Bart\197\130omiej Stajkowski"
	}
	table.insert(v17_, v425_)
	local v426_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Brine Mukombachoto"
	}
	table.insert(v17_, v426_)
	local v427_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dominik Krawczyk"
	}
	table.insert(v17_, v427_)
	local v428_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Haran Dev Murugan"
	}
	table.insert(v17_, v428_)
	local v429_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v429_)
	local v430_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Localisation QA"
	}
	table.insert(v17_, v430_)
	local v431_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Senior Localisation QA Manager"
	}
	table.insert(v17_, v431_)
	local v432_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Valentina Mollica"
	}
	table.insert(v17_, v432_)
	local v433_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v433_)
	local v434_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Localisation QA Manager"
	}
	table.insert(v17_, v434_)
	local v435_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jouhaina Ramy"
	}
	table.insert(v17_, v435_)
	local v436_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v436_)
	local v437_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Localisation QA Project Manager"
	}
	table.insert(v17_, v437_)
	local v438_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Krzysztof Orlikowski"
	}
	table.insert(v17_, v438_)
	local v439_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v439_)
	local v440_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Localisation QA Lead"
	}
	table.insert(v17_, v440_)
	local v441_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jamie Kelly-Warwick"
	}
	table.insert(v17_, v441_)
	local v442_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v442_)
	local v443_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Senior Localisation QA Technicians"
	}
	table.insert(v17_, v443_)
	local v444_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Anthony Brian Yuen"
	}
	table.insert(v17_, v444_)
	local v445_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Charlotte Cameron"
	}
	table.insert(v17_, v445_)
	local v446_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Dennis Born"
	}
	table.insert(v17_, v446_)
	local v447_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jefta de Cock"
	}
	table.insert(v17_, v447_)
	local v448_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Keiko Naito"
	}
	table.insert(v17_, v448_)
	local v449_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Morten \195\152stergaard"
	}
	table.insert(v17_, v449_)
	local v450_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Piotr Rokitnicki"
	}
	table.insert(v17_, v450_)
	local v451_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v451_)
	local v452_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Localisation QA Technicians"
	}
	table.insert(v17_, v452_)
	local v453_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "\195\129lvaro Saavedra Jeno"
	}
	table.insert(v17_, v453_)
	local v454_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Brice Jos\195\169 Fajardo Ory"
	}
	table.insert(v17_, v454_)
	local v455_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Cristina Baleanu"
	}
	table.insert(v17_, v455_)
	local v456_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Davide Fanni"
	}
	table.insert(v17_, v456_)
	local v457_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Jaehun Bae"
	}
	table.insert(v17_, v457_)
	local v458_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Kan Cheng"
	}
	table.insert(v17_, v458_)
	local v459_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Katarzyna Maciejewska"
	}
	table.insert(v17_, v459_)
	local v460_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marcela Ostrochovska"
	}
	table.insert(v17_, v460_)
	local v461_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Marilia Stieven Sonza"
	}
	table.insert(v17_, v461_)
	local v462_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "P\195\161l Veres Kov\195\161cs"
	}
	table.insert(v17_, v462_)
	local v463_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Roksolana Krushenytska"
	}
	table.insert(v17_, v463_)
	local v464_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Stephen Bubenheim"
	}
	table.insert(v17_, v464_)
	local v465_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v465_)
	local v466_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v466_)
	local v467_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v467_)
	local v468_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2003-2024 GIANTS Software GmbH"
	}
	table.insert(v17_, v468_)
	local v469_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Farming Simulator"
	}
	table.insert(v17_, v469_)
	local v470_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "GIANTS Software and its logos are trademarks"
	}
	table.insert(v17_, v470_)
	local v471_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "or registered trademarks of GIANTS Software"
	}
	table.insert(v17_, v471_)
	local v472_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "All rights reserved."
	}
	table.insert(v17_, v472_)
	local v473_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v473_)
	local v474_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v474_)
	local v475_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "All manufacturers, vehicles, machines,"
	}
	table.insert(v17_, v475_)
	local v476_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "equipment, names, brands, and"
	}
	table.insert(v17_, v476_)
	local v477_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "associated imagery featured in this game"
	}
	table.insert(v17_, v477_)
	local v478_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "in some cases include trademarks and/or"
	}
	table.insert(v17_, v478_)
	local v479_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "copyrighted materials of their"
	}
	table.insert(v17_, v479_)
	local v480_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "respective owners. The vehicles,"
	}
	table.insert(v17_, v480_)
	local v481_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "machines, and equipment in this game"
	}
	table.insert(v17_, v481_)
	local v482_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "may be different from the actual ones"
	}
	table.insert(v17_, v482_)
	local v483_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "in shapes, colors and performance."
	}
	table.insert(v17_, v483_)
	local v484_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v484_)
	local v485_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v485_)
	local v486_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Aprilia\194\174 Official Licensee. Aprilia\194\174 is a registered"
	}
	table.insert(v17_, v486_)
	local v487_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "trademark owned by Piaggio & C. S.p.A. and"
	}
	table.insert(v17_, v487_)
	local v488_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "used under license by GIANTS Software GmbH."
	}
	table.insert(v17_, v488_)
	local v489_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v489_)
	local v490_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v490_)
	local v491_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v491_)
	local v492_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Ape\194\174 Official Licensee. Ape\194\174 is a registered"
	}
	table.insert(v17_, v492_)
	local v493_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "trademark owned by Piaggio & C. S.p.A. and"
	}
	table.insert(v17_, v493_)
	local v494_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "used under license by GIANTS Software GmbH."
	}
	table.insert(v17_, v494_)
	local v495_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v495_)
	local v496_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v496_)
	local v497_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "The VOLVO trademarks (word and device),"
	}
	table.insert(v17_, v497_)
	local v498_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "other related trademarks, if applicable, "
	}
	table.insert(v17_, v498_)
	local v499_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "and the Volvo designs are licensed by"
	}
	table.insert(v17_, v499_)
	local v500_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "the AB Volvo Group."
	}
	table.insert(v17_, v500_)
	local v501_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v501_)
	local v502_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v502_)
	if not (GS_PLATFORM_XBOX or GS_IS_MOBILE_VERSION) then
		local v503_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = g_i18n:getText("ui_copyrightSymbol") .. " 2024 Sony Interactive Entertainment LLC."
		}
		table.insert(v17_, v503_)
		local v504_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "\"PlayStation Family Mark\", \"PlayStation\","
		}
		table.insert(v17_, v504_)
		local v505_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "\"PS5 logo\", \"PS5\","
		}
		table.insert(v17_, v505_)
		local v506_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "\"PlayStation Shapes Logo\" and \"Play Has No Limits\""
		}
		table.insert(v17_, v506_)
		local v507_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "are registered trademarks or trademarks of"
		}
		table.insert(v17_, v507_)
		local v508_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "Sony Interactive Entertainment Inc."
		}
		table.insert(v17_, v508_)
		local v509_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = ""
		}
		table.insert(v17_, v509_)
	end
	local v510_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Uses Lua"
	}
	table.insert(v17_, v510_)
	local v511_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1994-2024 Lua.org, PUC-Rio"
	}
	table.insert(v17_, v511_)
	local v512_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v512_)
	local v513_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v513_)
	local v514_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Uses Luau"
	}
	table.insert(v17_, v514_)
	local v515_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2019-2024 Roblox Corporation"
	}
	table.insert(v17_, v515_)
	local v516_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v516_)
	local v517_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v517_)
	local v518_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Uses Ogg Vorbis and Theora"
	}
	table.insert(v17_, v518_)
	local v519_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1994-2024 Xiph.Org Foundation"
	}
	table.insert(v17_, v519_)
	local v520_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v520_)
	local v521_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v521_)
	if GS_PLATFORM_PC then
		local v522_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "Uses FLAC"
		}
		table.insert(v17_, v522_)
		local v523_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2000-2009, Josh Coalson"
		}
		table.insert(v17_, v523_)
		local v524_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2011-2024, Xiph.Org Foundation"
		}
		table.insert(v17_, v524_)
		local v525_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = ""
		}
		table.insert(v17_, v525_)
		local v526_ = {
			["t"] = CreditsScreen.SEPARATOR
		}
		table.insert(v17_, v526_)
	end
	local v527_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Uses Zlib"
	}
	table.insert(v17_, v527_)
	local v528_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1995-2024 Jean-loup Gailly"
	}
	table.insert(v17_, v528_)
	local v529_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "and Mark Adler"
	}
	table.insert(v17_, v529_)
	local v530_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v530_)
	local v531_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v531_)
	local v532_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "This software is based in part on"
	}
	table.insert(v17_, v532_)
	local v533_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "the work of the Independent JPEG Group"
	}
	table.insert(v17_, v533_)
	local v534_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1991-2024 Independent JPEG Group"
	}
	table.insert(v17_, v534_)
	local v535_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v535_)
	local v536_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v536_)
	local v537_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Uses Opus Interactive Audio Codec"
	}
	table.insert(v17_, v537_)
	local v538_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2001-2011 Xiph.Org, Skype Limited,"
	}
	table.insert(v17_, v538_)
	local v539_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Octasic, Jean-Marc Valin, Timothy B. Terriberry, CSIRO, Gregory Maxwell, Mark Borgerding,"
	}
	table.insert(v17_, v539_)
	local v540_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Erik de Castro Lopo"
	}
	table.insert(v17_, v540_)
	local v541_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v541_)
	local v542_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v542_)
	if GS_PLATFORM_PC and not GS_IS_MSSTORE_VERSION then
		local v543_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "Uses Curl"
		}
		table.insert(v17_, v543_)
		local v544_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1996-2024, Daniel Stenberg, daniel@haxx.se, and many contributors, see the THANKS file."
		}
		table.insert(v17_, v544_)
		local v545_ = {
			["t"] = CreditsScreen.DISCLAIMER,
			["c"] = ""
		}
		table.insert(v17_, v545_)
		local v546_ = {
			["t"] = CreditsScreen.SEPARATOR
		}
		table.insert(v17_, v546_)
	end
	local v547_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Uses VHACD"
	}
	table.insert(v17_, v547_)
	local v548_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2011, Khaled Mamou (kmamou at gmail dot com)"
	}
	table.insert(v17_, v548_)
	local v549_ = {
		["t"] = CreditsScreen.DISCLAIMER,
		["c"] = ""
	}
	table.insert(v17_, v549_)
	local v550_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v550_)
	local v551_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v551_)
	local v552_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v552_)
	local v553_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v553_)
	local v554_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v554_)
	local v555_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v555_)
	local v556_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v556_)
	local v557_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v557_)
	local v558_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = "Special Thanks to"
	}
	table.insert(v17_, v558_)
	local v559_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Martin B\195\164rwolf"
	}
	table.insert(v17_, v559_)
	local v560_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Mike Pall"
	}
	table.insert(v17_, v560_)
	local v561_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Andr\195\169s Villegas"
	}
	table.insert(v17_, v561_)
	local v562_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Brian Burgess"
	}
	table.insert(v17_, v562_)
	local v563_ = {
		["t"] = CreditsScreen.SEPARATOR
	}
	table.insert(v17_, v563_)
	local v564_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v564_)
	local v565_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v565_)
	local v566_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v566_)
	local v567_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v567_)
	local v568_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v568_)
	local v569_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v569_)
	local v570_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v570_)
	local v571_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v571_)
	local v572_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v572_)
	local v573_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v573_)
	local v574_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v574_)
	local v575_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v575_)
	local v576_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v576_)
	local v577_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v577_)
	local v578_ = {
		["t"] = CreditsScreen.TEXT,
		["c"] = "Thanks for playing!"
	}
	table.insert(v17_, v578_)
	local v579_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v579_)
	local v580_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v580_)
	local v581_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v581_)
	local v582_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v582_)
	local v583_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v583_)
	local v584_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v584_)
	local v585_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v585_)
	local v586_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v586_)
	local v587_ = {
		["t"] = CreditsScreen.TITLE,
		["c"] = ""
	}
	table.insert(v17_, v587_)
	for v588_ = #self.creditsPlaceholder.elements, 1, -1 do
		self.creditsPlaceholder.elements[v588_]:delete()
	end
	self.creditsElements = {}
	for _, v589_ in pairs(v17_) do
		self.currentCreditsText = v589_.c
		local v590_ = nil
		if v589_.t == CreditsScreen.TITLE then
			v590_ = self.creditsTitleElement:clone(self.creditsPlaceholder)
			v590_:updateSize()
			v590_:setText(v589_.c)
		elseif v589_.t == CreditsScreen.TEXT then
			v590_ = self.creditsTextElement:clone(self.creditsPlaceholder)
			v590_:setText(v589_.c)
		elseif v589_.t == CreditsScreen.DISCLAIMER then
			v590_ = self.creditsDisclaimerElement:clone(self.creditsPlaceholder)
			v590_:setText(v589_.c)
		end
		if v590_ ~= nil then
			v590_:setAlpha(0)
			local v591_ = self.creditsElements
			table.insert(v591_, v590_)
		end
	end
	local v592_ = self.creditsPlaceholder:invalidateLayout(true)
	self.creditsEndY = self.creditsPlaceholder.size[2] + v592_
end

-- Local values: filename
function CreditsScreen:updateTheme()
	local v594_ = Platform.gameLogos[g_languageShort]
	if v594_ == nil then
		v594_ = Platform.gameLogos.en
	end
	if self.logo ~= nil then
		self.logo:setImageFilename(v594_)
	end
end

function CreditsScreen:onCareerClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.careerButton)
	g_mainScreen:onCareerClick(element)
end

function CreditsScreen:onAchievementsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.achievementsButton)
	g_mainScreen:onAchievementsClick(element)
end

function CreditsScreen:onChangeMobileSettingsClick(element)
	g_mainScreen:onChangeMobileSettingsClick(element)
end
