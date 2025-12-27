# VPN Lifecycle State Machine

## Overview

The VPN lifecycle manages WireGuard tunnel connections for secure remote access to the photo host. The state machine handles automatic network mode switching, app lifecycle events, and user preferences.

## State Diagram

```
                    ┌──────────────────────────────────────┐
                    │                                      │
                    │         App Launch / Init            │
                    │                                      │
                    └───────────────┬──────────────────────┘
                                    │
                                    ▼
                         ┌──────────────────┐
                         │                  │
                         │   DETERMINING    │◄──────────────┐
                         │                  │               │
                         └────────┬─────────┘               │
                                  │                         │
                    Network Reachability Check              │
                                  │                         │
                    ┌─────────────┴─────────────┐           │
                    │                           │           │
           LAN Reachable                 Not Reachable      │
                    │                           │           │
                    ▼                           ▼           │
         ┌──────────────────┐        ┌──────────────────┐  │
         │                  │        │                  │  │
         │    LAN_MODE      │        │  VPN_REQUIRED    │  │
         │   (Direct API)   │        │                  │  │
         │                  │        └────────┬─────────┘  │
         └────────┬─────────┘                 │            │
                  │                           │            │
                  │                  Check User Override   │
                  │                           │            │
                  │                ┌──────────┴─────────┐  │
                  │                │                    │  │
                  │         Override=Never       Override=Always │
                  │         Use VPN               or Auto  │
                  │                │                    │  │
                  │                ▼                    ▼  │
                  │     ┌──────────────────┐  ┌──────────────────┐
                  │     │                  │  │                  │
                  │     │    LAN_MODE      │  │   CONNECTING     │
                  │     │  (Force Direct)  │  │   (Starting VPN) │
                  │     │                  │  │                  │
                  │     └──────────────────┘  └────────┬─────────┘
                  │                                    │
                  │                           VPN Connection
                  │                                    │
                  │                        ┌───────────┴─────────┐
                  │                        │                     │
                  │                    Success                 Failure
                  │                        │                     │
                  │                        ▼                     ▼
                  │              ┌──────────────────┐  ┌──────────────────┐
                  │              │                  │  │                  │
                  │              │   VPN_ACTIVE     │  │   VPN_ERROR      │
                  │              │  (Tunnel UP)     │  │                  │
                  │              │                  │  └────────┬─────────┘
                  │              └────────┬─────────┘           │
                  │                       │                     │
                  │                       │              Retry (max 3)
                  │                       │                     │
                  └───────────────────────┴─────────────────────┘
                                          │
                                          │
                        ┌─────────────────┼─────────────────┐
                        │                 │                 │
                 LAN Available    App Background      User Disconnect
                        │                 │                 │
                        ▼                 ▼                 ▼
                  ┌──────────────────────────────────────────┐
                  │                                          │
                  │         TEARING_DOWN                     │
                  │     (Stopping VPN Tunnel)                │
                  │                                          │
                  └───────────────┬──────────────────────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │                  │
                         │      IDLE        │
                         │  (No VPN Active) │
                         │                  │
                         └──────────────────┘
```

## States

### 1. IDLE
**Description:** No VPN tunnel active. App either not running, in background, or using LAN mode.

**Entry Conditions:**
- App startup (before network check)
- VPN teardown completed
- App backgrounded (after teardown)

**Exit Conditions:**
- App foreground + remote access needed → DETERMINING
- Network change detected → DETERMINING

**Characteristics:**
- No WireGuard process running
- No IP address assigned on tunnel interface
- Minimal battery usage

---

### 2. DETERMINING
**Description:** Evaluating network conditions to determine if VPN is needed.

**Entry Conditions:**
- App foreground launch
- Network change event
- Manual refresh triggered
- Failed VPN attempt (retry)

**Actions:**
1. Check if LAN discovery finds host (mDNS timeout: 3 seconds)
2. If found, attempt direct HTTP health check
3. Check user override settings
4. Evaluate Wi-Fi SSID against trusted networks

**Exit Conditions:**
- Host reachable on LAN → LAN_MODE
- Host not reachable + VPN allowed → VPN_REQUIRED
- Host not reachable + VPN disabled → VPN_ERROR

