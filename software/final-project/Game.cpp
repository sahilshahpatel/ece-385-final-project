/*
 * Game.cpp
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "Game.h"

#include "usb_hid_keys.h"
#include "graphics.h"
#include <stdio.h>

// For pathfinding
#include <queue>
#include <map>

// For sorting leaderboard
#include <algorithm>

// Because to_string is broken
#include <sstream>

using std::priority_queue;
using std::pair;

// Game board is 64x64 tiles where each tile is 16x16 pixels
#define TILE_SIZE 32
#define COLS 20 // 640 pixels / TILE_SIZE
#define ROWS 15 // 480 pixels / TILE_SIZE

#define NUM_LEVELS 5

Game::Game() :
gameState(START),
light(true),
level(1),
dead(false),
next(false),
lastLightOffTime(clock()),
deathCounter(0),
levelStartTime(clock()),
totalTime(0),
prev_key(0),
key(0)
{
	// Allocate board
	board = new Tile*[COLS];
	for(int x = 0; x < COLS; x++){
		board[x] = new Tile[ROWS];
		for(int y = 0; y < ROWS; y++){
			board[x][y] = WALL;
		}
	}

	// Draw loading screen
	swapFrameBuffers(); // Prevents some glitches when SRAM has old frame info on reset
	drawScreen(TITLE_SCREEN_SPRITE);
	drawString("Connecting Keyboard...", 9, 26);
	swapFrameBuffers();

}

void Game::reset(){
	playerName = "";
	totalTime = 0;
	level = 1;
	deathCounter = 0;
}

Game::~Game(){
	// Delete board
	for(int x = 0; x < COLS; x++){
		delete[] board[x];
	}
	delete[] board;
}

// Game logic happens in update
void Game::update(int keycodes){
	clock_t time = clock();

	updateKey(keycodes); // Update the current key (handles on-key-down behavior)

	if(gameState == POST_GAME){
		playerNameInput(key);
	}
	else{
		handleInput(key); // Toggles light, moves player, continues through menu
	}

	if(gameState == IN_GAME){
		if(dead || next) return; // Don't update if in menu screen

		if(!validPos(player.x, player.y))
			printf("Invalid player pos: %d, %d\n", player.x, player.y);

		// If player is on spikes, they die
		if (board[player.x][player.y] == SPIKES){
			totalTime += (float)(time - levelStartTime)/CLOCKS_PER_SEC;
			dead = true;
		}

		// If player is on EXIT, they win the level
		if (board[player.x][player.y] == STAIRS){
			totalTime += (float)(time - levelStartTime)/CLOCKS_PER_SEC;
				next = true;
		}


		// Monster logic
		for(uint i = 0; i < monsters.size(); i++){
			if(!validPos(monsters[i].x, monsters[i].y))
				printf("Invalid monster pos: %d, %d\n", monsters[i].x, monsters[i].y);

			// Ignore dead monsters
			if(monsters[i].alive == false) continue;

			// If player sees a monster for the first time, it activates
			if (monsters[i].active == false && player.facing_x == monsters[i].x && player.facing_y == monsters[i].y){
				monsters[i].active = true;
				monsters[i].last_move_time = time;
			}

			// If player is on the same tile as a monster, they die
			if (player.x == monsters[i].x && player.y == monsters[i].y){
				totalTime += (float)(time - levelStartTime)/CLOCKS_PER_SEC;
				dead = true;
			}

			// Active monsters chase player if light is on
			if(time - monsters[i].last_move_time > CLOCKS_PER_SEC && light && monsters[i].active){
				pair<int, int> next_coord = findPath(monsters[i], player);
				monsters[i].x = next_coord.first;
				monsters[i].y = next_coord.second;
				monsters[i].last_move_time = time;
			}

			// If a monster is on spikes, it dies
			if(board[monsters[i].x][monsters[i].y] == SPIKES){
				monsters[i].alive = false;
				monsters[i].active = false;
			}
		}
	}
}

void Game::draw(){
	switch(gameState){
	case START:
		drawStart();
		break;
	case LEADERBOARD:
		drawLeaderboard();
		break;
	case IN_GAME:
		drawLevel();
		break;
	case POST_GAME:
		drawPostGame();
		break;
	}
	swapFrameBuffers(); // Graphics function
}

void Game::drawStart(){
	drawString("Press ESC to view leaderboard", 6, 4);
	drawScreen(TITLE_SCREEN_SPRITE);
	drawString("Press SPACE to begin", 10, 25);

	// Draw movement controls
	drawImg(MOVEMENT_CONTROLS_SPRITE_0, 5*TILE_SIZE, 13.5*TILE_SIZE);
	drawImg(MOVEMENT_CONTROLS_SPRITE_1, 6*TILE_SIZE, 13.5*TILE_SIZE);

	// Draw light controls
	drawImg(LIGHT_CONTROLS_SPRITE_0, 13*TILE_SIZE, 13.5*TILE_SIZE);
	drawImg(LIGHT_CONTROLS_SPRITE_1, 14*TILE_SIZE, 13.5*TILE_SIZE);
}

void Game::drawLeaderboard(){
	// Create leaderboard string
	std::stringstream ss;
	ss.precision(1);
	for(uint i = 0; i < leaderboard.size(); i++){
		ss << leaderboard.at(i).second << "     " << std::fixed << leaderboard.at(i).first << std::endl;
	}

	// Draw leaderboard table
	drawString("Press ESC to exit leaderboard", 6, 4);
	drawString("Name    Time", 14, 10); // Headings
	drawString(ss.str(), 14, 12); // Values
}

// Draws all sprites where they should be
void Game::drawLevel(){
	if(dead == false && next == false){
		// Draw current timer
		std::stringstream ss;
		ss.precision(1); // Draws one digit after the decimal
		ss << "Time: " << std::fixed << (float)(clock() - levelStartTime)/CLOCKS_PER_SEC;
		drawString(ss.str(), 1, 1);

		// Draw tiles only if light is on
		if(light){
			// Draw tile player is on
			drawImg(spriteFromTile(board[player.x][player.y]), player.x*TILE_SIZE, player.y*TILE_SIZE);

			// Draw tile player is facing
			if(validPos(player.facing_x, player.facing_y))
				drawImg(spriteFromTile(board[player.facing_x][player.facing_y]), player.facing_x*TILE_SIZE, player.facing_y*TILE_SIZE);
		}

		// Draw monsters if applicable
		for(uint i = 0; i < monsters.size(); i++){
			Monster& m = monsters[i];
			if(m.active){
				if(light && player.facing_x == m.x && player.facing_y == m.y)
					drawImg(MONSTER_LIGHT_SPRITE, m.x*TILE_SIZE, m.y*TILE_SIZE);
				else
					drawImg(MONSTER_DARK_SPRITE, m.x*TILE_SIZE, m.y*TILE_SIZE);
			}
			else if(m.alive == false){
				// If dead, draw both monster and tile below
				drawImg(spriteFromTile(board[m.x][m.y]), m.x*TILE_SIZE, m.y*TILE_SIZE);
				drawImg(MONSTER_DEAD_SPRITE, m.x*TILE_SIZE, m.y*TILE_SIZE);
			}
		}

		// Draw player with or without candle
		if(light){
			drawImg(PLAYER_LIGHT_SPRITE, player.x*TILE_SIZE, player.y*TILE_SIZE);
		}
		else{
			drawImg(PLAYER_DARK_SPRITE, player.x*TILE_SIZE, player.y*TILE_SIZE);
		}
	}

	//if player dies draw game over screen
	else if(dead){
		drawString("Your light fades!", 11, 12);
		drawString("Press SPACE to restart the level", 4, 17);
	}
	//if player draw next level //40x30
	else if(next){
		std::stringstream ss;
		ss << "You beat level " << level;
		drawString(ss.str(), 12, 12);

		drawImg(SKULL_SPRITE, 9*TILE_SIZE, 7*TILE_SIZE);

		std::stringstream ss2;
		ss2 << " " << deathCounter;
		drawString(ss2.str(), 20, 14);

		drawString("Press SPACE to go on", 10, 17);
	}
}

void Game::drawPostGame(){
	drawString("Congratulations player!", 8, 6);
	drawString("You have beaten back the dark", 5, 7);
	drawString("Enter your initials: " + playerName, 8, 12);
	drawString("Press ENTER to submit and continue", 3, 17);
}

/* Helper functions */

