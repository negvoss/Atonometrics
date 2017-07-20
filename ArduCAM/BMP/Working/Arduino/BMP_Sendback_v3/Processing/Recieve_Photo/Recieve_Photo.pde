//153666 Bytes = file size.


import processing.serial.*;
import java.util.*;

Serial myPort;
String msg = "";
boolean inPicture = false;
String imageData = "";

void setup() {
  size(600,600);
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.clear();
} 


void draw() {
  recieveMessage();
}

void recieveMessage() {
  while (myPort.available() > 0) {
    int data = myPort.read();
    String character = Character.toString((char)data);
    if (character.equals("\n") && !inPicture) { // End of message
      if (msg.equals("xlQPnM64")) { // Code for start of picture data.
        println("Starting transfer of picture data...");
        inPicture = true;
      } else {
        println(msg);
      }
      msg = "";
    } else if (!inPicture) {
      msg += character;
    } else {
      imageData += character;
      print(character);
    }
  }
    if (imageData.length() == 153666) {
    fill(255,0,0);
    ellipse(width/2,height/2,60,60);
    String[] str = new String[1];
    str[0] = imageData;
    saveStrings("capture.bmp", str);
    inPicture = false;
    imageData = "";
    noLoop();
  }  
}