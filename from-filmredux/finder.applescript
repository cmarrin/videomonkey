-- notttahubres.applescript
-- notttahubres


global displaywidth
global displayheight
global finalwidth
global finalheight
global extras
global fourbythree
global sixteenbynine
global twothreefivetoone

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

global audbitforce
global audbitset
global hzforce
global chanforce
global hzset
global chanset

global anam
global extras

global vfilters1

global randombit

on getres(toformat, anam, h264)
	
	
	--	set anam to contents of button "anam" of window "window"
	
	--	if origsar is 0 then
	set origsar to (origwidth / origheight)
	--	else if origsar is 1 then
	--		set origsar to (4 / 3)
	--	else if origsar is 2 then
	--		set origsar to (16 / 9)
	--	end if
	set correctedsar to origsar
	
	set {croptop, cropbottom, cropleft, cropright} to {0, 0, 0, 0}
	tell tab view item "advancedvideobox" of tab view "advancedbox" of window "advanced"
		set doautocrop to false
		set croptop to contents of text field "croptop"
		set cropbottom to contents of text field "cropbottom"
		set cropleft to contents of text field "cropleft"
		set cropright to contents of text field "cropright"
		if cropbottom is "" then
			set cropbottom to 0
		else
			try
				set cropbottom to (cropbottom as integer)
			on error
				set cropbottom to 0
			end try
		end if
		if cropleft is "" then
			set cropleft to 0
		else
			try
				set cropleft to (cropleft as integer)
			on error
				set cropleft to 0
			end try
		end if
		if cropright is "" then
			set cropright to 0
		else
			try
				set cropright to (cropright as integer)
			on error
				set cropright to 0
			end try
		end if
		if croptop is "" then
			set croptop to 0
		else if croptop is (localized string "Auto") then
			set doautocrop to true
		else
			try
				set croptop to (croptop as integer)
			on error
				set croptop to 0
			end try
		end if
		set forcewidth to contents of text field "videowidth"
		set forceheight to contents of text field "videoheight"
	end tell
	
	if doautocrop is true then set {croptop, cropbottom, cropleft, cropright} to autocrop() of (load script (scripts path of main bundle & "/snippets.scpt" as POSIX file))
	
	
	-- FIX 16 BY 9 SARS
	if origsar is greater than 1.77 and origsar is less than 1.78 then set correctedsar to (16 / 9)
	
	
	-- KNOWN 16 BY 9 RESOLUTIONS
	if {origwidth, origheight} is {1440, 1080} or {origwidth, origheight} is {1280, 1080} or {origwidth, origheight} is {1280, 720} or {origwidth, origheight} is {1920, 1080} then
		set correctedsar to (16 / 9)
		
		-- MESSED UP 1080P
	else if {origwidth, origheight} is {1920, 1088} then
		set correctedsar to {1.76470588}
		
		-- KNOWN 4 BY 3 RESOLUTIONS
	else if {origwidth, origheight} is {480, 480} or {origwidth, origheight} is {352, 480} or {origwidth, origheight} is {480, 576} or {origwidth, origheight} is {352, 576} then
		set correctedsar to (4 / 3)
	end if
	
	try
		set stretchratio to ((origheight * correctedsar) / origwidth)
		if stretchratio is less than or equal to 0 then error
	on error
		set stretchratio to 1
	end try
	
	--CROP FILTER
	if {croptop, cropbottom, cropleft, cropright} is not {0, 0, 0, 0} then
		set newx to (origwidth - cropleft) - cropright
		set newy to (origheight - croptop) - cropbottom
		set vfilters1 to (vfilters1 & ",crop=" & newx & ":" & newy & ":" & cropleft & ":" & croptop)
	end if
	
	
	set displayheight1 to ((origheight - croptop) - cropbottom)
	set displaywidth1 to (((origwidth - cropleft) - cropright) * stretchratio)
	
	set displaywidth to ((round (displaywidth1 / 2)) * 2) as integer
	set displayheight to ((round (displayheight1 / 2)) * 2) as integer
	
	set readyratio to (displaywidth / displayheight)
	set readyreverse to (displayheight / displaywidth)
	
	
	if forcewidth is "" and forceheight is not "" then
		return {((((forceheight * readyratio) / 2) as integer) * 2) as integer, forceheight as integer}
	end if
	
	if forcewidth is not "" and forceheight is "" then
		return {forcewidth as integer, ((((forcewidth * readyreverse) / 2) as integer) * 2) as integer}
	end if
	
	if forcewidth is not "" and forceheight is not "" then
		return {forcewidth as integer, forceheight as integer}
	end if
	
	-- CHOOSE YOUR DESTINY
	--DEFAULT
	set {fourbythree, sixteenbynine, twothreefivetoone} to {false, false, false}
	
	if readyratio is greater than 1.2 and readyratio is less than or equal to 1.5 then
		set fourbythree to true
	end if
	
	if readyratio is greater than 1.5 and readyratio is less than 2 then
		set sixteenbynine to true
	end if
	
	if readyratio is greater than or equal to 2 and readyratio is less than or equal to 2.5 then
		set twothreefivetoone to true
	end if
	
	if {fourbythree, sixteenbynine, twothreefivetoone} is {false, false, false} then
		set fourbythree to true
	end if
	
	if toformat is in {"ipod5gtvres", "ipodres", "ipodtvres", "iphoneres", "appletvres", "appletv30res"} then
		if displaywidth is less than or equal to 320 and displayheight is less than or equal to 240 then
			ipodres(true)
		else
			if toformat is "ipod5gtvres" then
				ipod5gtvres(true)
			end if
			if toformat is "ipodres" then
				ipodres(true)
			end if
			if toformat is "ipodtvres" then
				ipodtvres(true)
			end if
			if toformat is "iphoneres" then
				iphoneres(true)
			end if
			if toformat is "appletvres" then
				appletvres(true)
			end if
			if toformat is "appletv30res" then
				appletv30res(true)
			end if
		end if
	end if
	
	if toformat is "pspres" then
		pspres(true)
	end if
	if toformat is "psp330res" then
		psp330res()
	end if
	if toformat is "ntscdvres" then
		ntscdvres(anam)
	end if
	if toformat is "paldvres" then
		paldvres(anam)
	end if
	if toformat is "ntscdvdres" then
		ntscdvdres(anam, "4by3")
	end if
	if toformat is "paldvdres" then
		paldvdres(anam, "4by3")
	end if
	if toformat is "ntscdvdsmallres" then
		ntscdvdsmallres()
	end if
	if toformat is "paldvdsmallres" then
		paldvdsmallres()
	end if
	if toformat is "ntscvcdres" then
		ntscvcdres()
	end if
	if toformat is "palvcdres" then
		palvcdres()
	end if
	if toformat is "ntscvcdres" then
		ntscvcdres()
	end if
	if toformat is "palvcdres" then
		palvcdres()
	end if
	if toformat is "ntscsvcdres" then
		ntscsvcdres()
	end if
	if toformat is "palsvcdres" then
		palsvcdres()
	end if
	if toformat is "tivore" then
		tivores()
	end if
	if toformat is "hd720res" then
		hd720res(true)
	end if
	if toformat is "hd1080res" then
		hd1080res(true)
	end if
	if toformat is "hd720padres" then
		hd720padres(true)
	end if
	if toformat is "hd1080padres" then
		hd1080padres(true)
	end if
	
	return {finalwidth, finalheight}
	
