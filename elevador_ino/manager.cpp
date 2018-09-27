#include "manager.h"

Manager::Manager() {
}

void Manager::setSonar(int trig, int echo) {
  sonar = SonarUtils(trig, echo);
  sonar.sonarSetup();
}

void Manager::setPower(int IN1, int IN2, int PWM) {
  power = Power(IN1, IN2, PWM);
  power.powerSetup();
}

void Manager::setSerial(int baud) {
  Serial.begin(baud);
}

void Manager::callISR() {
}

void Manager::timerCallback(){
}

void Manager::run() {
  if (state == State::RISE_IN) {

  }
  else if (state == State::FALL_IN) {

  }
  else if (state == State::RISE_OUT) {

  }
  else if (state == State::FALL_OUT) {

  }
  else if (state == State::STOP) {

  }
  else if (state == State::PRE_STOP) {

  }

}



