import processing.serial.*;

Serial myPort;

int size = 307254;
byte[] data = new byte[size];
int index = 0;


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
    data[index] = myPort.readBytes(1)[0];
    index++;
    
    print(index*100/size);
    println("% complete.");
    
    if (index == size - 1) {
      saveBytes("recieved.bmp", data);
      PImage img = loadImage("recieved.bmp");
      image(img,0,0,width,height);
    }
  }
}