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
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
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

    local currentRecipes = {}
    local UpdateRecipeList
    local selectedItemID = nil

    -- Panneau gauche
    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -35)
    leftPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -5, 10)
    leftPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    leftPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.7)

    local ICON_SIZE = 37
    local ICON_SPACING = 2
    local ICONS_PER_ROW = 7
    local VISIBLE_ROWS = 11
    local ROW_HEIGHT_LEFT = ICON_SIZE + ICON_SPACING

    local scrollFrame = CreateFrame("ScrollFrame", nil, leftPanel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -30, 8)

    local collapsedCategories = {}
    local displayRows = {}
    local UpdateItemGrid

    local slots = {}
    for i = 1, VISIBLE_ROWS do
        local anchor = CreateFrame("Frame", nil, leftPanel)
        anchor:SetHeight(ROW_HEIGHT_LEFT)

        if i == 1 then
            anchor:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -8)
        else
            anchor:SetPoint("TOPLEFT", slots[i - 1].anchor, "BOTTOMLEFT", 0, 0)
        end
        anchor:SetPoint("RIGHT", leftPanel, "RIGHT", -30, 0)

        local header = CreateFrame("Button", nil, anchor)
        header:SetAllPoints()

        header.bg = header:CreateTexture(nil, "BACKGROUND")
        header.bg:SetAllPoints()
        header.bg:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
        header.bg:SetVertexColor(0.4, 0.35, 0.2, 0.8)

        header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header.text:SetPoint("LEFT", header, "LEFT", 6, 0)
        header.text:SetJustifyH("LEFT")

        header.highlight = header:CreateTexture(nil, "HIGHLIGHT")
        header.highlight:SetAllPoints()
        header.highlight:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
        header.highlight:SetVertexColor(0.6, 0.5, 0.3, 0.3)

        header:SetScript("OnClick", function(self)
            collapsedCategories[self.categoryName] = not collapsedCategories[self.categoryName]
            UpdateItemGrid()
        end)

        header:Hide()

        local btns = {}
        for j = 1, ICONS_PER_ROW do
            local btn = CraftProfit.CreateItemButton(anchor, ICON_SIZE)
            if j == 1 then
                btn:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
            else
                btn:SetPoint("TOPLEFT", btns[j - 1], "TOPRIGHT", ICON_SPACING, 0)
            end

            btn:SetScript("OnClick", function(self)
                if selectedItemID == self.itemID then
                    selectedItemID = nil
                    currentRecipes = {}
                else
                    selectedItemID = self.itemID
                    currentRecipes = CraftProfit.SortRecipesByCraftability(CraftProfit.FindRecipesByReagent(self.itemID))
                end
                UpdateItemGrid()
                UpdateRecipeList()
            end)

            btn:Hide()
            btns[j] = btn
        end

        slots[i] = {
            anchor = anchor,
            header = header,
            buttons = btns,
        }
    end

    local function BuildDisplayRows()
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

        displayRows = {}
        for _, catName in ipairs(categoryNames) do
            local items = categoryItems[catName]
            table.insert(displayRows, { type = "header", name = catName, count = #items })
            if not collapsedCategories[catName] then
                for startIdx = 1, #items, ICONS_PER_ROW do
                    local rowItems = {}
                    for j = startIdx, math.min(startIdx + ICONS_PER_ROW - 1, #items) do
                        table.insert(rowItems, items[j])
                    end
                    table.insert(displayRows, { type = "items", items = rowItems })
                end
            end
        end
    end

    UpdateItemGrid = function()
        BuildDisplayRows()

        local numRows = #displayRows
        FauxScrollFrame_Update(scrollFrame, numRows, VISIBLE_ROWS, ROW_HEIGHT_LEFT)
        local offset = FauxScrollFrame_GetOffset(scrollFrame)

        for i = 1, VISIBLE_ROWS do
            local slot = slots[i]
            local dataIndex = i + offset

            slot.header:Hide()
            for j = 1, ICONS_PER_ROW do
                slot.buttons[j]:Hide()
            end

            if dataIndex <= numRows then
                local row = displayRows[dataIndex]

                if row.type == "header" then
                    local arrow = collapsedCategories[row.name] and "> " or "v "
                    slot.header.text:SetText(arrow .. row.name .. " (" .. row.count .. ")")
                    slot.header.categoryName = row.name
                    slot.header:Show()
                else
                    for j = 1, ICONS_PER_ROW do
                        local btn = slot.buttons[j]
                        local item = row.items[j]
                        if item then
                            btn.icon:SetTexture(GetItemIcon(item.itemID))
                            btn.itemID = item.itemID
                            btn.itemLink = item.itemLink

                            if item.count > 1 then
                                btn.count:SetText(item.count)
                                btn.count:Show()
                            else
                                btn.count:Hide()
                            end

                            if item.itemID == selectedItemID then
                                btn.selected:Show()
                            else
                                btn.selected:Hide()
                            end

                            btn:Show()
                        end
                    end
                end
            end
        end
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT_LEFT, UpdateItemGrid)
    end)

    -- Panneau droit
    local rightPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rightPanel:SetPoint("TOPLEFT", f, "TOP", 5, -35)
    rightPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    rightPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    rightPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.7)

    local ROW_HEIGHT = 80
    local NUM_VISIBLE_ROWS = 5
    local RECIPE_ICON_SIZE = 32
    local REAGENT_ICON_SIZE = 20
    local MAX_REAGENTS = 8

    local rightScrollFrame = CreateFrame("ScrollFrame", nil, rightPanel, "FauxScrollFrameTemplate")
    rightScrollFrame:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -8)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -30, 8)

    local rows = {}
    for i = 1, NUM_VISIBLE_ROWS do
        local row = CraftProfit.CreateRecipeRow(rightPanel, RECIPE_ICON_SIZE, REAGENT_ICON_SIZE, MAX_REAGENTS)
        row:SetSize(300, ROW_HEIGHT)

        if i == 1 then
            row:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 8, -8)
            row:SetPoint("RIGHT", rightPanel, "RIGHT", -30, 0)
        else
            row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -2)
            row:SetPoint("RIGHT", rightPanel, "RIGHT", -30, 0)
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

        row.qtyInput:SetScript("OnEnterPressed", function(self)
            if not row.spellID then return end
            local recipe = CraftProfitDB.recipes[row.spellID]
            local craftable = CraftProfit.CalculateCraftable(recipe)
            local val = tonumber(self:GetText()) or 0
            if val > craftable then val = craftable end
            if val <= 0 then
                CraftProfitDB.craftQueue[row.spellID] = nil
                self:SetText("0")
            else
                CraftProfitDB.craftQueue[row.spellID] = val
            end
            self:ClearFocus()
        end)

        row.qtyInput:SetScript("OnEditFocusLost", function(self)
            if not row.spellID then return end
            local recipe = CraftProfitDB.recipes[row.spellID]
            local craftable = CraftProfit.CalculateCraftable(recipe)
            local val = tonumber(self:GetText()) or 0
            if val > craftable then val = craftable end
            if val <= 0 then
                CraftProfitDB.craftQueue[row.spellID] = nil
                self:SetText("0")
            else
                CraftProfitDB.craftQueue[row.spellID] = val
            end
        end)

        row.addBtn:SetScript("OnClick", function()
            if not row.spellID then return end
            local recipe = CraftProfitDB.recipes[row.spellID]
            local craftable = CraftProfit.CalculateCraftable(recipe)
            local current = CraftProfitDB.craftQueue[row.spellID] or 0
            if current < craftable then
                CraftProfitDB.craftQueue[row.spellID] = current + 1
                row.qtyInput:SetText(current + 1)
            end
        end)

        row.removeBtn:SetScript("OnClick", function()
            if not row.spellID then return end
            local current = CraftProfitDB.craftQueue[row.spellID] or 0
            if current <= 1 then
                CraftProfitDB.craftQueue[row.spellID] = nil
                row.qtyInput:SetText("0")
            else
                CraftProfitDB.craftQueue[row.spellID] = current - 1
                row.qtyInput:SetText(current - 1)
            end
        end)

        row.maxBtn:SetScript("OnClick", function()
            if not row.spellID then return end
            local recipe = CraftProfitDB.recipes[row.spellID]
            local craftable = CraftProfit.CalculateCraftable(recipe)
            if craftable > 0 then
                CraftProfitDB.craftQueue[row.spellID] = craftable
                row.qtyInput:SetText(craftable)
            end
        end)

        rows[i] = row
    end

    UpdateRecipeList = function()
        local numItems = #currentRecipes

        FauxScrollFrame_Update(rightScrollFrame, numItems, NUM_VISIBLE_ROWS, ROW_HEIGHT + 2)

        local offset = FauxScrollFrame_GetOffset(rightScrollFrame)

        for i = 1, NUM_VISIBLE_ROWS do
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
                row.qtyInput:SetText(CraftProfitDB.craftQueue[spellID] or 0)

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

    rightScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT + 2, UpdateRecipeList)
    end)

    f:SetScript("OnShow", function()
        UpdateItemGrid()
    end)

    CraftProfit.RefreshUI = function()
        if f:IsShown() then
            UpdateItemGrid()
            UpdateRecipeList()
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
