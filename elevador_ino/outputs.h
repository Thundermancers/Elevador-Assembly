#ifndef OUTPUTS_H
#define OUTPUTS_H

#include "Arduino.h"

class Outputs {
  public:
    Outputs(int led_pin, int display_0, int display_1);
    Outputs();
    void setLed(int on_off);
    void setDisplay(int d_0, int d_1);

  private:
    int led_pin;
    int display_0;
    int display_1;

};

#endif /* ifndef OUTPUTS_H */