void Game::handleInput(int key){
	switch(key){
	case KEY_SPACE: // Toggle light
		if(gameState == START){
			setupLevel();
			gameState = IN_GAME;
		}
		else if(gameState == IN_GAME){
			if(dead == false && next == false){
				if(light){
					// Record time when light was switched off
					lastLightOffTime = clock();
				}
				else{
					// Update monster lastMoveTimes to reflect time with light off
					clock_t time = clock();
					for(uint i = 0; i < monsters.size(); i++){
						monsters[i].last_move_time += time - lastLightOffTime;
					}
				}
				light = !light;
			}
			else if(next){
				if(level == NUM_LEVELS){
					gameState = POST_GAME;
				}
				else {
					level++;
					setupLevel();
				}
			}
			else if(dead){
				deathCounter++;
				setupLevel();
			}
		}
		break;
	case KEY_W: // Move up
		if(canMove(player, player.x, player.y - 1)){
			player.y--;
		}
		player.facing_y = player.y - 1;
		player.facing_x = player.x;
		break;
	case KEY_S: // Move down
		if(canMove(player, player.x, player.y + 1)){
			player.y++;
		}
		player.facing_y = player.y + 1;
		player.facing_x = player.x;
		break;
	case KEY_A: // Move left
		if(canMove(player, player.x - 1, player.y)){
			player.x--;
		}
		player.facing_y = player.y;
		player.facing_x = player.x - 1;
		break;
	case KEY_D: // Move right
		if(gameState == IN_GAME){
			if(canMove(player, player.x + 1, player.y)){
				player.x++;
			}
			player.facing_y = player.y;
			player.facing_x = player.x + 1;
		}
		break;
	case KEY_ESC:
		if(gameState == START){
			gameState = LEADERBOARD;
		}
		else if(gameState == LEADERBOARD){
			gameState = START;
		}
		break;
	}
}

