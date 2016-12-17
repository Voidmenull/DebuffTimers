-- UnitFrames Timer Module by Renew: https://github.com/Voidmenull/ --
----------------------------------------------------------------------

-- AUF = Aurae Unit Frames
-- damn you Bit and your setfenv -_-

local _G, _M = getfenv(0), {}
setfenv(1, setmetatable(_M, {__index=_G}))

do
	local f = CreateFrame'Frame'
	f:SetScript('OnEvent', function()
		_M[event](this)
	end)
	for _, event in {
		'CHAT_MSG_COMBAT_HONOR_GAIN', 'CHAT_MSG_COMBAT_HOSTILE_DEATH', 'PLAYER_REGEN_ENABLED',
		'CHAT_MSG_SPELL_AURA_GONE_OTHER', 'CHAT_MSG_SPELL_BREAK_AURA',
		'CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE', 'CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS', 'CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE',
		'SPELLCAST_STOP', 'SPELLCAST_INTERRUPTED', 'CHAT_MSG_SPELL_SELF_DAMAGE', 'CHAT_MSG_SPELL_FAILED_LOCALPLAYER',
		'PLAYER_TARGET_CHANGED', 'UPDATE_BATTLEFIELD_SCORE',
	} do f:RegisterEvent(event) end
end

CreateFrame('GameTooltip', 'AUF_Tooltip', nil, 'GameTooltipTemplate')

_G.AUF_settings = {}

local COMBO = 0

local DR_CLASS = {
	["Bash"] = 1,
	["Hammer of Justice"] = 1,
	["Cheap Shot"] = 1,
	["Charge Stun"] = 1,
	["Intercept Stun"] = 1,
	["Concussion Blow"] = 1,

	["Fear"] = 2,
	["Howl of Terror"] = 2,
	["Seduction"] = 2,
	["Intimidating Shout"] = 2,
	["Psychic Scream"] = 2,

	["Polymorph"] = 3,
	["Sap"] = 3,
	["Gouge"] = 3,

	["Entangling Roots"] = 4,
	["Frost Nova"] = 4,

	["Freezing Trap Effect"] = 5,
	["Wyvern String"] = 5,

	["Blind"] = 6,

	["Hibernate"] = 7,

	["Mind Control"] = 8,

	["Kidney Shot"] = 9,

	["Death Coil"] = 10,

	["Frost Shock"] = 11,
}

local timers = {}

do
	local factor = {1, 1/2, 1/4, 0}

	function DiminishedDuration(unit, effect, full_duration)
		local class = DR_CLASS[effect]
		if class then
			StartDR(effect, unit)
			return full_duration * factor[timers[class .. '@' .. unit].DR]
		else
			return full_duration
		end
	end
end

function UnitDebuffs(unit)
	local debuffs = {}
	local i = 1
	while UnitDebuff(unit, i) do
		AUF_Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		AUF_Tooltip:SetUnitDebuff(unit, i)
		debuffs[AUF_TooltipTextLeft1:GetText()] = true
		i = i + 1
	end
	return debuffs
end

function UnitDebuffText(unit,position)
	AUF_Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	AUF_Tooltip:SetUnitDebuff(unit, position)

	return AUF_TooltipTextLeft1:GetText()
end

function SetActionRank(name, rank)
	local _, _, rank = strfind(rank or '', 'Rank (%d+)')
	if rank and AUF_RANKS[name] then
		AUF_EFFECTS[AUF_RANKS[name].EFFECT or name].DURATION = AUF_RANKS[name].DURATION[tonumber(rank)]
	end
end

