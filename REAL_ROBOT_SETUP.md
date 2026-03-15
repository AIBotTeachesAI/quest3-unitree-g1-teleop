# Real Robot Setup - Terminal by Terminal

## Prerequisites Check

**On the workstation (via SSH), find your Wi-Fi IP:**
```bash
# Find Wi-Fi interface (usually wlp*, wlan*, or similar)
ip addr show | grep -E "inet.*192\.168\." | grep -v "192.168.123"

# Or list all interfaces and their IPs
ip addr show

# Common Wi-Fi IP ranges: 192.168.1.x, 192.168.0.x, 192.168.104.x, etc.
# Robot Ethernet is usually: 192.168.123.x (ignore this one)
```

**Example output:**
```
inet 192.168.104.65/24  ← This is your Wi-Fi IP (use this for Quest 3)
inet 192.168.123.15/24  ← This is robot Ethernet (ignore for Quest)
```

---

## Terminal 1: C++ Deploy (Real Robot)

**SSH to workstation, then:**
```bash
cd /home/stickbot/projects/hack_groot_sonic/GR00T-WholeBodyControl/gear_sonic_deploy
bash deploy.sh real --input-type zmq_manager
```

**Wait for:**
```
[DEBUG] G1Deploy object created successfully!
Init Done
[ZMQManager] Waiting for planner to be initialized
```

**Keep this terminal running!**

---

## Terminal 2: Quest 3 Server

**SSH to workstation, then:**
```bash
cd /home/stickbot/projects/hack_groot_sonic/GR00T-WholeBodyControl
source .venv_sim/bin/activate
bash run_quest3_server.sh
```

**The script will show:**
```
Workstation IP: <some-ip>
```

**⚠️ IMPORTANT:** If the IP shown is wrong (e.g., shows 192.168.123.x), you need to fix it:

**Option A: Manually set the IP in the script**
```bash
# Edit run_quest3_server.sh and change line 9:
# From: IP=$(hostname -I | awk '{print $1}')
# To:   IP="192.168.104.65"  # Your actual Wi-Fi IP
```

**Option B: Use environment variable**
```bash
export QUEST3_IP="192.168.104.65"  # Your Wi-Fi IP
cd /home/stickbot/projects/hack_groot_sonic/GR00T-WholeBodyControl
source .venv_sim/bin/activate
# Then modify the script or pass IP directly
```

**Keep this terminal running!**

---

## Terminal 3: Quest 3 Headset Connection

**On Quest 3 headset (NOT via SSH):**

1. **Make sure Quest 3 is on the SAME Wi-Fi network** as the workstation
2. **Open Meta Quest Browser**
3. **Go to:** `https://<WORKSTATION_WIFI_IP>:8443`
   - Example: `https://192.168.104.65:8443`
4. **Accept certificate warning:**
   - Tap "Advanced" → "Proceed anyway"
5. **Also visit:** `https://<WORKSTATION_WIFI_IP>:8765` and accept cert
6. **Go back to:** `https://<WORKSTATION_WIFI_IP>:8443`
7. **Tap "Connect WS"** (status should turn green)
8. **Tap "Start VR"** to begin tracking

**You should see in Terminal 2:**
```
[Manager] Quest 3 connected!
```

---

## Operation Sequence

1. **Get into calibration pose:**
   - Stand with arms in L-shape (elbows at 90°, arms parallel to floor)

2. **Press Y on Quest 3 controller:**
   - Calibration happens
   - Policy starts (robot should stabilize)

3. **Use Quest 3 controls:**
   - **Left Stick** = Move forward/back/left/right
   - **Right Stick** = Rotate/yaw
   - **X** = Toggle VR 3PT (arms follow your hands)
   - **Triggers** = Hand grasp (when VR 3PT is on)
   - **A** = Emergency stop

---

## Troubleshooting: Quest 3 Can't Connect

**Problem:** Quest 3 shows "Connection refused" or can't reach the server

**Solutions:**

1. **Check firewall:**
```bash
# Allow ports 8443 and 8765
sudo ufw allow 8443/tcp
sudo ufw allow 8765/tcp
```

2. **Verify Wi-Fi IP is correct:**
```bash
# On workstation, check which IP Quest 3 should use
ip route | grep default
# Should show Wi-Fi interface, not Ethernet

# If Ethernet is default route, fix it:
sudo ip route del default via 192.168.123.1
sudo ip route add default via <WIFI_GATEWAY> dev <WIFI_INTERFACE>
```

3. **Test connectivity from Quest 3:**
   - In Quest 3 browser, try: `https://<WORKSTATION_WIFI_IP>:8443`
   - Should see the WebXR page (even if cert warning appears)

4. **Check if server is listening:**
```bash
# On workstation
netstat -tlnp | grep -E "8443|8765"
# Should show Python processes listening
```

5. **If using Tailscale/VPN:**
   - Use the Tailscale IP (100.x.x.x) instead of local Wi-Fi IP
   - Make sure Quest 3 is also on Tailscale network

---

## Emergency Stop

**Always available:**
- **Press A on Quest 3** = Soft stop (exits manager)
- **Press O in Terminal 1 or 2** = Hard emergency stop (kills C++ deploy)

---

## Network Architecture

```
Quest 3 (Wi-Fi)  ←→  Workstation Wi-Fi (192.168.x.x)
                              ↓
                    C++ Deploy (Terminal 1)
                              ↓
                    Robot (Ethernet 192.168.123.x)
```

**Key:** Quest 3 and Robot use **different networks** (Wi-Fi vs Ethernet), so they don't conflict.
