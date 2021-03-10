local f = CreateFrame("Frame")

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

f:RegisterEvent("GOSSIP_SHOW")

f:SetScript("OnEvent", function(self, event, ...)
  local isNecroticWake = GetZoneText() == "The Necrotic Wake"
  local isSteward = GetUnitName("npc") == "Steward"

  if isNecroticWake and isSteward then
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
end)