// Validate movements
bool Game::canMove(Player p, int dest_x, int dest_y) const{
	//if player won or died, deny
	if(dead || next) return false;
	// If moving out of bounds, deny
	if(!validPos(dest_x, dest_y)) return false;

	// If moving to a wall, deny
	if(board[dest_x][dest_y] == WALL) return false;

	if(light){
		// If light is on, must be facing destination
		return dest_y == player.facing_y && dest_x == player.facing_x;
	}
	else{
		// If light is off, facing doesn't matter
		return true;
	}
}

bool Game::validPos(int x, int y) const{
	return x < COLS && x >= 0 && y < ROWS && y >= 0;
}

bool Game::validPos(pair<int, int> p) const{
	return validPos(p.first, p.second);
}


void Game::playerNameInput(int key){
	switch(key){
	case KEY_BACKSPACE:
		// Delete last character of playerName
		if(playerName.length() > 0)
			playerName = playerName.substr(0, playerName.length() - 1);
		break;
	case KEY_ENTER:
		// If they've entered 3 characters, move on
		if(playerName.length() == 3){
			leaderboard.push_back(pair<float, string>(totalTime, playerName));
			std::sort(leaderboard.begin(), leaderboard.end());
			reset();
			gameState = LEADERBOARD;
		}
		break;
	case KEY_A:
		appendToPlayerName('A');
		break;
	case KEY_B:
		appendToPlayerName('B');
		break;
	case KEY_C:
		appendToPlayerName('C');
		break;
	case KEY_D:
		appendToPlayerName('D');
		break;
	case KEY_E:
		appendToPlayerName('E');
		break;
	case KEY_F:
		appendToPlayerName('F');
		break;
	case KEY_G:
		appendToPlayerName('G');
		break;
	case KEY_H:
		appendToPlayerName('H');
		break;
	case KEY_I:
		appendToPlayerName('I');
		break;
	case KEY_J:
		appendToPlayerName('J');
		break;
	case KEY_K:
		appendToPlayerName('K');
		break;
	case KEY_L:
		appendToPlayerName('L');
		break;
	case KEY_M:
		appendToPlayerName('M');
		break;
	case KEY_N:
		appendToPlayerName('N');
		break;
	case KEY_O:
		appendToPlayerName('O');
		break;
	case KEY_P:
		appendToPlayerName('P');
		break;
	case KEY_Q:
		appendToPlayerName('Q');
		break;
	case KEY_R:
		appendToPlayerName('R');
		break;
	case KEY_S:
		appendToPlayerName('S');
		break;
	case KEY_T:
		appendToPlayerName('T');
		break;
	case KEY_U:
		appendToPlayerName('U');
		break;
	case KEY_V:
		appendToPlayerName('V');
		break;
	case KEY_W:
		appendToPlayerName('W');
		break;
	case KEY_X:
		appendToPlayerName('X');
		break;
	case KEY_Y:
		appendToPlayerName('Y');
		break;
	case KEY_Z:
		appendToPlayerName('Z');
		break;
	}
}

