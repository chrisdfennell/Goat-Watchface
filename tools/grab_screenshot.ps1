# Capture the watch face from the running Connect IQ simulator.
#
# Uses PrintWindow, which asks the simulator to render *itself* into a bitmap.
# That matters for two reasons:
#
#   * it cannot capture anything else on your desktop, whatever happens to be
#     in front of or behind the simulator
#   * it does not depend on window position, z-order, or display scaling
#
# savescreenshot.ps1 takes the other approach - work out the display rectangle
# from simulator.json and grab that region of the screen - which is sharper when
# it works, but is thrown off by a scaled display or a window that is not where
# it thinks it is.
#
# Run:  powershell -ExecutionPolicy Bypass -File tools\grab_screenshot.ps1
# then: python tools\crop_screenshot.py

Add-Type -AssemblyName System.Drawing

$code = @"
using System;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Drawing.Imaging;

public class WinGrab {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);

    // PW_RENDERFULLCONTENT - needed for windows that draw with a compositor
    const uint FULL_CONTENT = 2;

    public static Bitmap Window(IntPtr h, int w, int ht) {
        Bitmap bmp = new Bitmap(w, ht, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp)) {
            IntPtr hdc = g.GetHdc();
            try { PrintWindow(h, hdc, FULL_CONTENT); }
            finally { g.ReleaseHdc(hdc); }
        }
        return bmp;
    }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

[WinGrab]::SetProcessDPIAware() | Out-Null

$proc = Get-Process simulator -ErrorAction SilentlyContinue
if (!$proc) { Write-Error "The Connect IQ simulator is not running."; exit 1 }

$h = $proc.MainWindowHandle
if ($h -eq [IntPtr]::Zero) { Write-Error "No simulator window found."; exit 1 }

[WinGrab]::ShowWindow($h, 3) | Out-Null      # SW_MAXIMIZE - fit the whole device image
Start-Sleep -Milliseconds 900

$r = New-Object WinGrab+RECT
[WinGrab]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left
$ht = $r.Bottom - $r.Top
Write-Host "Rendering simulator window (${w}x${ht}) via PrintWindow"

$bmp = [WinGrab]::Window($h, $w, $ht)
$out = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\_simwin.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Saved $out" -ForegroundColor Green
