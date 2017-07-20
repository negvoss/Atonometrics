import processing.serial.*;
import java.util.*;

Serial myPort;

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
    print(character);
  }
}