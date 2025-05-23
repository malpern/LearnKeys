import Foundation
import CoreGraphics

// MARK: - Key Code Mapping Utilities

struct KeyCodeMapper {
    
    // MARK: - Main Key Mapping Function
    
    static func keyStringFromCode(_ keyCode: CGKeyCode) -> String? {
        return mapLetterKeyCodes(keyCode) ?? 
               mapArrowKeyCodes(keyCode) ?? 
               mapSpecialKeyCodes(keyCode)
    }
    
    // MARK: - Letter Key Mappings
    
    private static func mapLetterKeyCodes(_ keyCode: CGKeyCode) -> String? {
        switch keyCode {
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 5: return "g"
        case 4: return "h"
        case 38: return "j"
        case 40: return "k"
        case 37: return "l"
        case 41: return ";"
        case 13: return "w"
        case 11: return "b"
        default: return nil
        }
    }
    
    // MARK: - Arrow Key Mappings
    
    private static func mapArrowKeyCodes(_ keyCode: CGKeyCode) -> String? {
        switch keyCode {
        case 123: return "left"
        case 124: return "right"
        case 125: return "down"
        case 126: return "up"
        default: return nil
        }
    }
    
    // MARK: - Special Key Mappings
    
    private static func mapSpecialKeyCodes(_ keyCode: CGKeyCode) -> String? {
        switch keyCode {
        // Numbers
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        
        // QWERTY row
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 17: return "t"
        case 16: return "y"
        case 32: return "u"
        case 34: return "i"
        case 31: return "o"
        case 35: return "p"
        
        // ZXCV row  
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 45: return "n"
        case 46: return "m"
        
        // Special keys
        case 53: return "esc"    // ESC key
        case 49: return "spc"    // Space key
        case 51: return "bspc"   // Backspace
        case 36: return "ret"    // Return/Enter
        case 48: return "tab"    // Tab
        case 117: return "del"   // Delete
        case 115: return "home"  // Home
        case 119: return "end"   // End
        case 116: return "pgup"  // Page Up
        case 121: return "pgdn"  // Page Down
        
        // Punctuation and symbols
        case 27: return "-"      // Minus/hyphen
        case 24: return "="      // Equals
        case 33: return "["      // Left bracket
        case 30: return "]"      // Right bracket
        case 42: return "\\"     // Backslash
        case 39: return "'"      // Single quote
        case 41: return ";"      // Semicolon (handled in mapLetterKeyCodes but adding here too)
        case 43: return ","      // Comma
        case 47: return "."      // Period
        case 44: return "/"      // Forward slash
        case 50: return "`"      // Grave accent/backtick
        
        // Function keys
        case 122: return "f1"
        case 120: return "f2"
        case 99: return "f3"
        case 118: return "f4"
        case 96: return "f5"
        case 97: return "f6"
        case 98: return "f7"
        case 100: return "f8"
        case 101: return "f9"
        case 109: return "f10"
        case 103: return "f11"
        case 111: return "f12"
        
        default: return nil
        }
    }
    
    // MARK: - Keycode Hints
    
    static func getKeycodeHint(_ keyCode: Int) -> String {
        // Provide helpful hints for common unmapped keycodes
        // These are educated guesses based on common US keyboard layouts
        switch keyCode {
        // Modifier keys (these shouldn't be handled as regular keys anyway)
        case 54, 55: return "command keys (handled by modifier system)"
        case 56, 60: return "shift keys (handled by modifier system)"
        case 58, 61: return "option/alt keys (handled by modifier system)"
        case 59, 62: return "control keys (handled by modifier system)"
        case 57: return "caps lock (handled by modifier system)"
        case 63: return "fn key (system key)"
        
        // Numpad (if present)
        case 65: return "numpad decimal"
        case 67: return "numpad multiply"
        case 69: return "numpad plus"
        case 71: return "numpad clear"
        case 75: return "numpad divide"
        case 76: return "numpad enter"
        case 78: return "numpad minus"
        case 81: return "numpad equals"
        case 82: return "numpad 0"
        case 83: return "numpad 1"
        case 84: return "numpad 2"
        case 85: return "numpad 3"
        case 86: return "numpad 4"
        case 87: return "numpad 5"
        case 88: return "numpad 6"
        case 89: return "numpad 7"
        case 91: return "numpad 8"
        case 92: return "numpad 9"
        
        // System keys
        case 107: return "sysreq/print screen"
        case 113: return "scroll lock"
        case 114: return "pause/break"
        
        // Media keys
        case 144: return "brightness up"
        case 145: return "brightness down"
        case 160: return "volume up"
        case 161: return "volume down"
        case 162: return "mute"
        
        default: return ""
        }
    }
} 