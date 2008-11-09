-- FilmRedux.applescript
-- FilmRedux

property alldevices : 1
property ipod5g : 2
property ipodclassic : 3
property ipodnano : 4
property iphone : 5
property ipodtouch : 6
property appletv : 7
property dv : 10
property dvd : 11
property tivo2 : 12
property tivo3 : 13
property threeg : 14
property xbox : 17
property psp : 18
property ps3 : 19
property wii : 20
property avi : 23
property mp4 : 24
property mov : 25
property wmv : 26
property flash : 27
property mpeg : 28



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

global thePath
global thequotedapppath
global fullstarttime
global mencoder
global sysver
global stitchedfile
global quotedstitchedfile
global stitch
global stitchstack
global donestack
global filetoconvert
global theFilepath
global theFile
global thePath
global ext
global extsize
global filenoext
global quotedfile
global quotedpath
global quotedorigpath
global custompath
global quotedcustompath
global destpath
global backslash
global isauto
global theDataSource
global durfile
global buttonsscript
global theformat
global thedur
global thesize
global thecodec
global thebitdepth
global thehz
global thechan
global thebitrate
global thetitle
global theartist
global thealbum
global theyear
global thecomment
global thetrack
global thegenre
global snippets
global audbitforce
global audbitset
global hzforce
global chanforce
global hzset
global bitset
global chanset
global skipsec
global forcedur
global audiotrack
global forcetitle
global forceartist
global forcealbum
global forcetrack
global forceyear
global forcegenre
global forcecomment
global rawtitle
global rawartist
global rawalbum
global rawtrack
global rawyear
global rawgenre
global rawcomment
global ffaudios
global vol
global normalize
global toformat
global pipe
global quotedoutputfile
global outputfile
global mencoderstring
global tmpdir
global endline
global preview
global starttime
global howmanydone
global howmany
global thedurnum
global whichone
global isqt
global pipe
global pipeprep
global setyear
global setartist
global settitle
global setcomment
global settrack
global setgenre
global setalbum
global donefile
global quoteddonefile
global fileext
global exportfile
global theRow
global fulldur
global sofardur
global isassembly
global tailpid
global stitchdestpath
global quotedstitchdestpath
global finishstitch
global errors
global dowhendone
global whichwhendone
global appsup
global burnspeed
global pregap
global drive
global mp3ok
global hasgrowl
global icondone
global isflac
global isvlc
global thelogfile
global ismidi
global iscd
global cdtracknum

global whichpart

global origformat
global origdur
global origsize
global origcodec
global origbitdepth
global orighz
global origchan
global origbitrate
global origtitle
global origartist
global origalbum
global origyear
global origcomment
global origtrack
global origgenre

global finalbit
global finalhz
global finalchan

global nice

global otherextras

global whichsound
global batchstarttime
global batchtmpdir
global howlonglessthan
global thepercent
global iconsofar
global workingdone
global donedur
global whichstarttime
global updatefrequency
global remainingforfileorbatch
global randombit
global statusrow
global whichformat
global statusfile
global thisdur
global finalbitdepth
global multiconv

global origformat
global origduration
global origbitrate
global origvidtrack
global origviddvdid
global origvidlanguage
global origvidcodec
global origvidprofile
global originterlacing1
global originterlacing2
global origwidth
global origheight
global origPAR
global origsar
global origfps
global origvidbitrate
global origaudtrack
global origauddvdid
global origaudlanguage
global origaudcodec
global origaudhz
global origaudchannels
global origaudbitrate
global theformat
global theduration
global thebitrate
global thevidtrack
global theviddvdid
global thevidlanguage
global thevidcodec
global thevidprofile
global theinterlacing
global thewidth
global theheight
global thepar
global thesar
global thefps
global thevidbitrate
global theaudtrack
global theauddvdid
global theaudlanguage
global theaudcodec
global theaudhz
global theaudchannels
global theaudbitrate

global vfilters1
global vfilters2

global extras
global vcodec
global encopts
global vfilters
global afilters
global extraflags
global playgroundflags
global oformat
global ofps

global finalaudbitrate
global finalaudhz
global finalaudchannels

global runfps
global allfps
global fpshalf
global afaudios
global substring

global thismencoder
global conversionid

global twopass

global externalaudio

global extras

on whichconv()
	if isassembly is true then
		return false
	else
		set thestatuses to ((contents of data cell statustextcell of every data row of data source of table view "table" of scroll view "table" of window "FilmRedux") as string)
		if "frready" is in thestatuses or "frworking" is in thestatuses then
			return false
		else
			return true
		end if
	end if
end whichconv

