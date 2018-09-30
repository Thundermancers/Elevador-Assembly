#include "manager.h"
#include "TimerOne.h"

// Pinos do sonar

#define TRIG A4
#define ECHO A5

// Interrupções
#define INTERRUPT_PIN 2

// Pinos do motor (ALTERAR)
#define IN1 2
#define IN2 4
#define PWM 3

// Pinos de dentro do elevador e de fora

#define INSIDE_CALL_T 5
#define INSIDE_CALL_1 5
#define INSIDE_CALL_2 5
#define INSIDE_CALL_3 5

#define OUTSIDE_CALL_T 5
#define OUTISDE_CALL_1 5
#define OUTSIDE_CALL_2 5
#define OUTSIDE_CALL_3 5

// Definindo Serial
#define BAUD 9600

Manager manager = Manager();

void insideISR() {
  manager.insideISR();
}

void outsideISR() {
  manager.outsideISR();
}

void timerCallback() {
  manager.timerCallback();
}

void setup() {
  // put your setup code here, to run once:
  attachInterrupt(digitalPinToInterrupt(INTERRUPT_PIN), insideISR, RISING);
  Timer1.initialize(1000000);
  Timer1.attachInterrupt(timerCallback);
  manager.setSonar(TRIG, ECHO);
  manager.setPower(IN1, IN2, PWM);
  manager.setSerial(BAUD);
}

void loop() {
  // put your main code here, to run repeatedly:
  manager.run();

}
