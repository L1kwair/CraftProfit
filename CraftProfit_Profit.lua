local CUT_AH = 0.05

function CraftProfit.CalculateCraftCost(recipe)
    local totalCost = 0
    for _, reagent in ipairs(recipe.reagents) do
        if not reagent.itemID then
            return nil
        end
        local reagentPrice = CraftProfit.GetPrice(reagent.itemID)
        if not reagentPrice then
            return nil
        end
        totalCost = totalCost + (reagentPrice * reagent.count)
    end
    return totalCost
end

function CraftProfit.CalculateProfit(recipe)
    local sellPrice = CraftProfit.GetPrice(recipe.itemID)
    if not sellPrice then
        return nil
    end

    local craftCost = CraftProfit.CalculateCraftCost(recipe)
    if not craftCost then
        return nil
    end

    local quantity = math.ceil((recipe.minMade + recipe.maxMade) / 2)

    return {
        sellPrice = sellPrice,
        craftCost = craftCost,
        profit = sellPrice * quantity * (1 - CUT_AH) - craftCost
    }
end

function CraftProfit.ScanProfits(professionName)
    local spellIDs = CraftProfitDB.professions[professionName]
    if not spellIDs then
        CraftProfit.Debug("Aucune recette pour " .. professionName)
        return
    end

    for _, spellID in ipairs(spellIDs) do
        local recipe = CraftProfitDB.recipes[spellID]
        if recipe then
            local item = CraftProfitDB.items[recipe.itemID]
            local name = item and item.name or "?"
            local result = CraftProfit.CalculateProfit(recipe)
            if result then
                CraftProfit.Debug(name
                    .. " | Vente: " .. result.sellPrice
                    .. " | Craft: " .. result.craftCost
                    .. " | Profit: " .. result.profit)
            else
                CraftProfit.Debug(name .. " | Prix inconnu")
            end
        end
    end
end
