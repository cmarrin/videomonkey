-- preview.applescript
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


global thePath
global thequotedapppath
global fullstarttime
global mencoder
global sysver
global stitchedfile
global stitch
global stitchstack
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
global lossy
global aac
global mp3
global wma
global threeg
global ogg
global lossless
global aiff
global wav
global applelossless
global flac
global burn
global audiocd
global mp3cd
global bitforce
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
global finishstitch
global isflac
global isvlc
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
global ismidi
global dowhendone

global whichpart
global finalbit
global substring

global batchstarttime

on clicked theObject
	if name of theObject is "previewgenerate" then
		dopreview()
	end if
	if name of theObject is "previewloop" then
		set doloop to contents of button "previewloop" of window "preview"
		try
			tell movie view "previewqt" of window "preview"
				if doloop then
					set loop mode to looping playback
				else
					set loop mode to normal playback
				end if
			end tell
		end try
	end if
end clicked

on will close theObject
	tell window "preview"
		try
			tell movie view "previewqt" to stop
		end try
	end tell
end will close

on dopreview()
	
	set buttonsscript to (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))
	set howmany to gethowmany() of buttonsscript
	set theDataSource to data source of table view "table" of scroll view "table" of window "FilmRedux"
	if howmany is 0 then
		display alert (localized string "nofiles") message (localized string "nofilestext") as critical default button (localized string "nofilesbutton")
		error number -128
	end if
	
	set batchstarttime to do shell script "/bin/date +%s"
	
	-- GET THE SELECTED FILE PATH, OR THE FIRST FILE
	set thetableview to table view "table" of scroll view "table" of window "FilmRedux"
	try
		set origpath to (contents of data cell fullpathcell of selected data row of thetableview as Unicode text)
	on error
		set origpath to (contents of data cell fullpathcell of data row 1 of data source of thetableview as Unicode text)
	end try
	try
		set AppleScript's text item delimiters to "."
		set ext to last text item of origpath
		if ext is (first text item of theFile) then
			set ext to ""
			set extsize to -1
		end if
	end try
	set quotedorigpath to quoted form of origpath
	set filetoconvert to quotedorigpath
	
	-- USE TRIM VALUES INSTEAD WHEN APPLICABLE
	if contents of button "trimonoff" of tab view item "advancedoneoffbox" of tab view "advancedbox" of window "advanced" is true then
		tell window "preview"
			set visible of text field "previewusetrim" to true
			set visible of text field "previewstart" to false
			set visible of text field "previewss" to false
			set visible of text field "previewsecondsin" to false
			set visible of text field "previewt" to false
			set visible of text field "previewseconds" to false
			update
		end tell
	else
		tell window "preview"
			set visible of text field "previewusetrim" to false
			set visible of text field "previewstart" to true
			set visible of text field "previewss" to true
			set visible of text field "previewsecondsin" to true
			set visible of text field "previewt" to true
			set visible of text field "previewseconds" to true
			update
		end tell
	end if
	
	tell window "preview"
		try
			tell movie view "previewqt" to stop
		end try
		show
		tell progress indicator "previewbar"
			set uses threaded animation to true
			start
			set visible to true
		end tell
		update
	end tell
	
	
	-- INITIAL VARS
	set thePath to path of the main bundle as string
	set thequotedapppath to quoted form of thePath
	set snippets to (load script (scripts path of main bundle & "/snippets.scpt" as POSIX file))
	tmpgetter(false) of snippets
	do shell script "/usr/bin/touch " & tmpdir & "filmredux_time"
	set sysver to (do shell script "/usr/bin/uname -r | /usr/bin/cut -c 1")
	set mencoder to wheremencoder(false) of snippets
	set stitch to false
	set finishstitch to false
	set pipe to ""
	backslasher() of snippets
	set pipeprep to " "
	set isqt to false
	set isvlc to false
	set isflac to false
	set ismidi to false
	set whichstep to 0
	set dowhendone to false
	
	set endline to " 2>> " & tmpdir & "filmredux_time"
	set preview to true
	set quotedoutputfile to "/tmp/frtemp/frpreview" & fullstarttime
	set {theformat, thedur, thesize, thecodec, thebitdepth, thehz, thechan, thebitrate, thetitle, theartist, thealbum, theyear, thecomment, thetrack, thegenre} to quickinfo(origpath, fullstarttime, false) of (load script (scripts path of main bundle & "/table.scpt" as POSIX file))
	
	set {origformat, origdur, origsize, origcodec, origbitdepth, orighz, origchan, origbitrate, origtitle, origartist, origalbum, origyear, origcomment, origtrack, origgenre} to {theformat, thedur, thesize, thecodec, thebitdepth, thehz, thechan, thebitrate, thetitle, theartist, thealbum, theyear, thecomment, thetrack, thegenre}
	
	
	quicktimedetect() of snippets
	advanceds() of snippets
	
	formatinit() of buttonsscript
	
	-- USE TRIM VALUES INSTEAD WHEN APPLICABLE
	if contents of button "trimonoff" of tab view item "advancedoneoffbox" of tab view "advancedbox" of window "advanced" is false then
		tell window "preview"
			set skipsec to contents of text field "previewss"
			if skipsec is not "" then
				set skipsec to (" -ss " & skipsec & " ")
			else
				set skipsec to " "
			end if
			
			set forcedur to contents of text field "previewt"
			if forcedur is not "" then
				set forcedur to (" -t " & forcedur & " ")
			else
				set forcedur to " -t " & 20 & " "
			end if
		end tell
	end if
	
	if contents of button "previewcomp" of window "preview" is true and (contents of popup button "formats" of box "box" of window "FilmRedux" is not in {wav, aiff, flac, applelossless, audiocd}) then
		set docompression to true
	else
		set docompression to false
	end if
	
	
	if docompression is false then
		set whichformat to (load script (scripts path of main bundle & "/losslessers.scpt" as POSIX file))
		set toformat to wav
		formatstart(toformat) of whichformat
	else
		set toformat to contents of popup button "formats" of box "box" of window "FilmRedux"
		if toformat is mp3cd then
			set toformat to mp3
		end if
		if toformat is in {aac, mp3, wma, threeg, ogg} then
			set whichformat to (load script (scripts path of main bundle & "/lossies.scpt" as POSIX file))
			formatstart(toformat) of whichformat
		end if
		--		if toformat is in {audiocd} then
		--			set whichformat to (load script (scripts path of main bundle & "/cds.scpt" as POSIX file))
		--			formatstart(toformat) of whichformat
		--		end if
	end if
	
	-- NORMAL GO
	if (contents of default entry "nice" of user defaults) is true then
		set nice to "/usr/bin/nice -n 20 "
	else
		set nice to ""
	end if
	
	do shell script "cd /tmp ; " & nice & "/bin/sh -c \"" & mencoderstring & endline & "\" &> /dev/null ; exit 0"
	
	
	--FIX QTCANTREADS
	if toformat is in {wma, ogg, flac} then
		do shell script "cd /tmp ; " & nice & "/bin/sh -c \"" & mencoder & " -y -i " & " /tmp/frtemp/frpreview" & fullstarttime & ".temp." & fileext & " /tmp/frtemp/frpreview.temp.wav \" &> /dev/null ; exit 0"
		set fileext to "wav"
		do shell script "/bin/rm -f /tmp/frtemp/frpreview" & fullstarttime & ".temp." & fileext & " ; /bin/mv /tmp/frtemp/frpreview.temp.wav /tmp/frtemp/frpreview" & fullstarttime & ".temp." & fileext & " ; exit 0"
	end if
	
	tell window "preview"
		set moviefile to "/tmp/frtemp/frpreview" & fullstarttime & ".temp." & fileext
		try
			set movie of movie view "previewqt" to load movie moviefile
			--do it again for good measure
			--set movie of movie view "previewqt" to load movie moviefile
			tell progress indicator "previewbar"
				set visible to false
				stop
			end tell
			set doloop to contents of button "previewloop"
			tell movie view "previewqt"
				if doloop is true then
					set loop mode to looping playback
				else
					set loop mode to normal playback
				end if
				play
			end tell
			do shell script "/bin/rm -f " & moviefile
		on error
			display alert (localized string "previewerror") as warning default button (localized string "ok")
			tell progress indicator "previewbar"
				set visible to false
				stop
			end tell
			--do shell script "open /tmp/frtemp"
		end try
		update
	end tell
end dopreview