local modName = "AzCastBar";
local f = CreateFrame("Frame",modName.."Options",UIParent);
local acb = AzCastBar;

-- Config
AzCastBar_Profiles = {};
local cfg = AzCastBar_Config;

-- Lists
local CategoryList = {};
local ITEM_HEIGHT = 18;		-- height of plugin/category list buttons

-- DropDown Lists
local DROPDOWN_LABEL_ALIGNMENT = {
	Left = "LEFT",
	Center = "CENTER",
	Right = "RIGHT",
};
local DROPDOWN_FONT_FLAGS = {
	["|cffffa0a0None"] = "",
	["Outline"] = "OUTLINE",
	["Thick Outline"] = "THICKOUTLINE",
};

-- Options
local activePage, subPage = 1, 1;
local options = {
	{
		[0] = "General",
		{ type = "Check", var = "enabled", label = "Enable Bar Plugin", tip = "Enable or disable this bar plugin" },
		{ type = "Check", var = "reverseGrowth", label = "Reverse StatusBar Growth", tip = "Reverse Growth", y = 12 },
		{ type = "Check", var = "showSpark", label = "Show StatusBar Spark", tip = "Shows a spark on the statusbar" },
		{ type = "Slider", var = "fadeTime", label = "Fade Out Time", min = 0, max = 6, step = 0.1, y = 28 },
		{ type = "Slider", var = "alpha", label = "Alpha", min = 0, max = 1, step = 0.01 },
		{ type = "DropDown", label = "Copy Settings From", init = AzCastBarLayouts.CopyPluginSettings_Init, y = 28 },
		{ type = "DropDown", label = "Layout Template", init = AzCastBarLayouts.LayoutTemplate_Init },
	},
	{
		[0] = "Name Label",
		{ type = "Check", var = "showLabel", label = "Show Name Label", tip = "Display the name label on the bar" },
		{ type = "DropDown", var = "nameFontFace", label = "Font Face", media = "font", y = 38 },
		{ type = "DropDown", var = "nameFontFlags", label = "Font Flags", list = DROPDOWN_FONT_FLAGS },
		{ type = "Slider", var = "nameFontSize", label = "Font Size", min = 4, max = 29, step = 1 },
		{ type = "DropDown", var = "nameLabelAlign", label = "Name Label Alignment", list = DROPDOWN_LABEL_ALIGNMENT, y = 16 },
		{ type = "Color", var = "colNameLabel", label = "Name Label Color", y = 12 },
		{ type = "Slider", var = "nameOffsetX", label = "Name Label Offset X", min = -300, max = 300, step = 1 },
		{ type = "Slider", var = "nameOffsetY", label = "Name Label Offset Y", min = -300, max = 300, step = 1 },
	},
	{
		[0] = "Time Label",
		{ type = "Check", var = "showTime", label = "Show Time Label", tip = "Display the time label on the bar" },
		{ type = "Check", var = "showTotalTime", label = "Show Total Duration", tip = "Show the total time of the cast" },
		{ type = "DropDown", var = "timeFontFace", label = "Font Face", media = "font", y = 16 },
		{ type = "DropDown", var = "timeFontFlags", label = "Font Flags", list = DROPDOWN_FONT_FLAGS },
		{ type = "Slider", var = "timeFontSize", label = "Font Size", min = 4, max = 29, step = 1 },
		{ type = "DropDown", var = "timeLabelAlign", label = "Time Label Alignment", list = DROPDOWN_LABEL_ALIGNMENT, y = 16 },
		{ type = "Color", var = "colTimeLabel", label = "Time Label Color", y = 12 },
		{ type = "Slider", var = "timeOffsetX", label = "Time Label Offset X", min = -300, max = 300, step = 1 },
		{ type = "Slider", var = "timeOffsetY", label = "Time Label Offset Y", min = -300, max = 300, step = 1 },
	},
	{
		[0] = "Appearance",
		{ type = "DropDown", var = "texture", label = "Bar Texture", media = "statusbar" },
		{ type = "Check", var = "horzTile", label = "Tile Texture Horizontally" },
		{ type = "Check", var = "vertTile", label = "Tile Texture Vertically" },
		{ type = "Check", var = "useSameBGTexture", label = "Use Bar Texture as Background Texture", tip = "Enable this to have the background use the same texture as the bar. If disabled, a plain white texture is used instead", y = 8 },
		{ type = "Color", var = "colBackGround", label = "Background Color", y = 8 },
		{ type = "DropDown", var = "bgFile", label = "Backdrop Background", media = "background", y = 16 },
		{ type = "Color", var = "colBackdrop", label = "Backdrop Color" },
		{ type = "Slider", var = "backdropIndent", label = "Backdrop Indent", min = -20, max = 60, step = 0.5, y = 35 },
	},
--	{
--		[0] = "Backdrop",
--		{ type = "DropDown", var = "edgeFile", label = "Backdrop Border", media = "border", y = 8 },
--		{ type = "Color", var = "colBackdropBorder", label = "Backdrop Border Color" },
--		{ type = "Slider", var = "edgeSize", label = "Backdrop Edge Size", min = 0, max = 60, step = 0.5 },
--	},
	{
		[0] = "Position",
		{ type = "DropDown", var = "strata", label = "Frame Strata", list = { Low = "LOW", Medium = "MEDIUM", High = "HIGH" } },
		{ type = "Slider", var = "left", label = "Left Offset", min = 0, max = 2048, step = 1, y = 12 },
		{ type = "Slider", var = "bottom", label = "Bottom Offset", min = 0, max = 1536, step = 1 },
		{ type = "Slider", var = "width", label = "Width", min = 1, max = 2048, step = 1, y = 16 },
		{ type = "Slider", var = "height", label = "Height", min = 1, max = 120, step = 1 },
	},
	{
		[0] = "Anchors",
		{ type = "DropDown", var = "anchorPoint", label = "Anchor Direction", list = { Upwards = "TOP", Downwards = "BOTTOM", Left = "LEFT", Right = "RIGHT" } },
		{ type = "Slider", var = "anchorOffset", label = "Anchor Offset", min = -40, max = 40, step = 1 },
		{ type = "DropDown", var = "iconAnchor", label = "Icon Anchor", list = { Left = "LEFT", Right = "RIGHT", ["|cffffa0a0None"] = "NONE" }, y = 34 },
		{ type = "Slider", var = "iconOffset", label = "Icon Offset", min = 0, max = 20, step = 0.5 },
		{ type = "Check", var = "hideIconBorder", label = "Hide Icon Border", tip = "Do not display the border around spell icons" },
	},
};

