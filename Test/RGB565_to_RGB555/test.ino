void setup() {
  // put your setup code here, to run once:

  Serial.begin(115200);

  Serial.println("Start test.");
  
  char VH, VL;
  float red, green, blue, total;

  VH = 255;
  VL = 220;
  Serial.println((byte)VH);
  Serial.println((byte)VL);
  Serial.println("-------------");

  red = (float)((byte)VH/8)/31; 
  green = ((float)(((byte)VH & 0x07)*8 + ((byte)VL/32))/63);
  blue = (float)((byte)VL & 0x1F)/31;
  total = red + green + blue;
  Serial.println(red/total);
  Serial.println(green/total);
  Serial.println(blue/total);

}

void loop() {
  // put your main code here, to run repeatedly:

}
