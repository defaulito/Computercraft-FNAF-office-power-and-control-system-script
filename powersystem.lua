-- script by defaulito
local monitor = peripheral.find("monitor")
local speaker = peripheral.find("speaker") or nil
local doSetup = false
local configPath = "config.lua"

--CONFIG VARIABLES
local fullPowerDuringDay = false
local do6AMCelebration = false
local resetPowerAt6AM = false
--

term.clear()
term.setCursorPos(0,0)
monitor.setBackgroundColor(colors.black)
monitor.clear()

--On-monitor buttons
local Button = {}
Button.__index = Button
Button.instances = {}
function Button:new(x, y, xTOff, yTOff, width, height, text)
    if text ~= nil then
        assert(#text + xTOff <= width, "text is wider than the button, consider using acronyms (ex: DOR for door), or decreasing x text offset if present")
        assert(yTOff < height, "y text offset is too large")
    end

    local obj = {x = x, y = y, xTOff=xTOff, yTOff=yTOff, width = width, height = height, active = false, text = text or nil}
    setmetatable(obj, self)
    table.insert(self.instances, obj)
    return obj
end
function Button:draw()
    local bgcolor
    if self.active then bgcolor = "d"
    else bgcolor = "e"
    end
    for i = 0, self.height - 1 do
        monitor.setCursorPos(self.x, self.y + i)
        monitor.blit(string.rep(" ", self.width), string.rep("0", self.width), string.rep(bgcolor, self.width))
    end
    if self.text ~= nil then
        monitor.setCursorPos(self.x + self.xTOff, self.y + self.yTOff)
        monitor.blit(self.text, string.rep("0", #self.text), string.rep(bgcolor, #self.text))
    end
end
function Button:awaitClick()
    local eventData = {os.pullEvent()}
    local event = eventData[1]
    if event == "monitor_touch" then
        local x = eventData[3]
        local y = eventData[4]
        for _, button in ipairs(Button.instances) do
            if x >= button.x and x <= button.x + button.width - 1 and y >= button.y and y <= button.y + button.height - 1 then
                button.active = not button.active
            end
        end
    end
end
function Button:drawButtons()
    for _, button in ipairs(Button.instances) do
        button:draw()
    end
end
local function handleInput()
    while true do
        Button:awaitClick()
    end
end

local Link = {}
Link.instances = {}
function Link:new(parentRelay, childRelays, powerConsumption, initialActivity)
    local obj = {parentRelay = parentRelay or nil, childRelays = childRelays or nil, powerConsumption = powerConsumption, initialActivity = initialActivity, active = initialActivity}
    setmetatable(obj, self)
    self.__index = self
    table.insert(self.instances, obj)
    return obj
end
function Link:getParentRelayState()
    local sides = {"top", "bottom", "left", "right", "front", "back"}
        for _, side in ipairs(sides) do
        if self.parentRelay.getInput(side) then
            return true
        end
    end
    return false
end
function Link.updateChildRelayStates()
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    for _, link in ipairs(Link.instances) do
        if link.childRelays ~= nil then
            for _, relay in ipairs(link.childRelays) do
                for _, side in ipairs(sides) do
                    relay.setOutput(side, link.active)
                end
            end
        end
    end
end

local function setup()
    local userInput
    print("\nINITIAL SETUP")

    print("\nDo you want power to automatically reset at 6AM?\n | Yes | No |")
    userInput = read()
    if userInput:upper() == "YES" then
        resetPowerAt6AM = true
    elseif userInput:upper() == "NO" then
    end
    print("\nDo you want power to stay full during daytime?\n | Yes | No |")
    userInput = read()
    if userInput:upper() == "YES" then
        fullPowerDuringDay = true
    elseif userInput:upper() == "NO" then
    end
    if resetPowerAt6AM == false and fullPowerDuringDay == false then
        sleep(1)
        print("\nPower won't reset automatically at 6AM and power won't stay full during day, keep in mind that you will need to add a generator in order to recharge power")
        sleep(1)
    end
    print("\nDo you want the monitor to announce when time hits 6AM?\n | Yes | No |")
    userInput = read()
    if userInput:upper() == "YES" then
        do6AMCelebration = true
    elseif userInput:upper() == "NO" then
    end
    sleep(1)

    doSetup = true
    local event, p1, p2, p3
    while doSetup do
        print("\nConnecting a new device...")
        print("\nWaiting for a relay...\n | (D)one to exit setup |")
         event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if keys.getName(p1):upper() == "D" then
                print("Done")
                doSetup = false
            end
        elseif event == "peripheral" then
            local mainRelay = peripheral.wrap(p1)
            print("\nRelay attached, what did you connect?\n | Lever | Lights | Generator |")
            userInput = read()
            if userInput:upper() == "LEVER" then
                print("\nYou connected a lever, now connect the target device relay(s)")
                sleep(1)
                local connectingTargets = true
                local connectedTargets = {}
                while connectingTargets do
                    print("\nWaiting for a relay...\n | (D)one to finish |")
                     event, p1, p2, p3 = os.pullEvent()
                    if event == "key" then
                        if keys.getName(p1):upper() == "D" then
                            print("Done")
                            connectingTargets = false
                        end
                    elseif event == "peripheral" then
                        print("\nYou attached a target")
                        table.insert(connectedTargets, peripheral.wrap(p1))
                    end
                end
                print("\nHow much power will it consume?")
                sleep(1)
                local powerConsumption = tonumber(read())
                Link:new(mainRelay, connectedTargets or nil, powerConsumption, false)
                print("\nYou added a new lever and its " .. #connectedTargets .. " target(s)")
                sleep(1)
            elseif userInput:upper() == "LIGHTS" then
                local connectedTargets = {}
                print("\nYou connected lights\n")
                print("Do you want to add more lights?\n | Yes | No |")
                userInput = read()
                if userInput:upper() == "YES" then
                    sleep(1)
                    local connectingTargets = true
                    while connectingTargets do
                        print("\nWaiting for a relay...\n | (D)one |")
                        local event, p1, p2, p3 = os.pullEvent()
                        if event == "key" then
                            if keys.getName(p1):upper() == "D" then
                                print("Done")
                                connectingTargets = false
                            end
                        elseif event == "peripheral" then
                            print("\nYou attached a light")
                            table.insert(connectedTargets, peripheral.wrap(p1))
                        end
                    end
                elseif userInput.upper == "NO" then
                end
                table.insert(connectedTargets, mainRelay)
                sleep(1)
                print("\nHow much power will it consume?")
                local powerConsumption = tonumber(read())
                sleep(1)
                Link:new(nil, connectedTargets, powerConsumption, true)
                print("\nYou added " .. #connectedTargets .. " light(s)")
                sleep(1)
            elseif userInput:upper() == "GENERATOR" then
                print("You connected a generator\n")
                sleep(1)
                print("How much power will it generate?")
                sleep(1)
                local powerConsumption = -tonumber(read())
                sleep(1)
                Link:new(mainRelay, nil , powerConsumption, false)
                print("You added a new generator")
                sleep(1)
            end
        end
    end

    local config = {}
    config.resetPowerAt6AM = resetPowerAt6AM
    config.fullPowerDuringDay = fullPowerDuringDay
    config.do6AMCelebration = do6AMCelebration
    config.links = {}
    for _, link in ipairs(Link.instances) do
        local currentLink = {}
        currentLink.childRelays = {}
        if link.parentRelay ~= nil then
            currentLink.parentRelay = peripheral.getName(link.parentRelay)
        else currentLink.parentRelay = nil
        end
        if link.childRelays ~= nil then
            for _, relay in ipairs(link.childRelays) do
            table.insert(currentLink.childRelays, peripheral.getName(relay))
            end
        else currentLink.childRelays = nil
        end
        currentLink.powerConsumption = link.powerConsumption
        currentLink.initialActivity = link.initialActivity
        table.insert(config.links, currentLink)
        local file = fs.open(configPath, "w")
        file.write("return " .. textutils.serialize(config))
        file.close()
    end
    print("Config saved to " .. configPath)
    print("\nSetup is done, you will not need to set up again, if you wish to reset then delete " .. configPath)
end

local function loadConfig()
    local config = dofile(configPath)
    resetPowerAt6AM = config.resetPowerAt6AM
    fullPowerDuringDay = config.fullPowerDuringDay
    do6AMCelebration = config.do6AMCelebration
    for _, link in ipairs(config.links) do
        local parentRelay = nil
        if link.parentRelay ~= nil then
            parentRelay = peripheral.wrap(link.parentRelay)
        end
        local childRelays = nil
        if link.childRelays ~= nil then
            childRelays = {}
            for _, relay in ipairs(link.childRelays) do
                table.insert(childRelays, peripheral.wrap(relay))
            end
        end
        Link:new(parentRelay, childRelays, link.powerConsumption, link.initialActivity)
    end
    print("\nLoaded config from " .. configPath .. ", if you wish to reset setup then delete " .. configPath)
end

if fs.exists(configPath) then
    loadConfig()
else setup()
end

--handling power
local initialPower = 9999
local power = initialPower
local function handlePower()
    if power > 0 then
        for _, link in ipairs(Link.instances) do
            if link.parentRelay ~= nil and link.childRelays ~= nil then
                link.active = link:getParentRelayState()
                if link.active then
                    power = power - link.powerConsumption
                end
            elseif link.parentRelay == nil then
                link.active = link.initialActivity
                power = power - link.powerConsumption
            elseif link.childRelays == nil then
                link.active = link:getParentRelayState()
                if link.active then
                    power = power - link.powerConsumption
                end
            end
        end
    end
    Link.updateChildRelayStates()

    if power > initialPower then
        power = initialPower
    end
    if power <= 0 then
        power = 0
        for _, button in ipairs(Button.instances) do
            button.active = false
        end
        for _, link in ipairs(Link.instances) do
            if link.parentRelay ~= nil and link.childRelays ~= nil then
                link.active = false
            elseif link.parentRelay == nil then
                link.active = not link.initialActivity
            elseif link.childRelays == nil then
                link.active = link:getParentRelayState()
                if link.active then
                    power = power - link.powerConsumption
                end
            end
        end
    end
    if os.time() >= 6 and fullPowerDuringDay then
        power = initialPower
    end
end

--announcing 6AM on the monitor
local function celebrate6AM()
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(3, 1)
    monitor.write("5AM")
    sleep(2)
    monitor.clear()
    monitor.setCursorPos(3, 1)
    monitor.setBackgroundColor(colors.blue)
    monitor.clear()
    monitor.write("6AM")
    sleep(0.4)
    monitor.setCursorPos(1, 2)
    monitor.write("Your")
    sleep(0.4)
    monitor.setCursorPos(1, 3)
    monitor.write("shift")
    sleep(0.4)
    monitor.setCursorPos(1, 4)
    monitor.write("is")
    sleep(0.4)
    monitor.setCursorPos(1, 5)
    monitor.write("over!")
    sleep(5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
end

--drawing monitor screen stuff
local powerconsumelevel = 0
local powerlvlcolors = { "d", "d4", "d44", "d444", "d444e", "d444ee", "d444eee" }
local function drawScreen()
    if power <= 0 then
        monitor.setTextColor(colors.red)
        powerconsumelevel=0
    else
        monitor.setTextColor(colors.white)
    end
    -- PWR text and remaining percentage
    monitor.setCursorPos(1, 1)
    monitor.write("PWR")
    monitor.setCursorPos(5, 1)
    if power > 0 then
        monitor.write(tostring(math.ceil(((power / initialPower) * 100) -1 )).. "%")
    else
        monitor.write("0%")
    end
    -- power usage level bar (=======)
    monitor.setCursorPos(1, 2)
    for _, link in ipairs(Link.instances) do
        if link.active and link.powerConsumption > 0 then
            powerconsumelevel = powerconsumelevel + 1
        end
    end
    if powerconsumelevel > 0 then
        monitor.blit(string.rep("=", powerconsumelevel), powerlvlcolors[powerconsumelevel], string.rep("f", powerconsumelevel))
    end
    powerconsumelevel = 0
    -- draw buttons on the monitor (if there are buttons)
    Button:drawButtons()
end

local debounce6AM = false
local function mainLoop()
    while true do
        handlePower()
        if os.time() == 6 and debounce6AM == false then
            debounce6AM = true
            if do6AMCelebration then
                celebrate6AM()
            end
            if resetPowerAt6AM then
                power = initialPower
            end
        end
        if os.time() > 6 and debounce6AM == true then
            debounce6AM = false
        end
        drawScreen()
        sleep(0.05)
        monitor.clear()
    end
end

parallel.waitForAny(mainLoop, handleInput)

-- script by defaulito