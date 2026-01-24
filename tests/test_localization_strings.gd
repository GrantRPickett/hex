extends GdUnitTestSuite

const LocalizedStrings := preload("res://Resources/Localization/localization_strings.gd")

func test_supported_languages_include_defaults() -> void:
	var languages := LocalizedStrings.get_supported_languages()
	assert_that(languages).contains("en").contains("es")

func test_get_text_returns_spanish_value() -> void:
	var value := LocalizedStrings.get_text("menus.title.play", "es")
	assert_that(value).is_equal("Jugar")

func test_get_text_handles_region_variants() -> void:
	var value := LocalizedStrings.get_text("hud.end_turn", "es-MX")
	assert_that(value).is_equal("Terminar turno")

func test_get_text_falls_back_to_default_language_when_missing_language() -> void:
	var value := LocalizedStrings.get_text("combat.victory", "fr")
	assert_that(value).is_equal("Victory")

func test_get_text_returns_key_when_missing_entry() -> void:
	var missing_key := "hud.timer"
	var value := LocalizedStrings.get_text(missing_key, "en")
	assert_that(value).is_equal(missing_key)

func test_round_label_template_formats_value() -> void:
	var template := LocalizedStrings.get_text("hud.round_label")
	assert_that(template.format({"round": 3})).is_equal("Round: 3")

func test_enemy_fallback_translates() -> void:
	assert_that(LocalizedStrings.get_text("hud.enemy_fallback", "es")).is_equal("Enemigo")

