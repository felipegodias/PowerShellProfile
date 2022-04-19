$VS_WHERE = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
$POSH_THEME = ".mytheme.omp.json"

function Set-ListFilesAliases
{
    Import-Module Get-ChildItemColor
        
    Set-Alias -Name l -Value Get-ChildItem -Option AllScope -Scope Global
    Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope -Scope Global
}

function Set-NavigableMenu
{
    # Shows navigable menu of all options when hitting Tab
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

    # Autocompletion for arrow keys
    Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
}

function Start-Cmd($cmd, $arguments)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $cmd
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    return $p.StandardOutput.ReadToEnd()
}

function Enter-DevShell
{
    $vsInstanceId = Start-Cmd $VS_WHERE "-latest -property instanceId"
    $vsInstallPath = Start-Cmd $VS_WHERE "-latest -property installationPath"

    $vsInstanceId = $vsInstanceId -replace "\r\n",""
    $vsInstallPath = $vsInstallPath -replace "\r\n",""
    
    Import-Module "$vsInstallPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstanceId $vsInstanceId -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -no_logo'
}

function Set-PersonalAliases
{
    Set-Alias -Name sltp -Value Set-LocationToProject -Scope Global
    Set-Alias -Name ia -Value Invoke-Action -Scope Global
    Set-Alias -Name open -Value Invoke-Open -Scope Global
}

function Invoke-Open([string] $Path)
{
    if ($Path -eq "")
    {
        explorer .
    }
    else
    {
        Invoke-Item $Path
    }
}
Export-ModuleMember Invoke-Open

function Set-LocationToProject
{
    param(
        $Project
    )

    $Projects = $Global:SelectedProfile.projects
    $ProjectExists = $Projects.PSObject.Properties.Item($Project)
    if (-Not $ProjectExists)
    {
        Write-Host "Project '$Project' does not exists in the profile! Do you mean one of these?"
        foreach ($Key in $Projects.PSObject.Properties) {
            $KeyName = $Key.Name
            $ProjectName = $Projects.$KeyName.name
            "{0,-4} => {1}" -f $KeyName, $ProjectName
        }
        return
    }

    $Location = $Projects.$Project.path
    Write-Host "Going to: '$Location'"
    Set-Location $Location
}
Export-ModuleMember Set-LocationToProject

function Invoke-Action
{
    param(
        $Action
    )

    $Actions = $Global:SelectedProfile.actions
    $ActionsExists = $Actions.PSObject.Properties.Item($Action)
    if (-Not $ActionsExists)
    {
        Write-Host "Action '$Action' does not exists in the profile! Do you mean one of these?"
        foreach ($Key in $Actions.PSObject.Properties) {
            $KeyName = $Key.Name
            $ActionDescription = $Actions.$KeyName.name
            "{0,-4} => {1}" -f $KeyName, $ActionDescription
        }
        return
    }

    $Cmd = $Actions.$Action.cmd
    Invoke-Expression $Cmd
}
Export-ModuleMember Invoke-Action

function Invoke-Main
{
    param(
        $InProfile
    )

    $module = Get-Module PowerShellProfile
    $ModuleDir = $Module.ModuleBase

    Set-PoshPrompt -Theme "$moduleDir\$POSH_THEME"
    Set-ListFilesAliases
    
    Set-NavigableMenu

    Enter-DevShell

    Set-PersonalAliases

    Set-Alias -Name open -Value Invoke-Open

    $Module = Get-Module -Name PowerShellProfile

    $ProfileContent = Get-Content "$ModuleDir/profiles/$InProfile.json"
    $Global:SelectedProfile = $ProfileContent | ConvertFrom-Json
}
Export-ModuleMember Invoke-Main