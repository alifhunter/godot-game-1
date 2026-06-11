class_name SaveMigrations
extends RefCounted

# Stepwise save-format migration. RunState.load_from_dict routes every loaded
# run dict through migrate() before field parsing, so older saves can be
# upgraded structurally instead of relying solely on per-field _normalize_*
# defaults. RunState.SAVE_SCHEMA_VERSION aliases CURRENT_SCHEMA_VERSION.
#
# When the save shape changes:
#   1. Bump CURRENT_SCHEMA_VERSION.
#   2. Add a `static func _migrate_vN_to_vN1(data: Dictionary) -> Dictionary`
#      that rewrites the OLD shape into the NEW shape (mutate the copy it is
#      given and return it).
#   3. Add its `match` arm below. Never edit older migration functions —
#      they must keep accepting the shapes that existed when they shipped.

const CURRENT_SCHEMA_VERSION := 7


static func migrate(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return data
	var version: int = int(data.get("save_schema_version", 0))
	if version >= CURRENT_SCHEMA_VERSION:
		return data
	var migrated: Dictionary = data.duplicate(true)
	while version < CURRENT_SCHEMA_VERSION:
		match version:
			# Versions 0..6 predate structural migrations: their differences
			# are absorbed by RunState's _normalize_* layer (legacy guide
			# state, deprecated life locations, missing fields get defaults).
			# First real rewrite goes here as `7: migrated = _migrate_v7_to_v8(migrated)`.
			_:
				pass
		version += 1
	migrated["save_schema_version"] = CURRENT_SCHEMA_VERSION
	return migrated
