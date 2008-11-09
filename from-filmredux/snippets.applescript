-- snippets.applescript
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

global thefilecell
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
global fullstarttime
global filetoconvert
global writable
global audbitforce
global audbitset
global hzforce
global chanforce
global hzset
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
global mencoderstring
global quotedoutputfile
global outputfile
global tmpdir
global preview
global normalend
global howmany
global isqt
global pipe
global pipeprep
global durfile
global thequotedapppath
global theyear
global theartist
global thetitle
global thecomment
global thetrack
global thegenre
global thealbum
global setyear
global setartist
global settitle
global setcomment
global settrack
global setgenre
global setalbum
global stitch
global stitchstack
global donefile
global quoteddonefile
global fileext
global whichone
global exportfile
global mencoder
global buttonsscript
global stitchdestpath
global quotedstitchdestpath
global finishstitch
global appsup
global otherextras
global acodec
global isflac
global isvlc
global thelogfile
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
global totalleft
global ismidi
global thedur
global thedurnum

global iscd
global cdtracknum

global whichpart

global thehz
global thechan


global whichwhendone
global dowhendone

global batchstarttime
global randombit
global statusrow
global batchtmpdir

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

global externalaudio
global afaudios
global substring

global twopass
global theRow

global thismencoder
global conversionid


on pathings(thefilecell)
	-- GET THE FILE PATH --
	set theFilepath to contents of thefilecell as Unicode text
	
	-- PICK IT APART --
	set theFile to call method "lastPathComponent" of theFilepath
	set thePath to ((call method "stringByDeletingLastPathComponent" of theFilepath) & "/") as Unicode text
	
	-- FILE EXTENSION --
	set ext to (call method "pathExtension" of theFilepath)
	set filenoext to (call method "stringByDeletingPathExtension" of (call method "lastPathComponent" of theFilepath))
	
	-- IMPORTANT QUOTED FORMS --
	set quotedfile to (quoted form of filenoext) --JUST THE FILE NAME, NO EXTENSION
	set quotedpath to (quoted form of thePath) --JUST THE PATH TO THE FILE
	set quotedorigpath to (quoted form of theFilepath) --THE ENTIRE PATH AND FILE
	set filetoconvert to quotedorigpath --ALL NORMAL FILES: SAME AS QUOTEDORIGPATH
	
	-- CHECK FOR WRITEABILITY IN OUTPUT DIR --
	set writable to true
	tell text field "saveto" of box "workflowbox" of box "box" of window "FilmRedux"
		set custompath to contents
		if custompath is "" then
			try
				do shell script "/usr/bin/touch " & quotedpath & "/.frtest"
				do shell script "/bin/rm " & quotedpath & "/.frtest"
			on error
				set writable to false
			end try
		else
			-- SET CUSTOM PATH --
			set quotedcustompath to (quoted form of custompath)
			try
				do shell script "/usr/bin/touch " & quotedcustompath & "/.frtest"
				do shell script "/bin/rm " & quotedcustompath & "/.frtest"
			on error
				set writable to false
			end try
		end if
		if writable is false then
			set contents to (do shell script "cd ~/Desktop ; pwd")
		end if
		set saveto to contents
	end tell
	-- SET OUTPUT PATH --
	if saveto is "" then
		set destpath to (thePath)
	else
		if last text item of saveto is not "/" then
			set saveto to (saveto & "/")
		end if
		set destpath to (saveto) as Unicode text
	end if
	if stitch is true then
		set stitchdestpath to destpath
		set quotedstitchdestpath to quoted form of stitchdestpath
	end if
	
	set outputfile to (destpath & filenoext)
	set quotedoutputfile to quoted form of (destpath & filenoext)
	
	-- SPECIAL FORMAT EXCEPTIONS --
	if ext is "eyetv" then
		set filetoconvert to (quotedorigpath & "/*.mpg") as Unicode text
		set ext to "mpg"
	end if
	if ext is "iMovieProject" then
		set filetoconvert to (quotedorigpath & "/'Shared Movies/iDVD'/*.mov") as Unicode text
		set ext to "mov"
	end if
