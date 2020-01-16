Drop the contents of the yt_addon folder into into the GMod addon folders, then initialise the GMod server.
The server console can control whether to only allow admins or specific users to use the functionality.
The clients console can control the volume the music plays at, and whether to take part at all.
All console variables are prefixed with YT_*

To use this functionality, type `!yt <URL>` into the chat ingame.
Type `!ytr` to stop all currently playing music (Admin only)

Certain URLs will not be able to be successfully played due to the Youtube backend.

There appears to be a bug in lib BASS currently that means some files will end prematurely. In the event this is fixed in a future engine update, I will upload this addon to the workshop for easier installation.