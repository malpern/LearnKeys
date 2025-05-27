# Bug Report: `fork` Release Actions Fail on macOS with CMD-Enabled Binary

## Environment
- **Kanata Version**: v1.8.1 (CMD-enabled: `kanata_macos_cmd_allowed_arm64`)
- **OS**: macOS 14.5 (darwin 24.5.0)
- **Architecture**: ARM64 (Apple Silicon)
- **Karabiner Driver**: v5 (active, `driver_connected 1`)

## Summary
`fork` constructs fail to execute release actions (second parameter) on macOS when using CMD-enabled Kanata binary, despite press actions (first parameter) working correctly.

## Expected Behavior
```kanata
;; This should send both down and up messages
a (tap-hold 200 150
  a
  (fork 
    (cmd sh -c "echo 'modifier:shift:down' | nc 127.0.0.1 6790")
    (cmd sh -c "echo 'modifier:shift:up' | nc 127.0.0.1 6790")
    ()
  )
)
```

**Expected sequence:**
1. Hold 'a' → `modifier:shift:down` sent ✅
2. Release 'a' → `modifier:shift:up` sent ❌ (Never happens)

## Actual Behavior
- ✅ **Press action executes**: `modifier:shift:down` command runs successfully
- ❌ **Release action never executes**: `modifier:shift:up` command never runs
- ✅ **Modifier functionality works**: Actual shift behavior applies correctly
- ❌ **No error messages**: Kanata logs show no failures or warnings

## Reproduction Steps

### 1. Create minimal test configuration:
```kanata
(defcfg
  process-unmapped-keys yes
  danger-enable-cmd yes
)

(defsrc a)

(deflayer base @a)

(defalias
  a (tap-hold 200 150
    a
    (fork 
      (cmd sh -c "echo 'DOWN' | nc 127.0.0.1 6790")
      (cmd sh -c "echo 'UP' | nc 127.0.0.1 6790")
      ()
    )
  )
)
```

### 2. Set up TCP listener:
```bash
# Terminal 1: Start TCP listener
nc -l 6790
```

### 3. Run Kanata with CMD-enabled binary:
```bash
# Terminal 2: Start Kanata
sudo ./kanata_macos_cmd_allowed_arm64 --cfg test.kbd
```

### 4. Test the key:
- Hold 'a' key for >150ms
- Release 'a' key

### 5. Observe results:
- TCP listener receives: `DOWN` ✅
- TCP listener never receives: `UP` ❌

## Evidence from Kanata Logs

**Successful press action:**
```
[INFO] Running cmd: Program: sh, Arguments: -c echo 'DOWN' | nc 127.0.0.1 6790
[INFO] Successfully ran cmd: Program: sh, Arguments: -c echo 'DOWN' | nc 127.0.0.1 6790
```

**Missing release action:**
- No corresponding `Running cmd` log for UP command
- No error messages or warnings
- Release action silently ignored

## Systematic Testing Results

Tested multiple `fork` patterns - **all exhibit identical behavior**:

### Pattern 1: Basic fork
```kanata
(fork (cmd sh -c "echo 'down'") (cmd sh -c "echo 'up'") ())
```
**Result**: `down` sent, `up` never sent

### Pattern 2: Fork with multi
```kanata
(fork 
  (multi @shift (cmd sh -c "echo 'down'"))
  (cmd sh -c "echo 'up'")
  ()
)
```
**Result**: `down` sent, `up` never sent

### Pattern 3: Different timing
```kanata
(tap-hold 100 100 a (fork ...))  ;; Fast timing
(tap-hold 500 300 a (fork ...))  ;; Slow timing
```
**Result**: Same failure pattern regardless of timing

## Driver Status Verification

```
driver_activated 1
driver_connected 1
driver_version_mismatched 0
```

Karabiner daemon confirmed running:
```bash
$ ps aux | grep karabiner
root  814  /Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/
          Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/
          Karabiner-VirtualHIDDevice-Daemon
```

## Key Finding: CMD Binary Specific

**Critical Discovery**: This bug only manifests with CMD-enabled binaries.

