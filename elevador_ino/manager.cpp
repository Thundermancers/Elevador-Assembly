#include "manager.h"

Manager::Manager(int door_pin, int total_level) {
  this->count = 0;
  this->dist = 0;
  this->dist_old = 0;
  this->door_pin = door_pin;
  this->state = State::STOP;
  this->state = State::STOP;
  this->goal_dist = LIM_T_LEVEL;
  this->door_flag = OPEN;
  this->door_cnt = 0;
  level_pos.resize(total_level);
  level_pos[0] = LIM_T_LEVEL;
  level_pos[1] = LIM_1_LEVEL;
  level_pos[2] = LIM_2_LEVEL;
  level_pos[3] = LIM_3_LEVEL;
  buttons[0].resize(total_level);
  buttons[1].resize(total_level);
}

void Manager::setSonar(int trig, int echo) {
  sonar = SonarUtils(trig, echo);
  sonar.sonarSetup();
}

void Manager::setPower(int IN1, int IN2, int PWM) {
  power = Power(IN1, IN2, PWM);
  power.powerSetup();
}

void Manager::setButton(int pin, int mode, int pos){
  pinMode(pin, INPUT);
  buttons[mode][pos] = pin;
}

void Manager::setOutputs(int led_pin, int display_0, int display_1) {
  outputs = Outputs(led_pin, display_0, display_1);
}

int Manager::getLevel() {
  if (fabs(dist - LIM_T_LEVEL) < EPS) return 0;
  if (fabs(dist - LIM_1_LEVEL) < EPS) return 1;
  if (fabs(dist - LIM_2_LEVEL) < EPS) return 2;
  if (fabs(dist - LIM_3_LEVEL) < EPS) return 3;
  return -1;
}

void Manager::stateStopHandle() {
  int cur_level = getLevel();
  calls[INSIDE].set(cur_level, 0);
  calls[OUTSIDE].set(cur_level, 0);
  if (cur_level == -1) return;
  if (!door_flag) {
    bitset<LEVEL_TOTAL> shifted;

    if (calls[INSIDE] != 0) {
      shifted = calls[INSIDE] >> cur_level;
      if (shifted != 0) {
        goal_dist = level_pos[cur_level + 1];
        state = State::RISE_IN;
        return;
      }
      goal_dist = level_pos[cur_level - 1];
      state = State::FALL_IN;
    }
    else if (calls[OUTSIDE] != 0) {
      shifted = calls[OUTSIDE] >> cur_level;
      if (shifted != 0) {
        goal_dist = level_pos[cur_level + 1];
        state = State::RISE_OUT;
        return;
      }
      goal_dist = level_pos[cur_level - 1];
      state = State::FALL_OUT;
    }
  }
  else if (door_cnt >= 10){
    door_flag = CLOSED;
  }
}

void Manager::statePreStopHandle() {

  int cur_level = getLevel();
  if (cur_level == -1) return;

  calls[INSIDE].set(cur_level, 0);
  calls[OUTSIDE].set(cur_level, 0);
  if (door_flag) {
    if (door_cnt >= 10) {
      door_flag = CLOSED;
    }
  }
  else {
    state = next_state;
    if (state == State::RISE_IN) goal_dist = level_pos[cur_level + 1];
    else if (state == State::FALL_IN) goal_dist = level_pos[cur_level - 1];
    else if (state == State::RISE_OUT) goal_dist = level_pos[cur_level + 1];
    else if (state == State::FALL_OUT) goal_dist = level_pos[cur_level - 1];
    else if (state == State::STOP) goal_dist = level_pos[cur_level];
  }
}

void Manager::stateRiseInHandle() {
  int cur_level = getLevel();
  if (cur_level == -1) return;

  if (calls[INSIDE].test(cur_level)) {
    bitset<LEVEL_TOTAL> in_calls_shifted = calls[INSIDE] >> (cur_level + 1);
    if (in_calls_shifted == 0) {
      next_state = State::STOP;
    }
    else {
      next_state = State::RISE_IN;
    }
    prepareStop();
    state = State::PRE_STOP;
  }
  else {
    goal_dist = level_pos[cur_level + 1];
  }
}

void Manager::stateRiseOutHandle() {
  int cur_level = getLevel();
  if (cur_level == -1) return;

  bitset<LEVEL_TOTAL> in_calls_shifted = calls[INSIDE] >> (cur_level + 1);

  if (in_calls_shifted != 0) {
    state = State::RISE_IN;
    return;
  }

  if (calls[OUTSIDE].test(cur_level)) {
    next_state = State::STOP;
    prepareStop();
    state = State::PRE_STOP;
  }
  else {
    goal_dist = level_pos[cur_level + 1];
  }

}

void Manager::stateFallInHandle() {
  int cur_level = getLevel();
  if (cur_level == -1) return;

  bitset<LEVEL_TOTAL> all_calls = calls[INSIDE] | calls[OUTSIDE];

  if (all_calls.test(cur_level)) {
    bitset<LEVEL_TOTAL> calls_shifted = all_calls << (LEVEL_TOTAL - cur_level);
    if (calls_shifted != 0) {
      next_state = State::FALL_IN;
    }
    else {
      next_state = State::STOP;
    }
    prepareStop();
    state = State::PRE_STOP;
  }
  else {
    goal_dist = level_pos[cur_level - 1];
  }
}

