#include "manager.h"

Manager::Manager(int door_pin, int total_level) {
  this->door_pin = door_pin;
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
  Serial.begin(baud);
}

void Manager::setButton(int pin, int mode, int pos){
  pinMode(pin, INPUT);
  buttons[mode][pos] = pin;
}

void Manager::setOutputs(int led_pin) {
  outputs = Outputs(led_pin);
}

int Manager::getLevel() { // CORRIGIR CODIGO DE PEGAR O ANDAR ATUAL 
  float dist = sonar.getDist();
  if (dist <= LIM_T_LEVEL) return 0;
  if (dist <= LIM_1_LEVEL) return 1;
  if (dist <= LIM_2_LEVEL) return 2;
  if (dist <= LIM_3_LEVEL) return 3;
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
        state = State::RISE_IN;
        return;
      }
      state = State::FALL_IN;
    }
    else if (calls[OUTSIDE] != 0) {
      shifted = calls[OUTSIDE] >> cur_level;
      if (shifted != 0) {
        state = State::RISE_OUT;
        return;
      }
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
}

void Manager::stateFallOutHandle() {
  int cur_level = getLevel();

  if (calls[OUTSIDE].test(cur_level)) {
    next_state = State::STOP;
    prepareStop();
    state = State::PRE_STOP;
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
  if (state == State::RISE_IN) {
    power.up();
    stateRiseInHandle();
  }
  else if (state == State::FALL_IN) {
    power.down();
    stateFallInHandle();
  }
  else if (state == State::RISE_OUT) {
    power.up();
    stateRiseOutHandle();
  }
  else if (state == State::FALL_OUT) {
    power.down();
    stateFallOutHandle();
  }
  else if (state == State::STOP) {
    power.stop();
    stateStopHandle();
  }
  else if (state == State::PRE_STOP) {
    power.stop();
    statePreStopHandle();
  }
  configureOutputs();
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
    delay(500);
  }
}

void Manager::timerCallback() {
  if ((state == State::PRE_STOP || state == State::STOP) && door_flag) {
    door_cnt += 1;
  }
}
