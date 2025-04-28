if fs.exists("powersystem.lua") then
    shell.run("delete powersystem.lua")
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/powersystem.lua")
    print("Updated powersystem.lua\n")
else
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/powersystem.lua")
    print("Downloaded powersystem.lua\n")
end
if fs.exists("startup.lua") then
    shell.run("delete startup.lua")
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/startup.lua")
    print("Updated startup.lua\n")
else
    shell.run("wget https://raw.githubusercontent.com/defaulito/Computercraft-FNAF-office-power-and-control-system-script/main/startup.lua")
    print("Downloaded startup.lua\n")
end
print("Done. restart computer to run script, make sure the modems on the monitor and computer are activated")