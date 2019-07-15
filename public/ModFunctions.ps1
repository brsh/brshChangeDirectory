Function Remove-cdAlias {
	<#
	.SYNOPSIS
	Deletes an existing Directory Alias

	.DESCRIPTION
	Deletes a saved Directory Alias. If both a persisted and non-persisted Alias
	exists for the same Alias, the first run will remove only the non-persisted
	Alias (which doesn't require confirmation or the -Force switch), and a second
	run will be required to remove the persisted. Or you could use the -All switch
	to remove them both (which _would_ require confirmation for the file portion).

	Returns an object with either a confirmation of deletion... or a reason why not.

	.PARAMETER Alias
	The name of the existing saved Alias

	.PARAMETER Force
	Does not prompt to confirm the file should be deleted ... just does it (you don't need this for non-persisted Aliases)

	.PARAMETER All
	Deletes both Persisted and Non-Persisted at once (otherwise, non-persisted would go, if one exists)

	.EXAMPLE
	Remove-cdAlias -Alias 'Aida'

Alias  Type        Result
----   ----        -----
Aida   Persisted   Removed


	#>
	param (
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Get-cdAlias -Filter "$WordToComplete").Alias
				} else {
					(Get-cdAlias).Alias
				}
			})]
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias('Name')]
		[string] $Alias,
		[switch] $Force = $false,
		[Switch] $All = $false
	)

	#Deprecating $Confirm cuz it's the wrong option here
	#It's a delete, it should never just do it!
	[bool] $Confirm = -not $Force
	[bool] $DoPersisted = $false
	[bool] $DoNonPersisted = $false

	# $hash = [ordered] @{
	# 	Alias   = $Alias
	# 	Deleted = '!! Not removed !!'
	# }

	$AllTheThings = Get-cdAlias -Filter "^${Alias}$" | Sort-Object -Property Persist

	If (-$null -eq $AllTheThings) {
		Write-Status -Message "Alias $Alias not found" -Type 'Error' -Level 0
		Write-Status -Message "Verify the Alias with `'Get-cdAlias -filter $Alias`'" -Type 'Info' -Level 1
	} else {
		#Are there more than 1
		foreach ($Thing in $AllTheThings) {
			$DoPersisted = $false
			$DoNonPersisted = $false
			if ($All) {
				if ($Thing.Persist) {
					Remove-Persisted -Confirm:$Confirm -Alias $Thing.Alias
				} else {
					Remove-NonPersisted -Alias $Thing.Alias
				}

			} else {
				if ($Thing.Persist) {
					Remove-Persisted -Confirm:$Confirm -Alias $Thing.Alias
				} else {
					Remove-NonPersisted -Alias $Thing.Alias
				}
				break
			}
		}

	}

	# $out = New-Object -TypeName psobject -Property $hash
	# $out.PSObject.TypeNames.Insert(0, 'brshCD.RemovedAlias')
	# $out
}
