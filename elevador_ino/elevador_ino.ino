#include "manager.h"
#include "TimerOne.h"

#define TOTAL_LEVELS 4
#define INSIDE 0
#define OUTISDE 1

// Pino de interrupção
#define INTERRUPT_PIN 2

// Pinos do motor
#define PWM 3
#define IN1 4
#define IN2 5

// Pinos do Sonar
#define TRIGER 6
#define ECHO 7

// Pinos da chamada externa
#define OUTSIDE_CALL_T 8
#define OUTSIDE_CALL_1 9
#define OUTSIDE_CALL_2 10
#define OUTSIDE_CALL_3 11

// Pinos do display de 7 segmentos
#define DISPLAY1 12
#define DISPLAY2 13

// Pinos da chamada interna
#define INSIDE_CALL_T A0
#define INSIDE_CALL_1 A1
#define INSIDE_CALL_2 A2
#define INSIDE_CALL_3 A3

// Pino da porta
#define OPEN_CLOSE_DOOR A4

// Pino do led da porta
#define LED_PIN A5

// Definindo Serial
#define BAUD 115200

// Time
#define TIMER_TO_CALLBACK 1000000

Manager manager = Manager(OPEN_CLOSE_DOOR, TOTAL_LEVELS);

void ISRCallback() {
  manager.ISRCallback();
}

void timerCallback() {
  manager.timerCallback();
}

void setup() {
  Serial.begin(BAUD);
  manager.setSonar(TRIGER, ECHO);
  manager.setPower(IN1, IN2, PWM);
  manager.setOutputs(LED_PIN);
  int in_buttons[] = {INSIDE_CALL_T, INSIDE_CALL_1, INSIDE_CALL_2, INSIDE_CALL_3};
  for (int i = 0 ; i < TOTAL_LEVELS ; i++) {
    manager.setButton(in_buttons[i], INSIDE, i);
  }
  int out_buttons[] = {OUTSIDE_CALL_T, OUTSIDE_CALL_1, OUTSIDE_CALL_2, OUTSIDE_CALL_3};
  for (int i = 0 ; i < TOTAL_LEVELS ; i++) {
    manager.setButton(out_buttons[i], OUTSIDE, i);
  }
  attachInterrupt(digitalPinToInterrupt(INTERRUPT_PIN), ISRCallback, RISING);
  Timer1.initialize(TIMER_TO_CALLBACK);
  Timer1.attachInterrupt(timerCallback);
}

void loop() {
  manager.run();
}