end pathings

on autocrop()
	do shell script pipe & tmpdir & "mencoder" & fullstarttime & randombit & pipeprep & " " & filetoconvert & "  -vf cropdetect -ovc raw -nosound -of rawvideo -o /dev/null 2> /dev/null > " & tmpdir & "filmredux_crop &"
	set numdelay to (contents of default entry "autocroptime" of user defaults) as integer
	delay numdelay
	try
		do shell script "killall mencoder" & fullstarttime & randombit
	end try
	set mencodercrops to (do shell script "/usr/bin/tail " & tmpdir & "filmredux_crop | /usr/bin/grep crop | /usr/bin/tail -1 | /usr/bin/awk -F 'crop=' '{print $2}' | /usr/bin/awk -F ')' '{print $1}'")
	set AppleScript's text item delimiters to ":"
	set {keepx, keepy, cropx, cropy} to text items of mencodercrops
	set croptop to cropy
	set cropbottom to (origheight - keepy) - cropy
	set cropleft to cropx
	set cropright to (origwidth - keepx) - cropx
	return {croptop, cropbottom, cropleft, cropright}
end autocrop

on advanceds()
	tell tab view item "advancedoneoffbox" of tab view "advancedbox" of window "advanced"
		set skipsec to contents of slider "ss"
		if skipsec is not 0 then
			set skipsec to (" -ss " & skipsec & " ")
		else
			set skipsec to " "
		end if
		
		set AppleScript's text item delimiters to ""
		set thetrim to "untitled"
		
		set thisduration to "e" & second text item of thetrim & "dpos"
		set forcedur to contents of slider "t"
		set durmax to maximum value of slider "t"
		if forcedur is not (durmax) and forcedur is not 0 then
			set totalleft to ((durmax - (contents of slider "ss")) - (durmax - (contents of slider "t"))) as integer
			set forcedur to (" -" & thisduration & " " & totalleft & " ")
		else
			set forcedur to " "
		end if
		
		
	end tell
	
	
	tell tab view item "advancedvideobox" of tab view "advancedbox" of window "advanced"
		set howdeinterlace to contents of popup button "deinterlace"
		if howdeinterlace is 0 then
			if originterlacing1 is "Interlaced" then
				set vfilters1 to " -vf yadif=0,softskip"
			else
				set vfilters1 to " -vf softskip"
			end if
		end if
		if howdeinterlace is 1 then
			set vfilters1 to " -vf softskip"
		end if
		if howdeinterlace is 2 then
			set vfilters1 to " -vf dint,softskip"
		end if
		if howdeinterlace is 3 then
			--MAKE BETTER	
			set vfilters1 to " -vf yadif=0,softskip"
		end if
		if howdeinterlace is 4 then
			set vfilters1 to " -vf pullup,softskip"
		end if
		
		-- FILTERS
		set gamma to contents of slider "gamma" as string
		set brightness to contents of slider "brightness" as string
		set contrast to contents of slider "contrast" as string
		set saturation to contents of slider "saturation" as string
		set denoise to contents of slider "denoise" as integer
		if denoise is 1 then set vfilters1 to (vfilters1 & ",pp=de/-al")
		if denoise is 2 then set vfilters1 to (vfilters1 & ",pp=ac/-al")
		if denoise is 3 then set vfilters1 to (vfilters1 & ",pp=ac/-al/tmpnoise:1:2:3")
		
		
		--rotate
		
		-- FILTERS 2
		
		
		if my commadecimal() then
			set gamma to (switchText from gamma to "." instead of ",")
			set brightness to (switchText from brightness to "." instead of ",")
			set contrast to (switchText from contrast to "." instead of ",")
			set saturation to (switchText from saturation to "." instead of ",")
		end if
		if {gamma, brightness, contrast, saturation} is not {"1.0", "0.0", "1.0", "1.0"} then
			set vfilters2 to ((",eq2=" & gamma & ":" & contrast & ":" & brightness & ":" & saturation) & vfilters2)
		end if
		
		-- image overlay
	end tell
	
	tell tab view item "advancedaudiobox" of tab view "advancedbox" of window "advanced"
		set hzset to contents of combo box "audiohz"
		if hzset is "" or hzset is (localized string "auto") then
			set hzforce to false
		else
			set hzforce to true
		end if
		set audbitset to contents of text field "audiobitrate"
		if audbitset is "" or audbitset is (localized string "auto") then
			set audbitforce to false
		else
			set audbitforce to true
		end if
		set chanset to contents of popup button "audiochannels"
		if chanset is 0 then
			set chanforce to false
		else
			set chanforce to true
		end if
		set whichexternalaudio to contents of text field "replacementaudio"
		if whichexternalaudio is not "" then
			set externalaudio to " -audiofile " & quoted form of whichexternalaudio & " "
		else
			set externalaudio to " "
		end if
		set audiotrack to contents of popup button "audiotrack"
		if audiotrack is not 0 then
			set audiotrack to (" -aid " & audiotrack & " ")
		else
			set audiotrack to " "
		end if
		set afaudios to contents of text field "afaudio"
		set extraflags to (extraflags & " " & afaudios)
		if contents of button "normalize" is true then
			if afilters is " " then
				set afilters to " -af volnorm"
			else
				set afilters to (afilters & ",volnorm")
			end if
		end if
		set volslider to contents of slider "vol"
		if volslider is not 0 then
			if volslider is -30 then
				set afaudios to " -nosound "
			else
				set volwork to volslider as string
				
				if my commadecimal() then set volwork to (switchText from volwork to "." instead of ",")
				if afilters is " " then
					set afilters to " -af volume=" & volwork
				else
					set afilters to (afilters & ",volume=" & volwork)
				end if
			end if
		end if
	end tell
