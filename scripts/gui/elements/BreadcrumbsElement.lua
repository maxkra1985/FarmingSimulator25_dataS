-- Local values: BreadcrumbsElement_mt
BreadcrumbsElement = {}
local BreadcrumbsElement_mt = Class(BreadcrumbsElement, BoxLayoutElement)
Gui.registerGuiElement("Breadcrumbs", BreadcrumbsElement)

-- Upvalues: BreadcrumbsElement_mt
-- Local values: self
function BreadcrumbsElement.new(target, custom_mt)
	-- upvalues: (copy) BreadcrumbsElement_mt
	local v4_ = BoxLayoutElement.new(target, custom_mt or BreadcrumbsElement_mt)
	v4_.crumbs = {}
	return v4_
end

function BreadcrumbsElement:copyAttributes(src)
	BreadcrumbsElement:superClass().copyAttributes(self, src)
	self.textTemplate = src.textTemplate
	self.arrowTemplate = src.arrowTemplate
	self.ownsTemplates = false
end

function BreadcrumbsElement:onGuiSetupFinished()
	BreadcrumbsElement:superClass().onGuiSetupFinished(self)
	if self.textTemplate == nil or self.arrowTemplate == nil then
		self.ownsTemplates = true
		self.textTemplate = self:getFirstDescendant(function(p8_)
			return p8_:isa(TextBackdropElement)
		end)
		if self.textTemplate ~= nil then
			self.textTemplate:unlinkElement()
		end
		self.arrowTemplate = self:getFirstDescendant(function(p9_)
			return p9_:isa(BitmapElement)
		end)
		if self.arrowTemplate ~= nil then
			self.arrowTemplate:unlinkElement()
		end
	end
end

function BreadcrumbsElement:delete()
	if self.ownsTemplates then
		if self.textTemplate ~= nil then
			self.textTemplate:delete()
		end
		if self.arrowTemplate ~= nil then
			self.arrowTemplate:delete()
		end
	end
	BreadcrumbsElement:superClass().delete(self)
end

function BreadcrumbsElement:setBreadcrumbs(crumbs)
	self.crumbs = crumbs
	self:updateElements()
end

-- Local values: numItems, _, numCrumbs, index, crumb, profile, arrowProfile, backdrop, arrow
function BreadcrumbsElement:updateElements()
	for _ = 1, #self.elements do
		self.elements[1]:delete()
	end
	local v14_ = #self.crumbs
	for v15_ = 1, v14_ do
		local v16_ = self.crumbs[v15_]
		local v17_, v18_
		if v15_ == v14_ then
			v17_ = "shopItemsNavItemTextBackdropActive"
			v18_ = "shopItemsNavArrow"
		elseif v15_ == v14_ - 1 then
			v17_ = "shopItemsNavItemTextBackdrop"
			v18_ = "shopItemsNavFilledArrowActive"
		else
			v17_ = "shopItemsNavItemTextBackdrop"
			v18_ = "shopItemsNavFilledArrow"
		end
		local v19_ = self.textTemplate:clone(self)
		v19_:applyProfile(v17_)
		v19_.textElement:setText(v16_)
		self.arrowTemplate:clone(self):applyProfile(v18_)
	end
	self:invalidateLayout()
end
