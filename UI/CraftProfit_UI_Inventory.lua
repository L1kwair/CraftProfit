-- Left panel: bag inventory as a grid of icons, grouped by item category.

local PANEL_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local ICON_SIZE = 37
local ICON_SPACING = 2
local ICONS_PER_ROW = 7
local VISIBLE_ROWS = 11
local ROW_HEIGHT = ICON_SIZE + ICON_SPACING

-- onSelect(itemID) is called on every item click.
-- itemID is nil when the click deselects the current item.
function CraftProfit.CreateInventoryPanel(parent, onSelect)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetBackdrop(PANEL_BACKDROP)
    panel:SetBackdropColor(0.05, 0.05, 0.05, 0.7)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 8)

    local selectedItemID = nil
    local collapsedCategories = {}
    local displayRows = {}

    local UpdateItemGrid

    local slots = {}
    for i = 1, VISIBLE_ROWS do
        local anchor = CreateFrame("Frame", nil, panel)
        anchor:SetHeight(ROW_HEIGHT)

        if i == 1 then
            anchor:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
        else
            anchor:SetPoint("TOPLEFT", slots[i - 1].anchor, "BOTTOMLEFT", 0, 0)
        end
        anchor:SetPoint("RIGHT", panel, "RIGHT", -30, 0)

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
                else
                    selectedItemID = self.itemID
                end
                UpdateItemGrid()
                onSelect(selectedItemID)
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
        local categoryNames, categoryItems = CraftProfit.GetInventoryByCategory()

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
        FauxScrollFrame_Update(scrollFrame, numRows, VISIBLE_ROWS, ROW_HEIGHT)
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
                    local arrow = "v "
                    if collapsedCategories[row.name] then
                        arrow = "> "
                    end
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
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, UpdateItemGrid)
    end)

    function panel:Refresh()
        UpdateItemGrid()
    end

    return panel
end