void Game::appendToPlayerName(char c){
	if(playerName.length() < 3){
		playerName += c;
	}
}

/* Use BFS to find path */
pair<int, int> Game::findPath(Monster m, Player p) const{
	return findPath(m.x, m.y, p.x, p.y);
}

pair<int, int> Game::findPath(int x0, int y0, int dest_x, int dest_y) const{
	// Assume valid input for speed

	pair<int, int> start(x0, y0);
	pair<int, int> end(dest_x, dest_y);

	if(start == end) return start;

	std::queue<pair<int, int> > search;
	std::map<pair<int, int>, pair<int, int> > parent;

	search.push(start);
	parent.insert(std::make_pair(start, start)); // Marks start as visited

	//printf("Pathfinding from %d, %d to %d, %d\n", x0, y0, dest_x, dest_y);

	while(!search.empty()){
		pair<int, int> current = search.front();
		search.pop();

		//printf("Checking %d, %d\n", current.first, current.second);

		// Check if we have reached end
		if(current == end){
			// Look through parents to find first element of path
			while(parent.at(current) != start){
				current = parent.at(current);
			}
			return current;
		}

		// Add valid neighbors to queue
		vector<pair<int, int> > neighbors;
		neighbors.push_back(pair<int, int>(current.first - 1, current.second));
		neighbors.push_back(pair<int, int>(current.first + 1, current.second));
		neighbors.push_back(pair<int, int>(current.first, current.second - 1));
		neighbors.push_back(pair<int, int>(current.first, current.second + 1));

		for(uint i = 0; i < neighbors.size(); i++){
			pair<int, int> next = neighbors[i];
			if(parent.find(next) == parent.end() && validPos(next) && board[next.first][next.second] != WALL){
				//printf("Adding neighbor %d, %d\n", next.first, next.second);
				search.push(next);
				parent.insert(std::make_pair(next, current));
			}
		}
	}

	// If we reached here, a path doesn't exist. Return starting pos
	return start;
}

std::pair<int, int> Game::spriteFromTile(Tile tile){
	switch(tile){
	case TILE: return TILE_SPRITE;
	case WALL: return WALL_SPRITE;
	case SPIKES: return SPIKES_SPRITE;
	case STAIRS: return STAIRS_SPRITE;
	default: return TILE_SPRITE;
	}
}

