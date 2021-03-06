{{
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

}}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  _RX           = 31                         
  _TX           = 30                         

  ''Boundary Values
  NOT_AT_BOUNDARY = 0
  TW    =       1               ''Top Wall
  LW    =       2               ''Left Wall
  BW    =       3               ''Bottom Wall
  RW    =       4               ''Right Wall
  NWC   =       5               ''NorthWest Corner
  SWC   =       6               ''SouthWest Corner
  NEC   =       7               ''NorthEast Corner
  SEC   =       8               ''SouthEast Corner
  PAD   =       9               ''The Paddle

  ''Ball Directions
  SE    =       0               ''SouthEast
  NE    =       1               ''NorthEast
  NW    =       2               ''NorthWest
  SW    =       3               ''SouthWest

  ''ASCII Characters for Up and Down for the Paddle
  UPCHAR  =     $41             ''A is UP
  DNCHAR  =     $42             ''B is DOWN

  ''Constants for Up and Down Paddle in the game
  UP      =     1
  DOWN    =     2

  ''Constants for drawing and erasing the ball
  PEN_ERASE =   0
  PEN_DRAW  =   1

  ''The screen size we are using
  SCREENWIDTH = 160             ''Screen Width
  SCREENHEIGHT = 120            ''Screen Heigth

  ''Paddle Constants  
  HPH     =     8                       ''Half PaddleHeight (width)
  GOALWIDTH  =  16                      ''Width of Goal area
  PADSUR  =     SCREENWIDTH-GOALWIDTH   ''Paddle Surface X coordinate
  PADINC  =     4                      ''Paddle Increment

  ''The Ball
  BALL_BACK_IN_PLAY_DELAY = 3   ''Seconds
  BALL_OUT_OF_PLAY = 0
  BALL_IN_PLAY = 1
  BALLSIZE = 3                  ''Width and Height of the Ball is the same
                                ''Actual Ball Width and Height is determined by (BALLSIZE*2)+1

  BALLSPEED = 1024              ''Used as a divisor into CLKFREQ for WAITCNT
  BALLRATIO = 16                ''Used to set the ratio of Ball ON time to Ball OFF time

  ''Our game screen coordinate limits (the edges of the game screen)
  SCREEN_TOP_OFFSET = 0
  SCREEN_BOTTOM_OFFSET = 1
  SCREEN_LEFT_OFFSET = 0
  SCREEN_RIGHT_OFFSET = 1
  
  ''Do not change these
  SCREENMINX = SCREEN_LEFT_OFFSET                       ''Minimum X screen coordinate
  SCREENMAXX = SCREENWIDTH-SCREEN_RIGHT_OFFSET          ''Maximum X screen coordinate
  SCREENMINY = SCREEN_TOP_OFFSET                        ''Minimum Y screen coordinate
  SCREENMAXY = SCREENHEIGHT-SCREEN_BOTTOM_OFFSET        ''Maximum Y screen coordinate

  ''Do not change these
  MIN_X_COORDINATE = SCREENMINX+BALLSIZE
  MAX_X_COORDINATE = SCREENMAXX-BALLSIZE
  MIN_Y_COORDINATE = SCREENMINY+BALLSIZE
  MAX_Y_COORDINATE = SCREENMAXY-BALLSIZE 

  _pinGroup = 2
  _switchRate = 5

  
OBJ
  SCREEN   : "VGA64_PIXEngine"
  SPORT    : "FullDuplexSerial"

VAR
  long xBall, yBall, dirBall
  long xPaddle, yPaddle
  long Bound, perOff, perOn
  long DeadBallTime
  long BallInPlay         