- ✅ **Standard binary**: `fork` constructs ignored entirely (CMD actions fail silently)
- ❌ **CMD-enabled binary**: `fork` press actions work, release actions fail

**Binary verification:**
```bash
$ strings kanata_macos_cmd_allowed_arm64 | grep cmd
# Shows CMD support enabled

$ ./kanata_macos_cmd_allowed_arm64 --cfg test.kbd
[WARN] DANGER! cmd action is enabled.  # ✅ CMD support confirmed
```

## Impact
- **Severity**: High for users requiring CMD actions with fork constructs
- **Scope**: Affects all `fork` release actions on macOS with CMD-enabled binary
- **Workaround**: Layer switching method (see below)

## Workaround
Replace `fork` constructs with layer switching:

```kanata
;; Instead of fork, use layer switching
a (tap-hold 200 150
  a
  (multi 
    @shift 
    (cmd sh -c "echo 'modifier:shift:down' | nc 127.0.0.1 6790")
    (layer-switch shift-held)
  )
)

;; Release detection in tracking layer
a_release (multi
  (cmd sh -c "echo 'modifier:shift:up' | nc 127.0.0.1 6790")
  (layer-switch base)
  a
)

(deflayer shift-held
  @a_release  ;; Detect release
)
```

**Result**: ✅ Both down and up messages sent reliably

## Additional Context

### Related Issues
- This may be related to macOS-specific event handling in CMD-enabled builds
- Could be connected to Karabiner driver integration differences
- Similar to historical modifier timing issues but specific to `fork` release actions

### Testing Environment
- Tested with both TCP and UDP protocols (same failure)
- Tested with file-based output (same failure) 
- Tested with different shell commands (same failure)
- Issue is specifically with `fork` release action execution, not command execution itself

### Version History
- Issue confirmed present in v1.8.1 CMD-enabled binary
- Standard v1.8.1 binary doesn't exhibit issue (but CMD actions don't work)
- Need testing on earlier CMD-enabled versions to determine regression point

## Minimal Reproduction Case

**File: `fork_bug_test.kbd`**
```kanata
(defcfg
  process-unmapped-keys yes
  danger-enable-cmd yes
)

(defsrc a)
(deflayer base @test)

(defalias
  test (tap-hold 200 150
    a
    (fork 
      (cmd sh -c "echo 'PRESS' >> /tmp/kanata_test.log")
      (cmd sh -c "echo 'RELEASE' >> /tmp/kanata_test.log")
      ()
    )
  )
)
```

**Test procedure:**
1. `sudo ./kanata_macos_cmd_allowed_arm64 --cfg fork_bug_test.kbd`
2. Hold and release 'a' key multiple times
3. `cat /tmp/kanata_test.log`

**Expected output:**
```
PRESS
RELEASE
PRESS
RELEASE
```

**Actual output:**
```
PRESS
PRESS
```

---

**This bug prevents reliable modifier state tracking and creates stuck modifier scenarios in applications depending on press/release event pairs.**

## Related Issues

### Directly Related
- **No existing reports found** - This appears to be the first documented case of this specific `fork` release action bug

### Contextually Related
- **Issue #1342**: [Kanata crashes on macOS with Sidecar](https://github.com/jtroo/kanata/issues/1342) - Shows macOS driver stability issues
- **Issue #1211**: [IOHIDDeviceOpen permission errors](https://github.com/jtroo/kanata/issues/1211) - macOS permission/driver problems  
- **Issue #1264**: [Connection failures on macOS](https://github.com/jtroo/kanata/issues/1264) - Driver compatibility issues
- **Issue #413**: [Layer switching duplicate keypresses](https://github.com/jtroo/kanata/issues/413) - Shows layer-related bugs exist (Linux)

### Version Context
- **Release v1.3.0-prerelease-1**: First version where `fork` construct was available
- CMD-enabled binaries have been available since early releases but this interaction hasn't been reported

### Community Impact
Based on GitHub issue search, this specific `fork` + CMD + macOS combination hasn't been reported before, suggesting either:
1. Limited usage of `fork` constructs with CMD actions on macOS
2. Users working around the issue without reporting
3. Recent regression in CMD-enabled binary builds 