--[[
 Hero selection module for D2E.
 This file basically just separates the functions related to hero selection from
 the other functions present in D2E.
]]

--Constant parameters
SELECTION_DURATION_LIMIT = 60

--Class definition
if HeroSelection == nil then
	HeroSelection = {}
	HeroSelection.__index = HeroSelection
end

--[[
	Start
	Call this function from your gamemode once the gamestate changes
	to pre-game to start the hero selection.
]]
function HeroSelection:Start()
	--Figure out which players have to pick
	 HeroSelection.playerPicks = {}
	 HeroSelection.numPickers = 0
	for pID = 0, DOTA_MAX_PLAYERS -1 do
		if PlayerResource:IsValidPlayer( pID ) then
			HeroSelection.numPickers = self.numPickers + 1
		end
	end

	--Start the pick timer
	HeroSelection.TimeLeft = SELECTION_DURATION_LIMIT
	Timers:CreateTimer( 0.04, HeroSelection.Tick )

	--Keep track of the number of players that have picked
	HeroSelection.playersPicked = 0

	--Listen for the pick event
	HeroSelection.listener = CustomGameEventManager:RegisterListener( "hero_selected", HeroSelection.HeroSelect )
end

--[[
	Tick
	A tick of the pick timer.
	Params:
		- event {table} - A table containing PlayerID and HeroID.
]]
function HeroSelection:Tick() 
	--Send a time update to all clients
	if HeroSelection.TimeLeft >= 0 then
		CustomGameEventManager:Send_ServerToAllClients( "picking_time_update", {time = HeroSelection.TimeLeft} )
	end

	--Tick away a second of time
	HeroSelection.TimeLeft = HeroSelection.TimeLeft - 1
	if HeroSelection.TimeLeft == -1 then
		--End picking phase
		HeroSelection:EndPicking()
		return nil
	elseif HeroSelection.TimeLeft >= 0 then
		return 1
	else
		return nil
	end
end

--[[
	HeroSelect
	A player has selected a hero. This function is caled by the CustomGameEventManager
	once a 'hero_selected' event was seen.
	Params:
		- event {table} - A table containing PlayerID and HeroID.
]]
function HeroSelection:HeroSelect( event )

	--If this player has not picked yet give him the hero
	if HeroSelection.playerPicks[ event.PlayerID ] == nil then
		HeroSelection.playersPicked = HeroSelection.playersPicked + 1
		HeroSelection.playerPicks[ event.PlayerID ] = event.HeroName

		--Send a pick event to all clients
		CustomGameEventManager:Send_ServerToAllClients( "picking_player_pick", 
			{ PlayerID = event.PlayerID, HeroName = event.HeroName} )

		--Assign the hero if picking is over
		if HeroSelection.TimeLeft <= 0 then
			HeroSelection:AssignHero( event.PlayerID, event.HeroName )
		end
	end

	--Check if all heroes have been picked
	if HeroSelection.playersPicked >= HeroSelection.numPickers then
		--End picking
		HeroSelection.TimeLeft = 0
		HeroSelection:Tick()
	end
end

--[[
	EndPicking
	The final function of hero selection which is called once the selection is done.
	This function spawns the heroes for the players and signals the picking screen
	to disappear.
]]
function HeroSelection:EndPicking()
	--Stop listening to pick events
	--CustomGameEventManager:UnregisterListener( self.listener )

	--Assign the picked heroes to all players that have picked
	for player, hero in pairs( HeroSelection.playerPicks ) do
		HeroSelection:AssignHero( player, hero )
	end

	--Signal the picking screen to disappear
	CustomGameEventManager:Send_ServerToAllClients( "picking_done", {} )
end

--[[
	AssignHero
	Assign a hero to the player. Replaces the current hero of the player
	with the selected hero, after it has finished precaching.
	Params:
		- player {integer} - The playerID of the player to assign to.
		- hero {string} - The unit name of the hero to assign (e.g. 'npc_dota_hero_rubick')
]]
function HeroSelection:AssignHero( player, hero )
	PrecacheUnitByNameAsync( hero, function()
		PlayerResource:ReplaceHeroWith( player, hero, 0, 0 )
	end, player)
end