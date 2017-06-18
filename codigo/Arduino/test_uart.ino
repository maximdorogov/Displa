// URTouch_QuickDraw 
// Copyright (C)2015 Rinky-Dink Electronics, Henning Karlsen. All right reserved
// web: http://www.RinkyDinkElectronics.com/
//
// This program is a quick demo of how to use the library.
//
// This program requires the UTFT library.
//
// It is assumed that the display module is connected to an
// appropriate shield or that you know how to change the pin 
// numbers in the setup.
//

#include <UTFT.h>
#include <URTouch.h>

// Initialize display
// ------------------
// Set the pins to the correct ones for your development board
// -----------------------------------------------------------
// Standard Arduino Uno/2009 Shield            : <display model>,19,18,17,16
// Standard Arduino Mega/Due shield            : <display model>,38,39,40,41
// CTE TFT LCD/SD Shield for Arduino Due       : <display model>,25,26,27,28
// Teensy 3.x TFT Test Board                   : <display model>,23,22, 3, 4
// ElecHouse TFT LCD/SD Shield for Arduino Due : <display model>,22,23,31,33
//
// Remember to change the model parameter to suit your display module!
UTFT    myGLCD(ILI9325D_8,19,18,17,16);

// Initialize touchscreen
// ----------------------
// Set the pins to the correct ones for your development board
// -----------------------------------------------------------
// Standard Arduino Uno/2009 Shield            : 15,10,14, 9, 8
// Standard Arduino Mega/Due shield            :  6, 5, 4, 3, 2
// CTE TFT LCD/SD Shield for Arduino Due       :  6, 5, 4, 3, 2
// Teensy 3.x TFT Test Board                   : 26,31,27,28,29
// ElecHouse TFT LCD/SD Shield for Arduino Due : 25,26,27,29,30
//
URTouch  myTouch( 15,10,14, 9, 8);

void setup()
{
  
  myGLCD.InitLCD();
  myGLCD.fillScr(VGA_BLACK);
  myTouch.InitTouch();
  myTouch.setPrecision(10);
  //delay(2000);
}

void loop()
{
  long x, y;

  //while (myTouch.dataAvailable() == true)
  //{ 
   
    myTouch.read();
    x =  myTouch.getX();
    y =  myTouch.getY();
   
    if ((x!=-1) and (y!=-1) and (x!=319) and (y!=0))
    {
      myGLCD.drawPixel ( x,  240 - y);
      digitalWrite(18,LOW);
      Serial.begin(38400);
      Serial.print(x);
      Serial.print(";");
      Serial.println(y,DEC);      
      Serial.end();
      digitalWrite(18,HIGH);
    }
  
    
    
  //}
}

