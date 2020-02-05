--[[
Copyright (c) <2020> <James Carroll>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

print("YT Client initialised")

LocalPlayer().YTAudioChannel = nil -- The Sound being played

CreateClientConVar("YT_Enabled", 1, true, true, "Enable the YTA functionality, clientside, 1 for enabled, 0 for disabled.") -- Disable YTA on the client side.
CreateClientConVar("YT_Volume", 0.75, false, false, "The volume in the range of 0 to 1 YTA should play at. Takes effect at next played song.") -- Volume songs should play at. 

cvars.AddChangeCallback("YT_Volume", function( convar_name, value_old, value_new ) -- Update volume of a playing song.
	volume = tonumber( value_new, 10 ) 
	if (volume == nil) then return end -- Avoid strings and stuff. 
	if (volume >= 0 and volume <= 1.00) then
		if (LocalPlayer().YTAudioChannel ~= nil) then
			LocalPlayer().YTAudioChannel:SetVolume(volume)
		end
	end
end )

cvars.AddChangeCallback("YT_Enabled", function( convar_name, value_old, value_new ) -- Instantly disable any playing songs when YTA is disabled.
	value = tonumber( value_new, 10 ) 
	if (value == nil) then return end -- Avoid strings and stuff. 
	if (value == 0) then
		if (LocalPlayer().YTAudioChannel ~= nil) then
			LocalPlayer().YTAudioChannel:Stop()
		end
	end
end )

function YT_Play(URL, message)
	audioChannel = sound.PlayURL ( URL, "noblock", function (station, errorId, errorName) -- Remove noblock if in a future release, audio/mp4 is used. It takes a while to start playing!
		if ( IsValid( station ) ) then
			local volume = GetConVar("YT_Volume"):GetFloat()
			if (volume > 1 or volume < 0) then
				volume = 0.75
			end

			if (LocalPlayer().YTAudioChannel ~= nil) then
				LocalPlayer().YTAudioChannel:Stop()
			end

			station:SetVolume(volume)
			station:Play()
			notification.AddLegacy(message, NOTIFY_GENERIC, 10)
			LocalPlayer().YTAudioChannel = station
		else
			notification.AddLegacy(errorName .. " - Youtube is probably blocking the request, try again or find an alternate upload", NOTIFY_ERROR , 10 )
			-- LocalPlayer().YTAudioChannel = nil
		end 
	end)
end

net.Receive( "YT_Play", function( len, pl ) -- Trigger above function,  the actual processing of the song
	if (GetConVar("YT_Enabled"):GetInt() == 0) then
		return
	end
	local URL= net.ReadString()
	local message = net.ReadString()
	YT_Play(URL, message)
end)

net.Receive("YT_Request", function( len, pl ) -- Trigger above function when server sends message.
	if (GetConVar( "YT_Enabled" == 1)) then
		notification.AddLegacy( "It's your turn to pick a song, use '!yt URL'", NOTIFY_GENERIC, 15 )
		surface.PlaySound( "buttons/button15.wav" )
	end
end)

net.Receive("YT_Stop", function( len, pl) 
	if (LocalPlayer().YTAudioChannel ~= nil) then
		LocalPlayer().YTAudioChannel:Stop()
	end
end)