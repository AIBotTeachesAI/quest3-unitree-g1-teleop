# Quest 3 Teleop for Unitree G1 — Complete Setup Guide

## Overview

Control a Unitree G1 humanoid robot using Meta Quest 3 VR controllers via the GEAR-SONIC whole-body control policy. Works in MuJoCo simulation and on real robot.

**3-Terminal Architecture:**
| Terminal | Role | Description |
|---|---|---|
| Terminal 1 | MuJoCo Sim | The robot's body (skip for real robot) |
| Terminal 2 | C++ Deploy | The robot's brain (runs policy) |
| Terminal 3 | Quest 3 Server | Your hands (sends VR data to brain) |

---

## Step 1 — Clone the Repository

```bash
# Fix Git LFS config (if downloads are blocked)
git config --global --unset lfs.fetchexclude
git config --global --unset lfs.fetchinclude

# Clone
mkdir -p ~/projects/hack_groot_sonic
cd ~/projects/hack_groot_sonic
git clone https://github.com/NVlabs/GR00T-WholeBodyControl.git
cd GR00T-WholeBodyControl

# Pull all LFS files (3D models, libraries)
git lfs pull
```

### Verify LFS files downloaded correctly
```bash
# Should show binary data, NOT text starting with "version https://git-lfs.github.com"
file gear_sonic_deploy/thirdparty/unitree_sdk2/lib/x86_64/libunitree_sdk2.a
# Expected: "current ar archive"

file gear_sonic/data/robot_model/model_data/g1/meshes/left_hip_pitch_link.STL
# Expected: NOT "ASCII text"
```

---

## Step 2 — Build the C++ Deploy

```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl/gear_sonic_deploy
just build
```

Wait for successful build. Requires: CMake, g++, CUDA, TensorRT, ONNX Runtime.

---

## Step 3 — Download Model Checkpoints

```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl
pip install huggingface_hub
python download_from_hf.py
```

This downloads GEAR-SONIC ONNX models (encoder, decoder, planner) into `gear_sonic_deploy/`.

---

## Step 4 — Set Up Python Environment

```bash
# Create conda environment for simulation
conda create -n gear_sonic_sim python=3.10 -y
conda activate gear_sonic_sim

# Install simulation dependencies
pip install mujoco tyro scipy numpy

# Install Quest 3 teleop dependencies
uv pip install pyzmq websockets msgpack
```

---

## Step 5 — Copy Quest 3 Teleop Files

These files enable Quest 3 VR control (the original repo only supports PICO VR):

### Files added/modified:

| File | Purpose |
|---|---|
| `run_quest3_server.sh` | Launch script for Quest 3 server (Terminal 3) |
| `deploy_sonic_with_zmq.sh` | Wrapper to launch C++ deploy with ZMQ input |
| `gear_sonic/scripts/quest3_manager_thread_server.py` | Quest 3 teleop manager (button logic, mode switching) |
| `gear_sonic/utils/teleop/common.py` | Shared utilities (enums, helpers) for teleop |
| `gear_sonic/utils/teleop/vr/quest3_reader.py` | WebSocket server for Quest 3 tracking data |
| `gear_sonic/utils/teleop/vr/quest3_webxr_app/index.html` | WebXR app served to Quest 3 browser |
| `install_scripts/install_quest3.sh` | TLS certificate generator |
| `gear_sonic/data/robot_model/model_data/g1/scene_43dof.xml` | MuJoCo scene (room with walls + lighting) |

---

## Step 6 — Generate TLS Certificates

Quest 3 browser requires HTTPS/WSS for WebXR:

```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl
bash install_scripts/install_quest3.sh
```

This creates self-signed certs in `gear_sonic/utils/teleop/vr/quest3_certs/`.

---

## Step 7 — Configure `run_quest3_server.sh`

Edit line 53 to activate your conda environment (not a venv):

```bash
# Change this line:
source .venv_sim/bin/activate

# To this:
eval "$(conda shell.bash hook)" && conda activate gear_sonic_sim
```

---

## Step 8 — Modifications We Made

### 8a. Quest 3 Controller Bindings (`quest3_manager_thread_server.py`)

Changed from PICO's A+B+X+Y combo to simple single buttons:

| Button | Action |
|---|---|
| **Y** (left controller) | Start — calibrate + engage policy |
| **A** (right controller) | Stop — exits Quest 3 manager, robot stays standing |
| **X** (left controller) | Toggle arm tracking (VR 3PT mode) |
| **Left stick** | Move (forward/back/strafe) |
| **Right stick** | Turn/rotate |
| **Triggers** | Hand grasp (when arm tracking on) |
| **Grips** | Hand grip (when arm tracking on) |

### 8b. Added 2-Second Cooldown

Prevents accidental double-presses from triggering mode switches too fast.

### 8c. Default Locomotion Mode

- **For simulation:** Changed to `LocomotionMode.WALK` (robot walks by default)
- **For real robot:** Changed to `LocomotionMode.IDLE` (robot stands still, arms only)

To switch between them, edit `quest3_manager_thread_server.py`:
```python
# Line ~85: Change to WALK or IDLE
self.mode = LocomotionMode.IDLE   # real robot (safe)
self.mode = LocomotionMode.WALK   # simulation
```

### 8d. Safe Stop Behavior

