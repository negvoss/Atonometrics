void setup() {
  pinMode(LED_BUILTIN,OUTPUT);
}

void loop() {
  digitalWrite(LED_BUILTIN,HIGH);
  delay(millis()/100);
  digitalWrite(LED_BUILTIN,LOW);
  delay(millis()/100);
}