on readygo(auto)
	tell window "FilmRedux"
		if contents of text field "wanter" is "assembly" then
			set content of button "stitch" of box "workflowbox" of box "box" to false
			set isassembly to true
		else
			set isassembly to false
		end if
		set visible of button "start" to false
		set visible of button "cancel" to true
		set visible of button "pause" to true
		update window
	end tell
	set isauto to auto
	startrun()
	
	--	repeat until "frready" is not in (contents of data cell statustextcell of every data row of theDataSource)
	-- HERE WE GO --
	
	set updatefrequency to (2 / (contents of default entry "updatefrequency" of user defaults))
	
	set multiconv to (contents of default entry "multiconv" of user defaults)
	if multiconv is 0 then
		set multiconv to ((do shell script "/usr/sbin/sysctl -n hw.availcpu") as integer)
	end if
	
	set doinghowmany to 0
	repeat until whichconv() is true
		-- CAN WE DO ANOTHER?
		set dowait to true
		if doinghowmany is less than multiconv and ((count of (every data row of theDataSource whose contents of data cell statustextcell is "frready")) > 0 or isassembly) then
			set dowait to false
			-- FIND THE FIRST ROW THAT'S NOT DONE --
			-- If assembly line, wait for it. --
			try
				--tiger acts differently and needs this
				if contents of data cell statustextcell of (first data row of theDataSource whose contents of data cell statustextcell is "frready") as string is "" then
					error
				end if
				set contents of data cell statustextcell of (first data row of theDataSource whose contents of data cell statustextcell is "frready") to "frworking"
			on error
				if isassembly then
					tell progress indicator "bar" of window "FilmRedux"
						set indeterminate to true
						start
					end tell
					if howmany is 0 then
						set contents of text field "timeremaining" of window "FilmRedux" to (localized string "waitingforfiles")
					else
						set contents of text field "timeremaining" of window "FilmRedux" to (localized string "waitingformorefiles")
					end if
					repeat until "frready" is in ((contents of data cell statustextcell of every data row of data source of table view "table" of scroll view "table" of window "FilmRedux") as string)
						iscancelled()
						try
							statuscheck()
						end try
						if "frworking" is not in ((contents of data cell statustextcell of every data row of data source of table view "table" of scroll view "table" of window "FilmRedux") as string) and howmany > 0 then
							set contents of text field "timeremaining" of window "FilmRedux" to (localized string "waitingformorefiles")
						end if
						delay 1
					end repeat
					--set indeterminate of progress indicator "bar" of window "FilmRedux" to false
					set contents of data cell statustextcell of (first data row of theDataSource whose contents of data cell statustextcell is "frready") to "frworking"
				end if
			end try
			
			pervars()
			
			update window "FilmRedux"
			set whichrow to 1
			repeat until 1 is not 1
				if contents of data cell statustextcell of data row whichrow of theDataSource is "frworking" then
					set whichone to whichrow
					exit repeat
				else
					set whichrow to (whichrow + 1)
				end if
			end repeat
			set theRow to data row whichone of theDataSource
			
			--**GETTING IMPORTANT INFO**--
			if stitch is false then
				set toformat to contents of popup button "formats" of box "box" of window "FilmRedux"
			else
				set enabled of table view "table" of scroll view "table" of window "FilmRedux" to false
				set toformat to wav
			end if
			
			if stitch is true then
				set the content of text field "filenum" of window "FilmRedux" to (localized string "stepspace") & 1 & (localized string "spaceofspace") & 2
				--	else
				--	set the content of text field "filenum" of window "FilmRedux" to (localized string "filespace") & whichone & (localized string "spaceofspace") & howmany
			end if
			-- HEY, IT'S CONVERTING NOW --
			--set the content of text field "timeremaining" of window "FilmRedux" to (localized string "startingfile") & whichone & "..."
			set contents of data cell statusiconcell of theRow to (load image "converting")
			set contents of data cell statustextcell of theRow to "frworking0"
			
			tmpgetter(false) of snippets
			set contents of data cell starttimecell of theRow to fullstarttime & randombit
			do shell script "/usr/bin/touch " & tmpdir & "filmredux_time"
			do shell script "/usr/bin/touch " & batchtmpdir & "filmredux_time"
			set endline to " >> " & tmpdir & "filmredux_time 2>&1 " & " ; echo done > " & tmpdir & "filmredux_working"
			
			pathings(contents of data cell fullpathcell of theRow) of snippets
			set contents of data cell outputfilecell of theRow to outputfile
			
			set quickinforesult to quickinfo((contents of data cell fullpathcell of theRow), fullstarttime, false) of (load script (scripts path of main bundle & "/table.scpt" as POSIX file))
			if quickinforesult is "DRM" or quickinforesult is "?" then
				isbroken()
			else
				set {origformat, origduration, origbitrate, origvidtrack, origviddvdid, origvidlanguage, origvidcodec, origvidprofile, originterlacing1, originterlacing2, origwidth, origheight, origPAR, origsar, origfps, origvidbitrate, origaudtrack, origauddvdid, origaudlanguage, origaudcodec, origaudhz, origaudchannels, origaudbitrate} to quickinforesult
				set thedurnum to origduration
				
				-- WRITE FILE INFO TO LOG FILE
				do shell script "/bin/cat " & durfile & " >> " & tmpdir & "filmredux_time"
				
				quicktimedetect() of snippets
				
				convertfile()
				-- NEXT!
			end if
		end if
		
		
		
		
		
		
		
		statuscheck()
		
		if dowait then delay updatefrequency
		
		
		
		
		
		
		
		
		set doinghowmany to count of (data rows of theDataSource where "frworking" is in contents of data cell statustextcell)
	end repeat
	
	--DO THE STITCH!
	if stitch is true then
		set stitch to false
		set finishstitch to true
		set howmanydone to 0
		cleartags() of snippets
		set {thetitle, theartist, thealbum, thetrack, theyear, thegenre, thecomment} to {"", "", "", "", "", "", ""}
		--	set maximum value of progress indicator "bar" of window "FilmRedux" to howmany
		--	set howmany to 1
		
		--IS THIS RIGHT?
		set howmany to 1
		set howmanydone to 0
		set maximum value of progress indicator "bar" of window "FilmRedux" to 1
		-- ^^ THIS STUFF
		
		set contents of progress indicator "bar" of window "FilmRedux" to 0
		set indeterminate of progress indicator "bar" of window "FilmRedux" to true
		set the content of text field "filenum" of window "FilmRedux" to (localized string "stepspace") & 2 & (localized string "spaceofspace") & 2
		set isqt to false
		set alldurs to contents of data cell durationnumcell of every data row of theDataSource
		set fulldur to calcbigdur(alldurs) of snippets
		set tmpdir to batchtmpdir
		set thedurnum to fulldur
		set sofardur to 0
		set pipeprep to " -f s16le -ac 2 -ar 48000 "
		set stitchlist to ""
		set alltmps to (contents of data cell starttimecell of (every data row of theDataSource where contents of data cell statustextcell is "done"))
		repeat with thistmp in alltmps
			set stitchlist to (stitchlist & " " & tmpdir & "/" & thistmp & "/stitchfile.pcm ")
		end repeat
		set pipe to "/bin/cat " & stitchlist & " | "
		set filetoconvert to "-"
		--		pathings(tmpdir & "stitchfile.pcm") of snippets
		set toformat to contents of popup button "formats" of box "box" of window "FilmRedux"
		do shell script "echo notdone > " & tmpdir & "filmredux_working"
		set isdone to do shell script "/bin/cat " & tmpdir & "filmredux_working"
		set endline to " 2>> " & tmpdir & "filmredux_time " & " ; echo done > " & tmpdir & "filmredux_working"
		set thehz to 48000
		set thechan to 2
		set whichpart to "frworking0"
		set outputfile to stitchdestpath & stitchedfile
		set quotedoutputfile to quoted form of outputfile
		set update views of theDataSource to false
		set theRow to (make new data row at end of data rows of theDataSource)
		set contents of data cell fullpathcell of theRow to "frstitch"
		set contents of data cell statustextcell of theRow to whichpart
		set contents of data cell statusiconcell of theRow to (load image "converting")
		set contents of data cell shortnamecell of theRow to stitchedfile
		set contents of data cell durationnumcell of theRow to fulldur
		set contents of data cell durationcell of theRow to timeswap(fulldur) of buttonsscript
		set update views of theDataSource to true
		convertfile()
		repeat until whichconv() is true
			statuscheck()
			delay updatefrequency
			--set isdone to do shell script "/bin/cat " & tmpdir & "filmredux_working"
		end repeat
		--	try
		--		do shell script "/bin/rm " & tmpdir & "stitchfile.pcm"
		--	end try
	end if
	
	
	stoprun()
	
	-- FIGURE OUT HOW MANY ERRORS
	set thestatuscells to (contents of data cell statustextcell of every data row of theDataSource)
	set errors to 0
	repeat with thecell in thestatuscells
		if "frerror-" is in thecell then
			set errors to (errors + 1)
		end if
	end repeat
	
	--ALL DONE
	if errors is not howmany then
		if contents of default entry "playsound" of user defaults is true then
			play (load sound "Glass")
		end if
	end if
	
	--	update window "FilmRedux"
	--	try
	--		call method "deminiaturize:" of window "FilmRedux"
	--	end try
	--	
	--	display dialog "uhhh"
	--	delay 1
	
	
	--	-- PREPARE FOR WHENDONES -- NOW DONE IN PERVARS
	--	tell box "workflowbox" of box "box" of window "FilmRedux"
	--		set dowhendone to contents of button "postactiononoff"
	--		set whichwhendone to contents of popup button "postaction"
	--	end tell
	
	endrun()
	
