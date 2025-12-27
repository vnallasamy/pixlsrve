# PixlSrve Threat Model

## Overview

This document analyzes security threats to the PixlSrve photo hosting system and describes mitigation strategies.

## Assets to Protect

1. **User Photos** - Primary asset; private family photos
2. **Authentication Credentials** - API tokens, WireGuard keys
3. **User Privacy** - Photo metadata, location data, viewing patterns
4. **System Availability** - Host service uptime, mobile app functionality
5. **Network Configuration** - WireGuard configs, IP addresses, ports

## Trust Boundaries

### Boundary 1: Host System
- **Trusted:** Files on host filesystem, SQLite database
- **Untrusted:** Network requests from mobile clients
- **Controls:** Authentication, authorization, path traversal protection

### Boundary 2: Mobile App
- **Trusted:** User interaction, authenticated API calls
- **Untrusted:** Network responses, public Wi-Fi
- **Controls:** Certificate pinning, input validation, secure storage

### Boundary 3: Network (LAN)
- **Trusted:** Home Wi-Fi network (assumed secure)
- **Untrusted:** Other devices on LAN
- **Controls:** Authentication required even on LAN, rate limiting

### Boundary 4: Network (Internet)
- **Trusted:** Nothing
- **Untrusted:** All internet traffic
- **Controls:** WireGuard encryption, minimal exposed services

## Threat Categories

## 1. Authentication & Authorization Threats

### T1.1: Stolen API Token
**Threat:** Attacker obtains valid API token and accesses photos.

**Attack Vector:**
- Token leaked in logs
- Token stolen from mobile device storage
- Man-in-the-middle on insecure network
- Compromised mobile device

**Impact:** HIGH - Full access to victim's photo library

**Mitigations:**
- ✅ Use short-lived tokens (1 hour expiry)
- ✅ Implement refresh token rotation
- ✅ Store tokens in OS secure storage (Keychain/Keystore)
- ✅ Never log tokens
- ✅ Require TLS even on LAN
- ✅ Implement token revocation API
- ✅ Monitor for unusual access patterns
- ✅ Limit token scope (single device only)

**Residual Risk:** MEDIUM - Sophisticated attacker could extract from memory

---

### T1.2: Weak or Missing Authentication
**Threat:** Endpoints accessible without authentication.

**Attack Vector:**
- Developer error leaves endpoint unprotected
- Authentication check bypassed
- Default credentials used

**Impact:** CRITICAL - Unauthorized access to all photos

**Mitigations:**
- ✅ Authentication required for ALL endpoints except `/api/v1/discovery/info` on LAN
- ✅ Middleware enforces authentication globally
- ✅ No default credentials
- ✅ Unit tests verify auth requirement
- ✅ Security scanner checks for unprotected endpoints

**Residual Risk:** LOW

---

### T1.3: Device Pairing Attack
**Threat:** Attacker pairs rogue device to victim's host.

**Attack Vector:**
- Physical access to host during pairing QR code display
- QR code photographed/leaked
- Compromised pairing endpoint

**Impact:** HIGH - Rogue device gets full photo access

**Mitigations:**
- ✅ Pairing QR code displayed for limited time (5 minutes)
- ✅ Pairing requires physical access to host
- ✅ Pairing confirmation on host UI
- ✅ Notification when new device paired
- ✅ Host shows list of paired devices
- ✅ Easy device revocation
- ⚠️ Optional: Pairing PIN code for extra security

**Residual Risk:** MEDIUM - Physical access scenario difficult to prevent

---

### T1.4: Brute Force Token Guessing
**Threat:** Attacker attempts to guess valid API tokens.

**Attack Vector:**
- Automated token guessing
- Weak token generation

**Impact:** MEDIUM - Successful guess grants access

**Mitigations:**
- ✅ Tokens generated with crypto-random (256 bits)
- ✅ Rate limiting: 10 auth attempts per minute
- ✅ Exponential backoff after failed attempts
- ✅ Account lockout after 10 failed attempts
- ✅ Alert admin on suspicious activity

**Residual Risk:** LOW - Astronomically unlikely with proper token size

---

## 2. Network Attacks

### T2.1: Man-in-the-Middle (MITM) on LAN
**Threat:** Attacker on same LAN intercepts photo traffic.

**Attack Vector:**
- ARP spoofing
- Rogue Wi-Fi access point
- Compromised router

**Impact:** HIGH - Photos and tokens intercepted

**Mitigations:**
- ✅ TLS for all API communication (even on LAN)
- ✅ Certificate pinning in mobile app
- ✅ HSTS headers
- ⚠️ Optional: Mutual TLS
- ✅ Warn user if certificate changes

**Residual Risk:** LOW with TLS, MEDIUM if user accepts invalid cert

---

### T2.2: WireGuard VPN Compromise
**Threat:** Attacker breaks WireGuard encryption.

