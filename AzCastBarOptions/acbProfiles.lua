local acb = AzCastBar;
local acbo = AzCastBarOptions;
local cfg = AzCastBar_Config;

--------------------------------------------------------------------------------------------------------
--                                   Profiles: Button + Edit Scripts                                  --
--------------------------------------------------------------------------------------------------------

-- Load
local function Button_Load_OnClick(self,button)
	local p = acbo.profilesFrame;
	local left, bottom = cfg.optionsLeft, cfg.optionsBottom;
	wipe(cfg);
	cfg.optionsLeft, cfg.optionsBottom = left, bottom;
	for token, barCfg in next, AzCastBar_Profiles[p.edit:GetText()] do
		for _, plugin in ipairs(acb.frames) do
			if (token == plugin.token) then
				cfg[token] = CopyTable(barCfg);
			end
		end
	end
	acb:ValidateSettings();
	acb:ApplyAllSettings();
	acbo:BuildCategoryPage();
end

-- Save
local function Button_Save_OnClick(self,button)
	local p = acbo.profilesFrame;
	AzCastBar_Profiles[p.edit:GetText()] = CopyTable(cfg);
	p:BuildProfileList();
end

-- Delete
local function Button_Delete_OnClick(self,button)
	local p = acbo.profilesFrame;
	AzCastBar_Profiles[p.edit:GetText()] = nil;
	p:BuildProfileList();
end

-- Text Changed
local function Edit_OnTextChanged(self)
	local p = acbo.profilesFrame;
	local name = p.edit:GetText();
	-- save
	if (name == "") then
		p.btnSave:Disable();
	else
		p.btnSave:Enable();
	end
	-- load & delete
	if (AzCastBar_Profiles[name]) then
		p.btnLoad:Enable();
		p.btnDelete:Enable();
	else
		p.btnLoad:Disable();
		p.btnDelete:Disable();
	end
end

--------------------------------------------------------------------------------------------------------
--                                        Profiles: Build List                                        --
--------------------------------------------------------------------------------------------------------

-- Entry OnClick
local function Entry_OnClick(self,button)
	local p = acbo.profilesFrame;
	p.edit:SetText(p.list[self.index]);
end

-- Create Entry Button
local function CreateEntryButton(self,owner)
	local b = CreateFrame("Button",nil,owner);
	b:SetSize(owner:GetWidth() - 8,18);
	b:SetScript("OnClick",Entry_OnClick);

	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");

	b.text = b:CreateFontString(nil,"ARTWORK","GameFontNormal");
	b.text:SetPoint("LEFT",3,0);

	self.buttons[#self.buttons + 1] = b;
	return b;
end

-- Build List
local function BuildProfileList(self)
	wipe(self.list);
	for entryName in next, AzCastBar_Profiles do
		self.list[#self.list + 1] = entryName;
	end
	sort(self.list);

	self.header:SetFormattedText("Profiles (|cffffff00%d|r)",#self.list);
	self:SetHeight(max(8,#self.list) * 18 + 112);

	for i = 1, #self.list do
		local entry = self.buttons[i] or self:CreateEntryButton(self.outline);
		entry.text:SetText(self.list[i]);
		entry.index = i;
		entry:ClearAllPoints();
		if (i == 1) then
			entry:SetPoint("TOPLEFT",5,-6);
		else
			entry:SetPoint("TOPLEFT",self.buttons[i - 1],"BOTTOMLEFT");
		end
		entry:Show();
	end

	for i = (#self.list + 1), #self.buttons do
		self.buttons[i]:Hide();
	end

	Edit_OnTextChanged();
end

--------------------------------------------------------------------------------------------------------
--                                       Profiles: Create Window                                      --
--------------------------------------------------------------------------------------------------------

function acbo:CreateProfilesDialog(owner)
	owner = owner or acbo;
	local p = CreateFrame("Frame",nil,owner);

	p:SetSize(198,256);
	p:SetPoint("CENTER",UIParent);
	p:SetBackdrop(owner:GetBackdrop());
	p:SetBackdropColor(0.1,0.22,0.35,1);
	p:SetBackdropBorderColor(0.1,0.1,0.1,1);
	p:EnableMouse(true);
	p:SetMovable(true);
	p:SetToplevel(true);
	p:SetFrameStrata("DIALOG");
	p:SetFrameLevel(10);
	p:SetClampedToScreen(true);
	p:SetScript("OnMouseDown",p.StartMoving);
	p:SetScript("OnMouseUp",p.StopMovingOrSizing);
	p:Hide();

	p.header = p:CreateFontString(nil,"ARTWORK","GameFontHighlight");
	p.header:SetFont(p.header:GetFont(),22,"THICKOUTLINE");
	p.header:SetPoint("TOPLEFT",12,-12);

	p.close = CreateFrame("Button",nil,p,"UIPanelCloseButton");
	p.close:SetSize(24,24);
	p.close:SetPoint("TOPRIGHT",-5,-5);
	p.close:SetScript("OnClick",function() p:Hide(); end)

	p.outline = CreateFrame("Frame",nil,p);
	p.outline:SetHeight(158);
	p.outline:SetPoint("TOPLEFT",12,-38);
	p.outline:SetPoint("BOTTOMRIGHT",-12,62);
	p.outline:SetBackdrop(owner.outline:GetBackdrop());
	p.outline:SetBackdropColor(0.1,0.1,0.2,1);
	p.outline:SetBackdropBorderColor(0.8,0.8,0.9,0.4);

	p.edit = CreateFrame("EditBox","AzCastBarOptionsProfilesEdit",p,"InputBoxTemplate");
	p.edit:SetSize(110,21);
	p.edit:SetPoint("TOPLEFT",p.outline,"BOTTOMLEFT",7,-1);
	p.edit:SetPoint("TOPRIGHT",p.outline,"BOTTOMRIGHT",-2,-1);
	p.edit:SetScript("OnTextChanged",Edit_OnTextChanged);
	p.edit:SetAutoFocus(nil);

	p.btnLoad = CreateFrame("Button",nil,p,"UIPanelButtonTemplate");
	p.btnLoad:SetSize(56,24);
	p.btnLoad:SetPoint("BOTTOMLEFT",12,12);
	p.btnLoad:SetScript("OnClick",Button_Load_OnClick);
	p.btnLoad:SetText("Load");

	p.btnSave = CreateFrame("Button",nil,p,"UIPanelButtonTemplate");
	p.btnSave:SetSize(56,24);
	p.btnSave:SetPoint("LEFT",p.btnLoad,"RIGHT",2,0);
	p.btnSave:SetScript("OnClick",Button_Save_OnClick);
	p.btnSave:SetText("Save");

	p.btnDelete = CreateFrame("Button",nil,p,"UIPanelButtonTemplate");
	p.btnDelete:SetSize(56,24);
	p.btnDelete:SetPoint("LEFT",p.btnSave,"RIGHT",2,0);
	p.btnDelete:SetScript("OnClick",Button_Delete_OnClick);
	p.btnDelete:SetText("Delete");

	p.list = {};
	p.buttons = {};

	p.BuildProfileList = BuildProfileList;
	p.CreateEntryButton = CreateEntryButton;

	return p;
end