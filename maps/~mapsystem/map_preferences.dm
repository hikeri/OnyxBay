/datum/map
	var/load_legacy_saves = FALSE
	var/can_be_voted = TRUE

/datum/map/proc/preferences_key()
	// Must be a filename-safe string. In future if map paths get funky, do some sanitization here.
	return "default"

// Procs for loading legacy savefile preferences
/datum/map/proc/character_save_path(slot)
	//return "/[path]/character[slot]"
	return "/exodus/character[slot]"

/datum/map/proc/character_load_path(savefile/S, slot)
	var/original_cd = S.cd
	S.cd = "/"
	//. = private_use_legacy_saves(S, slot) ? "/character[slot]" : "/[path]/character[slot]"
	. = private_use_legacy_saves(S, slot) ? "/character[slot]" : "/exodus/character[slot]"
	S.cd = original_cd // Attempting to make this call as side-effect free as possible

/datum/map/proc/private_use_legacy_saves(savefile/S, slot)
	if(!load_legacy_saves) // Check if we're bothering with legacy saves at all
		return FALSE
	//if(!S.dir.Find(path)) // If we cannot find the map path folder, load the legacy save
	if(!S.dir.Find("exodus")) // If we cannot find the map path folder, load the legacy save
		return TRUE
	//S.cd = "/[path]" // Finally, if we cannot find the character slot in the map path folder, load the legacy save
	S.cd = "/exodus" // Finally, if we cannot find the character slot in the map path folder, load the legacy save
	return !S.dir.Find("character[slot]")
