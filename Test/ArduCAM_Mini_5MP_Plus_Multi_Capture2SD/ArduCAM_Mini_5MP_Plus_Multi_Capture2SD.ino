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
int total_time = 0;

ArduCAM myCAM(OV5642, CS);

uint8_t read_fifo_burst(ArduCAM myCAM);

void setup() {
  uint8_t vid, pid;
  uint8_t temp;

  Wire.begin();

  Serial.begin(115200);
  // To view serial communication, go to Tools --> Serial Monitor
  // Make sure the baud number (bottom right) matches the number inside Serial.begin().
  Serial.println("ArduCAM Start!");
  Serial.println("----------------------------");


  pinMode(CS, OUTPUT); // Set the CS pin as an output.


  SPI.begin();
  // Check if the ArduCAM SPI bus is OK
  myCAM.write_reg(ARDUCHIP_TEST1, 0x55);
  temp = myCAM.read_reg(ARDUCHIP_TEST1);
  
  if (temp != 0x55){
    Serial.println("SPI interface Error!");
    while(1);
  }


  // Check if the camera module type is OV5642
  myCAM.rdSensorReg16_8(OV5642_CHIPID_HIGH, &vid);
  myCAM.rdSensorReg16_8(OV5642_CHIPID_LOW, &pid);
  if ((vid != 0x56) || (pid != 0x42))
    Serial.println("Can't find OV5642 module!");
  else
    Serial.println("OV5642  detected.");



  if (!SD.begin(SD_CS)) { // Initialize SD Card
    Serial.println("SD Card Error!");
    while (1); // If failed, stop here
  }
  else
    Serial.println("SD Card detected.");
    Serial.println("----------------------------");


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
  Serial.println("Capture Starting!");
    total_time = millis();
  while ( !myCAM.get_bit(ARDUCHIP_TRIG, CAP_DONE_MASK)); 
  Serial.println("Capture Finished!");
  Serial.println("----------------------------");
  total_time = millis() - total_time;
  Serial.println("Stats For Nerds:");
  Serial.println();
  Serial.print("Capture time: ");
  Serial.print(total_time, DEC);
  Serial.println(" miliseconds");
  total_time = millis();
  read_fifo_burst(myCAM);
  total_time = millis() - total_time;
  Serial.print("Saving  time: ");
  Serial.print(total_time, DEC);
  Serial.println(" miliseconds");
  // Clear the capture done flag
  myCAM.clear_fifo_flag();
  delay(5000);
}

void loop() {
  // Nothing happens after setup().
}

uint8_t read_fifo_burst(ArduCAM myCAM) {
  uint8_t temp = 0, temp_last = 0;
  uint32_t length = 0;
  static int i = 0;
  static int k = 0;
  char str[8];
  File outFile;
  byte buf[256]; 
  length = myCAM.read_fifo_length();
  Serial.print("FIFO  length: ");
  Serial.println(length, DEC);
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
        outFile.close();
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
      //Create a avi file
      k = k + 1;
      itoa(k, str, 10);
      strcat(str, ".jpg");
      //Open the new file
      outFile = SD.open(str, O_WRITE | O_CREAT | O_TRUNC);
      if (! outFile) {
        Serial.println("Open file failed");
        while (1);
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