**Timeout:** 5 seconds max

---

### 3. LAN_MODE
**Description:** Direct connection to host via LAN (no VPN).

**Entry Conditions:**
- Host reachable via mDNS and direct API
- User override = "Never use VPN"
- On trusted Wi-Fi network

**Characteristics:**
- Direct HTTP API calls to host
- Fastest performance, no encryption overhead
- Host API address: `http://<lan-ip>:8080`

**Monitoring:**
- Periodic reachability check (every 30 seconds)
- Network change listener active

**Exit Conditions:**
- Network change detected → DETERMINING
- API call fails (timeout/error) → DETERMINING
- App backgrounded → IDLE

---

### 4. VPN_REQUIRED
**Description:** Remote access needed but VPN not yet connected.

**Entry Conditions:**
- Host not reachable on LAN
- User override = "Always use VPN" or "Auto"
- Network is cellular or untrusted Wi-Fi

**Actions:**
1. Load WireGuard configuration from secure storage
2. Display "Connecting to VPN" UI with progress
3. Transition to CONNECTING

**Exit Conditions:**
- User cancels → IDLE
- Proceed to connection → CONNECTING

---

### 5. CONNECTING
**Description:** Actively establishing WireGuard tunnel.

**Entry Conditions:**
- From VPN_REQUIRED state
- Retry after VPN_ERROR

**Actions:**
1. **Phase 1: Checking network** (0.5s)
   - Verify internet connectivity
   - Update UI: "Checking network..."

2. **Phase 2: Starting VPN** (1-2s)
   - Initialize WireGuard userspace/kernel module
   - Configure tunnel interface
   - Update UI: "Starting VPN..."

3. **Phase 3: Handshake** (2-5s)
   - Perform WireGuard handshake with host
   - Wait for first packet exchange
   - Update UI: "Handshake..."

4. **Phase 4: Verifying host** (1-2s)
   - Send HTTP health check to host via tunnel
   - Verify API is reachable
   - Update UI: "Verifying host..."

5. **Phase 5: Loading library** (0.5s)
   - Initialize photo gallery data
   - Update UI: "Loading library..."

**Exit Conditions:**
- All phases succeed → VPN_ACTIVE
- Any phase fails → VPN_ERROR
- User cancels → TEARING_DOWN
- App backgrounded → TEARING_DOWN

**Timeout:** 15 seconds total

**UI Elements:**
```
┌─────────────────────────────────┐
│  Connecting to Photo Library    │
│                                  │
│  ● Checking network              │
│  ○ Starting VPN                  │
│  ○ Handshake                     │
│  ○ Verifying host                │
│  ○ Loading library               │
│                                  │
│  [Cancel]                        │
└─────────────────────────────────┘
```

---

### 6. VPN_ACTIVE
**Description:** WireGuard tunnel successfully established and host is reachable.

**Entry Conditions:**
- CONNECTING phase completed successfully
- WireGuard handshake valid

**Characteristics:**
- WireGuard tunnel interface UP
- Host API address: `http://10.100.0.1:8080`
- Encrypted communication
- Ongoing handshake refresh (every 2 minutes)

**Monitoring:**
- Handshake liveness check (alert if no handshake in 3 minutes)
- API health check (every 60 seconds)
- Network change listener
- Battery usage monitoring

**UI Elements:**
- Status indicator: "Connected via VPN"
- Connection info button (show tunnel IP, handshake time, data usage)
- Disconnect button

**Exit Conditions:**
- LAN becomes available → TEARING_DOWN → LAN_MODE
- API health check fails → TEARING_DOWN → DETERMINING
- App backgrounded → TEARING_DOWN
- User disconnect → TEARING_DOWN
- Network lost → TEARING_DOWN → DETERMINING

---

### 7. VPN_ERROR
**Description:** VPN connection failed or encountered error.

**Entry Conditions:**
- CONNECTING failed (timeout, handshake error, etc.)
- VPN_ACTIVE experienced fatal error

