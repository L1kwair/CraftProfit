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

-- Bags minus what the craft queue reserves. [itemID] = count.
-- Can be negative: those reagents have to be bought or farmed.
-- Rebuilt once per refresh, never cached.
function CraftProfit.GetFreeStock()
    local free = {}

    for itemID, count in pairs(CraftProfitDB.inventory) do
        free[itemID] = count
    end

    for spellID, qty in pairs(CraftProfitDB.craftQueue) do
        local recipe = CraftProfitDB.recipes[spellID]
        if recipe then
            for _, reagent in ipairs(recipe.reagents) do
                local reserved = reagent.count * qty
                free[reagent.itemID] = (free[reagent.itemID] or 0) - reserved
            end
        end
    end

    return free
end

-- How many times this recipe can be crafted out of a given stock.
-- stock defaults to the raw bags (queue ignored); pass GetFreeStock() otherwise.
-- Not clamped to zero on purpose: GetMaxQueueable needs the negative value.
function CraftProfit.CalculateCraftable(recipe, stock)
    if not stock then
        stock = CraftProfitDB.inventory
    end

    local minCraftable = math.huge
    for _, reagent in ipairs(recipe.reagents) do
        local owned = stock[reagent.itemID] or 0
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
