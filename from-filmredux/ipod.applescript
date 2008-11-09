-- lossies.applescript
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
global bitforce
global hzforce
global chanforce
global hzset
global audbitforce
global audbitset
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
global mencoderstring
global quotedoutputfile
global outputfile
global tmpdir
global preview
global normalend
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
global stitch
global stitchstack
global donefile
global quoteddonefile
global fileext
global whichone
global exportfile
global appsup
global endline
global otherextras
global origformat
global origtitle
global origartist
global origalbum
global origyear
global origcomment
global origtrack
global origgenre

global whichpart
global finalbit
global finalchan
global finalhz

global thedurnum

global whichwhendone
global dowhendone
global finalbitdepth
global theRow

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
global fpshalf

global externalaudio
global afaudios
global substring

global multiconv

global twopass

global randombit

global thismencoder
global conversionid


--LOCAL GLOBALS
global qualitylevel
global do51

on formatstart(toformat)
	
	if toformat is in {alldevices, ipod5g, ipodclassic, ipodnano, iphone, ipodtouch} then
		set fileext to contents of default entry "itunesextension" of user defaults
	end if
	-- MAKE AN ADVANCED SETTING
	set anam to false
	set xopts1 to ""
	set xopts to ""
	set lavfopts to ""
	set do51 to false
	
	tell box "box" of window "FilmRedux"
		set qualitylevel to contents of slider "quality" of box "qualitybox"
		tell tab view item "ipodbox" of tab view "formatbox"
			set h264 to contents of button "h264"
			if toformat is appletv then
				set tvres to false
				if h264 is true then set do51 to true
				set h264 to true
			else if toformat is alldevices then
				set tvres to true
			else
				set tvres to contents of cell 2 of matrix "optim"
			end if
		end tell
	end tell
	
	
	if tvres is true then
		if toformat is in {alldevices, ipod5g} then
			set whichipod to "ipod5gtvres"
		else
			set whichipod to "ipodtvres"
		end if
	else
		if toformat is in {ipod5g, ipodclassic, ipodnano} then
			set whichipod to "ipodres"
		end if
		if toformat is in {iphone, ipodtouch} then
			set whichipod to "iphoneres"
		end if
		if toformat is in {appletv} then
			if qualitylevel is 1 then set fpshalf to true
			set thefps to getfps(fpshalf) of (load script (scripts path of main bundle & "/finder.scpt" as POSIX file))
			if thefps is in {"30000/1001", "30"} then
				set whichipod to "appletv30res"
			else
				set whichipod to "appletvres"
			end if
			--PUT AC3 STUFF HERE
			set fileext to "mp4"
		end if
	end if
	
	
	--	try
	set {finalaudhz, finalaudchannels, finalaudbitrate} to audbasher(toformat, qualitylevel) of (load script (scripts path of main bundle & "/finder.scpt" as POSIX file))
	--	on error
	--		set {finalaudhz, finalaudchannels, finalaudbitrate} to {44100, 2, 128}
	--	end try
	
	
	set encopts to " -lavcopts threads=" & multiconv & ":acodec=libfaac:aglobal=1:abitrate=" & finalaudbitrate
	set afilters to (afilters & " -af-add channels=" & finalaudchannels & ":resample=" & finalaudhz)
	
	set {finalwidth, finalheight} to getres(whichipod, anam, h264) of (load script (scripts path of main bundle & "/finder.scpt" as POSIX file))
	
	set vfilters to ",scale=" & finalwidth & ":" & finalheight
	
	if h264 then
		set vfilters to (vfilters & (",dsize=" & (finalwidth as integer) & ":" & (finalheight as integer)))
		set ovc to "x264"
		set xopts1 to " -x264encopts threads=" & multiconv * 2 & ":global_header"
	else
		set ovc to "lavc"
	end if
	
	
	if h264 then set xopts to ":frameref=2:level_idc=30:bframes=0"
	--BITRATES
	set forcebitrate to getvidbitrate() of snippets
	
	if forcebitrate is 0 then
		if finalwidth is less than or equal to 320 and finalheight is less than or equal to 240 and h264 is true then
			--SCREEN SIZED H264
			--maxrate 768
			set xopts to ":frameref=3:level_idc=13:bframes=0"
			
			if qualitylevel is 5 then
				set thevidbitrate to 700
				set qmin to 8
			end if
			if qualitylevel is 4 then
				set thevidbitrate to 600
				set qmin to 20
			end if
			if qualitylevel is 3 then
				set thevidbitrate to 500
				set qmin to 25
			end if
			if qualitylevel is 2 then
				if toformat is iphone then
					set thevidbitrate to 150
					set qmin to 25
				else
					set thevidbitrate to 300
					set qmin to 32
				end if
			end if
			if qualitylevel is 1 then
				if toformat is iphone then
					set thevidbitrate to 60
					set qmin to 25
				else
					set thevidbitrate to 150
					set qmin to 26
				end if
				set fpshalf to true
			end if
		else if (toformat is in {ipod5g, alldevices}) and h264 is true then
			--maxrate 1500
			set lavfopts to "-lavfopts format=ipod"
			if qualitylevel is 5 then
				set thevidbitrate to 1400
				set qmin to 8
			end if
			if qualitylevel is 4 then
				set thevidbitrate to 1200
				set qmin to 20
			end if
			if qualitylevel is 3 then
				set thevidbitrate to 1000
				set qmin to 25
			end if
			if qualitylevel is 2 then
				set thevidbitrate to 600
				set qmin to 28
			end if
			if qualitylevel is 1 then
				set thevidbitrate to 300
				set qmin to 32
				set fpshalf to true
			end if
		else if toformat is appletv then
			set xopts to ":frameref=3:level_idc=31:bframes=0"
			--maxrate 5000
			
			if qualitylevel is 5 then
				set thevidbitrate to 4500
				set qmin to 8
			end if
			if qualitylevel is 4 then
				set thevidbitrate to 3750
				set qmin to 18
			end if
			if qualitylevel is 3 then
				set thevidbitrate to 2500
				set qmin to 22
			end if
			if qualitylevel is 2 then
				set thevidbitrate to 1500
				set qmin to 26
			end if
			if qualitylevel is 1 then
				set thevidbitrate to 750
				set qmin to 32
				set fpshalf to true
			end if
		else
			--maxrate 2500
			
			if qualitylevel is 5 then
				set thevidbitrate to 2400
				set qmin to 2
				if h264 then set qmin to 8
			end if
			if qualitylevel is 4 then
				set thevidbitrate to 1800
				set qmin to 3
				if h264 then set qmin to 20
			end if
			if qualitylevel is 3 then
				set thevidbitrate to 1200
				set qmin to 5
				if h264 then set qmin to 25
			end if
			if qualitylevel is 2 then
				set thevidbitrate to 700
				set qmin to 8
				if h264 then set qmin to 28
			end if
			if qualitylevel is 1 then
				set thevidbitrate to 500
				set qmin to 6
				if h264 then set qmin to 32
				set fpshalf to true
			end if
		end if
		
		if h264 then
			if twopass then
				set qminflag to ":qp_min=8"
			else
				set qminflag to ":qp_min=" & (qmin as integer) as string
			end if
			set xopts1 to (xopts1 & ":nocabac" & qminflag & ":bitrate=" & (thevidbitrate as integer))
		else
			if twopass then
				set qminflag to ":vqmin=2"
			else
				set qminflag to ":vqmin=" & (qmin as integer) as string
			end if
			set encopts to (encopts & ":vcodec=mpeg4:vbitrate=" & thevidbitrate & qminflag & ":vglobal=1:vmax_b_frames=0")
		end if
	else
		set thevidbitrate to forcebitrate
		if h264 then
			set xopts1 to (xopts1 & ":qp_min=8:bitrate=" & (thevidbitrate as integer))
		else
			set encopts to (encopts & ":vcodec=mpeg4:vbitrate=" & thevidbitrate & ":vqmin=2:vglobal=1:vmax_b_frames=0")
		end if
	end if
	
	set thefps to getfps(fpshalf) of (load script (scripts path of main bundle & "/finder.scpt" as POSIX file))
	
	
	-- SHOULD THIS GO HERE???
	--	if preview is false then
	set exportfile to quotedoutputfile & ".temp." & fileext
	
	--IPHONE 2.0 WORKAROUND
	if thefps is "24" then set thefps to "24000/1001"
	
	if twopass then
		if h264 then
			set pass1xopts to (xopts & ":pass=1:turbo=1 -passlogfile " & tmpdir & "2pass.log -nosound")
			set xopts to (xopts & ":pass=2 -passlogfile " & tmpdir & "2pass.log.temp")
			set pass1encopts to ""
		else
			set pass1encopts to (encopts & ":vpass=1 -passlogfile " & tmpdir & "2pass.log -nosound")
			set encopts to (encopts & ":vpass=2 -passlogfile " & tmpdir & "2pass.log")
			set pass1xopts to ""
		end if
		set pass1start to "echo 1 > " & tmpdir & "filmredux_pass ; "
		set pass1string to pass1start & pipe & thismencoder & pipeprep & filetoconvert & substring & audiotrack & externalaudio & skipsec & forcedur & vfilters1 & vfilters & vfilters2 & afilters & " -ovc " & ovc & xopts1 & pass1xopts & " -oac lavc " & pass1encopts & " -ofps " & thefps & " -nosound " & playgroundflags & extraflags & " -of lavf " & lavfopts & " -o " & tmpdir & "pass1." & fileext & " >> " & tmpdir & "filmredux_time 2>&1 ; "
	end if
	
	set mencoderstring to pipe & thismencoder & pipeprep & " -cache 20000 " & filetoconvert & substring & audiotrack & externalaudio & skipsec & forcedur & vfilters1 & vfilters & vfilters2 & afilters & " -ovc " & ovc & xopts1 & xopts & " -oac lavc " & encopts & " -ofps " & thefps & " -srate " & finalaudhz & playgroundflags & extraflags & " -of lavf " & lavfopts & " -o " & exportfile
	
	if twopass then set mencoderstring to (pass1string & "echo 2 > " & tmpdir & "filmredux_pass ; " & mencoderstring)
	--	tell application "Terminal" to do script mencoderstring
