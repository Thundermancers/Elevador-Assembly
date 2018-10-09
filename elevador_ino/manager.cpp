#include "manager.h"

Manager::Manager(int door_pin, int total_level) {
  this->count = 0;
  this->dist = 0;
  this->door_pin = door_pin;
  this->state = State::STOP;
  this->goal_dist = -1;
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

void Manager::setSerial(int baud) {
}

void Manager::setButton(int pin, int mode, int pos){
  pinMode(pin, INPUT);
  buttons[mode][pos] = pin;
}

void Manager::setOutputs(int led_pin) {
  outputs = Outputs(led_pin);
}

int Manager::getLevel() { // CORRIGIR CODIGO DE PEGAR O ANDAR ATUAL 
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

  bitset<LEVEL_TOTAL> calls = calls[INSIDE] | calls[OUTSIDE];

  if (calls.test(cur_level)) {
    bitset<LEVEL_TOTAL> calls_shifted = calls << (LEVEL_TOTAL - cur_level);
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
}

void Manager::run() {
  callbackDist();
  moving();
  configureOutputs();

}

int Manager::moving() {
  if (goal_dist == -1) return 1;
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
      power.up(255);      
    }
    else {
      power.down(255);
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
    door_flag = !door_flag;
    delay(50);
  }
}

void Manager::timerCallback() {
  if ((state == State::PRE_STOP || state == State::STOP) && door_flag) {
      door_cnt += 1;
  }
  sendLog();
}

void Manager::callbackDist() {
  dist = sonar.getDist();
}


String Manager::stateString(State s) {
  switch (s) {
    case State::RISE_IN :
      return "RISE_IN";
    case State::RISE_OUT :
      return "RISE_OUT";
    case State::FALL_IN :
      return "FALL_IN";
    case State::FALL_OUT :
      return "FALL_OUT";
    case State::PRE_STOP :
      return "PRE_STOP";
    case State::STOP :
      return "STOP";
    default:
        return "ESTADO MALUCO";
  }
}


void Manager::sendLog() {
  Serial.println("");
  Serial.print("State: ");
  Serial.println(stateString(state));
  Serial.print("Dist: ");
  Serial.println(dist);
  Serial.print("Level: ");
  Serial.println(getLevel());
  Serial.print("in: ");
  for (int i = 0 ; i < 4 ; i++) {
    Serial.print(calls[INSIDE][i]);
  }
  Serial.println();
  Serial.print("out: ");
  for (int i = 0 ; i < 4 ; i++) {
    Serial.print(calls[OUTSIDE][i]);
  }
  Serial.println();
  Serial.println("");
}
