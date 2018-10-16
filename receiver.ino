//Carrega a biblioteca LiquidCrystal
#include <LiquidCrystal.h>

#define SIZE_MSG 50

#define OFFSET_STATE 3
#define OFFSET_NEXT_STATE 9
#define OFFSET_DOOR_STATE 15
#define OFFSET_DOOR_COUNT 20
#define OFFSET_LEVEL 26
#define OFFSET_NEXT_LEVEL 31
#define OFFSET_IN_CALLS 36
#define OFFSET_OUT_CALLS 44

#define STATE_LOG 0
#define DOOR_LOG 1
#define CALLS_LOG 2

#define NEXT_BUTTON_PIN 2
#define PREV_BUTTON_PIN 3
#define DELAY_DEBOUNCE 50


//Define os pinos que serão utilizados para ligação ao display
LiquidCrystal lcd(13, 12, 11, 10, 9, 8);


char log_str[SIZE_MSG];
int msg_state = STATE_LOG;
String cur_state = "";
String next_state = "";
String door_state = "";
String door_count = "";
String level = "";
String next_level = "";
String in_calls = "";
String out_calls = "";

void setup() {
  pinMode(NEXT_BUTTON_PIN, INPUT);
  pinMode(PREV_BUTTON_PIN, INPUT);
  Serial.begin(115200);
  attachInterrupt(digitalPinToInterrupt(NEXT_BUTTON_PIN), nextButtonISR, RISING);
  attachInterrupt(digitalPinToInterrupt(PREV_BUTTON_PIN), prevButtonISR, RISING);
  while( !Serial );
  lcd.begin(20, 4);
}

void nextButtonISR() {
  msg_state = (msg_state +  1) % 3;
  delay(DELAY_DEBOUNCE);
}

void prevButtonISR() {
  msg_state = (msg_state + 2) % 3;
  delay(DELAY_DEBOUNCE);
}

String expandState(String s) {
  if (s == "RI") 
    return "RISE_IN";
  else if (s == "RO") 
    return "RISE_OUT";
  else if (s == "FI") 
    return "FALL_IN";
  else if (s == "FO") 
    return "FALL_OUT";
  else if (s == "PS") 
    return "PRE_STATE";
  else if (s == "ST") 
    return "STOP";
}

void writeLog(String s) {
  if (msg_state == STATE_LOG) {
    cur_state = expandState(s.substring(OFFSET_STATE, OFFSET_STATE+2)); 
    next_state = expandState(s.substring(OFFSET_NEXT_STATE, OFFSET_NEXT_STATE+2));
    lcd.setCursor(0, 0);
    lcd.print("MODO: STATE_LOG");
    lcd.setCursor(0, 1);
    lcd.print("STATE:" + cur_state);
    lcd.setCursor(0, 2);
    lcd.print("N_STATE:" + next_state);
  }
  else if (msg_state == DOOR_LOG) {
    lcd.setCursor(0, 0);
    lcd.print("MODO: STATE_LOG");
    lcd.setCursor(0, 1);
    if (s[OFFSET_DOOR_STATE] == '1')
      lcd.print("DOOR_STATE: OPEN" );
    else if (s[OFFSET_DOOR_STATE] == '0')
      lcd.print("DOOR_STATE: CLOSED" );  
    lcd.setCursor(0, 2);
    lcd.print("DOOR_COUNT:" + s[OFFSET_DOOR_COUNT]);
    lcd.print(s[OFFSET_DOOR_COUNT + 1]);
  }
  else if (msg_state == CALLS_LOG) {
    // PRIMEIRA LINHA
    lcd.setCursor(0, 0);
    lcd.print("MODO: CALLS_LOG");

    // SEGUNDA LINHA
    lcd.setCursor(4, 1);
    lcd.print("T");
    lcd.setCursor(6, 1);
    lcd.print("1");
    lcd.setCursor(8, 1);
    lcd.print("2");
    lcd.setCursor(10, 1);
    lcd.print("3");
    lcd.setCursor(13, 1);
    lcd.print("|");
    
    // TERCEIRA LINHA
    lcd.setCursor(0, 2);
    lcd.print("IN:");
    lcd.setCursor(4, 2);
    lcd.print(s[OFFSET_IN_CALLS]);
    lcd.setCursor(6, 2);
    lcd.print(s[OFFSET_IN_CALLS + 1]);
    lcd.setCursor(8, 2);
    lcd.print(s[OFFSET_IN_CALLS + 2]);
    lcd.setCursor(10, 2);
    lcd.print(s[OFFSET_IN_CALLS + 3]);
    lcd.setCursor(13, 2);
    lcd.print("|");
    lcd.print("Lvl:" + s[OFFSET_LEVEL]);
    

    // QUARTA LINHA
    lcd.setCursor(0, 3);
    lcd.print("OUT:");
    lcd.setCursor(4, 3);
    lcd.print(s[OFFSET_OUT_CALLS]);
    lcd.setCursor(6, 3);
    lcd.print(s[OFFSET_OUT_CALLS + 1]);
    lcd.setCursor(8, 3);
    lcd.print(s[OFFSET_OUT_CALLS + 2]);
    lcd.setCursor(10, 3);
    lcd.print(s[OFFSET_OUT_CALLS + 3]);
    lcd.setCursor(13, 3);
    lcd.print("|");
    lcd.print("nLvl:" + s[OFFSET_LEVEL]);
  }
}

void clearLCD() {
  //Limpa a tela
  lcd.clear();
  //Posiciona o cursor na coluna 3, linha 0;
  lcd.setCursor(0, 0);
}

void loop() {
  int i = 0;
  char c = 'i';
  while (Serial.available() > 0) {
    while (c != 'A' && !i) {
      c = Serial.read();
    }
    log_str[i++] = c;
    c = Serial.read();
    if (c == '&') {
      clearLCD();
      writeLog(String(log_str));
      Serial.println(log_str);
      break;
    }
  }
  delay(1000);
}

