local min = min;
local unpack = unpack;
local GetTime = GetTime;
local GetNetStats = GetNetStats;
local UnitCastingInfo = _G.UnitCastingInfo or _G.CastingInfo;
local UnitChannelInfo = _G.UnitChannelInfo or _G.ChannelInfo;

local LibCTC = LibStub("LibClassicTargetCast-1.0")

-- Extra Options
local extraOptions = {
    {
        [0] = "Additional",
        { type = "Check", var = "showRank", default = false, label = "Show Spell Rank", tip = "If the spell being cast has a rank, it will be shown in brackets after the spell name." },
        { type = "Color", var = "colNormal", default = { 0.4, 0.6, 0.8 }, label = "Normal Cast Color", y = 16 },
        { type = "Color", var = "colFailed", default = { 1.0, 0.5, 0.5 }, label = "Failed Cast Bar Color" },
        { type = "Color", var = "colInterrupt", default = { 1.0, 0.75, 0.5 }, label = "Interrupted Cast Bar Color" },
        { type = "Color", var = "colNonInterruptable", default = { 0.78, 0.82, 0.86 }, label = "Uninterruptable Cast Bar Color" },  -- Az: yes, this var is misspelled :S
    },
};

local registered_callbacks = {
    "PLAYER_ENTERING_WORLD",
    "PLAYER_TARGET_CHANGED",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
};

-- Spell Names for Hearthstone & Astral Recall
local astral = GetSpellInfo(556);
local hearth = GetSpellInfo(8690);


local bar = AzCastBar:CreateMainBar("Frame","Classic Target",extraOptions);
bar.unit = "target";
-- Anchor
--------------------------------------------------------------------------------------------------------
--                                              OnUpdate                                              --
--------------------------------------------------------------------------------------------------------

function OnUpdate(self,elapsed)
    -- Progress -- Back in WoW 2.x only the player unit gave the UNIT_SPELLCAST_STOP event, so we had to force fadeout here when casts completes, now we just rely on the event
    if (not self.fadeTime) then
        local timeNow = GetTime()/1000

        
        self.timeProgress = (timeNow - self.startTime) *1000

        if self.timeProgress < self.castTime then 
            self.timeLeft = (self.castTime - self.timeProgress);
            self.status:SetValue(self.isCast and self.timeProgress or self.timeLeft);
            self.time:SetFormattedText("%s%s%s",self.delayText,self:FormatTime(self.timeLeft),self.cfg.showTotalTime and self.totalTimeText or "");
        else
            self:StartFadeOut()
        end
    -- FadeOut
    elseif (self.fadeElapsed <= self.fadeTime) then
        self.fadeElapsed = (self.fadeElapsed + elapsed);
        self:SetAlpha(self.cfg.alpha - self.fadeElapsed / self.fadeTime * self.cfg.alpha);
    else
        self:Hide();
    end
end

--------------------------------------------------------------------------------------------------------
--                                           Event Handling                                           --
--------------------------------------------------------------------------------------------------------

-- Entering World
function bar:PLAYER_ENTERING_WORLD(event)
    self:StartFadeOut();
end

function bar:UNIT_SPELLCAST_START(event,unit,castID,spellID)
    -- Initialise
    local isCast = (event == "UNIT_SPELLCAST_START");
    local isChannel = (event == "UNIT_SPELLCAST_CHANNEL_START");
    local spell, _, texture, startTime, endTime, isTrade, nonInterruptible;
    local subText = GetSpellSubtext(spellID);
    if (isCast) then
        spell, _, texture, startTime, endTime, isTrade, castID, nonInterruptible = LibCTC:UnitCastingInfo(unit);  
    else
        spell, _, texture, startTime, endTime, isTrade, nonInterruptible = LibCTC:UnitChannelInfo(unit);           
    end
    if (not startTime) then
        return;
    end
    startTime = (startTime / 1000);
    endTime = (endTime / 1000);

    local castTime = (endTime - startTime);
    
    -- Init Objects
    self.status:SetStatusBarColor(unpack(nonInterruptible and self.cfg.colNonInterruptable or self.cfg.colNormal));
    self.icon:SetTexture(texture);

    -- should we show rank/subText
    if (self.cfg.showRank and subText and subText ~= "") then
        spell = spell.." ("..subText..")";
    end

    self.name:SetText(spell);

    -- Copy vars into self
    self.isCast = isCast;
    self.isChannel = isChannel;
    self.castTime = castTime;
    self.startTime, self.endTime, self.isTrade, self.castID, self.nonInterruptible = startTime, endTime, isTrade, castID, nonInterruptible; -- castID is zero for channeled

    -- Reset Variables and Show
    self.castDelay = 0;
    self.delayText = "";
    bar:SetTimeText(self.castTime);
    self:ResetAndShow(self.castTime,1);

