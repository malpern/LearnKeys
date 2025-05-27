# Modifier Test Harness Guide

## 🎯 Purpose

This test harness isolates the 'a' key modifier issue to systematically verify that:
1. Tap 'a' → sends `KEY_A` message
2. Hold 'a' → sends `SHIFT_DOWN` message  
3. Release 'a' → sends `SHIFT_UP` message

## 📁 Test Files

- `test_harness_config.kbd` - Minimal Kanata config with only 'a' key
- `UDPTestMonitor.swift` - Simple UDP monitor for the three messages
- `run_simple_test.sh` - Test orchestration script
- `MODIFIER_TEST_GUIDE.md` - This guide

## 🚀 Quick Start

### Option 1: Manual Testing (Recommended)

1. **Start UDP Monitor** (Terminal 1):
   ```bash
   ./Tests/UDPTestMonitor.swift
   ```

2. **Start Kanata** (Terminal 2):
   ```bash
   sudo kanata --cfg Tests/test_harness_config.kbd
   ```

3. **Test the 'a' key**:
   - Quick tap 'a' → should see `KEY_A`
   - Hold 'a' for 1+ seconds → should see `SHIFT_DOWN` then `SHIFT_UP`

4. **Stop both programs** with Ctrl+C to see final results

### Option 2: Guided Setup

```bash
./Tests/run_simple_test.sh
```

## 🔍 Expected Results

### ✅ Working Correctly
```
[19:02:15.068] ⌨️  KEY_A (tap) - Count: 1
    Status: Shift inactive, Balance: 0 (downs: 0, ups: 0)

[19:02:16.234] 🔽 SHIFT_DOWN (hold start) - Count: 1
    Status: Shift ACTIVE, Balance: 1 (downs: 1, ups: 0)

[19:02:17.456] 🔼 SHIFT_UP (hold end) - Count: 1
    Status: Shift inactive, Balance: 0 (downs: 1, ups: 1)

==================================================
🏁 FINAL RESULTS
==================================================
KEY_A taps: 1
SHIFT_DOWN: 1
SHIFT_UP: 1
Balance: 0
Final shift state: inactive

✅ TEST PASSED - Perfect balance, no stuck modifiers
```

### ❌ Issue Detected
```
[19:02:15.068] ⌨️  KEY_A (tap) - Count: 1
    Status: Shift inactive, Balance: 0 (downs: 0, ups: 0)

[19:02:16.234] 🔽 SHIFT_DOWN (hold start) - Count: 1
    Status: Shift ACTIVE, Balance: 1 (downs: 1, ups: 0)

# Missing SHIFT_UP message!

==================================================
🏁 FINAL RESULTS
==================================================
KEY_A taps: 1
SHIFT_DOWN: 1
SHIFT_UP: 0
Balance: 1
Final shift state: STUCK ACTIVE

❌ TEST FAILED - Imbalanced or stuck modifier
   • Missing 1 UP events
   • Shift modifier stuck in active state
```

## 🔧 Troubleshooting

### No Messages Received
- Check if Kanata is running: `pgrep kanata`
- Check if UDP port 6789 is available: `lsof -i :6789`
- Verify netcat works: `echo "test" | nc -u 127.0.0.1 6789`

### Kanata Won't Start
- Check config syntax: `kanata --check --cfg Tests/test_harness_config.kbd`
- Run with verbose logging: `sudo kanata --cfg Tests/test_harness_config.kbd --log-level debug`

### Swift Monitor Won't Start
- Check Swift is installed: `swift --version`
- Make executable: `chmod +x Tests/UDPTestMonitor.swift`

## 🧪 Test Variations

### Different Timing
Edit `test_harness_config.kbd` and change:
```lisp
tap-time 200    ; Try 100, 300, 500
hold-time 150   ; Try 100, 200, 300
```

### Debug Mode
Add verbose logging to Kanata config:
```lisp
(defcfg
  process-unmapped-keys yes
  concurrent-tap-hold yes
  danger-enable-cmd yes
  log-layer-changes yes  ; Enable this
)
```

## 📊 Interpreting Results

### Key Metrics
- **Balance**: `SHIFT_DOWN` count should equal `SHIFT_UP` count
- **Final State**: Should be "inactive" not "STUCK ACTIVE"
- **Timing**: Messages should appear in correct sequence

### Common Issues
1. **Missing SHIFT_UP**: Fork construct not working
2. **Orphaned Events**: Timing issues or double-triggers
3. **No Messages**: UDP or Kanata configuration problems

## 🔄 Iteration Process

1. **Run Test** → Identify specific issue
2. **Modify Config** → Try different patterns
3. **Re-test** → Verify fix
4. **Document** → Record what worked

### Config Patterns to Try

**Current (should work)**:
```lisp
shift-test (fork (multi @shift (cmd sh -c "echo 'SHIFT_DOWN' | nc -u 127.0.0.1 6789")) (cmd sh -c "echo 'SHIFT_UP' | nc -u 127.0.0.1 6789") ())
a_test (tap-hold-release-keys $tap-time $hold-time (cmd sh -c "echo 'KEY_A' | nc -u 127.0.0.1 6789") @shift-test ())
```

**Alternative (if fork fails)**:
```lisp
a_test (tap-hold-release $tap-time $hold-time (cmd sh -c "echo 'KEY_A' | nc -u 127.0.0.1 6789") (cmd sh -c "echo 'SHIFT_DOWN' | nc -u 127.0.0.1 6789") (cmd sh -c "echo 'SHIFT_UP' | nc -u 127.0.0.1 6789"))
```

## 📝 Next Steps

Once this isolated test works:
1. Apply the same pattern to the main config
2. Test with multiple modifiers
3. Verify with the full LearnKeys app
4. Update documentation with the fix 