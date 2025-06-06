-- script by defaulito
local monitors = {peripheral.find("monitor")}
local speaker = peripheral.find("speaker")
local configPath = "config.lua" --where to save and load config, only edit if you need to
local debounce6AM = false
local debounceCelebration = false
--CONFIG VARIABLES
local fullPowerDuringDay = false
local do6AMCelebration = false
local resetPowerAt6AM = false
local initialPower
--
term.clear()
term.setCursorPos(1,1)
if monitors ~= nil then
    for _, monitor in ipairs(monitors) do
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
    end
else
    print("ERROR: Monitor not detected, make sure a monitor is present, and make sure that the wired modems on the sides of both the computer and the monitor are activated, then restart the computer")
    os.exit(false)
end
--on-monitor buttons --NOTE: not currently used, functionality will be added in the future probably...
local Button = {} --button class
Button.__index = Button
Button.instances = {}
function Button:new(x, y, xTOff, yTOff, width, height, text)
    if text ~= nil then
        assert(#text + xTOff <= width, "Text is wider than the button, consider using acronyms (ex: DOR for door), or decreasing X text offset if present")
        assert(yTOff < height, "Y text offset is too large, decrease or remove it")
    end
    local obj = {x = x, y = y, xTOff = xTOff, yTOff = yTOff, width = width, height = height, active = false, text = text or nil}
    setmetatable(obj, self)
    table.insert(self.instances, obj)
    return obj
end
function Button:draw(monitor)
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
function Button:drawAllButtons()
    for _, button in ipairs(Button.instances) do
        button:draw()
    end
end
--a "link" is just a fancy name in the code for devices and their levers or whatever controls them
local Link = {} --link class
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
function Link.isGeneratorOn()
    for _, link in ipairs(Link.instances) do
        if link.powerConsumption < 0 and link.active then
            return true
        end
    end
end
--setup function
local function setup()
    local userInput
    print("INITIAL SETUP")
    print("\nWhat is the initial power value?\n | Any positive number |")
    initialPower = tonumber(read())
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
    print("\nDo you want the monitor to announce when time hits 6AM with a little animation?\n | Yes | No |")
    userInput = read()
    if userInput:upper() == "YES" then
        do6AMCelebration = true
    elseif userInput:upper() == "NO" then
    end
    if do6AMCelebration == true and speaker ~= nil then
        sleep(1)
        print("\nSpeaker detected, when time hits 6AM, a chime will play")
        sleep(1)
    end
    sleep(1)
    --device connection
    local doSetup = true
    local event, p1, p2, p3
    while doSetup do
        print("\nConnecting a new device...")
        print("\nWaiting for a relay...\n | (D)one to exit setup |")
        event, p1, p2, p3 = os.pullEvent()
        if event == "key" and keys.getName(p1):upper() == "D" then
            print("Done")
            doSetup = false
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
                    if event == "key" and keys.getName(p1):upper() == "D" then
                        print("Done")
                        connectingTargets = false
                    elseif event == "peripheral" then
                        print("\nYou attached a target")
                        table.insert(connectedTargets, peripheral.wrap(p1))
                    end
                end
                print("\nHow much power will it consume per second of being active?\n | Positive number or 0 for no consumption |")
                sleep(1)
                local powerConsumption = tonumber(read())/20
                Link:new(mainRelay, connectedTargets or nil, powerConsumption, false)
                print("\nYou added a new lever and its "..#connectedTargets.." target(s)")
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
                        event, p1, p2, p3 = os.pullEvent()
                        if event == "key" and keys.getName(p1):upper() == "D" then
                            print("Done")
                            connectingTargets = false
                        elseif event == "peripheral" then
                            print("\nYou attached a light")
                            table.insert(connectedTargets, peripheral.wrap(p1))
                        end
                    end
                elseif userInput:upper() == "NO" then
                end
                table.insert(connectedTargets, mainRelay)
                sleep(1)
                print("\nHow much power will it consume per second of being active?\n | Positive number or 0 for no consumption |")
                local powerConsumption = tonumber(read())/20
                sleep(1)
                Link:new(nil, connectedTargets, powerConsumption, true)
                print("\nYou added "..#connectedTargets.." light(s)")
                sleep(1)
            elseif userInput:upper() == "GENERATOR" then
                print("You connected a generator\n")
                sleep(1)
                print("How much power will it generate per second of being active?\n | Positive number |")
                sleep(1)
                local powerConsumption = -tonumber(read())/20
                sleep(1)
                Link:new(mainRelay, nil , powerConsumption, false)
                print("You added a new generator")
                sleep(1)
            end
        end
    end
    --saving config to a file
    local config = {}
    config.resetPowerAt6AM = resetPowerAt6AM
    config.fullPowerDuringDay = fullPowerDuringDay
    config.do6AMCelebration = do6AMCelebration
    config.initialPower = initialPower
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
    end
    local file = fs.open(configPath, "w")
    file.write("return " ..textutils.serialize(config))
    file.close()
    print("\nConfig saved to "..configPath)
    print("\nSetup is done, you will not need to set up again\n\nif you wish to reset then delete "..configPath..", either by stopping the code and running the delete command or by going to\n(this world's save folder)/computercraft/computer/"..os.getComputerID())
end
--loading config
local function loadConfig()
    local config = dofile(configPath)
    resetPowerAt6AM = config.resetPowerAt6AM
    fullPowerDuringDay = config.fullPowerDuringDay
    do6AMCelebration = config.do6AMCelebration
    initialPower = config.initialPower
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
    print("Loaded config from "..configPath.."\n\nif you wish to reset setup then delete "..configPath..", either by stopping the code and running the delete command or by going to\n(this world's save folder)/computercraft/computer/"..os.getComputerID())
end
--check if config file exists, if it does, load it, if it doesn't, then start setup
if fs.exists(configPath) then loadConfig()
else setup()
end
--handling power
local power = initialPower
local function handlePower()
    --handling power consumption for devices
    if power > 0 then
        for _, link in ipairs(Link.instances) do
            if link.parentRelay ~= nil and link.childRelays ~= nil then
                if link.active then
                    power = power - link.powerConsumption
                end
            elseif link.parentRelay == nil then
                power = power - link.powerConsumption
            elseif link.childRelays == nil then
                if link.active then
                    power = power - link.powerConsumption
                end
            end
        end
    end
    --handling power outage and edge cases
    if power > initialPower then power = initialPower
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
--handling input, from on-monitor buttons or physical levers/buttons
local function handleInput()
    while true do
        if Button.instances ~= nil then
            Button:awaitClick()
        end
        if power > 0 then
            for _, link in ipairs(Link.instances) do
                if link.parentRelay ~= nil and link.childRelays ~= nil then
                    link.active = link:getParentRelayState()
                elseif link.parentRelay == nil then
                    link.active = link.initialActivity
                elseif link.childRelays == nil then
                    link.active = link:getParentRelayState()
                end
            end
        end
        Link.updateChildRelayStates()
        sleep(0.05) --remove or decrease when you add buttons back
    end
end
--6AM chime
local function playChime() --the westminster clock chime
    local instrument = "bell"
    local volume = 1
    local delay = 0.8
    for _, note in ipairs({6, 10, 8, 1}) do --first half
        speaker.playNote(instrument, volume, note)
        sleep(delay)
    end
    sleep(delay*2/3)
    for _, note in ipairs({6, 8, 10, 6}) do --second half
        speaker.playNote(instrument, volume, note)
        sleep(delay)
    end
end
--announcing 6AM on the monitor
local function announce6AM(monitor)
    monitor.clear()
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
local powerUsageLevel = 0
local powerUsageBarColors = {}
local function drawScreen(monitor)
    if power <= 0 then
        monitor.setTextColor(colors.red)
        powerUsageLevel=0
    else
        monitor.setTextColor(colors.white)
    end
    --PWR text and remaining percentage
    monitor.setCursorPos(1, 1)
    monitor.write("PWR")
    monitor.setCursorPos(5, 1)
    if power > 0 then
        monitor.write(tostring(math.ceil(((power/initialPower)*100)-1)).."%")
    else
        monitor.write("0%")
    end
    --power usage level bar (=======)
    if monitor.isColor() then
        powerUsageBarColors = {"d", "d4", "d44", "d44e", "d44ee", "d44eee", "d44eeee"}
    else
        powerUsageBarColors = {"d", "d8", "d88", "d886", "d8866", "d88666", "d886666"}
    end
    monitor.setCursorPos(1, 2)
    for _, link in ipairs(Link.instances) do
        if link.active and link.powerConsumption > 0 then
            powerUsageLevel = powerUsageLevel + 1
        end
        if powerUsageLevel > 7 then powerUsageLevel = 7
        end
    end
    if powerUsageLevel > 0 then
        monitor.blit(string.rep("=", powerUsageLevel), powerUsageBarColors[powerUsageLevel], string.rep("f", powerUsageLevel))
    end
    powerUsageLevel = 0
    --time
    local time = math.floor(os.time())
    monitor.setCursorPos(1, 5)
    if time <= 12 and time > 0 then
        monitor.write(time.."AM")
    elseif time > 12 then
        monitor.write((time-12).."PM")
    else
        monitor.write("12PM")
    end
    --generator indicator
    if Link.isGeneratorOn() then
        monitor.setCursorPos(7,5)
        monitor.blit("+","d","f")
    end
end
local function updateAllMonitors()
    while true do
        if math.floor(os.time()) == 6 and debounceCelebration == false then
            if do6AMCelebration then
                for _, monitor in ipairs(monitors) do
                    announce6AM(monitor)
                end
                debounceCelebration = true
            end
        end
        for _, monitor in ipairs(monitors) do
            drawScreen(monitor)
        end
        sleep(0.3)
        for _, monitor in ipairs(monitors) do
            monitor.clear()
        end
    end
end
--where it all comes together
local function mainLoop()
    while true do
        handlePower()
        local currentTime = os.time()
        if currentTime == 6 and not debounce6AM then
            debounce6AM = true
            if resetPowerAt6AM then
                power = initialPower
            end
            if do6AMCelebration then
                debounceCelebration = false
            end
        elseif currentTime > 6 and debounce6AM then
            debounce6AM = false
        end
        sleep(0.05) --executes once per tick
    end
end
--running mainLoop, handleInput and updateAllMonitors in parallel
parallel.waitForAny(mainLoop, handleInput, updateAllMonitors)
-- script by defaulito

--TODO:
-- improve setup wizard