end readygo

on endrun()
	writelog() of snippets
	
	tell window "wannabox"
		set title of button "wannayes" to (localized string "ok")
		set title of button "wannano" to (localized string "showlog")
		set contents of text field "wannawhat" to "done"
	end tell
	if errors > 0 then
		if errors = howmany then
			--display dialog (localized string "allerrors")
			----		set whichbutton to button returned of (display alert (localized string "allerrorstitle") message (localized string "allerrorstext") as warning default button (localized string "ok") other button (localized string "showlog"))
			tell window "wannabox"
				set contents of text field "wannado" to (localized string "allerrorstitle")
				set contents of text field "wannadotext" to (localized string "allerrorstext")
			end tell
		else
			tell window "wannabox"
				set contents of text field "wannadotext" to (localized string "someerrorstext")
				if errors is 999 then
					set contents of text field "wannado" to (localized string "allerrorstitle")
					----				set whichbutton to button returned of (display alert (localized string "errorsendedbatch") message (localized string "someerrorstext") as warning default button (localized string "ok") other button (localized string "showlog"))
				else
					set contents of text field "wannado" to (localized string "someerrorstitle")
					----				set whichbutton to button returned of (display alert (localized string "someerrorstitle") message (localized string "someerrorstext") as warning default button (localized string "ok") other button (localized string "showlog"))
				end if
			end tell
		end if
		if hasgrowl then
			set growltitle to (localized string "conversioncomplete")
			set growlstring to (localized string "someerrorstitle")
			completenotify("Conversion Complete", growltitle, growlstring) of (load script (scripts path of main bundle & "/growl.scpt" as POSIX file))
		end if
	else
		set extratext to ""
		-- SET TRIAL AND ELAPSEDS
		if isauto is false then
			try
				set nowtime to do shell script "/bin/date +%s"
				set elapsednum to (nowtime - batchstarttime) as integer
				set extratext to (extratext & (localized string "elapsedtimecolonspace") & timeswap(elapsednum) of buttonsscript)
			end try
			if hasgrowl then
				set growltitle to (localized string "conversioncomplete")
				completenotify("Conversion Complete", growltitle, extratext) of (load script (scripts path of main bundle & "/growl.scpt" as POSIX file))
			end if
			tell window "wannabox"
				set contents of text field "wannado" to (localized string "conversioncomplete")
				set contents of text field "wannadotext" to extratext
			end tell
		end if
	end if
	
	update window "wannabox"
	update window "FilmRedux"
	
	if ((call method "isMiniaturized" of window "FilmRedux") as boolean) then
		call method "deminiaturize:" of window "FilmRedux"
		delay 2
		update window "FilmRedux"
	end if
	if (dowhendone is false or errors > 0) and isauto is false then
		display panel window "wannabox" attached to window "FilmRedux"
		update window "FilmRedux"
		
		repeat until contents of text field "wannawhat" of window "wannabox" is not "done"
			delay 0.5
			--update window "FilmRedux"
		end repeat
		--			if whichbutton is (localized string "buyfilmredux") then
		
		--	if whichbutton is (localized string "showlog") then
		if contents of text field "wannawhat" of window "wannabox" is "log" then
			try
				do shell script "/usr/bin/open -t " & thelogfile
			end try
		end if
	end if
	
	-- WHEN DONES
	if dowhendone is true then
		-- NOW DONE AFTER FILECONVERSION
		--		if whichwhendone is 0 then
		--			try
		--				set itunesfile to (do shell script "echo " & donefile) as POSIX file
		--				tell application "Terminal" to do script "/usr/bin/osascript -e 'tell application \"iTunes\" to add \"" & donefile & "\"'"
		--			end try
		--		end if
		if whichwhendone is 1 then
			do shell script "/usr/bin/open " & destpath
		end if
		if whichwhendone is 2 then
			tell application "System Events" to sleep
		end if
		if whichwhendone is 3 then
			tell application "System Events" to shut down
		end if
		if whichwhendone is 4 then
			quit
			return true
		end if
		if whichwhendone is 6 then
			tell window "FilmRedux"
				set contents of text field "timeremaining" to (localized string "runningscript")
				set runthisscript to contents of text field "runscript" as POSIX file
			end tell
			set originalfiles to {}
			set originalfileswork to contents of data cell fullpathcell of every data row of theDataSource
			repeat with thisfile in originalfileswork
				set originalfiles to (originalfiles & (thisfile as POSIX file))
			end repeat
			with timeout of 35000000 seconds
				runscript(originalfiles, donestack) of (load script runthisscript)
			end timeout
		end if
	end if
	
	
	--CLEAN UP
	try
		do shell script "/bin/rm -r " & tmpdir
	end try
	
	if isauto is true then
		set textdonestack to ""
		repeat with thisdone in donestack
			set textdonestack to (textdonestack & thisdone & return)
		end repeat
		set contents of text field "supper" of window "FilmRedux" to textdonestack
	else
		set contents of text field "supper" of window "FilmRedux" to ""
	end if