end advanceds

on getvidbitrate()
	tell tab view item "advancedvideobox" of tab view "advancedbox" of window "advanced"
		set fit to contents of text field "fit"
		set vidbit to contents of text field "videobitrate"
		set matchoriginal to contents of button "matchoriginal"
		set fitonoff to contents of button "fitonoff"
		set twopass to contents of button "twopass"
		
		if matchoriginal or fitonoff then
			--SIZE IN kbps
			if matchoriginal then
				set theorigsize to (((do shell script "ls -lan " & quotedorigpath & " | awk '{print $5}'") * 8) / 1024) as integer
			else
				set theorigsize to ((fit as integer) * 8192)
			end if
			set fullbit to (theorigsize / origduration)
			set bitforvid to ((fullbit - finalaudbitrate) - 15) --COMPENSATE FOR CONTAINER OVERHEAD
			if bitforvid > 0 then return bitforvid as integer
		end if
		if vidbit is not "" then
			return vidbit as integer
		end if
		return 0
	end tell
end getvidbitrate

on quicktimedetect()
	set forcedecoder to false
	set whichdecoder to contents of popup button "decoder" of tab view item "advancedvideobox" of tab view "advancedbox" of window "advanced"
	if whichdecoder > 0 then
		set isqt to false
		set isvlc to false
		set isflac to false
		set ismidi to false
		set forcedecoder to true
		if whichdecoder is 1 then
			set isqt to true
			--	set forcedecoder to true
		end if
		if whichdecoder is 3 then
			set isvlc to true
			--		set forcedecoder to true
		end if
	end if
	if ("QuickTime" is in (contents of data cell infocell of theRow) and forcedecoder is false) or (isqt is true) then
		set isqt to true
		set movfps to origfps as integer
		set colon to ":1"
		if origfps is 23.98 then
			set movfps to 24
			set colon to "000:1001"
		end if
		if origfps is 29.97 then
			set movfps to 30
			set colon to "000:1001"
		end if
		if origfps as integer < 3 then
			set movfps to 30
		end if
		set movwidth to getmult(origwidth, 4)
		set movheight to getmult(origheight, 4)
		do shell script "/usr/bin/mkfifo " & tmpdir & "video.y4m"
		do shell script "/usr/bin/mkfifo " & tmpdir & "audio.pcm"
		set pipe to (thequotedapppath & "/Contents/Resources/mov123 " & quotedorigpath & " > " & tmpdir & "audio.pcm 2> /dev/null & " & thequotedapppath & "/Contents/Resources/movtoy4m -w " & movwidth & " -h " & movheight & " -F " & movfps & colon & " -a " & movwidth & ":" & movheight & " " & quotedorigpath & " 2>> " & tmpdir & "/filmredux_time > " & tmpdir & "video.y4m & ")
		set pipeprep to " -demuxer y4m -audio-demuxer rawaudio -audiofile " & tmpdir & "audio.pcm -rawaudio channels=2:rate=48000 -delay -0.3 "
		set filetoconvert to tmpdir & "video.y4m"
	end if
	if isvlc is true then
		if (contents of default entry "vlcloc" of user defaults as string) is "" then
			--		set contents of default entry "vlcloc" of user defaults to (POSIX path of (path to application "VLC"))
			try
				set contents of default entry "vlcloc" of user defaults to (do shell script "/usr/bin/osascript -l AppleScript -e 'POSIX path of (path to application \"VLC\")'")
			on error
				stoprun() of (load script (scripts path of main bundle & "/main.scpt" as POSIX file))
				error (localized string "novlc")
			end try
		end if
		
		if origfps > 60 then
			set vlcfps to 60
		end if
		if origfps < 51 then
			set vlcfps to 50
		end if
		if origfps < 31 then
			set vlcfps to 30
		end if
		if origfps < 26 then
			set vlcfps to 25
		end if
		if origfps < 25 then
			set vlcfps to 24
		end if
		if origfps < 23 then
			set vlcfps to 30
		end if
		if origfps is 15 then
			set vlcfps to 30
		end if
		
		set thefifo to (tmpdir & "/vlcpipe.mpg")
		do shell script "/usr/bin/mkfifo " & thefifo
		set pipe to ((quoted form of (contents of default entry "vlcloc" of user defaults as string)) & "/Contents/MacOS/clivlc -I dummy " & quotedorigpath & " --sout-transcode-fps " & vlcfps & " --gamma 1.18 --sout-ffmpeg-qscale 1 --sout='#transcode{vcodec=mp2v,scale=1,acodec=mpga,channels=2,samplerate=48000,ab=320,audio-sync}:std{mux=ps,dst=" & thefifo & "}' vlc:quit 2>> " & tmpdir & "/filmredux_time | ")
		set pipeprep to " -demuxer mpegps "
		set filetoconvert to thefifo
	end if