Changed A button to **not** send a stop command to the C++ deploy. This prevents the robot from going limp and falling. Instead, the Quest 3 manager just exits, and the C++ policy keeps the robot standing.

### 8e. MuJoCo Scene (`scene_43dof.xml`)

Added a room environment with:
- Wood floor, 4 walls, warm indoor lighting
- Backup with table + objects saved as `scene_43dof.xml.bak_room_table`

---

## Running in Simulation

### Terminal 1 — MuJoCo Simulator
```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl
conda activate gear_sonic_sim
python gear_sonic/scripts/run_sim_loop.py
```

### Terminal 2 — C++ Policy Deploy
```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl/gear_sonic_deploy
bash deploy.sh sim --input-type zmq_manager
```
Wait for "Init done".

### Terminal 3 — Quest 3 Server
```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl
bash run_quest3_server.sh
```

### Connect Quest 3
1. Quest 3 must be on **same Wi-Fi** as workstation
2. Open **Meta Quest Browser** on the headset
3. Go to `https://<workstation-ip>:8443`
4. Accept the self-signed certificate (Advanced → Proceed)
5. Also visit `https://<workstation-ip>:8765` and accept that cert
6. Go back to `https://<workstation-ip>:8443`
7. Tap **Connect WS** (status turns green)
8. Tap **Start VR**

### Operate
1. **Get into calibration pose:** Stand upright, arms at sides, forearms bent 90° forward (L-shape), palms inward
2. **Press Y** — policy starts, robot stands up
3. **Press `9` in MuJoCo window** — drops robot to ground (do this AFTER pressing Y)
4. Use **left stick** to walk, **right stick** to turn
5. **Press X** to enable arm tracking (arms follow your hands)
6. **Press A** to stop (robot stays standing)

---

## Running on Real Robot

### Prerequisites
- Ethernet cable from workstation to robot (192.168.123.x network)
- Robot powered on, in default stand mode
- Someone physically near the robot at all times

### Verify Network
```bash
ip addr | grep 192.168.123
# Should show an IP like 192.168.123.222
```

### Terminal 1 — Skip (no MuJoCo for real robot)

### Terminal 2 — C++ Policy Deploy (real)
```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl/gear_sonic_deploy
bash deploy.sh real --input-type zmq_manager
```
Wait for "Init done".

### Terminal 3 — Quest 3 Server (same as sim)
```bash
cd ~/projects/hack_groot_sonic/GR00T-WholeBodyControl
bash run_quest3_server.sh
```

### Connect Quest 3 (same steps as simulation)

### Operate
1. Get into calibration pose
2. Press **Y** — policy engages
3. Press **X** — enables arm tracking (move SLOWLY!)
4. Press **A** — safely stops Quest 3 manager, robot stays standing
5. Press **O** in Terminal 2 — full emergency stop (robot goes limp, someone must catch it)

---

## Emergency Stop Methods

| Method | Effect | When to Use |
|---|---|---|
| **A** (Quest 3) | Exits manager, robot stays standing | Normal stop |
| **O** key (Terminal 2) | Robot goes limp (damping only) | Emergency — someone must hold robot |
| **Ctrl+C** (Terminal 2) | Same as O | Emergency |
| **Robot power switch** | Immediate power off | Last resort |

---

## Safety Checklist (Real Robot)

- [ ] Someone physically near the robot at all times
- [ ] Safety operator at Terminal 2 keyboard (ready to press O)
- [ ] Tested in simulation first
- [ ] Default mode set to IDLE (not WALK)
- [ ] Strong private Wi-Fi (< 30ms latency)
- [ ] Calibration pose correct before pressing Y
- [ ] Arms aligned with robot before pressing X
- [ ] Start with very slow, small arm movements
- [ ] If possible, use gantry/harness on robot

---

## Troubleshooting

| Problem | Solution |
|---|---|
| "Neither immersive-ar nor immersive-vr supported" | Open the page in **Quest 3 browser**, not desktop browser |
| Controllers keep connecting/disconnecting | Disable hand tracking in Quest 3 Settings → Movement Tracking |
| Arms go in weird directions | Re-calibrate: press X to exit arm mode, match robot pose, press X again |
| Robot falls after pressing 9 | Press Y (start policy) BEFORE pressing 9 |
| Terminal 2 exits by itself | Restart both Terminal 2 and Terminal 3 together |
| `ModuleNotFoundError: No module named 'zmq'` | `uv pip install pyzmq websockets msgpack` in your conda env |
| Git LFS files not downloading | `git config --global --unset lfs.fetchexclude` then `git lfs pull` |

---

## File Backups

| Backup File | Contains |
|---|---|
| `quest3_manager_thread_server.py.bak_walk` | Version with WALK as default mode |
| `scene_43dof.xml.bak_room_table` | Scene with room + table + graspable red can |

---

## Architecture Diagram

```
Quest 3 Headset (Wi-Fi)
    │
    │ WebSocket (wss://)
    ▼
Terminal 3: quest3_manager_thread_server.py
    │
    │ ZMQ (tcp://)
    ▼
Terminal 2: g1_deploy_onnx_ref (C++ / TensorRT)
    │
    │ DDS / Unitree SDK2
    ▼
Terminal 1: MuJoCo Sim  ──OR──  Real G1 Robot (Ethernet)
```