end endrun

on makedate(thedate)
	return ("'" & (month of thedate as number) & "/" & (day of thedate as string) & "/" & (year of thedate as string) & " " & (hours of thedate as string) & ":" & (minutes of thedate as string) & ":" & (seconds of thedate as string) & "'") as string
end makedate

on normalgo()
	--Not done yet....
	do shell script "echo notdone > " & tmpdir & "filmredux_working"
	
	--	if stitch is true then
	--		set endline to " > " & tmpdir & "stitchfile.pcm 2>> " & tmpdir & "filmredux_time " & " ; echo done > " & tmpdir & "filmredux_working"
	--	end if
	set scriptline to (mencoderstring & endline)
	set scriptfile to POSIX file (tmpdir & "filmreduxcommand.sh")
	
	if "\"" is in scriptline or "$" is in scriptline then
		open for access scriptfile with write permission
		write (mencoderstring & endline) to scriptfile starting at 0
		close access scriptfile
	else
		do shell script "echo \"" & scriptline & "\" > " & quoted form of POSIX path of scriptfile
	end if
	
	
	do shell script "/bin/cat " & quoted form of POSIX path of scriptfile & " >> " & tmpdir & "filmredux_time"
	do shell script "cd /tmp ; /bin/chmod 755 " & quoted form of POSIX path of scriptfile & " ; " & nice & " " & quoted form of POSIX path of scriptfile & " &> /dev/null &"
	
	--Get a truncated epoch dating for the filestart for progress barification.
	set starttime to (do shell script "/bin/date +%s") as number
	delay 0.25
	--	if finishstitch is false then
	--set contents of data cell pidcell of theRow to pid
	--	end if
	
	delay 1
	set isdone to do shell script "/bin/cat " & tmpdir & "filmredux_working"
	if isdone is "done" then
		if "stream:" is not in (do shell script " /usr/bin/tail -n 40 " & tmpdir & "filmredux_time") then
			isbroken()
			return false
		else
			return true
		end if
	else
		return true
	end if
	
end normalgo

on convertfile()
	set conversionid to fullstarttime & randombit
	set thismencoder to tmpdir & "mencoder" & conversionid
	do shell script "/bin/ln -s " & mencoder & " " & thismencoder
	
	advanceds() of snippets
	
	(*
	-- NORMALIZE
	if normalize is true then
		--		set content of text field "timeremaining" of window "FilmRedux" to (localized string "normalizingfile") & whichone & "..."
		update window "FilmRedux"
		set normalizefile to (tmpdir & "normalize.wav")
		do shell script pipe & mencoder & pipeprep & " -y -i " & filetoconvert & audiotrack & " -vn " & normalizefile & " > /dev/null 2> /dev/null"
		do shell script thequotedapppath & "/Contents/Resources/normalize " & normalizefile & " > /dev/null 2>> " & tmpdir & "filmredux_time ; exit 0"
		set filetoconvert to normalizefile
		set pipe to ""
		set pipeprep to " "
		set audiotrack to " "
	end if
	*)
	
	--** PUT CONDITIONALS HERE **--
	if toformat is in {alldevices, ipod5g, ipodclassic, ipodnano, iphone, ipodtouch, appletv} then
		set whichformat to (load script (scripts path of main bundle & "/ipod.scpt" as POSIX file))
		formatstart(toformat) of whichformat
	end if
	set contents of data cell exportfilecell of theRow to exportfile
	set contents of data cell outputfilecell of theRow to outputfile
	
	--**HERE WE GO!**--
	set howgo to normalgo()
	
	--Wait to see if something went wrong
	if howgo is false then
		-- PUT KILLSWITCH HERE FOR BATCHING
		if contents of default entry "batcherrorcancel" of user defaults is true and (stitch is true or toformat is in {dvd}) then
			set errors to 999
			set dowhendone to false
			stoprun()
			endrun()
			error number -128
		end if
	end if
end convertfile

