-- Main window: shell, layout and wiring between the two panels.

local WINDOW_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local mainFrame = nil

function CraftProfit.ToggleMainWindow()
    if not mainFrame then
        mainFrame = CraftProfit.CreateMainWindow()
    end

    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

function CraftProfit.CreateMainWindow()
    local f = CreateFrame("Frame", "CraftProfitFrame", UIParent, "BackdropTemplate")
    f:SetSize(700, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop(WINDOW_BACKDROP)
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    table.insert(UISpecialFrames, "CraftProfitFrame")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("CraftProfit")

    -- Right panel first: the inventory callback below needs to reference it.
    local recipePanel = CraftProfit.CreateRecipePanel(f)
    recipePanel:SetPoint("TOPLEFT", f, "TOP", 5, -35)
    recipePanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)

    local inventoryPanel = CraftProfit.CreateInventoryPanel(f, function(itemID)
        recipePanel:SetRecipes(CraftProfit.GetRecipesForReagent(itemID))
    end)
    inventoryPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -35)
    inventoryPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -5, 10)

    f:SetScript("OnShow", function()
        inventoryPanel:Refresh()
        recipePanel:Refresh()
    end)

    CraftProfit.RefreshUI = function()
        if f:IsShown() then
            inventoryPanel:Refresh()
            recipePanel:Refresh()
        end
    end

    f:Hide()
    return f
end

SLASH_CRAFTPROFIT1 = "/craftprofit"
SLASH_CRAFTPROFIT2 = "/cp"
SlashCmdList["CRAFTPROFIT"] = function()
    CraftProfit.ToggleMainWindow()
end