// Key-down detector
void Game::updateKey(int keycodes){
	int key1 = keycodes & 0x0000ffff;
	//int key2 = (keycodes & 0xffff0000) >> 16;
	// Ignore key2 -- we only allow one button at a time

	// TODO: If we do animations, it would be nice to allow
	//	the user to hold down a key and have it activate every time
	//	an animation finishes. To do this we can get rid of this
	// "on-key-down" behavior and add a lockout time during animations!

	if(key1 == prev_key) key = 0;
	else key = key1;

	prev_key = key1;
}

void Game::setupLevel(){
	// Reset game state
	dead = false;
	light = true;
	next = false;
	monsters.clear();
	levelStartTime = clock();

	// Set initial board to all walls
	for(int x = 0; x < COLS; x++){
		for(int y = 0; y < ROWS; y++){
			board[x][y] = WALL;
		}
	}

	// Switch case for level
	switch(level){
	case 1:
		// Player is at 6, 13
		board[6][13] = TILE;
		player = Player(6, 13);

		// Monster is at 6, 9
		board[6][9] = TILE;
		monsters.push_back(Monster(6, 9));

		// Spikes at 6, 11
		board[6][11] = SPIKES;

		// Exit at 5, 7
		board[6][7] = TILE;
		board[5][7] = STAIRS;

		// Create rest of tile path
		board[6][12] = TILE;
		board[7][12] = TILE;
		board[8][12] = TILE;
		board[8][11] = TILE;
		board[8][10] = TILE;
		board[7][10] = TILE;
		board[6][10] = TILE;
		board[6][8]  = TILE;
		break;
	case 2:
		// player starts at 13,8
		board[13][8] = TILE;
		player = Player(13,8);

		//Monster at 8,10
		board[8][10] = TILE;
		monsters.push_back(Monster(8,10));

		//Spikes at 11,8
		board[11][8] = SPIKES;

		//EXIT at 5,10
		board[5][10] = STAIRS;

		//Create rest of tile path;
		board[12][8] = TILE;
		board[12][9] = TILE;
		board[11][5] = TILE;
		board[11][6] = TILE;
		board[11][7] = TILE;
		board[11][9] = TILE;
		board[11][10] = TILE;
		board[10][5] = TILE;
		board[10][7] = TILE;
		board[10][10] = TILE;
		board[9][5] = TILE;
		board[9][6] = TILE;
		board[9][7] = TILE;
		board[9][8] = TILE;
		board[9][9] = TILE;
		board[9][10] = TILE;
		board[7][10] = TILE;
		board[6][10] = TILE;
		break;

	case 3:
		// player starts at 9,9
		board[9][9] = TILE;
		player = Player(9,9);

		//Monsters at 9,5 12,2 13,6 and 15,3
		board[9][5] = TILE;
		board[12][2] = TILE;
		board[13][6] = TILE;
		board[15][3] = TILE;
 		monsters.push_back(Monster(9,5));
		monsters.push_back(Monster(12,2));
		monsters.push_back(Monster(13,6));
		monsters.push_back(Monster(15,3));

		//EXIT at 13,1
		board[14][1] = TILE;
		board[13][1] = STAIRS;


		//Create rest of tile path;
		board[9][8] = TILE;
		board[9][7] = TILE;
		board[9][6] = TILE;
		board[10][6] = TILE;
		board[11][6] = TILE;
		board[12][6] = TILE;
		board[12][5] = TILE;
		board[12][4] = TILE;
		board[12][3] = TILE;
		board[13][3] = TILE;
		board[14][3] = TILE;
		board[14][2] = TILE;
		break;

	case 4:
		// player starts at 3,6
		board[3][6] = TILE;
		player = Player(3,6);

		//Monsters at 8,8 and 11,3
		board[8][8] = TILE;
		board[11][3] = TILE;
		monsters.push_back(Monster(8,8));
		monsters.push_back(Monster(11,3));

		//Spikes at 5,6 and 10,3
		board[5][6] = SPIKES;
		board[10][3] = SPIKES;
		board[10][4] = SPIKES;

		//EXIT at 13,2
		board[13][2] = TILE;
		board[13][1] = TILE;
		board[12][1] = STAIRS;

		//Create rest of tile path;
		board[4][6] = TILE;
		board[4][7] = TILE;
		board[5][3] = TILE;
		board[5][4] = TILE;
		board[5][5] = TILE;
		board[5][7] = TILE;
		board[5][8] = TILE;
		board[6][3] = TILE;
		board[6][5] = TILE;
		board[6][8] = TILE;
		board[7][3] = TILE;
		board[7][4] = TILE;
		board[7][5] = TILE;
		board[7][6] = TILE;
		board[7][7] = TILE;
		board[7][8] = TILE;
		board[8][4] = TILE;
		board[9][3] = TILE;
		board[9][4] = TILE;
		board[9][5] = TILE;
		board[10][5] = TILE;
		board[11][5] = TILE;
		board[11][4] = TILE;
		board[12][3] = TILE;
		board[13][3] = TILE;
		break;
	case 5:
		// player starts at 9,6
		board[9][6] = TILE;
		player = Player(9,6);

		//Monsters at 15,3 4,4 10,13
		board[15][3] = TILE;
		board[4][4] = TILE;
		board[10][13] = TILE;

		monsters.push_back(Monster(15,3));
		monsters.push_back(Monster(4,4));
		monsters.push_back(Monster(10,13));


		//EXIT at 3,4
		board[3][4] = STAIRS;

		//Spikes at 8,5 10,5 8,7 10,7 5,7 12,3 8,8 8,9 7,10 7,11 7,12 8,13 9,12 10,7 10,8 10,9 11,10 11,11 11,12
		board[8][5] = SPIKES;
		board[10][5] = SPIKES;
		board[8][7] = SPIKES;
		board[10][7] = SPIKES;
		board[5][7] = SPIKES;
		board[12][3] = SPIKES;
		board[8][8] = SPIKES;
		board[8][9] = SPIKES;
		board[7][10] = SPIKES;
		board[7][11] = SPIKES;
		board[7][12] = SPIKES;
		board[8][13] = SPIKES;
		board[9][12] = SPIKES;
		board[10][7] = SPIKES;
		board[10][8] = SPIKES;
		board[10][9] = SPIKES;
		board[11][10] = SPIKES;
		board[11][11] = SPIKES;
		board[11][12] = SPIKES;

		//Create rest of tile path;
		board[9][5] = TILE;
		board[9][4] = TILE;
		board[9][3] = TILE;
		board[9][2] = TILE;
		board[10][2] = TILE;
		board[11][2] = TILE;
		board[12][2] = TILE;
		board[13][2] = TILE;
		board[14][2] = TILE;
		board[15][2] = TILE;
		board[13][3] = TILE;
		board[13][4] = TILE;
		board[13][6] = TILE;
		board[14][6] = TILE;
		board[15][7] = TILE;
		board[14][7] = TILE;
		board[16][7] = TILE;
		board[16][8] = TILE;
		board[12][4] = TILE;
		board[12][6] = TILE;
		board[11][3] = TILE;
		board[11][4] = TILE;
		board[11][6] = TILE;
		board[10][6] = TILE;
		board[10][10] = TILE;
		board[10][11] = TILE;
		board[10][12] = TILE;
		board[9][7] = TILE;
		board[9][8] = TILE;
		board[9][9] = TILE;
		board[9][10] = TILE;
		board[9][11] = TILE;
		board[8][6] = TILE;
		board[8][6] = TILE;
		board[8][10] = TILE;
		board[8][11] = TILE;
		board[8][12] = TILE;
		board[7][6] = TILE;
		board[6][4] = TILE;
		board[6][5] = TILE;
		board[6][6] = TILE;
		board[6][7] = TILE;
		board[6][8] = TILE;
		board[5][4] = TILE;
		board[5][6] = TILE;
		board[5][8] = TILE;
		board[4][6] = TILE;
		board[4][7] = TILE;
		board[4][8] = TILE;
		break;
	}
}
