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
    local ICONS_PER_ROW = 8
    local VISIBLE_ROWS = 11

    local scrollFrame = CreateFrame("ScrollFrame", nil, leftPanel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -30, 8)

    local buttons = {}
    local totalSlots = ICONS_PER_ROW * VISIBLE_ROWS
    local selectedButton = nil

    for i = 1, totalSlots do
        local btn = CraftProfit.CreateItemButton(leftPanel, ICON_SIZE)

        if i == 1 then
            btn:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -8)
        elseif (i - 1) % ICONS_PER_ROW == 0 then
            btn:SetPoint("TOPLEFT", buttons[i - ICONS_PER_ROW], "BOTTOMLEFT", 0, -ICON_SPACING)
        else
            btn:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", ICON_SPACING, 0)
        end

        btn:SetScript("OnClick", function(self)
            if selectedButton then
                selectedButton.selected:Hide()
            end
            if selectedButton == self then
                selectedButton = nil
            else
                self.selected:Show()
                selectedButton = self
            end
        end)

        buttons[i] = btn
    end

    local function UpdateItemGrid()
        local itemList = {}
        for itemID, count in pairs(CraftProfitDB.inventory) do
            local item = CraftProfitDB.items[itemID]
            table.insert(itemList, {
                itemID = itemID,
                count = count,
                itemLink = item and item.itemLink or nil,
            })
        end

        local numItems = #itemList
        local numRows = math.ceil(numItems / ICONS_PER_ROW)

        FauxScrollFrame_Update(scrollFrame, numRows, VISIBLE_ROWS, ICON_SIZE + ICON_SPACING)

        local rowOffset = FauxScrollFrame_GetOffset(scrollFrame)

        for i = 1, totalSlots do
            local btn = buttons[i]
            local visibleRow = math.ceil(i / ICONS_PER_ROW) - 1
            local col = (i - 1) % ICONS_PER_ROW
            local dataIndex = (rowOffset + visibleRow) * ICONS_PER_ROW + col + 1

            if dataIndex <= numItems then
                local item = itemList[dataIndex]
                btn.icon:SetTexture(GetItemIcon(item.itemID))
                btn.itemID = item.itemID
                btn.itemLink = item.itemLink

                if item.count > 1 then
                    btn.count:SetText(item.count)
                    btn.count:Show()
                else
                    btn.count:Hide()
                end
                btn:Show()
            else
                btn:Hide()
            end
        end
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ICON_SIZE + ICON_SPACING, UpdateItemGrid)
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

        rows[i] = row
    end

    local currentRecipes = {}

    local function UpdateRecipeList()
        local numItems = #currentRecipes

        FauxScrollFrame_Update(rightScrollFrame, numItems, NUM_VISIBLE_ROWS, ROW_HEIGHT + 2)

        local offset = FauxScrollFrame_GetOffset(rightScrollFrame)

        for i = 1, NUM_VISIBLE_ROWS do
            local row = rows[i]
            local index = i + offset

            if index <= numItems then
                local spellID = currentRecipes[index]
                local recipe = CraftProfitDB.recipes[spellID]
                local item = CraftProfitDB.items[recipe.itemID]
                local name = item and item.name or "?"
                local itemLink = item and item.itemLink or nil

                row.product.icon:SetTexture(GetItemIcon(recipe.itemID))
                row.product.itemLink = itemLink
                row.name:SetText(name)

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
                row.craftable:SetText("x" .. craftable)

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

    -- Mettre a jour le OnClick pour alimenter le panneau droit
    for i = 1, totalSlots do
        local btn = buttons[i]
        btn:SetScript("OnClick", function(self)
            if selectedButton then
                selectedButton.selected:Hide()
            end
            if selectedButton == self then
                selectedButton = nil
                currentRecipes = {}
            else
                self.selected:Show()
                selectedButton = self
                currentRecipes = CraftProfit.SortRecipesByCraftability(CraftProfit.FindRecipesByReagent(self.itemID))
            end
            UpdateRecipeList()
        end)
    end

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
