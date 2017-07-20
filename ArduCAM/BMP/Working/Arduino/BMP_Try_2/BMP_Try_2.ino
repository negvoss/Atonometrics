// This program does these tasks:
// 1. Set the camera to BMP output mode.
// 2. Capture and buffer the image to FIFO. (Camera Memory)
// 3. Write the picture data to the SD card.
// 4. Close the file.

#include <SD.h>
#include <Wire.h>
#include <ArduCAM.h>
#include <SPI.h>
#include "memorysaver.h"


const int SPI_CS = 7; // ArduCAM Chip Select (Slave Select) port for the Arduino.
#define    SD_CS   9  // SD Card Chip Select (Slave Select) port for the Arduino.


#define BMPIMAGEOFFSET 66 // Length of the file header


// The file header for the .bmp format
// This gets written at the beginning of the file in grabImage().
// File Sandwich:
//                                    ______________
//                                   / File  Header \
//                                   \______________/
//                                   /  Image Data  \
//                                   \______________/
//             _____________________ /File Extension\ _____________________
//             I                     \______________/                     I
//             I           O                               |||  P         I
//             I           |                                |   |         I
//             I___________|________________________________|___|_________I




const int bmp_header[BMPIMAGEOFFSET] PROGMEM = {
  0x42, 0x4D, 0x36, 0x58, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x42, 
  0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00, 0x40, 0x01, 0x00, 0x00, 
  0xF0, 0x00, 0x00, 0x00, 0x01, 0x00, 0x10, 0x00, 0x03, 0x00, 0x00, 
  0x00, 0x00, 0x58, 0x02, 0x00, 0xC4, 0x0E, 0x00, 0x00, 0xC4, 0x0E, 
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
  0xF8, 0x00, 0x00, 0xE0, 0x07, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00
};


ArduCAM myCAM(OV5642, SPI_CS); // Declare myCAM.


void setup() {
  uint8_t vid, pid;
  uint8_t temp;
  
  Wire.begin();
  
  Serial.begin(115200);
  // To view serial communication, go to Tools --> Serial Monitor.
  // Make sure the baud number (bottom right) matches the number inside Serial.begin().
  
  Serial.println("ArduCAM Start!");
  Serial.println("----------------------------");
  
  
  pinMode(SPI_CS, OUTPUT); // Set the CS pin as an output.
  
  SPI.begin(); // Initialize SPI:
  while(1) {
    //Check if the ArduCAM SPI bus is OK
    
    myCAM.write_reg(ARDUCHIP_TEST1, 0x55); // Test Write.
    temp = myCAM.read_reg(ARDUCHIP_TEST1); // Test Read.
    
    if (temp != 0x55) { // Check Test.
      Serial.println(F("SPI interface Error!"));
      delay(1000);
      continue;    
    } else {
      Serial.println(F("SPI interface OK."));
      break;
    }
  }

  

  #if defined (OV5642_CAM) // Check if the camera module type is OV5642
    while(1){
      myCAM.rdSensorReg16_8(OV5642_CHIPID_HIGH, &vid);
      myCAM.rdSensorReg16_8(OV5642_CHIPID_LOW, &pid);
      if ((vid != 0x56) || (pid != 0x42)) {
        Serial.println(F("Can't find OV5642 module!"));
        delay(1000);continue; 
      } else {
        Serial.println(F("OV5642  detected."));
        break;    
      }
    }
    #else
      #error "Please define OV5642_CAM in memorysaver.h"
  #endif

  
  myCAM.InitCAM();
  // Initialize SD Card on the SD_CS port number (defined above)
  // If SD.begin() returns false:
  // 1. Check that the SD card is plugged in correctly.
  // 2. Check that the SD card is wired into the correct ports on the arduino.
  // **NOTE** You can change which port the arduino looks for the SD_CS line in –
  //          Just change the value of SD_CS at the beginning of this program. 
  
  while(!SD.begin(SD_CS)) { 
    Serial.println(F("SD Card Error!"));
    while(1); // If failed, stop here.
  }
   Serial.println(F("SD Card detected."));
   Serial.println("----------------------------");




  char str[8];
  unsigned long previous_time = 0;
  static int k = 0;


  previous_time = millis();

  if ((millis() - previous_time) < 1500) {
    k = k + 1;
    itoa(k, str, 10);
    strcat(str, ".bmp"); // Generate file extension
    GrabImage(str); // Take the picture
  }
}







