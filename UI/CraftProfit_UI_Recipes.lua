-- Right panel: list of recipes, with profit, craftable count, reagents and
-- the craft queue controls.
-- This module FILLS the panel, it does not PLACE it: the SetPoint calls stay
-- in CraftProfit_UI.lua, the only file that knows the window layout.
-- The panel knows nothing about the item grid, it only receives a list of spellIDs.

local PANEL_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local ROW_HEIGHT = 80
local ROW_SPACING = 2
local VISIBLE_ROWS = 5
local RECIPE_ICON_SIZE = 32
local REAGENT_ICON_SIZE = 20
local MAX_REAGENTS = 8

function CraftProfit.CreateRecipePanel(parent)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetBackdrop(PANEL_BACKDROP)
    panel:SetBackdropColor(0.05, 0.05, 0.05, 0.7)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 8)

    -- Recipes currently displayed, set by SetRecipes.
    local currentRecipes = {}

    -- Forward declaration: the queue buttons below call UpdateRecipeList.
    local UpdateRecipeList

    local rows = {}
    for i = 1, VISIBLE_ROWS do
        local row = CraftProfit.CreateRecipeRow(panel, RECIPE_ICON_SIZE, REAGENT_ICON_SIZE, MAX_REAGENTS)
        row:SetSize(300, ROW_HEIGHT)

        if i == 1 then
            row:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
            row:SetPoint("RIGHT", panel, "RIGHT", -30, 0)
        else
            row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -ROW_SPACING)
            row:SetPoint("RIGHT", panel, "RIGHT", -30, 0)
        end

        row.addBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.addBtn:SetSize(26, 22)
        row.addBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -31, -4)
        row.addBtn:SetText("+")

        row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.removeBtn:SetSize(26, 22)
        row.removeBtn:SetPoint("LEFT", row.addBtn, "RIGHT", 5, 0)
        row.removeBtn:SetText("-")

        row.maxBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.maxBtn:SetSize(57, 22)
        row.maxBtn:SetPoint("TOPLEFT", row.addBtn, "BOTTOMLEFT", 0, -2)
        row.maxBtn:SetText("Max")
        row.maxBtn:GetFontString():SetFont(GameFontNormal:GetFont(), 9)

        row.qtyInput = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        row.qtyInput:SetSize(57, 22)
        row.qtyInput:SetPoint("TOPLEFT", row.maxBtn, "BOTTOMLEFT", 6, -2)
        row.qtyInput:SetAutoFocus(false)
        row.qtyInput:SetNumeric(true)
        row.qtyInput:SetText("0")
        row.qtyInput:SetMaxLetters(3)

        -- CraftQueue clamps the quantity and returns what it kept,
        -- so there is nothing to recompute here, we just display the answer.
        row.qtyInput:SetScript("OnEnterPressed", function(self)
            if row.spellID then
                self:SetText(CraftProfit.SetQueue(row.spellID, self:GetText()))
            end
            self:ClearFocus()
        end)

        row.qtyInput:SetScript("OnEditFocusLost", function(self)
            if row.spellID then
                self:SetText(CraftProfit.SetQueue(row.spellID, self:GetText()))
            end
        end)

        row.addBtn:SetScript("OnClick", function()
            if not row.spellID then return end
            row.qtyInput:SetText(CraftProfit.AddQueue(row.spellID, 1))
        end)

        row.removeBtn:SetScript("OnClick", function()
            if not row.spellID then return end
            row.qtyInput:SetText(CraftProfit.AddQueue(row.spellID, -1))
        end)

        row.maxBtn:SetScript("OnClick", function()
            if not row.spellID then return end
            row.qtyInput:SetText(CraftProfit.MaxQueue(row.spellID))
        end)

        rows[i] = row
    end

    UpdateRecipeList = function()
        local numItems = #currentRecipes

        FauxScrollFrame_Update(scrollFrame, numItems, VISIBLE_ROWS, ROW_HEIGHT + ROW_SPACING)

        local offset = FauxScrollFrame_GetOffset(scrollFrame)

        for i = 1, VISIBLE_ROWS do
            local row = rows[i]
            local index = i + offset

            if index <= numItems then
                local spellID = currentRecipes[index]
                row.spellID = spellID
                local recipe = CraftProfitDB.recipes[spellID]
                local item = CraftProfitDB.items[recipe.itemID]
                local name = item and item.name or "?"
                local itemLink = item and item.itemLink or nil

                row.product.icon:SetTexture(GetItemIcon(recipe.itemID))
                row.product.itemLink = itemLink
                row.name:SetText(name)
                row.qtyInput:SetText(CraftProfit.GetQueue(spellID))

                local result = CraftProfit.CalculateProfit(recipe)
                if result then
                    local quantity = math.ceil((recipe.minMade + recipe.maxMade) / 2)
                    local profitUnit = result.profit / quantity
                    row.profit:SetText(CraftProfit.FormatPrice(profitUnit))
                    if profitUnit < 0 then
                        row.profit:SetTextColor(1, 0, 0)
                    else
                        row.profit:SetTextColor(0, 1, 0)
                    end
                else
                    row.profit:SetText("Prix inconnu")
                    row.profit:SetTextColor(0.5, 0.5, 0.5)
                end

                local craftable = CraftProfit.CalculateCraftable(recipe)
                row.maxBtn:SetText("Max (" .. craftable .. ")")

                if craftable > 0 then
                    row:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
                    row:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
                    row.name:SetTextColor(1, 0.82, 0)
                    row.product.icon:SetDesaturated(false)
                    row.product.icon:SetAlpha(1)
                else
                    row:SetBackdropColor(0.08, 0.08, 0.08, 0.6)
                    row:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.6)
                    row.name:SetTextColor(0.4, 0.4, 0.4)
                    row.product.icon:SetDesaturated(true)
                    row.product.icon:SetAlpha(0.6)
                end

                for j = 1, MAX_REAGENTS do
                    local r = row.reagents[j]
                    local reagent = recipe.reagents[j]
                    if reagent then
                        r.icon:SetTexture(GetItemIcon(reagent.itemID))
                        local reagentItem = CraftProfitDB.items[reagent.itemID]
                        r.itemLink = reagentItem and reagentItem.itemLink or nil
                        local owned = CraftProfitDB.inventory[reagent.itemID] or 0
                        r.qty:SetText(owned .. "/" .. reagent.count)
                        if owned >= reagent.count then
                            r.qty:SetTextColor(0, 1, 0)
                            r.icon:SetDesaturated(false)
                            r.icon:SetAlpha(1)
                        else
                            r.qty:SetTextColor(1, 0, 0)
                            r.icon:SetDesaturated(true)
                            r.icon:SetAlpha(0.6)
                        end
                        r:Show()
                    else
                        r:Hide()
                    end
                end

                row:Show()
            else
                for j = 1, MAX_REAGENTS do
                    row.reagents[j]:Hide()
                end
                row:Hide()
            end
        end
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT + ROW_SPACING, UpdateRecipeList)
    end)

    -- spellIDs is the list to display, already sorted by the caller.
    function panel:SetRecipes(spellIDs)
        currentRecipes = spellIDs
        UpdateRecipeList()
    end

    -- Redraw the current list, for instance after the bags changed.
    function panel:Refresh()
        UpdateRecipeList()
    end

    return panel
end
