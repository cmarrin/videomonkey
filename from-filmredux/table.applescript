-- table.applescript
-- FilmRedux
property fullpathcell : 1
property statustextcell : 2
property statusiconcell : 3
property shortnamecell : 4
property starttimecell : 5
property pidcell : 6
property exportfilecell : 7
property outputfilecell : 8
property infocell : 9
property durationnumcell : 10
property durationcell : 11

global theFiles
global fullstarttime
global mencoder
global snippets
global durfile
global tmpdir
global preview
global iscd
global cdtracknum

on drop theObject drag info dragInfo
	set snippets to (load script (scripts path of main bundle & "/snippets.scpt" as POSIX file))
	tmpgetter(true) of snippets
	
	-- DRAG AND SORT --
	set theDataSource to (data source of table view "table" of scroll view "table" of window "FilmRedux")
	set dataTypes to types of pasteboard of dragInfo
	if "file names" is in dataTypes then
		set theFiles to {}
		set preferred type of pasteboard of dragInfo to "file names"
		set theFiles to contents of pasteboard of dragInfo
		if (count of theFiles) > 0 then
			set contents of text field "dragfiles" of window "FilmRedux" to (localized string "checkingfiles")
			
			--	set update views of theDataSource to false
			set theFiles2 to ASCII_Sort(theFiles) as list
			-- prepare temp directory and variables --
			set mencoder to wheremencoder(false) of snippets
			-- slam through files --
			repeat with theItem in theFiles2
				--	if (do shell script "/usr/bin/file -b " & quoted form of theItem & " ; exit 0") is "directory" then
				set theinsidefiles to (do shell script "/usr/bin/find " & quoted form of theItem & " -type f '!' -name '.*' '!' -path '.*' ; exit 0")
				set AppleScript's text item delimiters to return
				set theinsidefileslist to (text items of theinsidefiles)
				repeat with theinsideitem in theinsidefileslist
					tableadder(theinsideitem, fullstarttime)
				end repeat
				--	else
				--tableadder(theItem, fullstarttime)
				--	end if
			end repeat
			tmpcleaner(false) of snippets
			--	set update views of theDataSource to true
		end if
	end if
	gethowmany() of (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
	return true
end drop

on clicked theObject
	-- DRAGGER BUTTON DELETE SHORTCUT
	if enabled of table view "table" of scroll view "table" of window "FilmRedux" is true then
		removeitem() of (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
		gethowmany() of (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
	end if
end clicked

(*
on should select row theObject row theRow
	tell tab view item "advancedoneoffbox" of tab view "advancedbox" of window "advanced"
		set enabled of button "trimonoff" to true
		set contents of button "trimonoff" to false
		set enabled of slider "ss" to false
		set enabled of slider "t" to false
		set enabled of text field "startat" to false
		set contents of text field "startat" to (localized string "startatcolonspace")
		set contents of text field "endat" to (localized string "endatcolonspace")
		set enabled of text field "endat" to false
		set contents of text field "total" to ""
		set filedur to 240
		tell slider "ss" to set contents to 0
		-- BIIIIIG NUMBERRRRRR
		tell slider "t" to set contents to 999999
	end tell
	set visible of box "errorbox" of tab view item "advancedinfobox" of tab view "advancedbox" of window "advanced" to false
	--if visible of window "advanced" is true and content of control "advancedtabs" of window "advanced" is 2 then
	try
		audinfo(theRow)
	end try
	--end if
	return true
end should select row
*)

on selection changed theObject
	tell tab view item "advancedoneoffbox" of tab view "advancedbox" of window "advanced"
		set enabled of button "trimonoff" to true
		set contents of button "trimonoff" to false
		set enabled of slider "ss" to false
		set enabled of slider "t" to false
		set enabled of text field "startat" to false
		set contents of text field "startat" to (localized string "startatcolonspace")
		set contents of text field "endat" to (localized string "endatcolonspace")
		set enabled of text field "endat" to false
		set contents of text field "total" to ""
		set filedur to 240
		tell slider "ss" to set contents to 0
		-- BIIIIIG NUMBERRRRRR
		tell slider "t" to set contents to 999999
	end tell
	set visible of box "errorbox" of tab view item "advancedinfobox" of tab view "advancedbox" of window "advanced" to false
	if visible of window "advanced" is true and content of control "advancedtabs" of window "advanced" is 4 then
		--try
		audinfo(null) --(selected data row of table view "table" of scroll view "table" of window "FilmRedux")
		--end try
	end if
	return true
end selection changed

on quickinfo(theItem, fullstarttime, justdur)
	set thePath to path of the main bundle as string
	set snippets to (load script (scripts path of main bundle & "/snippets.scpt" as POSIX file))
	set buttonsscript to (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
	-- prepare and clear out durfile --
	set durfile to tmpdir & "filmredux_info"
	do shell script "/bin/echo '' > " & durfile
	set AppleScript's text item delimiters to "."
	set infoext to last text item of theItem
	
	set {origformat, origduration, origbitrate, origvidtrack, origviddvdid, origvidlanguage, origvidcodec, origvidprofile, originterlacing1, originterlacing2, origwidth, origheight, origPAR, origsar, origfps, origvidbitrate, origaudtrack, origauddvdid, origaudlanguage, origaudcodec, origaudhz, origaudchannels, origaudbitrate} to {"X", 0, 0, "X", 0, "", "", "", "", "", 0, 0, 0, 0, 0, 0, "X", "", "", "", 0, 0, 0}
	
	try
		set theinfos to do shell script quoted form of thePath & "/Contents/Resources/mediainfo --Inform=file://" & quoted form of thePath & "/Contents/Resources/Example.csv " & quoted form of theItem & " > " & durfile
		set AppleScript's text item delimiters to return
		set allinfos to (do shell script "cat " & durfile)
		set thegeneral to first text item of allinfos
		try
			set AppleScript's text item delimiters to ","
			set {origjustgeneral, origformat, origduration, origbitrate} to text items of thegeneral
			set origbitrate to (origbitrate / 1000) as integer
			set origduration to (origduration / 1000) as integer
		end try
		
		if justdur is true then
			return {timeswap(origduration) of buttonsscript, origduration, allinfos}
		else
			
			set AppleScript's text item delimiters to return
			try
				set thevideo to every text item of (do shell script "cat " & durfile & " | grep 'Video-,'")
			end try
			try
				set theaudio to every text item of (do shell script "cat " & durfile & " | grep 'Audio-.'")
			end try
			
			try
				set AppleScript's text item delimiters to ","
				set {origjustvidio, origvidtrack, origviddvdid, origvidlanguage, origvidcodec, origvidprofile, originterlacing1, originterlacing2, origwidth, origheight, origPAR, origsar, origfps} to text items of item 1 of thevideo
				set origvidtrack to (origvidtrack as integer)
				set origwidth to (origwidth as integer)
				set origheight to (origheight as integer)
				if originterlacing2 is "2:3 Pulldown" then set origfps to "23.976"
				if commadecimal then
					set origsar to (switchText from origsar to "," instead of ".") as number
					set origPAR to (switchText from origPAR to "," instead of ".") as number
					set origfps to (switchText from origfps to "," instead of ".") as number
				else
					set origsar to (origsar as number)
					set origPAR to (origPAR as number)
					set origfps to (origfps as number)
				end if
				--if origpar is 0 then set origpar to 1
			end try
			
			set AppleScript's text item delimiters to return
			
			try
				set theaudios to every text item of (do shell script "cat " & durfile & " | grep 'Audio-.'")
				set AppleScript's text item delimiters to ","
				set {origjustaudio, origaudtrack, origauddvdid, origaudlanguage, origaudcodec, origaudhz, origaudchannels, origaudbitrate} to text items of item 1 of theaudios
				set origaudtrack to (origaudtrack as integer)
				set origaudchannels to (origaudchannels as integer)
				set origaudhz to (origaudhz as integer)
				set origaudbitrate to (origaudbitrate / 1000) as integer
			end try
			
			try
				set origvidbitrate to (origbitrate - origaudbitrate) as integer
			end try
			
			try
				set thesubtitles to every text item of (do shell script "cat " & durfile & " | grep 'Text-,'")
			on error
				set thesubtitles to {""}
			end try
			
		end if
	on error
		return "?"
	end try
	
	if justdur is false then
		set readyinfo to {origformat, origduration, origbitrate, origvidtrack, origviddvdid, origvidlanguage, origvidcodec, origvidprofile, originterlacing1, originterlacing2, origwidth, origheight, origPAR, origsar, origfps, origvidbitrate, origaudtrack, origauddvdid, origaudlanguage, origaudcodec, origaudhz, origaudchannels, origaudbitrate}
		return readyinfo
	end if
end quickinfo

to switchText from t to r instead of s
	set d to text item delimiters
	set text item delimiters to s
	set t to t's text items
	set text item delimiters to r
	tell t to set t to item 1 & ({""} & rest)
	set text item delimiters to d
	t
end switchText


on audinfo(whichrow)
	if visible of window "advanced" is true and content of control "advancedtabs" of window "advanced" is 4 then
		set snippets to (load script (scripts path of main bundle & "/snippets.scpt" as POSIX file))
		set buttonsscript to (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
		--set mencoder to wheremencoder(false) of snippets
		tmpgetter(true) of snippets
		if whichrow is not null then
			set thisrow to contents of data cell fullpathcell of data row whichrow of data source of table view "table" of scroll view "table" of window "FilmRedux"
		else
			try
				set thisrow to contents of data cell fullpathcell of selected data row of table view "table" of scroll view "table" of window "FilmRedux"
			on error
				set thisrow to contents of data cell fullpathcell of data row 1 of data source of table view "table" of scroll view "table" of window "FilmRedux"
			end try
		end if
		if whichrow is not null then
			set statuscell to contents of data cell statustextcell of data row whichrow of data source of table view "table" of scroll view "table" of window "FilmRedux"
		else
			try
				set statuscell to contents of data cell statustextcell of selected data row of table view "table" of scroll view "table" of window "FilmRedux"
			on error
				set statuscell to contents of data cell statustextcell of data row 1 of data source of table view "table" of scroll view "table" of window "FilmRedux"
			end try
		end if
		set {origformat, origduration, origbitrate, origvidtrack, origviddvdid, origvidlanguage, origvidcodec, origvidprofile, originterlacing1, originterlacing2, origwidth, origheight, origPAR, origsar, origfps, origvidbitrate, origaudtrack, origauddvdid, origaudlanguage, origaudcodec, origaudhz, origaudchannels, origaudbitrate} to quickinfo(thisrow, fullstarttime, false)
		tmpcleaner(false) of snippets
		set thesize to (((round ((((do shell script "ls -lan " & quoted form of thisrow & " | awk '{print $5}'") / 1024)) / 1024) * 10) / 10) as string)
		
		tell tab view item "advancedinfobox" of tab view "advancedbox" of window "advanced"
			set contents of text field "infoformat" to origformat
			set contents of text field "infolength" to (timeswap(origduration) of buttonsscript)
			set contents of text field "infosize" to thesize & "MB"
			set contents of text field "infogenbitrate" to ((origbitrate as string) & " kbps")
			
			set contents of text field "infovidcodec" to origvidcodec
			tell text field "infovidprofile"
				if origvidprofile is "" then
					set contents to "N/A"
				else
					set contents to origvidprofile
				end if
			end tell
			tell text field "infovidinterlacing"
				if originterlacing1 is not "Interlaced" and originterlacing2 is "" then
					set contents to "Progressive"
				else
					if originterlacing2 is not "" then
						set contents to originterlacing2
					else
						set contents to originterlacing1
					end if
				end if
			end tell
			set contents of text field "infovidresolution" to ((origwidth as string) & "x" & origheight as string)
			set contents of text field "infovidaspect" to origsar
			set contents of text field "infovidframerate" to origfps
			set contents of text field "infovidbitrate" to ((origvidbitrate as string) & " kbps")
			
			
			
			set contents of text field "infoaudcodec" to origaudcodec
			--set contents of text field "infobitdepth" to thebitdepth
			set contents of text field "infoaudhz" to ((origaudhz as string) & "Hz")
			set contents of text field "infoaudchan" to origaudchannels
			set contents of text field "infoaudbitrate" to ((origaudbitrate as string) & " kbps")
		end tell
		if "frerror-" is in statuscell then
			set AppleScript's text item delimiters to "frerror-"
			tell tab view item "advancedinfobox" of tab view "advancedbox" of window "advanced"
				set contents of text field "errortext" of box "errorbox" to text item 2 of statuscell
				set visible of box "errorbox" to true
			end tell
		end if
	end if
	tmpcleaner(false) of snippets
	return true
end audinfo

on tableadder(theItem, fullstarttime)
	if enabled of table view "table" of scroll view "table" of window "FilmRedux" is true then
		set thequickinfos to quickinfo(theItem, fullstarttime, true)
		if ("0:00" is in (thequickinfos as string) or "?" is in (thequickinfos as string)) and contents of default entry "addunknowns" of user defaults is false then
			--IGNORE FILE
			return true
		else
			set theDataSource to (data source of table view "table" of scroll view "table" of window "FilmRedux")
			set update views of theDataSource to false
			
			set newrow to (make new data row at end of data rows of theDataSource)
			--		set newrow to make new data row at end of data rows of theDataSource
			set contents of data cell fullpathcell of newrow to theItem as Unicode text
			-- status text
			set contents of data cell statustextcell of newrow to "frready"
			-- status blip
			set contents of data cell statusiconcell of newrow to (load image "ready")
			-- shortname
			set AppleScript's text item delimiters to "/"
			set contents of data cell shortnamecell of newrow to (last text item of theItem as Unicode text)
			-- duration check
			if "0:00" is in thequickinfos or "?" is in thequickinfos then
				set contents of data cell statusiconcell of newrow to (load image "readyunknown")
				set contents of data cell durationnumcell of newrow to 0
				set contents of data cell durationcell of newrow to "?"
			else
				set {contents of data cell durationcell of newrow, contents of data cell durationnumcell of newrow, contents of data cell infocell of newrow} to thequickinfos
			end if
			try
				do shell script "/usr/bin/killall tagreader"
			end try
			set update views of theDataSource to true
			return true
		end if
	else
		display alert (localized string "disabledtable") attached to window "FilmRedux"
		error number -128
	end if
end tableadder

on opener()
	-- ON LAUNCHED --
	tell table view "table" of scroll view "table" of window "FilmRedux"
		set contents to {""}
		tell data source 1
			set allows reordering to true
			try
				set contents to ""
			end try
		end tell
	end tell
	tell button "dragger" of window "FilmRedux" to register drag types {"file names"}
end opener

on ASCII_Sort(my_list)
	set the index_list to {}
	set the sorted_list to {}
	repeat (count of items of my_list) times
		set the low_item to ""
		repeat with i from 1 to (count of items in my_list)
			if i is not in the index_list then
				set this_item to item i of my_list as text
				if the low_item is "" then
					set the low_item to this_item
					set the low_item_index to i
				else if this_item comes before the low_item then
					set the low_item to this_item
					set the low_item_index to i
				end if
			end if
		end repeat
		set the end of sorted_list to the low_item
		set the end of the index_list to the low_item_index
	end repeat
	return the sorted_list
end ASCII_Sort

on acodecgauntlet(thecodec)
	set foundname to ""
	if thecodec is "aac" or thecodec is "mpeg4aac" or thecodec is "libfaad" then
		set foundname to "MPEG-4 Audio / AAC"
	end if
	if "pcm" is in thecodec then
		if "le" is in thecodec then
			set foundname to "Uncompressed Little Endian"
		else
			set foundname to "Uncompressed Big Endian"
		end if
	end if
	if "adpcm" is in thecodec then
		if "ima" is in thecodec then
			set foundname to "ADPCM IMA"
		else
			set foundname to "ADPCM"
		end if
	end if
	if thecodec is "alac" then
		set foundname to "Apple Lossless"
	end if
	if thecodec is "amr_nb" then
		set foundname to "AMR Narrowband"
	end if
	if thecodec is "amr_wb" then
		set foundname to "AMR Wideband"
	end if
	if thecodec is "dts" then
		set foundname to "DTS"
	end if
	if thecodec is "flac" then
		set foundname to "FLAC"
	end if
	if thecodec is "mp3" then
		set foundname to "MPEG-1 Layer 3 Audio / MP3"
	end if
	if thecodec is "mp2" then
		set foundname to "MPEG-1 Layer 2 Audio"
	end if
	if thecodec is "vorbis" then
		set foundname to "Ogg Vorbis"
	end if
	if thecodec is "ac3" then
		set foundname to "AC3"
	end if
	if thecodec is "wmav1" then
		set foundname to "Windows Media Audio 7"
	end if
	if thecodec is "wmav2" then
		set foundname to "Windows Media Audio 8/9"
	end if
	if thecodec is "midi" then
		set foundname to "MIDI"
	end if
	if foundname is "" then
		return thecodec
	else
		return foundname
	end if
end acodecgauntlet

on formatgauntlet(theformat)
	set foundname to ""
	if theformat is "3g2" or theformat is "3gp" then
		set foundname to "3GPP - Mobile"
	end if
	if theformat is "ac3" then
		set foundname to "AC3 Audio"
	end if
	if theformat is "matroska" then
		set foundname to "Matroska / MKV"
	end if
	if theformat is "mov" then
		set foundname to "QuickTime / MPEG-4"
	end if
	if theformat is "mp2" then
		set foundname to "MPEG-1 Layer 2"
	end if
	if theformat is "mp3" then
		set foundname to "MP3 Audio"
	end if
	if theformat is "mpeg" or theformat is "mpegvideo" then
		set foundname to "MPEG Program Stream"
	end if
	if theformat is "mpeg1video" then
		set foundname to "MPEG-1 Elementary Stream"
	end if
	if theformat is "mpeg2video" then
		set foundname to "MPEG-2 Elementary Stream"
	end if
	if theformat is "mpegts" then
		set foundname to "MPEG Transport Stream"
	end if
	if theformat is "nut" then
		set foundname to "Nut"
	end if
	if theformat is "ogg" or theformat is "ogm" then
		set foundname to "Ogg Media Format"
	end if
	if theformat is "rm" then
		set foundname to "Real Media"
	end if
	if theformat is "swf" then
		set foundname to "Flash Animation"
	end if
	if theformat is "wav" then
		set foundname to "WAVE"
	end if
	if theformat is "aiff" then
		set foundname to "Apple AIFF"
	end if
	if theformat is "asf" then
		set foundname to "Microsoft WMV / ASF"
	end if
	if theformat is "avi" then
		set foundname to "AVI"
	end if
	if theformat is "dv" then
		set foundname to "DV Video"
	end if
	if theformat is "dvd" then
		set foundname to "DVD VOB"
	end if
	if theformat is "flac" then
		set foundname to "FLAC"
	end if
	if theformat is "flv" then
		set foundname to "Flash Video"
	end if
	if theformat is "midi" then
		set foundname to "MIDI"
	end if
	if foundname is "" then
		return theformat
	else
		return foundname
	end if
end formatgauntlet
