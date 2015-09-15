<#
Copyright 2015 Cloudbase Solutions Srl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

# Import required PowerShell modules
import-module Microsoft.PowerShell.Management
import-module Microsoft.PowerShell.Utility

$cloudbaseInitBaseDir = "$Env:SystemDrive\Cloudbase-Init"
$cloudbaseInitConfigDir = Join-Path $cloudbaseInitBaseDir "Config"
$cloudbaseInitLogDir = Join-Path $cloudbaseInitBaseDir "Log"
$cloudbaseInitPythonDir = Join-Path $cloudbaseInitBaseDir "Python"
$cloudbaseInitPythonScriptsDir = Join-Path $cloudbaseInitPythonDir "Scripts"
$cloudbaseInitConfigFile = Join-Path $cloudbaseInitConfigDir "cloudbase-init.conf"
$cloudbaseInitUnattendConfigFile = Join-Path $cloudbaseInitConfigDir "cloudbase-init-unattend.conf"
$pythonExePath = Join-Path $cloudbaseInitPythonDir "python.exe"
$cloudbaseInitExePath = Join-Path $cloudbaseInitPythonScriptsDir "cloudbase-init.exe"

# Register pywin32 COM components
& $pythonExePath "$cloudbaseInitPythonScriptsDir\pywin32_postinstall.py" -install -silent -quiet
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to run pywin32_postinstall.py"
    exit 1
}

# Update Python exe wrappers
& $pythonExePath -c "import os; import sys; from pip._vendor.distlib import scripts; specs = 'cloudbase-init = cloudbaseinit.shell:main'; scripts_path = os.path.join(os.path.dirname(sys.executable), 'Scripts'); m = scripts.ScriptMaker(None, scripts_path); m.executable = sys.executable; m.make(specs)"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to update Python exe wrappers"
    exit 1
}

# set service startup type
& sc.exe create "cloudbase-init" binPath= "\"$cloudbaseInitExePath\" --config-file \"$cloudbaseInitConfigFile\"" DisplayName= "Cloudbase-Init" start= auto
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set service auto start"
    exit 1
}

#run cloudbase-init unattend
& $cloudbaseInitExePath --config-file $cloudbaseInitUnattendConfigFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to run cloudbase-init unattend"
    exit 1
}
