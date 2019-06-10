local abs = abs;
local unpack = unpack;

-- Addon
local modName = ...;
local acb = CreateFrame("Frame",modName);

-- Global Chat Message Function
function AzMsg(msg) DEFAULT_CHAT_FRAME:AddMessage(tostring(msg):gsub("|1","|cffffff80"):gsub("|2","|cffffffff"),0.5,0.75,1.0); end

-- Config Data
local cfg;
local ACB_DefOptions = {
	enabled = true,
	reverseGrowth = false,
	showSpark = false,
	fadeTime = 0.6,		-- Should perhaps be removed from core option
	alpha = 1,

	showLabel = true,
	nameFontFace = "",
	nameFontFlags = "",
	nameFontSize = 12,
	nameLabelAlign = "LEFT",
	colNameLabel = { 1, 1, 1 },
	nameOffsetX = 0,
	nameOffsetY = 0,

	showTime = true,
	timeFontFace = "",
	timeFontFlags = "",
	timeFontSize = 12,
	timeLabelAlign = "RIGHT",
	colTimeLabel = { 1, 1, 1 },
	timeOffsetX = 0,
	timeOffsetY = 0,
	showTotalTime = false,

	texture = "Interface\\Addons\\AzCastBar\\Textures\\Waterline",
	horzTile = false,
	vertTile = false,
	useSameBGTexture = false,
	colBackGround = { 0.3, 0.3, 0.3, 0.6 },

	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	colBackdrop = { 0.1, 0.22, 0.35 },
	backdropIndent = -2.5,
--	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
--	colBackdropBorder = { 0.1, 0.22, 0.35 },
--	edgeSize = 12,

	strata = "MEDIUM",
	width = 250,
	height = 18,

	anchorPoint = "BOTTOM",
	anchorOffset = 6,
	iconAnchor = "LEFT",
	iconOffset = 2.5,
	hideIconBorder = true,
};
local ACB_DefaultMeta = { __index = ACB_DefOptions };

-- Work Table
local backDrop = { insets = {} };

-- Anchors
local optimalAnchor = { "ANCHOR_BOTTOMLEFT", "ANCHOR_BOTTOMRIGHT", "ANCHOR_RIGHT", "ANCHOR_LEFT" };
local mirrorAnchor = { TOP = "BOTTOM", BOTTOM = "TOP", LEFT = "RIGHT", RIGHT = "LEFT" };
local labelAlignOffset = { LEFT = 3, CENTER = 0, RIGHT = -3 };

-- StatusBarSetValue -- Somewhat hackish, but it does the job
local StatusBarSetValue = getmetatable(GameTooltipStatusBar).__index.SetValue;

-- References in main Table
acb.frames = {};
acb.mixins = {};
acb.defOptions = ACB_DefOptions;

--------------------------------------------------------------------------------------------------------
--                                     OnEvent - Variables Loaded                                     --
--------------------------------------------------------------------------------------------------------

-- Modify All CastBars to fit the Users Settings on "VARIABLES_LOADED"
local function OnEvent(self,event)
	-- cfg
	if (not AzCastBar_Config) then
		AzCastBar_Config = {};
	end
	cfg = AzCastBar_Config;
	-- default font
	local gameFont = GameFontNormal:GetFont();
	ACB_DefOptions.nameFontFace = gameFont;
	ACB_DefOptions.timeFontFace = gameFont;
	-- settings
	self.ValidateSettings();
	self.ApplyAllSettings();
	-- Backwards compatability: Add global names for all bar frames, mainly a request for people who wish to anchor panels around bars
	for _, plugin in ipairs(self.frames) do
		if (not plugin:GetName()) then
			_G["AzCastBarPlugin"..plugin.token] = plugin;
		end
	end
	-- clean
	OnEvent = nil;
	self:SetScript("OnEvent",nil);
end

acb:SetScript("OnEvent",OnEvent);
acb:RegisterEvent("VARIABLES_LOADED");

--------------------------------------------------------------------------------------------------------
--                                          Helper Functions                                          --
--------------------------------------------------------------------------------------------------------

-- Default OnEvent Script
local function Default_OnEvent(self,event,...)
	if (self[event]) then
		self[event](self,event,...);
	end
end

-- Will Reverse the StatusBar, and update the spark
local function StatusBar_ModifiedSetValue(self,value)
	local cfg = self:GetParent().cfg;
	local _, max = self:GetMinMaxValues();
	-- Value
	if (cfg.reverseGrowth) then
		value = (max - value);
	end
	StatusBarSetValue(self,value);
	-- Spark -- The weird hiding is done because we cannot rely on the value being 0 or max, due to rounding errors
	if (cfg.showSpark) then
		if (abs(value) < 0.001 or abs(max - value) < 0.001) then
			self.spark:Hide();
		else
			local pos = (value / max * self:GetWidth());
			self.spark:ClearAllPoints();
			self.spark:SetPoint("CENTER",self,"LEFT",pos,0);
			self.spark:Show();
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Apply Settings                                           --
--------------------------------------------------------------------------------------------------------

