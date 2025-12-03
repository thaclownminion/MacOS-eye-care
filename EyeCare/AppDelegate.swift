import Cocoa
import SwiftUI
import ServiceManagement
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timerManager: TimerManager!
    var breakWindow: BreakOverlayWindow?
    var sleepWindow: SleepBlockWindow?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        }
        
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Eye Care")
        }
        
        // Initialize timer manager
        timerManager = TimerManager()
        timerManager.onBreakStart = { [weak self] in
            DispatchQueue.main.async {
                self?.showBreakOverlay()
                print("showBreakOverlay actief")
            }
        }
        print("showBreakOverlay is nu weg")
        timerManager.onBreakEnd = { [weak self] in
            print("🔴🔴🔴 onBreakEnd CALLBACK TRIGGERED in AppDelegate")
            DispatchQueue.main.async {
                print("🔴 About to call hideBreakOverlay")
                self?.hideBreakOverlay()
                print("🔴 hideBreakOverlay completed")
            }
        }
        timerManager.onSleepModeChange = { [weak self] isActive in
            DispatchQueue.main.async {
                if isActive {
                    self?.showSleepBlock()
                } else {
                    self?.hideSleepBlock()
                }
            }
        }
        timerManager.onBreakWarning = { [weak self] minutesRemaining in
            DispatchQueue.main.async {
                self?.showInAppWarning(minutesRemaining: minutesRemaining)
            }
        }
        
        timerManager.onBreakWarning = { [weak self] minutesRemaining in
            DispatchQueue.main.async {
                self?.showInAppWarning(minutesRemaining: minutesRemaining)
            }
        }
        timerManager.onBreakCountdown = { [weak self] secondsRemaining in
            DispatchQueue.main.async {
                self?.updateInAppWarning(secondsRemaining: secondsRemaining)
            }
        }
        // Create menu
        setupMenu()
        
        // Start timer
        timerManager.start()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        let timeLeftItem = NSMenuItem(title: "Next break: calculating...", action: nil, keyEquivalent: "")
        timeLeftItem.isEnabled = false
        menu.addItem(timeLeftItem)
        
        let focusItem = NSMenuItem(title: "Focus Mode: Off", action: nil, keyEquivalent: "")
        focusItem.isEnabled = false
        menu.addItem(focusItem)
        
        let sleepItem = NSMenuItem(title: "Sleep Mode: Off", action: nil, keyEquivalent: "")
        sleepItem.isEnabled = false
        menu.addItem(sleepItem)
        
        timerManager.onTimeUpdate = { [weak timeLeftItem] remaining in
            DispatchQueue.main.async {
                let minutes = Int(remaining) / 60
                let seconds = Int(remaining) % 60
                timeLeftItem?.title = String(format: "Next break in: %d:%02d", minutes, seconds)
            }
        }
        
        timerManager.onFocusUpdate = { [weak focusItem] remaining in
            DispatchQueue.main.async {
                if remaining > 0 {
                    let minutes = Int(remaining) / 60
                    let seconds = Int(remaining) % 60
                    focusItem?.title = String(format: "Focus Mode: %d:%02d left", minutes, seconds)
                } else {
                    focusItem?.title = "Focus Mode: Off"
                }
            }
        }
        
        timerManager.onSleepModeChange = { [weak sleepItem] isActive in
            DispatchQueue.main.async {
                if isActive {
                    sleepItem?.title = "Sleep Mode: Active 😴"
                } else {
                    sleepItem?.title = "Sleep Mode: Off"
                }
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "s"))
        
        let focusToggleItem = NSMenuItem(title: "Enable Focus Mode", action: #selector(toggleFocusMode), keyEquivalent: "f")
        menu.addItem(focusToggleItem)
        
        menu.addItem(NSMenuItem(title: "Take Break Now", action: #selector(takeBreakNow), keyEquivalent: "b"))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Credits", action: #selector(showCredits), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        
        statusItem.menu = menu
        
        // Update menu items based on settings
        timerManager.onSettingsChange = { [weak quitItem, weak focusToggleItem, weak self] in
            DispatchQueue.main.async {
                quitItem?.isEnabled = !UserDefaults.standard.bool(forKey: "preventQuit")
                
                if let manager = self?.timerManager {
                    if manager.isFocusModeActive {
                        focusToggleItem?.title = "Disable Focus Mode"
                    } else {
                        focusToggleItem?.title = "Enable Focus Mode"
                    }
                }
            }
        }
    }
    
    @objc func openSettings() {
        if timerManager.isCurrentlyInSleepTime() {
            showSleepModeAlert()
            return
        }
        
        if timerManager.isSettingsLocked() {
            showLockedAlert()
            return
        }
        
        if settingsWindow == nil {
            let settingsView = SettingsView(timerManager: timerManager, appDelegate: self)
            let hostingController = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Eye Care Settings"
            settingsWindow?.styleMask = [.titled, .closable, .resizable]
            settingsWindow?.setContentSize(NSSize(width: 400, height: 800))
            settingsWindow?.center()
            
            // Reset settings window when closed
            settingsWindow?.delegate = self
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func toggleFocusMode() {
        if timerManager.isCurrentlyInSleepTime() {
            showSleepModeAlert()
            return
        }
        
        if timerManager.isFocusModeActive {
            timerManager.endFocusMode()
        } else {
            timerManager.startFocusMode()
        }
    }
    
    @objc func takeBreakNow() {
        if timerManager.isCurrentlyInSleepTime() {
            showSleepModeAlert()
            return
        }
        
        timerManager.triggerBreakNow()
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if isLaunchAtLoginEnabled() {
            disableLaunchAtLogin()
            sender.state = .off
        } else {
            enableLaunchAtLogin()
            sender.state = .on
        }
    }
    
    func isLaunchAtLoginEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
    
    func enableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                UserDefaults.standard.set(true, forKey: "launchAtLogin")
            } catch {
                print("Failed to enable launch at login: \(error)")
                showLaunchAtLoginError(enable: true)
            }
        } else {
            UserDefaults.standard.set(true, forKey: "launchAtLogin")
            showLaunchAtLoginLegacyMessage()
        }
    }
    
    func disableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                UserDefaults.standard.set(false, forKey: "launchAtLogin")
            } catch {
                print("Failed to disable launch at login: \(error)")
                showLaunchAtLoginError(enable: false)
            }
        } else {
            UserDefaults.standard.set(false, forKey: "launchAtLogin")
            showLaunchAtLoginLegacyMessage()
        }
    }
    
    func showLaunchAtLoginError(enable: Bool) {
        let alert = NSAlert()
        alert.messageText = "Launch at Login Error"
        alert.informativeText = "Unable to \(enable ? "enable" : "disable") launch at login. Please check System Settings > General > Login Items."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showLaunchAtLoginLegacyMessage() {
        let alert = NSAlert()
        alert.messageText = "Manual Setup Required"
        alert.informativeText = "Please add Eye Care to your Login Items manually in System Preferences > Users & Groups > Login Items."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showSleepModeAlert() {
        let alert = NSAlert()
        alert.messageText = "Sleep Mode Active"
        alert.informativeText = "This feature is blocked during your sleep time. Please wait until your sleep time ends."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        if UserDefaults.standard.bool(forKey: "preventQuit") {
            let alert = NSAlert()
            alert.messageText = "Are you sure you want to quit?"
            alert.informativeText = "Eye Care helps protect your eyes. Quitting will disable break reminders."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Quit Anyway")
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn {
                NSApplication.shared.terminate(nil)
            }
            return
        }
        NSApplication.shared.terminate(nil)
    }
    
    func showBreakOverlay() {
        if breakWindow == nil {
            breakWindow = BreakOverlayWindow(timerManager: timerManager)
        }
        breakWindow?.show()
    }
    
    func hideBreakOverlay() {
        print("🔴🔴🔴 hideBreakOverlay() called in AppDelegate")
        
        // Close any warning windows
        warningWindow?.close()
        warningWindow = nil
        warningHostingController = nil
        
        guard let window = breakWindow else {
            print("⚠️ breakWindow is already nil")
            return
        }
        
        print("🔴 Step 1: Force closing window")
        window.forceClose()
        
        print("🔴 Step 2: Setting breakWindow to nil")
        breakWindow = nil
        
        print("🔴 Step 3: Forcing window list update")
        NSApp.updateWindows()
        
        print("🔴 Step 4: Hiding all app windows at screenSaver level")
        for appWindow in NSApp.windows {
            if appWindow.level == .screenSaver {
                print("🔴 Found lingering screenSaver window, forcing it out")
                appWindow.orderOut(nil)
                appWindow.close()
            }
        }
        
        print("🔴 Step 5: Activating normal windows")
        NSApp.activate(ignoringOtherApps: false)
        
        print("✅ hideBreakOverlay completed - window MUST be gone")
    }
    
    func showSleepBlock() {
        print("🌙 showSleepBlock() - Creating sleep block window")
        if sleepWindow == nil {
            sleepWindow = SleepBlockWindow(timerManager: timerManager)
        }
        sleepWindow?.show()
        print("🌙 Sleep block window is now active")
    }

    func hideSleepBlock() {
        print("☀️ hideSleepBlock() - Removing sleep block window")
        if let window = sleepWindow {
            window.forceClose()
            sleepWindow = nil
        }
        print("☀️ Sleep block window removed")
    }

    private var warningWindow: NSWindow?
    private var warningHostingController: NSHostingController<InAppWarningView>?

    func showInAppWarning(minutesRemaining: Int) {
        // Close existing warning
        warningWindow?.close()
        
        // Create warning view
        let warningView = InAppWarningView(minutesRemaining: minutesRemaining, secondsRemaining: nil)
        let hostingController = NSHostingController(rootView: warningView)
        warningHostingController = hostingController
        
        // Create window
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.contentView = hostingController.view
        
        // Position at top-right of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.maxX - windowFrame.width - 20
            let y = screenFrame.maxY - windowFrame.height - 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.orderFrontRegardless()
        warningWindow = window
        
        // Don't auto-dismiss if it's the 1-minute warning (countdown will show)
        if minutesRemaining != 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.warningWindow?.close()
                self?.warningWindow = nil
                self?.warningHostingController = nil
            }
        }
    }

    func updateInAppWarning(secondsRemaining: Int) {
        // Only show countdown for the last 60 seconds
        guard secondsRemaining <= 60 else { return }
        
        // If no window exists, create one
        if warningWindow == nil {
            let warningView = InAppWarningView(minutesRemaining: nil, secondsRemaining: secondsRemaining)
            let hostingController = NSHostingController(rootView: warningView)
            warningHostingController = hostingController
            
            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 100),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            window.level = .floating
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.contentView = hostingController.view
            
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let x = screenFrame.maxX - windowFrame.width - 20
                let y = screenFrame.maxY - windowFrame.height - 20
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            window.orderFrontRegardless()
            warningWindow = window
        } else {
            // Update existing window
            let warningView = InAppWarningView(minutesRemaining: nil, secondsRemaining: secondsRemaining)
            warningHostingController?.rootView = warningView
        }
        
        // Close when countdown reaches 0
        if secondsRemaining == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.warningWindow?.close()
                self?.warningWindow = nil
                self?.warningHostingController = nil
            }
        }
    }
    
    func showLockedAlert() {
        let remainingTime = timerManager.getRemainingLockTime()
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        
        let alert = NSAlert()
        alert.messageText = "Settings Locked"
        alert.informativeText = String(format: "Settings are locked for %d:%02d more.", minutes, seconds)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func showCredits() {
        let alert = NSAlert()
        alert.messageText = "Credits"
        alert.informativeText = """
        EyeCare App
        
        Created by: Kai Rozema
        
        If you have any good ideas for new features or an app, please contact me, I like to make apps and I would love to help you!
        
        For sugestions and contact: https://github.com/thaclownminion/MacOS-eye-care/issues
        © \(Calendar.current.component(.year, from: Date()))
        App version: 1.3.0
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            settingsWindow = nil
        }
    }
}
