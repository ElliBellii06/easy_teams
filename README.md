# Easy Teams

A standalone team management script for FiveM servers. Players can create teams using the `/createteam` command, becoming the team leader. Access the context menu with `/team` to view members, invite players, kick members or leave the team.

## Client Exports
```lua
local leader = exports['easy_teams']:isTeamLeader()
print(leader)
```

## Server Exports
```lua
local leader = exports['easy_teams']:getTeamLeader(source)
print(leader)
```
```lua
local members = exports['easy_teams']:getTeamMembers(source)
print(json.encode(members))
```
```lua
local busy = exports['easy_teams']:isTeamBusy(source)
print(busy)
```
```lua
local busy = exports['easy_teams']:setTeamBusyStatus(source, status)
print(busy)
```

## Server Events
```lua
TriggerEvent('teams:triggerTeamEvent', source, eventName, ...)
```

## Dependencies
- [ox_lib](<https://github.com/overextended/ox_lib/releases>)
