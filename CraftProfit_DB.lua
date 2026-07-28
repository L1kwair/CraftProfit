CraftProfit = CraftProfit or {}

local function GetItemCategory(itemID)
    local _, _, _, _, _, itemType, _, _, _, _, _, classID = GetItemInfo(itemID)
    if not itemType then return "Autre" end

    if classID == 2 or classID == 4 then
        return "Equipement"
    end

    return itemType
end

function CraftProfit.RegisterItem(itemID)
    if not itemID then return end
    if CraftProfitDB.items[itemID] then return end

    local name, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    if not name then return end

    CraftProfitDB.items[itemID] = {
        name = name,
        itemLink = itemLink,
        icon = icon,
        category = GetItemCategory(itemID),
    }
end

-- Regroupe l'inventaire des sacs par categorie d'objet.
-- Retourne deux valeurs :
--   categoryNames : liste triee des categories ("Equipement" en tete, puis alphabetique)
--   categoryItems : table [nomCategorie] = { { itemID, count, itemLink }, ... }
-- Ne lit que les sacs pour l'instant ; la banque viendra plus tard.
function CraftProfit.GetInventoryByCategory()
    local categoryItems = {}
    local categoryNames = {}
    local categorySet = {}

    for itemID, count in pairs(CraftProfitDB.inventory) do
        local item = CraftProfitDB.items[itemID]
        local category = item and item.category or "Autre"

        if not categorySet[category] then
            categorySet[category] = true
            table.insert(categoryNames, category)
            categoryItems[category] = {}
        end

        table.insert(categoryItems[category], {
            itemID = itemID,
            count = count,
            itemLink = item and item.itemLink or nil,
        })
    end

    table.sort(categoryNames, function(a, b)
        if a == "Equipement" then return true end
        if b == "Equipement" then return false end
        return a < b
    end)

    return categoryNames, categoryItems
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

-- Combien de fois cette recette est craftable avec le contenu des sacs.
-- Vient de CraftProfit_Profit.lua : elle ne calcule aucun prix, c'est une requete
-- sur l'inventaire, et SortRecipesByCraftability juste en dessous l'utilise.
function CraftProfit.CalculateCraftable(recipe)
    local minCraftable = math.huge
    for _, reagent in ipairs(recipe.reagents) do
        local owned = CraftProfitDB.inventory[reagent.itemID] or 0
        local possible = math.floor(owned / reagent.count)
        minCraftable = math.min(minCraftable, possible)
    end
    return minCraftable
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

-- Recipes consuming this item, already sorted for display
-- (craftable ones first, then by decreasing profit).
-- A nil itemID (nothing selected) returns an empty list, not nil,
-- so the caller can always ipairs over it without a guard.
function CraftProfit.GetRecipesForReagent(itemID)
    if not itemID then return {} end

    local spellIDs = CraftProfit.FindRecipesByReagent(itemID)
    return CraftProfit.SortRecipesByCraftability(spellIDs)
end