void Manager::stateFallOutHandle() {
  int cur_level = getLevel();
  if (cur_level == -1) return;

  if (calls[OUTSIDE].test(cur_level)) {
    next_state = State::STOP;
    prepareStop();
    state = State::PRE_STOP;
  }
  else {
    goal_dist = level_pos[cur_level - 1];
  }

}

void Manager::prepareStop() {
  door_cnt = 0;
  door_flag = OPEN;
}

void Manager::configureOutputs() {
  outputs.setLed(door_flag);
  int cur_level = getLevel();
  if (cur_level != -1) {
    outputs.setDisplay( cur_level&1 , cur_level&2 );
  }
}

void Manager::run() {
  callbackDist();
  flag_stop = moving();
  configureOutputs();
}

int Manager::moving() {
  double error = goal_dist - dist;
  if( fabs(error) <= EPS ) {
    if (state == State::RISE_IN) { stateRiseInHandle(); }
    else if (state == State::FALL_IN) { stateFallInHandle(); }
    else if (state == State::RISE_OUT) { stateRiseOutHandle(); }
    else if (state == State::FALL_OUT) { stateFallOutHandle(); }
    else if (state == State::STOP) { stateStopHandle(); }
    else if (state == State::PRE_STOP) { statePreStopHandle(); }
    power.stop(state);
    return 1;
  }
  else {
    if( error > 0 ) {
      power.up(200);      
    }
    else {
      power.down(100);
    }
    return 0;
  }
}
void Manager::ISRCallback() {
  int read;
  for (int j = 0 ; j < 2 ; j++) {
    for(int i = 0 ; i < (int)buttons[j].size() ; i++) {
      read = digitalRead(buttons[j][i]);
      if (read) {
        calls[j].set(i, 1);
      }
    }
  }

  read = digitalRead(door_pin);
  if ((state == State::PRE_STOP || state == State::STOP) && read) {
    if (!door_flag) door_cnt = 0;
    door_flag = !door_flag;
    delay(50);
  }
}

void Manager::timerCallback() {
  if ((state == State::PRE_STOP || state == State::STOP) && door_flag) {
      door_cnt += 1;
  }
  if (door_cnt >= 10) door_flag = CLOSED;
  sendLog();
}

double Manager::distCalibrationLinear(double d) {
  double p1 = 1.068;
  double p2 = 1.314;
  return p1 * d + p2;
}

double Manager::distCalibrationDeg8(double d) {
  double p1 = 5.29e-11;
  double p2 = -1.415e-8;
  double p3 = 1.553e-6;
  double p4 = -9.032e-5;
  double p5 = 0.002993;
  double p6 = -0.05626;
  double p7 = 0.5552;
  double p8 = -1.233;
  double p9 = 3.526;
  double coeffs[] = {p1, p2, p3, p4, p5, p6, p7, p8, p9};
  double sum = 0;
  double k = 1;
  for (int i = 8 ; i >= 0 ; i--) {
    sum += k*coeffs[i];
    k *= d;

  }
  return sum;
}

void Manager::callbackDist() {
  double sum = 0;
  double valueMin = 1<<10; // 2^10
  double valueMax = - 1<<10; // - 2^10
  // Amostras de alturas
  for( int i = 0 ; i < SAMPLES ; ++i ) {
    double h = sonar.getDist();
    sum += h;
    valueMin = min(valueMin, h);
    valueMax = max(valueMax, h);
    delay( DELAY_SAMPLE );
  }
  // Retirar possíveis ruídos
  dist_old = ( sum - valueMin - valueMax )/( SAMPLES - 2 );
  if (goal_dist == 64)
    dist = distCalibrationLinear(dist_old);
  else
    dist = distCalibrationDeg8(dist_old);
  
}

String Manager::stateString(State s) {
  switch (s) {
    case State::RISE_IN :
      return "RI";
    case State::RISE_OUT :
      return "RO";
    case State::FALL_IN :
      return "FI";
    case State::FALL_OUT :
      return "FO";
    case State::PRE_STOP :
      return "PS";
    case State::STOP :
      return "ST";
    default:
      return "??";
  }
}

String Manager::countToString(int dc) {
  String a = "XX";
  if( dc <= 10 && dc >= 0)  {
    a = (dc/10);
    a += (dc%10);  
  }
  return a;
}

String Manager::levelToString(int lvl) {
  String a = "X";
  if(lvl >= 0) {
    a = lvl;     
  }
  return a;
}

void Manager::sendLog() {
  String log_string = "", s = "";
  log_string += "AS_" + stateString(state) + SPACE;
  log_string += "NS_" + stateString(next_state) + SPACE;
  s = int(door_flag);
  log_string += "DS_" + s + SPACE;
  log_string += "CD_" + countToString(door_cnt) + SPACE;
  log_string += "LV_" + levelToString(getLevel()) + SPACE;
  log_string += "NL_" + levelToString(goal_dist/20) + SPACE;
  s = "";
  for (int i = 0 ; i < 4 ; i++) {
    s += int(calls[INSIDE][i]);
  }
  log_string += "IN_" + s + SPACE;
  s = "";
  for (int i = 0 ; i < 4 ; i++) {
    s += int(calls[OUTSIDE][i]);
  }
  log_string += "OT_" + s;
  log_string += ENDSEND; 
  log_string += "\n";
  sendToRcv(log_string);
}

void Manager::sendToRcv(String log_string){
  char logchar[60];
  for ( int i = 0 ; i < SIZE_MSG ; ++i ){
    logchar[i] = log_string[i];
  }
  Serial.write(logchar,SIZE_MSG);
}
