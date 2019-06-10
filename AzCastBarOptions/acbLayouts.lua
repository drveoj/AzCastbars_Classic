AzCastBarLayouts = {};
local cfg = AzCastBar_Config;

--------------------------------------------------------------------------------------------------------
--                                            List Plugins                                            --
--------------------------------------------------------------------------------------------------------

local function CopyPluginSettings_SelectValue(dropDown,entry,index)
	local cfgTo = cfg[AzCastBarOptions.activeBar.token];
	local cfgFrom = entry.value;
	-- using rawget here makes sure it goes default if the bar we copy from doesn't have this option set
	for option, value in next, AzCastBar.defOptions do
		cfgTo[option] = rawget(cfgFrom,option);
	end
	AzCastBarOptions.activeBar:ApplyBarSettings();
	dropDown:SetText("|cff80ff80Settings Copied");
end

function AzCastBarLayouts.CopyPluginSettings_Init(dropDown,list)
	dropDown.selectValueFunc = CopyPluginSettings_SelectValue;
	for index, plugin in ipairs(AzCastBar.frames) do
		if (plugin ~= AzCastBarOptions.activeBar) then
			local tbl = list[#list + 1];
			tbl.text = plugin.token; tbl.value = plugin.cfg; tbl.checked = false;
		end
	end
	dropDown:SetText("|cff00ff00Select Plugin...");
end

--------------------------------------------------------------------------------------------------------
--                                            List Layouts                                            --
--------------------------------------------------------------------------------------------------------

local layouts = {
	["|cff80ff80Default"] = {
		enabled = true,
		reverseGrowth = false,
		showSpark = false,
		fadeTime = 0.6,
		alpha = 1,

		showLabel = true,
		nameFontFace = GameFontNormal:GetFont(),
		nameFontFlags = "",
		nameFontSize = 12,
		nameLabelAlign = "LEFT",
		colNameLabel = { 1, 1, 1 },
		nameOffsetX = 0,
		nameOffsetY = 0,

		showTime = true,
		timeFontFace = GameFontNormal:GetFont(),
		timeFontFlags = "",
		timeFontSize = 12,
		timeLabelAlign = "RIGHT",
		colTimeLabel = { 1, 1, 1 },
		timeOffsetX = 0,
		timeOffsetY = 0,
		showTotalTime = false,

		texture = "Interface\\Addons\\AzCastBar\\Textures\\Waterline",
		useSameBGTexture = false,
		colBackGround = { 0.3, 0.3, 0.3, 0.6 },
		colBackdrop = { 0.1, 0.22, 0.35 },
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		backdropIndent = -2.5,

		strata = "MEDIUM",
		width = 250,
		height = 18,

		anchorPoint = "BOTTOM",
		anchorOffset = 6,
		iconAnchor = "LEFT",
		iconOffset = 2.5,
		hideIconBorder = true,
	},
	["Dark Background"] = {
		colBackGround = { 0.3, 0.3, 0.3, 0.5 },
		bgFile = "Interface\\Buttons\\WHITE8X8",
		colBackdrop = { 0, 0, 0, 0.9 },
	},
	["Aura Bars"] = {
		backdropIndent = 0,

		nameFontSize = 10,
		timeFontSize = 10,

		width = 200,
		height = 16,

		anchorPoint = "BOTTOM",
		anchorOffset = 0,
		iconAnchor = "LEFT",
		iconOffset = 0,
		hideIconBorder = true,
	},
	["Aura Icons"] = {
		showLabel = false,
		showTime = true,
		timeLabelAlign = "CENTER",
		colTimeLabel = { 1, 0.82, 0 },
		timeOffsetX = -16,
		timeOffsetY = -22,

		width = 32,
		height = 32,

		colBackdrop = { 0, 0, 0, 0 },

		anchorPoint = "LEFT",
		anchorOffset = 4,
		iconAnchor = "LEFT",
		iconOffset = 0,
		hideIconBorder = false,
	},
};

local function LayoutTemplate_SelectValue(dropDown,entry,index)
	local barCfg = cfg[AzCastBarOptions.activeBar.token];
	for option, value in next, layouts[entry.value] do
		barCfg[option] = value;
	end
	AzCastBarOptions.activeBar:ApplyBarSettings();
	dropDown:SetText("|cff80ff80Layout Loaded");
end

function AzCastBarLayouts.LayoutTemplate_Init(dropDown,list)
	dropDown.selectValueFunc = LayoutTemplate_SelectValue;
	for layoutName in next, layouts do
		local tbl = list[#list + 1];
		tbl.text = layoutName; tbl.value = layoutName; tbl.checked = false;
	end
	dropDown:SetText("|cff00ff00Pick Layout...");
end