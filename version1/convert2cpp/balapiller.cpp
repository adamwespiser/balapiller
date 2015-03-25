//
// automatically generated by spin2cpp v1.91 on Tue Mar 24 18:25:35 2015
// spin2cpp balapiller.spin 
//

/* 
***********************************************
*  Title:  Pong
*  Author: Thomas P. Sullivan
*  Date:   3/17/2011
***********************************************

 -----------------REVISION HISTORY-----------------
 v1.00 - Original Version - 11/11/2010 
 v1.01 - Work done for 2011 Microprocessor Class ENT234 3/17/2011
 v2.00 - Switched to full 512x384 using Jim Pyne's Bresenham code.  3/18/2011
 v2.01 - Ch ch ch ch changes...added a lot of new Constants  3/24/2011
 v3.00 - 160x120 Pong  4/21/2011

Balapiller: An arcade game for embedded microprocessors. 
Copyright (C) 2013,2014,2015  Russ Chisholm and Adam Wespiser

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <propeller.h>
#include "balapiller.h"

#ifdef __GNUC__
#define INLINE__ static inline
#define PostEffect__(X, Y) __extension__({ int32_t tmp__ = (X); (X) = (Y); tmp__; })
#else
#define INLINE__ static
static int32_t tmp__;
#define PostEffect__(X, Y) (tmp__ = (X), (X) = (Y), tmp__)
#endif

int32_t balapiller::Main(void)
{
  int32_t	i, lastx, lasty, StartBallDir;
  // ----
  // Pong
  // ----
  // Start the serial port
  SPORT.start(_RX, _TX, 0, 19200);
  // Start VGA screen and graphics
  if (!(SCREEN.PIXEngineStart(_pinGroup))) {
    clkset(0x80, 0);
  }
  // Wait for everything to start up
  waitcnt(((CLKFREQ * 2) + CNT));
  // Set Ball initial position, direction and speed
  // ToDo: Maybe this could be a function that adds some
  // randomness to the ball's initial position and direction!?
  StartBallDir = 1;
  //                               'MODIFIED [REPLACED 4 WITH 2 SO BALL IS IN MIDDLE]
  xBall = SCREENWIDTH - (SCREENWIDTH / 2);
  yBall = SCREENHEIGHT / 2;
  //                               'MODIFIED [REPLACED NW WITH _UP]
  dirBall = _UP;
  // Draw Ball at initial Position
  PlotBall(xBall, yBall, PEN_DRAW);
  BallInPlay = BALL_IN_PLAY;
  // This is how we set the speed of the ball along with how it is
  // drawn and erased on the screen.
  perOn = BALLSPEED / BALLRATIO;
  perOff = BALLSPEED - (BALLSPEED / BALLRATIO);
  // Set Paddle initial position
  // Set X position of the paddle
  xPaddle = SCREENWIDTH - GOALWIDTH;
  // Paddle starts in the middle of the screen in the Y direction
  yPaddle = SCREENHEIGHT / 2;
  lasty = yPaddle;
  // Draw Paddle at initial position
  DrawPaddle(xPaddle, yPaddle, PEN_DRAW);
  // ------------------------------
  // Repeat Forever
  // ------------------------------
  while (1) {
    // ------------------------------
    // Update Paddle Position
    // ------------------------------
    // Move it
    // TO MODIFY [CHANGE FUNC TO MOVEBALL, GET RID OF IF STATEMENT/BLOCK
    MovePaddle();
    if (lasty != yPaddle) {
      // Erase Paddle at old position
      DrawPaddle(xPaddle, lasty, PEN_ERASE);
      // Draw Paddle at new position
      DrawPaddle(xPaddle, yPaddle, PEN_DRAW);
      lasty = yPaddle;
    }
    // Get Ball/Boundary Status
    Bound = AtBoundary();
    // If we are not at the right boundary
    // if(Bound<>RW)                                                              'MODIFIED [CHANGED LARGER IF TO NO BOUNDARIES]
    // ''If we are at a boundary
    if (Bound != NOT_AT_BOUNDARY) {
      // Change Ball Direction
      // MODIFIED[]
      dirBall = ChangeDirection(Bound, dirBall);
      // ------------------------------
      // Update Ball Position
      // ------------------------------
      if (BallInPlay == BALL_IN_PLAY) {
        // Erase at old position
        PlotBall(xBall, yBall, PEN_ERASE);
        // Waitcnt(clkfreq/perOff+cnt)
        // Based on heading,update position
        MoveBall();
        // Draw at new position
        PlotBall(xBall, yBall, PEN_DRAW);
        waitcnt(((CLKFREQ / perOn) + CNT));
      } else {
        // ----------------------------------------------------------------
        // Ball out of play. Check to see if we have to kick one off again.
        // ----------------------------------------------------------------
        if (DeadBallTime < CNT) {
          // Put another ball in play
          BallInPlay = BALL_IN_PLAY;
          // Set Ball initial position, direction and speed
          (StartBallDir++);
          // MODIFIED[]
          xBall = SCREENWIDTH - (SCREENWIDTH / 2);
          yBall = SCREENHEIGHT / 2;
          if (StartBallDir & 0x1) {
            // MODIFIED[]
            dirBall = _UP;
          } else {
            // MODIFIED[]
            dirBall = -UP;
          }
          // Draw Ball at Start Position
          PlotBall(xBall, yBall, PEN_DRAW);
        }
      }
    } else {
      // ---------------------------------------------------------------
      // The ball is at the right boundary...the paddle missed the ball!
      // ---------------------------------------------------------------
      // Erase the Ball
      BallInPlay = BALL_OUT_OF_PLAY;
      PlotBall(xBall, yBall, PEN_ERASE);
      // ToDo: Play taps (or some other sound to indicate FAIL)
      // Stick the ball (even though not in play) back inside the game field
      // MODIFIED[]
      xBall = SCREENWIDTH - (SCREENWIDTH / 2);
      yBall = SCREENHEIGHT / 2;
      DeadBallTime = (CLKFREQ * BALL_BACK_IN_PLAY_DELAY) + CNT;
    }
  }
  return 0;
}

int32_t balapiller::AtBoundary(void)
{
  int32_t TheBoundary = 0;
  // -------------------------------------------------------------------
  // Function to determine if we are at a boundary.
  // Returns -1 if not, otherwise returns boundary (UW, LW, BW, RW, etc)
  // -------------------------------------------------------------------
  if ((xBall == MIN_X_COORDINATE) && (yBall == MIN_Y_COORDINATE)) {
    TheBoundary = NWC;
  } else {
    if ((xBall == MIN_X_COORDINATE) && (yBall == MAX_Y_COORDINATE)) {
      TheBoundary = SWC;
    } else {
      if ((xBall == MAX_X_COORDINATE) && (yBall == MIN_Y_COORDINATE)) {
        TheBoundary = NEC;
      } else {
        if ((xBall == MAX_X_COORDINATE) && (yBall == MAX_Y_COORDINATE)) {
          TheBoundary = SEC;
        } else {
          if (xBall == MIN_X_COORDINATE) {
            TheBoundary = LW;
          } else {
            if (xBall == MAX_X_COORDINATE) {
              TheBoundary = RW;
            } else {
              if (yBall == MIN_Y_COORDINATE) {
                TheBoundary = TW;
              } else {
                if (yBall == MAX_Y_COORDINATE) {
                  TheBoundary = BW;
                } else {
                  if (xBall == ((PADSUR - BALLSIZE) - 1)) {
                    // Ensures that the ball hitting the paddle doesn't chew up the paddle
                    if ((yBall < (yPaddle + HPH)) && (yBall > (yPaddle - HPH))) {
                      TheBoundary = PAD;
                    }
                  } else {
                    TheBoundary = NOT_AT_BOUNDARY;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return TheBoundary;
}

int32_t balapiller::ChangeDirection(int32_t WhichBoundary, int32_t OldDirection)
{
  int32_t NewDirection = 0;
  // --------------------------------------------------------
  // Function to change direction( ball has reached the Wall)
  // --------------------------------------------------------
  if (WhichBoundary == TW) {
    // Top Wall
    if (OldDirection == ) {
      NewDirection = ;
    } else {
      NewDirection = ;
    }
  } else if (WhichBoundary == LW) {
    // Left Wall
    if (OldDirection == ) {
      NewDirection = ;
    } else {
      NewDirection = ;
    }
  } else if (WhichBoundary == BW) {
    // Bottom Wall
    if (OldDirection == ) {
      NewDirection = ;
    } else {
      NewDirection = ;
    }
  } else if (WhichBoundary == RW || WhichBoundary == PAD) {
    // Right Wall or Paddle if Paddle is in the game
    if (OldDirection == ) {
      NewDirection = ;
    } else {
      NewDirection = ;
    }
  } else if (WhichBoundary == NWC) {
    // NorthWest Corner
    NewDirection = ;
  } else if (WhichBoundary == SWC) {
    // SouthWest Corner
    NewDirection = ;
  } else if (WhichBoundary == NEC) {
    // NorthEast Corner
    NewDirection = ;
  } else if (WhichBoundary == SEC) {
    // SouthEast Corner
    NewDirection = ;
  }
  return NewDirection;
}

int32_t balapiller::MoveBall(void)
{
  // MODIFIED[][][]
  // --------------------------------
  // Function to update Ball position
  // --------------------------------
  if (dirBall == _UP) {
    // up
    yBall = yBall - 2;
  } else if (dirBall == _DN) {
    // DOWN
    yBall = yBall + 2;
  } else if (dirBall == _LT) {
    // LEFT
    xBall = xBall - 2;
  } else if (dirBall == _RT) {
    // RIGHT
    xBall = xBall + 2;
  }
  return 0;
}

int32_t balapiller::WhatKey(void)
{
  int32_t	UpDown;
  // MODIFIED[]
  // --------------------------------------------------------------
  // WhatKey reads the serial port looking for the Up and Down keys
  // to move the paddle. It returns 0 if no 'valid' key is pressed
  // otherwise it returns Up or Down.
  // --------------------------------------------------------------
  UpDown = SPORT.rxcheck();
  if (UpDown == UPCHAR) {
    UpDown = UP;
  } else if (UpDown == DNCHAR) {
    UpDown = DOWN;
  } else if (UpDown == LTCHAR) {
    UpDown = LEFT;
  } else if (UpDown == RTCHAR) {
    UpDown = RIGHT;
  } else if (1) {
    UpDown = 0;
  }
  return UpDown;
}

int32_t balapiller::MovePaddle(void)
{
  int32_t	PadDir;
  // MODIFIED[FROM MOVEPADDLE TO MOVEBALL, ETC]
  // -----------------------------------
  // See if Paddle movement is requested
  // -----------------------------------
  PadDir = WhatKey();
  if (PadDir == UP) {
    if (((yPaddle - HPH) - 1) > (0 + PADINC)) {
      yPaddle = yPaddle - PADINC;
    }
  } else if (PadDir == DOWN) {
    if (((yPaddle + HPH) + 1) < (SCREENMAXY - PADINC)) {
      yPaddle = yPaddle + PADINC;
    }
  } else if (1) {
  }
  return 0;
}

int32_t balapiller::PlotBall(int32_t x, int32_t y, int32_t k)
{
  // -------------------------------------------------------
  // Draw a series of horizontal lines to form a square ball 
  // -------------------------------------------------------
  // SCREEN.displayWait(1)
  if (k == PEN_ERASE) {
    SCREEN.plotBox(SCREEN.displayColor(0, 0, 0), (x - 1), (y - 1), (x + 1), (y + 1));
  } else if (k == PEN_DRAW) {
    SCREEN.plotBox(SCREEN.displayColor(3, 2, 1), (x - 1), (y - 1), (x + 1), (y + 1));
  }
  return 0;
}

int32_t balapiller::DrawPaddle(int32_t x, int32_t y, int32_t k)
{
  // -------------------------------------------------------
  // Draw the Paddle (or undraw the Paddle) at x,y
  // The paddle right now is just a series of vertical lines
  // -------------------------------------------------------
  if (k == PEN_ERASE) {
    SCREEN.plotBox(SCREEN.displayColor(0, 0, 0), (x - 1), (y - HPH), (x + 1), (y + HPH));
  } else if (k == PEN_DRAW) {
    SCREEN.plotBox(SCREEN.displayColor(3, 2, 1), (x - 1), (y - HPH), (x + 1), (y + HPH));
  }
  return 0;
}

int32_t balapiller::getKeyPressed(void)
{
  int32_t	UpDown;
  // MODIFIED[]
  // --------------------------------------------------------------
  // WhatKey reads the serial port looking for the Up and Down keys
  // to move the paddle. It returns 0 if no 'valid' key is pressed
  // otherwise it returns Up or Down.
  // --------------------------------------------------------------
  UpDown = SPORT.rxcheck();
  if (UpDown == UPCHAR) {
    UpDown = UP;
  } else if (UpDown == DNCHAR) {
    UpDown = DOWN;
  } else if (UpDown == LTCHAR) {
    UpDown = LEFT;
  } else if (UpDown == RTCHAR) {
    UpDown = RIGHT;
  } else if (1) {
    UpDown = 0;
  }
  return UpDown;
}

int32_t balapiller::newDirection(int32_t whichKey, int32_t oldDirection)
{
  int32_t newDirection = 0;
  // --------------------------------------------------------
  // gets key pressed, changes ball's direction if different, adds ball if different
  // --------------------------------------------------------
  if (whichKey == UP) {
    // UP
    if (oldDirection != _UP) {
      (++);
      newDirection = _UP;
    }
  } else if (whichKey == DOWN) {
    // down
    if (oldDirection != _DN) {
      (++);
      newDirection = _DN;
    }
  } else if (whichKey == LEFT) {
    // left
    if (oldDirection != _LT) {
      (++);
      newDirection = _LT;
    }
  } else if (whichKey == RIGHT) {
    // Right
    if (oldDirection != _RT) {
      (++);
      newDirection = _RT;
    }
  } else if (1) {
    return oldDirection;
  }
  return newDirection;
}

int32_t balapiller::setNewBall(int32_t oldDirection)
{
  return 0;
}

/* 
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 */