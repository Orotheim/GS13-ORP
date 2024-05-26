/mob/living/carbon
	//Due to the changes needed to create the system to hide fatness, here's some notes:
	// -If you are making a mob simply gain or lose weight, use adjust_fatness. Try to not touch the variables directly unless you know 'em well
	// -fatness is the value a mob is being displayed and calculated as by most things. Changes to fatness are not permanent
	// -fatness_real is the value a mob is actually at, even if it's being hidden. For permanent changes, use this one
	//What level of fatness is the parent mob currently at?
	var/fatness = 0
	//Is something hiding the actual fatness value of a character?
	var/fat_hider = FALSE
	//The actual value a mob is at. Is equal to fatness if fat_hider is FALSE.
	var/fatness_real = 0
	//The value a mob's fatness is being overwritten with if fat_hider has something in it.
	var/fatness_over = 0
	///At what rate does the parent mob gain weight? 1 = 100%
	var/weight_gain_rate = 1
	//At what rate does the parent mob lose weight? 1 = 100%
	var/weight_loss_rate = 1
	//Variable related to door stuckage code
	var/doorstuck = 0

/** 
* Adjusts the fatness level of the parent mob.
*
* * adjustment_amount - adjusts how much weight is gained or loss. Positive numbers add weight. 
* * type_of_fattening - what type of fattening is being used. Look at the traits in fatness.dm for valid options.
*/
/mob/living/carbon/proc/adjust_fatness(adjustment_amount, type_of_fattening = FATTENING_TYPE_ITEM)
	if(!adjustment_amount || !type_of_fattening)
		return FALSE

	if(!HAS_TRAIT(src, TRAIT_UNIVERSAL_GAINER) && client?.prefs)
		if(!check_weight_prefs(type_of_fattening))
			return FALSE

	var/amount_to_change = adjustment_amount
	if(adjustment_amount > 0)
		amount_to_change = amount_to_change * weight_gain_rate	
	else
		amount_to_change = amount_to_change * weight_loss_rate

	fatness_real += amount_to_change 
	fatness_real = max(fatness_real, MINIMUM_FATNESS_LEVEL) //It would be a little silly if someone got negative fat.

	if(client?.prefs?.max_weight) // GS13
		fatness_real = min(fatness_real, (client?.prefs?.max_weight - 1))

	if(fat_hider)	//If a character's real fatness is being hidden
		if(client?.prefs?.max_weight) //Check their prefs
			fatness_over = min(fatness_over, (client?.prefs?.max_weight - 1)) //And make sure it's not above their preferred max

		fatness = fatness_over //Then, make that value their current fatness
	else			//If it's not being hidden
		fatness = fatness_real //Make their current fatness their real fatness

	if(client?.prefs?.weight_gain_extreme)
		xwg_resize()

	return TRUE


/mob/living/carbon/fully_heal(admin_revive)
	fatness = 0
	fatness_real = 0
	. = ..()

///Checks the parent mob's prefs to see if they can be fattened by the fattening_type
/mob/living/carbon/proc/check_weight_prefs(type_of_fattening = FATTENING_TYPE_ITEM)
	if(HAS_TRAIT(src, TRAIT_UNIVERSAL_GAINER) && !client.prefs) //Comment this second part out
		return TRUE
	
	if(!client?.prefs || !type_of_fattening)
		return FALSE

	switch(type_of_fattening)
		if(FATTENING_TYPE_ITEM)
			if(!client?.prefs?.weight_gain_items)
				return FALSE

		if(FATTENING_TYPE_FOOD)
			if(!client?.prefs?.weight_gain_food)
				return FALSE

		if(FATTENING_TYPE_CHEM) 
			if(!client?.prefs?.weight_gain_chems)
				return FALSE

		if(FATTENING_TYPE_WEAPON)
			if(!client?.prefs?.weight_gain_weapons)
				return FALSE

		if(FATTENING_TYPE_MAGIC)
			if(!client?.prefs?.weight_gain_magic)
				return FALSE

		if(FATTENING_TYPE_VIRUS)
			if(!client?.prefs?.weight_gain_viruses)
				return FALSE

		if(FATTENING_TYPE_WEIGHT_LOSS)
			if(HAS_TRAIT(src, TRAIT_WEIGHT_LOSS_IMMUNE))
				return FALSE
		
	return TRUE

/mob/living/carbon/proc/fat_hide(hide_amount, hide_source)	//If something wants to hide fatness_real, it'll call this method and give it an amount to cover it with
	fat_hider = hide_source
	fatness_over = hide_amount
	fatness = fatness_over	//To update a mob's fatness with the new amount to be shown immediately
	if(client?.prefs?.weight_gain_extreme)
		xwg_resize()

	return TRUE

/mob/living/carbon/proc/fat_show()				//If something that hides fatness is removed or expires, it'll call this method
	fat_hider = FALSE
	fatness = fatness_real	//To update a mob's fatness with their real one immediately
	if(client?.prefs?.weight_gain_extreme)
		xwg_resize()

	return TRUE

/mob/living/carbon/proc/xwg_resize()
	var/xwg_size = sqrt(fatness/FATNESS_LEVEL_BLOB)
	xwg_size = min(xwg_size, RESIZE_HUGE)
	xwg_size = max(xwg_size, custom_body_size*0.01)
	resize(xwg_size)

/proc/get_fatness_level_name(fatness_amount)
	if(fatness_amount < FATNESS_LEVEL_FAT)
		return "Normal"
	if(fatness_amount < FATNESS_LEVEL_FATTER)
		return "Fat"
	if(fatness_amount < FATNESS_LEVEL_VERYFAT)
		return "Fatter"
	if(fatness_amount < FATNESS_LEVEL_OBESE)
		return "Very Fat"
	if(fatness_amount < FATNESS_LEVEL_MORBIDLY_OBESE)
		return "Obese"
	if(fatness_amount < FATNESS_LEVEL_EXTREMELY_OBESE)
		return "Morbidly Obese"
	if(fatness_amount < FATNESS_LEVEL_BARELYMOBILE)
		return "Extremely Obese"
	if(fatness_amount < FATNESS_LEVEL_IMMOBILE)
		return "Barely Mobile"
	if(fatness_amount < FATNESS_LEVEL_BLOB)
		return "Immobile"

	return "Blob"
