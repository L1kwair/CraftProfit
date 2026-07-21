function CraftProfit.CreateItemButton(parent, size)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)

    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetSize(size * 1.78, size * 1.78)
    btn.border:SetPoint("CENTER", btn, "CENTER")
    btn.border:SetTexture("Interface/Buttons/UI-Quickslot2")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    btn.count:SetJustifyH("RIGHT")

    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetTexture("Interface/Buttons/ButtonHilight-Square")
    btn.highlight:SetBlendMode("ADD")

    btn.selected = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    btn.selected:SetSize(size * 1.78, size * 1.78)
    btn.selected:SetPoint("CENTER", btn, "CENTER")
    btn.selected:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    btn.selected:SetBlendMode("ADD")
    btn.selected:SetVertexColor(1, 0.82, 0, 0.8)
    btn.selected:Hide()

    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return btn
end

function CraftProfit.CreateRecipeRow(parent, iconSize, reagentIconSize, maxReagents)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    row:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    row:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    row.product = CraftProfit.CreateItemButton(row, iconSize)
    row.product:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -5)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.product, "RIGHT", 8, 6)
    row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.name:SetJustifyH("LEFT")

    row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.profit:SetPoint("LEFT", row.product, "RIGHT", 8, -8)
    row.profit:SetJustifyH("LEFT")

    row.craftable = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.craftable:SetPoint("RIGHT", row, "RIGHT", -4, -8)
    row.craftable:SetJustifyH("RIGHT")

    row.reagents = {}
    for j = 1, maxReagents do
        local r = CraftProfit.CreateItemButton(row, reagentIconSize)

        if j == 1 then
            r:SetPoint("TOPLEFT", row.product, "BOTTOMLEFT", 0, -6)
        else
            r:SetPoint("LEFT", row.reagents[j - 1], "RIGHT", 14, 0)
        end

        r.qty = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
        r.qty:SetPoint("TOP", r, "BOTTOM", 0, -1)
        r.qty:SetJustifyH("CENTER")

        r:Hide()
        row.reagents[j] = r
    end

    row:Hide()
    return row
end
