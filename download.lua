if fs.exists("powersystem.lua") then
    shell.run("delete powersystem.lua")
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/powersystem.lua")
    print("\nUpdated powersystem.lua")
else
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/powersystem.lua")
    print("\nDownloaded powersystem.lua")
end
if fs.exists("startup.lua") then
    shell.run("delete startup.lua")
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/startup.lua")
    print("\nUpdated startup.lua")
else
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/startup.lua")
    print("\nDownloaded startup.lua")
end
print("Done. restart computer to run script, make sure the modems on the monitor and computer are activated")