on dones(thisrow)
	-- PREPARE FOR WHENDONES
	tell box "workflowbox" of box "box" of window "FilmRedux"
		set dowhendone to contents of button "postactiononoff"
		set whichwhendone to contents of popup button "postaction"
	end tell
	
	--if mp3ok is false then
	-- FILE'S DONE! --
	
	set fullpath to contents of data cell fullpathcell of thisrow
	set thisstarttime to contents of data cell starttimecell of thisrow
	set contents of data cell pidcell of thisrow to ""
	--GET TAG INFO
	--		set taginforesult to quickinfo(fullpath, thisstarttime, false) of (load script (scripts path of main bundle & "/table.scpt" as POSIX file))
	--		set {theformat, thedur, thesize, thecodec, thebitdepth, thehz, thechan, thebitrate, thetitle, theartist, thealbum, theyear, thecomment, thetrack, thegenre} to taginforesult
	--		set {origformat, origdur, origsize, origcodec, origbitdepth, orighz, origchan, origbitrate, origtitle, origartist, origalbum, origyear, origcomment, origtrack, origgenre} to taginforesult
	
	
	normaldone() of whichformat
	-- Add finished file to stitchstacks
	try
		set stitchstack to (stitchstack & donefile)
		set fixeddonefile to POSIX file donefile
		set donestack to (donestack & fixeddonefile)
	end try
	--	end if
	
	if finishstitch is false then
		do shell script "/bin/cat " & tmpdir & "filmredux_time >> " & batchtmpdir & "filmredux_time"
	end if
	
	if stitch is false then
		
		-- SET CREATION AND MODIFICATION DATES IF WANTED
		try
			set moddate to contents of default entry "moddate" of user defaults
			set creationdate to contents of default entry "creationdate" of user defaults
			if moddate is true or creationdate is true then
				set origdatefile to (fullpath as POSIX file) as alias
				tell application "System Events"
					set filecreationdate to creation date of origdatefile
					set filemoddate to modification date of origdatefile
				end tell
				if moddate is true then
					do shell script quoted form of (resource path of the main bundle & "/SetFile") & " -m " & makedate(filemoddate) & " " & quoted form of donefile
				end if
				if creationdate is true then
					do shell script quoted form of (resource path of the main bundle & "/SetFile") & " -d " & makedate(filecreationdate) & " " & quoted form of donefile
				end if
			end if
		end try
		if dowhendone is true then
			if whichwhendone is 0 then
				--TWO WAYS TO DO ITUNES IMPORT. EACH SUCKS.
				try
					set itunesfile to donefile as POSIX file
				end try
				
				--try
				--						do shell script "/usr/bin/osascript -e 'tell application \"iTunes\" to add \"" & itunesfile & "\"' &> /dev/null &"
				itunesadd(itunesfile) of (load script (scripts path of main bundle & "/itunes.scpt" as POSIX file))
				--end try
				set dowhendone to false
			end if
		end if
	end if
	
	if hasgrowl then
		set growltitle to (localized string "filecomplete")
		set filenoext to (call method "stringByDeletingPathExtension" of (call method "lastPathComponent" of donefile))
		completenotify("File Complete", growltitle, filenoext) of (load script (scripts path of main bundle & "/growl.scpt" as POSIX file))
	end if
	
end dones

on isbroken()
	set contents of data cell statusiconcell of theRow to (load image "error")
	set contents of data cell statustextcell of theRow to ("frerror-" & (do shell script "/usr/bin/tail -n 4 " & tmpdir & "filmredux_time | /usr/bin/head -2"))
	--	do shell script "/usr/bin/open -t " & tmpdir & "filmredux_time"
end isbroken

on percenter(tmpdir)
	-- Not needed? 
	(*  	set startpercenter to ("/usr/bin/tail -c 1000 " & tmpdir & "filmredux_time | /usr/bin/strings | /usr/bin/grep 'time=' | /usr/bin/tail -n 1 | /usr/bin/awk -F 'time=' '{print $2}' | /usr/bin/awk -F . '{print $1}'")
	if commadecimal() of snippets is true then
		set endpercenter to " | /usr/bin/sed -e 's/" & backslash & "./,/g'"
	else
		set endpercenter to ""
	end if
	set getdone to (do shell script (startpercenter & endpercenter)) as number  *)
	
	(*	if whichpart is "frworking2" then
		--ADD AFCONVERT HERE
		set bytespersec to ((finalbit / 8) * 1024) as integer
		set bytessofar to (do shell script "/bin/ls -ln " & statusfile & " | /usr/bin/awk '{print $5}'") as number
		set startpercenter to (bytessofar / bytespersec) as integer
	else if "frworking1" is in whichpart then
		set startpercenter to 0
	else *)
	set startpercenter to (do shell script ("/usr/bin/tail -c 2048 " & tmpdir & "filmredux_time | /usr/bin/strings | /usr/bin/grep 'Pos:' | /usr/bin/tail -n 1 | /usr/bin/awk -F 'Pos:' '{print $2}' | /usr/bin/awk -F . '{print $1}'")) as number
	try
		set runfps to (do shell script ("/usr/bin/tail -c 2048 " & tmpdir & "filmredux_time | /usr/bin/strings | /usr/bin/grep 'Pos:' | /usr/bin/tail -n 1 | /usr/bin/awk '{print $5}' | /usr/bin/awk -F . '{print $1}'")) as number
	on error
		set runfps to 0
	end try
	--	end if
	
	--	if contents of default entry "fulldur" of user defaults is true and isassembly is false then
	set restofdur to fulldur
	--	else
	--		set donedur to 0
	--		set restofdur to thedurnum
	--	end if
	set thepercent to ((startpercenter + sofardur) / (restofdur))
	set thesinglepercent to (startpercenter / thisdur)
	return {thepercent, thesinglepercent, startpercenter, runfps}
end percenter

