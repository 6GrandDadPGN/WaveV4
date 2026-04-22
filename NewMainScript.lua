local _args = ...
local _isPaidUser = type(_args) == 'table' and _args.Username and _args.Password
getgenv().AeroLocalPaid = _isPaidUser and true or false
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/6GrandDadPGN/WaveV4/'..readfile('vaperewrite/profiles/commit.txt')..'/'..select(1, path:gsub('vaperewrite/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'vaperewrite', 'vaperewrite/games', 'vaperewrite/profiles', 'vaperewrite/assets', 'vaperewrite/libraries', 'vaperewrite/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

local function downloadPremadeProfiles(commit)
    local httpService = game:GetService('HttpService')
    
    if isfolder('vaperewrite/profiles/premade') then
        for _, file in listfiles('vaperewrite/profiles/premade') do
            pcall(function()
                if isfile(file) then
                    delfile(file)
                end
            end)
        end
    else
        makefolder('vaperewrite/profiles/premade')
    end

    local success, response = pcall(function()
        return game:HttpGet('https://api.github.com/repos/6GrandDadPGN/WaveV4/contents/profiles/premade?ref=' .. commit)
    end)

    if success and response then
        local ok, files = pcall(function()
            return httpService:JSONDecode(response)
        end)

        if ok and type(files) == 'table' then
            for _, file in pairs(files) do
                if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                    local filePath = 'vaperewrite/profiles/premade/' .. file.name
                    local dl = file.download_url or ('https://raw.githubusercontent.com/6GrandDadPGN/WaveV4/' .. commit .. '/profiles/premade/' .. file.name)
                    local ds, dc = pcall(function()
                        return game:HttpGet(dl, true)
                    end)
                    if ds and dc and dc ~= '404: Not Found' then
                        writefile(filePath, dc)
                    end
                end
            end
        end
    end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/6GrandDadPGN/WaveV4')
	end)

	local commit = 'main'
	local ok, res = pcall(function()
		return game:HttpGet('https://api.github.com/repos/6GrandDadPGN/WaveV4/commits/main', true)
	end)

	if ok and res then
		local h = res:match('"sha":"([a-f0-9]+)"')
		if h and #h == 40 then
			commit = h
		end
	end

	if commit == 'main' or (isfile('vaperewrite/profiles/commit.txt') and readfile('vaperewrite/profiles/commit.txt') or '') ~= commit then
		wipeFolder('vaperewrite')
		wipeFolder('vaperewrite/games')
		wipeFolder('vaperewrite/guis')
		pcall(function()
			if isfile('vaperewrite/guis/new.lua') then
				delfile('vaperewrite/guis/new.lua')
			end
		end)
		wipeFolder('vaperewrite/libraries')
		if isfolder('vaperewrite/profiles/premade') then
			for _, file in listfiles('vaperewrite/profiles/premade') do
				pcall(function()
					if isfile(file) then
						delfile(file)
					end
				end)
			end
		end
	end

	pcall(downloadPremadeProfiles, commit)
	writefile('vaperewrite/profiles/commit.txt', commit)

	pcall(function()
		if isfile('vaperewrite/profiles/paid_accounts.txt') then
			delfile('vaperewrite/profiles/paid_accounts.txt')
		end
	end)

	pcall(function()
		if isfile('vaperewrite/profiles/paid_accounts.txt') then
			delfile('vaperewrite/profiles/paid_accounts.txt')
		end
	end)
	local paidSuc, paidRes = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/6GrandDadPGN/whitelistcheck/main/WhitelistAcc.json', true)
	end)
	if paidSuc and paidRes and paidRes ~= '404: Not Found' then
		local jsonService = game:GetService('HttpService')
		local ok, data = pcall(function()
			return jsonService:JSONDecode(paidRes)
		end)
		if ok and data and data.accounts then
			local lines = {}
			for _, entry in data.accounts do
				if type(entry) == 'table' and entry.id and entry.tier then
					if tonumber(entry.id) and tonumber(entry.id) ~= 0 then
						table.insert(lines, tostring(entry.id) .. ':' .. tostring(entry.tier))
					end
				end
			end
			if #lines > 0 then
				writefile('vaperewrite/profiles/paid_accounts.txt', table.concat(lines, '\n'))
			end
		end
	end
end

return loadstring(downloadFile('vaperewrite/main.lua'), 'main')({
    Username = shared.ValidatedUsername,
    Password = args and args.Password or nil
})
