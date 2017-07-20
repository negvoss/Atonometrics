#include <SPI.h>
#include <SD.h>

File myFile;



void setup() {
  Serial.begin(9600);

  Serial.println("Initializing SD card...");

  if (!SD.begin(9)) {
    Serial.println("initialization failed!");
    return;
  }
  
  Serial.println("initialization done.");

  // Only one file can be open at a time.
  // Close one before opening another.
  
  myFile = SD.open("capture.bmp",FILE_READ);
  if (myFile) {
    Serial.println("Contents:");

    long counter = 0;

//    for (int i = 0; i < 20; i++) {
//      Serial.print(myFile.read());
//      Serial.print(" ");
//    }
//    Serial.println();
 
    
    
    while (myFile.available()) { // Read from file until there's nothing left to read.
      myFile.read();
      //Serial.write(myFile.read());
      counter++;
    }
    
    myFile.close();
    Serial.println(counter);
    Serial.println("Done.");
  } else {
    Serial.println("Error opening file");
  }
}

void loop() {
  // Nothing happens after setup().
}
