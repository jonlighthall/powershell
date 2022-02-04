userdir = 'C:\Users\jlighthall'
source = '$userdir\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\'
target = '$userdir\Pictures'

Write-Output "copy pictures..."
if (Test-Path -Path $source) {
       Write-Output "$source found"
       if (Test-Path -Path $target) {
	      Write-Output "$target found"
	      Write-Output "proceeding with copy..."
	      Copy-Item $source\* $target
	      Set-Location $target
	      Get-ChildItem -Exclude *.jpg,*.ps1 | Rename-Item -NewName { $_.Name + ".jpg"} | Remove-Item
	      Get-ChildItem -Exclude *.jpg,*.ps1 | Remove-Item
	      Write-Output "done"
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
	      

	
