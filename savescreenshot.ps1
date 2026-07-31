Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Define Win32 wrapper
$Win32Code = @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Drawing;
using System.Drawing.Imaging;

public class Win32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(IntPtr hwndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public class WindowInfo {
        public IntPtr Handle { get; set; }
        public string ClassName { get; set; }
        public int Left { get; set; }
        public int Top { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
    }

    public static List<WindowInfo> GetChildWindows(IntPtr parentHandle) {
        List<WindowInfo> result = new List<WindowInfo>();
        EnumChildWindows(parentHandle, (hWnd, lParam) => {
            StringBuilder className = new StringBuilder(256);
            GetClassName(hWnd, className, className.Capacity);
            RECT rect;
            GetWindowRect(hWnd, out rect);
            result.Add(new WindowInfo {
                Handle = hWnd,
                ClassName = className.ToString(),
                Left = rect.Left,
                Top = rect.Top,
                Width = rect.Right - rect.Left,
                Height = rect.Bottom - rect.Top
            });
            return true;
        }, IntPtr.Zero);
        return result;
    }

    public static Bitmap CaptureRegion(int x, int y, int width, int height) {
        Bitmap bmp = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp)) {
            g.CopyFromScreen(x, y, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy);
        }
        return bmp;
    }

    public static Bitmap ResizeBitmap(Bitmap src, int width, int height) {
        Bitmap result = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(result)) {
            g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
            g.DrawImage(src, 0, 0, width, height);
        }
        return result;
    }

    public static Bitmap ApplyCircularMask(Bitmap src) {
        int w = src.Width;
        int h = src.Height;
        Bitmap result = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(result)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using (System.Drawing.Drawing2D.GraphicsPath path = new System.Drawing.Drawing2D.GraphicsPath()) {
                path.AddEllipse(0, 0, w, h);
                g.SetClip(path);
                g.DrawImage(src, 0, 0);
            }
        }
        return result;
    }
}
"@

Add-Type -TypeDefinition $Win32Code -ReferencedAssemblies System.Drawing

$process = Get-Process -Name simulator -ErrorAction SilentlyContinue
if (!$process) {
    Write-Error "Garmin Connect IQ Simulator is not running."
    exit 1
}

$mainHandle = $process.MainWindowHandle
if ($mainHandle -eq [IntPtr]::Zero) {
    Write-Error "Could not find simulator main window handle."
    exit 1
}

# Resolve device directory from Simulator window title
$title = $process.MainWindowTitle
Write-Host "Simulator window title: '$title'"

$devicesBaseDir = Join-Path $env:APPDATA "Garmin\ConnectIQ\Devices"
$deviceDir = $null

if ($title -like "*CIQ Simulator - *") {
    $rawDevices = ($title -split "CIQ Simulator - ")[1] -split "/"
    foreach ($rawDevice in $rawDevices) {
        $clean = ($rawDevice -split "\(")[0].Trim().ToLower() -replace "[^a-z0-9]", ""
        # Candidates include the clean string and substitutions for accented model
        # names: "fenixr" -> "fenix", and "fnix" -> "fenix" (the "e" in "fēnix" is an
        # accented char that gets stripped, e.g. "fēnix 8 47mm" -> "fnix847mm").
        $candidates = @($clean, ($clean -replace "fenixr", "fenix"), ($clean -replace "fnix", "fenix"))
        foreach ($cand in $candidates) {
            $path = Join-Path $devicesBaseDir $cand
            if (Test-Path $path) {
                $deviceDir = $path
                break
            }
        }
        if ($deviceDir) { break }
    }
}

if (!$deviceDir) {
    Write-Host "Could not automatically resolve device directory from window title. Falling back to fenix8solar51mm."
    $deviceDir = Join-Path $devicesBaseDir "fenix8solar51mm"
}

Write-Host "Using device configuration from: $deviceDir"

# Load simulator.json
$simJsonPath = Join-Path $deviceDir "simulator.json"
if (!(Test-Path $simJsonPath)) {
    Write-Error "simulator.json not found in device directory."
    exit 1
}

$simJson = Get-Content $simJsonPath | ConvertFrom-Json
$displayLoc = $simJson.display.location
$bgImageFile = $simJson.image

# Load background image to get its original resolution
$bgImagePath = Join-Path $deviceDir $bgImageFile
if (!(Test-Path $bgImagePath)) {
    Write-Error "Background image $bgImagePath not found."
    exit 1
}