PUB Main | i,lastx,lasty,StartBallDir
  ''----
  ''Pong
  ''----

  ''Start the serial port
  SPORT.start(_RX, _TX, %0000, 19200)

  ''Start VGA screen and graphics
  ifnot(SCREEN.PIXEngineStart(_pinGroup))
    reboot

  ''Wait for everything to start up
  waitcnt(clkfreq*2+cnt)
  
  ''Set Ball initial position, direction and speed
  ''ToDo: Maybe this could be a function that adds some
  ''randomness to the ball's initial position and direction!?
  StartBallDir := 1
  xBall := SCREENWIDTH-SCREENWIDTH/4
  yBall := SCREENHEIGHT/2
  dirBall := NW
  plotball(xBall,yBall,PEN_DRAW)       ''Draw Ball at initial Position
  BallInPlay := BALL_IN_PLAY

  ''This is how we set the speed of the ball along with how it is
  ''drawn and erased on the screen.
  perOn := BALLSPEED/BALLRATIO
  perOff := BALLSPEED-(BALLSPEED/BALLRATIO)

  ''Set Paddle initial position
  xPaddle := SCREENWIDTH - GOALWIDTH   ''Set X position of the paddle
  yPaddle := SCREENHEIGHT/2            ''Paddle starts in the middle of the screen in the Y direction
  lasty := yPaddle

  ''Draw Paddle at initial position
  DrawPaddle(xPaddle, yPaddle, PEN_DRAW)

  ''------------------------------
  ''Repeat Forever
  ''------------------------------
  repeat
    ''------------------------------
    ''Update Paddle Position
    ''------------------------------
    ''Move it
    MovePaddle
    if(lasty <> yPaddle)
      ''Erase Paddle at old position
      DrawPaddle(xPaddle,lasty,PEN_ERASE)
      ''Draw Paddle at new position
      DrawPaddle(xPaddle,yPaddle,PEN_DRAW)
      lasty := yPaddle
     
    ''Get Ball/Boundary Status
    Bound := AtBoundary
    ''If we are not at the right boundary
    if(Bound<>RW)
    ' ''If we are at a boundary
      if(Bound<>NOT_AT_BOUNDARY)
        'Change Ball Direction
        dirBall := ChangeDirection(Bound,dirBall)
       
      ''------------------------------
      ''Update Ball Position
      ''------------------------------
      If(BallInPlay==BALL_IN_PLAY)
        ''Erase at old position
        PlotBall(xBall,yBall,PEN_ERASE)
        'Waitcnt(clkfreq/perOff+cnt)
        ''Based on heading,update position
        MoveBall
        ''Draw at new position
        PlotBall(xBall,yBall,PEN_DRAW)
        Waitcnt(clkfreq/perOn+cnt)
      Else
        ''----------------------------------------------------------------
        ''Ball out of play. Check to see if we have to kick one off again.
        ''----------------------------------------------------------------
        If(DeadBallTime<cnt)
          ''Put another ball in play
          BallInPlay := BALL_IN_PLAY        
          ''Set Ball initial position, direction and speed
          StartBallDir++
          xBall := SCREENWIDTH-SCREENWIDTH/4
          yBall := SCREENHEIGHT/2
          if(StartBallDir & $1)
            dirBall := NW
          else
            dirBall := SW
           
          ''Draw Ball at Start Position
          PlotBall(xBall,yBall,PEN_DRAW)
    else
      ''---------------------------------------------------------------
      ''The ball is at the right boundary...the paddle missed the ball!
      ''---------------------------------------------------------------
      ''Erase the Ball
      BallInPlay := BALL_OUT_OF_PLAY
      PlotBall(xBall,yBall,PEN_ERASE)
      ''ToDo: Play taps (or some other sound to indicate FAIL)
      'Stick the ball (even though not in play) back inside the game field
      xBall := SCREENWIDTH-SCREENWIDTH/4
      yBall := SCREENHEIGHT/2
      DeadBallTime := CLKFREQ*BALL_BACK_IN_PLAY_DELAY+cnt
       
