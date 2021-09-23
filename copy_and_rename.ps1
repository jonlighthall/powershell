$userdir = 'C:\Users\jlighthall'
$source = '$userdir\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\'
$target = '$userdir\Pictures'

echo "copy pictures..."
if (Test-Path -Path $source) {
       echo "$source found"
       if (Test-Path -Path $target) {
	      echo "$target found"
	      echo "proceeding with copy..."
	      cp $source\* $target
	      cd $target
	      Get-ChildItem -Exclude *.jpg,*.ps1 | Rename-Item -NewName { $_.Name + ".jpg"} | Remove-Item
	      Get-ChildItem -Exclude *.jpg,*.ps1 | Remove-Item
	      echo "done"
	  }
   else {
    echo "$target not found"
    echo "no destination to copy to`nexiting"
    }   	      
   }
   else {
    echo "$source not found"
    echo "no pictures to copy`nexiting"
    }   	      
	      

	