--------------------------------------------------------------------------------------------------------
--                                          LSM Registration                                          --
--------------------------------------------------------------------------------------------------------

do
	local acbStatusbarTextures = {
		["HorizontalFade"] = "Interface\\Addons\\AzCastBar\\Textures\\HorizontalFade",
		["Pale"] = "Interface\\Addons\\AzCastBar\\Textures\\Pale",
		["Lines"] = "Interface\\Addons\\AzCastBar\\Textures\\Lines",
		["SmoothBar"] = "Interface\\Addons\\AzCastBar\\Textures\\SmoothBar",
		["Streamline"] = "Interface\\Addons\\AzCastBar\\Textures\\Streamline",
		["Streamline-Inverted"] = "Interface\\Addons\\AzCastBar\\Textures\\Streamline-Inverted",
		["Waterline"] = "Interface\\Addons\\AzCastBar\\Textures\\Waterline",
	}

	local LSM = LibStub and LibStub("LibSharedMedia-3.0",1);
	if (LSM) then
		for name, path in next, acbStatusbarTextures do
			LSM:Register("statusbar",name,path);
		end
	else
		local lsmSubst = AzOptionsFactory.LibSharedMediaSubstitute;
		if (lsmSubst) then
			local statusbar = lsmSubst.statusbar;
			if (statusbar) then
				for name, path in next, acbStatusbarTextures do
					statusbar[name] = path;
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                        Options Category List                                       --
--------------------------------------------------------------------------------------------------------

