# Snake_ECE287

For our ECE 287 Project, we decided to implement the famous game "Snake" in Verilog, via Quartus II. All programming was done on a Altera DE2-115 board. 

### Background

"Snake" is a video game where a player controls a snake that moves around to eat apples in order to become bigger. As the snake gets bigger, the less room there is to maneuver. The player loses if the snake hits itself or a border. The player wins if it eats all of the appless. 

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
  * A lose state (when the player's snake hits the border or enemy snake).
  * Raised difficulty:
  	* After eating a fourth apple, the apples will begin to move at a speed relative to the size of the snake. As the snake gets bigger, the apple moves faster. 
 	* An enemy snake appears after the player eats their first apple. The snake grows bigger at the same rate of the player snake, 4 blocks at a time. 
 	* A score counter, which are tally marks that increment by 1. Once you reach a multiple of five, the tally is represented as a big block.

#### Implementation
##### Keyboard input

```verilog
module kbInput(KB_clk, data, direction, reset);

	input KB_clk, data;
	output reg [4:0] direction;
	output reg reset = 0; 
	reg [7:0] code;
	reg [10:0]keyCode, previousCode;
	reg recordNext = 0;
	integer count = 0;

always@(negedge KB_clk)
	begin
		keyCode[count] = data;
		count = count + 1;			
		if(count == 11)
		begin
			if(previousCode == 8'hF0)
			begin
				code <= keyCode[8:1];
			end
			previousCode = keyCode[8:1];
			count = 0;
		end
	end
	
	always@(code)
	begin
		if(code == 8'h75)
			direction = 5'b00010;
		else if(code == 8'h6B)
			direction = 5'b00100;
		else if(code == 8'h72)
			direction = 5'b01000;
		else if(code == 8'h74)
			direction = 5'b10000;
		else if(code == 8'h2D)
			reset <= ~reset;
		else direction <= direction;
	end	
endmodule
```

Here, we have how our keyboard is implemented. When a key is pressed, 11 bits of data is sent, called a make code. When it is released, it sends another 11 bits called a break code, followed by another make code, totalling 33 bits of data. All of this is being sent on the negative edge of its own clock. We didn't make many changes from the original code, except for changing the break codes that are coded for different keys from W,A,S,D to Up Arrow, Left Arrow, Right Arrow, Down Arrow. 

##### VGA Output

```verilog
module VGA_gen(VGA_clk, xCount, yCount, displayArea, VGA_hSync, VGA_vSync, blank_n);

	input VGA_clk;
	output reg [9:0]xCount, yCount; 
	output reg displayArea;  
	output VGA_hSync, VGA_vSync, blank_n;

	reg p_hSync, p_vSync; 
	
	integer porchHF = 640; //start of horizntal front porch
	integer syncH = 655;//start of horizontal sync
	integer porchHB = 747; //start of horizontal back porch
	integer maxH = 793; //total length of line.

	integer porchVF = 480; //start of vertical front porch 
	integer syncV = 490; //start of vertical sync
	integer porchVB = 492; //start of vertical back porch
	integer maxV = 525; //total rows. 

	always@(posedge VGA_clk)
	begin
		if(xCount === maxH)
			xCount <= 0;
		else
			xCount <= xCount + 1;
	end
	// 93sync, 46 bp, 640 display, 15 fp
	// 2 sync, 33 bp, 480 display, 10 fp
	always@(posedge VGA_clk)
	begin
		if(xCount === maxH)
		begin
			if(yCount === maxV)
				yCount <= 0;
			else
			yCount <= yCount + 1;
		end
	end
	
	always@(posedge VGA_clk)
	begin
		displayArea <= ((xCount < porchHF) && (yCount < porchVF)); 
	end

	always@(posedge VGA_clk)
	begin
		p_hSync <= ((xCount >= syncH) && (xCount < porchHB)); 
		p_vSync <= ((yCount >= syncV) && (yCount < porchVB)); 
	end
 
	assign VGA_vSync = ~p_vSync; 
	assign VGA_hSync = ~p_hSync;
	assign blank_n = displayArea;
endmodule
```

This is the VGA output module. The screen resolution is defined as 640 x 480. Then on the positive edge of the VGA clock, the x and y coordinate counts are created, which draw on the display, as well as track the snkae and the apple. Using the positvie edge of the VGA clock again, the actual display area is created. VGA syncs are created to be the inverse of the vertical and horizontal sync. To define the display area, blank_n is assigned. There was also a module to decrease the clock time of the FPGA of 50 MHz to 25 MHz, which is the native clock to the VGA. We didn't change this code at all from the original, since it fit our needs. 

##### Apple Mechanics

```verilog
module randomGrid(VGA_clk, rand_X, rand_Y, direction);
	input VGA_clk;
	input [4:0]direction;
	output reg [9:0]rand_X;
	output reg [8:0]rand_Y;
	reg [5:0]pointX, pointY;

	always @(posedge VGA_clk)
	begin
		case(direction)
			5'b00010: pointX <= pointX + 2;
			5'b00100: pointX <= pointX + 3;
			default: pointX <= pointX + 1;
		endcase
	end
	always @(posedge VGA_clk)
	begin
		case(direction)
			5'b01000: pointY <= pointY + 2;
			5'b10000: pointY <= pointY + 3;
			default: pointY <= pointY + 1;
		endcase
	end
	always @(posedge VGA_clk)
	begin	
		if(pointX>62)
			rand_X <= 620;
		else if (pointX<2)
			rand_X <= 20;
		else
			rand_X <= (pointX * 10);
	end
	
	always @(posedge VGA_clk)
	begin	
		if(pointY>46)
			rand_Y <= 460;
		else if (pointY<2)
			rand_Y <= 20;
		else
			rand_Y <= (pointY * 10);
	end
endmodule
```

Above is the module that generates where to place the apple. Based on your direction, we created counters in the x and y directions that would add random values to them. Then, those values would get multiplied by ten, so the apple would appear on the screen. We implemented a check so that if it was greater than given values, it would set itself to a desired value. 

```verilog
		if (size > 16)
		begin
			count3 <= count3 + 1;
			if (count3 >= 50000000 - (level * 270000))
			begin
				move <= rand_X/10;
				case(move)
					2'b00:
					begin
						if (appleX < 620)
							appleX <= appleX + 10;
					end
					2'b01:
					begin
						if (appleX > 20)
							appleX <= appleX - 10;
					end
					2'b10:
					begin
						if (appleY < 460)
							appleY <= appleY + 10;
					end
					2'b11:
					begin
						if (appleY > 20)
							appleY <= appleY - 10;
					end
				endcase
				count3 <= 0;
			end
		end
	end
```
Above is the piece of code that ramps up the difficulty once the size of the player snake becomes greater than sixteen. Based on the random value of X divided by 10, the apple will move in a random direction up, down, left, or right. There are also checks so the apple is never outside of the border.

```verilog
	assign lethal = border || snakeBody || snakeBody2;
	assign nonLethal = apple;
	always @(posedge VGA_clk) if(nonLethal && snakeHead) begin 
																		good_collision<=1;
																		size = size+1;
																		score <= score + 1;
																		end
									else if(~start)
										begin
										size = 1;	
										score = 0;
										end
									else good_collision=0;
										
	
always@(posedge VGA_clk)
	if (score >= 62)
		win <= 1;
	else
		win <= 0;
	
	
	always @(posedge VGA_clk) if(lethal && snakeHead) bad_collision<=1;
										else bad_collision=0;
	always @(posedge VGA_clk) if(bad_collision || win) game_over<=1;
										else if(~start) game_over=0;
	
									
	assign R = (displayArea && ~win && ((scoreboard && (~snakeBody && ~snakeBody2))|| apple || game_over));
	assign G = (displayArea && ((((scoreboard && (~apple && ~snakeBody2)) || snakeHead || snakeBody) && ~game_over) || (game_over && win)));
	assign B = (displayArea && ~win && (((scoreboard && (~apple && ~snakeBody)) || border || snakeBody2) && ~game_over) );//---------------------------------------------------------------Added border
	
	always@(posedge VGA_clk)
	begin
		VGA_R = {8{R}};
		VGA_G = {8{G}};
		VGA_B = {8{B}};
	end 

endmodule
```

Above is most of where we have the rest of our apple logic. We define the apple as a non-lethal collision. Then we say that when the snake head hits the apple, it is defined as a good collision and adds to the score. Once you reach 16 apples, or 62 blocks of snake, then you win. We also assigned the color red to the apple. 

##### Player Snake and Enemy Snake Mechanics

```verilog
always@(posedge VGA_clk)
	begin 
		count6 <= count6 + 1;
		
		if (count6 >= 50000000)
		begin
			if(down)
			begin
				slither <= 0;
				count6 <= 0;
				right <= 1;
				down <= 0;
			end
			else if(right)
			begin
				slither <= 3;
				count6 <= 0;
				up <= 1;
				right <= 0;
			end
		end
		if (count6 >= 25000000)
		begin
			if(up)
			begin
				slither <= 2;
				count6 <= 0;
				left <= 1;
				up <= 0;
			end
			else if(left)
			begin
				slither <= 1;
				count6 <= 0;
				down <= 1;
				left <= 0;
			end
		end
				
	end
	
	always@(posedge update)
	begin
		if(start)
		begin
			for(count1 = 127; count1 > 0; count1 = count1 - 1)
				begin
					if(start && ~ready)
					begin
						snakeX[0] = 300;
						snakeY[0] = 250;
						snake2X[0] = 100;
						snake2Y[0] = 80;
						ready = 1;
					end
					if(count1 <= size - 1)
					begin
						snakeX[count1] = snakeX[count1 - 1];
						snakeY[count1] = snakeY[count1 - 1];
					end
					if(count1 <= size-1)
					begin
						snake2X[count1] = snake2X[count1 - 1];
						snake2Y[count1] = snake2Y[count1 - 1];
					end
				end
			case(direction)
				5'b00010: snakeY[0] <= (snakeY[0] - 10);
				5'b00100: snakeX[0] <= (snakeX[0] - 10);
				5'b01000: snakeY[0] <= (snakeY[0] + 10);
				5'b10000: snakeX[0] <= (snakeX[0] + 10);
				endcase
			case(slither)
				2'b00: snake2Y[0] <= (snake2Y[0] - 10);
				2'b01: snake2X[0] <= (snake2X[0] - 10);
				2'b10: snake2Y[0] <= (snake2Y[0] + 10);
				2'b11: snake2X[0] <= (snake2X[0] + 10);
				default: snake2Y[0] <= (snake2Y[0] + 10);
			endcase
		end
		else if(~start)
		begin
			ready = 0;
			for(count4 = 1; count4 < 128; count4 = count4+1)
				begin
				snakeX[count4] = 700;
				snakeY[count4] = 500;
				snake2X[count4] = 710;
				snake2Y[count4] = 510;
				end	
		end
	end
	
	always@(posedge VGA_clk)
	begin
		found = 0;
		
		for(count2 = 1; count2 < size; count2 = count2 + 1)
		begin
			if(~found)
			begin				
				snakeBody = ((xCount > snakeX[count2] && xCount < snakeX[count2]+10) && (yCount > snakeY[count2] && yCount < snakeY[count2]+10));
				found = snakeBody;
			end
		end
	end
	
	always@(posedge VGA_clk)
	begin
		found2 = 0;
			
		for(count2 = 1; count2 < size; count2 = count2 + 1)
		begin
			if(~found2)
			begin				
				snakeBody2 = ((xCount > snake2X[count2] && xCount < snake2X[count2]+10) && (yCount > snake2Y[count2] && yCount < snake2Y[count2]+10));
				found2 = snakeBody2;
			end
		end
	end
```

Above is most of our snake logic. Here we create the snake head and have it move 10 units in whatever direction is inputted by the user. We used to have a bug in our code that would randomly spawn the snake head in the border sometimes, which is an automatic game over, so we overcame that by programming so the snake head would always start in the middle. We also explained earlier that when the snake head hits the apple, it is a good collision and the snake grows by 4 body parts. Once the snake hits itself or hits the border, it is game over. We gave the enemy snake its own direction command called slither. It basically mirrors the direction code that we gave our snake, but these are predetermined values, so the enemy can be thought of as an AI that moves randomly. The enemy also grows every time the player achieves a good collision. In last portion of code from the section Apple Mechanics, we assign green to the player snake and blue to the enemy snake. 

##### Other features not explained

* The snake is updated at 28 Hz on the VGA.
* The game over screen is a blank red screen.
* The win screen is a blank green screen. 
* To reset, press the first reset button, KEY0.
* Without the win state, the maximum snake length is 128 total parts, 1 head and 127 body parts. 
* With no key presses, the snake will continue moving in the last direction that was pressed. 
* The 127 body parts are actually hidden behind the porch. Once the apple is eaten, 4 parts are revealed. 
* The score counter
```verilog
case(score)
			0: scoreboard <= 0;
			4: scoreboard <= (xCount >= 30) && (xCount < 40) && (yCount >= 440) && (yCount < 460);
			8: scoreboard <= (((xCount >= 30) && (xCount < 40)) || ((xCount >= 50) && (xCount < 60))) && (yCount >= 440) && (yCount < 460);
			12: scoreboard <= (((xCount >= 30) && (xCount < 40)) || ((xCount >= 50) && (xCount < 60) || ((xCount >= 70) && (xCount < 80)))) && (yCount >= 440) && (yCount < 460);
			16: scoreboard <= (((xCount >= 30) && (xCount < 40)) || (xCount >= 50) && (xCount < 60) || ((xCount >= 70) && (xCount < 80)) || ((xCount >= 90) && (xCount < 100))) && (yCount >= 440) && (yCount < 460);
			20: scoreboard <= ((xCount >= 30) && (xCount < 80)) && (yCount >= 440) && (yCount < 460);
			24: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 100))) && (yCount >= 440) && (yCount < 460);
			28: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 100)) || ((xCount >= 110) && (xCount < 120))) && (yCount >= 440) && (yCount < 460);
			32: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 100)) || ((xCount >= 110) && (xCount < 120)) || ((xCount >= 130) && (xCount < 140))) && (yCount >= 440) && (yCount < 460);
			36: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 100)) || ((xCount >= 110) && (xCount < 120)) || ((xCount >= 130) && (xCount < 140)) || ((xCount >= 150) && (xCount < 160))) && (yCount >= 440) && (yCount < 460);
			40: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 140))) && (yCount >= 440) && (yCount < 460);
			44: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 140)) || ((xCount >= 150) && (xCount < 160))) && (yCount >= 440) && (yCount < 460);
			48: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 140)) || ((xCount >= 150) && (xCount < 160)) || ((xCount >= 170) && (xCount < 180))) && (yCount >= 440) && (yCount < 460);
			52: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 140)) || ((xCount >= 150) && (xCount < 160)) || ((xCount >= 170) && (xCount < 180)) || ((xCount >= 190) && (xCount < 200))) && (yCount >= 440) && (yCount < 460);
			56: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 140)) || ((xCount >= 150) && (xCount < 160)) || ((xCount >= 170) && (xCount < 180)) || ((xCount >= 190) && (xCount < 200)) || ((xCount >= 210) && (xCount < 220))) && (yCount >= 440) && (yCount < 460);
			60: scoreboard <= (((xCount >= 30) && (xCount < 80)) || ((xCount >= 90) && (xCount < 140)) || ((xCount >= 150) && (xCount < 200))) && (yCount >= 440) && (yCount < 460);
		endcase
```
Here, we basically coded a case statement that draws a tally mark in white (which is contained in the assigning colors code in the section Apple Mechanics). The score can be thought of the amount of body parts added to the snake, witch is why we increment by 4. 

#### Challenges

The biggest challenge that we ran into was understanding the base code of the game, which was essentially what took the longest. Once we understood that, we had to fix the code because when we first ran the base code, the game would not leave the game-over screen. After fixing that, we had to implement our own logic, which is what took the rest of our time. This was a challenge in itself, because we had to conform our ideas to the base code, so that they matched. There was also the fact that when something went wrong, we had to do trial-and-error analysis to figure out what was wrong. We couldn't detect a certain spot that went wrong, unless we were changing only one line of code. 

#### Bugs/Glitches

1. The very first time the player runs the game, the score tally marks will sometimes disappear. 
2. There are times where the keyboard no longer accepts input and the player would have to program the board again. 
3. Very few times, if a player lost on the bottom border, the game would keep the snake in the border when you reset . You simply have to reset another time. 
4. At times, the apple would move to another part of the screen. This wasn't game-breaking because the apple wouldn't move like that more than once, but it still was a glitch. 

## Conclusion

All in all, this project took about 50 - 60 hours of lab time, from conception to demo. In the process, we gained a better understanding of Verilog and hardware. The base code that we used was definitely a great help in that. It was also interesting to see how much work it takes to develop a program like this from the ground up, putting this project into a real world perspective. This project was an amazing learning experience that we definitely took away a good amount of information from. 


Credits: Ken DeRose and Trevis Graham 
