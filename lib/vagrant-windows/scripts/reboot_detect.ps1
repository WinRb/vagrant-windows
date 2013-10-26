# function to check whether machine is currently shutting down
function ShuttingDown {
    [string]$sourceCode = @"
using System;
using System.Runtime.InteropServices;

namespace VagrantWindows {
    public static class RemoteManager {
        private const int SM_SHUTTINGDOWN = 0x2000;

        [DllImport("User32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetSystemMetrics(int Index);

        public static bool Shutdown() {
            return (0 != GetSystemMetrics(SM_SHUTTINGDOWN));
        }
    }
}
"@
    $type = Add-Type -TypeDefinition $sourceCode -PassThru
    return $type::Shutdown()
}

if (ShuttingDown) {
  Write-Host "Shutting Down"
  exit 1
}
else {
  Write-Host "All good"
  exit 0
}
