import SwiftUI
import AppKit

struct MakeFontApp: App {
    
    // swiftlint:disable:next weak_delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
            NSApp.applicationIconImage = appIcon
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 260, maxWidth: 260,
                       minHeight: 260, maxHeight: 260)
        }
        .windowResizability(.contentSize)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
