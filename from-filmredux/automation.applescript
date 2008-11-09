-- automation.applescript
-- FilmRedux
global fullstarttime
global tmpdir
global ffmpeg

on comlink()
	return true
end comlink

on CheckStatus()
	tell application "FilmRedux"
		tell progress indicator "bar" of window "FilmRedux"
			set therange to (maximum value - minimum value)
			set howmuchdone to contents
		end tell
		return {((howmuchdone / therange) - 1) * -1, content of text field "timeremaining" of window "FilmRedux"}
	end tell
end CheckStatus

on AddFiles(theFiles)
	set AppleScript's text item delimiters to ""
	if (count of items of theFiles) is 1 then
		if ".DS_Store" is in (theFiles as string) then
			error number -128
		end if
	end if
	if text item 1 of (theFiles as string) is not "/" then
		-- APPLESCRIPT PATH WAY
		set readyfiles to ""
		repeat with theItem in theFiles
			if ".DS_Store" is not in (theItem as string) then
				set readyfiles to (readyfiles & ((quoted form of POSIX path of (theItem as string)) & " "))
			end if
		end repeat
	else
		-- UNIX PATH WAY
		set readyfiles to ""
		repeat with theItem in theFiles
			if ".DS_Store" is not in (theItem as string) then
				set readyfiles to (readyfiles & ((quoted form of theItem) & " "))
			end if
		end repeat
	end if
	do shell script "/usr/bin/open -b org.location.filmredux " & readyfiles & " ; exit 0"
	-- WAIT UNTIL DONE
	set howmanyrows to 0
	set thismanyrows to 1
	repeat until howmanyrows is thismanyrows
		tell application "FilmRedux" to set howmanyrows to number of data rows of data source of table view "table" of scroll view "table" of window "FilmRedux"
		delay 1.5
		tell application "FilmRedux" to set thismanyrows to number of data rows of data source of table view "table" of scroll view "table" of window "FilmRedux"
	end repeat
	return true
end AddFiles

on clearall()
	tell application "FilmRedux"
		delete every data row of data source of table view "table" of scroll view "table" of window "FilmRedux"
		
		-- EVERYTHING BELOW IS REPEATED CODE
		tell window "FilmRedux"
			set therows to count of data rows of data source of table view "table" of scroll view "table"
			tell text field "dragfiles"
				if therows > 1 then
					set contents to ((therows as string) & (localized string "...files") as Unicode text)
				end if
				if therows is 1 then
					set contents to ((therows as string) & (localized string "file") as Unicode text)
				end if
				if therows is 0 then
					set contents to (localized string "dragfiles" as Unicode text)
				end if
			end tell
			tell text field "timeremaining"
				if contents is (localized string "addandclickstarttostart") or contents is (localized string "clickstarttostart") then
					if therows is 0 then
						set contents to (localized string "addandclickstarttostart")
					else
						set contents to (localized string "clickstarttostart")
					end if
				end if
			end tell
			update
			return therows
		end tell
	end tell
end clearall

on SetSaveLocation(saveas)
	if saveas is null then
		tell application "FilmRedux" to set content of text field "saveto" of box "workflowbox" of box "box" of window "FilmRedux" to ""
	else
		set AppleScript's text item delimiters to ""
		if text item 1 of (saveas as string) is "/" then
			set saveasposix to (saveas as Unicode text)
		else
			set saveasposix to POSIX path of (saveas as Unicode text)
		end if
		tell application "FilmRedux"
			set content of text field "saveto" of box "workflowbox" of box "box" of window "FilmRedux" to saveasposix
			update window "FilmRedux"
		end tell
	end if
end SetSaveLocation

on StartConversion()
	--set stupidhack to (do shell script "echo $RANDOM | /usr/bin/cut -c 1-3")
	tell application "FilmRedux"
		--	doitmulti("auto") of (load script (scripts path of main bundle & "/main.scpt" as POSIX file))
		if contents of text field "supper" of window "FilmRedux" is "" then
			set contents of text field "supper" of window "FilmRedux" to "auto"
		end if
		set whatstatus to contents of text field "timeremaining" of window "FilmRedux"
		if whatstatus is in {(localized string "addandclickstarttostart"), (localized string "clickstarttostart"), ""} then
			call method "performClick:" of object (button "start" of window "FilmRedux")
		end if
		--		with timeout of 35000000 seconds
		--			set size of text field "supper" of window "FilmRedux" to {stupidhack, 1}
		--		end timeout
	end tell
