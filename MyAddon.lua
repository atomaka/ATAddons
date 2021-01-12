local f, MyAddon, events = CreateFrame("Frame"), {}, {}

StaticPopupDialogs["REPAIR_ALERT"] = {
  text = "Remember to repair your gear",
  button1 = "Ok",
  timeout = 10,
  whileDead = false,
  hideOnEscape = true,
  preferredIndex = 3
}

MyAddon.keyItemID = 180653

function MyAddon.OnEvent(self, event, ...)
  events[event](self, ...)
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

function events:PLAYER_LOGIN(...)
  -- found from some forums
  local b=ActionButton8 _MH=_MH or(b:SetAttribute("*type5","macro")or SecureHandlerWrapScript(b,"PreClick",b,'Z=IsAltKeyDown()and 0 or(Z or 0)%8+1 self:SetAttribute("macrotext5","/wm [nomod]"..Z)'))or 1
end

function events:MERCHANT_SHOW(...)
  -- Sell all gray items
  MyAddon.sellGrayItems()

  -- Repair if we need to and merchant allows it
  if CanMerchantRepair() and MyAddon.needsRepair() then
    RepairAllItems(CanGuildBankRepair())
    DEFAULT_CHAT_FRAME:AddMessage("Your items have been repaired")
  end
end

function events:PLAYER_UPDATE_RESTING(...)
  -- Notify that we should repair
  if MyAddon.needsRepair() then StaticPopup_Show("REPAIR_ALERT") end
end

function events:PLAYER_ROLES_ASSIGNED(...)
  if MyAddon.amTankInParty() then MyAddon.markSelfSquare() end
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

function MyAddon.needsRepair()
  local slots = {
    "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot",
    "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot"
  }

  for slot = 1, #slots do
    local id = GetInventorySlotInfo(slots[slot])
    local cur, max = GetInventoryItemDurability(id)

    if max and cur ~= max then return true end
  end

  return false
end

function MyAddon.sellGrayItems()
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local name = GetContainerItemLink(bag, slot)
      if name and string.find(name, "ff9d9d9d") then
        DEFAULT_CHAT_FRAME:AddMessage("Selling "..name)
        UseContainerItem(bag, slot)
      end
    end
  end
end

function MyAddon.amTankInParty()
  local isParty = UnitInRaid("player") == nil
  local isTank = UnitGroupRolesAssigned("player") == "TANK"
  local notAlreadyMarked = GetRaidTargetIndex("player") == nil

  if (isParty and isTank and notAlreadyMarked) then
    return true
  else
    return false
  end
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
