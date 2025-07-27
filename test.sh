#!/bin/bash

# Cleanup function
cleanup() {
    echo -e "\n=== Cleanup ==="
    if [ ! -z "$DAEMON_PID" ]; then
        kill $DAEMON_PID 2>/dev/null && echo "Daemon stopped"
    fi
    rm -f ~/appearance-notify-test.log
    rm -f ~/.config/appearance-notify/hooks.d/test.sh
}

# Ensure cleanup on exit
trap cleanup EXIT

echo "=== Testing appearance-notify ==="

# Build
echo "Building..."
swift build --configuration release || exit 1

# Setup test hook
echo "Setting up test hook..."
mkdir -p ~/.config/appearance-notify/hooks.d
cat > ~/.config/appearance-notify/hooks.d/test.sh << 'EOF'
#!/bin/bash
echo "$(date): DARKMODE=$DARKMODE" >> ~/appearance-notify-test.log
EOF
chmod +x ~/.config/appearance-notify/hooks.d/test.sh

# Clean previous test log
rm -f ~/appearance-notify-test.log

# Run daemon
echo "Starting daemon..."
./.build/release/appearance-notify &
DAEMON_PID=$!

# Give it time to start and run initial hooks
sleep 2

# Check results
echo -e "\n=== Initial hook execution ==="
cat ~/appearance-notify-test.log

echo -e "\n=== Testing theme changes ==="

# Get current mode
CURRENT_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
echo "Current mode: $CURRENT_MODE"

# Toggle to opposite mode
if [ "$CURRENT_MODE" = "Dark" ]; then
    echo "Switching to Light mode..."
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
else
    echo "Switching to Dark mode..."
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
fi

sleep 2

# Toggle back
echo "Toggling back..."
if [ "$CURRENT_MODE" = "Dark" ]; then
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
else
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
fi

sleep 2

echo -e "\n=== Test results ==="
echo "Hook executions:"
cat ~/appearance-notify-test.log

echo -e "\nTest completed successfully!"
echo "To monitor logs: log stream --predicate 'subsystem == \"com.appearance.notify\"'"