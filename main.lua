-- Command: "/autolog [on|off] [password]"

autolog = {}


local account_info = unspickle(gkini.ReadString("autolog", "accountinfo", ""))

function autolog.getcharacterslot(name)
	for i=1, GetNumCharacters() do
		if name == GetCharacterInfo(i) then return i end
	end
end

function autolog:OnEvent(event, ...)
	if not account_info[1] then return end
	if event == "PLAYER_LOGGED_OUT" then -- relog gogo
		Login(account_info[1], account_info[2])
	elseif event == "SERVER_DISCONNECTED" then -- assume server shut down for update, quit to apply. / DOESN'T TRIGGER D:
		Game.Quit()
	elseif event == "LOGIN_SUCCESSFUL" then
		-- do nothing!
	elseif event == "LOGIN_FAILED" then
		local str = string.lower(...)
		if str:match("version") then -- need to update.
			Game.Quit()
		elseif str:match("login incorrect") then -- user or pass is wrong
			account_info = {}
			gkini.WriteString("autolog", "accountinfo", spickle(account_info))
		else -- server-side, keep trying
			Login(account_info[1], account_info[2])
		end
	elseif event == "START" then
		Login(account_info[1], account_info[2])
	elseif event == "UPDATE_CHARACTER_LIST" then
		SelectCharacter(account_info[3])
		Game.StopLoginCinematic()
	end
end

function autolog.commands(_, data)
	if not IsConnected() then return end
	if not data then purchaseprint("Command: \"/autolog [on|off] [password]\"") return end
	local cmd = data[1]:lower()
	if cmd == "on" and data[2] then
		local charname = GetPlayerName(GetCharacterID())
		account_info = {
			GetUserName(),
			data[2], -- password
			autolog.getcharacterslot(charname),
		}
		gkini.WriteString("autolog", "accountinfo", spickle(account_info))
		purchaseprint("Autolog now ON for the character "..charname.." on the account "..account_info[1])
	elseif cmd == "off" then
		account_info = {}
		gkini.WriteString("autolog", "accountinfo", spickle(account_info))
		purchaseprint("Autolog now OFF")
	elseif cmd == "status" then
		-- print account name if on
		if account_info[1] then
			local charname = GetCharacterInfo(account_info[3])
			purchaseprint("Autolog is ON for the character "..charname.." on the account "..account_info[1])
		else
			purchaseprint("Autolog is OFF")
		end
	end
end

RegisterEvent(autolog, "LOGIN_SUCCESSFUL")
RegisterEvent(autolog, "PLAYER_LOGGED_OUT")
RegisterEvent(autolog, "UPDATE_CHARACTER_LIST")
RegisterEvent(autolog, "LOGIN_FAILED")
RegisterEvent(autolog, "SERVER_DISCONNECTED")
RegisterEvent(autolog, "START")
RegisterUserCommand("autolog", autolog.commands)
