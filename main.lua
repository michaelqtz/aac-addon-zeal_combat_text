local zeal_combat_text_addon = {
	name = "Zeal Combat Text",
	author = "Michaelqt",
	version = "0.3",
	desc = "Make damage and heals pink when zeal'd"
}

local zealCombatText = api.Interface:CreateEmptyWindow("zealCombatText", "UIParent")
local zealBuffId = 495
local zealColorHeal = {
  r = 0.75,
  g = 0.08,
  b = 0.90,
  a = 1
}

local zealColorDmg = {
  r = 0.93,
  g = 0.4,
  b = 0.75,
  a = 1
}
-- TODO: Doesn't work for heals
local defaultColorDmg = COMBAT_TEXT_COLOR.SKILL
local defaultColorHeal = COMBAT_TEXT_COLOR.HEAL

local zealFound = false

-- Determine through combat messages if the damages are critical and during zeal
local function checkForZealDmg(targetUnitId, combatEvent, source, target, ...)
  if combatEvent == "SPELL_AURA_APPLIED" then
    local result = ParseCombatMessage(combatEvent, unpack(arg))
    if result.spellName == "Zeal" then
      zealFound = true
    end
  elseif combatEvent == "SPELL_AURA_REMOVED" then
    local result = ParseCombatMessage(combatEvent, unpack(arg))
    if result.spellName == "Zeal" then
      zealFound = false
    end
  end
  local wasItMe = api.Unit:GetUnitNameById(api.Unit:GetUnitId("player")) == source
  if wasItMe == false then
    return nil
  end
  zealFound = false
  for i = 1, api.Unit:UnitBuffCount("player") do
    local currentBuff = api.Unit:UnitBuff("player", i)
    if currentBuff.buff_id == 495 then
      zealFound = true
    end
  end

  -- Determining if event is "CRITICAL" or not
  local hitType = nil
  local pos = combatEvent:find("_")
  local suffix = combatEvent:sub(pos + 1)
  local parsingIndex = 3
  local function GetNextIndex()
    parsingIndex = parsingIndex + 1
    return parsingIndex
  end
  if suffix == "DAMAGE" or suffix == "DOT_DAMAGE" then  
    local damage = arg[GetNextIndex()]
    local powerType = arg[GetNextIndex()]
    hitType = arg[GetNextIndex()]
  end
  if (zealFound and hitType == "CRITICAL") then
    COMBAT_TEXT_COLOR.SKILL = zealColorDmg
    COMBAT_TEXT_COLOR.DOT = zealColorDmg
  else
    COMBAT_TEXT_COLOR.SKILL = defaultColorDmg
    COMBAT_TEXT_COLOR.DOT = defaultColorDmg
  end
end

-- TODO: In this function, find combat text frames, loop, and turn critical ones purple
local function checkForZealHeal(sourceUnitId, targetUnitId, amount, skillType, hitOrMissType, weaponDamage, isSynergy, distance)
  local wasItMe = api.Unit:GetUnitNameById(api.Unit:GetUnitId("player")) == api.Unit:GetUnitNameById(sourceUnitId)
  if wasItMe == false then
    return nil
  end
  local hitType = nil
  if skillType == "HEAL" then
    hitType = hitOrMissType
  end 
  if (zealFound and hitType == "CRITICAL") then
    local combatTextFrame = ADDON:GetContent(UIC.COMBAT_TEXT_FRAME)
    for i, combatText in ipairs(combatTextFrame.combatTexts) do
      if combatText:GetText() == "+" .. tostring(amount) then 
        combatText.style:SetColor(zealColorHeal["r"], zealColorHeal["g"], zealColorHeal["b"], zealColorHeal["a"])
      end 
    end 
  else
    COMBAT_TEXT_COLOR.HEAL = defaultColorHeal
  end 
  
end 

function zealCombatText:OnEvent(event, ...)
  if event == "COMBAT_MSG" then      
    checkForZealDmg(unpack(arg))
  end
  if event == "COMBAT_TEXT" then 
    checkForZealHeal(unpack(arg))
  end   
end
zealCombatText:SetHandler("OnEvent", zealCombatText.OnEvent)
zealCombatText:RegisterEvent("COMBAT_MSG")
zealCombatText:RegisterEvent("COMBAT_TEXT")

local function OnLoad()
  defaultColorDmg = COMBAT_TEXT_COLOR.SKILL
  defaultColorHeal = COMBAT_TEXT_COLOR.HEAL
end

local function OnUnload()
  zealCombatText:ReleaseHandler("OnEvent")
  zealCombatText = nil
end

zeal_combat_text_addon.OnLoad = OnLoad
zeal_combat_text_addon.OnUnload = OnUnload

return zeal_combat_text_addon
