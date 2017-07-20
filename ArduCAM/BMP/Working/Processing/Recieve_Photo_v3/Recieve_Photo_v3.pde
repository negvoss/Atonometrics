import processing.serial.*;

Serial myPort;

int size;
byte[] data;
int index = 0;

boolean recievingSize = false;
boolean inPicture = false;
boolean finished = false;

String msg = "";


void setup() {
  size(320,240);
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.clear();
}


void draw() {
  recieveMessage();
}

void recieveMessage() {
  while (myPort.available() > 0) {
    if (inPicture && !finished) {
      data[index] = myPort.readBytes(1)[0];
      index++;
      
      stroke(0);
      fill(255,0,0);
      rect(0,height/2 - 50,index*width/size,100);
      
      if (index == size - 1) {
        saveBytes("recieved.bmp", data);
        PImage img = loadImage("recieved.bmp");
        image(img,0,0,width,height);
        finished = true;
        println("Done!");
      }
    } else {
      char chr = myPort.readChar();
      msg += chr;
      
      if (msg.endsWith("Yt4H3g")) {
        msg = msg.split("Yt4H3g")[0];
        if (!recievingSize) {
          println(msg);
        } else {
          size = Integer.parseInt(msg);
          data = new byte[size];
        }
        msg = "";
      }
      
      if (msg.startsWith("zXQ64R7D")) {
        msg = "";
        recievingSize = true;
      }
      
      if (msg.endsWith("xlQPnM64")) {
        println("Starting transfer of picture data.");
        inPicture = true;
        msg = "";
      }
    }
  }
}