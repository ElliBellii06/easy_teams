local teams = {}
local config = lib.load('shared')

-- functions
local function notify(id, description, type)
    TriggerClientEvent('ox_lib:notify', id, {
        title = 'Teams',
        description = description,
        type = type,
    })
end

local function isPlayerTeamLeader(id)
    return teams[id] and true or false
end

local function isPlayerInTeam(id)
    for _, team in pairs(teams) do
        for _, member in pairs(team.members) do
            if member.id == id then
                return team
            end
        end
    end
    return false
end

local function isPlayerOnline(id)
    return GetPlayerName(id) and true or false
end

-- commands
RegisterCommand(config.commands.create, function(source)
    local src = source
    if isPlayerInTeam(src) then
        notify(src, 'You are already in a team!', 'error')
        return
    end

    teams[src] = {
        leader = src,
        isBusy = false,
        members = {
            {
                id = src,
                name = GetPlayerName(src),
            },
        },
    }
    notify(src, 'You have created a team! Use /team to open the menu', 'success')
end)

RegisterCommand(config.commands.menu, function(source)
    local src = source
    local team = isPlayerInTeam(src)
    if not team then
        notify(src, 'You are not in a team!', 'error')
        return
    end

    TriggerClientEvent('teams:mainMenu', src, team)
end)

-- event handlers
RegisterNetEvent('teams:invitePlayer', function(target)
    local src = source
    if not isPlayerTeamLeader(src) then
        notify(src, 'You are not a team leader!', 'error')
        -- modder??
        return
    end

    if not isPlayerOnline(target) then
        notify(src, 'Player is not online!', 'error')
        return
    end

    if isPlayerInTeam(target) then
        notify(src, 'Player is already in a team!', 'error')
        return
    end

    if #teams[src].members >= config.maxGroupMembers then
        notify(src, 'Your team is full!', 'error')
        return
    end

    local accepted = lib.callback.await('teams:requestMembership', target, GetPlayerName(src))
    if accepted == 'confirm' then
        table.insert(teams[src].members, {
            id = target,
            name = GetPlayerName(target),
        })
        notify(src, GetPlayerName(target) .. ' joined your team!', 'success')
        notify(target, 'You have joined ' .. GetPlayerName(src) .. '!', 'success')
    else
        notify(src, GetPlayerName(target) .. ' declined your invite!', 'error')
    end
end)

RegisterNetEvent('teams:leaveTeam', function()
    local src = source
    local team = isPlayerInTeam(src)
    if not team then return end

    if isPlayerTeamLeader(src) then
        for _, member in pairs(teams[src].members) do
            if member.id ~= src then
                notify(member.id, GetPlayerName(src) .. ' (team leader) has left the team! The team is now disbanded.', 'error')
            end
        end
        notify(src, 'You disbanded your team.', 'success')
        teams[src] = nil
    else
        for i, member in pairs(team.members) do
            if member.id == src then
                table.remove(team.members, i)
                notify(src, 'You have left your team!', 'success')
                break
            end
            notify(member.id, GetPlayerName(src) .. ' has left the team!', 'error')
        end
    end
end)

RegisterNetEvent('teams:kickMember', function(target)
    local src = source
    if not isPlayerTeamLeader(src) then
        notify(src, 'You are not a team leader!', 'error')
        -- modder??
        return
    end

    if src == target then
        notify(src, 'You cannot kick yourself!', 'error')
        return
    end

    local team = isPlayerInTeam(src)
    for i, member in pairs(team.members) do
        if member.id == target then
            table.remove(team.members, i)
            notify(src, GetPlayerName(target) .. ' has been kicked from the team!', 'success')
            notify(target, 'You have been kicked from the team!', 'error')
            break
        end
    end
end)

RegisterNetEvent('teams:triggerTeamEvent')
AddEventHandler('teams:triggerTeamEvent', function(id, eventName, ...)
    local src = id or source
    if not isPlayerTeamLeader(src) then
        notify(src, 'You are not a team leader!', 'error')
        return
    end

    if type(eventName) ~= 'string' or eventName == '' then
        notify(src, 'Invalid event name!', 'error')
        return
    end

    local team = teams[src]
    for _, member in ipairs(team.members) do
        TriggerClientEvent(eventName, member.id, ...)
    end
end)

-- diconnect handler
AddEventHandler('playerDropped', function()
    local src = source
    local team = isPlayerInTeam(src)
    if not team then return end

    if isPlayerTeamLeader(src) then
        for _, member in pairs(team.members) do
            if member.id ~= src then
                notify(member.id, GetPlayerName(src) .. ' (team leader) has left the server! The team is now disbanded.', 'error')
            end
        end
        teams[src] = nil
        print('Team disbanded because leader left the server.')
        return
    else
        for i, member in pairs(team.members) do
            if member.id == src then
                table.remove(team.members, i)
                break
            end
            notify(member.id, GetPlayerName(src) .. ' has left the server!', 'error')
        end
    end
end)

-- exports
lib.callback.register('teams:isPlayerTeamLeader', function()
    local src = source
    return isPlayerTeamLeader(src)
end)

exports('getTeamLeader', function(id)
    local team = isPlayerInTeam(id)
    if not team then return nil end
    return team.leader
end)

exports('getTeamMembers', function(id)
    if not isPlayerTeamLeader(id) then return nil end
    return teams[id].members
end)

exports('isTeamBusy', function(id)
    if not isPlayerTeamLeader(id) then return nil end
    return teams[id].isBusy
end)

exports('setTeamBusyStatus', function(id, status)
    if not isPlayerTeamLeader(id) then return nil end
    if type(status) ~= 'boolean' then return nil end
    teams[id].isBusy = status
    return teams[id].isBusy
end)
