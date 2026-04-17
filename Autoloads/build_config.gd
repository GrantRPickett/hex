class_name BuildConfig

enum BuildType {
	DEBUG,
	PRE_RELEASE_DEMO,
	POST_RELEASE_DEMO,
	PAID_BUILD
}

static func get_build_type() -> BuildType:
	# Check for command line overrides first
	var args := OS.get_cmdline_args()
	if "--build-type=debug" in args: return BuildType.DEBUG
	if "--build-type=pre-demo" in args: return BuildType.PRE_RELEASE_DEMO
	if "--build-type=post-demo" in args: return BuildType.POST_RELEASE_DEMO
	if "--build-type=paid" in args: return BuildType.PAID_BUILD

	# Fallback to defaults
	if OS.is_debug_build():
		return BuildType.DEBUG
	
	# Default to paid for production, unless a marker file exists
	if FileAccess.file_exists("user://pre_release_demo.marker"):
		return BuildType.PRE_RELEASE_DEMO
	if FileAccess.file_exists("user://post_release_demo.marker"):
		return BuildType.POST_RELEASE_DEMO
		
	return BuildType.PAID_BUILD
