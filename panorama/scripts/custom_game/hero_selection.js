"use strict";
/* This file contains the scripts associated with hero_selection.xml.
 * This UI element provides a custom hero selection screen.
 *
 * By: Perry
 * Date: July 2015 */

//Define variables
var playerPanels = {};
var canEnter = false;

//Subscribe to events
GameEvents.Subscribe( "picking_done", OnPickingDone );
GameEvents.Subscribe( "picking_time_update", OnTimeUpdate );
GameEvents.Subscribe( "picking_player_pick", OnPlayerPicked );

/* Event Handlers
=========================================================================*/

/* Picking phase is done, allow the player to enter the game */
function OnPickingDone( data ) {
	$("#EnterGameBtn").RemoveClass( "disabled" );
	$("#EnterGameBtnTxt").text = "Enter Game";
	canEnter = true;
}

/* Visual timer update */
function OnTimeUpdate( data ) {
	$("#TimerTxt").text = data.time;
}

/* A player has picked a hero */
function OnPlayerPicked( data ) {
	PlayerPicked( data.PlayerID, data.HeroName );
}

/* Functionality
=========================================================================*/

/* Add an empty element for each player in the game (steam avatar plus space for hero portrait) */
function LoadPlayers() {
	//Get the players for both teams
	var radiantPlayers = Game.GetPlayerIDsOnTeam( DOTATeam_t.DOTA_TEAM_GOODGUYS );
	var direPlayers = Game.GetPlayerIDsOnTeam( DOTATeam_t.DOTA_TEAM_BADGUYS );

	//Assign radiant players
	$.Each( radiantPlayers, function( player ) {
		var playerPanel = Modular.Spawn( "picking_player", $("#LeftPlayers") );
		playerPanel.SetPlayer( player );

		//Save the panel for later
		playerPanels[player] = playerPanel;
	});

	//Assign dire players
	$.Each( direPlayers, function( player ) {
		var playerPanel = Modular.Spawn( "picking_player", $("#RightPlayers") );
		playerPanel.SetPlayer( player );
		playerPanel.SetIsRight( true );

		//Save the panel for later
		playerPanels[player] = playerPanel;
	});
}

/* A player has picked a hero, tell the player's panel a hero was picked,
 * show the hero was taken and if the player that picked is the local player
 * swap to the hero preview screen. */
function PlayerPicked( player, hero ) {
	//Update the player panel
	playerPanels[player].SetHero( hero );

	//Disable the hero button
	$('#'+hero).AddClass( "taken" );

	//Check if the pick was by the local player
	if ( player == Players.GetLocalPlayer() ) {
		SwitchToHeroPreview( hero );
	}
}

/* Switch the content of the screen to show the picked hero instead of the
 * pickable heroes. */
function SwitchToHeroPreview( heroName ) {
	var previewPanel = $.CreatePanel("Panel", $('#PostPickScreen'), "HeroPreview");
	previewPanel.BLoadLayoutFromString('<root><Panel><DOTAScenePanel style="width: 600px; height: 600px; opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" unit="'+heroName+'"/></Panel></root>', false, false );

	$('#PostPickScreen').MoveChildBefore( previewPanel, $("#EnterGameBtn") );

	$('#PickList').style.visibility = 'collapse';
	$('#PostPickScreen').style.visibility = 'visible';
}

/* Select a hero, called when a player clicks a hero panel in the layout */
function SelectHero( heroName ) {
	//Send the pick to the server
	GameEvents.SendCustomGameEventToServer( "hero_selected", { HeroName: heroName } );
}

/* Enter the game by removing the picking screen, called when the player
 * clicks a button in the layout. */
function EnterGame() {
	if ( canEnter ) {
		$('#PickingScreen').DeleteAsync( 0.0 );
	}
}

/* Initialisation - runs when the element is created
=========================================================================*/
(function () {
	//Set panel visibility
	$('#PickList').style.visibility = 'visible';
	$('#PostPickScreen').style.visibility = 'collapse';

	///Load player elements
	LoadPlayers();
})();