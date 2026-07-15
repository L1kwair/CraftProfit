local CUT_AH = 0.05

function CraftProfit.CalculateProfit(recipe)

    local sellPrice = CraftProfit.GetPrice(recipe.itemID)
    if not sellPrice then
        return nil
    end
    
    local craftCost = 0
    for _, reagent in ipairs(recipe.reagents) do
        if not reagent.itemID then
            return nil
        end
        local reagentPrice = CraftProfit.GetPrice(reagent.itemID)
        if not reagentPrice then
            return nil
        end
        craftCost = craftCost + (reagentPrice * reagent.count)
    end

    return {
        sellPrice = sellPrice,
        craftCost = craftCost,
        profit = sellPrice * math.ceil((recipe.minMade + recipe.maxMade) / 2) * (1 - CUT_AH) - craftCost
    }
end

function CraftProfit.ScanProfits(professionName)
    if not CraftProfitDB.recipes or not CraftProfitDB.recipes[professionName] then
        CraftProfit.Debug("Aucune recette pour " .. professionName)
        return
    end

    local recipes = CraftProfitDB.recipes[professionName]

    for i, recipe in ipairs(recipes) do
        local result = CraftProfit.CalculateProfit(recipe)
        if result then
            CraftProfit.Debug(recipe.name
                .. " | Vente: " .. result.sellPrice
                .. " | Craft: " .. result.craftCost
                .. " | Profit: " .. result.profit)
        else
            CraftProfit.Debug(recipe.name .. " | Prix inconnu")
        end
    end
end
