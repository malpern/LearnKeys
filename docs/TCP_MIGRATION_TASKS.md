# TCP Migration Task List

*Updated: December 24, 2024*

## 🎯 **Goal: Replace UDP + cmd with native TCP**

**Why:** Security (no shell commands), Performance (direct TCP), Compatibility (standard Kanata)

## 📋 **Phase 2: TCP Migration Tasks**

### **2.0 Kanata Installation Migration (0.5 days)**
- [ ] **Remove Current Kanata Installation**
  ```bash
  # Identify current Kanata installation
  which kanata
  ps aux | grep kanata  # Stop any running instances
  
  # Remove custom Kanata build (with danger-enable-cmd support)
  # Location depends on how it was installed - check:
  ls -la /usr/local/bin/kanata
  ls -la ~/.cargo/bin/kanata
  rm /path/to/current/kanata  # Remove the cmd-enabled version
  ```

- [ ] **Install Standard Kanata from Homebrew**
  ```bash
  # Install standard Kanata (no cmd support)
  brew install kanata
  
  # Verify installation
  which kanata  # Should be /opt/homebrew/bin/kanata
  kanata --version
  kanata --help | grep -i tcp  # Check for TCP server support
  ```

- [ ] **Backup Current Configurations**
  ```bash
  # Backup existing .kbd files (they have cmd statements)
  cp config.kbd config-with-cmd-backup.kbd
  cp *.kbd ./kbd-backups/  # Backup all configs
  
  # These will need migration to TCP in step 2.3
  ```

### **2.1 Research & Validation (1-2 days)**
- [ ] **Test Standard Kanata TCP Server**
  ```bash
  # Verify TCP capability with Homebrew Kanata
  kanata --port 5829 --cfg config.kbd
  # Note: This should fail initially since config has cmd statements
  ```
- [ ] **Test TCP Message Format** 
  ```bash
  # Compare TCP vs UDP message handling
  echo "keypress:a" | nc 127.0.0.1 5829
  ```
- [ ] **Document Differences**
  - TCP vs UDP message format differences
  - Connection handling requirements
  - Performance characteristics
  - Standard Kanata limitations (no cmd support)

### **2.2 Swift TCP Implementation (2-3 days)**
- [ ] **Create TCPKeyTracker.swift**
  - Replace UDPKeyTracker with TCP NWConnection
  - Maintain same callback interface
  - Add connection state management
  - Handle reconnection logic
  
- [ ] **Update App Integration**
  - Modify LearnKeysUDPApp.swift to use TCPKeyTracker
  - Update logging to show TCP connection status
  - Preserve headless mode functionality
  - Handle TCP connection errors gracefully

### **2.3 Configuration Migration (1 day)**
- [ ] **Update Kanata Configs**
  - Remove `danger-enable-cmd yes` requirement
  - Replace `cmd` statements with TCP output
  - Test with standard Kanata builds
  
- [ ] **Migration Examples**
  ```lisp
  # Before (UDP + cmd - REMOVE)
  (defcfg
    danger-enable-cmd yes  ;; REMOVE - not available in standard Kanata
  )
  (cmd "printf 'keypress:a\n' | nc -u 127.0.0.1 6789")  ;; REMOVE
  
  # After (TCP native - RESEARCH SYNTAX)
  # Research the correct TCP syntax for standard Kanata
  # May need to use different configuration approach
  ```

### **2.4 Testing & Validation (1-2 days)**
- [ ] **Port Existing Tests**
  - Update test_udp_functional.sh for TCP
  - Test connection handling (connect/disconnect)
  - Verify message delivery and processing
  
- [ ] **Performance Benchmarking**
  - Compare TCP vs UDP+cmd latency
  - Test under high message volume
  - Validate memory usage patterns
  
- [ ] **Integration Testing**
  - End-to-end workflow with real Kanata config
  - Headless mode with TCP
  - CI/CD pipeline updates

### **2.5 Documentation (0.5 days)**
- [ ] **Update README**
  - TCP setup instructions
  - Migration guide from UDP → TCP
  - Performance and security benefits
  
- [ ] **Update Examples**
  - Sample .kbd files for TCP
  - Installation guide for standard Kanata
  - Troubleshooting common issues

## 🧪 **Testing Checklist**

### **Basic TCP Functionality**
- [ ] TCP connection establishment
- [ ] Message processing (all types: keypress, navkey, modifier, layer)
- [ ] Connection state handling
- [ ] Graceful disconnection/reconnection

### **Feature Parity**
- [ ] Headless mode works with TCP
- [ ] All existing callbacks function correctly
- [ ] Logging shows TCP-specific information
- [ ] Signal handling (SIGINT/SIGTERM) works

### **Performance Validation**
- [ ] TCP latency < UDP+cmd latency
- [ ] No message loss under load
- [ ] Memory usage reasonable
- [ ] CPU usage improved vs UDP+cmd

### **Integration Validation**
- [ ] Works with standard Kanata from Homebrew
- [ ] No `danger-enable-cmd` required
- [ ] End-to-end setup from scratch works
- [ ] CI/CD pipeline passes all tests

## 🎯 **Success Criteria**

**TCP Migration Complete When:**
- ✅ Native TCP communication (no shell commands)
- ✅ Standard Kanata compatibility (Homebrew)
- ✅ Performance improved vs UDP+cmd
- ✅ Security enhanced (no shell injection risk)
- ✅ All existing functionality preserved
- ✅ Comprehensive tests passing

## 🗂️ **Post-TCP: Visual Work Archive**

*These tasks become Phase 3 after TCP migration:*
- Visual recreation (match original styling)
- Animation completion (green/blue/orange effects)
- Layer visual indicators
- Performance tuning (match original speed)
- Advanced features and customization

---

**Focus: Complete TCP migration foundation. Everything else builds on this.** 