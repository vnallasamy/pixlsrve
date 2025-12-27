# Pairing & Connectivity Test Plan

## Overview

This document outlines end-to-end testing scenarios for device pairing and network connectivity in the PixlSrve system.

## Test Environment Setup

### Requirements

#### Host System
- **OS:** Windows 10+ or macOS 11+
- **Network:** Connected to Wi-Fi router with internet
- **Firewall:** Configured to allow WireGuard port 51820
- **Dependencies:** Go 1.21+, SQLite, WireGuard tools

#### Mobile Devices
- **iOS:** iPhone running iOS 14+ (physical device, not simulator)
- **Android:** Android 10+ device
- **Both:** Connected to same Wi-Fi as host for LAN tests

#### Network
- **Router:** Supports mDNS/Bonjour
- **Internet:** Active internet connection for VPN tests
- **Cellular:** Mobile data enabled for VPN tests

---

## Test Categories

## 1. Device Pairing Tests

### Test 1.1: Initial Device Pairing (QR Code)

**Objective:** Verify new device can pair with host using QR code.

**Prerequisites:**
- Host app running
- Mobile app installed but not paired

**Steps:**
1. Open host admin UI
2. Navigate to "Add Device" section
3. Click "Generate Pairing QR"
4. Observe QR code displayed with 5-minute countdown
5. Open mobile app
6. Tap "Add Host"
7. Scan QR code with camera
8. Verify device name pre-filled
9. Confirm pairing

**Expected Results:**
- ✅ QR code generates successfully
- ✅ QR code expires after 5 minutes
- ✅ Mobile app scans QR successfully
- ✅ Pairing completes within 5 seconds
- ✅ Mobile app receives:
  - API token
  - WireGuard config
  - Host ID and name
- ✅ Host shows new device in device list
- ✅ Mobile app navigates to photo gallery

**Error Cases:**
- ❌ Scanning expired QR shows "QR code expired"
- ❌ Scanning invalid QR shows "Invalid QR code"
- ❌ Network error during pairing shows retry option

---

### Test 1.2: Manual Device Pairing (IP Entry)

**Objective:** Verify device can pair by manually entering host IP.

**Prerequisites:**
- Host app running on known IP (e.g., 192.168.1.100)
- Mobile app installed

**Steps:**
1. Open mobile app
2. Tap "Add Host Manually"
3. Enter host IP address: `192.168.1.100`
4. Enter port: `8080`
5. Tap "Connect"
6. Wait for host discovery
7. Confirm pairing on both devices
8. Enter device name

**Expected Results:**
- ✅ App validates IP format
- ✅ Connects to host within 3 seconds
- ✅ Shows host name and photo count
- ✅ Pairing completes successfully
- ✅ Mobile app stores host configuration

**Error Cases:**
- ❌ Invalid IP format shows validation error
- ❌ Unreachable IP shows "Cannot reach host"
- ❌ Wrong port shows timeout error

---

### Test 1.3: Multiple Device Pairing

**Objective:** Verify multiple devices can pair with same host.

**Steps:**
1. Pair first device (iPhone) using QR
2. Verify iPhone can access photos
3. Generate new QR code on host
4. Pair second device (Android) using same QR
5. Verify Android can access photos
6. Verify host shows both devices in list

**Expected Results:**
- ✅ Both devices paired successfully
- ✅ Each device has unique WireGuard IP (10.100.0.2, 10.100.0.3)
- ✅ Each device has unique API token
- ✅ Both devices can access photos simultaneously
- ✅ Host lists both devices with correct names

---

### Test 1.4: Device Re-pairing

**Objective:** Verify device can be removed and re-paired.

**Steps:**
1. Pair device
2. On host, revoke device access
3. Verify mobile app shows "Device revoked" error
4. Generate new QR code
5. Re-pair same device

**Expected Results:**
- ✅ Revocation takes effect immediately
- ✅ Old token rejected by API
- ✅ Re-pairing generates new token and key
- ✅ Re-paired device can access photos

---

## 2. LAN Discovery Tests

### Test 2.1: mDNS Discovery

**Objective:** Verify mobile app discovers host via mDNS on LAN.

**Prerequisites:**
- Host and mobile on same Wi-Fi network
- mDNS/Bonjour enabled on router

