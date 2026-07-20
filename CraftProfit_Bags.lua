local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetItemInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo

function CraftProfit.ScanBags()
    CraftProfitDB.inventory = {}

    for bagID = 0, 4 do
        local numSlots = GetNumSlots(bagID)
        for slot = 1, numSlots do
            local info = GetItemInfo(bagID, slot)
            if info then
                local itemID = info.itemID
                local count = info.stackCount or 1
                local link = info.itemLink or info.hyperlink

                CraftProfitDB.inventory[itemID] = (CraftProfitDB.inventory[itemID] or 0) + count
                CraftProfit.RegisterItem(itemID, link, info.iconFileID)
            end
        end
    end

    CraftProfit.Debug("Inventaire scanne")
    CraftProfit.Debug(CraftProfitDB.inventory)
end
