import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    weak var appDelegate: AppDelegate?
    
    @State private var workMinutes: Double
    @State private var breakSeconds: Double
    @State private var focusMinutes: Double
    @State private var breakMessage: String
    @State private var selectedTheme: AppTheme
    @State private var preventQuit: Bool = UserDefaults.standard.bool(forKey: "preventQuit")
    @State private var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: "launchAtLogin")
    
    @State private var notificationsEnabled: Bool
    @State private var useSystemNotifications: Bool
    @State private var notification5min: Bool
    @State private var notification2min: Bool
    @State private var notification1min: Bool
    
    @State private var scheduleEnabled: Bool
    @State private var mondayEnabled: Bool
    @State private var tuesdayEnabled: Bool
    @State private var wednesdayEnabled: Bool
    @State private var thursdayEnabled: Bool
    @State private var fridayEnabled: Bool
    @State private var saturdayEnabled: Bool
    @State private var sundayEnabled: Bool
    
    let defaultBreakMessage = "Time for a break!"
    
    init(timerManager: TimerManager, appDelegate: AppDelegate?) {
        self.timerManager = timerManager
        self.appDelegate = appDelegate
        _workMinutes = State(initialValue: timerManager.workInterval / 60)
        _breakSeconds = State(initialValue: timerManager.breakDuration)
        _focusMinutes = State(initialValue: timerManager.focusDuration / 60)
        _breakMessage = State(initialValue: timerManager.breakMessage)
        _selectedTheme = State(initialValue: timerManager.currentTheme)
        
        _scheduleEnabled = State(initialValue: timerManager.scheduleEnabled)
        _mondayEnabled = State(initialValue: timerManager.mondayEnabled)
        _tuesdayEnabled = State(initialValue: timerManager.tuesdayEnabled)
        _wednesdayEnabled = State(initialValue: timerManager.wednesdayEnabled)
        _thursdayEnabled = State(initialValue: timerManager.thursdayEnabled)
        _fridayEnabled = State(initialValue: timerManager.fridayEnabled)
        _saturdayEnabled = State(initialValue: timerManager.saturdayEnabled)
        _sundayEnabled = State(initialValue: timerManager.sundayEnabled)
        
        _notificationsEnabled = State(initialValue: timerManager.notificationsEnabled)
        _useSystemNotifications = State(initialValue: timerManager.useSystemNotifications)
        _notification5min = State(initialValue: timerManager.notificationTiming.contains(5))
        _notification2min = State(initialValue: timerManager.notificationTiming.contains(2))
        _notification1min = State(initialValue: timerManager.notificationTiming.contains(1))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Eye Care Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Theme Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance Theme")
                            .font(.headline)
                        
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedTheme) { oldValue, newValue in
                            // Apply theme immediately
                            applyThemeImmediately(newValue)
                        }
                        
                        Text("Changes the appearance of the settings window only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Break Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Message")
                            .font(.headline)
                        
                        TextField("Enter custom message", text: $breakMessage)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: resetToDefaultMessage) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11))
                                Text("Reset to default")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                        
                        Text("This message appears during breaks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Work Interval")
                            .font(.headline)
                        Text("\(Int(workMinutes)) minutes")
                            .foregroundColor(.secondary)
                        Slider(value: $workMinutes, in: 1...120, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Duration")
                            .font(.headline)
                        Text("\(Int(breakSeconds)) seconds")
                            .foregroundColor(.secondary)
                        Slider(value: $breakSeconds, in: 10...300, step: 5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus Mode Duration")
                            .font(.headline)
                        Text("\(Int(focusMinutes)) minutes")
                            .foregroundColor(.secondary)
                        Slider(value: $focusMinutes, in: 15...180, step: 5)
                        Text("No breaks during focus mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()

                    // Break Notifications
                    VStack(alignment: .leading, spacing: 15) {
                        Toggle("Enable Break Notifications", isOn: $notificationsEnabled)
                            .font(.headline)
                        
                        if notificationsEnabled {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Notification Type")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $useSystemNotifications) {
                                    Text("System Notifications").tag(true)
                                    Text("In-App Indicator").tag(false)
                                }
                                .pickerStyle(.segmented)
                                
                                Text("Notify me before break:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                                
                                Toggle("5 minutes before", isOn: $notification5min)
                                Toggle("2 minutes before", isOn: $notification2min)
                                Toggle("1 minute before", isOn: $notification1min)
                                
                                Text(useSystemNotifications ?
                                    "System notifications appear in Notification Center" :
                                    "In-app indicator shows at top-right of screen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                            .padding(.leading, 10)
                        }
                    }
                    
                    Divider()
                    
                    // Weekly Schedule
                    VStack(alignment: .leading, spacing: 15) {
                        Toggle("Enable Weekly Schedule", isOn: $scheduleEnabled)
                            .font(.headline)
                            .onChange(of: scheduleEnabled) { oldValue, newValue in
                                timerManager.scheduleEnabled = newValue
                                timerManager.updateScheduleSettings()
                            }
                        
                        if scheduleEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Active Days")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Toggle("Monday", isOn: $mondayEnabled)
                                    .onChange(of: mondayEnabled) { oldValue, newValue in
                                        timerManager.mondayEnabled = newValue
                                    }
                                Toggle("Tuesday", isOn: $tuesdayEnabled)
                                    .onChange(of: tuesdayEnabled) { oldValue, newValue in
                                        timerManager.tuesdayEnabled = newValue
                                    }
                                Toggle("Wednesday", isOn: $wednesdayEnabled)
                                    .onChange(of: wednesdayEnabled) { oldValue, newValue in
                                        timerManager.wednesdayEnabled = newValue
                                    }
                                Toggle("Thursday", isOn: $thursdayEnabled)
                                    .onChange(of: thursdayEnabled) { oldValue, newValue in
                                        timerManager.thursdayEnabled = newValue
                                    }
                                Toggle("Friday", isOn: $fridayEnabled)
                                    .onChange(of: fridayEnabled) { oldValue, newValue in
                                        timerManager.fridayEnabled = newValue
                                    }
                                Toggle("Saturday", isOn: $saturdayEnabled)
                                    .onChange(of: saturdayEnabled) { oldValue, newValue in
                                        timerManager.saturdayEnabled = newValue
                                    }
                                Toggle("Sunday", isOn: $sundayEnabled)
                                    .onChange(of: sundayEnabled) { oldValue, newValue in
                                        timerManager.sundayEnabled = newValue
                                    }
                                
                                Text("Breaks only happen on selected days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 10)
                        }
                    }
                    
                    Divider()
                    
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { oldValue, newValue in
                            if newValue {
                                appDelegate?.enableLaunchAtLogin()
                            } else {
                                appDelegate?.disableLaunchAtLogin()
                            }
                        }
                    
                    Text("Start Eye Care automatically when you log in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("confirm before quitting the app", isOn: $preventQuit)
                        .onChange(of: preventQuit) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "preventQuit")
                            timerManager.onSettingsChange?()
                        }
                    
                    Text("When enabled, quitting requires confirmation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 30)
                
                Button(action: saveSettings) {
                    Text("Save Settings")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 400, height: 700)
    }
    
    func resetToDefaultMessage() {
        breakMessage = defaultBreakMessage
    }
    
    // ADD: Apply theme immediately without saving
    func applyThemeImmediately(_ theme: AppTheme) {
        // Update timer manager theme
        timerManager.currentTheme = theme
        
        // Apply to settings window
        if let window = NSApp.windows.first(where: { $0.title == "Eye Care Settings" }) {
            switch theme {
            case .system:
                window.appearance = nil
            case .light:
                window.appearance = NSAppearance(named: .aqua)
            case .dark:
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
    
    func saveSettings() {
        print("💾 Saving settings...")
        
        let manager = timerManager
        
        var timings: [Int] = []
        if notification5min { timings.append(5) }
        if notification2min { timings.append(2) }
        if notification1min { timings.append(1) }
        manager.notificationTiming = timings.sorted(by: >)
        
        manager.notificationsEnabled = notificationsEnabled
        manager.useSystemNotifications = useSystemNotifications
        
        manager.updateSettings(
            work: workMinutes * 60,
            breakTime: breakSeconds,
            focusTime: focusMinutes * 60,
            message: breakMessage,
            theme: selectedTheme
        )
        
        manager.updateScheduleSettings()
        
        let alert = NSAlert()
        alert.messageText = "Settings Saved ✅"
        alert.informativeText = "Your settings have been saved successfully."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        
        if let window = NSApp.windows.first(where: { $0.title == "Eye Care Settings" }) {
            window.close()
        }
    }
}
