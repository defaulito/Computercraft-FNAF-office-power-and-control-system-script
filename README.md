![2025-02-18_03 41 27](https://github.com/user-attachments/assets/c6b9bda9-2f9f-47d8-b629-f2e1f108dd0f)

# Computercraft FNAF office power and control system script
FNAF Power and control System for ComputerCraft

## This script simulates a power management system for FNAF-style Minecraft builds.

### Features:
* Clickable buttons on a monitor to toggle power-consuming devices.
* Power drains over time; if it reaches 0, all outputs (doors, lights, vents, etc) turn off.
* Redstone outputs for doors, lights, vents, etc.
* Automatically starts shift at 12pm and resets power and stops consumption at 6 AM.

#### To use the script:
First, you will need computercraft (CC: Tweaked) and create mod, You start by placing a computer in the world, then put both startup.lua and powersystem.lua in the following folder: (world save folder)/computercraft/computers/(computer id)

### Setting up in the in-game world
Place an **Advanced** monitor beside the computer in any direction\
Turn on the computer. (It should automatically run the script)\
Place redstone links on the sides of the computer **or** you can place a redstone relay in any direction beside the computer and place the redstone links on it instead.

Here are some example setups:
![2025-02-17_23 03 06](https://github.com/user-attachments/assets/a49ed0d5-1b67-4407-9db9-4134497e36cd)

### Editing the script:
To edit the script I recommend using notepad or a code editor although you can edit it through a computer in-game.\
Open powersystem.lua using notepad or a code editor.\
Scroll down until you find the edit here area.\
Code comments should help you edit according to your needs.\
In the future this will probably be switched to a separate configuration file for more a more user friendly experience and the ability to update the script without having to re-apply your edits.

Resourcepack I used to change the look of computercraft: https://modrinth.com/resourcepack/create-computercraft

You are free to use, modify, and redistribute the code as long as you link to this repository and not modify the code in any malicious way.
