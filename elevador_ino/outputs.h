#ifndef OUTPUTS_H
#define OUTPUTS_H

#include "Arduino.h"

class Outputs {
  public:
    Outputs(int led_pin);
    Outputs();
    void setLed(int on_off);

  private:
    int led_pin;

};

#endif /* ifndef OUTPUTS_H */



