local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetItemInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo

function CraftProfit.ScanBank()
    CraftProfitDB.bank = {}
    local incomplete = false

    for _, bagID in ipairs({-1, 5, 6, 7, 8, 9, 10, 11}) do
        local numSlots = GetNumSlots(bagID)
        for slot = 1, numSlots do
            local info = GetItemInfo(bagID, slot)
            if info then
                local itemID = info.itemID
                local count = info.stackCount or 1
                local link = info.itemLink or info.hyperlink

                if itemID then
                    CraftProfitDB.bank[itemID] = (CraftProfitDB.bank[itemID] or 0) + count
                    CraftProfit.RegisterItem(itemID, link, info.iconFileID)

                    if not link then
                        incomplete = true
                    end
                end
            end
        end
    end

    CraftProfit.needsRescanBank = incomplete

    if not incomplete then
        CraftProfit.Debug("Banque : scan complet")
    else
        CraftProfit.Debug("Banque : scan partiel, en attente de donnees...")
    end
    CraftProfit.Debug(CraftProfitDB.bank)
end
