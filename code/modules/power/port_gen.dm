//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/* new portable generator - work in progress

/obj/structure/machinery/power/port_gen
	name = "portable generator"
	desc = "A portable generator used for emergency backup power."
	icon = 'generator.dmi'
	icon_state = "off"
	density = TRUE
	anchored = FALSE
	directwired = 0
	var/t_status = 0
	var/t_per = 5000
	var/filter = 1
	var/tank = null
	var/turf/inturf
	var/starter = 0
	var/rpm = 0
	var/rpmtarget = 0
	var/capacity = 1e6
	var/turf/outturf
	var/lastgen


/obj/structure/machinery/power/port_gen/process()
ideally we're looking to generate 5000

/obj/structure/machinery/power/port_gen/attackby(obj/item/W, mob/user)
tank [un]loading stuff

/obj/structure/machinery/power/port_gen/attack_hand(mob/user)
turn on/off

/obj/structure/machinery/power/port_gen/get_examine_text(mob/user)
display floor(lastgen) and phorontank amount

*/

//Previous code been here forever, adding new framework for portable generators


//Baseline portable generator. Has all the default handling. Not intended to be used on it's own (since it generates unlimited power).
/obj/structure/machinery/power/port_gen
	name = "Placeholder Generator" //seriously, don't use this. It can't be anchored without VV magic.
	desc = "A portable generator for emergency backup power."
	icon = 'icons/obj/structures/machinery/power.dmi'
	icon_state = "portgen0"
	density = TRUE
	anchored = FALSE
// directwired = 0
	use_power = USE_POWER_NONE
	unslashable = FALSE

	var/active = 0
	var/power_gen = 5000
	var/open = 0
	var/recent_fault = 0
	var/power_output = 1
	power_machine = TRUE

/obj/structure/machinery/power/port_gen/proc/HasFuel() //Placeholder for fuel check.
	return 1

/obj/structure/machinery/power/port_gen/proc/UseFuel() //Placeholder for fuel use.
	return

/obj/structure/machinery/power/port_gen/proc/DropFuel()
	return

/obj/structure/machinery/power/port_gen/proc/handleInactive()
	return

/obj/structure/machinery/power/port_gen/power_change()
	return

/obj/structure/machinery/power/port_gen/process()
	if(active && HasFuel() && !crit_fail && anchored && powernet)
		add_avail(power_gen * power_output)
		UseFuel()
		src.updateDialog()

	else
		active = 0
		stop_processing()
		icon_state = initial(icon_state)
		handleInactive()

/obj/structure/machinery/power/powered()
	return 1 //doesn't require an external power source

/obj/structure/machinery/power/port_gen/attack_hand(mob/user as mob)
	if(..())
		return
	if(!anchored)
		return

/obj/structure/machinery/power/port_gen/get_examine_text(mob/user)
	. = ..()
	if(active)
		. += SPAN_NOTICE("The generator is on.")
	else
		. += SPAN_NOTICE("The generator is off.")

/obj/structure/machinery/power/port_gen/attack_alien(mob/living/carbon/xenomorph/attacking_xeno)
	if(!active && !anchored)
		return ..()

	if(attacking_xeno.mob_size < MOB_SIZE_XENO)
		to_chat(attacking_xeno, SPAN_XENOWARNING("You're too small to do any significant damage to affect this!"))
		return XENO_NO_DELAY_ACTION

	attacking_xeno.animation_attack_on(src)
	attacking_xeno.visible_message(SPAN_DANGER("[attacking_xeno] slashes [src]!"), SPAN_DANGER("You slash [src]!"))
	playsound(attacking_xeno, pick('sound/effects/metalhit.ogg', 'sound/weapons/alien_claw_metal1.ogg', 'sound/weapons/alien_claw_metal2.ogg', 'sound/weapons/alien_claw_metal3.ogg'), 25, 1)

	if(active)
		active = FALSE
		stop_processing()
		icon_state = initial(icon_state)
		visible_message(SPAN_NOTICE("[src] sputters to a stop!"))
		return XENO_NONCOMBAT_ACTION

	if(anchored)
		anchored = FALSE
		visible_message(SPAN_NOTICE("[src]'s bolts are dislodged!"))
		return XENO_NONCOMBAT_ACTION

//A power generator that runs on solid plasma sheets.
/obj/structure/machinery/power/port_gen/pacman
	name = "P.A.C.M.A.N.-type Portable Generator"
	var/sheets = 0
	var/max_sheets = 100
	var/sheet_name = ""
	var/sheet_path = /obj/item/stack/sheet/mineral/phoron
	var/board_path = /obj/item/circuitboard/machine/pacman
	var/sheet_left = 0 // How much is left of the sheet
	var/time_per_sheet = 70
	var/heat = 0

