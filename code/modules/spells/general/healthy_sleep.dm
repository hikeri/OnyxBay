
/datum/spell/healthy_sleep
	name = "Take a nap"
	desc = "Healthy sleep is a basic need that is closely tied to health and wellbeing."
	spell_flags = INCLUDEUSER
	charge_max = 120 SECONDS
	duration = 30 SECONDS
	need_target = FALSE

	invocation = "lies down and falls asleep immediately."
	invocation_type = SPI_EMOTE

	range = 0
	icon_state = "wiz_sleep"

/datum/spell/healthy_sleep/New()
	..()
	add_think_ctx("wakethefuckup", CALLBACK(src, nameof(.proc/wakethefuckup)), 0)

/datum/spell/healthy_sleep/cast(list/targets, mob/user)
	user.sleeping = max(30, user.sleeping)
	set_next_think_ctx("wakethefuckup", world.time + duration)

/datum/spell/healthy_sleep/proc/wakethefuckup()
	if(QDELETED(holder))
		return

	if(!ishuman(holder))
		return

	var/mob/living/carbon/human/H = holder

	if(H.is_ic_dead())
		return

	H.restore_blood()
	H.adjustToxLoss(H.getToxLoss() * -1)
	H.adjustOxyLoss(H.getOxyLoss() * -1)
	H.adjustBrainLoss(H.getBrainLoss() * -1)
	H.heal_overall_damage(H.getBruteLoss(), H.getFireLoss())

	var/list/organs = H.get_damaged_organs(1, 1)
	for(var/A in organs)
		var/obj/item/organ/external/E = A
		if(E.status & ORGAN_ARTERY_CUT)
			E.status &= ~ORGAN_ARTERY_CUT
		if(E.status & ORGAN_TENDON_CUT)
			E.status &= ~ORGAN_TENDON_CUT
		if(E.status & ORGAN_BROKEN)
			E.mend_fracture()
			E.stage = 0

	H.updatehealth()
	H.sleeping = 0
	to_chat(H, SPAN("notice", "<b>You've had a good rest. Now you absolutely need to munch on something.</b>"))
	H.remove_nutrition(H.nutrition)