on statuscheck()
	
	--Everything seems to be working...That's amazing!
	iscancelled()
	
	
	--	set isdone to (do shell script "/bin/cat " & tmpdir & "filmredux_working")
	--hidin' spinnaz
	
	--if whichpart is 1 then
	--	set indeterminate of progress indicator "bar" of window "FilmRedux" to true
	--	set content of text field "timeremaining" of window "FilmRedux" to (localized string "preparingfile") & whichone & "..."
	--	set remainingforfileorbatch to (localized string "preparingfile") & whichone & "..."
	--	if contents of default entry "fulldur" of user defaults is true and isassembly is false then
	--		set whichstarttime to batchstarttime
	--	else
	--		set whichstarttime to starttime
	--	end if
	--	else
	
	-- WHAT ABOUT ASSEMBLY LINE?
	if isassembly is false then
		set remainingforfileorbatch to ((localized string "remainingforthebatch"))
		set whichstarttime to batchstarttime
	else
		set remainingforfileorbatch to (localized string "convertingfiles")
		set whichstarttime to batchstarttime
	end if
	if finishstitch is true then
		set remainingforfileorbatch to (localized string "remainingforstitching")
		set whichstarttime to starttime
	end if
	--	end if
	--	
	
	--GET PERCENTS
	set workingdone to 1.0E-3
	set startpercenter to 1.0E-3
	--set thesinglepercent to 1.0E-3
	
	
	
	set allfps to 0
	repeat with statusrow in (data rows of theDataSource where "frworking" is in contents of data cell statustextcell)
		--	try
		--	display dialog 7
		--	display dialog (contents of data cell shortnamecell of statusrow) as string
		set whichpart to contents of data cell statustextcell of statusrow
		set iconsofar to "sofar0"
		--	display dialog 8
		
		if finishstitch is false then
			set tmpdir to batchtmpdir & contents of data cell starttimecell of statusrow & "/"
		else
			set tmpdir to batchtmpdir
		end if
		
		if whichpart is "frworking2" then
			set statusfile to quoted form of ((contents of data cell exportfilecell of statusrow) as string)
			set donefile to contents of data cell exportfilecell of statusrow
		else
			set statusfile to contents of data cell exportfilecell of statusrow
		end if
		--	if whichpart is "frworking2" then
		--		set statusfile to quoted form of contents of data cell exportfilecell of statusrow
		--	else
		--		set statusfile to "/tmp/frtemp/" & batchstarttime & "/"
		--	end if
		--end if
		
		
		--	if stitch is false then
		set thisdur to contents of data cell durationnumcell of statusrow
		--	end if
		
		set isdone to do shell script "/bin/cat " & tmpdir & "filmredux_working"
		if isdone is not "done" then
			try
				if twopass then
					if (do shell script "/bin/cat " & tmpdir & "filmredux_pass") is "2" then
						set passmultiplier to thisdur
					else
						set passmultiplier to 0
					end if
				else
					set passmultiplier to 0
				end if
				
				set {thepercent, thesinglepercent, startpercenter, runfps} to percenter(tmpdir)
				set workingdone to (workingdone + startpercenter + passmultiplier)
				if whichpart is in {"frworking0", "frworking2"} then
					if thesinglepercent > 0.9 then
						--		if iconsofar is not in {"sofar9"} then
						set iconsofar to "sofar9"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.8 then
						--		if iconsofar is not in {"sofar8", "sofar9"} then
						set iconsofar to "sofar8"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.7 then
						--		if iconsofar is not in {"sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar7"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.6 then
						--		if iconsofar is not in {"sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar6"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.5 then
						--		if iconsofar is not in {"sofar5", "sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar5"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.4 then
						--		if iconsofar is not in {"sofar4", "sofar5", "sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar4"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.3 then
						--		if iconsofar is not in {"sofar3", "sofar4", "sofar5", "sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar3"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent > 0.2 then
						--		if iconsofar is not in {"sofar2", "sofar3", "sofar4", "sofar5", "sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar2"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent is greater than or equal to 0.1 then
						--		if iconsofar is not in {"sofar1", "sofar2", "sofar3", "sofar4", "sofar5", "sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar1"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					else if thesinglepercent < 0.1 then
						--		if iconsofar is not in {"sofar0", "sofar1", "sofar2", "sofar3", "sofar4", "sofar5", "sofar6", "sofar7", "sofar8", "sofar9"} then
						set iconsofar to "sofar0"
						set contents of data cell statusiconcell of statusrow to (load image iconsofar)
						--		end if
					end if
				end if
			end try
			
		else
			if whichpart is in {"frworking0", "frworking2"} then
				pathings(contents of data cell fullpathcell of statusrow) of snippets
				set outputfile to contents of data cell outputfilecell of statusrow
				set exportfile to contents of data cell exportfilecell of statusrow
				dones(statusrow)
				-- MAKE FILE LOOK DONE
				set contents of data cell statusiconcell of statusrow to (load image "ok")
				set contents of data cell statustextcell of statusrow to "done"
				update window "FilmRedux"
				set workingdone to (workingdone + thisdur)
				if howmanydone > 0 then
					set sofardur to calcbigdur(contents of data cell durationnumcell of (every data row of theDataSource where contents of data cell statustextcell is "done")) of snippets
				else
					set sofardur to 0
				end if
				exit repeat
			else
				do shell script "echo notdone > " & tmpdir & "filmredux_working"
				afconvert(statusrow)
			end if
			
		end if
		
		set allfps to (runfps + allfps)
		--end try
	end repeat
	
	
	bartime()
	
	--100% DONE	
	--	set contents of data cell progresscell of theRow to 1
	--	if whichpart is not 1 then
	--		set the content of progress indicator "bar" of window "FilmRedux" to (1 + howmanydone)
	--	end if
	return true
end statuscheck


on bartime()
	--repeat until isdone is "done"
	iscancelled()
	--	try
	--		set {thepercent, thesinglepercent} to percenter()
	--	end try
	if twopass then
		set fullpassmultiplier to 2
	else
		set fullpassmultiplier to 1
	end if
	set thepercent to ((workingdone + (sofardur * fullpassmultiplier)) / (fulldur * fullpassmultiplier))
	
	--set contents of data cell progresscell of theRow to (thesinglepercent)
	try
		if thepercent > 0.99 then
			set thepercent to 0.99
		end if
	end try
	if thepercent > 0.01 and (title of button "pause" of window "FilmRedux" is not (localized string "resume")) then --and whichpart is not 1 then
		tell progress indicator "bar" of window "FilmRedux"
			set beforecontent to content
			if thepercent > beforecontent then
				set the content to (thepercent)
			end if
			if isassembly is false then set indeterminate to false
		end tell
		try
			if allfps > 0 then
				tell text field "filenum" of window "FilmRedux"
					set content to (allfps & "fps") as string
				end tell
			end if
		end try
		--	 call method "updateDockTile:" of class "UKDockProgressIndicator" of progress indicator "bar" of window "FilmRedux"
		--	if aroundonce is true or aroundonce is false then
		-- I still don't really remember how this code works...
		set nowtime to (do shell script "/bin/date +%s") as number
		set spenttime to (nowtime - whichstarttime)
		set percentnotdone to (1 - thepercent)
		set percentleft to (percentnotdone / thepercent)
		set timeremaining to (((spenttime * percentleft) / 60) * 1)
		if timeremaining < 1 then
			set approx to (localized string "lessthanspace")
			set theminutes to (localized string "spaceminutespace")
			set howlonglessthan to (howlonglessthan + 1)
		else
			set approx to (localized string "aboutspace")
			set theminutes to (localized string "spaceminutesspace")
		end if
		-- Keep the "Paused" message up during pausation.
		if howlonglessthan > (60 / updatefrequency) and isassembly is false then
			set the content of text field "timeremaining" of window "FilmRedux" to (localized string "badestimate")
		end if
		if timeremaining > 0 then
			if isassembly is false then
				set the content of text field "timeremaining" of window "FilmRedux" to (approx & (round timeremaining rounding up) & theminutes & remainingforfileorbatch & "...")
			else
				set the content of text field "timeremaining" of window "FilmRedux" to remainingforfileorbatch
				
			end if
		end if
		--	end if
	else
		set indeterminate of progress indicator "bar" of window "FilmRedux" to true
		
	end if
	--set isdone to (do shell script "/bin/cat " & tmpdir & "filmredux_working")
	
	--set aroundonce to true
	
	--	if whichpart is not 1 then
	set overallpercent to thepercent -- ((contents of progress indicator "bar" of window "FilmRedux")) -- / therange) -- - 1) * -1)
	(*
	if overallpercent > 0.2 then
		if icondone is not in {"prog2", "prog4", "prog6", "prog8"} then
			set icondone to "prog2"
			set icon image to (load image icondone)
		end if
	end if
	if overallpercent > 0.4 then
		if icondone is not in {"prog4", "prog6", "prog8"} then
			set icondone to "prog4"
			set icon image to (load image icondone)
		end if
	end if
	if overallpercent > 0.6 then
		if icondone is not in {"prog6", "prog8"} then
			set icondone to "prog6"
			set icon image to (load image icondone)
		end if
	end if
	if overallpercent > 0.8 then
		if icondone is not "prog8" then
			set icondone to "prog8"
			set icon image to (load image icondone)
		end if
	end if
	*)
	--	end if
	
	--	end repeat
end bartime


on startrun()
	
	--PREREQUISITE VARIABLES
	set buttonsscript to (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
	set howmany to gethowmany() of buttonsscript
	set theDataSource to data source of table view "table" of scroll view "table" of window "FilmRedux"
	if howmany is 0 and isassembly is false then
		stoprun()
		display alert (localized string "nofiles") message (localized string "nofilestext") as critical default button (localized string "nofilesbutton")
		error number -128
	end if
	
	-- STITCH HAS A CANCEL FIRST. STITCH NEEDS TO BE RE-WRITTEN ANYWAY--
	set stitch to false
	if content of button "stitch" of box "workflowbox" of box "box" of window "FilmRedux" is true then
		if isauto is false then
			set stitchedfile to ((text returned of (display dialog (localized string "namestitched") with icon 1 default answer "FilmReduxCombinedFile" giving up after 60)))
		else
			set stitchedfile to (contents of text field "supper" of window "FilmRedux") as Unicode text
		end if
		if stitchedfile is "" then
			set stitchedfile to "FilmReduxCombinedFile"
		end if
		set quotedstitchedfile to (quoted form of stitchedfile)
		set stitch to true
	end if
	
	
	tell menu "conversionmenu" of main menu
		set enabled of menu item "conversionmenuresume" to true
		set enabled of menu item "conversionmenucancel" to true
		set enabled of menu item "conversionmenuassembly" to false
		set enabled of menu item "conversionmenustart" to false
	end tell
	
	
	
	if (count of (every data row of theDataSource where (contents of data cell statustextcell is "frready"))) is 0 and isassembly is false then
		display alert (localized string "alreadydone") message (localized string "alreadydonetext") as warning default button (localized string "continue") alternate button (localized string "cancel")
		if button returned of the result is (localized string "cancel") then
			stoprun()
			error number -128
		else
			-- LET ERRORS CONVERT TOO --set allconverts to (every data row of theDataSource where contents of data cell statustextcell is "frworking")
			set allconverts to (every data row of theDataSource)
			repeat with thisconvert in allconverts
				set contents of data cell statustextcell of thisconvert to "frready"
				set contents of data cell statusiconcell of thisconvert to (load image "ready")
			end repeat
			
			-- LET ERRORS CONVERT TOO
			(*		
			set allok to (every data row of theDataSource where contents of data cell statustextcell is "done")
			repeat with thisok in allok
				set contents of data cell statustextcell of thisok to "frready"
				set contents of data cell statusiconcell of thisok to (load image "ready")
			end repeat
			*)
			update window "FilmRedux"
		end if
	end if
	
	-- COMMON VARIABLES --
	set thePath to path of the main bundle as string
	set thequotedapppath to quoted form of thePath
	set thequotedrecpath to quoted form of (resource path of the main bundle as Unicode text)
	set snippets to (load script (scripts path of main bundle & "/snippets.scpt" as POSIX file))
	set batchstarttime to do shell script "/bin/date +%s"
	set batchtmpdir to ("/tmp/frtemp/" & batchstarttime & "/")
	
	(* --RE-ADD THIS LATER SOMEHOW
	if state of menu item "conversionmenulog" of menu "conversionmenu" of main menu as boolean is true then
		tell application "Terminal" to do script "/usr/bin/tail -f " & tmpdir & "filmredux_time"
	end if
	*)
	set sysver to (do shell script "/usr/bin/uname -r | /usr/bin/cut -c 1")
	set mencoder to wheremencoder(false) of snippets
	set preview to false
	set finishstitch to false
	set pipe to ""
	set stitchstack to {}
	set donestack to {}
	set icondone to "prog0"
	set hasgrowl to false
	set thepercent to 0
	set howlonglessthan to 0
	--set icon image to (load image icondone)
	
	if contents of default entry "growl" of user defaults is true then
		tell application "System Events" to set hasgrowl to ((count of (every process whose name is "GrowlHelperApp")) > 0)
	end if
	if contents of default entry "nice" of user defaults is true then
		set nice to "/usr/bin/nice -n 20 "
	else
		set nice to ""
	end if
	
	
	backslasher() of snippets
	
	--ENABLE GROWL
	if hasgrowl then
		try
			startgrowl() of (load script (scripts path of main bundle & "/growl.scpt" as POSIX file))
		end try
	end if
	
	-- GET THE BAR RUNNING --
	tell progress indicator "bar" of window "FilmRedux"
		set uses threaded animation to true
		set indeterminate to true
		set minimum value to 0
		set maximum value to 1
		set content to 0
		start
	end tell
	set the content of text field "timeremaining" of window "FilmRedux" to (localized string "startingconversion")
	update window "FilmRedux"
	
	(* --OLD WAY
	if state of menu item "conversionmenulog" of menu "conversionmenu" of main menu as boolean is true then
		delay 1
		set tailpid to (do shell script "/bin/ps xwwo pid,command | /usr/bin/grep 'tail -f' | /usr/bin/grep -v grep | /usr/bin/tail -1 | /usr/bin/awk '{print $1}'" as string)
		set contents of text field "tailpid" of window "FilmRedux" to tailpid
	end if
	*)
end startrun

on pervars()
	set howmany to gethowmany() of buttonsscript
	set maximum value of progress indicator "bar" of window "FilmRedux" to 1
	tell progress indicator "bar" of window "FilmRedux" to set therange to (maximum value - minimum value)
	set howmanydone to count of (data rows of theDataSource whose contents of data cell statustextcell is "done")
	set whichpart to "frworking0"
	set mp3ok to false
	set pipe to ""
	set pipeprep to " "
	set isqt to false
	set isvlc to false
	set fpshalf to false
	set twopass to false
	set externalaudio to " "
	set substring to " "
	set extras to ""
	set playgroundflags to " "
	set extraflags to " "
	set vfilters1 to " -vf softskip"
	set vfilters2 to ",harddup "
	set vfilters to ""
	set afaudios to ""
	set afilters to " "
	set {thetitle, theartist, thealbum, thetrack, theyear, thegenre, thecomment} to {"", "", "", "", "", "", ""}
	set alldurs to contents of data cell durationnumcell of every data row of theDataSource
	set fulldur to calcbigdur(alldurs) of snippets
	if howmanydone > 0 then
		set sofardur to calcbigdur(contents of data cell durationnumcell of (every data row of theDataSource where contents of data cell statustextcell is "done")) of snippets
	else
		set sofardur to 0
	end if
	-- PREPARE FOR WHENDONES
	tell box "workflowbox" of box "box" of window "FilmRedux"
		set dowhendone to contents of button "postactiononoff"
		set whichwhendone to contents of popup button "postaction"
	end tell
end pervars

on stoprun()
	tell window "FilmRedux"
		tell progress indicator "bar"
			set indeterminate to false
			set minimum value to 0
			set maximum value to 1
			set content to 0
			stop
		end tell
		set title of button "pause" to (localized string "pause")
		set visible of button "start" to true
		set visible of button "cancel" to false
		set visible of button "pause" to false
		set contents of text field "timeremaining" to ""
		set contents of text field "filenum" to ""
		set enabled of table view "table" of scroll view "table" to true
		update
	end tell
	--	set icon image to (load image "FilmRedux")
	tell menu "conversionmenu" of main menu
		set enabled of menu item "conversionmenuresume" to false
		set enabled of menu item "conversionmenucancel" to false
		set enabled of menu item "conversionmenuassembly" to true
		set enabled of menu item "conversionmenustart" to true
	end tell
	--	try
	--		if state of menu item "conversionmenulog" of menu "conversionmenu" of main menu as boolean is true then
	--			set tailpid to (do shell script "/bin/ps xwwo pid,command | /usr/bin/grep 'tail -f' | /usr/bin/grep filmredux_time | /usr/bin/grep -v grep | /usr/bin/tail -1 | /usr/bin/awk '{print $1}'" as string)
	--			do shell script "/bin/kill -s QUIT " & tailpid
	--			--		do shell script "/bin/kill -s QUIT " & contents of text field "tailpid" of window "FilmRedux"
	--		end if
	--	end try
end stoprun

on iscancelled()
	if contents of text field "wanter" of window "FilmRedux" is "cancel" then
		tell window "FilmRedux"
			set contents of text field "timeremaining" to (localized string "cancelling")
			update
			try
				set allconversionids to contents of data cell starttimecell of every data row of theDataSource
				set allprocesses to ""
				repeat with thisid in allconversionids
					set allprocesses to (allprocesses & " mencoder" & thisid)
				end repeat
				set AppleScript's text item delimiters to " "
				do shell script "/usr/bin/killall " & allprocesses
			end try
			try
				writelog() of snippets
			end try
			try
				if contents of popup button "formats" of box "box" of window "FilmRedux" > 13 then
					do shell script "/bin/sh -c '/usr/bin/drutil eject' &> /dev/null &"
				end if
			end try
			set contents of text field "wanter" to ""
			update
		end tell
		if contents of default entry "keepcancel" of user defaults is false then
			try
				do shell script "/bin/rm " & exportfile
			end try
		end if
		stoprun()
		set allconverts to (every data row of theDataSource)
		repeat with thisconvert in allconverts
			set contents of data cell statustextcell of thisconvert to "frready"
			set contents of data cell statusiconcell of thisconvert to (load image "ready")
		end repeat
		update window "FilmRedux"
		error number -128
	end if
	return true
end iscancelled

on choose menu item theObject
	if name of theObject is "conversionmenustart" then
		readygo(false)
	end if
	if name of theObject is "conversionmenuassembly" then
		set contents of text field "wanter" of window "FilmRedux" to "assembly"
		readygo(false)
	end if
end choose menu item

on clicked theObject
	if contents of text field "supper" of window "FilmRedux" is not "" then
		readygo(true)
	else
		readygo(false)
	end if
end clicked

on bounds changed theObject
	readygo(true)
end bounds changed

