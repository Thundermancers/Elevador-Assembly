#include "sonarUtils.h"

SonarUtils::SonarUtils(int trig, int echo) {
  this->TRIG = trig;
  this->ECHO = echo;
}

SonarUtils::SonarUtils() {}

void SonarUtils::sonarSetup() {
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
}


double SonarUtils::getDist() {
  // Clears the trigPin
  long duration;
  double dist;
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  
  // Sets the trigPin on HIGH state for 10 micro seconds
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  
  // Reads the echoPin, returns the sound wave travel time in microseconds
  duration = pulseIn(ECHO, HIGH);
  
  // Calculating the distance
  dist = duration*0.034/2;
  return dist;
}
