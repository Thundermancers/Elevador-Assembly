#ifndef SONAR_UTILS_H
#define SONAR_UTILS_H

#include "Arduino.h"

class SonarUtils {
  public:
    SonarUtils(int trig, int echo);
    SonarUtils();
    double getDist();
    void sonarSetup();
   
  private:
    int TRIG;
    int ECHO;
};

#endif


