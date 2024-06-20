function git_get_user {
    $get_name = (git config --get user.name)
    $get_email = (git config --get user.email)
    return $get_name, $get_email
}

function git_print_user {
    $get_name, $get_email = git_get_user
    $TAB = "   "
    Write-Host "current author name:"
    Write-Host "$TAB$get_name"
    Write-Host
    Write-Host "current author email:"
    Write-Host "$TAB$get_email"
    Write-Host
    return $get_name, $get_email
}

function git_set_user {
    $set_name = "Jon Lighthall"
    $set_email = "jon.lighthall@gmail.com"
    git_print_user
    $get_name, $get_email = git_get_user

    $do_update = $false

    if ($get_name -eq $set_name) {
            Write-Host "names match"
    }
    else {
        Write-Host "names do not match"
        Write-Host "setting git user name..."
        git config user.name $set_name
        $do_update = $true
    }

    if ($get_email -eq $set_email) {
            Write-Host "emails match"
    }
    else {
        Write-Host "emails do not match"
        Write-Host "setting git user email..."
        git config user.email $set_email
        $do_update = $true
    }

    if ($do_update) {
        git_print_user
    }
}

git_set_user
