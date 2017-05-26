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


UTFT    myGLCD(ILI9325D_8,19,18,17,16);//Configuro pines de control en el display
URTouch  myTouch( 15,10,14, 9, 8);//Configuro pines de control en  el tactil

void setup()
{
  myGLCD.InitLCD(); //inicializo el Display
  myGLCD.fillScr(VGA_BLACK);//Fijo un color de pantalla
  myTouch.InitTouch(); //Inicializo el tactil
  myTouch.setPrecision(PREC_MEDIUM);//Fijo una precicion de sensado
}

void loop()
{
  long x, y;
  
  while (myTouch.dataAvailable() == true) //Si hay algo apoyado en el tactil realizo la lectura y conversion de datos
  {
    myTouch.read();
    x =  myTouch.getX();//obtengo numero de pixel en X donde estoy apoyando
    y =  myTouch.getY();//obtengo numero de pixel en Y
   
    if ((x!=-1) and (y!=-1)) //valido la lectura de datos
    {
      myGLCD.drawPixel ( x,  240 - y); //imprimo lo sensado en el display 
    }
  }
}

