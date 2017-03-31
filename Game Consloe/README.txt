Game Conlose
============
By: Sin Chi Chiu, Kevin Bato

This is a project for the course CSCB58 at University of Toronto Scarborough winter 2017 semester.
The goal of this project is to create a game consloe that contains multiple games on board without
the needs to load games from external source. The games included in this repository are pong and 
squash. 

Control
-----------------
Reset  | SW17
pong   | SW0 OFF
squash | SW0 ON	
-----------------



Pong
====
This game is taken from the pong clone repository at https://github.com/felixmo/Pong/blob/master/pong.v
Modifications were made to the original source code in order to make it functional on the DE2-115 FPGA 
board. The pll50Mz files are created by us and are required to run with this code on the DE2-115 FPGA 
board due to the lack of a physical 27Mz clock signal that was used in the original source code. Other
modifications were made to improve the visual appearance on screen.

Control | Player 1	| Player 2
--------|-----------|----------
Reset  	| SW17		| SW17
up   	| KEY3		| KEY1
down	| KEY2		| KEY0
-------------------------------



Squash
======
This game is a heavily modified version of pong. This game is a single player game where player can 
practice their skill in pong. Player is given 5 lives, and there is no score rewarded.

Control | Player 1	
--------|----------
Reset  	| SW17		
up   	| KEY3		
down	| KEY2		
-------------------