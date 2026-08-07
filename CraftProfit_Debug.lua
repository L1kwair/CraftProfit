CraftProfit = CraftProfit or {}

local function DumpTable(t, indent)
    indent = indent or ""
    
    for key, value in pairs(t) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. " = {")
            DumpTable(value, indent .. "  ")
            print(indent .. "}")
        else
            print(indent .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

function CraftProfit.Debug(value)
    if type(value) == "table" then
        print("=== Debug Table ===")
        DumpTable(value, "  ")
        print("====================")
    else
        print("[CraftProfit Debug] " .. tostring(value))
    end
end