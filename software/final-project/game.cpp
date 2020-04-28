/*
 * game.c
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "game.h"
#include "system.h"
#include "graphics.h"

// Game board is 64x64 tiles where each tile is 16x16 pixels
#define SPRITE_SIZE 16
#define ROWS 40 // 640 pix / SPRITE_SIZE
#define COLS 30 // 480 pix / SPRITE_SIZE

Game::Game(){
	// Setup board
	board = new Tile*[ROWS];
	for(int r = 0; r < ROWS; r++){
		board[r] = new Tile[COLS];
		for(int c = 0; c < COLS; c++){
			board[r][c] = TILE;
		}
	}

	// Set initial player locations
	player.x = ROWS/2;
	player.y = COLS-1;
	player.light = true;
	player.facing_x = player.x;
	player.facing_y = player.y - 1; // Face forward to begin

	// Set initial monster list
	monsters = new Monster[1]; // TODO: decide how many monsters to have
	monsters[0].x = 0;
	monsters[0].y = 0;

	// Set initial key press
	key = 0;
}

// Keycodes
#define KEYCODE_W 26
#define KEYCODE_A 4
#define KEYCODE_S 22
#define KEYCODE_D 7
#define KEYCODE_SPACE 44

// Game logic happens in update
void Game::update(int keycodes){
	//std::cout << "updating game" << std::endl;


	//Turning Light on and off
	if(key == KEYCODE_SPACE && light){
		light = 0;
	}
	else if(key == KEYCODE_SPACE && light == false){
		light = 1;
	}


	// Movement
	//light on
	if(key == KEYCODE_W && player.facing_y != WALL && player.facing_y == player.y - 1 && light){
		player.y--;
		player.facing_y--;
	}
	else if(key == KEYCODE_W && player.facing_y != player.y - 1 && light){
		player.facing_y = player.y -1;
		player.facing_x = player.x;
	}
	else if(key == KEYCODE_S && player.facing_y != WALL && player.facing_y == player.y + 1 && light){
		player.y++;
		player.facing_y++;
	}
	else if(key == KEYCODE_S && player.facing_y != player.y +1 && light){
		player.facing_y = player.y +1;
		player.facing_x = player.x;
	}
	else if(key == KEYCODE_A && play.facing_x != WALL && player.facing_x == player.x -1 && light){
		player.x--;
		player.facing_x--;
	}
	else if(key == KEYCODE_A && player.facing_x != player.x -1 && light){
		player.facing_x = player.x -1;
		player.facing_y = player.y;
	}
	else if(key == KEYCODE_D && player.facing_x != WALL && player.facing_x == player.x +1 && light){
		player.x++;
		player.facing_x++;
	}
	else if(key == KEYCODE_D && player.facing_x != player.x +1 && light){
		player.facing_x = player.x +1;
		player.facing_y = player.y;
	}


	//light off
	else if(key == KEYCODE_W && player.y - 1 != WALL && light == false){
		player.y--;
		player.facing_y = player_y -1;
	}
	else if(key == KEYCODE_S && player.y + 1 != WALL && light == false){
		player.y++;
		player.facing_y = player_y +1;
		}
	else if(key == KEYCODE_A && player.x - 1 != WALL && light == false){
		player.x--;
		player.facing_x = player_x -1;
	}
	else if(key == KEYCODE_D && player.x  +1 != WALL && light == false){
		player.x++;
		player.facing_x = player_x +1;
	}


	// Wrap-around
	if(player.y < 0){
		player.y = COLS-1;
	}
	else if(player.y > COLS-1){
		player.y = 0;
	}
	else if(player.x > ROWS-1){
		player.x = 0;
	}
	else if (player.x < 0){
		player.x = ROWS-1;
	}

	//if player on spikes = DEATH
	if (board[player.x][player.y] == SPIKES){
		//TODO: WHAT HAPPENS ON DEATH
	}
	//if player on EXIT = next level/win
	if (board[player.x][player.y] == EXIT){
		//TODO: WHAT HAPPENS ON WIN
	}

	//if player sees monster
	if (board[player.facing_x][player.facing_y] == board[monster[0].x][monster[0].y]){
		monster[0].active = 1;
	}

	//if player on same tile as monster = DEATH
	if(board[player.x][player.y] == board[monster[0].x][monster[0].y]){
		//What happens on DEATH
	}

	//Monster logic
	if(monster[0].active && light){
		monster[0].x = chasePlayer//TODO:fix when ready
	}
	if(monster[0].active == false || light == false){
		monster[0].x;
		monster[0].y;
	}

	//monster death
	if(board[monster[0].x][monster[0].y] == SPIKES){
		//TODO monster dies
	}

}

// Image IDs
#define MAIN_CHARACTER_SPRITE 0
#define TILE_SPRITE 1

// Draws all sprites where they should be
void Game::draw(){
	// For testing, draw main character
	drawImg(MAIN_CHARACTER_SPRITE, player.x*SPRITE_SIZE, player.y*SPRITE_SIZE);
}

// Pathfinding
Monster Game::chasePlayer(Monster m, Player p){
	Monster nextMonster;

	// TODO: replace
	nextMonster.x = 0;
	nextMonster.y = 0;
	return nextMonster;
}

// Key-down detector
void Game::updateKey(int keycodes){
	int key1 = keycodes & 0x0000ffff;
	int key2 = (keycodes & 0xffff0000) >> 16;

	// Ignore key2 -- we only allow one button at a time

	if(key1 == key){
		key = 0;
	}
	else {
		key = key1;
	}
}
