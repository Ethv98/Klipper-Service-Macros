
# 📘 **Klipper Service Macros**
A streamlined toolhead service suite for Klipper—making nozzle changes, diagnostics, and maintenance simple, guided, and safe through the Mainsail/Fluidd interface.

This macro package provides a clean, menu-driven maintenance system with automated filament handling, temperature management, diagnostic tests, and optional dockable probe support.

---

# V2.0.0 Beta Notes

- Complete revamp and feature update from V1.0.0
- added features
    - Checks Menu (stable and operational)
    - Probe Test (stable and operational)
    - Wiggle Test (stable and operational)
    - Fan Test (stable and operational)
    - Heater Test (still in early development)
    - Heatbreak Test (still in early development)
- File structure revised and broken into a total of 5 files (4 macro files in a folder and 1 user settings file)
- Focusing on a univeral code that supports as many printer set ups as possible while keeping it simple enough that anyone can use it
- Maintaining a simple install process to reduce install errors for all users

  *USE AT YOUR OWN RISK*

---

# 🚀 **Features**

### 🛠️ **Service Menu**
Running `SERVICE_POSITION` places the toolhead in an accessible position and presents a unified maintenance menu:

<img width="428" height="242" alt="Service Menu" src="https://github.com/user-attachments/assets/fddd02d1-776f-4fd0-87d6-7a65678e172e" />

- **Nozzle Change**  
- **Toolhead Checks**  
- **Return to Last Position**
- **Exit**

---

### 🔧 **Nozzle Change**
Supports both **hot-swap** and **cold-swap** hotends.

Includes:

- Automatic heating to configured temperatures  
- Automatic filament retraction  
- Cooling cycle for cold-swap systems  
- LED feedback  
- Optional automatic probe repeatability test after swap  
- Clean UI prompt to confirm swap completion  
- Automatic return to Service Menu

---

### 🧪 **Checks Menu**

A collection of diagnostic tools to verify printer health:

<img width="420" height="243" alt="Checks Menu" src="https://github.com/user-attachments/assets/7d05dd3c-d518-4cda-bb3f-71651dc9d0ea" />


#### ✔ **Fan Test**
- Multi-stage fan ramp (0 → 30% → 60% → 100% → down again)  
- Clear console feedback + confirmation prompt  

#### ✔ **Probe Repeatability Test**
- Dockable probe attach/detach support  
- Console-only output (no UI prompt)  
- Reports:
  - Each probe sample  
  - Min / Max  
  - Average  
  - ΔZ deviation  
- Automatically returns to the Checks Menu

#### ✔ **Wiggle Test**
High-speed mechanical oscillation using **machine max velocity & accel**.

- Moves to center  
- Applies max speed feedrate  
- Runs 10 X-axis cycles and 10 Y-axis cycles  
- Restores motion limits after test  
- Returns to the service position  
- Popup confirms completion

Perfect for detecting:
- Loose belts  
- Bearing noise  
- Frame resonance

### ✔ **Heater Test**
- Heats to 200°C  
- Stabilizes briefly  
- Turns off  
- Lets the user review thermal behavior  

### ✔ **Heatbreak Cooling Test**
- Tests heatsink effectiveness  
- “Fan-off soak” followed by forced cooldown  
- Useful for diagnosing underperforming cooling systems

---

# 🧭 **Workflow Overview**

## 1️⃣ Enter Service Mode
```
SERVICE_POSITION
```
This will:

- Smart-home the printer if needed  
- Save the current toolhead state  
- Move to a safe maintenance position  
- Open the **Service Menu**  

---

## 2️⃣ Perform Maintenance  

Choose from:

### 🔧 Nozzle  
Runs the hot- or cold-swap workflow depending on your settings.

### 🔍 Checks  
Opens the diagnostic sub-menu.

### ↩️ Return  
Restores the position and exits service mode.

---

## 3️⃣ Exit Service Mode
Press **Return** in the Service Menu to restore the exact previous printer state (position, movement mode, etc.).

---

# 📥 Installation

You can install Klipper-Service-Macros with this SSH command:

```
cd ~
curl -fsSL https://raw.githubusercontent.com/Herculez3D/Klipper-Service-Macros/V2.0.0-Beta/service_macros_installer.sh -o service_macros_installer.sh
chmod +x service_macros_installer.sh
bash ./service_macros_installer.sh install

```

Running this command will automatically install all files along with adding update manager to your `moonraker.conf`

Add `[include ServiceSettings.cfg]` to your `printer.cfg`

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

---

# 🗂️ **Folder Structure**

```
printer.cfg
└── ServiceSettings.cfg     ← User-editable settings file

config/ServiceMacros/
    ├── Service_Main.cfg      ← Service menu + positioning logic
    ├── Service_Probe.cfg     ← Probe & dockable probe handling
    ├── Service_Checks.cfg    ← Diagnostics suite (fans, wiggle, heater tests)
    └── Service_Nozzle.cfg    ← Hot & cold nozzle change workflows
```

---

# 🔧 **Configuration**

All user settings live in:

```
ServiceSettings.cfg
```

### **Settings Overview**

| Setting | Description |
|--------|-------------|
| `variable_retract_distance` | Filament movement distance used during retraction/extrusion |
| `variable_retract_temp` | Hotend temp used to retract filament |
| `variable_nozzle_swap_temp` | Hot-swap temperature |
| `variable_cold_swap_hotend` | Enable for cold-swap systems (e.g. Revo) |
| `variable_cold_swap_temp` | Temperature required before a cold nozzle swap |
| `variable_leds` | Enables LED status feedback |
| `variable_dockable_probe` | Enables probe attach/detach handling |
| `variable_attach_probe` | G-code used to attach the probe |
| `variable_detach_probe` | G-code used to detach the probe |
| `variable_autoprobe_after_nozzle_change` | Runs probe repeatability test after nozzle swap |

---

# 🛡️ **Safety Features**

- Smart homing  
- Heater shutdown after nozzle swap (when applicable)  
- Temperature-based gating for safe nozzle swaps  
- Dockable probe validation  
- State saving + restoration  
- LEDs for visual feedback   
- All diagnostic tests return to safe positions automatically  

---

# 💬 **Console Feedback**

Every macro outputs clear `M118` lines for:

- Temperatures  
- Task progress  
- Probe results  
- Safety steps  
- Movement details  
- Diagnostic outcomes  

This makes it easy to follow along during maintenance.

---

# Smart Homing
```
_Smart_Homing
```
- Can be used in place of other G28 commands in other macros.
- A quick "home the machine if it hasnt been" script

---

## 🙌 Contributions

Pull requests and improvements are welcome.

