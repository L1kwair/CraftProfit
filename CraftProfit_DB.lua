CraftProfit = CraftProfit or {}

function CraftProfit.RegisterItem(itemID, itemLink, icon)
    if not itemID or not itemLink then return end
    if CraftProfitDB.items[itemID] then return end

    CraftProfitDB.items[itemID] = {
        name = itemLink:match("%[(.-)%]") or itemLink,
        itemLink = itemLink,
        icon = icon,
    }
end
