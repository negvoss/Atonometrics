#include "hello.h"

void setup() {
  Serial.begin(9600);
}

void loop() {
  #if (defined HellosAtTheJoes)
    Serial.println();
    Serial.write("It Works!");
  #endif
}
