



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



  
  ''Ball Directions MODIFIED[][][]
  
  _UP    =       0               ''UP
  _DN    =       1               ''DOWN
  _LT    =       2               ''LEFT
  _RT    =       3               ''RIGHT

  ''ASCII Characters for Up and Down for the Paddle  MODIFIED[][][]
  UPCHAR  =     $38             ''8 is UP
  DNCHAR  =     $32             ''2 is DOWN
  LTCHAR  =     $34             ''4 is LEFT
  RTCHAR  =     $36             ''6 is RIGHT

  ''Constants for Up and Down [BALL] in the game      MODIFIED[][][]
  UP      =     1
  DOWN    =     2
  LEFT    =     3
  RIGHT   =     4
  

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
  xBall := SCREENWIDTH-SCREENWIDTH/2 ''''''''''''                               'MODIFIED [REPLACED 4 WITH 2 SO BALL IS IN MIDDLE]
  yBall := SCREENHEIGHT/2
  dirBall := _UP ''''''''''''''''''''''''''''''''                               'MODIFIED [REPLACED NW WITH _UP]
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
    MovePaddle                                                                  'TO MODIFY [CHANGE FUNC TO MOVEBALL, GET RID OF IF STATEMENT/BLOCK
    if(lasty <> yPaddle)
      ''Erase Paddle at old position
      DrawPaddle(xPaddle,lasty,PEN_ERASE)
      ''Draw Paddle at new position
      DrawPaddle(xPaddle,yPaddle,PEN_DRAW)
      lasty := yPaddle
     
    ''Get Ball/Boundary Status
    Bound := AtBoundary
    ''If we are not at the right boundary
    'if(Bound<>RW)                                                              'MODIFIED [CHANGED LARGER IF TO NO BOUNDARIES]
    ' ''If we are at a boundary
    if(Bound<>NOT_AT_BOUNDARY)
        'Change Ball Direction
        dirBall := ChangeDirection(Bound,dirBall)                               'MODIFIED[]
       
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
          xBall := SCREENWIDTH-SCREENWIDTH/2                                    'MODIFIED[]
          yBall := SCREENHEIGHT/2
          if(StartBallDir & $1)
            dirBall := _UP                                                      'MODIFIED[]
          else
            dirBall := -UP                                                      'MODIFIED[]
           
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
      xBall := SCREENWIDTH-SCREENWIDTH/2                                          'MODIFIED[]
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
  
PUB MoveBall '''''''''''''''''''''MODIFIED[][][]
  ''--------------------------------
  ''Function to update Ball position
  ''--------------------------------
  case dirBall
    _UP:    'up
      yBall := yBall -2     
    _DN:    'DOWN
      yBall := yBall+2    
    _LT:    'LEFT
      xBall := xBall-2 
    _RT:    'RIGHT
      xBall := xBall+2

PUB WhatKey | UpDown                   'MODIFIED[]
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
    LTCHAR:
      UpDown := LEFT
    RTCHAR:
      UpDown := RIGHT
    other:
      UpDown := 0

  return UpDown

PUB MovePaddle | PadDir                     'MODIFIED[FROM MOVEPADDLE TO MOVEBALL, ETC]
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


PUB getKeyPressed  | UpDown                 'MODIFIED[]
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
    LTCHAR:
      UpDown := LEFT
    RTCHAR:
      UpDown := RIGHT
    other:
      UpDown := 0

  return UpDown

PUB newDirection(whichKey, oldDirection) : newDirection
 ''--------------------------------------------------------
  ''gets key pressed, changes ball's direction if different, adds ball if different
  ''--------------------------------------------------------
  Case whichKey 
    UP:    'UP
      if(OldDirection<>_UP)
        balls++
        NewDirection := _UP
    DOWN:    'down
      if(OldDirection<>_DN)
        balls++
        NewDirection := _DN
    LEFT:    'left
      if(OldDirection<>_LT)
        balls++
        NewDirection := _LT
    RIGHT:    'Right
      if(OldDirection<>_RT)
        balls++
        NewDirection := _RT
    other:
       return oldDirection
  
  return NewDirection


PUB setNewBall(oldDirection)

  


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
