#ifndef MANAGER_H
#define MANAGER_H


#include "Arduino.h"
#include "sonarUtils.h"
#include "power.h"
#include "state.h"
#include "outputs.h"
#include <ArduinoSTL.h>
#include <bitset>
#include <vector>

#define LIM_T_LEVEL 20
#define LIM_1_LEVEL 40
#define LIM_2_LEVEL 60
#define LIM_3_LEVEL 80

#define LEVEL_TOTAL 4
#define OPEN 1
#define CLOSED 0

using namespace std;

class Manager {
  public:
    Manager();
    void setSonar(int trig, int echo);
    void setPower(int IN1, int IN2, int PWM);
    void setSerial(int baud);
    void setOutputs(int led_pin, int buzzer_pin);
    void setButtons(int IN_T_PIN, int IN_1_PIN, int IN_2_PIN, int IN_3_PIN,
      int OUT_T_PIN, int OUT_1_PIN, int OUT_2_PIN, int OUT_3_PIN);
    void outsideISR();
    void insideISR();
    void timerCallback();
    void run();

  private:
    /* Variaveis */
    SonarUtils sonar;
    Power power;
    State state;
    State next_state;
    Outputs outputs;
    int door_cnt;
    int door_flag;
    bitset<LEVEL_TOTAL> in_calls;
    bitset<LEVEL_TOTAL> out_calls;

    vector<int> out_buttons;
    vector<int> in_buttons;

    /* Funcoes */
    void stateStopHandle();
    void statePreStopHandle();
    void stateFallOutHandle();
    void stateRiseOutHandle();
    void stateRiseInHandle();
    void stateFallInHandle();
    int getLevel();
    void configureOutputs();
    void prepareStop();
};


#endif /* ifndef Manager_H */
