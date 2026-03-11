extends GdUnitTestSuite

func test_paths_access() -> void:
	assert_str(GameConfig.Paths.AUDIO_MUSIC).is_equal("audio/music_db")
	assert_str(GameConfig.Paths.AUDIO_MUSIC_MUTED).is_equal("audio/music_muted")
	assert_str(GameConfig.Paths.AUDIO_NARRATIVE).is_equal("audio/narrative_db")
	assert_str(GameConfig.Paths.AUDIO_NARRATIVE_MUTED).is_equal("audio/narrative_muted")
	print("Paths access verified successfully!")
