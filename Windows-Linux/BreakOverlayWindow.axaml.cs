using System;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Shapes;
using Avalonia.Media;
using Avalonia.Threading;

namespace Descreen;

public partial class BreakOverlayWindow : Window
{
    private readonly TimerManager _timer;
    private readonly DispatcherTimer _uiTimer;
    private Arc? _progressArc;
    private double _totalDuration;
    private bool _forceClosing = false;

    public BreakOverlayWindow(TimerManager timer)
    {
        InitializeComponent();
        _timer = timer;
        _totalDuration = timer.BreakDuration;

        MessageLabel.Text = timer.BreakMessage;

        // Ensure true fullscreen covering entire screen including taskbar
        this.WindowState = WindowState.FullScreen;

        BuildRing();

        _uiTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
        _uiTimer.Tick += Tick;
        _uiTimer.Start();
    }

    // Called by App.axaml.cs when the break ends
    public void ForceClose()
    {
        _forceClosing = true;
        _uiTimer.Stop();
        Close();
    }

    private void BuildRing()
    {
        const double cx = 110, cy = 110, r = 90, stroke = 12;

        var track = new Ellipse
        {
            Width = r * 2, Height = r * 2,
            Stroke = new SolidColorBrush(Color.FromArgb(50, 255, 255, 255)),
            StrokeThickness = stroke
        };
        Canvas.SetLeft(track, cx - r);
        Canvas.SetTop(track,  cy - r);
        RingCanvas.Children.Add(track);

        _progressArc = new Arc
        {
            Width = r * 2, Height = r * 2,
            Stroke = new SolidColorBrush(Colors.Cyan),
            StrokeThickness = stroke,
            StartAngle = -90,
            SweepAngle = 360,
            StrokeLineCap = PenLineCap.Round
        };
        Canvas.SetLeft(_progressArc, cx - r);
        Canvas.SetTop(_progressArc,  cy - r);
        RingCanvas.Children.Add(_progressArc);
    }

    private void Tick(object? sender, EventArgs e)
    {
        double remaining = _timer.GetRemainingBreakTime();
        CountdownLabel.Text = ((int)Math.Ceiling(remaining)).ToString();

        if (_progressArc != null && _totalDuration > 0)
            _progressArc.SweepAngle = 360f * (float)(remaining / _totalDuration);

        if (_progressArc != null && remaining <= 5)
            _progressArc.Stroke = new SolidColorBrush(Color.FromArgb(200, 0, 230, 230));
    }

    // Block Alt+F4 — the overlay cannot be dismissed by the user
    protected override void OnClosing(WindowClosingEventArgs e)
    {
        if (!_forceClosing)
        {
            e.Cancel = true;
            return;
        }
        _uiTimer.Stop();
        base.OnClosing(e);
    }
}