do
	local casting = {}
	local last_cast
	local pending = {}

	do
		local orig = UseAction
		function _G.UseAction(slot, clicked, onself)
			if HasAction(slot) and not GetActionText(slot) then
				AUF_Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
				AUF_TooltipTextRight1:SetText()
				AUF_Tooltip:SetAction(slot)
				local name = AUF_TooltipTextLeft1:GetText()
				casting[name] = TARGET
				SetActionRank(name, AUF_TooltipTextRight1:GetText())
			end
			return orig(slot, clicked, onself)
		end
	end

	do
		local orig = CastSpell
		function _G.CastSpell(index, booktype)
			local name, rank = GetSpellName(index, booktype)
			casting[name] = TARGET
			SetActionRank(name, rank)
			return orig(index, booktype)
		end
	end

	do
		local orig = CastSpellByName
		function _G.CastSpellByName(text, onself)
			if not onself then
				casting[text] = TARGET
			end
			return orig(text, onself)
		end
	end

	function CHAT_MSG_SPELL_FAILED_LOCALPLAYER()
		for action in string.gfind(arg1, 'You fail to %a+ (.*):.*') do
			casting[action] = nil
		end
	end

	function SPELLCAST_STOP()
		for action, target in casting do
			if AUF_ACTIONS[action] then
				local effect = AUF_ACTIONS[action] == true and action or AUF_ACTIONS[action]
				
				if not IsPlayer(target) or EffectActive(effect, target) then
					if pending[effect] then
						last_cast = nil
					else
						pending[effect] = {target=target, time=GetTime() + (AUF_DELAYS[effect] or 0)}
						if GetComboPoints() > 0 then
							COMBO = GetComboPoints()
						end
						last_cast = effect
					end
				end
			end
		end
		casting = {}
	end

	CreateFrame'Frame':SetScript('OnUpdate', function()
		for effect, info in pending do
			if GetTime() >= info.time  then
				StartTimer(effect, info.target, info.time)
				pending[effect] = nil
			end
		end
	end)

	function AbortCast(effect, unit)
		for k, v in pending do
			if k == effect and v.target == unit then
				pending[k] = nil
			end
		end
	end

	function AbortUnitCasts(unit)
		for k, v in pending do
			if v.target == unit or not unit and not IsPlayer(v.target) then
				pending[k] = nil
			end
		end
	end

	function SPELLCAST_INTERRUPTED()
		if last_cast then
			pending[last_cast] = nil
		end
	end

	do
		local patterns = {
			'is immune to your (.*)%.',
			'Your (.*) missed',
			'Your (.*) was resisted',
			'Your (.*) was evaded',
			'Your (.*) was dodged',
			'Your (.*) was deflected',
			'Your (.*) is reflected',
			'Your (.*) is parried'
		}
		function CHAT_MSG_SPELL_SELF_DAMAGE()
			for _, pattern in patterns do
				local _, _, effect = strfind(arg1, pattern)
				if effect then
					pending[effect] = nil
					return
				end
			end
		end
	end
end

function CHAT_MSG_SPELL_AURA_GONE_OTHER()
	for effect, unit in string.gfind(arg1, '(.+) fades from (.+)%.') do
		AuraGone(unit, effect)
	end
end

function CHAT_MSG_SPELL_BREAK_AURA()
	for unit, effect in string.gfind(arg1, "(.+)'s (.+) is removed%.") do
		AuraGone(unit, effect)
	end
end

function ActivateDRTimer(effect, unit)
	for k, v in DR_CLASS do
		if v == DR_CLASS[effect] and EffectActive(k, unit) then
			return
		end
	end
	local timer = timers[DR_CLASS[effect] .. '@' .. unit]
	if timer then
		timer.START = GetTime()
		timer.END = timer.START + 15
	end
end

function AuraGone(unit, effect)
	if AUF_EFFECTS[effect] then
		if IsPlayer(unit) then
			AbortCast(effect, unit)
			StopTimer(effect .. '@' .. unit)
			if DR_CLASS[effect] then
				ActivateDRTimer(effect, unit)
			end
		elseif unit == UnitName'target' then
			-- TODO pet target (in other places too)
			local unit = TARGET
			local debuffs = UnitDebuffs'target'
			for k, timer in timers do
				if timer.UNIT == unit and not debuffs[timer.EFFECT] then
					StopTimer(timer.EFFECT .. '@' .. timer.UNIT)
				end
			end
		end
	end
