local f, ATMe, events = CreateFrame("Frame"), {}, {}

StaticPopupDialogs["REPAIR_ALERT"] = {
  text = "Remember to repair your gear",
  button1 = "Ok",
  timeout = 10,
  whileDead = false,
  hideOnEscape = true,
  preferredIndex = 3
}

SLASH_ATME1 = "/ta"

ATMe.keyItemID = 180653
ATMe.taunts =  {
  [56222] = true,  -- Dark Command
  [51399] = true,  -- Death Grip
  [185245] = true, -- Torment
  [6795] = true,   -- Growl
  [115546] = true, -- Provke
  [62124] = true,  -- Hand of Reckoning
  [355] = true,    -- Taunt

  [1161] = true,   -- Challenging Shout
  [204079] = true  -- Final Stand
}
ATMe.slots = {
  "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot",
  "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot"
}
inspectInitialized = false
local InspectFontStrings = {}

function ATMe.SlashHandler(cmd)
end

function ATMe.OnEvent(self, event, ...)
  events[event](self, ...)
end

function GetUnitFromGuid(guid)
  if UnitGUID("target") == guid then return "target"
  elseif IsInRaid() then
    for i = 1, MAX_RAID_MEMBERS do
      if UnitGUID("raid"..i) == guid then return "raid"..i end
    end
  elseif IsInGroup() then
    for i = 1, MAX_PARTY_MEMBERS do
      if UnitGUID("party"..i) == guid then return "party"..i end
    end
  else return nil end
end

function events:INSPECT_READY(guid)
  if not inspectInitialized and InspectFrame then
    InspectFontStrings["itemLevel"] = InspectFrame:CreateFontString(nil, "OVERLAY")
    InspectFontStrings["itemLevel"]:SetPoint("BOTTOMLEFT", 10, 5)
    InspectFontStrings["itemLevel"]:SetFont("Fonts\\FRIZQT__.ttf", 24, "OUTLINE")
    InspectFontStrings["itemLevel"]:SetTextColor(1, 1, 1)

    inspectInitialized = true
  end


  unit = GetUnitFromGuid(guid)
  if unit and CanInspect(unit) and inspectInitialized then
    local itemLevel = C_PaperDollInfo.GetInspectItemLevel(unit)
    InspectFontStrings["itemLevel"]:SetText(itemLevel)
  end
end

function events:CHAT_MSG_PARTY_LEADER(message, ...)
  if message == '!keys' then
    ATMe.announceKey()
  end
end

function events:CHAT_MSG_PARTY(message, ...)
  if message == '!keys' then
    ATMe.announceKey()
  end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(...)
  ATMe.announceTaunts(CombatLogGetCurrentEventInfo())
end

function events:MERCHANT_SHOW(...)
  -- Sell all gray items
  ATMe.sellGrayItems()

  -- Repair if we need to and merchant allows it
  if CanMerchantRepair() and ATMe.needsRepair() then
    RepairAllItems(CanGuildBankRepair())
    print("Your items have been repaired")
  end
end

function events:PLAYER_LOGIN(...)
  -- found from some forums
  local b=ActionButton8 _MH=_MH or(b:SetAttribute("*type5","macro")or SecureHandlerWrapScript(b,"PreClick",b,'Z=IsAltKeyDown()and 0 or(Z or 0)%8+1 self:SetAttribute("macrotext5","/wm [nomod]"..Z)'))or 1
end

function events:PLAYER_REGEN_DISABLED(...)
  StopwatchFrame:Show()
  Stopwatch_Clear()
  Stopwatch_Play()
end

function events:PLAYER_REGEN_ENABLED(...)
  Stopwatch_Pause()
end

function events:PLAYER_DEAD(...)
  Stopwatch_Pause()
end

function events:PLAYER_ROLES_ASSIGNED(...)
  if ATMe.amTankInParty() then ATMe.markSelfSquare() end
end

function events:PLAYER_UPDATE_RESTING(...)
  -- Notify that we should repair
  if ATMe.needsRepair() then StaticPopup_Show("REPAIR_ALERT") end
end

function ATMe.announceKey()
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag)do
      itemID = GetContainerItemID(bag, slot)
      if GetContainerItemID(bag, slot) == ATMe.keyItemID then
        local link = GetContainerItemLink(bag, slot)
        SendChatMessage(link, "PARTY")

        return
      end
    end
  end
end

function ATMe.announceTaunts(...)
  event = select(2, ...)
  spellId = select(12, ...)

  if event ~= 'SPELL_CAST_SUCCESS' or ATMe.taunts[spellId] ~= true then
    return
  end

  srcName = select(5, ...)
  destName = select(9, ...)
  spellName = select(13, ...)

  message = format("|cffFF0000TAUNT:|r %s used %s", srcName, spellName)
  if destName ~= nil then
    message = format("%s on %s", message, destName)
  end

  print(message)
end

function ATMe.needsRepair()
  for slot = 1, #ATMe.slots do
    local id = GetInventorySlotInfo(ATMe.slots[slot])
    local cur, max = GetInventoryItemDurability(id)

    if max and cur ~= max then return true end
  end

  return false
end

function ATMe.sellGrayItems()
  sellTotal = 0
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local _, count, _, quality, _, _, link = GetContainerItemInfo(bag, slot)
      if quality and quality == 0 then
        local price = select(11, GetItemInfo(link))
        sellTotal = sellTotal + (price * count)
        print("Selling "..count.."x"..link)
        UseContainerItem(bag, slot)
      end
    end
  end
  if sellTotal ~= 0 then
    print("Made "..GetCoinTextureString(sellTotal))
  end
end

function ATMe.amTankInParty()
  local isParty = UnitInRaid("player") == nil
  local isTank = UnitGroupRolesAssigned("player") == "TANK"
  local notAlreadyMarked = GetRaidTargetIndex("player") == nil

  return isParty and isTank and notAlreadyMarked
end

function ATMe.markSelfSquare()
  SetRaidTarget("player", 6)
end

-- Register events
for event, method in pairs(events) do
  f:RegisterEvent(event)
end
f:SetScript("OnEvent", ATMe.OnEvent)

function PaperDollFrame_SetMovementSpeed(statFrame, unit)
	statFrame.wasSwimming = nil
	statFrame.unit = unit
	MovementSpeed_OnUpdate(statFrame)

	statFrame.onEnterFunc = MovementSpeed_OnEnter
	statFrame:SetScript("OnUpdate", MovementSpeed_OnUpdate)
	statFrame:Show()
end

CharacterStatsPane.statsFramePool.resetterFunc =
	function(pool, frame)
		frame:SetScript("OnUpdate", nil)
		frame.onEnterFunc = nil
		frame.UpdateTooltip = nil
		FramePool_HideAndClearAnchors(pool, frame)
	end
table.insert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "MOVESPEED"})

SlashCmdList["ATME"] = ATMe.SlashHandler
