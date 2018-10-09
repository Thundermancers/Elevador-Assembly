#ifndef MANAGER_H
#define MANAGER_H

#include "Arduino.h"
#include "sonarUtils.h"
#include "power.h"
#include "state.h"
#include "outputs.h"
#include <ArduinoSTL.h>
#include <bitset>
#include <string>
#include <vector>

#define LIM_T_LEVEL 4
#define LIM_1_LEVEL 24
#define LIM_2_LEVEL 44
#define LIM_3_LEVEL 64
#define DX 3
#define EPS 1.0

#define LEVEL_TOTAL 4
#define OPEN 1
#define CLOSED 0
#define INSIDE 0
#define OUTSIDE 1

#define SAMPLES 5
#define DELAY_SAMPLE 10

using namespace std;

class Manager {
  public:
    Manager(int door_pin, int total_level);
    Manager();
    void setSonar(int trig, int echo);
    void setPower(int IN1, int IN2, int PWM);
    void setSerial(int baud);
    void setOutputs(int led_pin);
    void setButton(int pin, int mode, int pos);
    void ISRCallback();
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
    int last_level;
    int count;
    double dist;
    double goal_dist;
    int door_pin;
    bitset<LEVEL_TOTAL> calls[2];
    vector<int> buttons[2];
    vector<int> level_pos;

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
    void callbackDist();
    void sendLog();
    int moving();
    String stateString(State s);
};


#endif /* ifndef Manager_H */
