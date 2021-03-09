local f, MyAddon, events = CreateFrame("Frame"), {}, {}

StaticPopupDialogs["REPAIR_ALERT"] = {
  text = "Remember to repair your gear",
  button1 = "Ok",
  timeout = 10,
  whileDead = false,
  hideOnEscape = true,
  preferredIndex = 3
}

StaticPopupDialogs["GOLIATH_MISSING"] = {
  text = "Option to repair goliath not found; move closer",
  button1 = "Ok",
  OnAccept = function()
    C_GossipInfo.CloseGossip()
  end,
  timeout = 5,
  whileDead = false,
  hideOnEscape = true,
  preferredIndex = 3
}

SLASH_MYADDON1 = "/ta"

MyAddon.keyItemID = 180653
MyAddon.taunts =  {
  [56222] = true,  -- Dark Command
  [51399] = true,  -- Death Grip
  [185245] = true, -- Torment
  [6795] = true,   -- Growl
  [115546] = true, -- Provke
  [62124] = true, -- Hand of Reckoning
  [355] = true,    -- Taunt

  [1161] = true,   -- Challenging Shout
  [204079] = true  -- Final Stand
}
MyAddon.slots = {
  "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot",
  "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot"
}
inspectInitialized = false
local InspectFontStrings = {}

function MyAddon.SlashHandler(cmd)
  if cmd == "frames" then
    MyAddon.moveFrames()
  end
end

function MyAddon.OnEvent(self, event, ...)
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
    InspectFontStrings["itemLevel"]:SetPoint("BOTTOMRIGHT", -5, 5)
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

function events:GOSSIP_SHOW()
  local isNecroticWake = GetZoneText() == 'The Necrotic Wake'
  local isSteward = GetUnitName('npc') == 'Steward'

  if isNecroticWake and isSteward then MyAddon.activateGoliath() end
end

function events:CHAT_MSG_PARTY_LEADER(message, ...)
  if message == '!keys' then
    MyAddon.announceKey()
  end
end

function events:CHAT_MSG_PARTY(message, ...)
  if message == '!keys' then
    MyAddon.announceKey()
  end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(...)
  MyAddon.announceTaunts(CombatLogGetCurrentEventInfo())
end

function events:MERCHANT_SHOW(...)
  -- Sell all gray items
  MyAddon.sellGrayItems()

  -- Repair if we need to and merchant allows it
  if CanMerchantRepair() and MyAddon.needsRepair() then
    RepairAllItems(CanGuildBankRepair())
    print("Your items have been repaired")
  end
end

function events:PLAYER_LOGIN(...)
  -- found from some forums
  local b=ActionButton8 _MH=_MH or(b:SetAttribute("*type5","macro")or SecureHandlerWrapScript(b,"PreClick",b,'Z=IsAltKeyDown()and 0 or(Z or 0)%8+1 self:SetAttribute("macrotext5","/wm [nomod]"..Z)'))or 1

  QuickJoinToastButton:Hide()
  ChatFrameChannelButton:Hide()
  ChatFrameMenuButton:Hide()
  ChatFrame1ButtonFrame:Hide()

  -- ChatFrame1.ScrollBar:Hide()
  -- ChatFrame1.ScrollToBottomButton:Hide()

  ChatFrame1:SetWidth(400)
  ChatFrame1:SetHeight(150)

  ChatFrame1:ClearAllPoints()
  ChatFrame1:SetClampRectInsets(0, 0, 0, 0)
  ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)

  ChatFrame1EditBox:ClearAllPoints()
  ChatFrame1EditBox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 0)
  ChatFrame1EditBox:SetPoint("RIGHT", ChatFrame1, 0, 0)

  ChatFrame1:SetUserPlaced(true)
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
  if MyAddon.amTankInParty() then MyAddon.markSelfSquare() end
end

function events:PLAYER_UPDATE_RESTING(...)
  -- Notify that we should repair
  if MyAddon.needsRepair() then StaticPopup_Show("REPAIR_ALERT") end
end

function MyAddon.moveFrames()
  print("Moving frames to MyAddon default locations")
  PlayerFrame:ClearAllPoints()
  PlayerFrame:SetPoint("CENTER",UIParent,-350,-225)PlayerFrame:SetUserPlaced(true)

  TargetFrame:ClearAllPoints()
  TargetFrame:SetPoint("CENTER",UIParent,350,-225)TargetFrame:SetUserPlaced(true)

  FocusFrame:ClearAllPoints()
  FocusFrame:SetPoint("CENTER",UIParent,-350,150)TargetFrame:SetUserPlaced(true)
end

function MyAddon.announceKey()
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag)do
      itemID = GetContainerItemID(bag, slot)
      if GetContainerItemID(bag, slot) == MyAddon.keyItemID then
        local link = GetContainerItemLink(bag, slot)
        SendChatMessage(link, "PARTY")

        return
      end
    end
  end
end

function MyAddon.announceTaunts(...)
  event = select(2, ...)
  spellId = select(12, ...)

  if event ~= 'SPELL_CAST_SUCCESS' or MyAddon.taunts[spellId] ~= true then
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

function MyAddon.activateGoliath()
  options = C_GossipInfo.GetOptions()

  found = false
  for k, v in pairs(options) do
    if v['name'] == 'Can you reactivate this goliath?' then
      found = true
      C_GossipInfo.SelectOption(k)
      break
    end
  end

  if not found then StaticPopup_Show("GOLIATH_MISSING") end
end

function MyAddon.needsRepair()
  for slot = 1, #MyAddon.slots do
    local id = GetInventorySlotInfo(MyAddon.slots[slot])
    local cur, max = GetInventoryItemDurability(id)

    if max and cur ~= max then return true end
  end

  return false
end

function MyAddon.sellGrayItems()
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

function MyAddon.amTankInParty()
  local isParty = UnitInRaid("player") == nil
  local isTank = UnitGroupRolesAssigned("player") == "TANK"
  local notAlreadyMarked = GetRaidTargetIndex("player") == nil

  return isParty and isTank and notAlreadyMarked
end

function MyAddon.markSelfSquare()
  SetRaidTarget("player", 6)
end

-- Register events
for event, method in pairs(events) do
  f:RegisterEvent(event)
end
f:SetScript("OnEvent", MyAddon.OnEvent)

--[[ hooksecurefunc("TalkingHeadFrame_PlayCurrent", function()
  TalkingHeadFrame:Hide()
end) ]]--

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

for i = 1, 7 do
  local chat = _G["ChatFrame"..i]
  local font, size = chat:GetFont()
  chat:SetFont(font, size, "THINOUTLINE")
  chat:SetShadowOffset(0, 0)
  chat:SetShadowColor(0, 0, 0, 0)
end

SlashCmdList["MYADDON"] = MyAddon.SlashHandler
