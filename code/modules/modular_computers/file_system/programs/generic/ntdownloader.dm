/datum/computer_file/program/ntnetdownload
	filename = "ntndownloader"
	filedesc = "NTNet Software Download Tool"
	program_icon_state = "generic"
	program_key_state = "generic_key"
	program_menu_icon = "arrowthickstop-1-s"
	program_light_color = "#00B000"
	extended_desc = "This program allows downloads of software from official NT repositories"
	unsendable = 1
	undeletable = 1
	size = 4
	category = PROG_UTIL
	requires_ntnet = 1
	requires_ntnet_feature = NTNET_SOFTWAREDOWNLOAD
	available_on_ntnet = 0
	nanomodule_path = /datum/nano_module/program/computer_ntnetdownload/
	ui_header = "downloader_finished.gif"
	var/datum/computer_file/program/downloaded_file = null
	var/hacked_download = 0
	var/download_completion = 0 //GQ of downloaded data.
	var/download_netspeed = 0
	var/downloaderror = ""
	var/list/downloads_queue[0]
	var/file_info //For logging, can be faked by antags.
	var/server
	usage_flags = PROGRAM_ALL

/datum/computer_file/program/ntnetdownload/kill_program()
	..()
	downloaded_file = null
	download_completion = 0
	download_netspeed = 0
	downloaderror = ""
	ui_header = "downloader_finished.gif"


/datum/computer_file/program/ntnetdownload/proc/begin_file_download(filename)
	if(downloaded_file)
		return 0

	var/datum/computer_file/program/PRG = ntnet_global.find_ntnet_file_by_name(filename)

	if(!check_file_download(filename))
		return 0

	ui_header = "downloader_running.gif"

	hacked_download = (PRG in ntnet_global.available_antag_software)
	file_info = hide_file_info(PRG)
	generate_network_log("Began downloading file [file_info] from [server].")
	downloaded_file = PRG.clone()

/datum/computer_file/program/ntnetdownload/proc/check_file_download(filename)
	//returns 1 if file can be downloaded, returns 0 if download prohibited
	var/datum/computer_file/program/PRG = ntnet_global.find_ntnet_file_by_name(filename)

	if(!PRG || !istype(PRG))
		return 0

	// Attempting to download antag only program, but without having emagged computer. No.
	if(PRG.available_on_syndinet && !computer_emagged)
		return 0

	if(!computer || !computer.hard_drive || !computer.hard_drive.try_store_file(PRG))
		return 0

	return 1

/datum/computer_file/program/ntnetdownload/proc/hide_file_info(datum/computer_file/file)
	server = (file in ntnet_global.available_station_software) ? "NTNet Software Repository" : "unspecified server"
	if(!hacked_download)
		return "[file.filename].[file.filetype]"
	if(prob(50))
		return "**ENCRYPTED**.[file.filetype]"
	var/datum/computer_file/fake_file = pick(ntnet_global.available_station_software)
	server = "NTNet Software Repository"
	return "[fake_file.filename].[fake_file.filetype]"

/datum/computer_file/program/ntnetdownload/proc/abort_file_download()
	if(!downloaded_file)
		return
	generate_network_log("Aborted download of file [file_info].")
	downloaded_file = null
	download_completion = 0
	ui_header = "downloader_finished.gif"

/datum/computer_file/program/ntnetdownload/proc/complete_file_download()
	if(!downloaded_file)
		return
	generate_network_log("Completed download of file [file_info].")
	if(!computer || !computer.hard_drive || !computer.hard_drive.store_file(downloaded_file))
		// The download failed
		downloaderror = "I/O ERROR - Unable to save file. Check whether you have enough free space on your hard drive and whether your hard drive is properly connected. If the issue persists contact your system administrator for assistance."
	downloaded_file = null
	download_completion = 0
	ui_header = "downloader_finished.gif"

