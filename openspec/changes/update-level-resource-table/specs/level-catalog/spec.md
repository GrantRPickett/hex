## ADDED Requirements
### Requirement: Level catalog is defined by resources
Level metadata MUST be declared via LevelCatalogEntry Resource assets stored under es://Resources/levels/catalog_entries/ so ResourceTables can edit them as rows.

#### Scenario: Designer edits a level entry in ResourceTables
- **GIVEN** a LevelCatalogEntry resource with exported fields level_id, level_path, display_name, prerequisites, is_hometown, epeatable, and sort_index
- **WHEN** the designer changes any of those fields through the ResourceTables addon
- **THEN** the saved .tres file reflects the new value and can be committed without editing scripts.

### Requirement: LevelCatalog loads entries from resources
The LevelCatalog helper MUST load every LevelCatalogEntry resource, convert it into dictionaries compatible with the existing API, and preserve the sort_index ordering for UI display.

#### Scenario: Loading catalog entries
- **GIVEN** entries level_0, level_1, level_2 with ascending sort_index
- **WHEN** LevelCatalog.get_levels() is called
- **THEN** it returns dictionaries ordered by sort_index, each containing the keys id, path, display_name, prerequisites, is_hometown, and epeatable populated from the resources.

#### Scenario: Lookup by id/path
- **GIVEN** an entry whose level_id is level_5 and level_path is es://Resources/levels/level_5.tres
- **WHEN** get_level_by_id("level_5") or ind_level_by_path("res://Resources/levels/level_5.tres") is invoked
- **THEN** the catalog returns a duplicate dictionary with the same metadata as defined in the resource.

