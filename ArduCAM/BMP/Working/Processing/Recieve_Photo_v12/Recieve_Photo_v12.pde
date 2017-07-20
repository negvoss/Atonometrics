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
boolean displayAnalysis = false;

String msg = "";

int picWidth = 650;
int picHeight = picWidth*3/4;


int totalPixels = 0;

int redTotal = 0;
int greenTotal = 0;
int blueTotal = 0;

int whiteTotal = 0;
int blackTotal = 0;




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
  displayImageLoading();
  displayImage();
  displayImageBox();
  
  if (!displayAnalysis) {
    displayConsoleBox();
    displayConsoleMessages();
  } else {
    displayAnalysisBox();
    displayAnalysisResults();
  }
  
  recieveMessage();
}

void recieveMessage() {
  while (myPort.available() > 0) {
    if (inPicture && !finished && readyToRecieve) {
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
  if (inPicture) {
    stroke(0);
    strokeWeight(1);
    fill(200);
    textSize(20);
    textAlign(LEFT);
    if (!finished) {
      text("Loading capture... ~ " + size/1000 + " KB ------- " + index*100/size + "%",width - picWidth,picHeight + 30);
    } else {
      text("Loading capture... ~ " + size/1000 + " KB ------- " + "100%",width - picWidth,picHeight + 30);
    }
  }
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
  float blueMultiplier = 1.3; // Camera does not detect blue very well. (Mistakes it for green).
  
  for (color p:img.pixels) {
    if (red(p) > green(p) && red(p) > blue(p)*blueMultiplier) {
      redTotal++;
    }
    if (green(p) > red(p) && green(p) > blue(p)*blueMultiplier) {
      greenTotal++;
    }
    if (blue(p)*blueMultiplier > red(p) && blue(p)*blueMultiplier > green(p)) {
      blueTotal++;
    }
    
    if (red(p) + green(p) + blue(p) > 360) {
      whiteTotal++;
    } else {
      blackTotal++;
    }
    totalPixels++;
  }
}

void displayAnalysisBox() {
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
  text("Analysis",20,50);
}

void displayAnalysisResults() {
  stroke(0);
  strokeWeight(3);
  fill(255,255,0);
  ellipse(width - picWidth - 200,250,200,200);
  line(width - picWidth - 200,250,width - picWidth - 200,150);
  
  float rRatio = (float)redTotal*TWO_PI/totalPixels;
  float gRatio = (float)greenTotal*TWO_PI/totalPixels;
  float bRatio = (float)blueTotal*TWO_PI/totalPixels;
  //println(redTotal);
  //println(totalPixels);
  //println(rRatio);
  
  stroke(0);
  strokeWeight(2);
  line(width - picWidth - 200,250,cos(rRatio - HALF_PI)*100 + width - picWidth - 200,sin(rRatio - HALF_PI)*100 + 250);
  rotate(rRatio - HALF_PI);
  line(width - picWidth - 200,250,cos(gRatio - HALF_PI)*100 + width - picWidth - 200,sin(gRatio - HALF_PI)*100 + 250);
  rotate(gRatio - HALF_PI);
  line(width - picWidth - 200,250,cos(bRatio - HALF_PI)*100 + width - picWidth - 200,sin(bRatio - HALF_PI)*100 + 250);
  
  //stroke(0);
  //strokeWeight(1);
  //fill(200);
  //textAlign(LEFT);
  //textSize(10);
  //text("Red", width - picWidth - 200,250);
}



void keyPressed() {
  if (key == ' ') {
    displayAnalysis = true;
  }
}



void reset() {  
  index = 0;
  consoleMessages = new ArrayList<String>();
  
  recievingSize = false;
  inPicture = false;
  finished = false;
  displayAnalysis = false;
  
  msg = "";
  
  picWidth = 650;
  picHeight = picWidth*3/4;
  
  background(51);
}