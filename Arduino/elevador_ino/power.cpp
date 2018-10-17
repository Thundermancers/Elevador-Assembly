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
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, 0);
}

void Power::up(int vel) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  analogWrite(PWM, vel);
}

void Power::down(int vel) {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, vel);
}

void Power::stop(State s) {
  if (s == State::STOP || s == State::PRE_STOP) {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, HIGH);
    analogWrite(PWM, 0);
  }
}


