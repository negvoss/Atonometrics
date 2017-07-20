import processing.serial.*;
import java.util.*;

Serial myPort;
String msg = "";
boolean inPicture = false;
byte[] imageData = new byte[300000]; // Number of pixels in photo * 3 for RGB
int imageDataIndex = 0;

void setup() {
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
    if (character.equals("\n")) { // End of message
      if (msg.equals("xlQPnM64")) { // Code for start of picture data.
        println("Starting transfer of picture data");
        inPicture = true;
      } else if (msg.equals("zsKdR98Q")){
        println("End of picture data");
        inPicture = false;
        print(imageData);
      } else {
        println(msg);
      }
      msg = "";
    } else if (!inPicture){
      msg += character;
    } else {
      imageData[imageDataIndex] = (byte)data;
      imageDataIndex++;
    }
  }
}