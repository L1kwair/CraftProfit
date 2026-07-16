function CraftProfit.FormatPrice(copper)
    local gold = math.floor(math.abs(copper) / 10000)
    local silver = math.floor((math.abs(copper) % 10000) / 100)
    local cop = math.abs(copper) % 100
    local sign = copper < 0 and "-" or ""
    return string.format("%s%dg %ds %dc", sign, gold, silver, cop)
end
