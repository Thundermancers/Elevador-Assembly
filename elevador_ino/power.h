#ifndef POWER_H
#define POWER_H

#include "Arduino.h"

#define FULL_PWM 255

class Power {
  public:
    Power(int IN1, int IN2, int PWM);
    Power();

    void powerSetup();
    void up();
    void down();
    void stop();

  private:
    int IN1;
    int IN2;
    int PWM;
};

#endif /* ifndef POWER_H */