end

function CHAT_MSG_COMBAT_HOSTILE_DEATH()
	for unit in string.gfind(arg1, '(.+) dies') do -- TODO does not work when xp is gained
		if IsPlayer(unit) then
			UnitDied(unit)
		elseif unit == UnitName'target' and UnitIsDead'target' then
			UnitDied(TARGET)
		end
	end
end

function CHAT_MSG_COMBAT_HONOR_GAIN()
	for unit in string.gfind(arg1, '(.+) dies') do
		UnitDied(unit)
	end
end

function UpdateTimers()
	local t = GetTime()
	for k, timer in timers do
		if timer.END and t > timer.END then
			StopTimer(k)
			if DR_CLASS[timer.EFFECT] and not timer.DR then
				ActivateDRTimer(timer.EFFECT, timer.UNIT)
			end
		end
	end
end

function EffectActive(effect, unit)
	return timers[effect .. '@' .. unit] and true or false
end

function StartTimer(effect, unit, start)
	local key = effect .. '@' .. unit
	local timer = timers[key] or {}
	timers[key] = timer

	timer.EFFECT = effect
	timer.UNIT = unit
	timer.START = start
	timer.END = timer.START

	local duration = AUF_EFFECTS[effect].DURATION
	if AUF_COMBO[effect] then
		duration = duration + AUF_COMBO[effect] * COMBO
	end

	if bonuses[effect] then
		duration = duration + bonuses[effect](duration)
	end

	if IsPlayer(unit) then
		timer.END = timer.END + DiminishedDuration(unit, effect, AUF_PVP_DURATION[effect] or duration)
	else
		timer.END = timer.END + duration
	end

	timer.stopped = nil
	AUF:UpdateDebuffs()
end

function StartDR(effect, unit)

	local key = DR_CLASS[effect] .. '@' .. unit
	local timer = timers[key] or {}

	if not timer.DR or timer.DR < 3 then
		timers[key] = timer

		timer.EFFECT = effect
		timer.UNIT = unit
		timer.START = nil
		timer.END = nil
		timer.DR = min(3, (timer.DR or 0) + 1)
	end
end

function PLAYER_REGEN_ENABLED()
	AbortUnitCasts()
	for k, timer in timers do
		if not IsPlayer(timer.UNIT) then
			StopTimer(k)
		end
	end
end

function StopTimer(key)
	if timers[key] then
		timers[key].stopped = GetTime()
		timers[key] = nil
	end
end

function UnitDied(unit)
	AbortUnitCasts(unit)
	for k, timer in timers do
		if timer.UNIT == unit then
			StopTimer(k)
		end
	end
end

CreateFrame'Frame':SetScript('OnUpdate', RequestBattlefieldScoreData)

do
	local player = {}

	local function hostilePlayer(msg)
		local _, _, name = strfind(arg1, "^([^%s']*)")
		return name
	end

	function CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS()
		if player[hostilePlayer(arg1)] == nil then player[hostilePlayer(arg1)] = true end -- wrong for pets
	end

	function CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE()
		if player[hostilePlayer(arg1)] == nil then player[hostilePlayer(arg1)] = true end -- wrong for pets
		for unit, effect in string.gfind(arg1, '(.+) is afflicted by (.+)%.') do
			if AUF_EFFECTS[effect] and AUF_EFFECTS[effect].EXTERN then
				--StartTimer(effect, unit, GetTime())
			end
		end
	end
	
	function CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE()
		if player[hostilePlayer(arg1)] == nil then player[hostilePlayer(arg1)] = true end -- wrong for pets
		for unit, effect in string.gfind(arg1, '(.+) is afflicted by (.+)%.') do
			if AUF_EFFECTS[effect] and AUF_EFFECTS[effect].EXTERN then
				--StartTimer(effect, unit, GetTime())
			end
		end
	end

	do
		local current
		function PLAYER_TARGET_CHANGED()
			local unit = UnitName'target'
			TARGET = unit
			if unit then
				player[unit] = UnitIsPlayer'target' and true or false
				current = unit
			end
		end
	end

	function UPDATE_BATTLEFIELD_SCORE()
		for i = 1, GetNumBattlefieldScores() do
			player[GetBattlefieldScore(i)] = true
		end
	end

	function IsPlayer(unit)
		return player[unit]
	end
