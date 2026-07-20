local ICON_GOLD = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14|t"
local ICON_SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14|t"
local ICON_COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14|t"

function CraftProfit.FormatPrice(copper)
    copper = math.floor(copper + 0.5)
    local gold = math.floor(math.abs(copper) / 10000)
    local silver = math.floor((math.abs(copper) % 10000) / 100)
    local cop = math.abs(copper) % 100
    local sign = copper < 0 and "-" or ""
    return sign .. gold .. ICON_GOLD .. " " .. silver .. ICON_SILVER .. " " .. cop .. ICON_COPPER
end
