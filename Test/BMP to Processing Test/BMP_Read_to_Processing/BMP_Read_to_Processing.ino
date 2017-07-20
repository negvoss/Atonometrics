#include <SD.h>;
#include <SPI.h>;

File outFile;

void setup() {
  Serial.begin(115200);

  if (!SD.begin(9)) {
    //Serial.println("SD card error.");
    return;
  }
  
  outFile = SD.open("capture.bmp");
  
  if (outFile) {
    Serial.print("File Size: Yt4H3g");
    Serial.print(outFile.size());
    Serial.print(" Bytes Yt4H3g");
    
    Serial.print("xlQPnM64"); // Code for start of picture
    
    while (outFile.available()) { // Read from file until there's nothing left to read.
      Serial.write(outFile.read());
    }
    
    outFile.close();
  } else {
    Serial.println("Error opening file");
  }
}

void loop() {
  //Nothing happens after setup().
}

