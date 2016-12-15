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
 
#### Challenges

The biggest challenge that we ran into was understanding the base code of the game, which was essentially what took the longest. Once we understood that, we had to fix the code because when we first ran the base code, the game would not leave the game-over screen. After fixing that, we had to implement our own logic, which is what took the rest of our time. That was a challenge in itself, because we had to conform our ideas to that of the base code, that way they matched. This was really at the beginning, because we soon got used to the base code. There was also the fact that when something went wrong, we had to do trial-and-error analysis to figure out what was wrong. We couldn't detect a certain spot that went wrong, unless we were changing only one line of code. 

#### Bugs/Glitches

1. The very first time the player runs the game, the score tally marks will disappear. 
2. There are times where the keyboard no longer accepts input and the player would have to program the board again. 
3. Very few times, if a player lost on the bottom border, the game would keep the snake in the border when you reset . You simply have to reset another time. This happens because before resetting, the snake is in the position it lost in for a split second. 
4. At times, the apple would move to another part of the screen. This wasn't game-breaking because the apple wouldn't move like that more than once, but it still was a glitch. 

## Conclusion

All in all, this project took about 50 - 60 hours of lab time, from conception to demo. In the process, we gained a better understanding of Verilog and hardware. The base code that we used was definitely a great help in that. It was also interesting to see how much work it takes to develop a program like this from the ground up, putting this project into a real world perspective. This project was an amazing learning experience that we definitely took away a good amount of information from. 


Credits: Ken DeRose and Trevis Graham 