end

CreateFrame'Frame':SetScript('OnUpdate', function()
	UpdateTimers()
end)

do
	local function rank(i, j)
		local _, _, _, _, rank = GetTalentInfo(i, j)
		return rank
	end

	local _, class = UnitClass'player'
	if class == 'ROGUE' then
		bonuses = {
			["Gouge"] = function()
				return rank(2, 1) * .5
			end,
			["Garrote"] = function()
				return rank(3, 8) * 3
			end,
		}
	elseif class == "WARLOCK" then
		bonuses = {
			["Shadow Word: Pain"] = function() -- ???
				return rank(2, 7) * 1.5
			end,
			["Seduction"] = function()
				return rank(2, 7) * 1.5
			end,
		}
	elseif class == "WARRIOR" then
		bonuses = {
			["Demoralizing Shout"] = function()
				return rank(2, 1) * 3
			end,
		}
	elseif class == 'HUNTER' then
		bonuses = {
			["Freezing Trap Effect"] = function(t)
				return t * rank(3, 7) * .15
			end,
			["Frost Trap Aura"] = function(t)
				return t * rank(3, 7) * .15
			end,
		}
	elseif class == 'PRIEST' then
		bonuses = {
			["Shadow Word: Pain"] = function()
				return rank(3, 4) * 3
			end,
		}
	elseif class == 'MAGE' then
		bonuses = {
			["Cone of Cold"] = function()
				return min(1, rank(3, 2)) * .5 + rank(3, 2) * .5
			end,
			["Frostbolt"] = function()
				return min(1, rank(3, 2)) * .5 + rank(3, 2) * .5
			end,
			["Polymorph"] = function()
				return AUF_settings.arcanist and 15 or 0
			end,
		}
	elseif class == 'DRUID' then
		bonuses = {
			["Pounce"] = function()
				return rank(2, 4) * .5
			end,
			["Bash"] = function()
				return rank(2, 4) * .5
			end,
		}
	else
		bonuses = {}
	end
end

function AUFPromt(msg)
	if msg then
		local command = strlower(msg)
		if string.sub(command, 1, 8) == "textsize" then
			local size = tonumber(string.sub(command, 10, string.len(command)))
			AUF_settings.TextSize = size
			for i=1,16 do
				AUF.Debuff[i].Font:SetFont("Fonts\\ARIALN.TTF", AUF_settings.TextSize, "OUTLINE")
				if getglobal("pfUITargetDebuff1") then AUF.Debuff[i].Font:SetFont("Interface\\AddOns\\pfUI\\fonts\\homespun.ttf", AUF_settings.TextSize, "OUTLINE") end
				AUF.Buff[i].Font:SetFont("Fonts\\ARIALN.TTF", AUF_settings.TextSize, "OUTLINE")
				if getglobal("pfUITargetBuff1") then AUF.Buff[i].Font:SetFont("Interface\\AddOns\\pfUI\\fonts\\homespun.ttf", AUF_settings.TextSize, "OUTLINE") end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Debuff Timers:|r This is help topic for |cFFFFFF00 /DebuffTimers|r",1,1,1)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Debuff Timers:|r |cFFFFFF00 /DebuffTimers textsize NUMBER|r - sets textsize (20 is default).",1,1,1)
		end
	else
	
	end
end

_G.SLASH_DEBUFFTIMERS1 = '/DebuffTimers'
_G.SLASH_DEBUFFTIMERS2 = '/debufftimers'
SlashCmdList.DEBUFFTIMERS = AUFPromt

