GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end

    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end

    local spellIDs = CraftProfitDB.itemToRecipe[itemID]
    if not spellIDs then return end

    local recipe = CraftProfitDB.recipes[spellIDs[1]]
    if not recipe then return end

    local result = CraftProfit.CalculateProfit(recipe)
    if not result then return end

    local quantity = math.ceil((recipe.minMade + recipe.maxMade) / 2)
    local craftCostUnit = result.craftCost / quantity
    local profitUnit = result.profit / quantity

    tooltip:AddDoubleLine("Craft", CraftProfit.FormatPrice(craftCostUnit), 1, 0.8, 0, 1, 1, 1)
    local pr, pg, pb = 0, 1, 0
    if profitUnit < 0 then pr, pg, pb = 1, 0, 0 end
    tooltip:AddDoubleLine("Profit", CraftProfit.FormatPrice(profitUnit), 1, 0.8, 0, pr, pg, pb)
    tooltip:Show()
end)
