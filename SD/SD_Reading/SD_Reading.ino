//* MOSI - pin 11
//* MISO - pin 12
//* CLK  - pin 13
//* CS   - pin 9

//**NOTE**
//Only one file can be open at a time, so you have to close one before opening another.



#include <SPI.h>
#include <SD.h>



File myFile;

void setup() {
  Serial.begin(9600);
  // To view serial communication, go to Tools --> Serial Monitor
  // Make sure the baud number (bottom right) matches the number inside Serial.begin().
  while (!Serial) {
    // Wait for Serial port to connect.
  }


  Serial.print("Initializing SD card... ");

  if (!SD.begin(9)) { // Initialization of SD Card failed.
    Serial.println("failed!");
    return;
  }
  Serial.println("done!");
  Serial.println("----------------------------");

  char filename[] = "1.jpg"; // The file to be opened

  // Open the file for reading:
  myFile = SD.open(filename);
  if (myFile) {
    unsigned char pixels[14140]; //TODO: Determine length
    
    Serial.print("Opening ");
    Serial.println(filename);
    Serial.println("----------------------------");
    Serial.println("Stats For Nerds:");

    // Read from the file until there's nothing else to read.
    unsigned long i = 0;
    while (myFile.available()) {
      unsigned char index = myFile.read();
      pixels[i] = index;
//      if (i > 0) {
//        Serial.print("pixels[");
//        Serial.print(i);
//        Serial.print("]: ");
//        Serial.println(pixels[i]);
//      }
      i++;
    }
    
    Serial.print("Pixels: ");
    //Serial.println(pixels[0]);
    myFile.close();
    
  } else {
    // If the file didn't open, print an error:
    Serial.print("Error opening ");
    Serial.println(filename);
  }
}








void loop() {
  //Nothing happens after setup().
}

