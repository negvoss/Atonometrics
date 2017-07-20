#include <SD.h>;
#include <SPI.h>;

File outFile;

void setup() {
  Serial.begin(115200);
  sendText("\n\n\n\n\n\n\n\n\n\n\n");

  if (!SD.begin(9)) {
    sendText("SD card error.");
    return;
  }
  
  outFile = SD.open("capture.bmp");
  
  if (outFile) {
    Serial.print("File size: ");
    Serial.print(outFile.size());
    sendText(" bytes.");

    Serial.print("zXQ64R7D"); // Code for file size
    Serial.print(outFile.size());
    Serial.print("Yt4H3g");
    
    Serial.print("xlQPnM64"); // Code for start of picture
    
    while (outFile.available()) { // Read from file until there's nothing left to read.
      Serial.write(outFile.read());
    }
    
    outFile.close();
  } else {
    sendText("Error opening file");
  }
}

void loop() {
  //Nothing happens after setup().
}

void sendText(char msg[]) {
  Serial.print(msg);
  Serial.print("Yt4H3g"); // Code for end of message.
}