-- Checks if the settings exists and are correct
function acb:ValidateSettings()
	for _, plugin in ipairs(acb.frames) do
		if (not cfg[plugin.token]) then
			cfg[plugin.token] = {};
		end
		local barCfg = cfg[plugin.token];

		-- Get positions from current
		if (barCfg.left == nil) then
			barCfg.left = plugin:GetLeft();
		end
		if (barCfg.bottom == nil) then
			barCfg.bottom = plugin:GetBottom();
		end

		-- Initialise Any Extra Plugin Options
		if (type(plugin.options) == "table") then
			for _, categories in ipairs(plugin.options) do
				for _, option in ipairs(categories) do
					if (option.default ~= nil) and (rawget(barCfg,option.var) == nil) and (plugin:IsOptionAllowed(option)) then
						barCfg[option.var] = option.default;
					end
				end
			end
		end
	end
end

-- Apply Settings to All Bars
function acb:ApplyAllSettings()
	for _, plugin in ipairs(acb.frames) do
		plugin:ApplyBarSettings();
	end
end

--------------------------------------------------------------------------------------------------------
--                                             ACB Mixins                                             --
--------------------------------------------------------------------------------------------------------

-- Resets vars used for the bar and displays it
function acb.mixins:ResetAndShow(duration,ext)

	if (duration) then
		self.status:SetValue(0);
		self.status:SetMinMaxValues(0,duration);
		self.totalTimeText = self:FormatTotalTime(duration,ext);
		--self.duration = duration;
	end

	self.fadeTime = nil;
	self.fadeElapsed = 0;
	self:SetAlpha(self.cfg.alpha);
	self:Show();
end

-- Time Text Updater
function acb.mixins:SetTimeText(sec,ext)
	local totalText = self.cfg.showTotalTime and self.totalTimeText or "";
	if (abs(sec) <= 60) then
		self.time:SetFormattedText(ext and "%.2f%s" or "%.1f%s",sec,totalText);
	else
		self.time:SetFormattedText("%d:%.2d%s",sec / 60,abs(sec) % 60,totalText);
	end
end

-- Format time as it is shown on the CastBar, with ext set, one extra decimal point is shown
function acb.mixins:FormatTime(sec,ext)
	if (abs(sec) <= 60) then
		return (ext and "%.2f" or "%.1f"):format(sec);
	else
		return ("%d:%.2d"):format(sec / 60,abs(sec) % 60);
	end
end

-- returns the formatted total time, or nil if zero or invalid
function acb.mixins:FormatTotalTime(duration,ext)
	return (duration) and (duration > 0) and (" / "..self:FormatTime(duration,ext)) or nil;
end

-- checks if the option is allowed for this plugin token
function acb.mixins:IsOptionAllowed(option)
	local restrictType = type(option.restrict);
	return (
		(restrictType == "nil")
		or (restrictType == "string" and self.token == option.restrict)
		or (restrictType == "table" and tIndexOf(option.restrict,self.token))
	);
end

