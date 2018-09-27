#include "power.h"

Power::Power(int IN1, int IN2, int PWM) {
  this->IN1 = IN1;
  this->IN2 = IN2;
  this->PWM = PWM;
}

Power::Power(){}

void Power::powerSetup() {
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(PWM, OUTPUT);
}

void Power::up() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  analogWrite(PWM, FULL_PWM);
}

void Power::down() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, FULL_PWM);
}

void Power::stop() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, 0);
}


