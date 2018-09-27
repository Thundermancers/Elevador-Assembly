#ifndef MANAGER_H
#define MANAGER_H


#include "Arduino.h"
#include "sonarUtils.h"
#include "power.h"
#include <ArduinoSTL.h>
#include <bitset>

class Manager {
  public:
    enum State {
      RISE_IN,
      RISE_OUT,
      FALL_IN,
      FALL_OUT,
      STOP,
      PRE_STOP
    };
    Manager();
    void setSonar(int trig, int echo);
    void setPower(int IN1, int IN2, int PWM);
    void setSerial(int baud);
    static void callISR();
    static void timerCallback();
    void run();

  private:
    SonarUtils sonar;
    Power power;
    State state;
};


#endif /* ifndef Manager_H */
