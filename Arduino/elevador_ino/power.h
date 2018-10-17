#ifndef POWER_H
#define POWER_H

#include "Arduino.h"
#include "state.h"

#define FULL_PWM 255

class Power {
  public:
    Power(int IN1, int IN2, int PWM);
    Power();

    void powerSetup();
    void up(int vel);
    void down(int vel);
    void stop(State s);

  private:
    int IN1;
    int IN2;
    int PWM;
};

#endif /* ifndef POWER_H */
