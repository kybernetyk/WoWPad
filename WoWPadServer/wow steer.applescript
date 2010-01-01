-- Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
--
-- LICENSED UNDER THE BSD LICENSE (with attribution)
-- SEE LICENSE FILE

-- this is a little apple script that wraps world of warcraft's keybindings
-- it's just a proof of concept and not feature complete
--
-- there are so many key-press methods because not everyone will work in 
-- every case. (eg the chat needs a longer delay.) you'll have to try out what works




-- presses a key, holds it down for a given time and releases it again
on press_key(key, howlong)
	tell application "System Events" to tell process "World Of Warcraft"
		key down key
		delay howlong
		key up key
	end tell
end press_key

-- use system events keystroke
on stroke (key)
	tell application "System Events" to tell process "World Of Warcraft"
		keystroke key
	end tell
end press_key


-- presses the key down and DOES NOT release it (autowalk anyone?)
on press_keydown(key)
	tell application "System Events" to tell process "World Of Warcraft"
		key down key
	end tell
end press_keydown

-- releases a pressed key
on release_key(key)
	tell application "System Events" to tell process "World Of Warcraft"
		key up key
	end tell
end release_key

-- will take a keycode and press the key for 0.1 sec
on press_keycode(keycode)
	tell application "System Events" to tell process "World Of Warcraft"
		key code keycode
		delay 0.1
	end tell
end press_keycode

-- don't know :D
on supertell (keystring)
	tell application "System Events" to tell process "World Of Warcraft"
		keystroke keystring & return
	end tell
end supertell

-- sends return (used for chatting)
on sendreturn ()
	tell application "System Events" to tell process "World Of Warcraft"
		delay 0.1
		keystroke return
		delay 0.1
	end tell
end sendreturn

-- sends tab (just a convinience method)
on sendtab ()
	tell application "System Events" to tell process "World Of Warcraft"
		key code 48
	end tell
end sendreturn

-- keystrokes a string. you shouldn't use it as it will fail from time to time
on exectell (keystring)
	tell application "System Events" to tell process "World Of Warcraft"
		keystroke return
		delay 0.1
		keystroke keystring 
		delay 0.1
		keystroke return
		delay 0.1
	end tell
end supertell


--convinience movement methods

on walk_forward(howlong)
	press_key("w", howlong)
end walk_forward

on walk_backward(howlong)
	press_key("s", howlong)
end walk_backward

on turn_left(howlong)
	press_key("a", howlong)
end turn_left

on turn_right(howlong)
	press_key("d", howlong)
end turn_right

on jump()
	press_keycode(49)
	--press_key("SPACE", 2.0)
end jump


-- turns the char by a given amount of degrees. +value = turn right, -value = turn left
on turn(degrees)
	--wow turns at 180 degrees per second if you're using keyboard turning
	set thedelay to (degrees / 180.0)
	if thedelay < 0.0 then
		set thedelay to thedelay * -1.0
		turn_left(thedelay)
	else
		turn_right(thedelay)
	end if
end turn

-- this will be called first by the apple script interpreter. it will make wow active
-- (will start wow if not running)
tell application "World of Warcraft"
	activate
end tell
