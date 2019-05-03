Tracker:AddItems("items/bosses.json")
Tracker:AddItems("items/unique.json")

if (string.find(Tracker.ActiveVariantUID, "hard")) then
    Tracker:AddItems("items/tanks_hard.json")
  else
    Tracker:AddItems("items/tanks_normal.json")
end

Tracker:AddLayouts("layouts/shared/items.json")
Tracker:AddLayouts("layouts/shared/bosses.json")
Tracker:AddLayouts("layouts/shared/shared_grid.json")

Tracker:AddLayouts("layouts/layout.json")

ScriptHost:LoadScript("scripts/autotracking.lua")