$bgImg = [System.Drawing.Image]::FromFile($bgImagePath)
$bgWidth = $bgImg.Width
$bgHeight = $bgImg.Height
$bgImg.Dispose()

Write-Host "Device background image dimensions: $($bgWidth)x$($bgHeight)"
Write-Host "Device display relative location: X=$($displayLoc.x), Y=$($displayLoc.y), W=$($displayLoc.width), H=$($displayLoc.height)"

# Enumerate child windows to find the drawing canvas wxWindowNR
$children = [Win32]::GetChildWindows($mainHandle)
$canvas = $null
foreach ($c in $children) {
    if ($c.ClassName -eq "wxWindowNR") {
        $canvas = $c
        break
    }
}

if (!$canvas) {
    Write-Error "Could not find simulator canvas (wxWindowNR)."
    exit 1
}

Write-Host "Found simulator canvas: Handle=$($canvas.Handle), Pos=($($canvas.Left), $($canvas.Top)), Size=$($canvas.Width)x$($canvas.Height)"

# Activate and restore simulator window to bring it to foreground
[Win32]::ShowWindow($mainHandle, 9) | Out-Null # SW_RESTORE
[Win32]::SetForegroundWindow($mainHandle) | Out-Null
Start-Sleep -Milliseconds 400

# The simulator draws the device image at NATIVE 1:1 resolution, anchored to the
# canvas top-left; it does NOT scale to fit. If the window is too small the image is
# simply clipped (cutting off the bottom/right of the watch). So size the window large
# enough to show the whole device image (bgWidth x bgHeight) plus the toolbar/border
# chrome, then capture the display region 1:1. This makes the script correct for ANY
# device (454 and 416 alike) with no manual window sizing.
$winRect = New-Object Win32+RECT
[Win32]::GetWindowRect($mainHandle, [ref]$winRect) | Out-Null
$winW = $winRect.Right - $winRect.Left
$winH = $winRect.Bottom - $winRect.Top
$chromeW = $winW - $canvas.Width    # window border width beyond the canvas
$chromeH = $winH - $canvas.Height   # toolbar + title bar + border height
$targetW = $bgWidth + $chromeW + 8
$targetH = $bgHeight + $chromeH + 8
[Win32]::MoveWindow($mainHandle, 80, 10, $targetW, $targetH, $true) | Out-Null
Start-Sleep -Milliseconds 600

# Re-read the canvas rect after the resize.
$children = [Win32]::GetChildWindows($mainHandle)
foreach ($c in $children) {
    if ($c.ClassName -eq "wxWindowNR") {
        $canvas = $c
        break
    }
}

Write-Host "Canvas after resize: Pos=($($canvas.Left), $($canvas.Top)) Size=$($canvas.Width)x$($canvas.Height) (device image $($bgWidth)x$($bgHeight) shown 1:1)"

# Compute absolute screen region to capture (1:1, top-left anchored).
$captureLeft = $canvas.Left + $displayLoc.x
$captureTop = $canvas.Top + $displayLoc.y
$captureWidth = $displayLoc.width
$captureHeight = $displayLoc.height

Write-Host "Capturing screen region: Left=$captureLeft, Top=$captureTop, Width=$captureWidth, Height=$captureHeight"

# Capture from screen
$capturedBmp = [Win32]::CaptureRegion($captureLeft, $captureTop, $captureWidth, $captureHeight)

# Resize back to native resolution for clean output (e.g. 280x280)
$resizedBmp = [Win32]::ResizeBitmap($capturedBmp, $displayLoc.width, $displayLoc.height)

# Apply circular mask if the device display shape is round
if ($simJson.display.shape -eq "round") {
    Write-Host "Applying circular mask for round screen..."
    $maskedBmp = [Win32]::ApplyCircularMask($resizedBmp)
    $resizedBmp.Dispose()
    $resizedBmp = $maskedBmp
}

# Save image to assets (resolved relative to this script's location)
$outputPath = Join-Path $PSScriptRoot "assets\screen_active.png"
Write-Host "Saving watchface screenshot to $outputPath"
if (Test-Path $outputPath) {
    Remove-Item $outputPath -Force
}
$resizedBmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Clean up
$capturedBmp.Dispose()
$resizedBmp.Dispose()

Write-Host "Successfully captured watchface and updated screen_active.png!" -ForegroundColor Green