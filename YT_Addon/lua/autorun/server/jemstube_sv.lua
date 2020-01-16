local API = "https://invidio.us/api/v1/videos/"
local luckyDJ = nil -- Who has the priveledge of picking a song.
local songTimeout = 0 -- The time at which the next song can be requested, equal to the time the last song was played + it's duration.

print("JemsTube Server initialised")

CreateConVar("YT_Minimum_Song_Request_Timeout", 20, CVAR_REPLICATED, "Once a request has been accepted from the first valid user, another request will not be considered for the amount of seconds specified here.")
CreateConVar("YT_Admin_Only", 0, CVAR_REPLICATED, "Only allow admins or superadmins to play music, Enable with 1, disable with 0.")
CreateConVar("YT_Lucky_DJ", 0, CVAR_REPLICATED, "In TTT, one user per round will get the ability to pick the song! Enable with 1, disable with 0.")
CreateConVar("YT_Usergroup", "Veteran", CVAR_REPLICATED, "If YT_Usergroup_Only = 1, this string will be the group with YTA rights.")
CreateConVar("YT_Usergroup_Only", 0, CVAR_REPLICATED, "Allow only the specified usergroup + admins to use YTA. Enable with 1, disable with 0.")

util.AddNetworkString("JemsTube_Request") -- Ask a client for an URL
util.AddNetworkString("JemsTube_Play") -- Give the clients an URL to play
util.AddNetworkString("JemsTube_Stop") -- Kill all playing sounds for all clients

function JemsTube_ResetModule() -- Reset all variables during the game, does not effect convars.
	luckyDJ = nil
	songTimeout = 0
	net.Start("JemsTube_Stop")
	net.Broadcast()
end


function JemsTube_UpdateLuckyDJ()
	songTimeout = 0 -- Reset the song timeout so the new DJ can drop some beats
	if (GetConVar("YT_Lucky_DJ"):GetInt() == 1) then
		if (#player.GetAll() == 0) then return end
		local random = math.random(#player.GetHumans())
		luckyDJ = player.GetHumans()[random]
		print("Lucky DJ this round is " .. luckyDJ:Nick())
	end
end
if (GetConVar("Gamemode"):GetString() == "terrortown") then
	hook.Add("TTTPrepareRound", "JemsTube_TTT_Lucky_DJ", JemsTube_UpdateLuckyDJ)
end

function JemsTube_UpdateSongTimeout(duration) -- Update the songTimeout var.
	songTimeout = RealTime() + duration
end

function JemsTube_GetMetadata(VID, ply) -- Send HTTP request to middle man server to fetch direct youtube link

	if (RealTime() < songTimeout) then -- ignore too many requests in too short a time frame
		print ("Ignoring request from " .. ply:Nick() .. " due to YT_Minimum_Song_Request_Timeout")
        return
    end
	JemsTube_UpdateSongTimeout(GetConVar("YT_Minimum_Song_Request_Timeout"):GetInt())	
    http.Fetch( API .. VID, 
    function (result)
		local metadata = util.JSONToTable(result)
		if (metadata["adaptiveFormats"] == nil) then
			print ("Unexpected response from API processing request from " .. ply:Nick()) -- Sometimes the API returns malformed responses.
			return
		end
		for stream = 1, #metadata["adaptiveFormats"] do
			if (string.sub(metadata["adaptiveFormats"][stream]["type"], 1, 5) == "audio" ) then
				URL = metadata["adaptiveFormats"][stream]["url"]
				message = ply:Nick() .. " is playing " .. metadata["title"] .. "  Length: " .. string.NiceTime(metadata["lengthSeconds"])
				print(message)
				JemsTube_InformClients(URL, message)
				return
			end
		end
	end, 
	
	function(failed) 
		print("Unable to connect to API whilst processing request from " .. ply:Nick())
    end)
    
end

function JemsTube_InformClients(URL, message)
	net.Start("JemsTube_Play")
	net.WriteString(URL)
	net.WriteString(message)
	net.Broadcast()
end

function JemsTube_ProcessChat(ply, text, team)
	if (GetConVar("YT_Admin_Only"):GetInt() == 1) then
		if (ply:IsAdmin() ~= true and ply:IsSuperAdmin() ~= true) then
			return text
		end
	end

	if (GetConVar("YT_Usergroup_Only"):GetInt() == 1) then
		if (ply:IsAdmin() == false and ply:IsSuperAdmin() == false  and  ply:GetUserGroup() ~= GetConVar("YT_Usergroup"):GetString()) then
			return text
		end
	end

	if (string.sub(text, 1, 4) == "!ytr") then
		if (ply:IsAdmin() or ply:IsSuperAdmin()) then
			JemsTube_ResetModule()
			print("JemsTube session reset by " .. ply:Nick())
			return nil
		else
			return text
		end
	end

	if (ply ~= luckyDJ and GetConVar("YT_Lucky_DJ"):GetInt() == 1) then
		return text
	end

	if (string.sub(text, 1, 3) == "!yt") then 
        local VID = string.match( text ,"v=[%w-_]+" )

        -- Check if a valid video ID was found.
        if (VID == nil) then 
            return text -- So that other modules can process it, and kill the request here since it's invalid
        end

        VID = string.gsub(VID, "v=", "") -- Remove V= from the video ID

        JemsTube_GetMetadata(VID, ply)
        return nil; --Hide the message from other modules
    end
    return text
end
hook.Add( "PlayerSay", "JemsTube_Chat_Event", JemsTube_ProcessChat)