end StartConversion

on StartAssemblyLine()
	--	set stupidhack to (do shell script "echo $RANDOM | /usr/bin/cut -c 1-3")
	tell application "FilmRedux"
		if contents of text field "timeremaining" of window "FilmRedux" is in {(localized string "addandclickstarttostart"), (localized string "clickstarttostart"), ""} then
			--	doitmulti("auto") of (load script (scripts path of main bundle & "/main.scpt" as POSIX file))
			set whatstatus to contents of text field "timeremaining" of window "FilmRedux"
			if whatstatus is in {(localized string "addandclickstarttostart"), (localized string "clickstarttostart"), ""} then
				set contents of text field "wanter" of window "FilmRedux" to "assembly"
				do shell script "/usr/bin/osascript -e 'tell application \"FilmRedux\" to call method \"performClick:\" of object (button \"start\" of window \"FilmRedux\")' &> /dev/null & "
			end if
			--		with timeout of 35000000 seconds
			--			set size of text field "supper" of window "FilmRedux" to {stupidhack, 1}
			--		end timeout
		end if
	end tell
end StartAssemblyLine

on loadsettings(theFile)
	set AppleScript's text item delimiters to ""
	if text item 1 of (theFile as string) is "/" then
		do shell script "/usr/bin/open -b org.location.filmredux " & (quoted form of theFile)
	else
		do shell script "/usr/bin/open -b org.location.filmredux " & (quoted form of POSIX path of theFile)
	end if
end loadsettings

on QuitApp()
	tell application "FilmRedux" to quit
end QuitApp

on ForceQuit()
	tell application "FilmRedux" to quit saving no
end ForceQuit

on SetWhenDone(theoption)
	try
		set theoption to (theoption as number)
		if theoption < 5 then
			set contents of popup button "postaction" of box "workflowbox" of box "box" of window "FilmRedux" to (theoption - 1)
		end if
	on error
		--then it must be a script path.
		set AppleScript's text item delimiters to ""
		if text item 1 of (theoption as string) is "/" then
			set whichscript to (theoption as Unicode text)
		else
			set whichscript to POSIX path of (theoption as Unicode text)
		end if
		tell application "FilmRedux"
			set contents of text field "runscript" of window "FilmRedux" to POSIX path of whichscript
			set contents of popup button "postaction" of box "workflowbox" of box "box" of window "FilmRedux" to 5
			update window "FilmRedux"
		end tell
	end try
end SetWhenDone

(*
on TurnXgridOn(saveas)
	tell application "FilmRedux"
		set content of button "Xgrid" of window "FilmRedux" to true
		try
			set AppleScript's text item delimiters to ""
			if text item 1 of (saveas as string) is "/" then
				set saveasposix to (saveas as Unicode text)
			else
				set saveasposix to POSIX path of saveas
			end if
			tell application "FilmRedux" to set content of text field "path" of window "FilmRedux" to saveasposix as Unicode text
		on error
			error "Save Path must be specified. Example: XgridOn(\"/moviestore/conversions/\")"
		end try
	end tell
end TurnXgridOn

on TurnXgridOff()
	tell application "FilmRedux" to set content of button "Xgrid" of window "FilmRedux" to false
end TurnXgridOff
*)

on TurnOnStitch(filename)
	tell application "FilmRedux"
		tell window "FilmRedux"
			if enabled of button "stitch" of box "workflowbox" of box "box" is true then
				set contents of text field "supper" to filename
				set contents of button "stitch" of box "workflowbox" of box "box" to true
			end if
		end tell
	end tell
end TurnOnStitch
--  Created by Tyler Loch on 12/3/07.
--  Copyright 2007 __MyCompanyName__. All rights reserved.
