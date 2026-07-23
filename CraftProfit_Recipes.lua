function CraftProfit.ScanRecipes()
    local professionName = GetTradeSkillLine()
    local numSkills = GetNumTradeSkills()

    CraftProfitDB.professions[professionName] = {}
    local count = 0
    local incomplete = false

    for i = 1, numSkills do
        local name, skillType = GetTradeSkillInfo(i)

        if skillType ~= "header" then
            local itemLink = GetTradeSkillItemLink(i)
            local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
            local recipeLink = GetTradeSkillRecipeLink(i)
            local spellID = recipeLink and tonumber(recipeLink:match("enchant:(%d+)"))
            local itemIcon = GetTradeSkillIcon(i)
            local minMade, maxMade = GetTradeSkillNumMade(i)
            local numReagents = GetTradeSkillNumReagents(i)
            local reagents = {}

            if not itemID or not spellID then
                incomplete = true
            end

            for j = 1, numReagents do
                local reagentName, reagentTexture, reagentCount = GetTradeSkillReagentInfo(i, j)
                local reagentLink = GetTradeSkillReagentItemLink(i, j)
                local reagentID = reagentLink and tonumber(reagentLink:match("item:(%d+)"))

                if reagentName and reagentID then
                    reagents[j] = {
                        itemID = reagentID,
                        count = reagentCount,
                    }
                    CraftProfit.RegisterItem(reagentID)
                else
                    incomplete = true
                end
            end

            if spellID then
                CraftProfitDB.recipes[spellID] = {
                    itemID = itemID,
                    profession = professionName,
                    minMade = minMade,
                    maxMade = maxMade,
                    reagents = reagents,
                }

                if itemID then
                    CraftProfitDB.itemToRecipe[itemID] = CraftProfitDB.itemToRecipe[itemID] or {}
                    table.insert(CraftProfitDB.itemToRecipe[itemID], spellID)
                    CraftProfit.RegisterItem(itemID)
                end

                count = count + 1
                table.insert(CraftProfitDB.professions[professionName], spellID)
            end
        end
    end

    CraftProfit.needsRescan = incomplete

    if not incomplete then
        CraftProfit.Debug(professionName .. " : scan complet, " .. count .. " recettes trouvees")
    else
        CraftProfit.Debug(professionName .. " : scan partiel, en attente de donnees...")
    end
end