end quicktimedetect

on cleartags()
	set {settitle, setartist, setalbum, settrack, setyear, setgenre, setcomment} to {" ", " ", " ", " ", " ", " ", " "}
end cleartags

on easyend()
	--Finished.
	if finishstitch is true then
		set the content of text field "timeremaining" of window "FilmRedux" to (localized string "finishing")
		--	else
		--		set the content of text field "timeremaining" of window "FilmRedux" to (localized string "finishingfile") & whichone & "..."
	end if
	update window "FilmRedux"
	
	(* MODIFY FOR FilmRedux 	if stitch is true then
		set stitchstack to (stitchstack & quotedoutputfile)
		set quoteddonefile to " "
	else *)
	set donefile to (outputfile & "." & fileext)
	if (do shell script "/bin/test -f " & quoted form of donefile & " ; echo $?") is "1" then
		-- DESTINATION IS CLEAR!
	else
		-- FILE ALREADY EXISTS!
		set thedate to do shell script "/bin/date +%y%m%d-%H%M%S"
		set donefile to (outputfile & "-converted-" & thedate & "." & fileext)
	end if
	set quoteddonefile to quoted form of donefile
	try
		do shell script "/bin/mv -n " & exportfile & " " & quoteddonefile
	end try
	--	end if
end easyend

