#include "outputs.h"

Outputs::Outputs(){}
Outputs::Outputs(int led_pin, int display_0, int display_1) {
  pinMode(led_pin, OUTPUT);
  pinMode(display_0, OUTPUT);
  pinMode(display_1, OUTPUT);
  this->led_pin = led_pin;
  this->display_0 = display_0;
  this->display_1 = display_1;
}

void Outputs::setLed(int on_off) {
  digitalWrite(led_pin, on_off);
}

void Outputs::setDisplay(int d_0, int d_1) {
  digitalWrite(this->display_0, d_0);
  digitalWrite(this->display_1, d_1);
}