end getres


on minires(h264)
	if fourbythree then set {finalwidth, finalheight} to {240, 176}
	if sixteenbynine then set {finalwidth, finalheight} to {240, 128}
	if twothreefivetoone then set {finalwidth, finalheight} to {240, 96}
end minires

on ipodres(h264)
	if fourbythree then set {finalwidth, finalheight} to {320, 240}
	if sixteenbynine then set {finalwidth, finalheight} to {320, 176}
	if twothreefivetoone then set {finalwidth, finalheight} to {320, 144}
end ipodres

on pspres(h264)
	if fourbythree then set {finalwidth, finalheight} to {320, 240}
	if sixteenbynine then set {finalwidth, finalheight} to {368, 208}
	if twothreefivetoone then set {finalwidth, finalheight} to {416, 176}
end pspres

on psp330res()
	if fourbythree then
		set {finalwidth, finalheight} to {368, 272}
		set extras to (extras & " -vf-add expand=-112:0,dsize=480:272 ")
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {480, 272}
		set extras to (extras & " -vf-add dsize=480:272 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {480, 208}
		set extras to (extras & " -vf-add expand=0:-64,dsize=480:272 ")
	end if
end psp330res

on ipod5gtvres(h264)
	if displaywidth is less than or equal to 640 and displayheight is less than or equal to 480 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {640, 480}
		if h264 is true then
			if sixteenbynine then set {finalwidth, finalheight} to {640, 352}
			if twothreefivetoone then set {finalwidth, finalheight} to {640, 272}
		else
			if sixteenbynine then set {finalwidth, finalheight} to {720, 400}
			if twothreefivetoone then set {finalwidth, finalheight} to {720, 304}
		end if
	end if
end ipod5gtvres

on ipodtvres(h264)
	if displaywidth is less than or equal to 720 and displayheight is less than or equal to 480 and (displaywidth * displayheight) is less than or equal to 307200 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {640, 480}
		if sixteenbynine then set {finalwidth, finalheight} to {720, 400}
		if twothreefivetoone then set {finalwidth, finalheight} to {720, 304}
	end if
end ipodtvres

on iphoneres(h264)
	if displaywidth is less than or equal to 480 and displayheight is less than or equal to 320 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {432, 320}
		if sixteenbynine then set {finalwidth, finalheight} to {480, 272}
		if twothreefivetoone then set {finalwidth, finalheight} to {480, 192}
	end if
end iphoneres

on appletvres(h264)
	if displaywidth is less than or equal to 1280 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {960, 720}
		if sixteenbynine then set {finalwidth, finalheight} to {1280, 720}
		if twothreefivetoone then set {finalwidth, finalheight} to {1280, 544}
	end if
end appletvres

on appletv30res(h264)
	if displaywidth is less than or equal to 960 and displayheight is less than or equal to 540 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {720, 540}
		if sixteenbynine then set {finalwidth, finalheight} to {960, 540}
		if twothreefivetoone then set {finalwidth, finalheight} to {960, 408}
	end if
end appletv30res

on ntscdvres(anamorphic)
	if fourbythree then
		set {finalwidth, finalheight} to {720, 480}
	end if
	if sixteenbynine then
		if anamorphic then
			set {finalwidth, finalheight} to {720, 480}
		else
			set {finalwidth, finalheight} to {720, 352}
			set extras to (extras & " -vf-add expand=0:-128 ")
		end if
	end if
	if twothreefivetoone then
		if anamorphic then
			set {finalwidth, finalheight} to {720, 384}
			set extras to (extras & " -vf-add expand=0:-96 ")
		else
			set {finalwidth, finalheight} to {720, 272}
			set extras to (extras & " -vf-add expand=0:-208 ")
		end if
	end if
end ntscdvres

on paldvres(anamorphic)
	if fourbythree then
		set {finalwidth, finalheight} to {720, 576}
	end if
	if sixteenbynine then
		if anamorphic then
			set {finalwidth, finalheight} to {720, 576}
		else
			set {finalwidth, finalheight} to {720, 432}
			set extras to (extras & " -vf-add expand=0:-144 ")
		end if
	end if
	if twothreefivetoone then
		if anamorphic then
			set {finalwidth, finalheight} to {720, 432}
			set extras to (extras & " -vf-add expand=0:-144 ")
		else
			set {finalwidth, finalheight} to {720, 352}
			set extras to (extras & " -vf-add expand=0:-224 ")
		end if
	end if
end paldvres

on ntscdvdres(anamorphic, ratio)
	if fourbythree then
		if ratio is not "16by9" then
			ntscdvres(false)
		else
			set {finalwidth, finalheight} to {560, 480}
			set extras to (extras & " -vf-add expand=0:-160 ")
		end if
	end if
	if sixteenbynine then
		if anamorphic is false and ratio is "4by3" then
			ntscdvres(false)
		else
			ntscdvres(true)
		end if
	end if
	if twothreefivetoone then
		if anamorphic is false and ratio is "4by3" then
			ntscdvres(false)
		else
			ntscdvres(true)
		end if
	end if
end ntscdvdres

on paldvdres(anamorphic, ratio)
	if fourbythree then
		if ratio is not "16by9" then
			paldvres(false)
		else
			set {finalwidth, finalheight} to {560, 576}
			set extras to (extras & " -vf-add expand=0:-160 ")
		end if
	end if
	if sixteenbynine then
		if anamorphic is false and ratio is "4by3" then
			paldvres(false)
		else
			paldvres(true)
		end if
	end if
	if twothreefivetoone then
		if anamorphic is false and ratio is "4by3" then
			paldvres(false)
		else
			paddvres(true)
		end if
	end if
end paldvdres

on ntscdvdsmallres()
	if fourbythree then
		set {finalwidth, finalheight} to {352, 480}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {352, 352}
		set extras to (extras & " -vf-add expand=0:-128 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {352, 272}
		set extras to (extras & " -vf-add expand=0:-208 ")
	end if
end ntscdvdsmallres

on paldvdsmallres()
	if fourbythree then
		set {finalwidth, finalheight} to {352, 576}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {352, 432}
		set extras to (extras & " -vf-add expand=0:-144 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {352, 352}
		set extras to (extras & " -vf-add expand=0:-224 ")
	end if
end paldvdsmallres

on ntscsvcdres()
	if fourbythree then
		set {finalwidth, finalheight} to {480, 480}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {480, 352}
		set extras to (extras & " -vf-add expand=0:-128 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {480, 272}
		set extras to (extras & " -vf-add expand=0:-208 ")
	end if
end ntscsvcdres

on palsvcdres()
	if fourbythree then
		set {finalwidth, finalheight} to {480, 576}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {480, 432}
		set extras to (extras & " -vf-add expand=0:-144 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {480, 352}
		set extras to (extras & " -vf-add expand=0:-224 ")
	end if
end palsvcdres

on tivores()
	if fourbythree then
		set {finalwidth, finalheight} to {544, 480}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {544, 352}
		set extras to (extras & " -vf-add expand=0:-128 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {544, 272}
		set extras to (extras & " -vf-add expand=0:-208 ")
	end if
end tivores

on ntscvcdres()
	if fourbythree then
		set {finalwidth, finalheight} to {352, 240}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {352, 176}
		set extras to (extras & " -vf-add expand=0:-64 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {352, 144}
		set extras to (extras & " -vf-add expand=0:-96 ")
	end if
end ntscvcdres

on palvcdres()
	if fourbythree then
		set {finalwidth, finalheight} to {352, 288}
	end if
	if sixteenbynine then
		set {finalwidth, finalheight} to {352, 192}
		set extras to (extras & " -vf-add expand=0:-96 ")
	end if
	if twothreefivetoone then
		set {finalwidth, finalheight} to {352, 160}
		set extras to (extras & " -vf-add expand=0:-128 ")
	end if
end palvcdres

on hd720res(h264)
	if displaywidth is less than or equal to 1280 and displayheight is less than or equal to 720 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {960, 720}
		if sixteenbynine then set {finalwidth, finalheight} to {1280, 720}
		if twothreefivetoone then set {finalwidth, finalheight} to {1280, 544}
	end if
end hd720res

on hd1080res(h264)
	if displaywidth is less than or equal to 1920 and displayheight is less than or equal to 1080 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then set {finalwidth, finalheight} to {1440, 1080}
		if sixteenbynine then set {finalwidth, finalheight} to {1920, 1080}
		if twothreefivetoone then set {finalwidth, finalheight} to {1920, 816}
	end if
end hd1080res

on hd720padres(h264)
	if displaywidth is less than or equal to 1280 and displayheight is less than or equal to 720 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then
			set {finalwidth, finalheight} to {960, 720}
			set extras to (extras & " -vf-add expand=-320:0 ")
		end if
		if sixteenbynine then
			set {finalwidth, finalheight} to {1280, 720}
		end if
		if twothreefivetoone then
			set {finalwidth, finalheight} to {1280, 544}
			set extras to (extras & " -vf-add expand=0:-176 ")
		end if
	end if
	if h264 then set extras to (extras & (" -vf-add dsize=1280:720 "))
end hd720padres

on hd1080padres(h264)
	if displaywidth is less than or equal to 1920 and displayheight is less than or equal to 1080 then
		set {finalwidth, finalheight} to {displaywidth, displayheight}
	else
		if fourbythree then
			set {finalwidth, finalheight} to {1440, 1080}
			set extras to (extras & " -vf-add expand=-480:0 ")
		end if
		if sixteenbynine then
			set {finalwidth, finalheight} to {1920, 1080}
		end if
		if twothreefivetoone then
			set {finalwidth, finalheight} to {1920, 816}
			set extras to (extras & " -vf-add expand=0:-264 ")
		end if
	end if
	if h264 then set extras to (extras & (" -vf-add dsize=1920:1080 "))
end hd1080padres

on getfps(fpshalf)
	
	set AppleScript's text item delimiters to space
	set forcefps1 to contents of combo box "fps" of tab view item "advancedvideobox" of tab view "advancedbox" of window "advanced"
	set forcefps to first text item of forcefps1
	
	if forcefps is "" or forcefps is (localized string "Auto") then
		--FPS SANITY
		try
			origfps as number
			if origfps is less than 1 then error
		on error
			set origfps to 30
		end try
		
		if fpshalf then
			if origfps is 25 then
				set thisfps to (origfps / 2)
			else
				set thisfps to (origfps / 2) as integer
			end if
		else
			set thisfps to origfps
			--NTSC FILM
			if origfps is greater than or equal to 23.9 and origfps is less than 24 then set thisfps to "24000/1001"
			--NTSC
			if origfps is greater than or equal to 29.9 and origfps is less than 30 then set thisfps to "30000/1001"
			--BROKEN XVID
			if origfps is 2 then set thisfps to "24000/1001"
			--BROKEN MKV
			if origfps is 24.39 then set thisfps to "24000/1001"
			--TOO BIG
			if origfps is greater than 30 then
				if origfps is 50 then
					set thisfps to "25"
				else if origfps is greater than or equal to 59.9 and origfps is less than 60 then
					set thisfps to "30000/1001"
				else
					set thisfps to "30"
				end if
			end if
		end if
		
	else
		set thisfps to forcefps
		if forcefps is in {"29.97", "29,97"} then set thisfps to "30000/1001"
		if forcefps is in {"23.98", "23,98", "23.976", "23,976", "23.97", "23,97"} then set thisfps to "24000/1001"
	end if
	
	return thisfps as string
end getfps

on audbasher(toformat, qualitylevel)
	
	--AUDIO	
	if hzforce is true then
		set theaudhz to hzset
	else
		set theaudhz to origaudhz
	end if
	
	if chanforce is true then
		set theaudchannels to chanset
	else
		set theaudchannels to origaudchannels
	end if
	
	if audbitforce is true then
		set theaudbitrate to audbitset
	else
		set theaudbitrate to origaudbitrate
	end if
	
	
	--BACKUP DEFAULTS
	set endhz to 44100
	set chanbit to 64
	set endchan to 2
	
	--SCARE HZ STRAIGHT
	try
		if theaudhz is greater than 44100 then
			set endhz to 48000
			set chanbit to 64
			if qualitylevel is 2 then
				set endhz to 44100
				set chanbit to 64
			end if
			if qualitylevel is 1 then
				set endhz to 22050
				set chanbit to 16
			end if
		end if
		if theaudhz is less than or equal to 44100 then
			set endhz to 44100
			set chanbit to 64
			if qualitylevel is 2 then
				set endhz to 44100
				set chanbit to 64
			end if
			if qualitylevel is 1 then
				set endhz to 22050
				set chanbit to 32
			end if
		end if
		if theaudhz is less than or equal to 32000 then
			set endhz to 32000
			set chanbit to 48
			if qualitylevel is 2 then
				set endhz to 22050
				set chanbit to 32
			end if
			if qualitylevel is 1 then
				set endhz to 11025
				set chanbit to 16
			end if
		end if
		if theaudhz is less than or equal to 22050 then
			set endhz to 22050
			set chanbit to 32
			if qualitylevel is 2 then
				set endhz to 11025
				set chanbit to 16
			end if
			if qualitylevel is 1 then
				set endhz to 11025
				set chanbit to 16
			end if
		end if
		if theaudhz is less than or equal to 11025 then
			set endhz to 11025
			set chanbit to 16
		end if
		if theaudhz is less than or equal to 8000 then
			set endhz to 8000
			set chanbit to 8
		end if
	end try
	
	--UNDERSTAND CHANNELS
	if chanforce is false then
		try
			if theaudchannels as string is "5.1" then
				set endchan to 2
			end if
			if theaudchannels as string is "5 channels" then
				set endchan to 2
			end if
			if theaudchannels as string is "6" then
				set endchan to 2
			end if
			if theaudchannels as string is "5" then
				set endchan to 2
			end if
			if theaudchannels as string is "4" then
				set endchan to 2
			end if
			if theaudchannels as string is "3" then
				set endchan to 2
			end if
			if theaudchannels as string is "2" then
				set endchan to 2
			end if
			if theaudchannels as string is "1" then
				set endchan to 1
			end if
			-- FORCE QUALITY PRESET CHANNELS
			if qualitylevel < 3 then
				set endchan to 1
			end if
		end try
	else
		set endchan to chanset
	end if
	
	--FORCED BIT CALC
	if hzforce is true then
		set endhz to theaudhz
		try
			if endhz is greater than or equal to 44100 then
				set chanbit to 64
			end if
			if endhz is less than 44100 then
				set chanbit to 48
			end if
			if endhz is less than or equal to 24000 then
				set chanbit to 32
			end if
			if endhz is less than or equal to 11025 then
				set chanbit to 16
			end if
			if endhz is less than or equal to 8000 then
				set chanbit to 8
			end if
		end try
	end if
	
	if audbitforce is true then
		set endbit to theaudbitrate
	else
		set endbit to (chanbit * endchan)
	end if
	
	if toformat is wmv and endbit is 16 then set endbit to 24
	
	if toformat is threeg then
		if contents of cell 1 of which3g is false then
			set endbit to 5900
			if qualitylevel is 1 then
				set endbit to 4.75
			end if
			if qualitylevel is 2 then
				set endbit to 5.15
			end if
			if qualitylevel is 3 then
				set endbit to 5.9
			end if
			if qualitylevel is 4 then
				set endbit to 7.95
			end if
			if qualitylevel is 5 then
				set endbit to 10.2
			end if
		end if
	end if
	
	return {endhz as number, endchan as number, endbit as number}
end audbasher
