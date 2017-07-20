import processing.serial.*;

Serial myPort;

int size;
byte[] data;
int index = 0;
ArrayList<String> consoleMessages = new ArrayList<String>();
PImage img;
PImage atono;
PImage gradient;

boolean readyToRecieve = false;
boolean recievingSize = false;
boolean inPicture = false;
boolean finished = false;
boolean analysisDone = false;
boolean displayAnalysis = false;

int graphQuality = 200;
int[] counts = new int[graphQuality];

float white_percent = 0;
float black_percent = 0;

float threshold = 100;

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
  atono = loadImage("../../atonometrics.jpg");
  gradient = loadImage("../../black_to_white.jpg");
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
        saveBytes("recieved.jpg", data);
        img = loadImage("recieved.jpg");
        picHeight = picWidth*img.height/img.width;
        finished = true;
        
        println("Done! \n\n\n\n");
        writeToConsole("Done! - Press Space to view results");
        writeToConsole("----------------------------");
        
        println("Press the reset button on the arduino to analyze a new picture!");
        writeToConsole("Press the reset button on the arduino to analyze a new picture!");
        
        
        analyzeImage();        
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
  
  text("Loading capture... ~ " + size/1000 + " KB.",width - picWidth,picHeight + 30);
  
  if (!finished) {
    text(index*100/size + "%",width - 70,picHeight + 30);
  } else {
    text(              "100%",width - 70,picHeight + 30);
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
  
  textAlign(CENTER);
  textSize(25);
  text("Press Space to go to the analysis.",width - (width - picWidth)/2 + 50,height - 27);
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
  counts = new int[graphQuality];
  int white = 0;
  int black = 0;
  
  float total = 0;
  
  for (color p:img.pixels) {
    for (int i = 0; i < counts.length; i++) {
      float brightness = red(p) + green(p) + blue(p);
      float min = (float)i*765/counts.length;
      float max = (float)(i + 1)*765/counts.length; // 765 = 255*3 (max value on far right)
      if (brightness >= min && brightness < max) {
        counts[i]++;
        total += brightness;
        if (brightness < threshold*3) {
          black++;
        } else {
          white++;
        }
      }
    }
  }
  white_percent = (float)white*100/(white + black);
  black_percent = (float)black*100/(white + black);
  
  averageBrightness = (total/img.pixels.length)/765;
  analysisDone = true;
}

void displayAnalysisResults() {
  
  for (float i = 0; i < 10; i++) {
    float h = (10 - i)*(height - 150)/10 + 100;stroke(0,255,100);
    strokeWeight(1);
    line(0,h,width - picWidth - 50,h);
    
    stroke(0);
    strokeWeight(1);
    fill(255,255,0);
    textAlign(LEFT);
    textSize(10);
    text(String.format("%4.0f",i*(height - 150)),width - picWidth - 40,h);
  }
  
  boolean hitWhite = false;
  
  for (int i = 0; i < counts.length; i++) {
    if ((float)(i + 1)*765/counts.length < averageBrightness*765) {
      if (!hitWhite) {
        hitWhite = true;
      }
    }
    
    fill(i*255/counts.length);
    
    stroke(50,100,255);
    strokeWeight(0.1);
    
    if (img != null) {
      rect(
        i*(width - picWidth - 50)/counts.length,
        height - 50,
        (width - picWidth - 50)/counts.length,
        -(float)counts[i]*7500/(img.width*img.height) // 7680 = ratio of 10.
      );
    }
  }
  
  if (averageBrightness > 0) {
    stroke(255,255,0);
    strokeWeight(2);
    line(averageBrightness*(width - picWidth - 50),210,averageBrightness*(width - picWidth - 50),height - 50);
    
    stroke(255,0,0);
    strokeWeight(2);
    textSize(15);
    fill(255,0,0);
    
    textAlign(CENTER);
    
    line((threshold/250)*(float)(width - picWidth - 65),200,(threshold/250)*(float)(width - picWidth - 65),height - 50);
    line((threshold/250)*(float)(width - picWidth - 65),100,(threshold/250)*(float)(width - picWidth - 65),150);
    text(
      "      " + String.format("%2.2f",black_percent) + "% soiling --- " + "Threshold --- " + String.format("%2.2f",white_percent) + "% transmission ",
      (threshold/250)*(width - picWidth - 50),
      180
    );
    
    
    textAlign(LEFT);
    textSize(12);
    fill(255,255,0);
    text("Average Brightness: \n" + String.format("%2.2f",averageBrightness*255) + "/255",averageBrightness*(width - picWidth - 50) + 40,197);
  }
  
  imageMode(CORNER);
  image(gradient,0,height - 50,width - picWidth - 50,50);
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
  
  fill(255);
  textAlign(CENTER);
  text("0",20,height - 10);
  
  fill(0);
  text("255",width - picWidth - 90,height - 10);
  
  fill(200,20,50);
  text("<--- Brightness --->",(width - picWidth - 50)/2,height - 10);
  
  fill(200);
  textSize(15);
  text("C\no\nu\nn\nt",width - picWidth - 25,25); //"Count"
  
  textSize(25);
  text("Press Space to go back to the console.",width - (width - picWidth)/2 + 50,height - 27);
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
}