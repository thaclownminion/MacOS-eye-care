using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Avalonia.Threading;

namespace Descreen;

public partial class App : Application
{
    public override void Initialize() => AvaloniaXamlLoader.Load(this);

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            var timerManager = new TimerManager();
            var mainVm       = new MainViewModel(timerManager);
            var mainWindow   = new MainWindow { DataContext = mainVm };

            mainVm.SetWindow(mainWindow);
            desktop.MainWindow = mainWindow;

            // Guard: only one overlay can be open at a time
            BreakOverlayWindow? activeOverlay = null;

            timerManager.OnBreakStart = () => Dispatcher.UIThread.Post(() =>
            {
                // If an overlay is somehow already open, close it first
                if (activeOverlay != null && activeOverlay.IsVisible)
                {
                    activeOverlay.ForceClose();
                    activeOverlay = null;
                }

                activeOverlay = new BreakOverlayWindow(timerManager);
                activeOverlay.Closed += (_, _) => activeOverlay = null;
                activeOverlay.Show();
            });

            timerManager.OnBreakEnd = () => Dispatcher.UIThread.Post(() =>
            {
                activeOverlay?.ForceClose();
                activeOverlay = null;
            });

            timerManager.Start();
        }

        base.OnFrameworkInitializationCompleted();
    }
}
