-- Reading Config file --
local cfg_file = fs.open("EnergyMonitorConfig.lua", "r")
local cfg = textutils.unserialise(cfg_file.readAll())
cfg_file:close()

local Abbreviations = cfg.Abbreviations
local EnergyType = "RF"  -- Only focus on RF for this script

-- Global Variables --
cells = {}
monitor = nil

-- Maps for display --
RF_DISPLAY_MAP = {
    [1] = "k",
    [2] = "M",
    [3] = "G",
    [4] = "T",
    [5] = "P"
}

RF_CELL_TYPE = {
    "thermal:energy_cell",
    "powah:energy_cell",
    "powah:ender_cell"  -- Include powah:ender_cell here
}

-- Functions --

-- Check if a table contains a value
local function tableContains(tbl, item)
    for _, v in pairs(tbl) do
        if v == item then
            return true
        end
    end
    return false
end

-- Add two large numbers represented as strings
local function addLargeNumbers(num1, num2)
    print("Adding numbers: " .. num1 .. " + " .. num2)
    local length1 = #num1
    local length2 = #num2
    local carry = 0
    local result = ""

    local maxLength = math.max(length1, length2)
    for i = 1, maxLength do
        local digit1 = tonumber(num1:sub(-i, -i)) or 0
        local digit2 = tonumber(num2:sub(-i, -i)) or 0
        local sum = digit1 + digit2 + carry

        carry = math.floor(sum / 10)
        result = (sum % 10) .. result
    end

    if carry > 0 then
        result = carry .. result
    end

    print("Result of addition: " .. result)
    return result
end

-- Convert a large number into a readable string format
local function formatNumberAsString(number)
    local numberStr = tostring(number)
    local length = #numberStr
    local result = ""

    for i = 1, length do
        result = result .. numberStr:sub(i, i)
        if (length - i) % 3 == 0 and i < length then
            result = result .. ","
        end
    end

    print("Formatted number: " .. result .. " RF")
    return result .. " RF"
end

-- Handle large energy values
local function getLargeEnergy(v_wrap)
    -- Attempt to use a method for retrieving large values
    if v_wrap.getEnergy then
        local energy = v_wrap.getEnergy()
        print("Energy retrieved from peripheral using getEnergy: " .. energy)
        return tostring(energy) -- Ensure this is returned as a string
    elseif v_wrap.getEnergyStored then
        local energyStored = v_wrap.getEnergyStored()
        print("Energy retrieved from peripheral using getEnergyStored: " .. energyStored)
        return tostring(energyStored)
    end
    error("Energy retrieval method not found for peripheral.")
end

local function getLargeCapacity(v_wrap)
    if v_wrap.getEnergyCapacity then
        local capacity = v_wrap.getEnergyCapacity()
        print("Capacity retrieved from peripheral: " .. capacity)
        return tostring(capacity) -- Ensure this is returned as a string
    end
    error("Capacity retrieval method not found for peripheral.")
end

local function getTotalEnergy(cells)
    local total_energy = "0"
    for _, cell in ipairs(cells) do
        local v_wrap = peripheral.wrap(cell)
        print("Checking cell: " .. cell)
        local energy = getLargeEnergy(v_wrap)
        total_energy = addLargeNumbers(total_energy, energy)
    end
    print("Total energy: " .. total_energy)
    return total_energy
end

local function getTotalEnergyCapacity(cells)
    local total_capacity = "0"
    for _, cell in ipairs(cells) do
        local v_wrap = peripheral.wrap(cell)
        print("Checking cell: " .. cell)
        local capacity = getLargeCapacity(v_wrap)
        total_capacity = addLargeNumbers(total_capacity, capacity)
    end
    print("Total capacity: " .. total_capacity)
    return total_capacity
end

local function updateEnergyBar(monitor, percentage)
    print("Updating energy bar with percentage: " .. percentage)
    monitor.setCursorPos(2, 4 + 13)
    for r = 13, 0, -1 do
        monitor.clearLine()
        monitor.setCursorPos(2, 4 + r)
        if percentage < 0 then
            monitor.blit("             ", "7777777777777", "7777777777777")
        else
            monitor.blit("             ", "eeeeeeeeeeeee", "eeeeeeeeeeeee")
        end
        percentage = percentage - 1
    end
end

local function updateEnergyText(monitor, energy, capacity)
    print("Updating energy text on monitor")
    monitor.setTextColour(colors.green)
    local energy_str = formatNumberAsString(energy)
    local capacity_str = formatNumberAsString(capacity)

    monitor.setCursorPos(19, 5)
    monitor.write(energy_str)
    monitor.setCursorPos(19, 7)
    monitor.write(capacity_str)
end

local function updateEnergyLevels(cells, monitor)
    print("Updating energy levels...")
    local energy = getTotalEnergy(cells)
    local capacity = getTotalEnergyCapacity(cells)

    monitor.setTextColour(colors.white)
    monitor.setCursorPos(2, 3)
    monitor.write("Energy stored:")
    
    -- Energy Bar --    
    local percentage = (tonumber(energy) / tonumber(capacity)) * 13
    percentage = math.floor(percentage)
    
    updateEnergyBar(monitor, percentage)
    
    -- Energy / Capacity
    updateEnergyText(monitor, energy, capacity)
end

local function findCells()
    print("Finding energy cells...")
    cells = {}

    local ps = peripheral.getNames()

    for _, peripheral_name in pairs(ps) do
        local vtype = peripheral.getType(peripheral_name)
        print("Found peripheral: " .. peripheral_name .. " of type " .. vtype)
        if tableContains(RF_CELL_TYPE, vtype) then
            table.insert(cells, peripheral_name)
            print("Added cell: " .. peripheral_name)
        end
    end
end

local function update(cells, monitor)
    updateEnergyLevels(cells, monitor)
    os.sleep(1)
end

local function initprogram()
    print("----------------- Energy Monitor -----------------")
    print(" * Starting initialization...")

    local ps = peripheral.getNames()
    monitor = peripheral.find("monitor")

    print("")
    print(" * Connected Devices:")
    for _, v in pairs(ps) do
        print("   > "..v)
    end

    --  Check for devices --
    print("\n * Energy Type: "..EnergyType)

    findCells()

    print("")

    if monitor == nil then error(" /!\\ No monitor found!") end
    if #cells == 0 then error(" /!\\ No energy cells found!") end

    print(" * Found energy cells: ("..#cells..")")
    for _, v in pairs(cells) do
        print("   > "..v)
    end
end

local function program()
    initprogram()

    print("")
    print(" * Program successfully started!")
    print("--------------------------------------------------")

    while true do
        update(cells, monitor)
    end
end

-- Program --
program()