**Error Types:**
1. **Network Error:** No internet connectivity
2. **Handshake Timeout:** Host not responding to WireGuard
3. **Configuration Error:** Invalid WireGuard config
4. **Host Unreachable:** Tunnel up but host API not accessible
5. **Authentication Error:** API token invalid
6. **Device Revoked:** Host revoked this device's access

**Actions:**
1. Log error details
2. Display user-friendly error message
3. Provide retry button
4. Show troubleshooting tips

**UI Elements:**
```
┌─────────────────────────────────┐
│  Connection Failed               │
│                                  │
│  ⚠ Unable to reach photo host    │
│                                  │
│  Error: Handshake timeout        │
│                                  │
│  Troubleshooting:                │
│  • Check internet connection     │
│  • Verify host is online         │
│  • Try LAN connection            │
│                                  │
│  [Retry]  [Use LAN]             │
└─────────────────────────────────┘
```

**Retry Logic:**
- Attempt 1: Immediate retry
- Attempt 2: Wait 5 seconds
- Attempt 3: Wait 15 seconds
- After 3 attempts: Show error UI

**Exit Conditions:**
- User retry → DETERMINING
- User cancel → IDLE
- Network change → DETERMINING

---

### 8. TEARING_DOWN
**Description:** Gracefully shutting down VPN tunnel.

**Entry Conditions:**
- App backgrounded
- App closed
- LAN connection available (switching to LAN mode)
- User manual disconnect
- Error requiring reconnection

**Actions:**
1. Stop WireGuard tunnel
2. Remove tunnel interface
3. Clear tunnel IP assignment
4. Persist necessary state for quick reconnect
5. Update UI: "Disconnecting..."

**Timeout:** 3 seconds (then force kill if needed)

**Exit Conditions:**
- Teardown complete → IDLE (or LAN_MODE if switching)

---

## App Lifecycle Integration

### iOS

#### App Launch
```swift
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: ...) {
    vpnManager.setState(.DETERMINING)
}
```

#### App Foreground
```swift
func applicationWillEnterForeground(_ application: UIApplication) {
    if vpnManager.state == .IDLE && needsRemoteAccess() {
        vpnManager.setState(.DETERMINING)
    }
}
```

#### App Background
```swift
func applicationDidEnterBackground(_ application: UIApplication) {
    if vpnManager.state in [.VPN_ACTIVE, .CONNECTING] {
        vpnManager.setState(.TEARING_DOWN)
    }
}
```

#### App Terminate
```swift
func applicationWillTerminate(_ application: UIApplication) {
    vpnManager.forceStop()  // Best-effort teardown
}
```

### Android

#### Activity Lifecycle
```kotlin
override fun onResume() {
    super.onResume()
    if (vpnManager.state == VpnState.IDLE && needsRemoteAccess()) {
        vpnManager.setState(VpnState.DETERMINING)
    }
}

override fun onPause() {
    super.onPause()
    if (!isChangingConfigurations && isFinishing) {
        vpnManager.tearDown()
    }
}

override fun onDestroy() {
    super.onDestroy()
    vpnManager.forceStop()
}
```

---

## User Override Settings

### Setting: VPN Mode Preference

**Options:**
1. **Auto (Default)**
   - Use LAN when available
   - Use VPN when remote
   - Follow standard state machine

2. **Always VPN**
   - Force VPN even on LAN
   - Useful for testing or security paranoia
   - Skip LAN reachability check

3. **Never VPN on Wi-Fi**
   - Only allow VPN on cellular
   - Prevent accidental VPN on untrusted Wi-Fi
   - Show warning if host unreachable

4. **LAN Only**
   - Disable VPN completely
   - Only connect when on same network as host
   - Useful for privacy-conscious users

### Setting: Trusted Networks

Users can designate specific Wi-Fi SSIDs as "trusted":
- `Home Network` → Always try LAN first
- `Office WiFi` → Allow VPN if needed
- `Coffee Shop WiFi` → VPN required (untrusted)

### Setting: Per-Host Configuration

