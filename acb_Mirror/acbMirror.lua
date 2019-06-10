local GetMirrorTimerProgress = GetMirrorTimerProgress;

-- Icons
local MirrorTimerIcons = {
	[0] = "Interface\\Icons\\Spell_Shadow_SoulLeech_2",
	BREATH = "Interface\\Icons\\Spell_Shadow_DemonBreath",
	FEIGNDEATH = "Interface\\Icons\\Ability_Rogue_FeignDeath",
};

-- Extra Options
local extraOptions = {
	{
		[0] = "Colors",
		{ type = "Color", var = "colNormal", default = { 0.4, 0.6, 0.8 }, label = "Mirror Bar Color" },
	},
};

-- Plugin
local plugin = AzCastBar:CreateMainBar("Frame","Mirror",extraOptions,true);

--------------------------------------------------------------------------------------------------------
--                                           Frame Scripts                                            --
--------------------------------------------------------------------------------------------------------

local function OnUpdate(self,elapsed)
	-- Progression
	if (not self.fadeTime) then
		self.timeLeft = (GetMirrorTimerProgress(self.ident) / 1000);
		self.timeLeft = (self.timeLeft < 0 and 0) or (self.timeLeft < self.duration and self.timeLeft) or (self.duration);
		self.status:SetValue(self.timeLeft);
		self:SetTimeText(self.timeLeft);
	-- FadeOut
	elseif (self.fadeElapsed < self.fadeTime) then
		self.fadeElapsed = (self.fadeElapsed + elapsed);
		self:SetAlpha(self.cfg.alpha - self.fadeElapsed / self.fadeTime * self.cfg.alpha);
	else
		self.ident = nil;
		self:Hide();
	end
end

-- Entering World
function plugin:PLAYER_ENTERING_WORLD(event)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local ident, value, maxvalue, step, pause, label = GetMirrorTimerInfo(i);
		if (ident and ident ~= "UNKNOWN") then
			self:ShowTimer(ident,label,maxvalue / 1000);
		end
	end
end

-- Timer Start
function plugin:MIRROR_TIMER_START(event,ident,value,maxvalue,step,pause,label)
	self:ShowTimer(ident,label,maxvalue / 1000);
end

-- Timer Stop
function plugin:MIRROR_TIMER_STOP(event,ident)
	for index, bar in ipairs(self.bars) do
		if (bar.ident == ident) then
			bar.fadeTime = self.cfg.fadeTime;
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                                Code                                                --
--------------------------------------------------------------------------------------------------------

-- ConfigureBar
function plugin:ConfigureBar(bar)
	bar = (bar or self);
	bar:SetScript("OnUpdate",OnUpdate);
	return bar;
end

-- returns a bar, 1) reusing one with the same ident, 2) a bar not in use, 3) or creating a new one
-- Use first free bar, but keep a lookout for one with our ident
function plugin:FindBar(ident)
	local freeBar;
	for index, bar in ipairs(self.bars) do
		if (ident == bar.ident) then
			return bar;
		elseif (not freeBar) and (not bar.ident) then
			freeBar = bar;
		end
	end
	return freeBar or self:ConfigureBar(AzCastBar:CreateBar("Frame",self));
end

-- Show Timer
function plugin:ShowTimer(ident,label,duration)
	local bar = self:FindBar(ident);
	-- Init Bar
	bar.ident = ident;
	bar.duration = duration;

	bar.name:SetText(label);
	bar.icon:SetTexture(MirrorTimerIcons[ident] or MirrorTimerIcons[0]);

	bar.status:SetStatusBarColor(unpack(self.cfg.colNormal));

	bar:ResetAndShow(duration);
end

-- Config Changed
function plugin:OnConfigChanged(cfg)
	-- Our Mirror
	if (cfg.enabled) then
		self:RegisterEvent("MIRROR_TIMER_START");
		self:RegisterEvent("MIRROR_TIMER_STOP");
		self:RegisterEvent("PLAYER_ENTERING_WORLD");
		self:PLAYER_ENTERING_WORLD();
	else
		self:UnregisterAllEvents();
		for index, bar in ipairs(self.bars) do
			bar.fadeTime = self.cfg.fadeTime;
		end
	end
	-- Blizz Mirror
	if (cfg.enabled) then
		UIParent:UnregisterEvent("MIRROR_TIMER_START");
		for i = 1, MIRRORTIMER_NUMTIMERS do
			_G["MirrorTimer"..i]:UnregisterAllEvents();
			_G["MirrorTimer"..i]:Hide();
		end
	else
		UIParent:RegisterEvent("MIRROR_TIMER_START");
		for i = 1, MIRRORTIMER_NUMTIMERS do
			local bar = _G["MirrorTimer"..i];
			bar:RegisterEvent("MIRROR_TIMER_STOP");
			bar:RegisterEvent("MIRROR_TIMER_PAUSE");
			bar:RegisterEvent("PLAYER_ENTERING_WORLD");
			if (bar:GetScript("OnEvent")) then
				bar:GetScript("OnEvent")(bar,"PLAYER_ENTERING_WORLD");
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                          Initialise Plugin                                         --
--------------------------------------------------------------------------------------------------------

plugin:ConfigureBar();