**Attack Vector:**
- Cryptographic breakthrough (extremely unlikely)
- Key compromise
- Implementation vulnerability

**Impact:** CRITICAL - All remote traffic decrypted

**Mitigations:**
- ✅ WireGuard uses modern crypto (ChaCha20, Poly1305, Curve25519)
- ✅ Regular key rotation (every 90 days)
- ✅ Use established WireGuard libraries (don't roll our own)
- ✅ Per-device keys (limit blast radius)
- ✅ Monitor WireGuard security advisories

**Residual Risk:** VERY LOW - WireGuard is well-audited

---

### T2.3: DDoS Attack on Host
**Threat:** Attacker floods host with requests, causing denial of service.

**Attack Vector:**
- Flood of API requests
- Connection exhaustion
- Resource exhaustion (CPU, memory, disk)

**Impact:** HIGH - Host becomes unavailable

**Mitigations:**
- ✅ Rate limiting per device
- ✅ Rate limiting per IP
- ✅ Connection limits
- ✅ Request timeouts
- ✅ Graceful degradation (serve cached thumbnails)
- ⚠️ Optional: Fail2ban integration
- ⚠️ Optional: Cloudflare/CDN for public endpoint

**Residual Risk:** MEDIUM - Determined attacker can still overwhelm

---

### T2.4: Port Scanning / Service Discovery
**Threat:** Attacker discovers host services and attacks them.

**Attack Vector:**
- Port scan finds WireGuard port
- Brute force WireGuard handshake
- Exploit vulnerabilities in exposed services

**Impact:** MEDIUM - Information disclosure, potential exploit

**Mitigations:**
- ✅ Minimal exposed ports (only WireGuard 51820, API 8080)
- ✅ Host firewall enabled by default
- ✅ WireGuard doesn't respond to invalid handshakes
- ✅ No service banners or version info exposed
- ✅ Rate limiting on WireGuard handshake attempts

**Residual Risk:** LOW

---

## 3. Data Security Threats

### T3.1: Path Traversal Attack
**Threat:** Attacker requests files outside photo directories.

**Attack Vector:**
- Crafted API request: `/api/v1/photos/../../etc/passwd`
- Unicode encoding tricks
- Symlink following

**Impact:** CRITICAL - Access to sensitive system files

**Mitigations:**
- ✅ Strict path validation (reject `..`, absolute paths)
- ✅ Canonicalize all paths before access
- ✅ Chroot or path restrictions
- ✅ Never follow symlinks outside photo roots
- ✅ Unit tests for path traversal attempts
- ✅ WAF-style filtering

**Residual Risk:** LOW with proper implementation

---

### T3.2: SQL Injection
**Threat:** Attacker injects SQL into search queries.

**Attack Vector:**
- Malicious search query: `'; DROP TABLE photos; --`
- Unescaped user input in SQL

**Impact:** HIGH - Database corruption or information disclosure

**Mitigations:**
- ✅ Use parameterized queries exclusively
- ✅ ORM/query builder with automatic escaping
- ✅ Input validation on all user-supplied data
- ✅ Principle of least privilege for DB user
- ✅ Read-only database connection for query operations

**Residual Risk:** VERY LOW with parameterized queries

---

### T3.3: Metadata Leakage
**Threat:** Photo EXIF contains sensitive location/device data.

**Attack Vector:**
- Photos include GPS coordinates of home
- Device serial numbers in EXIF
- Timestamps reveal user patterns

**Impact:** MEDIUM - Privacy violation, potential physical security risk

**Mitigations:**
- ⚠️ Optional: Strip EXIF on upload
- ⚠️ Warning to user about EXIF data
- ⚠️ User control over metadata sharing
- ✅ Access control prevents unauthorized viewing

**Residual Risk:** MEDIUM - Users may not be aware of EXIF data

---

### T3.4: Insufficient Data Deletion
**Threat:** Deleted photos remain accessible.

**Attack Vector:**
- Photos "deleted" but not actually removed
- Database entries removed but files remain
- Thumbnails cached after deletion

**Impact:** MEDIUM - Privacy violation

**Mitigations:**
- ✅ Secure deletion removes both DB entry and files
- ✅ Thumbnail cache invalidation
- ✅ Periodic cleanup of orphaned files
- ⚠️ Optional: Secure wipe for sensitive photos

**Residual Risk:** LOW

---

## 4. Host System Threats

### T4.1: Compromised Host System
**Threat:** Attacker gains access to host computer.

**Attack Vector:**
- Malware infection
- Physical access
- Remote exploit

**Impact:** CRITICAL - Complete compromise of all photos and keys

**Mitigations:**
- ✅ Rely on OS security (Windows Defender, macOS Gatekeeper)
- ✅ Encrypt SQLite database at rest
- ✅ Store WireGuard keys with OS protection
- ✅ Principle of least privilege for host process
- ⚠️ Run host as non-admin user
- ⚠️ Sandbox host process (if feasible)

**Residual Risk:** HIGH - Host compromise is game over

**Note:** This is outside our control; rely on OS security.

---

### T4.2: Unauthorized Local Access
**Threat:** Someone with physical access to host views photos.

**Attack Vector:**
- Host left unlocked
- Shared computer
- Lost/stolen laptop

**Impact:** HIGH - Privacy violation

**Mitigations:**
- ⚠️ Optional: PIN/password to access host admin UI
- ⚠️ Optional: Database encryption with user-provided key
- ✅ Encourage users to lock their computers
- ✅ Documentation on physical security

**Residual Risk:** HIGH - Difficult to prevent physical access

---

### T4.3: Malicious Photo Files
**Threat:** Attacker places malicious photo file in indexed directory.

**Attack Vector:**
- JPEG/PNG with embedded exploit
- File triggers parser vulnerability
- Zip bomb or resource exhaustion

**Impact:** MEDIUM - Host process crash or compromise

**Mitigations:**
- ✅ Use well-tested image libraries (libvips, ImageMagick)
- ✅ Limit file size (reject files > 100MB)
- ✅ Timeout on thumbnail generation
- ✅ Sandbox thumbnail generation process
- ✅ Validate file format before processing

**Residual Risk:** LOW

---

## 5. Mobile App Threats

### T5.1: Compromised Mobile Device
**Threat:** Attacker gains access to user's phone.

**Attack Vector:**
- Malware on phone
- Physical access to unlocked phone
- Jailbreak/root access

**Impact:** HIGH - Access to cached photos and credentials

**Mitigations:**
- ✅ Use OS secure storage (Keychain/Keystore)
- ✅ Minimize cached data
- ✅ Clear cache on logout
- ✅ Require device PIN/biometric
- ⚠️ Optional: App-level PIN
- ✅ Detect jailbreak/root and warn user

**Residual Risk:** MEDIUM - Device compromise difficult to defend

---

### T5.2: Malicious Mobile App
**Threat:** Fake PixlSrve app steals credentials.

**Attack Vector:**
- Phishing via fake app
- App impersonation
- Sideloaded malicious app

**Impact:** HIGH - Credentials stolen

**Mitigations:**
- ✅ Publish to official app stores only
- ✅ Code signing
- ⚠️ App attestation (SafetyNet/DeviceCheck)
- ✅ Warn about sideloading in docs
- ✅ Trademark/DMCA against impersonators

**Residual Risk:** LOW on official stores, HIGH on sideload

---

### T5.3: Insecure Data Storage on Mobile
**Threat:** Cached photos/data accessible without authentication.

**Attack Vector:**
- Device backup exposes cache
- Forensic tools read app data
- Shared device access

**Impact:** MEDIUM - Privacy violation

**Mitigations:**
- ✅ Exclude cache from device backups
- ✅ Encrypt cached photos
- ✅ Clear cache on logout
- ⚠️ Optional: Ephemeral cache (in-memory only)

**Residual Risk:** LOW

---

## 6. Availability Threats

### T6.1: Accidental Photo Deletion
**Threat:** User accidentally deletes photo collection.

**Attack Vector:**
- User error
- Bug in file watcher
- Sync issue

**Impact:** MEDIUM - Data loss

**Mitigations:**
- ⚠️ Soft delete (trash/recycle bin)
- ⚠️ Backup recommendations in docs
- ✅ Confirmation dialog for deletions
- ⚠️ Optional: Sync with cloud backup

**Residual Risk:** MEDIUM

---

### T6.2: Database Corruption
**Threat:** SQLite database becomes corrupted.

**Attack Vector:**
- System crash during write
- Disk failure
- Software bug

**Impact:** HIGH - Photo index lost

**Mitigations:**
- ✅ SQLite WAL mode
- ✅ Regular PRAGMA integrity_check
- ✅ Automatic database backup
- ✅ Database rebuild from filesystem

**Residual Risk:** LOW

---

## 7. Implementation Threats

### T7.1: Dependency Vulnerabilities
**Threat:** Vulnerable library exposes security flaw.

**Attack Vector:**
- Outdated dependency with CVE
- Supply chain attack

**Impact:** VARIES - Depends on vulnerability

**Mitigations:**
- ✅ Dependency scanning in CI/CD
- ✅ Automated dependency updates
- ✅ Use minimal dependencies
- ✅ Pin dependency versions
- ✅ Review dependencies before adding

**Residual Risk:** MEDIUM

---

### T7.2: Insufficient Logging for Forensics
**Threat:** Security incident occurs but not enough logs to investigate.

**Attack Vector:**
- Attacker covers tracks
- Logs not captured

**Impact:** MEDIUM - Can't determine breach scope

**Mitigations:**
- ✅ Log all authentication attempts
- ✅ Log API access (anonymized)
- ✅ Log VPN connections
- ✅ Log device pairing/revocation
- ❌ Don't log sensitive data (tokens, keys)

**Residual Risk:** LOW

---

## Attack Scenarios

### Scenario 1: Rogue Device on LAN
**Attacker:** On victim's home Wi-Fi

**Attack Steps:**
1. Discover host via mDNS
2. Attempt API access without token → Blocked by auth
3. Sniff network for token → Blocked by TLS
4. Attempt WireGuard connection → Blocked (no valid key)

**Outcome:** Attack fails

---

### Scenario 2: Stolen Phone
**Attacker:** Physical possession of unlocked victim's phone

**Attack Steps:**
1. Open PixlSrve app → Photos visible (cached)
2. Extract API token from app storage → Protected by Keychain (requires device PIN)
3. Extract WireGuard config → Protected by Keystore

**Outcome:** Cached photos compromised, but can't access new photos after token expires or device revoked

**Mitigation:** User should remotely revoke device

---

### Scenario 3: Compromised Wi-Fi (Coffee Shop)
**Attacker:** Controls rogue Wi-Fi access point

**Attack Steps:**
1. Victim connects to "Free Coffee WiFi"
2. Attacker performs MITM
3. Victim launches PixlSrve
4. App detects host not on LAN → Starts VPN
5. All traffic encrypted via WireGuard → Attacker sees only ciphertext

**Outcome:** Attack fails due to VPN

---

### Scenario 4: Internet-Based Attacker
**Attacker:** Remote on internet, no physical access

**Attack Steps:**
1. Port scan finds host WireGuard port 51820
2. Attempt WireGuard handshake with invalid key → No response
3. Brute force WireGuard key → Computationally infeasible
4. Exploit WireGuard vulnerability → None known
5. Try to access API directly → Blocked by firewall

**Outcome:** Attack fails

---

## Security Checklist

### Authentication ✅
- [x] All endpoints require authentication
- [x] Short-lived tokens (1 hour)
- [x] Token rotation implemented
- [x] Secure token storage
- [x] Rate limiting on auth endpoints

### Network Security ✅
- [x] TLS for all API communication
- [x] WireGuard for remote access
- [x] Certificate pinning
- [x] Firewall rules configured

### Data Protection ✅
- [x] Path traversal protection
- [x] SQL injection prevention (parameterized queries)
- [x] Input validation
- [x] Secure data deletion

### Host Security ✅
- [x] Principle of least privilege
- [x] Database encryption at rest
- [x] Secure key storage
- [x] Regular updates

### Mobile Security ✅
- [x] Secure credential storage (Keychain/Keystore)
- [x] VPN auto-teardown on background
- [x] Jailbreak/root detection
- [x] Cache encryption

### Monitoring ✅
- [x] Authentication logging
- [x] Access logging
- [x] Error logging
- [x] Security event alerts

---

## Assumptions & Limitations

### Assumptions
1. User's home network is reasonably secure
2. User keeps OS and apps updated
3. User doesn't share device PIN with others
4. Physical security of host computer maintained

### Out of Scope
1. Protecting against nation-state adversaries
2. Quantum-resistant cryptography
3. Zero-knowledge encryption (host needs access to photos)
4. Air-gapped scenarios

### Limitations
1. Cannot protect against compromised host OS
2. Cannot protect against compromised mobile OS
3. Cannot prevent physical access attacks
4. Metadata (EXIF) not stripped by default

---

## Security Recommendations for Users

1. **Use strong device PINs/passwords**
2. **Keep host computer locked when away**
3. **Regularly review paired devices**
4. **Enable device encryption** (FileVault, BitLocker)
5. **Use trusted Wi-Fi networks**
6. **Keep software updated**
7. **Revoke lost devices immediately**
8. **Consider metadata privacy** (EXIF contains location)
9. **Regular backups** (3-2-1 rule)
10. **Review access logs** periodically

---

## Incident Response Plan

### If Device Stolen
1. Log into host admin UI
2. Revoke device access
3. Review access logs for unusual activity
4. Rotate WireGuard keys if necessary

### If Host Compromised
1. Immediately disconnect host from network
2. Revoke all device tokens
3. Forensic analysis of host system
4. Restore from clean backup
5. Regenerate all keys

### If Vulnerability Discovered
1. Assess severity and exploitability
2. Develop and test patch
3. Release security update
4. Notify users
5. Public disclosure after mitigation

---

## Security Updates

This threat model should be reviewed:
- Before each major release
- After any security incident
- Quarterly at minimum
- When new features added
- When new attack vectors discovered

**Last Updated:** 2023-12-27  
**Next Review:** 2024-03-27
