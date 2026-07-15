local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetItemInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo

function CraftProfit.ScanBags()
    CraftProfitDB.items = {}

    for bagID = 0, 4 do
        local numSlots = GetNumSlots(bagID)
        for slot = 1, numSlots do
            local info = GetItemInfo(bagID, slot)
            if info then
                local itemID = info.itemID
                local count = info.stackCount or 1
                local link = info.itemLink or info.hyperlink

                if CraftProfitDB.items[itemID] then
                    CraftProfitDB.items[itemID].count = CraftProfitDB.items[itemID].count + count
                else
                    CraftProfitDB.items[itemID] = {
                        name = link,
                        count = count
                    }
                end
            end
        end
    end

    CraftProfit.Debug("Items sauvegardes : ")
    CraftProfit.Debug(CraftProfitDB.items)
end