AUF = CreateFrame("Frame")
AUF.Debuff = CreateFrame("Frame")
AUF.Buff = CreateFrame("Frame",nil,UIParent)
AUF.DR = CreateFrame("Frame",nil,UIParent)
AUF:RegisterEvent("PLAYER_TARGET_CHANGED")
AUF:RegisterEvent("ADDON_LOADED")
AUF.UnitDebuff = UnitDebuff
AUF.UnitBuff = UnitBuff
AUF.UnitName = UnitName


AUF.DebuffAnchor = "TargetFrameDebuff"
AUF.BuffAnchor = "TargetFrameBuff"

AUF.ClickCast = {}
AUF.DoubleCheck = {}

-- get unitframes
if getglobal("LunaLUFUnittargetDebuffFrame1") then AUF.DebuffAnchor = "LunaLUFUnittargetDebuffFrame"; AUF.BuffAnchor = "LunaLUFUnittargetBuffFrame" -- luna x2.x
elseif getglobal("XPerl_Target_BuffFrame") then AUF.DebuffAnchor = "XPerl_Target_BuffFrame_DeBuff"; AUF.BuffAnchor = "XPerl_Target_BuffFrame_Buff" -- xperl
elseif getglobal("DUF_TargetFrame_Debuffs_1") then AUF.DebuffAnchor = "DUF_TargetFrame_Debuffs_"; AUF.BuffAnchor = "DUF_TargetFrame_Buffs_" -- DUF
elseif getglobal("pfUITargetDebuff1") then AUF.DebuffAnchor = "pfUITargetDebuff"; AUF.BuffAnchor = "pfUITargetBuff" -- pfUI
end

function AUF.Debuff:Build()
	for i=1,16 do
		AUF.Debuff[i] = CreateFrame("Model", "AUFDebuff"..i, nil, "CooldownFrameTemplate")
		AUF.Debuff[i].parent = CreateFrame("Frame", "AUFDebuff"..i.."Cooldown", getglobal(AUF.DebuffAnchor..i))
		AUF.Debuff[i].parent:SetPoint("CENTER",getglobal(AUF.DebuffAnchor..i),"CENTER", 0, 0)
		AUF.Debuff[i].parent:SetWidth(100)
		AUF.Debuff[i].parent:SetHeight(100)
		AUF.Debuff[i].parent:SetFrameStrata("DIALOG")
		if getglobal(AUF.DebuffAnchor..i) then AUF.Debuff[i].parent:SetFrameLevel(getglobal(AUF.DebuffAnchor..i):GetFrameLevel() + 1) end
		AUF.Debuff[i]:SetParent(AUF.Debuff[i].parent)
		AUF.Debuff[i]:SetAllPoints(AUF.Debuff[i].parent)
		AUF.Debuff[i].parent:SetScript("OnUpdate",nil)

		AUF.Debuff[i].Font = AUF.Debuff[i]:CreateFontString(nil, "OVERLAY")
		AUF.Debuff[i].Font:SetPoint("CENTER", 0, 0)
		AUF.Debuff[i].Font:SetFont("Fonts\\ARIALN.TTF", AUF_settings.TextSize, "OUTLINE")
		if getglobal("pfUITargetDebuff1") then AUF.Debuff[i].Font:SetFont("Interface\\AddOns\\pfUI\\fonts\\homespun.ttf", AUF_settings.TextSize, "OUTLINE") end
		AUF.Debuff[i].Font:SetJustifyH("CENTER")
		AUF.Debuff[i].Font:SetTextColor(1,1,1)
		AUF.Debuff[i].Font:SetText("")
		
	end
end

