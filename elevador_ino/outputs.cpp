#include "outputs.h"

Outputs::Outputs(){}
Outputs::Outputs(int led_pin, int buzzer_pin) {
  this->led_pin = led_pin;
  this->buzzer_pin = buzzer_pin;
}

void Outputs::setLed(int on_off) {
  digitalWrite(led_pin, on_off);
}

void Outputs::setBuzzer(int on_off) {
  digitalWrite(buzzer_pin, on_off);
}