/datum/computer_file/program/ntnetdownload/process_tick()
	if(!downloaded_file)
		return
	if(download_completion >= downloaded_file.size)
		complete_file_download()
		if(downloads_queue.len > 0)
			begin_file_download(downloads_queue[1], downloads_queue[downloads_queue[1]])
			downloads_queue.Remove(downloads_queue[1])

	// Download speed according to connectivity state. NTNet server is assumed to be on unlimited speed so we're limited by our local connectivity
	download_netspeed = 0
	// Speed defines are found in misc.dm
	switch(ntnet_status)
		if(1)
			download_netspeed = NTNETSPEED_LOWSIGNAL
		if(2)
			download_netspeed = NTNETSPEED_HIGHSIGNAL
		if(3)
			download_netspeed = NTNETSPEED_ETHERNET
	download_completion += download_netspeed

/datum/computer_file/program/ntnetdownload/Topic(href, href_list)
	if(..())
		return 1
	if(href_list["PRG_downloadfile"])
		if(!downloaded_file)
			begin_file_download(href_list["PRG_downloadfile"])
		else if(check_file_download(href_list["PRG_downloadfile"]) && !downloads_queue.Find(href_list["PRG_downloadfile"]) && downloaded_file.filename != href_list["PRG_downloadfile"])
			downloads_queue += href_list["PRG_downloadfile"]
		return 1
	if(href_list["PRG_removequeued"])
		downloads_queue.Remove(href_list["PRG_removequeued"])
		return 1
	if(href_list["PRG_reseterror"])
		if(downloaderror)
			download_completion = 0
			download_netspeed = 0
			downloaded_file = null
			downloaderror = ""
		return 1
	return 0

/datum/nano_module/program/computer_ntnetdownload
	name = "Network Downloader"
	var/obj/item/modular_computer/my_computer = null

/datum/nano_module/program/computer_ntnetdownload/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1, datum/topic_state/state = GLOB.default_state)
	if(program)
		my_computer = program.computer

	if(!istype(my_computer))
		return

	var/list/data = list()
	var/datum/computer_file/program/ntnetdownload/prog = program
	// For now limited to execution by the downloader program
	if(!prog || !istype(prog))
		return
	if(program)
		data = program.get_header_data()

	// This IF cuts on data transferred to client, so i guess it's worth it.
	if(prog.downloaderror) // Download errored. Wait until user resets the program.
		data["error"] = prog.downloaderror
	if(prog.downloaded_file) // Download running. Wait please..
		data["downloadname"] = prog.downloaded_file.filename
		data["downloaddesc"] = prog.downloaded_file.filedesc
		data["downloadsize"] = prog.downloaded_file.size
		data["downloadspeed"] = prog.download_netspeed
		data["downloadcompletion"] = round(prog.download_completion, 0.1)

	data["disk_size"] = my_computer.hard_drive.max_capacity
	data["disk_used"] = my_computer.hard_drive.used_capacity
	var/list/all_entries[0]
	for(var/category in ntnet_global.available_software_by_category)
		var/list/category_list[0]
		for(var/datum/computer_file/program/P in ntnet_global.available_software_by_category[category])
			// Only those programs our user can run will show in the list
			if(!P.can_run(user) && P.requires_access_to_download)
				continue
			//if(!P.is_supported_by_hardware(my_computer.hardware_flag, 1, user))
			//	continue
			category_list.Add(list(list(
			"filename" = P.filename,
			"filedesc" = P.filedesc,
			"fileinfo" = P.extended_desc,
			"size" = P.size,
			"icon" = P.program_menu_icon
			)))
		if(category_list.len)
			all_entries.Add(list(list("category"=category, "programs"=category_list)))

	data["hackedavailable"] = 0
	if(prog.computer_emagged) // If we are running on emagged computer we have access to some "bonus" software
		var/list/hacked_programs[0]
		for(var/datum/computer_file/program/P in ntnet_global.available_antag_software)
			data["hackedavailable"] = 1
			hacked_programs.Add(list(list(
			"filename" = P.filename,
			"filedesc" = P.filedesc,
			"fileinfo" = P.extended_desc,
			"size" = P.size,
			"icon" = P.program_menu_icon
			)))
		data["hacked_programs"] = hacked_programs

	data["downloadable_programs"] = all_entries

	if(prog.downloads_queue.len > 0)
		var/list/queue = list() // Nanoui can't iterate through assotiative lists, so we have to do this
		for(var/item in prog.downloads_queue)
			queue += item
		data["downloads_queue"] = queue

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "ntnet_downloader.tmpl", "NTNet Download Program", 575, 700, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)
