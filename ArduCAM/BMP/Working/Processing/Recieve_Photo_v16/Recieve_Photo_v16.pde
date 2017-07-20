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

float averageBrightness;


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
        
        println("Press Space to view analysis results");
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
  float total = 0;
  
  for (color p:img.pixels) {
    for (int i = 0; i < counts.length; i++) {
      float brightness = red(p) + green(p) + blue(p);
      float min = (float)i*765/counts.length;
      float max = (float)(i + 1)*765/counts.length; // 765 = 255*3 (max value on far right)
      if (brightness >= min && brightness < max) {
        counts[i]++;
        total += brightness;
      }
    }
  }
  averageBrightness = (total/img.pixels.length)/765;
  analysisDone = true;
}

void displayAnalysisResults() {
  int linePosition = 0;
  boolean hitWhite = false;
  for (int i = 0; i < counts.length; i++) {
    if ((float)(i + 1)*765/counts.length > averageBrightness*765) {
      fill(255);
    } else {
      fill(0);
      if (!hitWhite) {
        linePosition = counts[i];
        hitWhite = true;
      }
    }
    
    noStroke();
    
    rect(
      i*(width - picWidth - 50)/counts.length,
      height - 50,
      (width - picWidth - 50)/counts.length,
      -(float)counts[i]/10
    );
  }
  if (averageBrightness > 0) {
    stroke(255,255,0);
    strokeWeight(2);
    line(averageBrightness*(width - picWidth - 50),height - (float)linePosition/10 - 250,averageBrightness*(width - picWidth - 50),100);
    
    noStroke();
    fill(200);
    textAlign(CENTER);
    textSize(10);
    text("Average Brightness: " + String.format("%2.2f",averageBrightness*255) + "/255",averageBrightness*(width - picWidth - 50),height - (float)linePosition/10 - 220);
  }
}

void displayAnalysisBox() {
  stroke(0);
  strokeWeight(3);
  fill(51);
  rect(0,0,width - picWidth - 50,100);
  
  noFill();
  rect(0,100,width - picWidth - 50,height - 50);
  rect(0,height - 50,width - picWidth - 50,50);
  
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