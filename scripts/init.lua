Tracker:AddItems("items/bosses.json")
Tracker:AddItems("items/unique.json")
Tracker:AddItems("items/bingo.json")
if (string.find(Tracker.ActiveVariantUID, "hard")) then
    Tracker:AddItems("items/tanks_hard.json")
  else
    Tracker:AddItems("items/tanks_normal.json")
end

Tracker:AddLayouts("layouts/shared/bingo.json")
Tracker:AddLayouts("layouts/shared/items.json")
Tracker:AddLayouts("layouts/shared/bosses.json")
Tracker:AddLayouts("layouts/shared/layout_default.json")

Tracker:AddLayouts("layouts/tracker.json")

ScriptHost:LoadScript("scripts/autotracking.lua")