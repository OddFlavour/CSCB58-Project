module paddleMovement(paddle_pos, move_up, move_down, clk, enable, resetn);

    input reg [7:0] paddle_pos;
    input move_up, move_down;
    input clk, enable, resetn;

    always @(posedge clk) // <clk> should hit posedge every X frames
    begin
        if (move_up == 1'b1)
            paddle_pos <= paddle_pos + 1'b1;
        else if (move_down == 1'b1)
            paddle_pos <= paddle_pos - 1'b1;
    end

endmodule

module ball_physics(before_dir, after_dir);

endmodule

// Let trajectory of ball be represented by (x, y) where
// - x is the number of pixels travelled in one second in the X direction.
// - y is the number of pixels travelled in one second in the Y direction.

// --> Want magnitude of vector (i.e. speed of ball) to be the same:

Screen Size: 160px wide by 120px high

Paddle Size: 3px wide by 20px high
--> We separate the paddle into 10 sections (2px each) - trajectory upon hitting each section is outlined below

Magnitude: 80 (160/2 => 2 seconds to move exactly horizontal across the screen)
(i.e.) Equation must satisfy: x^2 + y^2 = 6,400
As well, angle <theta> must satisfy: x/(sqrt(x^2+y^2)) = cos(theta)

So we need:
-> x = 80*cos(theta)
-> y^2 = 6400 - x^2

Left Paddle:
=======================
Angle 75 up: (22, -77)
Angle 60 up: (40, -69)
Angle 45 up: (57, -56)
Angle 30 up: (69, -40)
Angle 15 up: (77, -22)
Angle 15 dn: (77, 22)
Angle 30 dn: (69, 40)
Angle 45 dn: (57, 56)
Angle 60 dn: (40, 69)
Angle 75 dn: (22, 77)

Right Paddle:
=======================
Left Paddle but w/ negated x

Hitting Edge:
-------------------------
(x, y) --> (x, -y)


// * We can consider taking prior trajectory into account: Just have to negate the given x coordinate and provide some constant "upward/downward bias": +constant or -constant


// Speed determined by timing:
// - If joystick is moved left/right within some range, speed of ball upon impact with paddle will increase/decrease

