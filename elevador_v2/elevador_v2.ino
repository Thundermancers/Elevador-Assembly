#include "TimerOne.h"

#define TOTAL_LEVELS 4
#define INSIDE 0
#define OUTISDE 1

// Interrupções
#define INTERRUPT_PIN 2

// Pinos do motor (ALTERAR)
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

// Pinos do Display de 7 segmentos
#define DISPLAY1 12
#define DISPLAY2 13

// Pinos da chamada interna

#define INSIDE_CALL_T A0
#define INSIDE_CALL_1 A1
#define INSIDE_CALL_2 A2
#define INSIDE_CALL_3 A3
#define OPEN_CLOSE_DOOR A4
#define LED_PIN A5

// Definindo Serial
#define BAUD 115200

// Time
#define TIMER_TO_CALLBACK 1000000

#define EPS 1.0

double dist = 0;
double goal_dist = 10;

double getDist() {
  // Clears the trigPin
  long duration;
  digitalWrite(TRIGER, LOW);
  delayMicroseconds(2);
  
  // Sets the trigPin on HIGH state for 10 micro seconds
  digitalWrite(TRIGER, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIGER, LOW);
  
  // Reads the echoPin, returns the sound wave travel time in microseconds
  duration = pulseIn(ECHO, HIGH);
  
  // Calculating the distance
  dist = duration*0.034/2;
}

void up(int vel) {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, vel);
}

void down(int vel) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  analogWrite(PWM, vel);
}

void stopp() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, 0);
}


void moving() {
  double error = goal_dist - dist;
  if( fabs(error) <= EPS ) {
    stopp();
  }
  else {
    if( error > 0 ) {
      up(255);      
    }
    else {
      down(255);
    }
  }
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(PWM, OUTPUT);
  pinMode(TRIGER, OUTPUT);
  pinMode(ECHO, INPUT);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, HIGH);
  analogWrite(PWM, 0);
  while ( !Serial );

}

void loop() {
  // put your main code here, to run repeatedly:
  if ( Serial.available() > 0 ) {
    String input = Serial.readString();
    goal_dist = input.toInt();
  }
  getDist();
  moving();
  Serial.print("Altura atual: ");
  Serial.println(dist);
  Serial.print("Altura desejada: ");
  Serial.print(goal_dist);

  

}
