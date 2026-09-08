-- Local values: IndexableElementMixin_mt
IndexChangeSubjectMixin = {}
local IndexableElementMixin_mt = Class(IndexChangeSubjectMixin, GuiMixin)
function IndexChangeSubjectMixin.new()
	-- upvalues: (copy) IndexableElementMixin_mt
	local v2_ = GuiMixin.new(IndexableElementMixin_mt, IndexChangeSubjectMixin)
	v2_.callbacks = {}
	return v2_
end

function IndexChangeSubjectMixin:addTo(guiElement)
	if not IndexChangeSubjectMixin:superClass().addTo(self, guiElement) then
		return false
	end
	guiElement.addIndexChangeObserver = IndexChangeSubjectMixin.addIndexChangeObserver
	guiElement.notifyIndexChange = IndexChangeSubjectMixin.notifyIndexChange
	return true
end

function IndexChangeSubjectMixin.addIndexChangeObserver(guiElement, observer, indexChangeCallback)
	guiElement[IndexChangeSubjectMixin].callbacks[observer] = indexChangeCallback
end

-- Local values: callbacks, observer, callback
function IndexChangeSubjectMixin.notifyIndexChange(guiElement, index, count)
	local v11_ = guiElement[IndexChangeSubjectMixin].callbacks
	for v12_, v13_ in pairs(v11_) do
		v13_(v12_, index, count)
	end
end

function IndexChangeSubjectMixin:clone(srcGuiElement, dstGuiElement)
	if srcGuiElement[IndexChangeSubjectMixin].callbacks ~= nil then
		dstGuiElement[IndexChangeSubjectMixin].callbacks = table.clone(srcGuiElement[IndexChangeSubjectMixin].callbacks)
	end
end
