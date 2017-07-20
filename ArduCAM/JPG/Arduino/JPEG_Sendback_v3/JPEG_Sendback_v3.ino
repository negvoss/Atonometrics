// This program does these tasks:
// 1. Set the camera to JEPG output mode.
// 2. Capture a JPEG photo and buffer the image to FIFO. (Camera Memory)
// 3. Write the picture data to the SD card.
// 5. Close the file.



#include <Wire.h>
#include <ArduCAM.h>
#include <SPI.h>
#include <SD.h>
#include "memorysaver.h"

const int  CS = 7; // ArduCAM Chip Select (Slave Select) port for the Arduino.
#define SD_CS   9  // SD Card Chip Select (Slave Select) port for the Arduino.

bool is_header = false;

File outFile;

ArduCAM myCAM(OV5642, CS);

uint8_t read_fifo_burst(ArduCAM myCAM);

void setup() {
  uint8_t vid, pid;
  uint8_t temp;

  Wire.begin();

  Serial.begin(115200);
  
  // To view serial communication, go to Tools --> Serial Monitor
  // Make sure the baud number (bottom right) matches the number inside Serial.begin().
  sendText("ArduCAM Start!");
  sendText("----------------------------");


  pinMode(CS, OUTPUT); // Set the CS pin as an output.


  SPI.begin();
  // Check if the ArduCAM SPI bus is OK
  myCAM.write_reg(ARDUCHIP_TEST1, 0x55);
  temp = myCAM.read_reg(ARDUCHIP_TEST1);
  
  if (temp != 0x55){
    sendText("SPI interface Error!");
    while(1);
  }


  // Check if the camera module type is OV5642
  myCAM.rdSensorReg16_8(OV5642_CHIPID_HIGH, &vid);
  myCAM.rdSensorReg16_8(OV5642_CHIPID_LOW, &pid);
  if ((vid != 0x56) || (pid != 0x42))
    sendText("Can't find OV5642 module!");
  else
    sendText("OV5642 detected.");



  if (!SD.begin(SD_CS)) { // Initialize SD Card
    sendText("SD Card Error!");
    while (1); // If failed, stop here
  }
  else
    sendText("SD Card detected.");
    sendText("----------------------------");


  // Change to JPEG capture mode and initialize the OV5642 module
  myCAM.set_format(JPEG);
  myCAM.InitCAM();
  myCAM.set_bit(ARDUCHIP_TIM, VSYNC_LEVEL_MASK);
  myCAM.clear_fifo_flag();
  myCAM.write_reg(ARDUCHIP_FRAMES, 1);

  myCAM.flush_fifo();
  myCAM.clear_fifo_flag();
  myCAM.OV5642_set_JPEG_size(OV5642_320x240);
  delay(1000);

  // Start capture
  myCAM.start_capture();
  sendText("Capture Starting!");
  
  while ( !myCAM.get_bit(ARDUCHIP_TRIG, CAP_DONE_MASK)); 
  sendText("Capture Finished!");
  sendText("----------------------------");
  

  read_fifo_burst(myCAM);
  
  // Clear the capture done flag
  myCAM.clear_fifo_flag();
  delay(5000);


//  Send photo data back to computer on the Serial port.

  outFile.seek(0);
  

  if (outFile) {
    Serial.print("File size: ~");
    Serial.print(outFile.size()/1000);
    sendText(" kilobytes.");
    
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
  // Nothing happens after setup().
}


void sendText(char msg[]) {
  Serial.print(msg);
  Serial.print("Yt4H3g"); // Code for end of message.
}



uint8_t read_fifo_burst(ArduCAM myCAM) {
  uint8_t temp = 0, temp_last = 0;
  uint32_t length = myCAM.read_fifo_length();
  static int i = 0;
  byte buf[256];
  
  if (length >= MAX_FIFO_SIZE) { // 8M
    Serial.println("Over size.");
    return 0;
  }
  
  if (length == 0 ) { //0 kb
    Serial.println("Size is 0.");
    return 0;
  } 
  myCAM.CS_LOW();
  myCAM.set_fifo_burst(); // Set fifo burst mode
  i = 0;
  while ( length-- ) {
    temp_last = temp;
    temp =  SPI.transfer(0x00);
    // Read JPEG data from FIFO
    if ( (temp == 0xD9) && (temp_last == 0xFF) ) { // If find the end, break while,
        buf[i++] = temp;  // Save the last  0XD9     
       //Write the remain bytes in the buffer
        myCAM.CS_HIGH();
        outFile.write(buf, i);
        is_header = false;
        myCAM.CS_LOW();
        myCAM.set_fifo_burst();
        i = 0;
    }
    if (is_header == true) {
       //Write image data to buffer if not full
        if (i < 256)
        buf[i++] = temp;
        else {
          //Write 256 bytes image data to file
          myCAM.CS_HIGH();
          outFile.write(buf, 256);
          i = 0;
          buf[i++] = temp;
          myCAM.CS_LOW();
          myCAM.set_fifo_burst();
        }
    }
    else if ((temp == 0xD8) & (temp_last == 0xFF)) {
      is_header = true;
      myCAM.CS_HIGH();

      SD.remove("capture.jpg");
      
      //Open the new file
      outFile = SD.open("capture.jpg",FILE_WRITE);
      if (!outFile) {
        sendText("Error creating file");
        while(1);
      }
      myCAM.CS_LOW();
      myCAM.set_fifo_burst();
      buf[i++] = temp_last;
      buf[i++] = temp;
    }
  }
   myCAM.CS_HIGH();
   return 1;
}