**Steps:**
1. Start host app (should advertise `_pixlsrve._tcp.local.`)
2. Open mobile app
3. Observe "Discovering hosts..." screen
4. Wait up to 5 seconds

**Expected Results:**
- ✅ Host discovered within 5 seconds
- ✅ Shows host name and photo count
- ✅ Shows "On Local Network" badge
- ✅ Tap host to pair or connect

**Error Cases:**
- ❌ If not found after 5 seconds, show "No hosts found. Try manual setup."

---

### Test 2.2: LAN Direct Connection

**Objective:** Verify mobile connects directly to host on LAN.

**Prerequisites:**
- Device already paired
- Both on same Wi-Fi

**Steps:**
1. Launch mobile app
2. Observe connection status during startup
3. Navigate to photo gallery
4. Load thumbnails
5. Open full-resolution photo

**Expected Results:**
- ✅ Status shows "Connected via LAN"
- ✅ Connection established within 2 seconds
- ✅ Thumbnails load quickly (<1s for 20 items)
- ✅ Full photo loads quickly (<3s for 5MB)
- ✅ No VPN indicator in system tray

**Performance:**
- Thumbnail load: <100ms per image
- Full image (5MB): <3s on typical home Wi-Fi

---

### Test 2.3: LAN Network Reliability

**Objective:** Verify LAN connection handles interruptions.

**Steps:**
1. Connect to host via LAN
2. Browse photos normally
3. Briefly disconnect Wi-Fi (5 seconds)
4. Reconnect Wi-Fi
5. Observe app behavior

**Expected Results:**
- ✅ App shows "Connection lost" during disconnect
- ✅ App automatically reconnects when Wi-Fi restored
- ✅ Resumes photo browsing without requiring manual action
- ✅ No VPN initiated if LAN restored quickly

---

## 3. VPN Connection Tests

### Test 3.1: VPN Connection from Cellular

**Objective:** Verify VPN establishes when host not on LAN.

**Prerequisites:**
- Device paired
- Disable Wi-Fi (use cellular only)
- Host has public IP or port forwarding configured

**Steps:**
1. Launch mobile app on cellular
2. Observe VPN connection progress UI
3. Wait for connection to establish

**Expected Results:**
- ✅ Progress UI shows phases:
  1. "Checking network..." (~0.5s)
  2. "Starting VPN..." (~2s)
  3. "Handshake..." (~3s)
  4. "Verifying host..." (~1s)
  5. "Loading library..." (~0.5s)
- ✅ Total connection time: 5-10 seconds
- ✅ Status shows "Connected via VPN"
- ✅ System VPN indicator appears
- ✅ Photo gallery loads successfully

**Error Cases:**
- ❌ If handshake fails, show "VPN Error" with retry

---

### Test 3.2: VPN Connection Stability

**Objective:** Verify VPN remains stable during use.

**Steps:**
1. Connect via VPN
2. Browse photos for 5 minutes
3. Monitor connection status
4. Load various thumbnails and full images
5. Search photos

**Expected Results:**
- ✅ VPN remains active throughout
- ✅ No disconnections
- ✅ Handshake refreshes every ~2 minutes
- ✅ All API calls succeed
- ✅ Performance acceptable (thumbnails <2s, full <10s)

**Metrics:**
- Latency: <200ms typical
- Thumbnail load: <2s
- Full image (5MB): <10s
- Handshake every 120s ±10s

---

### Test 3.3: VPN Reconnection After Interruption

**Objective:** Verify VPN reconnects after network loss.

**Steps:**
1. Connect via VPN on cellular
2. Enable airplane mode for 10 seconds
3. Disable airplane mode
4. Observe app behavior

**Expected Results:**
- ✅ App detects network loss
- ✅ Shows "Connection lost"
- ✅ When network restored, automatically attempts reconnection
- ✅ VPN re-establishes within 10 seconds
- ✅ Photo browsing resumes

---

### Test 3.4: VPN Handshake Failure

**Objective:** Verify app handles VPN handshake timeout gracefully.

**Setup:**
- Simulate unreachable host (block WireGuard port on host firewall)

**Steps:**
1. Launch app on cellular
2. Attempt VPN connection
3. Wait for handshake timeout (15 seconds)

