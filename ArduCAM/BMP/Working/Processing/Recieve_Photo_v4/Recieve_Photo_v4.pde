import processing.serial.*;

Serial myPort;

int size;
byte[] data;
int index = 0;
PImage img;
PImage atono;

boolean recievingSize = false;
boolean inPicture = false;
boolean finished = false;

String msg = "";

int picWidth = 650;
int picHeight = picWidth*3/4;




void settings() {
  fullScreen();
}


void setup() {
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.clear();
  atono = loadImage("C:/Users/aaron/Downloads/atonometrics.png");
}


void draw() {
  background(51);
  
  recieveMessage();
  
  showLogo();
  displayImageLoading();
  displayImage();
  displayImageBox();
  displayConsole();
}

void recieveMessage() {
  while (myPort.available() > 0) {
    if (inPicture && !finished) {
      data[index] = myPort.readBytes(1)[0];
      index++;
      
      stroke(0);
      strokeWeight(1);
      fill(255 - index*250/size,index*250/size,0);
      rect(width - picWidth,picHeight*2/5,index*picWidth/size,picHeight/5);
      
      if (index == size - 1) {
        saveBytes("recieved.bmp", data);
        img = loadImage("recieved.bmp");
        picHeight = picWidth*img.height/img.width;
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

void showLogo() {
  imageMode(CENTER);
  image(
    atono,
    width - picWidth/2,
    height - (height - picHeight)/2,
    picWidth,
    picWidth*atono.height/atono.width
  );
}

void displayImageLoading() {
  if (inPicture) {
    stroke(0);
    strokeWeight(1);
    fill(200);
    textSize(20);
    textAlign(CENTER);
    text("Loading capture... ~ " + size/1000 + " KB",width - picWidth/2,picHeight/3);
    text(index*100/size + "%",width - picWidth/2,picHeight*2/3);
  }
}

void displayImage() {
  if (finished) {
    imageMode(CORNER);
    image(img,width - picWidth,0,picWidth,picHeight);
  }
}

void displayImageBox() {
  stroke(0);
  strokeWeight(3);
  noFill();
  rect(width - picWidth,0,picWidth,picHeight);
}

void displayConsole() {
  
}