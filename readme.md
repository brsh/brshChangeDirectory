# brshChangeDirectory - A simple Set-Location via Directory Aliases module

I think everyone might have one of these. But why should that stop me
from practicing my PowerShell. (Even if I did strip a lot from the
SecureTokens module, it's still practice).

This is just a reasonably simple module that lets you set Aliases for
oft used directories so you can just Set-Location to an much shorter
collection of letters than the full path.

So rather than typing:

```PowerShell
Set-Location C:\MyLong\Path\Is\Too\Long\To\Type
```

You can instead type:
```PowerShell
Set-cdLocation TooLong
```

and poof - there you be.

Note: Set-cdLocation is aliased to `cdcd`

Of course, you have to create those Aliases, but there are functions for that too.

```PowerShell
Add-cdAlias -Alias TooLong -Path C:\MyLong\Path\Is\Too\Long\To\Type
```

Or leave off the `-Path` switch and it'll choose the current location. And if
you like, it will natively support PSDrives or use the -LiteralPath for $pwd
and it'll use the ... literal path.

Most of the Aliases are Persisted to local storage (by default in the
$env:APPDATA\brshChangeDirectory, but that's changeable). You can also use
temporary Non-Persisted Aliases via the `-DoNotPersist` switch. Non-Persisted
will disappear when the PS session is closed. They also over-ride Persisted
Aliases during the PS session.

| Command        | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| Add-cdAlias    | Add a Directory Alias                                                |
| Get-cdAlias    | Returns the list of all active directory aliases                     |
| Get-cdFolder   | Returns the path to the data file for Set-cdLocation                 |
| Get-cdHelp     | List commands available in the brshChangeDirectory Module            |
| Remove-cdAlias | Deletes an existing Directory Alias                                  |
| Set-cdFolder   | Set (and save) the location of the files that hold Directory Aliases |
| Set-cdLocation | Set-Location based on Directory Alias                                |