**Expected Results:**
- ✅ Progress UI shows "Handshake..." phase
- ✅ After 15s timeout, shows "VPN Error"
- ✅ Error message: "Unable to reach photo host"
- ✅ Provides troubleshooting tips
- ✅ "Retry" button available
- ✅ After 3 failed attempts, suggest checking host status

---

## 4. Network Mode Switching Tests

### Test 4.1: LAN to Cellular Transition

**Objective:** Verify seamless transition from LAN to VPN.

**Steps:**
1. Connect to host via LAN
2. Browse photos
3. Disable Wi-Fi (switch to cellular)
4. Observe app behavior
5. Continue browsing photos

**Expected Results:**
- ✅ App detects LAN loss within 5 seconds
- ✅ Shows "Switching to VPN..." notification
- ✅ VPN connection establishes automatically
- ✅ No user action required
- ✅ Photo browsing continues (may pause briefly)
- ✅ Status changes to "Connected via VPN"
- ✅ Total transition time: <10 seconds

---

### Test 4.2: Cellular to LAN Transition

**Objective:** Verify app switches from VPN to LAN when available.

**Steps:**
1. Connect via VPN on cellular
2. Enable Wi-Fi (connect to home network)
3. Wait for LAN detection
4. Observe app behavior

**Expected Results:**
- ✅ App detects LAN availability within 5 seconds
- ✅ Shows "Switching to LAN..." notification
- ✅ VPN tears down gracefully
- ✅ LAN connection establishes
- ✅ Status changes to "Connected via LAN"
- ✅ System VPN indicator disappears
- ✅ Performance improves (faster photo loads)
- ✅ Total transition time: <5 seconds

---

### Test 4.3: Wi-Fi Network Change

**Objective:** Verify app handles changing between different Wi-Fi networks.

**Steps:**
1. Connect via LAN on home Wi-Fi
2. Switch to different Wi-Fi network (e.g., coffee shop)
3. Observe app behavior

**Expected Results:**
- ✅ App detects network change
- ✅ Checks if host reachable on new network
- ✅ If not found, switches to VPN mode
- ✅ If found (unlikely), stays in LAN mode
- ✅ Transition smooth without manual intervention

---

### Test 4.4: Multiple Rapid Network Changes

**Objective:** Verify app handles rapid network switching.

**Steps:**
1. Connect via LAN
2. Toggle Wi-Fi off/on rapidly (5 times in 30 seconds)
3. Observe app behavior

**Expected Results:**
- ✅ App doesn't crash
- ✅ Eventually stabilizes in appropriate mode
- ✅ Doesn't leave VPN dangling
- ✅ No memory leaks
- ✅ User can still browse after stabilization

---

## 5. App Lifecycle Tests

### Test 5.1: VPN Teardown on Background (iOS)

**Objective:** Verify VPN tears down when app backgrounds.

**Steps:**
1. Connect via VPN
2. Press home button (app to background)
3. Wait 5 seconds
4. Check iOS VPN settings

**Expected Results:**
- ✅ VPN tears down within 3 seconds
- ✅ iOS VPN indicator disappears
- ✅ No VPN shown in Settings > VPN
- ✅ App saves state for quick reconnect

**Timing:**
- Teardown complete: <3s

---

### Test 5.2: VPN Teardown on Background (Android)

**Objective:** Verify VPN tears down when app backgrounds.

**Steps:**
1. Connect via VPN
2. Press home button
3. Wait 5 seconds
4. Check Android VPN settings

**Expected Results:**
- ✅ VPN tears down within 3 seconds
- ✅ Android VPN indicator disappears
- ✅ No VPN shown in Settings > Network
- ✅ App saves state

---

### Test 5.3: VPN Reconnect on Foreground

**Objective:** Verify VPN reconnects when app returns to foreground.

**Steps:**
1. Connect via VPN
2. Background app (VPN tears down)
3. Wait 30 seconds
4. Return to app
5. Observe behavior

**Expected Results:**
- ✅ App detects foreground event
- ✅ If on cellular, automatically starts VPN
- ✅ If on LAN, uses direct connection
- ✅ Reconnection fast (<5s)
- ✅ User returns to same screen

---

### Test 5.4: App Force Kill

**Objective:** Verify VPN cleaned up after force kill.