-- Apply Settings to Given Bar and all its subbars
function acb.mixins:ApplyBarSettings()
	for i = 1, (type(self.bars) == "table" and #self.bars or 1) do
		self:ApplyBarSettingsSpecific(i);
	end
	-- Call the OnConfigChanged func
	if (self.OnConfigChanged) then
		self:OnConfigChanged(self.cfg);
	end
end

-- Apply Settings to Given Bar
function acb.mixins:ApplyBarSettingsSpecific(id)
	-- This might get called before VARIABLES_LOADED, return in that case
	if (not cfg) then
		return;
	end

	-- Init Bar & Config
	local id = (id or 1);
	local bar = (id == 1 and self) or (self.bars[id]);
	local barCfg = cfg[self.token];
	bar.cfg = barCfg;

	-- Main Bar Changes Only. Set Position & Update EditMode bar if one exists
	if (bar == self) then
		setmetatable(barCfg,ACB_DefaultMeta);
		bar:ClearAllPoints();
		bar:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",barCfg.left,barCfg.bottom);
		-- Update visuals of the edit mode bar, if it exists
		if (bar.editModeBar) then
			bar.editModeBar:ApplyBarSettingsSpecific();
			bar.editModeBar.status:SetStatusBarColor(bar.status:GetStatusBarColor());
			--bar.editModeBar:SetShown(barCfg.enabled);
		end
	-- Anchor Frame - This only happens to sub bars of multi bar plugins
	else
		local point = barCfg.anchorPoint;
		local x = (point == "LEFT" and barCfg.anchorOffset * -1) or (point == "RIGHT" and barCfg.anchorOffset) or 0;
		local y = (point == "BOTTOM" and barCfg.anchorOffset * -1) or (point == "TOP" and barCfg.anchorOffset) or 0;
		bar:ClearAllPoints();
		bar:SetPoint(mirrorAnchor[point],self.bars[id - 1],point,x,y);
	end

	-- This is as a way of: "if not enabled, why waste clock cycles on applying settings?".
	if (not barCfg.enabled) then
		return;
	end

	-- Width + Height + Strata
	bar:SetSize(barCfg.width,barCfg.height);
	bar:SetFrameStrata(barCfg.strata);

	-- Icon Borders
	if (barCfg.hideIconBorder) then
		bar.icon:SetTexCoord(0.07,0.93,0.07,0.93);
	else
		bar.icon:SetTexCoord(0,1,0,1);
	end

	-- Anchor Icon & StatusBar
	bar.icon:SetSize(barCfg.height,barCfg.height);
	bar.icon:ClearAllPoints();
	if (barCfg.iconAnchor == "NONE") then
		bar.icon:Hide();
		bar.status:SetAllPoints();
	elseif (barCfg.iconAnchor == "LEFT") then
		bar.icon:Show();
		bar.icon:SetPoint("LEFT");
		bar.status:SetPoint("TOPLEFT",bar.icon,"TOPRIGHT",barCfg.iconOffset,0);
		bar.status:SetPoint("BOTTOMRIGHT");
	elseif (barCfg.iconAnchor == "RIGHT") then
		bar.icon:Show();
		bar.icon:SetPoint("RIGHT");
		bar.status:SetPoint("TOPLEFT");
		bar.status:SetPoint("BOTTOMRIGHT",bar.icon,"BOTTOMLEFT",-barCfg.iconOffset,0);
	end

	-- Anchor Labels
	bar.name:ClearAllPoints();
	bar.time:ClearAllPoints();
	bar.name:SetJustifyH(barCfg.nameLabelAlign);
	bar.time:SetJustifyH(barCfg.timeLabelAlign);
	bar.name:SetPoint(barCfg.nameLabelAlign,labelAlignOffset[barCfg.nameLabelAlign] + barCfg.nameOffsetX,barCfg.nameOffsetY);
	bar.time:SetPoint(barCfg.timeLabelAlign,labelAlignOffset[barCfg.timeLabelAlign] + barCfg.timeOffsetX,barCfg.timeOffsetY);
	if (barCfg.nameLabelAlign == "LEFT") and (barCfg.timeLabelAlign == "RIGHT") then
		bar.name:SetPoint("RIGHT",bar.time,"LEFT",-8,0);
	elseif (barCfg.nameLabelAlign == "RIGHT") and (barCfg.timeLabelAlign == "LEFT") then
		bar.name:SetPoint("LEFT",bar.time,"RIGHT",8,0);
	end

	-- Show/Hide Labels
	bar.name:SetShown(barCfg.showLabel);
	bar.time:SetShown(barCfg.showTime);

	-- Set Label Font + Color
	bar.name:SetFont(barCfg.nameFontFace,barCfg.nameFontSize,barCfg.nameFontFlags);
	bar.time:SetFont(barCfg.timeFontFace,barCfg.timeFontSize,barCfg.timeFontFlags);
	bar.name:SetTextColor(unpack(barCfg.colNameLabel));
	bar.time:SetTextColor(unpack(barCfg.colTimeLabel));

	-- Fill in  Backdrop
	backDrop.bgFile = barCfg.bgFile;
--	backDrop.edgeFile = barCfg.edgeFile;
--	backDrop.edgeSize = barCfg.edgeSize;
	backDrop.insets.left = barCfg.backdropIndent;
	backDrop.insets.right = barCfg.backdropIndent;
	backDrop.insets.top = barCfg.backdropIndent;
	backDrop.insets.bottom = barCfg.backdropIndent;

	-- Alpha + Backdrop
	bar:SetAlpha(barCfg.alpha);
	bar:SetBackdrop(backDrop);
	bar:SetBackdropColor(unpack(barCfg.colBackdrop));
--	bar:SetBackdropBorderColor(unpack(barCfg.colBackdropBorder));

	-- StatusBar Texture -- This code will check if the texture set is valid, if not, it will be defaulted to the one set in "ACB_DefOptions"
	bar.status:SetStatusBarTexture(nil);	-- You have clear the texture before setting a new, otherwise setting the tiling setting later, will not have any effect, if the texture file was not changed.
	bar.status:SetStatusBarTexture(barCfg.texture,true,true,true);
	if (not bar.status:GetStatusBarTexture()) then
		barCfg.texture = nil;
		bar.status:SetStatusBarTexture(barCfg.texture);
	end
--	bar.status:GetStatusBarTexture():SetWidth(10);
--	bar.status:GetStatusBarTexture():SetHeight(20);
	bar.status:GetStatusBarTexture():SetHorizTile(barCfg.horzTile);	-- Az: 3.3.3 fix
	bar.status:GetStatusBarTexture():SetVertTile(barCfg.vertTile);	-- Az: 3.3.3 fix

	-- Background Texture
	if (barCfg.useSameBGTexture) then
		bar.bg:SetTexture(barCfg.texture);
	else
		bar.bg:SetColorTexture(1,1,1,1);
	end
	bar.bg:SetVertexColor(unpack(barCfg.colBackGround));

	-- Spark
	if (barCfg.showSpark) then
		if (not bar.status.spark) then
			bar.status.spark = bar.status:CreateTexture(nil,"OVERLAY");
			bar.status.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
			bar.status.spark:SetWidth(20);
			bar.status.spark:SetBlendMode("ADD");
		end
		bar.status.spark:SetHeight(barCfg.height * 2.3);
	elseif (bar.status.spark) then
		bar.status.spark:Hide();
	end

	-- Use Modified SetValue Func
	bar.status.SetValue = (barCfg.reverseGrowth or barCfg.showSpark) and StatusBar_ModifiedSetValue or nil;
end

--------------------------------------------------------------------------------------------------------
--                                        Shared Core Functions                                       --
--------------------------------------------------------------------------------------------------------

-- Where to anchor the tip, so we are sure it wont block the parent frame
function acb:GetOptimalAnchor(parent)
	local x, y = (UIParent:GetWidth() / 2), (UIParent:GetHeight() / 2);
	local left, bottom = parent:GetLeft(), parent:GetBottom();
	local quadrant = (left > x and bottom > y and 1) or (left <= x and bottom > y and 2) or (left <= x and bottom <= y and 3) or (left > x and bottom <= y and 4);
	return optimalAnchor[quadrant];
end

-- Creates the Main Plugin Bar
function acb:CreateMainBar(frameType,token,options,multi)
	local f = self:CreateBar(frameType,nil,"AzCastBarPlugin"..token);
	f:SetScript("OnEvent",Default_OnEvent);
	f:SetPoint("CENTER");
	f.token = token;
	f.options = options;
	if (multi) then
		f.bars = { f };
	end
	acb.frames[#acb.frames + 1] = f;
	return f;
end

-- Creates a Bar
function acb:CreateBar(frameType,mainBar,name)
	local f = CreateFrame(frameType or "Frame",name,UIParent);
	f:SetSize(250,18);
	f:Hide();

	f.icon = f:CreateTexture(nil,"ARTWORK");

	f.status = CreateFrame("StatusBar",nil,f);

	f.name = f.status:CreateFontString(nil,"OVERLAY","GameFontHighlight");
	f.name:SetWordWrap(false);

	f.time = f.status:CreateFontString(nil,"OVERLAY","GameFontHighlight");
	f.time:SetWordWrap(false);

	f.bg = f.status:CreateTexture(nil,"BACKGROUND");
	f.bg:SetAllPoints();

	-- mixins
	Mixin(f,acb.mixins);

	if (mainBar) then
		mainBar.bars[#mainBar.bars + 1] = f;
		mainBar:ApplyBarSettingsSpecific(#mainBar.bars);
	end

	return f;
end

--------------------------------------------------------------------------------------------------------
--                                           Slash Handling                                           --
--------------------------------------------------------------------------------------------------------

_G["SLASH_"..modName.."1"] = "/acb";
SlashCmdList[modName] = function(cmd)
	-- Extract Parameters
	local param1, param2 = cmd:match("^([^%s]+)%s*(.*)$");
	param1 = (param1 and param1:lower() or cmd:lower());
	-- Options
	if (param1 == "") then
		local loaded, reason = LoadAddOn("AzCastBarOptions");
		if (loaded) then
			AzCastBarOptions:SetShown(not AzCastBarOptions:IsVisible());
		else
			AzMsg("Could not open AzCastBar Options: |1"..tostring(reason).."|r. Make sure the addon is enabled from the character selection.");
		end
	-- Wipe Config
	elseif (param1 == "wipeconfig") then
		wipe(cfg);
		acb:ValidateSettings();
		acb:ApplyAllSettings();
		AzMsg("|2"..modName..":|r All plugin settings has been wiped and reset to their default values");
	-- Invalid or No Command
	else
		UpdateAddOnMemoryUsage();
		AzMsg(format("----- |2%s|r |1%s|r ----- |1%.2f |2kb|r -----",modName,GetAddOnMetadata(modName,"Version"),GetAddOnMemoryUsage(modName)));
		AzMsg("The following |2parameters|r are valid for this addon:");
		AzMsg(" |2wipeconfig|r = Clears the configurations for all plugins, does not affect profiles");
	end
end