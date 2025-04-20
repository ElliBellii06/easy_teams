-- main menu
RegisterNetEvent('teams:mainMenu')
AddEventHandler('teams:mainMenu', function(team)
    lib.registerContext({
        id = 'teams:mainMenu',
        title = 'Team',
        options = {
            {
                title = 'Team Members',
                icon = 'users',
                description = 'View team members',
                onSelect = function()
                    TriggerEvent('teams:membersMenu', team)
                end,
            },
            {
                title = 'Invite Player',
                icon = 'user-plus',
                description = 'Invite a player to your team',
                disabled = not (team.leader == GetPlayerServerId(PlayerId())) or team.isBusy,
                onSelect = function()
                    local input = lib.inputDialog('Invite Player', {
                        { type = 'number', label = 'Player ID', icon = 'user', required = true },
                    })
                    if not input then return end
                    TriggerServerEvent('teams:invitePlayer', input[1])
                end,
            },
            {
                title = 'Leave Team',
                icon = 'right-from-bracket',
                description = 'Leave your team',
                disabled = team.isBusy,
                onSelect = function()
                    if team.leader == GetPlayerServerId(PlayerId()) then
                        local alert = lib.alertDialog({
                            header = 'You are the team leader!',
                            content = 'If you choose to leave, the team will be disbanded, and everyone will be kicked. Are you sure?',
                            centered = true,
                            cancel = true,
                        })
                        if alert == 'cancel' then return end
                    end
                    TriggerServerEvent('teams:leaveTeam')
                end,
            },
        },
    })
    lib.showContext('teams:mainMenu')
end)

--  members menu
AddEventHandler('teams:membersMenu', function(team)
    local options = {}

    if #team.members > 0 then
        for _, member in pairs(team.members) do
            table.insert(options, {
                title = member.name .. ' (' .. member.id .. ')',
                icon = 'user',  
                description = 'Click to kick this member',
                disabled = not (team.leader == GetPlayerServerId(PlayerId())) or team.isBusy,
                onSelect = function()
                    TriggerServerEvent('teams:kickMember', member.id)
                end,
            })
        end 
    else
        table.insert(options, {
            title = 'No members in this team',
            icon = 'exclamation',
            disabled = true,
        })
    end

    lib.registerContext({
        id = 'teams:membersMenu',
        title = 'Team Members (' .. #team.members .. ')',
        menu = 'teams:mainMenu',
        options = options
    })
    lib.showContext('teams:membersMenu')
end)

-- callbacks
lib.callback.register('teams:requestMembership', function(name)
    local alert = lib.alertDialog({
        header = 'Team Invitation!',
        content = 'Do you want to join ' .. name .. '?',
        centered = true,
        cancel = true,
    })
    return alert
end)

--  exports
exports('isTeamLeader', function()
	return lib.callback.await('teams:isPlayerTeamLeader', false)
end)