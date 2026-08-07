-- Craft queue: the only module allowed to write into CraftProfitDB.craftQueue.
-- A quantity of 0 is not stored, the entry is removed from the table.

function CraftProfit.GetQueue(spellID)
    if not spellID then return 0 end
    return CraftProfitDB.craftQueue[spellID] or 0
end

-- Returns how many times this recipe can be planned at most.
-- Defaults to the stock left once the craft queue took its share; when free is
-- given, the count is computed on that table instead.
function CraftProfit.GetMaxQueueable(spellID, free)
    if not spellID then return 0 end

    local recipe = CraftProfitDB.recipes[spellID]
    if not recipe then return 0 end

    if not free then
        free = CraftProfit.GetFreeStock()
    end

    local max = CraftProfit.CalculateCraftable(recipe, free) + CraftProfit.GetQueue(spellID)
    if max < 0 then max = 0 end

    return max
end

-- Sets the planned quantity, clamped to [0, GetMaxQueueable].
function CraftProfit.SetQueue(spellID, qty)
    if not spellID then return 0 end

    local recipe = CraftProfitDB.recipes[spellID]
    if not recipe then return 0 end

    qty = math.floor(tonumber(qty) or 0)

    local max = CraftProfit.GetMaxQueueable(spellID)
    if qty > max then qty = max end

    if qty <= 0 then
        CraftProfitDB.craftQueue[spellID] = nil
        return 0
    end

    CraftProfitDB.craftQueue[spellID] = qty
    return qty
end

function CraftProfit.AddQueue(spellID, delta)
    return CraftProfit.SetQueue(spellID, CraftProfit.GetQueue(spellID) + delta)
end

function CraftProfit.MaxQueue(spellID)
    if not spellID then return 0 end

    local recipe = CraftProfitDB.recipes[spellID]
    if not recipe then return 0 end

    return CraftProfit.SetQueue(spellID, CraftProfit.GetMaxQueueable(spellID))
end
