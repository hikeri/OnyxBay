
/mob/living/carbon/human/verb/wristwear_layer()
	set name = "Change Wristwear Layer"
	set category = "IC"

	change_wristwear_layer()

/mob/living/carbon/human/proc/change_wristwear_layer()
	var/list/underwear_list = list()
	for(var/obj/item/underwear/wrist/W in worn_underwear)
		underwear_list |= W

	if(length(underwear_list) < 1)
		to_chat(usr, SPAN("notice", "You wear nothing on your wrists."))
		return

	var/obj/item/underwear/wrist/choice = null
	if(length(underwear_list) == 1)
		choice = underwear_list[1]
	else
		choice = tgui_input_list(usr, "Position Wristwear", "Select Wristwear", underwear_list)

	var/list/options = list("Under Uniform" = HO_UNDERWEAR_PLUS_LAYER, "Over Uniform" = HO_UNDERWEAR_UNIFORM_LAYER, "Over Suit" = HO_UNDERWEAR_SUIT_LAYER)
	var/new_layer = tgui_input_list(usr, "Position Wristwear", "Wristwear Style", options)
	if(new_layer)
		choice.mob_wear_layer = options[new_layer]
		to_chat(usr, SPAN_NOTICE("\The [src] will now layer [new_layer]."))
		var/mob/living/carbon/human/H = usr
		H?.update_underwear()


/obj/item/underwear/wrist
	required_free_body_parts = NO_BODYPARTS
	mob_wear_layer = HO_UNDERWEAR_PLUS_LAYER
	underwear_slot = UNDERWEAR_SLOT_WRISTS
	icon = 'icons/obj/clothing/wrist.dmi'
	/// Can use different wear layers to be drawn over/under uniform.
	/// Some children of this type can be flipped (left/right wrist). -1 means it cannot be flipped at all.
	var/flipped = -1

/obj/item/underwear/wrist/Initialize()
	. = ..()
	if(flipped != -1)
		verbs += /obj/item/underwear/wrist/proc/swap_wrists

// If we can't equip the thing - we'll try to flip it automatically.
/obj/item/underwear/wrist/CanEquipUnderwear(mob/user, mob/living/carbon/human/H, silent = TRUE)
	. = ..()
	if(.)
		return TRUE // We are good

	if(flipped == -1)
		return FALSE // No sense trying

	_swap_wrists(null)
	return ..(user, H, FALSE) // Trying again after swapping

/obj/item/underwear/wrist/proc/swap_wrists()
	set name = "Flip Wristwear"
	set category = "Object"
	set src in usr

	if(!ishuman(usr))
		return

	if(usr.stat)
		return

	_swap_wrists(usr)

/obj/item/underwear/wrist/proc/_swap_wrists(mob/living/carbon/human/user)
	if(user && (src in user.worn_underwear))
		to_chat(user, "\The [src] must be taken off first.")
		return // Screw checking things, let's just force them to take the thing off. That's exactly now you put your watches on the other wrist, after all.

	flipped = !flipped
	icon_state = "[initial(item_state)][flipped ? "_flip" : ""]"
	underwear_slot = flipped ? UNDERWEAR_SLOT_L_WRIST  : UNDERWEAR_SLOT_R_WRIST

	if(user)
		to_chat(user, "You change \the [src] to be on your [flipped ? "left" : "right"] wrist.")

	if(pickup_sound)
		play_handling_sound(slot_r_hand)
	else
		play_drop_sound()

	user?.update_underwear()