end
bar.UNIT_SPELLCAST_CHANNEL_START = bar.UNIT_SPELLCAST_START;

-- Cast Failed
function bar:UNIT_SPELLCAST_FAILED(event,unit,castID,spellID)
    if (self.isCast) and (self.castID == castID) and (event == "UNIT_SPELLCAST_FAILED") then
        self.status:SetValue(self.castTime);
        self.status:SetStatusBarColor(unpack(self.cfg.colFailed));
        self.time:SetText(FAILED);
        self:StartFadeOut();
    end
end
bar.UNIT_SPELLCAST_FAILED_QUIET = bar.UNIT_SPELLCAST_FAILED;  -- quiet = tradeskill cast fail


-- Cast Stop
function bar:UNIT_SPELLCAST_STOP(event,unit,castID,spellID)
    if (self.isCast) and (self.castID == castID) and not (self.fadeTime) and not (self.tradeCount) then
        self.status:SetValue(self.castTime);
        self:StartFadeOut();
    end
end

-- Channel Stop
function bar:UNIT_SPELLCAST_CHANNEL_STOP(event,unit,castID,spellID)
    if (self.isChannel) and not (self.fadeTime) then
        self.status:SetValue(0);
        self:StartFadeOut();
    end
end

-- Cast/Channel Delayed -- This will fire for channeled spells on interrupts, not UNIT_SPELLCAST_INTERRUPTED.
function bar:UNIT_SPELLCAST_DELAYED(event,unit,castID,spellID)
    local _, _, _, startTimeNew, endTimeNew 
    if self.isChannel then
        _, _, _, startTimeNew, endTimeNew = LibCTC:UnitChannelInfo(self.unit); 
    else
        _, _, _, startTimeNew, endTimeNew = LibCTC:UnitCastingInfo(self.unit); 
    end        
    if (startTimeNew and endTimeNew) then
        local endTimeOld = self.endTime;
        self.startTime, self.endTime = (startTimeNew / 1000), (endTimeNew / 1000);
        self.castDelay = (self.castDelay + self.endTime - endTimeOld);
        self.delayText = format("|cffff8080%s%.1f|r  ",self.castDelay > 0 and "+" or "",self.castDelay);
    end
end

function bar:PLAYER_TARGET_CHANGED(event,unit,castID,spellID)

    local cast = "UNIT_SPELLCAST_START"
    local channel = "UNIT_SPELLCAST_CHANNEL_START"
    if castID then
        if LibCTC:UnitCastingInfo(unit) then
            return self:UNIT_SPELLCAST_START(cast,unit,castID,spellID)
        elseif LibCTC:UnitCastingInfo(unit) then
            return self:UNIT_SPELLCAST_START(channel,unit,castID,spellID)
        end
    else
        self:StartFadeOut();
    end
end


--------------------------------------------------------------------------------------------------------
--                                          Initialise Plugin                                         --
--------------------------------------------------------------------------------------------------------

-- Config Changed
function OnConfigChanged(self,cfg)
    -- For All CastBars
    LibCTC.UnregisterAllCallbacks(self);
    if (cfg.enabled) then
        for _, event in ipairs(registered_callbacks) do
            LibCTC.RegisterCallback(self,event);
        end
        bar.PLAYER_ENTERING_WORLD(self,"PLAYER_ENTERING_WORLD");
    else
        self:StartFadeOut();
    end
end

-- Start Frame FadeOut
local function StartFadeOut(self)
    if (not self.fadeTime) then
        self.isCast = nil;
        self.isChannel = nil;
        self.fadeTime = self.cfg.fadeTime;
    end
end

bar:ClearAllPoints();
bar:SetPoint("CENTER",0,-100);
-- callbacks
for _, cb in ipairs(registered_callbacks) do
        LibCTC.RegisterCallback(bar,cb);
end
bar:SetScript("OnUpdate",OnUpdate);
bar.StartFadeOut = StartFadeOut;
