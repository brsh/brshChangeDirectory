param (
	[switch] $Quiet = $False
)
#region Default Private Variables
# Current script path
[string] $script:ScriptPath = Split-Path (Get-Variable MyInvocation -scope script).value.MyCommand.Definition -Parent
if ((Get-Variable MyInvocation -Scope script).Value.Line.Trim().Length -eq 0) { $Quiet = $true }
[string[]] $script:ShowHelp = @()
# if ($PSVersionTable.PSVersion.Major -lt 6) {
# 	[bool] $IsLinux = $false
# }
#endregion Default Private Variables

#region Load Private Helpers
# Dot sourcing private script files
Get-ChildItem $script:ScriptPath/private -Recurse -Filter "*.ps1" -File | ForEach-Object {
	. $_.FullName
}
#endregion Load Private Helpers

#region Load Public Helpers
# Dot sourcing public script files
Get-ChildItem $ScriptPath/public -Recurse -Filter "*.ps1" -File | ForEach-Object {
	. $_.FullName

	# From https://www.the-little-things.net/blog/2015/10/03/powershell-thoughts-on-module-design/
	# Find all the functions defined no deeper than the first level deep and export it.
	# This looks ugly but allows us to not keep any unneeded variables from polluting the module.
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref] $null, [ref] $null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
		#if (($IsLinux) -and ($_.Name -match 'SomethingThatMatches')) {
		#	#This Function is not available in Linux
		#} else {
		Export-ModuleMember $_.Name
		$ShowHelp += $_.Name
		#}
	}
}
#endregion Load Public Helpers

[string] $script:cdFolder = ''
$script:InMemory = @()

try {
	if (test-path "$script:scriptpath\config\DataFolderPath.txt") {
		if (-not $Quiet) { Write-host "Attempting to load ChangeDirectory config file..." }
		[string] $script:cdFolder = get-content "$script:scriptpath\config\DataFolderPath.txt"
		if (-not $Quiet) { Write-Host "  Loaded config file" -ForegroundColor Green }
		if (-not $Quiet) {
			if (test-path $script:cdFolder -ErrorAction SilentlyContinue) {
				Write-Host "  Path to cdFolder ($($script:cdFolder)) is valid" -ForegroundColor Green
			} else {
				Write-Host "  Path to cdFolder ($($script:cdFolder)) is NOT valid" -ForegroundColor Yellow
				Write-Host "  Use the Set-cdFolder function "
			}
		}
	} else {
		if (-not $Quiet) { Write-host "Default config does not exist.... Fixing that problem.... " -ForegroundColor Yellow }
		Set-cdFolder -default -clobber
		if (-not $Quiet) {
			Write-host "  Use Set-cdFolder to override this default (if necessary)"
			Write-host ""
		}
	}

} catch {
	$script:cdFolder = ""
	Write-Host "No default cdFolder exists. Use 'Set-cdFolder' to create one"
}


#region Load Formats
if (test-path $ScriptPath\formats\brshChangeDirectory.format.ps1xml) {
	Update-FormatData $ScriptPath\formats\brshChangeDirectory.format.ps1xml
}
#endregion Load Formats

if (-not $Quiet) {
	Get-cdHelp
}

Export-ModuleMember -Alias 'cdcd'

#region Module Cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
	# cleanup when unloading module (if any)
	Get-ChildItem alias: | Where-Object { $_.Source -match "brshChangeDirectory" } | Remove-Item
	Get-ChildItem function: | Where-Object { $_.Source -match "brshChangeDirectory" } | Remove-Item
	Get-ChildItem variable: | Where-Object { $_.Source -match "brshChangeDirectory" } | Remove-Item
}
#endregion Module Cleanup