function AUF.Buff:Build()
	for i=1,16 do
		AUF.Buff[i] = CreateFrame("Model", "AUFBuff"..i, nil, "CooldownFrameTemplate")
		AUF.Buff[i].parent = CreateFrame("Frame", "AUFBuff"..i.."Cooldown", getglobal(AUF.BuffAnchor..i))
		AUF.Buff[i].parent:SetPoint("CENTER",getglobal(AUF.BuffAnchor..i),"CENTER", 0, 0)
		AUF.Buff[i].parent:SetWidth(100)
		AUF.Buff[i].parent:SetHeight(100)
		AUF.Buff[i].parent:SetFrameStrata("DIALOG")
		if getglobal(AUF.BuffAnchor..i) then AUF.Buff[i].parent:SetFrameLevel(getglobal(AUF.BuffAnchor..i):GetFrameLevel() + 1) end
		AUF.Buff[i]:SetParent(AUF.Buff[i].parent)
		AUF.Buff[i]:SetAllPoints(AUF.Buff[i].parent)
		AUF.Buff[i].parent:SetScript("OnUpdate",nil)
		
		AUF.Buff[i].Font = AUF.Buff[i]:CreateFontString(nil, "OVERLAY")
		AUF.Buff[i].Font:SetPoint("CENTER", 0, 0)
		AUF.Buff[i].Font:SetFont("Fonts\\ARIALN.TTF", AUF_settings.TextSize, "OUTLINE")
		if getglobal("pfUITargetBuff1") then AUF.Buff[i].Font:SetFont("Interface\\AddOns\\pfUI\\fonts\\homespun.ttf", AUF_settings.TextSize, "OUTLINE") end
		AUF.Buff[i].Font:SetJustifyH("CENTER")
		AUF.Buff[i].Font:SetTextColor(1,1,1)
		AUF.Buff[i].Font:SetText("")
		
	end
end

function AUF:UpdateFont(button,start,duration,style)
	if style == "Debuff" then
		AUF.Debuff[button].Duation = duration
		AUF.Debuff[button].parent:SetScript("OnUpdate",function()
			AUF.Debuff[button].Duation = AUF.Debuff[button].Duation - arg1
			
			if AUF.Debuff[button].Duation > 0 then
				AUF.Debuff[button].Font:SetText(floor(AUF.Debuff[button].Duation+0.5))
				if AUF.Debuff[button].Duation > 3 then
					AUF.Debuff[button].Font:SetTextColor(1,1,1)
				else AUF.Debuff[button].Font:SetTextColor(1,0.4,0.4) end
			else
				AUF.Debuff[button].parent:SetScript("OnUpdate",nil)
			end

		end)
	elseif style == "Buff" then
		AUF.Buff[button].Duation = duration
		AUF.Buff[button].parent:SetScript("OnUpdate",function()
			AUF.Buff[button].Duation = AUF.Buff[button].Duation - arg1
			
			if AUF.Buff[button].Duation > 0 then
				AUF.Buff[button].Font:SetText(floor(AUF.Buff[button].Duation+0.5))
				if AUF.Buff[button].Duation > 3 then
					AUF.Buff[button].Font:SetTextColor(1,1,1)
				else AUF.Buff[button].Font:SetTextColor(1,0.4,0.4) end
					
			else
				AUF.Buff[button].parent:SetScript("OnUpdate",nil)
			end

		end)
	end
end

function AUF:OnEvent()
	if event == "PLAYER_TARGET_CHANGED" then
		AUF:OnTarget()
	elseif event == "UNIT_AURA" and arg1 == "target" then
		for _, timer in timers do
			timer.DOUBLE = nil -- clear double timers
		end
		AUF:UpdateDebuffs()
	elseif event == "ADDON_LOADED" and arg1 == "DebuffTimers" then
		if not AUF_settings then AUF_settings = {} end
		if not AUF_settings.TextSize then AUF_settings.TextSize = 20 end
		AUF.Debuff:Build()
		AUF.Buff:Build()
	end
end
AUF:SetScript("OnEvent", AUF.OnEvent)

function AUF:OnTarget()
	if UnitExists("target") then
		AUF:RegisterEvent("UNIT_AURA")
		AUF:UpdateDebuffs()
	else
		AUF:UnregisterEvent("UNIT_AURA")
		for i=1,16 do -- xperl fade problem
			AUF.Debuff[i].parent:Hide()
			AUF.Buff[i].parent:Hide()
		end
	end
end

