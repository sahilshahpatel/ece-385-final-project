/*
 * Game.cpp
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "Game.h"

#include "graphics.h"
#include <stdio.h>
#include <queue>
#include <map>

#include <sstream>

using std::priority_queue;
using std::pair;

// Game board is 64x64 tiles where each tile is 16x16 pixels
#define TILE_SIZE 32
#define COLS 20 // 640 pix / TILE_SIZE
#define ROWS 15 // 480 pix / TILE_SIZE

#define NUM_LEVELS 3

Game::Game() :
gameState(START),
level(1),
win(false),
dead(false),
next(false),
levelStartTime(clock()),
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

Game::~Game(){
	// Delete board
	for(int x = 0; x < COLS; x++){
		delete[] board[x];
	}
	delete[] board;
}

// Keycodes
#define KEYCODE_W 26
#define KEYCODE_A 4
#define KEYCODE_S 22
#define KEYCODE_D 7
#define KEYCODE_SPACE 44

// Game logic happens in update
void Game::update(int keycodes){
	clock_t time = clock();

	updateKey(keycodes); // Update the current key (handles on-key-down behavior)

	handleInput(key); // Toggles light, moves player, continues through menu

	if(gameState == IN_GAME){
		if(dead || next || win) return; // Don't update if in menu screen

		if(!validPos(player.x, player.y))
			printf("Invalid player pos: %d, %d\n", player.x, player.y);

		// If player is on spikes, they die
		if (board[player.x][player.y] == SPIKES){
			dead = true;
		}

		// If player is on EXIT, they win the level
		if (board[player.x][player.y] == STAIRS){
			if(level == NUM_LEVELS){
				win = true;
			}
			else{
				next = true;
			}
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
				// TODO: increment score counter
			}
		}
	}
}

void Game::draw(){
	switch(gameState){
	case START:
		drawStart();
		break;
	case IN_GAME:
		drawLevel();
		break;
	default:
		drawStart();
		break;
	}
	swapFrameBuffers(); // Graphics function
}

void Game::drawStart(){
	drawScreen(TITLE_SCREEN_SPRITE);
	// TODO: Draw controls
	drawString("Press SPACE to begin", 10, 26);
}

// Draws all sprites where they should be
void Game::drawLevel(){
	if(dead == false && win == false && next == false){
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
				if(light)
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
		drawString("GAME OVER", 15, 12);
		drawString("Press SPACE to RESTART", 9, 17);
	}
	//if player draw next level //40x30 //TODO add Score
	else if(next){
		std::stringstream ss;
		ss << "You beat level " << level;
		drawString(ss.str(), 12, 12);
		drawString("Press SPACE to go on", 9, 17);
	}
	else if(win){
		drawString("YOU ARE SO COOL", 12, 12);
		drawString("CONGRATS WINNER", 12, 13);
		drawString("Press SPACE to RESTART", 9, 17);
	}
}

/* Helper functions */

void Game::handleInput(int key){
	switch(key){
	case KEYCODE_SPACE: // Toggle light
		if(gameState == START){
			setupLevel();
			gameState = IN_GAME;
		}
		else if(gameState == IN_GAME){
			if(dead == false && win == false && next == false){
				light = !light;
			}
			else if(next){
				level++;
				setupLevel();
			}
			else if(win){
				level = 1;
				gameState = START;
			}
			else{
				setupLevel();
			}
		}
		break;
	case KEYCODE_W: // Move up
		if(canMove(player, player.x, player.y - 1)){
			player.y--;
		}
		player.facing_y = player.y - 1;
		player.facing_x = player.x;
		break;
	case KEYCODE_S: // Move down
		if(canMove(player, player.x, player.y + 1)){
			player.y++;
		}
		player.facing_y = player.y + 1;
		player.facing_x = player.x;
		break;
	case KEYCODE_A: // Move left
		if(canMove(player, player.x - 1, player.y)){
			player.x--;
		}
		player.facing_y = player.y;
		player.facing_x = player.x - 1;
		break;
	case KEYCODE_D: // Move right
		if(canMove(player, player.x + 1, player.y)){
			player.x++;
		}
		player.facing_y = player.y;
		player.facing_x = player.x + 1;
		break;
	}
}

// Validate movements
bool Game::canMove(Player p, int dest_x, int dest_y) const{
	//if player won or died, deny
	if(win || dead || next) return false;
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
	// TODO: When/if we do animations, it would be nice to allow
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
	win = false;
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
	}
}
