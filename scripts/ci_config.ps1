function Get-CiConfig {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $defaultGodotCliRoot = Join-Path $repoRoot ".godot-cli"
    $defaultExtensionListPath = Join-Path $repoRoot ".godot\\extension_list.cfg"

    return @{
        GodotCliRoot = $env:HEX_GODOT_CLI_ROOT ?? $defaultGodotCliRoot
        ExtensionListPath = $env:HEX_EXTENSION_LIST_PATH ?? $defaultExtensionListPath
    }
}
