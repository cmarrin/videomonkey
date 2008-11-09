-- growl.applescript
-- FilmRedux

on startgrowl()
	tell application "GrowlHelperApp"
		set the allNotificationsList to {"Conversion Complete", "File Complete"}
		set the enabledNotificationsList to {"Conversion Complete", "File Complete"}
		register as application "FilmRedux" all notifications allNotificationsList default notifications enabledNotificationsList icon of application "FilmRedux"
	end tell
end startgrowl

on completenotify(whichnotify, growltitle, growlstring)
	tell application "GrowlHelperApp" to notify with name whichnotify title growltitle description growlstring application name "FilmRedux"
end completenotify

