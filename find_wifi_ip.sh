#!/usr/bin/env bash
# Find the Wi-Fi IP address (excluding robot Ethernet)

echo "Finding Wi-Fi IP address..."
echo ""

# Method 1: Exclude robot Ethernet network (192.168.123.x)
WIFI_IP=$(ip addr show | grep -E "inet.*192\.168\." | grep -v "192.168.123" | head -1 | awk '{print $2}' | cut -d'/' -f1)

if [ -z "$WIFI_IP" ]; then
    # Method 2: Find interface that's not the robot Ethernet
    WIFI_IP=$(ip route | grep default | grep -v "192.168.123" | awk '{print $5}' | head -1 | xargs -I {} ip addr show {} | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
fi

if [ -z "$WIFI_IP" ]; then
    # Method 3: List all non-loopback IPs
    echo "Could not auto-detect Wi-Fi IP. Available IPs:"
    ip addr show | grep "inet " | grep -v "127.0.0.1" | grep -v "192.168.123"
    echo ""
    echo "Please manually set QUEST3_IP environment variable:"
    echo "  export QUEST3_IP=\"192.168.x.x\""
    exit 1
fi

echo "Wi-Fi IP found: $WIFI_IP"
echo ""
echo "Use this IP in Quest 3 browser:"
echo "  https://${WIFI_IP}:8443"
echo ""
echo "To use this IP automatically, run:"
echo "  export QUEST3_IP=\"${WIFI_IP}\""
echo "  bash run_quest3_server.sh"