**Steps:**
1. Connect via VPN
2. Force kill app (swipe up on iOS, force stop on Android)
3. Wait 5 seconds
4. Check system VPN status
5. Reopen app

**Expected Results:**
- ✅ VPN tears down (best-effort)
- ✅ No orphaned VPN connection
- ✅ App restarts cleanly
- ✅ Can reconnect successfully

---

### Test 5.5: App Crash During VPN

**Objective:** Verify VPN cleanup on app crash.

**Setup:**
- Trigger crash during active VPN (simulate via test button)

**Steps:**
1. Connect via VPN
2. Trigger crash
3. Check VPN status
4. Reopen app

**Expected Results:**
- ✅ OS cleans up VPN (iOS/Android handle this)
- ✅ No system issues
- ✅ App recovers on restart
- ✅ Can reconnect VPN

---

## 6. User Override Settings Tests

### Test 6.1: "Always Use VPN" Setting

**Objective:** Verify VPN used even when on LAN.

**Steps:**
1. Enable "Always Use VPN" in settings
2. Connect to home Wi-Fi (where host is available)
3. Launch app
4. Observe connection mode

**Expected Results:**
- ✅ App skips LAN detection
- ✅ Initiates VPN connection
- ✅ Connects via VPN despite being on LAN
- ✅ Status shows "Connected via VPN"

---

### Test 6.2: "Never Use VPN on Wi-Fi" Setting

**Objective:** Verify VPN disabled on any Wi-Fi.

**Steps:**
1. Enable "Never Use VPN on Wi-Fi"
2. Connect to random Wi-Fi (not home)
3. Launch app
4. Observe behavior

**Expected Results:**
- ✅ App attempts LAN connection
- ✅ If host not found, shows error (not VPN)
- ✅ Error: "Cannot reach host. Disable 'Never Use VPN on Wi-Fi' or use cellular."
- ✅ No VPN initiated

---

### Test 6.3: "LAN Only" Mode

**Objective:** Verify VPN completely disabled.

**Steps:**
1. Enable "LAN Only" in settings
2. Disable Wi-Fi (use cellular)
3. Launch app

**Expected Results:**
- ✅ App shows "LAN Only mode enabled"
- ✅ Error: "Cannot reach host. Connect to local network."
- ✅ No VPN attempt
- ✅ Suggests enabling VPN in settings

---

### Test 6.4: Trusted Networks

**Objective:** Verify trusted network whitelist.

**Steps:**
1. Add "Home WiFi" to trusted networks
2. Connect to "Home WiFi"
3. Launch app → Should use LAN
4. Connect to "Coffee Shop" (not trusted)
5. Launch app → Should use VPN

**Expected Results:**
- ✅ On trusted Wi-Fi, prefers LAN
- ✅ On untrusted Wi-Fi, uses VPN
- ✅ Setting respected correctly

---

## 7. Performance Tests

### Test 7.1: Large Library Performance

**Setup:**
- Host with 10,000+ photos

**Steps:**
1. Connect via LAN
2. Browse album list
3. Open album with 500 photos
4. Scroll through photo grid
5. Measure metrics

**Expected Results:**
- ✅ Album list loads: <2s
- ✅ 500-photo grid loads: <5s (paginated)
- ✅ Scrolling smooth (60fps)
- ✅ Thumbnails load progressively

---

### Test 7.2: VPN Overhead Measurement

**Steps:**
1. Connect via LAN
2. Download 10MB photo, measure time
3. Connect via VPN
4. Download same photo, measure time
5. Compare

**Expected Results:**
- LAN: ~5-10s (depends on Wi-Fi)
- VPN: +20-30% overhead acceptable
- VPN latency: +50-100ms acceptable

---

### Test 7.3: Battery Usage Test

**Steps:**
1. Fully charge device
2. Use app via VPN for 1 hour (active browsing)
3. Measure battery drain
4. Repeat via LAN for comparison

**Expected Results:**
- VPN: 15-20% battery drain per hour
- LAN: 10-15% battery drain per hour
- VPN overhead: <5% additional drain

---

## 8. Security Tests

### Test 8.1: Revoked Device Access

**Steps:**
1. Pair device
2. Connect and browse photos
3. On host, revoke device
4. Continue using app

**Expected Results:**
- ✅ Next API call returns 401 Unauthorized
- ✅ App shows "Device has been revoked"
- ✅ Clears cached credentials
- ✅ Returns to pairing screen
- ✅ Cannot access photos

