void setup() {
  Serial.begin(115200);
  sendmsg("hello world");
  sendmsg("papa is smart");
}

void loop() {
  //Nothing happends after setup().
}

void sendmsg(char msg[]) {
  Serial.write(msg);
  Serial.write("\n");
}

