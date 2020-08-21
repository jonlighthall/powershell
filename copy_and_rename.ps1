cp C:\Users\jlighthall\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\* ./
Get-ChildItem -Exclude *.jpg,*.ps1 | Rename-Item -NewName { $_.Name + ".jpg"} | Remove-Item
Get-ChildItem -Exclude *.jpg,*.ps1 | Remove-Item