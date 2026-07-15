function CraftProfit.GetPrice(itemID)
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        return Auctionator.API.v1.GetAuctionPriceByItemID("CraftProfit", tonumber(itemID))
    end
    return nil
end
