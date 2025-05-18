import Cocoa

class QuitOnCommandWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Command+W
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "w" {
                NSApp.terminate(nil)
                return
            }
        }
        super.keyDown(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.performDrag(with: event)
    }
}

class NonInteractiveImageView: NSImageView {
    override var acceptsFirstResponder: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func setupMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let quitTitle = "Quit " + (Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App")
        appMenu.addItem(
            withTitle: quitTitle,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu

        NSApp.mainMenu = mainMenu
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenu()
        let path = ("~/Downloads/homerow-guide.png" as NSString).expandingTildeInPath
        if let image = NSImage(contentsOfFile: path) {
            let screens = NSScreen.screens
            let targetScreen = screens.count > 1 ? screens[1] : screens[0] // Use secondary if available, else main
            window = QuitOnCommandWindow(
                contentRect: targetScreen.frame,
                styleMask: [.borderless, .resizable],
                backing: .buffered,
                defer: false
            )
            window.level = .floating
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false

            // Create a black background view
            let backgroundView = NSView(frame: window.contentView!.bounds)
            backgroundView.wantsLayer = true
            backgroundView.layer?.backgroundColor = NSColor.black.cgColor
            backgroundView.autoresizingMask = [.width, .height]

            // Create the image view
            let imageView = NonInteractiveImageView(image: image)
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.frame = backgroundView.bounds
            imageView.autoresizingMask = [.width, .height]

            // Add image view to background view
            backgroundView.addSubview(imageView)
            window.contentView = backgroundView
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window)
        } else {
            print("Image not found at \(path)")
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hide from Dock and Cmd+Tab
app.run()