---

### Test 8.2: Token Expiration

**Steps:**
1. Pair device
2. Wait for token to expire (1 hour)
3. Attempt to browse photos

**Expected Results:**
- ✅ API returns 401
- ✅ App automatically refreshes token
- ✅ Request retries successfully
- ✅ User unaware of token refresh

---

### Test 8.3: Invalid Certificate

**Setup:**
- Host with self-signed cert that changes

**Steps:**
1. Connect to host
2. Change host certificate
3. Attempt connection

**Expected Results:**
- ✅ App detects certificate change
- ✅ Shows warning: "Host certificate changed"
- ✅ Requires user confirmation
- ✅ Option to re-pair device

---

## 9. Error Handling Tests

### Test 9.1: Host Offline

**Steps:**
1. Stop host app
2. Launch mobile app
3. Attempt connection (both LAN and VPN)

**Expected Results:**
- ✅ LAN: "Host not found"
- ✅ VPN: "VPN established but host unreachable"
- ✅ Helpful error messages
- ✅ Retry option

---

### Test 9.2: Network Completely Offline

**Steps:**
1. Enable airplane mode
2. Launch app

**Expected Results:**
- ✅ Shows "No internet connection"
- ✅ Displays cached photos (if any)
- ✅ Grays out unavailable features
- ✅ Monitors for network restoration

---

### Test 9.3: Slow Network

**Setup:**
- Simulate slow network (network throttling)

**Steps:**
1. Connect with 2G-speed network
2. Browse photos

**Expected Results:**
- ✅ App doesn't crash or timeout
- ✅ Shows loading indicators
- ✅ Progressive image loading
- ✅ User can cancel slow requests

---

## Test Execution Checklist

### Pre-Release Testing

- [ ] All pairing tests pass (1.1 - 1.4)
- [ ] All LAN tests pass (2.1 - 2.3)
- [ ] All VPN tests pass (3.1 - 3.4)
- [ ] All switching tests pass (4.1 - 4.4)
- [ ] All lifecycle tests pass (5.1 - 5.5)
- [ ] All override tests pass (6.1 - 6.4)
- [ ] Performance acceptable (7.1 - 7.3)
- [ ] Security tests pass (8.1 - 8.3)
- [ ] Error handling tests pass (9.1 - 9.3)

### Regression Testing

Run on:
- [ ] iOS (latest)
- [ ] iOS (latest - 1)
- [ ] Android (latest)
- [ ] Android (API 29)
- [ ] Windows 10 host
- [ ] Windows 11 host
- [ ] macOS (latest)
- [ ] macOS (latest - 1)

### Networks Tested

- [ ] Home Wi-Fi (2.4GHz)
- [ ] Home Wi-Fi (5GHz)
- [ ] Public Wi-Fi (coffee shop)
- [ ] Corporate Wi-Fi (if available)
- [ ] Cellular (4G)
- [ ] Cellular (5G)
- [ ] Cellular (poor signal)

---

## Automated Test Coverage

### Unit Tests
- Network reachability detection
- VPN state machine transitions
- Token refresh logic
- Path validation
- SQL queries

### Integration Tests
- API endpoint authentication
- WireGuard handshake
- mDNS discovery
- Database operations

### End-to-End Tests
- Full pairing flow
- Photo gallery navigation
- Network mode switching
- VPN lifecycle

**Target Coverage:** 80%+ code coverage

---

## Test Metrics

Track these metrics:
- Test pass rate (target: 95%+)
- Average connection time (LAN: <2s, VPN: <10s)
- VPN teardown time (target: <3s)
- Network switch time (target: <10s)
- Battery drain (target: <20%/hour)
- Memory usage (target: <100MB)
- Crash rate (target: <0.1%)

---

## Issue Tracking

For failed tests, log:
- Test ID (e.g., 3.1)
- Platform (iOS 15, Android 12, etc.)
- Network conditions
- Failure description
- Steps to reproduce
- Logs and screenshots

---

## Sign-Off

Each test category must be signed off by:
- [ ] Developer
- [ ] QA Engineer
- [ ] Product Owner

**Test Plan Version:** 1.0  
**Last Updated:** 2023-12-27
