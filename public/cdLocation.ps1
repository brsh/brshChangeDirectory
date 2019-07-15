function Set-cdLocation {
	<#
	.SYNOPSIS
	Set-Location based on Directory Alias

	.DESCRIPTION
	A Set-Location replacement (aliased as cdcd) that leverages aliases for directories

	So, you can use the function Add-cdAlias to add an alias for a directory, and then
	use this function to quickly switch to that directory.

	If you have "over-ridden" the persisted Alias with a non-persisted one, this function
	will select the over-ride (i.e., the 'in memory' not the 'on-disk' alias).

	And yeah, it breaks the 'do one thing' commandment, but this function will also
	save new Aliases ... so you can combine a change directory command with a save for
	later command into one line.

	.PARAMETER Alias
	The Alias to lookup

	.PARAMETER Directory
	The directory to which to switch

	.PARAMETER Save
	Store this alias and the path to reference later

	.PARAMETER DoNotPersist
	Save it, but only temporarily

	.PARAMETER Clobber
	Overwrite an existing alias

	.EXAMPLE
	Set-cdLocation MyHome

	Sets the location to the directory referred to by the MyHome alias

	.EXAMPLE
	Set-cdLocation MyHome -Directory $env:USERPROFILE -DoNotPersist

	Sets a temporary alias called MyHome to the UserProfile directory


	.EXAMPLE
	Set-cdLocation MyHome -Directory $env:USERPROFILE -Save

	Sets an alias called MyHome to the UserProfile directory

	#>
	[cmdletbinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = "Default", Position = 0)]
		[Parameter(Mandatory = $true, ParameterSetName = "Save", Position = 0)]
		[Parameter(Mandatory = $true, ParameterSetName = "NoPersist", Position = 0)]
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Get-cdAlias -Filter "$WordToComplete").Alias
				} else {
					(Get-cdAlias).Alias
				}
			})]
		[Alias('Name')]
		[string] $Alias,
		[Parameter(Mandatory = $true, ParameterSetName = "Save", Position = 1)]
		[Parameter(Mandatory = $true, ParameterSetName = "NoPersist", Position = 1)]
		[Alias('Path')]
		[string] $Directory,
		[Parameter(Mandatory = $true, ParameterSetName = "Save")]
		[switch] $Save,
		[Parameter(Mandatory = $true, ParameterSetName = "NoPersist")]
		[switch] $DoNotPersist,
		[Parameter(Mandatory = $false, ParameterSetName = "Save")]
		[Parameter(Mandatory = $false, ParameterSetName = "NoPersist")]
		[Alias('Force')]
		[switch] $Clobber = $false
	)
	if (($Save) -or ($DoNotPersist)) {
		Add-cdAlias -Alias $Alias -Path $Directory -DoNotPersist:$DoNotPersist -Clobber:$Clobber
	}

	$loc = (Get-cdAlias -Filter "^${Alias}`$") | Sort-Object -Property Persist | Select-Object -First 1

	if ($loc.Directory.Length -gt 0) {
		try {
			Set-Location -Path $loc.Directory
			Write-Status -Message "Directory set: $($loc.Directory)" -Type "Good" -Level 0
		} catch {
			Write-Status -Message "Failed to change directory." -Type 'Error' -Level 0 -E $_
		}
	} else {
		Write-Status -Message "Alias $Alias not found" -Type 'Error' -Level 0
	}

}

New-Alias -Name 'cdcd' -Value 'Set-cdLocation' -Description 'Set-Location with a Directory Alias'
