local frame = CreateFrame("frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_CLOSE")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("BANKFRAME_CLOSED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("CraftProfit charge avec succes !")

        if CraftProfitDB == nil then
            CraftProfitDB = {
                loginCount = 0,
                items = {},
                recipes = {}
            }
            CraftProfit.Debug("Premiere utilisation, base creee")
        else
            CraftProfit.Debug("Base existante chargee")
        end

        CraftProfitDB.loginCount = CraftProfitDB.loginCount + 1
        CraftProfit.Debug("Connexion numero : " .. CraftProfitDB.loginCount)

        CraftProfit.ScanBags()

        if CraftProfitDB.recipes then
            local count = 0
            for _ in pairs(CraftProfitDB.recipes) do count = count + 1 end
            CraftProfit.Debug("Recettes en memoire : " .. count)
        else
            CraftProfit.Debug("Aucune recette en memoire")
        end
    end

    if event == "TRADE_SKILL_SHOW" then
        CraftProfit.ScanRecipes()
    end

    if event == "BANKFRAME_OPENED" then
        CraftProfit.ScanBank()
    end

    if event == "BANKFRAME_CLOSED" then
        CraftProfit.needsRescanBank = false
    end

    if event == "GET_ITEM_INFO_RECEIVED" then
        if CraftProfit.needsRescan then
            CraftProfit.ScanRecipes()
        end
        if CraftProfit.needsRescanBank then
            CraftProfit.ScanBank()
        end
    end

    if event == "TRADE_SKILL_CLOSE" then
        CraftProfit.needsRescan = false
    end
end)