/obj/structure/machinery/power/port_gen/pacman/Initialize()
	. = ..()
	if(anchored)
		connect_to_network()

	QDEL_NULL_LIST(component_parts)
	LAZYADD(component_parts, new /obj/item/stock_parts/matter_bin(src))
	LAZYADD(component_parts, new /obj/item/stock_parts/micro_laser(src))
	LAZYADD(component_parts, new /obj/item/stack/cable_coil(src))
	LAZYADD(component_parts, new /obj/item/stack/cable_coil(src))
	LAZYADD(component_parts, new /obj/item/stock_parts/capacitor(src))
	LAZYADD(component_parts, new board_path(src))
	var/obj/sheet = new sheet_path(null)
	sheet_name = sheet.name
	RefreshParts()

/obj/structure/machinery/power/port_gen/pacman/Destroy()
	DropFuel()
	. = ..()

/obj/structure/machinery/power/port_gen/pacman/RefreshParts()
	var/temp_rating = 0
	var/temp_reliability = 0
	for(var/obj/item/stock_parts/SP in component_parts)
		if(istype(SP, /obj/item/stock_parts/matter_bin))
			max_sheets = SP.rating * SP.rating * 50
		else if(istype(SP, /obj/item/stock_parts/micro_laser) || istype(SP, /obj/item/stock_parts/capacitor))
			temp_rating += SP.rating
	for(var/obj/item/CP in component_parts)
		temp_reliability += CP.reliability
	reliability = min(floor(temp_reliability / 4), 100)
	power_gen = floor(initial(power_gen) * (max(2, temp_rating) / 2))

/obj/structure/machinery/power/port_gen/pacman/get_examine_text(mob/user)
	. = ..()
	. += SPAN_NOTICE(" The generator has [sheets] units of [sheet_name] fuel left, producing [power_gen] per cycle.")
	if(crit_fail) . += SPAN_DANGER("The generator seems to have broken down.")

/obj/structure/machinery/power/port_gen/pacman/HasFuel()
	if(sheets >= 1 / (time_per_sheet / power_output) - sheet_left)
		return 1
	return 0

/obj/structure/machinery/power/port_gen/pacman/DropFuel()
	if(sheets)
		var/fail_safe = 0
		while(sheets > 0 && fail_safe < 100)
			fail_safe++
			var/obj/item/stack/sheet/S = new sheet_path(loc)
			var/amount = min(sheets, S.max_amount)
			S.amount = amount
			sheets -= amount

/obj/structure/machinery/power/port_gen/pacman/UseFuel()
	var/needed_sheets = 1 / (time_per_sheet / power_output)
	var/temp = min(needed_sheets, sheet_left)
	needed_sheets -= temp
	sheet_left -= temp
	sheets -= floor(needed_sheets)
	needed_sheets -= floor(needed_sheets)
	if (sheet_left <= 0 && sheets > 0)
		sheet_left = 1 - needed_sheets
		sheets--

	var/lower_limit = 56 + power_output * 10
	var/upper_limit = 76 + power_output * 10
	var/bias = 0
	if (power_output > 4)
		upper_limit = 400
		bias = power_output * 3
	if (heat < lower_limit)
		heat += 3
	else
		heat += rand(-7 + bias, 7 + bias)
		if (heat < lower_limit)
			heat = lower_limit
		if (heat > upper_limit)
			heat = upper_limit

	if (heat > 300)
		overheat()
		qdel(src)
	return

/obj/structure/machinery/power/port_gen/pacman/handleInactive()

	if (heat > 0)
		heat = max(heat - 2, 0)
		src.updateDialog()

/obj/structure/machinery/power/port_gen/pacman/proc/overheat()
	explosion(src.loc, 2, 5, 2, -1)

/obj/structure/machinery/power/port_gen/pacman/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O, sheet_path))
		var/obj/item/stack/addstack = O
		var/amount = min((max_sheets - sheets), addstack.amount)
		if(amount < 1)
			to_chat(user, SPAN_NOTICE(" The [src.name] is full!"))
			return
		to_chat(user, SPAN_NOTICE(" You add [amount] sheets to the [src.name]."))
		sheets += amount
		addstack.use(amount)
		updateUsrDialog()
		return
	else if(!active)

		if(HAS_TRAIT(O, TRAIT_TOOL_WRENCH))

			if(!anchored)
				connect_to_network()
				to_chat(user, SPAN_NOTICE(" You secure the generator to the floor."))
			else
				disconnect_from_network()
				to_chat(user, SPAN_NOTICE(" You unsecure the generator from the floor."))

			playsound(src.loc, 'sound/items/Deconstruct.ogg', 25, 1)
			anchored = !anchored

		else if(HAS_TRAIT(O, TRAIT_TOOL_SCREWDRIVER))
			open = !open
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
			if(open)
				to_chat(user, SPAN_NOTICE(" You open the access panel."))
			else
				to_chat(user, SPAN_NOTICE(" You close the access panel."))
		else if(HAS_TRAIT(O, TRAIT_TOOL_CROWBAR) && open)
			var/obj/structure/machinery/constructable_frame/new_frame = new /obj/structure/machinery/constructable_frame(src.loc)
			for(var/obj/item/I in component_parts)
				if(I.reliability < 100)
					I.crit_fail = 1
				I.forceMove(src.loc)
			while ( sheets > 0 )
				var/obj/item/stack/sheet/G = new sheet_path(src.loc)

				if ( sheets > 50 )
					G.amount = 50
				else
					G.amount = sheets

				sheets -= G.amount

			new_frame.state = CONSTRUCTION_STATE_PROGRESS
			new_frame.update_icon()
			qdel(src)

