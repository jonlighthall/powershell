# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

Set-Variable -Name "userdir" -Value "C:\Users\jlighthall"
Set-Variable -Name "source" -Value "$userdir\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\"
Set-Variable -Name "target" -Value "$userdir\OneDrive - US Navy-flankspeed\Pictures\Lock Screen"
$start_dir = pwd

Write-Output "copy pictures..."
if (Test-Path -Path $source) {
       Write-Output "$source found"
       if (Test-Path -Path $target) {
	      Write-Output "$target found"
	      Write-Output "proceeding with copy..."
	      Copy-Item -Verbose $source\* $target
	      Set-Location $target
	      Get-ChildItem -Exclude *.jpg,*.ps1 | Rename-Item -NewName { $_.Name + ".jpg"} | Remove-Item
	      Get-ChildItem -Exclude *.jpg,*.ps1 | Remove-Item
	      Write-Output "done"
          Set-Location $start_dir
	  }
   else {
    Write-Output "$target not found"
    Write-Output "no destination to copy to`nexiting"
    }   	      
   }
   else {
    Write-Output "$source not found"
    Write-Output "no pictures to copy`nexiting"
    }