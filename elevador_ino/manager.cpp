#include "manager.h"

Manager::Manager() {
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

void Manager::setButtons(int IN_T_PIN, int IN_1_PIN, int IN_2_PIN, int IN_3_PIN,
    int OUT_T_PIN, int OUT_1_PIN, int OUT_2_PIN, int OUT_3_PIN) {
  in_buttons.push_back(IN_T_PIN);
  in_buttons.push_back(IN_1_PIN);
  in_buttons.push_back(IN_2_PIN);
  in_buttons.push_back(IN_3_PIN);

  out_buttons.push_back(OUT_T_PIN);
  out_buttons.push_back(OUT_1_PIN);
  out_buttons.push_back(OUT_2_PIN);
  out_buttons.push_back(OUT_3_PIN);
}

void Manager::setOutputs(int led_pin, int buzzer_pin) {
  outputs = Outputs(led_pin, buzzer_pin);
}

int Manager::getLevel() {
  float dist = sonar.getDist();
  if (dist <= LIM_T_LEVEL) return 0;
  if (dist <= LIM_1_LEVEL) return 1;
  if (dist <= LIM_2_LEVEL) return 2;
  if (dist <= LIM_3_LEVEL) return 3;
}

void Manager::stateStopHandle() {
  int cur_level = getLevel();
  in_calls.set(cur_level, 0);
  out_calls.set(cur_level, 0);

  if (!door_flag) {
    bitset<LEVEL_TOTAL> shifted;

    if (in_calls != 0) {
      shifted = in_calls >> cur_level;
      if (shifted != 0) {
        state = State::RISE_IN;
        return;
      }
      state = State::FALL_IN;
    }
    else if (out_calls != 0) {
      shifted = out_calls >> cur_level;
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
  in_calls.set(cur_level, 0);
  out_calls.set(cur_level, 0);

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

  if (in_calls.test(cur_level)) {
    bitset<LEVEL_TOTAL> in_calls_shifted = in_calls >> (cur_level + 1);
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
  bitset<LEVEL_TOTAL> in_calls_shifted = in_calls >> (cur_level + 1);

  if (in_calls_shifted != 0) {
    state = State::RISE_IN;
    return;
  }

  if (out_calls.test(cur_level)) {
    next_state = State::STOP;
    prepareStop();
    state = State::PRE_STOP;
  }

}

void Manager::stateFallInHandle() {
  int cur_level = getLevel();
  bitset<LEVEL_TOTAL> calls = in_calls | out_calls;

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

  if (out_calls.test(cur_level)) {
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
  if (!door_flag) {
    outputs.setLed(LOW);
    outputs.setBuzzer(LOW);
  }
  else {
    outputs.setLed(HIGH);
    if (door_cnt >= 5) {
      outputs.setBuzzer(HIGH);
    }
  }
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

void Manager::insideISR() {
  int read;
  for(int i = 0 ; i < (int)in_buttons.size() ; i++) {
    read = digitalRead(in_buttons[i]);
    if (read) {
      in_calls.set(i, 1);
    }
  }
}

void Manager::outsideISR() {
  int read;
  for(int i = 0 ; i < (int)out_buttons.size() ; i++) {
    read = digitalRead(out_buttons[i]);
    if (read) {
      out_calls.set(i, 1);
    }
  }
}

void Manager::timerCallback() {
  if ((state == State::PRE_STOP || state == State::STOP) && door_flag) {
    door_cnt += 1;
  }
}



