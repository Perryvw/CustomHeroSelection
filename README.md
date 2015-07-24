# CustomHeroSelection
Custom hero selection in Panorama/Lua for Dota 2 custom games

The screen is visible by default as soon as the player gets ingame. To use this successfully use this first force a default hero: 

```lua
GameRules:GetGameModeEntity():SetCustomGameForceHero( "npc_dota_hero_jakiro" )
```

Then listen for the game_rules_state_change event and to the handler add:

```lua
if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		HeroSelection:Start()
```