end formatstart

on normaldone()
	
	set workfile to quoted form of (outputfile & ".post." & fileext)
	set donefile to (outputfile & "." & fileext)
	if (do shell script "/bin/test -f " & quoted form of donefile & " ; echo $?") is "1" then
		-- DESTINATION IS CLEAR!
	else
		-- FILE ALREADY EXISTS!
		set thedate to do shell script "/bin/date +%y%m%d-%H%M%S"
		set donefile to (outputfile & "-converted-" & thedate & "." & fileext)
		set workfile to quoted form of (outputfile & "-converted-" & thedate & ".finish." & fileext)
	end if
	set quoteddonefile to quoted form of donefile
	
	try
		--IF STREAMING IPHONE, DO QT MUX
		if (toformat is in {ipodtouch, iphone} and qualitylevel < 3) then
			do shell script thequotedapppath & "/Contents/Resources/qt_export --loadsettings=" & thequotedapppath & "/Contents/Resources/mp4pass --exporter=mpg4 " & exportfile & " " & workfile & " > /dev/null 2>&1 ; exit 0"
		else
			do shell script thequotedapppath & "/Contents/Resources/AtomicParsley " & exportfile & " --encodingTool 'FilmRedux 2.00' -o " & workfile & " > /dev/null 2>&1 ; exit 0"
		end if
	end try
	
	-- IF MUX FAILS, KEEP OLD FILE
	if (do shell script "/bin/test -f " & workfile & " ; echo $?") is "0" then
		set howbig to (do shell script "ls -ln " & workfile & " | /usr/bin/awk '{print $5}'") as number
		try
			if (howbig > 100) then
				do shell script "/bin/rm " & exportfile
			else
				do shell script "/bin/rm " & workfile
			end if
		end try
	end if
	try
		do shell script "/bin/mv -n " & workfile & " " & quoteddonefile
	end try
	
	
	--		easyend() of snippets
	--specialtags() of snippets
end normaldone
