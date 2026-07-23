CraftProfit = CraftProfit or {}

function CraftProfit.RegisterItem(itemID)
    if not itemID then return end
    if CraftProfitDB.items[itemID] then return end

    local name, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    if not name then return end

    CraftProfitDB.items[itemID] = {
        name = name,
        itemLink = itemLink,
        icon = icon,
    }
end

function CraftProfit.FindRecipesByReagent(itemID)
    local results = {}
    for spellID, recipe in pairs(CraftProfitDB.recipes) do
        for _, reagent in ipairs(recipe.reagents) do
            if reagent.itemID == itemID then
                table.insert(results, spellID)
                break
            end
        end
    end
    return results
end

function CraftProfit.SortRecipesByCraftability(spellIDs)
    table.sort(spellIDs, function(a, b)
        local recipeA = CraftProfitDB.recipes[a]
        local recipeB = CraftProfitDB.recipes[b]
        local craftableA = CraftProfit.CalculateCraftable(recipeA) > 0
        local craftableB = CraftProfit.CalculateCraftable(recipeB) > 0

        if craftableA ~= craftableB then
            return craftableA
        end

        local resultA = CraftProfit.CalculateProfit(recipeA)
        local resultB = CraftProfit.CalculateProfit(recipeB)
        local profitA = resultA and resultA.profit or -math.huge
        local profitB = resultB and resultB.profit or -math.huge

        return profitA > profitB
    end)

    return spellIDs
end
