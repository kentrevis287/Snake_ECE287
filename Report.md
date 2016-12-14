# Snake_ECE287

For our ECE 287 Project, we decided to implement the famous game "Snake" in Verilog, via Quartus II. All programming was done on a Altera DE2-115 board. 

### Background

"Snake" is a video game where a player controls a snake that moves around to eat objects in order to become bigger. As the snake gets bigger, the harder it becomes to control that snake. The player loses if the snake hits itself, or a border. The player wins if it eats all of the objects. 

## Design
#### Summary

To complete this project, we used:
  * Quartus II
  * Altera DE2-115 board, power cable, and USB cable
  * PS/2 Keyboard
  * VGA cable and monitor

Features include:
  * A moving Snake that eats "apples" to grow 4 blocks. 
  * A win state (when your score reaches 16).
  * A psuedo-lose state (when the player's snake hits the border or enemy snake).
  * Raised difficulty:
  	* After eating a fourth apple, the apples will begin to move at a speed relative to the size of the snake. As the snake gets bigger, the apple moves faster. 
 	* An enemy snake that appears after the player eats their first apple. The snake grows bigger at the same rate of the player snake, 4 blocks at a time. 
 	* A score counter, which are tally marks that increment by 1. Once you reach a multiple of five, the tally is represented as a big block.

#### Challenges

#### Bugs/Glitches

1. The very first time the player runs the game, the score tally marks will disappear. 
2. There are times where the keyboard no longer accepts input and the player would have to program the board again. 
3. Very few times, if a player lost on the bottom border, the game would keep the snake in the border when you reset . You simply have to reset another time. This happens because before resetting, the snake is in the position it lost in for a split second. 
4. At times, the apple would move to another part of the screen. 

## Conclusion


Credits: Ken DeRose and Trevis Graham 