void loop() {
  // Nothing happens after setup().
}



void GrabImage(char * str) {
  File outFile;
  
  char VH, VL;
  byte buf[256];
  static int k = 0;
  int i, j = 0;
  
  outFile = SD.open(str, O_WRITE | O_CREAT | O_TRUNC);
  
  if (!outFile) {
    Serial.println(F("File open error"));
    return;
  }
  
  // Flush FIFO.
  myCAM.flush_fifo();
  
  // Start capture
  myCAM.start_capture();
  Serial.println(F("Capture Starting!"));
  
  // Polling the capture done flag
  while (!myCAM.get_bit(ARDUCHIP_TRIG, CAP_DONE_MASK));
  Serial.println(F("Capture Finished!"));
  Serial.println("----------------------------");
  Serial.println("Analyzing Data... Wait a moment. \n \n");


  // Write the BMP header defined at the beginning of this program.
  k = 0;
  for ( i = 0; i < BMPIMAGEOFFSET; i++) {
    char ch = pgm_read_byte(&bmp_header[i]);
    buf[k++] = ch;
  }
  outFile.write(buf, k);
  k = 0;
  
  // Read 320x240x2 byte from FIFO and save as RGB565 .bmp format.
  int width = 240;
  int height = 320;

  float w = 240.0;
  float h = 320.0;

  float R = 0;
  float G = 0;
  float B = 0;

  float red = 0;
  float green = 0;
  float blue = 0;

  float M = 0;

  float white = 0;
  float black = 0;

  float brightness = 0;

  //Transform the 2 bytes of data (VH and VL) from each pixel to 3 bytes of data.
  //Used for RGB values and analysis of the photo.
  //
  //   VH       VL
  //RRRRRGGG|GGGBBBBB
  
  for (i = 0; i < width; i++) {
    for (j = 0; j < height; j++) {
      VH = myCAM.read_fifo();
      VL = myCAM.read_fifo();

      red = (float)((byte)VH/8)/31;
      green = ((float)(((byte)VH & 0x07)*8 + ((byte)VL/32))/63);
      blue = (float)((byte)VL & 0x1F)/31;


      R += red;
      G += green;
      B += blue;
      
      //Serial.println(red);
      //Serial.println(green);
      //Serial.println(blue);


      brightness = (float)(VH & 0x00FF)/256;

      M += brightness;

      if (brightness > 0.56) {
        white++;
      } else {
        black++;
      }


      
      buf[k++] = VL;
      buf[k++] = VH;

  
      // Write image data to file if
      // 1. Buffer is full
      // OR
      // 2. The last pixel is reached. (May not work)
      
      if (k >= 256 || (i == width && j == height)) {
        outFile.write(buf, 256); // Write 256 bytes image data to file from buffer.
        k = 0;
      }
    }
  }


  Serial.println("Stats For Nerds: \n");

  float total = R + G + B;

  Serial.print(R*100/total);
  Serial.println("% Red");
  
  Serial.print(G*100/total);
  Serial.println("% Green");
  
  Serial.print(B*100/total);
  Serial.println("% Blue \n");
  
  Serial.print("Average Brightness: ");
  Serial.print(total/3000);
  Serial.println("% \n");
  
  Serial.print(white*100/(w*h));
  Serial.println("% Transmission");
  
  Serial.print(black*100/(w*h));
  Serial.println("% Soiling \n \n \n \n \n");
  
  outFile.close(); // Close the file.
  myCAM.clear_fifo_flag(); // Clear the FIFO flag.
  return;
}