on wheremencoder(onlaunched)
	set thePath to path of the main bundle as string
	set thequotedapppath to quoted form of thePath
	return thequotedapppath & "/Contents/Resources/mencoder"
end wheremencoder

on calcbigdur(alldurs)
	(* --OLD WAY
	set durwork to 0
	repeat with thisdur in alldurs
		--try
		set durwork to ((durwork) + (timeswap(thisdur) of (load script (scripts path of main bundle & "/buttons.scpt" as POSIX file))))
		--end try
	end repeat
	*)
	
	set AppleScript's text item delimiters to "+"
	set durwork to do shell script "echo '" & alldurs & "' | /usr/bin/bc"
	
	set AppleScript's text item delimiters to ""
	
	return durwork
end calcbigdur

on writelog()
	--WRITE THE LOG
	try
		do shell script "/usr/bin/head -c 6000 " & quotedorigpath & " | /usr/bin/gzip | /usr/bin/uuencode -m - >> " & batchtmpdir & "filmredux_time"
	end try
	try
		do shell script "/bin/mkdir -p ~/Library/Logs/FilmRedux ; exit 0"
	end try
	set thelogfiledate to do shell script "/bin/date +%y%m%d-%H%M"
	set thelogfile to "~/Library/Logs/FilmRedux/fr-" & thelogfiledate & "-" & quotedfile & ".txt"
	do shell script "/bin/cp " & batchtmpdir & "filmredux_time " & thelogfile
end writelog

on backslasher()
	set backslash to "\\"
	try
		if (do shell script "/bin/echo " & (ASCII character 128) & "a") is "a" then
			set backslash to (ASCII character 128)
		end if
	end try
end backslasher

on tmpgetter(justadd)
	set fullstarttime to do shell script "/bin/date +%s"
	set randombit to do shell script "echo $RANDOM$RANDOM$RANDOM$RANDOM | /usr/bin/cut -c 1-4"
	if justadd is false then
		set contents of text field "fullstarttime" of window "FilmRedux" to batchstarttime
		set tmpdirname to (batchstarttime & "/" & fullstarttime & randombit)
	else
		set tmpdirname to (fullstarttime & randombit)
	end if
	if (contents of default entry "tmploc" of user defaults as string) is "/tmp/" then
		try
			do shell script "/bin/mkdir -p /tmp/frtemp/" & tmpdirname
		end try
		try
			do shell script "/bin/chmod 777 /tmp/frtemp" & tmpdirname
		end try
		try
			do shell script "/bin/chmod -R 777 /tmp/frtemp"
		end try
	else
		try
			--display dialog (quoted form of (contents of default entry "tmpdir" of user defaults as string))
			do shell script "/bin/ln -s " & (quoted form of (contents of default entry "tmploc" of user defaults as string)) & " /tmp/frtemp"
		end try
		try
			do shell script "/bin/mkdir -p /tmp/frtemp/" & tmpdirname
		end try
		try
			do shell script "/bin/chmod -R 777 /tmp/frtemp"
		end try
	end if
	set tmpdir to "/tmp/frtemp/" & tmpdirname & "/"
end tmpgetter

on tmpcleaner(fullclean)
	if fullclean is true then
		try
			do shell script "/bin/rm -r /tmp/frtemp"
		end try
	else
		try
			do shell script "/bin/rm -r /tmp/frtemp/" & fullstarttime
		end try
	end if
end tmpcleaner

on commadecimal()
	if (0.73 as string) is "0,73" then
		return true
	else
		return false
	end if
end commadecimal


on getmult(orignum, mult)
	return ((round (orignum / mult)) * mult)
end getmult

on getupmult(orignum, mult)
	return ((round (orignum / mult) rounding up) * mult)
end getupmult

