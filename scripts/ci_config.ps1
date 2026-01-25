function Get-CiConfig {
	$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
	$defaultGodotCliRoot = Join-Path $repoRoot ".godot-cli"
	$defaultExtensionListPath = Join-Path $repoRoot ".godot\\extension_list.cfg"

	$godotCliRoot = if ($env:HEX_GODOT_CLI_ROOT) { $env:HEX_GODOT_CLI_ROOT } else { $defaultGodotCliRoot }
	$extensionListPath = if ($env:HEX_EXTENSION_LIST_PATH) { $env:HEX_EXTENSION_LIST_PATH } else { $defaultExtensionListPath }

	return @{
		GodotCliRoot = $godotCliRoot
		ExtensionListPath = $extensionListPath
	}
}