-- Builds the Category List from Core and Plugin options
local function BuildSubCategoryList()
	wipe(CategoryList);
	for index, tbl in ipairs(options) do
		CategoryList[#CategoryList + 1] = { name = tbl[0], options = tbl, index = index };
	end
	if (type(acb.frames[activePage].options) == "table") then
		for index, tbl in ipairs(acb.frames[activePage].options) do
			CategoryList[#CategoryList + 1] = { name = tbl[0], options = tbl, index = index, custom = 1 };
		end
	end
	if (subPage > #CategoryList) then
		subPage = 1;
	end
end

-- Update Plugins
local function UpdatePluginList()
	FauxScrollFrame_Update(AzCastBarPluginsScroll,#acb.frames,#f.plugins,ITEM_HEIGHT);
	local width = (f.outline:GetWidth() - (#acb.frames > #f.plugins and 26 or 11));
	local index = f.scroll.offset;
	for i = 1, #f.plugins do
		index = (index + 1);
		local button = f.plugins[i];
		local plugin = acb.frames[index];
		if (plugin) then
			button.text:SetText(plugin.token);
			button.index = index;
			if (index == activePage) then
				button:LockHighlight();
				button.text:SetTextColor(1,1,1);
			else
				button:UnlockHighlight();
				button.text:SetTextColor(1,0.82,0);
			end
			button:SetWidth(width);
			button:Show();
		else
			button:Hide();
		end
	end
end

-- Update Option List
local function UpdateCategoryList()
	FauxScrollFrame_Update(AzCastBarCategoryScroll,#CategoryList,#f.categories,ITEM_HEIGHT);
	local width = (f.outline2:GetWidth() - (#CategoryList > #f.categories and 26 or 11));
	local index = f.scroll2.offset;
	for i = 1, #f.categories do
		index = (index + 1);
		local button = f.categories[i];
		local cat = CategoryList[index];
		if (cat) then
			button.text:SetText((cat.custom and "|cff00ff00*|r " or "")..cat.name);
			button.index = index;
			if (index == subPage) then
				button:LockHighlight();
				button.text:SetTextColor(1,1,1);
			else
				button:UnlockHighlight();
				button.text:SetTextColor(1,0.82,0);
			end
			button:SetWidth(width);
			button:Show();
		else
			button:Hide();
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                          Initialize Frame                                          --
--------------------------------------------------------------------------------------------------------

f:SetSize(460,416);
f:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 3, right = 3, top = 3, bottom = 3 } });
f:SetBackdropColor(0.1,0.22,0.35,1);
f:SetBackdropBorderColor(0.1,0.1,0.1,1);
f:EnableMouse(true);
f:SetMovable(true);
f:SetToplevel(true);
f:SetFrameStrata("DIALOG");
f:SetClampedToScreen(true);
f:SetScript("OnShow",function() if (#acb.frames > 0) then UpdatePluginList(); BuildSubCategoryList(); UpdateCategoryList(); f:BuildCategoryPage(); f:SetScript("OnShow",nil); end end);
f:Hide();

f.outline = CreateFrame("Frame",nil,f);
f.outline:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } });
f.outline:SetBackdropColor(0.1,0.1,0.2,1);
f.outline:SetBackdropBorderColor(0.8,0.8,0.9,0.4);
f.outline:SetPoint("TOPLEFT",12,-12);
f.outline:SetWidth(120);

f.outline2 = CreateFrame("Frame",nil,f);
f.outline2:SetBackdrop(f.outline:GetBackdrop());
f.outline2:SetBackdropColor(0.1,0.1,0.2,1);
f.outline2:SetBackdropBorderColor(0.8,0.8,0.9,0.4);
f.outline2:SetPoint("TOPLEFT",f.outline,"BOTTOMLEFT",0,-8);
f.outline2:SetPoint("BOTTOMLEFT",12,12);
f.outline2:SetWidth(120);

f:SetScript("OnMouseDown",f.StartMoving);
f:SetScript("OnMouseUp",function(self) self:StopMovingOrSizing(); cfg.optionsLeft = self:GetLeft(); cfg.optionsBottom = self:GetBottom(); end);

if (cfg.optionsLeft) and (cfg.optionsBottom) then
	f:SetPoint("BOTTOMLEFT",cfg.optionsLeft,cfg.optionsBottom);
else
	f:SetPoint("CENTER");
end

f.header = f:CreateFontString(nil,"ARTWORK","GameFontHighlight");
f.header:SetFont(GameFontNormal:GetFont(),22,"THICKOUTLINE");
f.header:SetPoint("TOPLEFT",f.outline,"TOPRIGHT",10,-4);
f.header:SetText(modName.." Options");

f.vers = f:CreateFontString(nil,"ARTWORK","GameFontNormal");
f.vers:SetPoint("TOPRIGHT",-20,-20);
f.vers:SetText(GetAddOnMetadata(modName,"Version"));
f.vers:SetTextColor(1,1,0.5);

local function Reset_OnClick()
	for index, option in ipairs(CategoryList[subPage].options) do
		if (option.var) then
			cfg[f.activeBar.token][option.var] = nil;
		end
	end
	acb:ValidateSettings();
	f.activeBar:ApplyBarSettings();
	f:BuildCategoryPage();
end

local function Profiles_OnClick()
	if (not f.profilesFrame) then
		f.profilesFrame = f:CreateProfilesDialog(f);
	end
	f.profilesFrame:SetShown(not f.profilesFrame:IsShown());
	if (f.profilesFrame:IsShown()) then
		f.profilesFrame:BuildProfileList();
	end
end

f.btnClose = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnClose:SetSize(68,24);
f.btnClose:SetPoint("BOTTOMRIGHT",-15,15);
--f.btnClose:SetScript("OnClick",function() f:Hide(); f.profilesFrame:Hide(); end);
f.btnClose:SetScript("OnClick",function() f:Hide(); end);
f.btnClose:SetText("Close");

f.btnReset = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnReset:SetSize(68,24);
f.btnReset:SetPoint("RIGHT",f.btnClose,"LEFT",-4,0);
f.btnReset:SetScript("OnClick",Reset_OnClick);
f.btnReset:SetText("Reset");

f.btnProfiles = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnProfiles:SetSize(68,24);
f.btnProfiles:SetPoint("RIGHT",f.btnReset,"LEFT",-4,0);
f.btnProfiles:SetScript("OnClick",Profiles_OnClick);
f.btnProfiles:SetText("Profiles");

UISpecialFrames[#UISpecialFrames + 1] = f:GetName();
f.activeBar = acb.frames[activePage];

--------------------------------------------------------------------------------------------------------
--                                      Plugin & Category Entries                                     --
--------------------------------------------------------------------------------------------------------

-- OnClicks
local function PluginButton_OnClick(self,button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);	-- "igMainMenuOptionCheckBoxOn"

	activePage = self.index;
	f.activeBar = acb.frames[activePage];

    BuildSubCategoryList();
	UpdatePluginList();
	UpdateCategoryList();
	f:BuildCategoryPage();
end

local function CategoryButton_OnClick(self,button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);	-- "igMainMenuOptionCheckBoxOn"
	subPage = self.index;
	UpdateCategoryList();
	f:BuildCategoryPage();
end

-- Plugins
f.plugins = {};
for i = 1, 12 do
	local b = CreateFrame("Button",nil,f.outline);
	b:SetHeight(ITEM_HEIGHT);
	b:SetScript("OnClick",PluginButton_OnClick);
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
	b:GetHighlightTexture():SetAlpha(0.7);

	b.text = b:CreateFontString(nil,"ARTWORK","GameFontNormal");
	b.text:SetPoint("LEFT",3,0);

	if (i == 1) then
		b:SetPoint("TOPLEFT",5,-6);
	else
		b:SetPoint("TOPLEFT",f.plugins[i - 1],"BOTTOMLEFT");
	end

	f.plugins[i] = b;
end

f.scroll = CreateFrame("ScrollFrame","AzCastBarPluginsScroll",f.outline,"FauxScrollFrameTemplate");
f.scroll:SetPoint("TOPLEFT",f.plugins[1]);
f.scroll:SetPoint("BOTTOMRIGHT",f.plugins[#f.plugins],-6,-1);
f.scroll:SetScript("OnVerticalScroll",function(self,offset) FauxScrollFrame_OnVerticalScroll(self,offset,ITEM_HEIGHT,UpdatePluginList) end);

f.outline:SetHeight(#f.plugins * ITEM_HEIGHT + 12);

-- Categories
f.categories = {};
for i = 1, 8 do
	local b = CreateFrame("Button",nil,f.outline2);
	b:SetHeight(ITEM_HEIGHT);
	b:SetScript("OnClick",CategoryButton_OnClick);
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
	b:GetHighlightTexture():SetAlpha(0.7);

	b.text = b:CreateFontString(nil,"ARTWORK","GameFontNormal");
	b.text:SetPoint("LEFT",3,0);
	b.text:SetTextColor(0.45,0.83,0.67);

	if (i == 1) then
		b:SetPoint("TOPLEFT",5,-6);
	else
		b:SetPoint("TOPLEFT",f.categories[i - 1],"BOTTOMLEFT");
	end

	f.categories[i] = b;
end

f.scroll2 = CreateFrame("ScrollFrame","AzCastBarCategoryScroll",f.outline2,"FauxScrollFrameTemplate");
f.scroll2:SetPoint("TOPLEFT",f.categories[1]);
f.scroll2:SetPoint("BOTTOMRIGHT",f.categories[#f.categories],-6,-1);
f.scroll2:SetScript("OnVerticalScroll",function(self,offset) FauxScrollFrame_OnVerticalScroll(self,offset,ITEM_HEIGHT,UpdateCategoryList) end);

--------------------------------------------------------------------------------------------------------
--                                              Edit Mode                                             --
--------------------------------------------------------------------------------------------------------

-- EditModeBar: OnUpdate
local function EditModeBar_OnUpdate(self,elapsed)
	local time = (GetTime() % self.duration);
	self.status:SetValue(time);
	self:SetTimeText(time);
end

-- Stop Moving a Bar
local function EditModeBar_OnMouseUp(self,button)
	if (button == "RightButton") then
		self:ClearAllPoints();
		self:SetPoint("CENTER");
	end
	self:StopMovingOrSizing();
	-- Save New Position & Set The Real Bars Position
	self.cfg.left = self:GetLeft();
	self.cfg.bottom = self:GetBottom();
	self.realFrame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",self:GetLeft(),self:GetBottom());
	-- Reflect Change in Options if Visible
	if (f:IsVisible()) and (self.cfg == f.activeBar.cfg) then
		f:BuildCategoryPage();
	end
end

-- Create EditMode Bars
local function CreateEditModeBar(frame)
	local b = acb:CreateBar("Button");
	b.token = frame.token;
	b.realFrame = frame;

	b:EnableMouse(true);
	b:SetMovable(true);
	b:SetToplevel(true);
	b:SetFrameStrata("DIALOG");

	b.name:SetText(frame.token);
	b.icon:SetTexture("Interface\\Icons\\Spell_Nature_UnrelentingStorm");

	b:SetScript("OnUpdate",EditModeBar_OnUpdate);
	b:SetScript("OnMouseUp",EditModeBar_OnMouseUp);
	b:SetScript("OnMouseDown",b.StartMoving);

	b.duration = 2.36;

	return b;
end

-- Toggle EditMode
local function EditMode_OnClick(self,button)
	local editMode = self:GetChecked();
	for index, frame in ipairs(acb.frames) do
		if (editMode) and (frame.cfg.enabled) then
			if (not frame.editModeBar) then
				frame.editModeBar = CreateEditModeBar(frame);
			end
			frame.editModeBar:ApplyBarSettingsSpecific();
			frame.editModeBar.status:SetStatusBarColor(frame.status:GetStatusBarColor());
			frame.editModeBar:ResetAndShow(frame.editModeBar.duration,1);
		elseif (frame.editModeBar) then
			frame.editModeBar:Hide();
		end
	end
end

-- Edit Mode CheckButton
f.editMode = CreateFrame("CheckButton",nil,f,"OptionsSmallCheckButtonTemplate");
f.editMode:SetSize(26,26);
f.editMode:SetScript("OnEnter",nil);
f.editMode:SetScript("OnLeave",nil);
f.editMode:SetScript("OnClick",EditMode_OnClick);
f.editMode:SetPoint("BOTTOMLEFT",f.outline2,"BOTTOMRIGHT",8,2);
f.editMode.text = select(6,f.editMode:GetRegions());
f.editMode.text:SetText("Edit Mode");

--------------------------------------------------------------------------------------------------------
--                                        Build Option Objects                                        --
--------------------------------------------------------------------------------------------------------

-- Get Setting Func
local function GetConfigValue(self,var)
	return cfg[f.activeBar.token][var];
end

-- Set Setting Func
local function SetConfigValue(self,var,value)
	if (not self.isBuildingOptions) then
		cfg[f.activeBar.token][var] = value;
		f.activeBar:ApplyBarSettings();
		-- Update EditMode bars if enabled status was toggled
		if (var == "enabled") and (f.editMode:GetChecked()) then
			EditMode_OnClick(f.editMode);
		end
	end
end

-- create new factory instance
local factory = AzOptionsFactory:New(f,GetConfigValue,SetConfigValue);

-- Build Page
function f:BuildCategoryPage()
	factory:BuildOptionsPage(CategoryList[subPage].options,f.outline,f.outline:GetWidth(),38,f.activeBar.token);
end