Multiple hosts can have different settings:
```json
{
  "hosts": [
    {
      "host_id": "uuid-1",
      "name": "Home Server",
      "vpn_mode": "auto",
      "trusted_networks": ["Home WiFi"]
    },
    {
      "host_id": "uuid-2",
      "name": "Parents' Server",
      "vpn_mode": "vpn_only",
      "trusted_networks": []
    }
  ]
}
```

---

## Network Change Handling

### Wi-Fi to Cellular
```
Current: VPN_ACTIVE (via WiFi)
Event:   Network changed to Cellular
Action:  Stay in VPN_ACTIVE (already using VPN)
```

### Cellular to Wi-Fi
```
Current: VPN_ACTIVE (via Cellular)
Event:   Network changed to WiFi
Action:  → DETERMINING → Check LAN → Possibly switch to LAN_MODE
```

### Wi-Fi to Different Wi-Fi
```
Current: LAN_MODE (on Home WiFi)
Event:   Network changed to Coffee Shop WiFi
Action:  → DETERMINING → Host not found → VPN_REQUIRED
```

### Network Lost
```
Current: VPN_ACTIVE
Event:   No network connectivity
Action:  → VPN_ERROR (wait for network)
```

---

## Battery Optimization

### Strategies

1. **Avoid VPN When Possible**
   - Prefer LAN connections
   - Don't keep VPN active in background

2. **Efficient Monitoring**
   - Use system network change broadcasts (don't poll)
   - Health checks: 60s when active, none when idle

3. **WireGuard Keepalive**
   - Set to 25 seconds (balance between reliability and battery)
   - Disable when app backgrounded

4. **Background Restrictions**
   - Don't start VPN from background
   - Tear down VPN when backgrounded
   - Only connect when app in foreground

---

## Security Considerations

### 1. VPN Configuration Storage
- Store WireGuard private keys in OS keychain/keystore
- Never log private keys
- Encrypt configuration files at rest

### 2. API Token Management
- Use short-lived tokens (1 hour)
- Refresh tokens stored securely
- Invalidate tokens on VPN teardown (optional)

### 3. Host Verification
- Verify host public key matches expected
- Reject WireGuard handshake from unknown hosts
- Alert user if host key changes

### 4. Path Traversal Protection
- All API calls validate file paths
- Reject requests with `..` or absolute paths
- Only serve files within configured photo roots

### 5. Rate Limiting
- Enforce rate limits even over VPN
- Prevent brute force attacks
- Monitor for suspicious activity

---

## Testing Scenarios

### Scenario 1: Normal LAN Usage
1. User launches app on home Wi-Fi
2. Host discovered via mDNS
3. App enters LAN_MODE
4. User browses photos (no VPN)

### Scenario 2: Remote Access
1. User launches app on cellular
2. No LAN host found
3. VPN connection initiated
4. CONNECTING → VPN_ACTIVE
5. User browses photos via VPN

### Scenario 3: Network Transition
1. User on cellular with VPN active
2. Connects to home Wi-Fi
3. App detects LAN availability
4. Tears down VPN
5. Switches to LAN_MODE

### Scenario 4: App Background
1. User browses photos via VPN
2. User switches to another app
3. VPN tears down within 3 seconds
4. User returns to app
5. VPN reconnects if still needed

### Scenario 5: Connection Failure
1. User on cellular, initiates VPN
2. Handshake times out
3. App shows VPN_ERROR
4. User clicks retry
5. Eventually succeeds or gives up

---

## Metrics & Monitoring

Track these metrics for debugging and optimization:

- Time in each state (per session)
- VPN connection success rate
- VPN connection latency (handshake time)
- LAN detection accuracy
- Mode switches per session
- Battery usage (VPN vs LAN)
- API latency (VPN vs LAN)
- Background VPN teardown success rate

---

## Future Enhancements

1. **WireGuard Roaming**
   - Keep VPN active during network changes
   - Requires careful battery optimization

2. **Split Tunneling**
   - Only route photo API traffic through VPN
   - Allow other apps to use direct internet

3. **Multi-Host Support**
   - Connect to multiple hosts simultaneously
   - Separate VPN tunnels per host

4. **On-Demand VPN**
   - iOS Network Extension on-demand rules
   - Start VPN automatically when needed
