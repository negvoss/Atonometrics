import processing.serial.*;

Serial myPort;

int size;
byte[] data;
int index = 0;
ArrayList<String> consoleMessages = new ArrayList<String>();
PImage img;
PImage atono;

boolean readyToRecieve = false;
boolean recievingSize = false;
boolean inPicture = false;
boolean finished = false;
boolean analysisDone = false;
boolean displayAnalysis = false;

int[] counts = new int[200];

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
  
  showLogo();
  if (inPicture) {
    displayImageLoading();
  }
  displayImage();
  displayImageBox();
  
  if (!displayAnalysis) {
    displayConsoleBox();
    displayConsoleMessages();
  } else {
    displayAnalysisResults();
    displayAnalysisBox();
  }
  
  recieveMessage();
}

void recieveMessage() {
  while (myPort.available() > 0) {
    if (inPicture && !finished && readyToRecieve) {
      data[index] = myPort.readBytes(1)[0];
      index++;
      
      if (index == size - 1) {
        saveBytes("recieved.bmp", data);
        img = loadImage("recieved.bmp");
        picHeight = picWidth*img.height/img.width;
        finished = true;
        
        println("Done! \n\n\n\n");
        writeToConsole("Done!");
        
        analyzeImage();
        
        println("Press Space to view analysis");
        writeToConsole("Press Space to view analysis");
        
        readyToRecieve = false;
      }
    } else {
      char chr = myPort.readChar();
      msg += chr;
      
      if (msg.endsWith("Yt4H3g")) {
        msg = msg.split("Yt4H3g")[0];
        if (!recievingSize && readyToRecieve) {
          println(msg);
          writeToConsole(msg);
        } else if (readyToRecieve) {
          size = Integer.parseInt(msg);
          data = new byte[size];
        }
        if (msg.endsWith("R4p2Dyf7")) {
          readyToRecieve = true;
          reset();
        }
        msg = "";
      }
      
      if (msg.startsWith("zXQ64R7D")) {
        msg = "";
        recievingSize = true;
      }
      
      if (msg.endsWith("xlQPnM64") && readyToRecieve) {
        println("Starting transfer of picture data.");
        writeToConsole("Starting transfer of picture data.");
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
  stroke(0);
  strokeWeight(1);
  fill(200);
  textSize(20);
  textAlign(LEFT);
  if (!finished) {
    text("Loading capture... ~ " + size/1000 + " KB                                               " + index*100/size + "%",width - picWidth,picHeight + 30);
  } else {
    text("Loading capture... ~ " + size/1000 + " KB                                               " + "100%",width - picWidth,picHeight + 30);
  }
  stroke(0);
  strokeWeight(1);
  noFill();
  rect(width - 350,picHeight + 15,250,15);
  
  fill(255 - index*255/size,index*255/size,0);
  rect(width - 350,picHeight + 15,index*250/size,15);
}

void displayImage() {
  if (img != null) {
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

void displayConsoleBox() {
  stroke(0);
  strokeWeight(3);
  noFill();
  rect(0,0,width - picWidth - 50,height);
  
  line(0,100,width - picWidth - 50,100);
  
  stroke(0);
  strokeWeight(1);
  fill(200);
  textSize(40);
  textAlign(LEFT);
  text("Console",20,50);
}

void writeToConsole(String message) {
  consoleMessages.add(message);
}

void displayConsoleMessages() {
  int consoleCounter = 0;
  stroke(0);
  strokeWeight(1);
  fill(200);
  textSize(20);
  textAlign(LEFT);
  for (String s:consoleMessages) {
    text(s,20,150 + consoleCounter*40);
    consoleCounter++;
  }
}


void analyzeImage() {
  for (color p:img.pixels) {
    for (int i = 0; i < counts.length; i++) {
      float total = red(p) + green(p) + blue(p);
      float min = (float)i*765/counts.length;
      float max = (float)(i + 1)*765/counts.length; // 765 = 255*3 (max value)
      if (total >= min && total < max) {
        counts[i]++;
      }
    }
  }
  analysisDone = true;
}

void displayAnalysisResults() {
  stroke(0);
  strokeWeight(1);
  for (int i = 0; i < counts.length; i++) {
    fill(255,255,0);
    println((float)i*(width - picWidth - 50)/counts.length);
    rect(
      i*(width - picWidth - 50)/counts.length,
      height,
      (width - picWidth - 50)/counts.length,
      -(float)counts[i]/10
    );
  }
}

void displayAnalysisBox() {
  stroke(0);
  strokeWeight(3);
  fill(51);
  rect(0,0,width - picWidth - 50,100);
  
  noFill();
  rect(0,100,width - picWidth - 50,height - 100);
  
  stroke(0);
  strokeWeight(1);
  fill(200);
  textSize(40);
  textAlign(LEFT);
  text("Range of transmission",20,50);
}



void keyPressed() {
  if (key == ' ') {
    if (displayAnalysis) {
      displayAnalysis = false;
    } else {
      displayAnalysis = true;
    }
  }
}



void reset() {  
  index = 0;
  consoleMessages = new ArrayList<String>();
  
  recievingSize = false;
  inPicture = false;
  finished = false;
  analysisDone = false;
  
  msg = "";
  
  picWidth = 650;
  picHeight = picWidth*3/4;
  
  background(51);
}