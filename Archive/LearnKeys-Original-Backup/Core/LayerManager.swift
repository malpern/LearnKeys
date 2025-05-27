import Foundation

/// Simple layer state management driven by UDP
class LayerManager: ObservableObject {
    @Published var currentLayer: String = "base"
    @Published var layerHistory: [String] = ["base"]
    @Published var layerTransitions: [LayerTransition] = []
    
    private let maxHistorySize = 10
    private let maxTransitionHistory = 20
    
    struct LayerTransition {
        let from: String
        let to: String
        let timestamp: Date
        let duration: TimeInterval?
    }
    
    func updateLayer(_ newLayer: String) {
        guard newLayer != currentLayer else { return }
        
        let transition = LayerTransition(
            from: currentLayer,
            to: newLayer,
            timestamp: Date(),
            duration: nil
        )
        
        print("🗂️ Layer transition: \(currentLayer) → \(newLayer)")
        
        // Update current layer
        let previousLayer = currentLayer
        currentLayer = newLayer
        
        // Update history
        layerHistory.append(newLayer)
        if layerHistory.count > maxHistorySize {
            layerHistory.removeFirst()
        }
        
        // Update transition history
        layerTransitions.append(transition)
        if layerTransitions.count > maxTransitionHistory {
            layerTransitions.removeFirst()
        }
        
        // Notify about layer change
        NotificationCenter.default.post(
            name: .layerDidChange,
            object: self,
            userInfo: [
                "previousLayer": previousLayer,
                "currentLayer": newLayer,
                "timestamp": Date()
            ]
        )
    }
    
    func getLayerDisplayName(_ layer: String) -> String {
        switch layer.lowercased() {
        case "base":
            return "Base"
        case "f-nav", "fnav":
            return "Navigation"
        case "navfast":
            return "Fast Nav"
        case "nomods":
            return "No Modifiers"
        default:
            return layer.capitalized
        }
    }
    
    func isBaseLayer() -> Bool {
        return currentLayer.lowercased() == "base"
    }
    
    func isNavigationLayer() -> Bool {
        let navLayers = ["f-nav", "fnav", "navfast", "navigation"]
        return navLayers.contains(currentLayer.lowercased())
    }
    
    func getPreviousLayer() -> String? {
        return layerHistory.count > 1 ? layerHistory[layerHistory.count - 2] : nil
    }
    
    func getRecentTransitions(count: Int = 5) -> [LayerTransition] {
        return Array(layerTransitions.suffix(count))
    }
    
    func reset() {
        currentLayer = "base"
        layerHistory = ["base"]
        layerTransitions = []
        
        print("🗂️ Layer manager reset to base")
    }
}

// Notification for layer changes
extension Notification.Name {
    static let layerDidChange = Notification.Name("LayerDidChange")
} 