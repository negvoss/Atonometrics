PImage img;
boolean analysisDone = false;

int[] counts = new int[200];

void setup() {
  img = loadImage("C:/Users/aaron/Pictures/desert beast.jpg");
  size(800,600);
  
  analyzeImage();
}

void draw() {
  background(51);
  if (analysisDone) {
    displayAnalysisResults();
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
  strokeWeight(3);
  noFill();
  rect(0,0,width,height);
  
  stroke(0);
  strokeWeight(1);
  for (int i = 0; i < counts.length; i++) {
    fill(255,255,0);
    println((float)i*width/counts.length);
    rect(i*width/counts.length,height,width/counts.length,-(float)counts[i]/400);
  }
}