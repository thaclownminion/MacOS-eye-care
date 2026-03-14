using System;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Avalonia.Threading;

namespace Descreen;

public partial class MainViewModel : ObservableObject
{
    private readonly TimerManager _timer;
    private MainWindow? _window;

    [ObservableProperty] private string _timeLeftText    = "Calculating...";
    [ObservableProperty] private string _focusStatusText = "Focus Mode: Off";
    [ObservableProperty] private string _focusButtonText = "Enable Focus Mode";

    public MainViewModel(TimerManager timer)
    {
        _timer = timer;

        _timer.OnTimeUpdate = remaining => UI(() =>
        {
            int m = (int)remaining / 60, s = (int)remaining % 60;
            TimeLeftText = $"Next break in:  {m}:{s:D2}";
        });

        _timer.OnFocusUpdate = remaining => UI(() =>
        {
            FocusStatusText = remaining > 0
                ? $"Focus Mode: {(int)remaining / 60}:{(int)remaining % 60:D2} left"
                : "Focus Mode: Off";
        });

        _timer.OnSettingsChange   = () => UI(UpdateFocusButton);
        _timer.OnTimerStateChange = () => UI(UpdateFocusButton);

        // Notifications go to OS — handled by Notifier, not in-app
        _timer.OnBreakWarning = mins => UI(() =>
        {
            string title = mins <= 1 ? "Break Starting Soon!" : "Break Coming Soon";
            string body  = $"Your eye break starts in {mins} minute{(mins == 1 ? "" : "s")}";
            Notifier.Send(title, body);
        });
    }

    // Called by App so the ViewModel can show/hide the window
    public void SetWindow(MainWindow window) => _window = window;

    private void UpdateFocusButton() =>
        FocusButtonText = _timer.IsFocusModeActive ? "Disable Focus Mode" : "Enable Focus Mode";

    [RelayCommand]
    private void ToggleFocusMode()
    {
        if (_timer.IsFocusModeActive) { _timer.EndFocusMode(); return; }

        if (_timer.FocusCooldownEnabled)
        {
            var raw = Prefs.Get("lastFocusEnd");
            if (long.TryParse(raw, out var ticks))
            {
                double elapsed  = (DateTime.Now - new DateTime(ticks)).TotalSeconds;
                double cooldown = _timer.FocusCooldownMinutes * 60;
                if (elapsed < cooldown)
                {
                    double rem = cooldown - elapsed;
                    Notifier.Send("Focus Mode Cooldown",
                        $"Please wait {(int)rem / 60}:{(int)rem % 60:D2} before enabling again.");
                    return;
                }
            }
        }
        _timer.StartFocusMode();
    }

    [RelayCommand]
    private void TakeBreakNow() => _timer.TriggerBreakNow();

    [RelayCommand]
    private void HideWindow() => _window?.Hide();

    [RelayCommand]
    private void OpenSettings()
    {
        var win = new SettingsWindow(_timer);
        win.Show();
    }

    [RelayCommand]
    private void OpenFeedback() =>
        OpenUrl("https://github.com/thaclownminion/Descreen-app_Windows-Linux-MacOS/issues");

    [RelayCommand]
    private void OpenGithub() =>
        OpenUrl("https://github.com/thaclownminion/Descreen-app_Windows-Linux-MacOS");

    public TimerManager Timer => _timer;

    private static void UI(Action a) =>
        Dispatcher.UIThread.Post(a, DispatcherPriority.Normal);

    private static void OpenUrl(string url) =>
        Process.Start(new ProcessStartInfo { FileName = url, UseShellExecute = true });
}
