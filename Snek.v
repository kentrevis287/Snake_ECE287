module Snek(start, master_clk, KB_clk, data, DAC_clk, VGA_R, VGA_G, VGA_B, VGA_W, VGA_hSync, VGA_vSync, blank_n);
	
	input master_clk, KB_clk, data; //50MHz
	output reg [7:0]VGA_R, VGA_G, VGA_B, VGA_W;  //Red, Green, Blue VGA signals
	output VGA_hSync, VGA_vSync, DAC_clk, blank_n; //Horizontal and Vertical sync signals
	wire [9:0] xCount; //x pixel
	wire [9:0] yCount; //y pixel
	reg [9:0] appleX;
	reg [8:0] appleY;
	wire [9:0]rand_X;
	wire [8:0]rand_Y;
	wire displayArea; //is it in the active display area
	wire VGA_clk; //25 MHz
	wire R;
	wire G;
	wire B;
	wire W;
	wire [4:0] direction;
	wire lethal, nonLethal;
	reg bad_collision, good_collision, game_over, initpos, ready, up, left, right, win;
	reg down = 1;
	reg apple_inX, apple_inY, apple, border, found, found2, scoreboard; //---------------------------------------------------------------Added border
	integer appleCount, count1, count2, count3, count4, count5, count6, level, score, slither;
	reg [6:0] size;
	input start;
	reg [9:0] snakeX[0:127];
	reg [8:0] snakeY[0:127];
	reg [9:0] snakeHeadX;
	reg [9:0] snakeHeadY;
	
	reg [9:0] snake2X[0:127];
	reg [8:0] snake2Y[0:127];
	reg snakeBody2;
	
	reg [1:0] move, timer;
	reg snakeHead;
	reg snakeBody;
	wire update, reset;
	integer maxSize = 16;
	

	clk_reduce reduce1(master_clk, VGA_clk); //Reduces 50MHz clock to 25MHz
	VGA_gen gen1(VGA_clk, xCount, yCount, displayArea, VGA_hSync, VGA_vSync, blank_n);//Generates xCount, yCount and horizontal/vertical sync signals	
	randomGrid rand1(VGA_clk, rand_X, rand_Y, direction);
	kbInput kbIn(KB_clk, data, direction, reset);
	updateClk UPDATE(master_clk, update);
	
	assign DAC_clk = VGA_clk;
	//
	always @(posedge VGA_clk)//---------------------------------------------------------------Added border function
	begin
		border <= (((xCount >= 0) && (xCount < 11) || (xCount >= 630) && (xCount < 641)) || ((yCount >= 0) && (yCount < 11) || (yCount >= 470) && (yCount < 481)));
	end
	
	always@(posedge VGA_clk)
	begin
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
		timer <= timer + 1'b1;
	end
	
	always@(posedge VGA_clk)
	begin
	level <= size;
	appleCount = appleCount+1;
		if(appleCount == 1)
		begin
			appleX <= 20;
			appleY <= 20;
		end
		else
		begin	
			if(good_collision)
			begin
				if((rand_X<10) || (rand_X>630) || (rand_Y<10) || (rand_Y>470))
				begin
					appleX <= 40;
					appleY <= 30;
				end
				else
				begin
					appleX <= rand_X;
					appleY <= rand_Y;
				end
			end
			else if(~start)
			begin
				if((rand_X<10) || (rand_X>630) || (rand_Y<10) || (rand_Y>470))
				begin
					appleX <=340;
					appleY <=430;
				end
				else
				begin
					appleX <= rand_X;
					appleY <= rand_Y;
				end
			end
		end
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

	always @(posedge VGA_clk)
	begin
		apple_inX <= (xCount > appleX && xCount < (appleX + 10));
		apple_inY <= (yCount > appleY && yCount < (appleY + 10));
		apple = apple_inX && apple_inY;
	end
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

	
	always@(posedge VGA_clk)
	begin	
		snakeHead = (xCount > snakeX[0] && xCount < (snakeX[0]+10)) && (yCount > snakeY[0] && yCount < (snakeY[0]+10));
	end
		
	assign lethal = border || snakeBody || snakeBody2;
	assign nonLethal = apple;
	always @(posedge VGA_clk) if(nonLethal && snakeHead) begin 
																				good_collision<=1;
																				size = size+1;
																				score <= score + 1;
																			end
										else if(~start)begin
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

/////////////////////////////////////////////////////////////////////////////////////////////////

module clk_reduce(master_clk, VGA_clk);

	input master_clk; //50MHz clock
	output reg VGA_clk; //25MHz clock
	reg q;

	always@(posedge master_clk)
	begin
		q <= ~q; 
		VGA_clk <= q;
	end
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////////////////////////////////

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
		if(pointY>46)//---------------------------------------------------------------Changed to 469
			rand_Y <= 460;
		else if (pointY<2)
			rand_Y <= 20;
		else
			rand_Y <= (pointY * 10);
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////////////////////////////////

module updateClk(master_clk, update);
	input master_clk;
	output reg update;
	reg [21:0]count;	

	always@(posedge master_clk)
	begin
		count <= count + 1;
		if(count == 1777777)
		begin
			update <= ~update;
			count <= 0;
		end	
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////