PUB AtBoundary : TheBoundary
  ''-------------------------------------------------------------------
  ''Function to determine if we are at a boundary.
  ''Returns -1 if not, otherwise returns boundary (UW, LW, BW, RW, etc)
  ''-------------------------------------------------------------------
  if xBall==MIN_X_COORDINATE and yBall==MIN_Y_COORDINATE
    TheBoundary := NWC
  elseif xBall==MIN_X_COORDINATE and yBall==MAX_Y_COORDINATE 
    TheBoundary := SWC
  elseif xBall==MAX_X_COORDINATE and yBall==MIN_Y_COORDINATE 
    TheBoundary := NEC
  elseif xBall==MAX_X_COORDINATE and yBall==MAX_Y_COORDINATE 
    TheBoundary := SEC
  elseif xBall==MIN_X_COORDINATE
    TheBoundary := LW
  elseif xBall==MAX_X_COORDINATE
    TheBoundary := RW
  elseif yBall==MIN_Y_COORDINATE
    TheBoundary := TW
  elseif yBall==MAX_Y_COORDINATE
    TheBoundary := BW
  elseif (xBall == PADSUR-BALLSIZE-1)'Ensures that the ball hitting the paddle doesn't chew up the paddle
    if(yBall<(yPaddle+HPH) AND yBall > (yPaddle-HPH))
      TheBoundary := PAD  
  else
    TheBoundary := NOT_AT_BOUNDARY   

  return TheBoundary

PUB ChangeDirection(WhichBoundary,OldDirection):NewDirection
  ''--------------------------------------------------------
  ''Function to change direction( ball has reached the Wall)
  ''--------------------------------------------------------
  Case WhichBoundary 
    TW:    'Top Wall
      if(OldDirection==NE)
        NewDirection := SE
      else 
        NewDirection := SW
    LW:    'Left Wall
      if(OldDirection==NW)
        NewDirection := NE
      else 
        NewDirection := SE
    BW:    'Bottom Wall
      if(OldDirection==SW)
        NewDirection := NW
      else 
        NewDirection := NE
    RW, PAD:    'Right Wall or Paddle if Paddle is in the game
      if(OldDirection==SE)
        NewDirection := SW
      else 
        NewDirection := NW
    NWC:   'NorthWest Corner
        NewDirection := SE
    SWC:   'SouthWest Corner
        NewDirection := NE
    NEC:   'NorthEast Corner
        NewDirection := SW
    SEC:   'SouthEast Corner
        NewDirection := NW
  
  return NewDirection
  
PUB MoveBall
  ''--------------------------------
  ''Function to update Ball position
  ''--------------------------------
  case dirBall
    SE:    'SouthEast
      ++xBall
      ++yBall
    NE:    'NorthEast
      ++xBall
      --yBall
    NW:    'NorthWest
      --xBall
      --yBall
    SW:    'SouthWest
      --xBall
      ++yBall

PUB WhatKey | UpDown
  ''--------------------------------------------------------------
  ''WhatKey reads the serial port looking for the Up and Down keys
  ''to move the paddle. It returns 0 if no 'valid' key is pressed
  ''otherwise it returns Up or Down.
  ''--------------------------------------------------------------
  UpDown := SPORT.rxcheck
  case UpDown
    UPCHAR:
      UpDown := UP
    DNCHAR:
      UpDown := DOWN
    other:
      UpDown := 0

  return UpDown

PUB MovePaddle | PadDir
  ''-----------------------------------
  ''See if Paddle movement is requested
  ''-----------------------------------
  PadDir := WhatKey
  Case PadDir
    UP:
      If(yPaddle-HPH-1)>0+PADINC
        yPaddle-=PADINC
    DOWN:
      If(yPaddle+HPH+1)<SCREENMAXY-PADINC
        yPaddle+=PADINC
    OTHER:

PUB PlotBall(x,y,k)
  ''-------------------------------------------------------
  ''Draw a series of horizontal lines to form a square ball 
  ''-------------------------------------------------------
    'SCREEN.displayWait(1)
    case k
      PEN_ERASE:
        SCREEN.plotBox(SCREEN.displayColor(0,0,0),x-1,y-1,x+1,y+1)
      PEN_DRAW:
        SCREEN.plotBox(SCREEN.displayColor(3,2,1),x-1,y-1,x+1,y+1)
       
PUB DrawPaddle(x,y,k)
  ''-------------------------------------------------------
  ''Draw the Paddle (or undraw the Paddle) at x,y
  ''The paddle right now is just a series of vertical lines
  ''-------------------------------------------------------
    case k
      PEN_ERASE:
        SCREEN.plotBox(SCREEN.displayColor(0,0,0),x-1,y-HPH,x+1,y+HPH)
      PEN_DRAW:
        SCREEN.plotBox(SCREEN.displayColor(3,2,1),x-1,y-HPH,x+1,y+HPH)

{{
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
}}    