/obj/structure/machinery/power/port_gen/pacman/attack_hand(mob/user as mob)
	..()
	if (!anchored)
		return

	interact(user)

/obj/structure/machinery/power/port_gen/pacman/attack_remote(mob/user as mob)
	interact(user)

/obj/structure/machinery/power/port_gen/pacman/interact(mob/user)
	if (get_dist(src, user) > 1 )
		if (!isRemoteControlling(user))
			user.unset_interaction()
			close_browser(user, "port_gen")
			return

	user.set_interaction(src)

	var/dat = text("<b>[name]</b><br>")
	if (active)
		dat += text("Generator: <A href='byond://?src=\ref[src];action=disable'>On</A><br>")
	else
		dat += text("Generator: <A href='byond://?src=\ref[src];action=enable'>Off</A><br>")
	dat += text("[capitalize(sheet_name)]: [sheets] - <A href='byond://?src=\ref[src];action=eject'>Eject</A><br>")
	var/stack_percent = round(sheet_left * 100, 1)
	dat += text("Current stack: [stack_percent]% <br>")
	dat += text("Power output: <A href='byond://?src=\ref[src];action=lower_power'>-</A> [power_gen * power_output] <A href='byond://?src=\ref[src];action=higher_power'>+</A><br>")
	dat += text("Power current: [(powernet == null ? "Unconnected" : "[avail()]")]<br>")
	dat += text("Heat: [heat]<br>")
	dat += "<br><A href='byond://?src=\ref[src];action=close'>Close</A>"
	user << browse("[dat]", "window=port_gen")
	onclose(user, "port_gen")

/obj/structure/machinery/power/port_gen/pacman/Topic(href, href_list)
	if(..())
		return

	src.add_fingerprint(usr)
	if(href_list["action"])
		if(href_list["action"] == "enable")
			if(!active && HasFuel() && !crit_fail)
				active = 1
				start_processing()
				icon_state = "portgen1"
				src.updateUsrDialog()
		if(href_list["action"] == "disable")
			if (active)
				active = 0
				stop_processing()
				icon_state = "portgen0"
				src.updateUsrDialog()
		if(href_list["action"] == "eject")
			if(!active)
				DropFuel()
				src.updateUsrDialog()
		if(href_list["action"] == "lower_power")
			if (power_output > 1)
				power_output--
				src.updateUsrDialog()
		if (href_list["action"] == "higher_power")
			if (power_output < 4)
				power_output++
				src.updateUsrDialog()
		if (href_list["action"] == "close")
			close_browser(usr, "port_gen")
			usr.unset_interaction()

/obj/structure/machinery/power/port_gen/pacman/inoperable(additional_flags)
	return (stat & (BROKEN|additional_flags)) //Removes NOPOWER check since its a goddam generator and doesn't need power

/obj/structure/machinery/power/port_gen/pacman/super
	name = "S.U.P.E.R.P.A.C.M.A.N.-type Portable Generator"
	icon_state = "portgen1"
	sheet_path = /obj/item/stack/sheet/mineral/uranium
	power_gen = 15000
	time_per_sheet = 120
	board_path = /obj/item/circuitboard/machine/pacman/super

/obj/structure/machinery/power/port_gen/pacman/super/overheat()
	explosion(src.loc, 3, 3, 3, -1)

/obj/structure/machinery/power/port_gen/pacman/mrs
	name = "M.R.S.P.A.C.M.A.N.-type Portable Generator"
	icon_state = "portgen2"
	sheet_path = /obj/item/stack/sheet/mineral/tritium
	power_gen = 40000
	time_per_sheet = 150
	board_path = /obj/item/circuitboard/machine/pacman/mrs

/obj/structure/machinery/power/port_gen/pacman/mrs/overheat()
	explosion(src.loc, 4, 4, 4, -1)
