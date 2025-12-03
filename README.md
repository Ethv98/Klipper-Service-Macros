# 🔧 Klipper Toolhead Service & Nozzle-Change Macros

This repository provides a set of Klipper macros that automate and
simplify common 3D-printer maintenance tasks, including nozzle changes,
cold swaps, and general toolhead servicing. The macros park the toolhead
front-and-center for easy access, guide the user through each step with
on-screen prompts, movement, retraction, LED control, and
heater management automatically.

--------------------------------------------------------------------------------

# V1.0.0 Release Notes

- this is the first stable release of the macro, installer and formating

- Clunky but functional, treate this as the first prototype

- Establishes fundamentals of funtion and operation

---------------------------------------------------------------------------------

## ✨ Features

-   **One-click toolhead servicing**
    Automatically homes the printer, lifts Z, and parks the hotend in an
    ideal service position.

-   **Fully guided workflow**
    Integrated UI prompts walk the user through each step of swapping or
    servicing a nozzle.

-   **Safe & consistent nozzle changes**
    Supports both **hot nozzle swaps** and **cold swaps**, depending on
    your workflow.
    
-   **LED support**
    -  Led_Effects Support for RGB and Neopixel Lighting
            Repo Used : https://github.com/julianschill/klipper-led_effect/tree/master
       
-------------------------------------------------------------------------

## 🧩 Macro Overview

### Service_Position

Prepares the printer for maintenance:
- Homing if its gotta
- Moves Toolhead to service position
- Filament retraction
- Displays start prompts

### Nozzle Swap

A fully guided hot-nozzle change:
- Prompts user to heat, loosen, and install new nozzle
- Optioinal extra extrusion or retraction for flushing

If using a cold swap nozzle:
- Uses machine partcooling fans to assist with cooldown 
- Prompts user to change nozzle after minium temp is reached

-----------------------------------------------------------------------

## ⚙️ Configuration

All user-adjustable settings are stored in:

    ServiceSettings.cfg

## 🧩 ServiceSettings.cfg --- Variable Reference Table

  **Setting**                      **Description**
  

  `Retract_Distance `              How far the filament is retracted in MM
                                   

  `Retract_Temp`                   Temperature used for retracting filament
                                   from the melt zone.

  `Nozzle_Swap_temp`               Temperature used for tightening a new
                                   nozzle during a hot swap.

  `Cold_Swap_Hotend`               Enables if using a  cold-nozzle replacement
                                   hotend. (ie. Revo...)

  `Cold_Swap_Temp`                 Automatically cools down to this temp for
                                   cold swap if enabled.

  `Leds`                           Enables LED color changes during service
                                   routines using this plugin and Macros:
                                   https://github.com/julianschill/klipper-led_effect/tree/master

  --------------------------------------------------------------------------

## 📥 Installation

You can install Klipper-Service-Macros with this SSH command:

```
cd ~
curl -fsSL https://raw.githubusercontent.com/Herculez3D/Klipper-Service-Macros/main/service_macros_installer.sh -o service_macros_installer.sh
chmod +x service_macros_installer.sh
bash ./service_macros_installer.sh install
```

Running this command will automatically install all files along with adding update manager to your `moonraker.conf`

Add `[include ServiceSettings.cfg]` to your `printer.cfg`


### After installation, Mainsail will show:

```
printer_data/config/
│
├── ServiceSettings.cfg          ← Editable settings
│
└── ServiceMacros/               ← Folder
      ├── ServiceMacros.cfg
      └── ServiceSettings.cfg    (template only)
```

---

## 🔄 Updating

### Via Mainsail:
**Machine → Updates → Klipper-Service-Macros → Update**

### Via SSH:
```
bash ~/service_macros_installer.sh update
```

Your custom settings remain preserved, and any new options are added automatically.

---

## ❌ Uninstall

```bash
bash ~/service_macros_installer.sh uninstall
```

This removes:
  
- The cloned repository  
- The `update_manager` entry in Moonraker  

Your user settings file is backed up and preserved.

Be sure to Comment out `[include ServiceSettings.cfg]` from your `printer.cfg`

---
    
## Smart Homing

         _Smart_Homing 
   
- Can be used in place of other G28 commands in other macros.
- A quick "home the machine if it hasnt been" script

-----------------------------------------------------------------------------------

## 🙌 Contributions

Pull requests and improvements are welcome.