function AUF:UpdateDebuffs()
	-- close old animations
	for i=1,16 do
		CooldownFrame_SetTimer(AUF.Debuff[i],0,0,0)
		CooldownFrame_SetTimer(AUF.Buff[i],0,0,0)
	end
	-- delete old doublecheck
	for effect, _ in AUF.DoubleCheck do
		AUF.DoubleCheck[effect] = nil
	end
	
	if UnitExists("target") then
		for _, timer in timers do
			if not timer.DR and AUF.UnitName("target") == timer.UNIT then
				for i=1,16 do
					if UnitDebuffText("target",i) == timer.EFFECT and getglobal(AUF.DebuffAnchor..i) and not AUF.DoubleCheck[timer.EFFECT] then
						AUF.DoubleCheck[timer.EFFECT] = true
						-- xper exception
						if  getglobal("XPerl_Target_BuffFrame") then
							AUF.Debuff[i].parent:SetWidth(getglobal(AUF.DebuffAnchor..i):GetWidth()*0.7)
							AUF.Debuff[i].parent:SetHeight(getglobal(AUF.DebuffAnchor..i):GetHeight()*0.7)
							AUF.Debuff[i]:SetScale(getglobal(AUF.DebuffAnchor..i):GetHeight()/36*0.7)
						else
							AUF.Debuff[i].parent:SetWidth(getglobal(AUF.DebuffAnchor..i):GetWidth())
							AUF.Debuff[i].parent:SetHeight(getglobal(AUF.DebuffAnchor..i):GetHeight())
							AUF.Debuff[i]:SetScale(getglobal(AUF.DebuffAnchor..i):GetHeight()/36)
						end
						
						AUF.Debuff[i].parent:SetPoint("CENTER",getglobal(AUF.DebuffAnchor..i),"CENTER",0,0)
						--getglobal(AUF.DebuffAnchor..i):SetID(i)
						--getglobal(AUF.DebuffAnchor..i):SetScript("OnClick", function() CastSpellByName(UnitDebuffText("target",this:GetID())) end)
						AUF.Debuff[i].parent:Show()
						
						if pfCooldownFrame_SetTimer then pfCooldownFrame_SetTimer(AUF.Debuff[i],timer.START, timer.END-timer.START,1)
						else CooldownFrame_SetTimer(AUF.Debuff[i],timer.START, timer.END-timer.START,1) end
						AUF:UpdateFont(i,timer.START,timer.END-GetTime(),"Debuff")
					end
					
					if AUF.UnitBuff("target",i) == "Interface\\Icons\\"..AUF_EFFECTS[timer.EFFECT].ICON and getglobal(AUF.BuffAnchor..i) then
						
						if  getglobal("XPerl_Target_BuffFrame") then
							AUF.Buff[i].parent:SetWidth(getglobal(AUF.BuffAnchor..i):GetWidth()*0.7)
							AUF.Buff[i].parent:SetHeight(getglobal(AUF.BuffAnchor..i):GetHeight()*0.7)
							AUF.Buff[i]:SetScale(getglobal(AUF.BuffAnchor..i):GetHeight()/36*0.7)
						else
							AUF.Buff[i].parent:SetWidth(getglobal(AUF.BuffAnchor..i):GetWidth())
							AUF.Buff[i].parent:SetHeight(getglobal(AUF.BuffAnchor..i):GetHeight())
							AUF.Buff[i]:SetScale(getglobal(AUF.BuffAnchor..i):GetHeight()/36)
						end
						AUF.Buff[i].parent:SetPoint("CENTER",getglobal(AUF.BuffAnchor..i),"CENTER",0,0)
						AUF.Buff[i].parent:Show()
						
						if pfCooldownFrame_SetTimer then pfCooldownFrame_SetTimer(AUF.Buff[i],timer.START, timer.END-timer.START,1)
						else CooldownFrame_SetTimer(AUF.Buff[i],timer.START, timer.END-timer.START,1) end
						AUF:UpdateFont(i,timer.START,timer.END-GetTime(),"Buff")
					end
				end
			end
		end--]]
	end
end