CaptionUtil = {}
CaptionUtil.TEXTS = {}

function CaptionUtil.addText(text)
	local v2_ = CaptionUtil.TEXTS
	table.insert(v2_, text)
	CaptionUtil.updateCaption()
	return #CaptionUtil.TEXTS
end

function CaptionUtil.setPartialText(index, text)
	if CaptionUtil.TEXTS[index] ~= nil then
		CaptionUtil.TEXTS[index] = text
	end
end
function CaptionUtil.updateCaption()
	local v5_ = CaptionUtil.getCaption()
	setCaption(v5_)
end
function CaptionUtil.getCaption()
	return table.concat(CaptionUtil.TEXTS, " ")
end
