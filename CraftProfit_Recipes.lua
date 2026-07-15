function CraftProfit.ScanRecipes()
    local professionName = GetTradeSkillLine()
    local numSkills = GetNumTradeSkills()

    if not CraftProfitDB.recipes then
        CraftProfitDB.recipes = {}
    end

    CraftProfitDB.recipes[professionName] = {}
    local count = 0
    local incomplete = false

    for i = 1, numSkills do
        local name, skillType = GetTradeSkillInfo(i)

        if skillType ~= "header" then
            local itemLink = GetTradeSkillItemLink(i)
            local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
            local minMade, maxMade = GetTradeSkillNumMade(i)
            local numReagents = GetTradeSkillNumReagents(i)
            local reagents = {}

            if not itemID then
                incomplete = true
            end

            for j = 1, numReagents do
                local reagentName, reagentTexture, reagentCount = GetTradeSkillReagentInfo(i, j)
                local reagentLink = GetTradeSkillReagentItemLink(i, j)
                local reagentID = reagentLink and tonumber(reagentLink:match("item:(%d+)"))

                if reagentName then
                    reagents[j] = {
                        name = reagentName,
                        icon = reagentTexture,
                        count = reagentCount,
                        itemID = reagentID
                    }
                    if not reagentID then
                        incomplete = true
                    end
                else
                    incomplete = true
                end
            end

            count = count + 1
            CraftProfitDB.recipes[professionName][count] = {
                name = name,
                itemLink = itemLink,
                itemID = itemID,
                minMade = minMade,
                maxMade = maxMade,
                reagents = reagents
            }
        end
    end

    CraftProfit.needsRescan = incomplete

    if not incomplete then
        CraftProfit.Debug(professionName .. " : scan complet, " .. count .. " recettes trouvees")
    else
        CraftProfit.Debug(professionName .. " : scan partiel, en attente de donnees...")
    end
end
