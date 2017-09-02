/*
 */
#include "EP2C35F484.h"

#define MAX4IR 1000
#define MAX4DR 2048

#define setBit(A,k)   ( A[(k/8)] |= (0x01 << (k%8)) )
#define clrBit(A,k)   ( A[(k/8)] &= ~(0x01 << (k%8)) )            
#define getBit(A,k)   ( (A[(k/8)] & (0x01 << (k%8))) >> (k%8) )

#define TCK_PIN 2
#define TMS_PIN 3
#define TDI_PIN 4
#define TDO_PIN 5
#define PROBE_PIN 6
#define LED 13

int IRlen, nDevices;
uint8_t dr[256];
uint8_t dr2[256];

///////////////////////////////////////////////////////////
uint8_t JTAG_clock(uint8_t TDI, uint8_t TMS) {
	uint8_t result;
  digitalWrite(TDI_PIN, TDI);
  digitalWrite(TMS_PIN, TMS);
  result = digitalRead(TDO_PIN);
  digitalWrite(TCK_PIN, HIGH);
  digitalWrite(TCK_PIN, LOW);
	return result;
}

void JTAG_SelectDR2ShiftIR() {
	JTAG_clock(0, 1);
	JTAG_clock(0, 0);
	JTAG_clock(0, 0);
}

void JTAG_SelectDR2ShiftDR() {
	JTAG_clock(0, 0);
	JTAG_clock(0, 0);
}

void JTAG_Exit1xx2SelectDR() {
	JTAG_clock(0, 1);
	JTAG_clock(0, 1);
}

void JTAG_Shiftxx2SelectDR() {
	JTAG_clock(0, 1);
  JTAG_Exit1xx2SelectDR();
}

// note: call this function only when in shift-IR or shift-DR state
int JTAG_GetChainLength() {
	int i;
	for(i=0; i<MAX4IR; i++) JTAG_clock(0, 0); // empty the chain (fill it with 0's)
	for(i=0; i<MAX4IR; i++) if(JTAG_clock(1, 0)) break; // feed the chain with 1's
	JTAG_Shiftxx2SelectDR();
	return i;
}

// note: call this function only when in shift-IR or shift-DR state
void JTAG_SendData(uint8_t* p, int len){
  for (int i = 0; i < len; i++){
    JTAG_clock(getBit(p, i), (len - i) == 1); // at last bit set TMS=1
  }
	JTAG_Exit1xx2SelectDR();
}

// note: call this function only when in shift-IR or shift-DR state
void JTAG_ReadData(uint8_t* p, int len) {
  for (int i = 0; i < len; i++){
    clrBit(p, i);
    if (JTAG_clock(0, ((len - i) == 1))) setBit(p, i); // at last bit set TMS=1
  }
	JTAG_Exit1xx2SelectDR();
}

///////////////////////////////////////////////////////////
void JTAG_Any2Reset2SelectDR() {
	int i;
	for(i=0; i<5; i++) JTAG_clock(0, 1); // ResetState
	JTAG_clock(0, 0);
	JTAG_clock(0, 1); // SelectDR
}
// SetIR & return to SelectDR
void JTAG_SetIR(uint32_t ir) {
	JTAG_SelectDR2ShiftIR();
	JTAG_SendData((uint8_t*) &ir, IRlen);
}
// SetDR & return to SelectDR
void JTAG_SetDR(uint8_t* p, int len) {
	JTAG_SelectDR2ShiftDR();
	JTAG_SendData(p, len);
}
// GetDR & return to SelectDR
void JTAG_GetDR(uint8_t* p, int len) {
	JTAG_SelectDR2ShiftDR();
	JTAG_ReadData(p, len);
}

///////////////////////////////////////////////////////////
void JTAG_Scan() {
  uint32_t idcode;
	JTAG_Any2Reset2SelectDR();
	JTAG_SelectDR2ShiftIR();
	IRlen = JTAG_GetChainLength();
	Serial.print("IR chain length = ");
	Serial.println(IRlen);
	// we are in BYPASS mode since JTAG_DetermineChainLength filled the IR chain full of 1's
	// now we can easily determine the number of devices (= DR chain length when all the devices are in BYPASS mode)
	JTAG_SelectDR2ShiftDR();
	nDevices = JTAG_GetChainLength();
	Serial.print("Number of device(s) = ");
	Serial.println(nDevices);
	// read the IDCODEs (assume all devices support IDCODE, so read 32 bits per device)
	JTAG_Any2Reset2SelectDR();
  JTAG_SetIR(0x006); // JTAG Instruction: IDCODE
	JTAG_GetDR((uint8_t*) &idcode, 32);
  Serial.print("device #1 IDCODE: 0x");
  Serial.println(idcode, HEX);
  JTAG_SetIR(0x005); // JTAG Instruction: SAMPLE/PRELOAD
  JTAG_GetDR(dr, 1456);
  Serial.print("msel[1..0] ");
  Serial.print(getBit(dr, 558));//MSEL1 for EP2C35F484
  Serial.println(getBit(dr, 555));//MSEL0 for EP2C35F484
  JTAG_SetIR(0x001); // JTAG Instruction: PULSE_NCONFIG
}
///////////////////////////////////////////////////////////


void setup() {
  pinMode(LED, OUTPUT);
  pinMode(PROBE_PIN, INPUT);
  pinMode(TCK_PIN, OUTPUT);
  pinMode(TMS_PIN, OUTPUT);
  pinMode(TDI_PIN, OUTPUT);
  pinMode(TDO_PIN, INPUT);
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
}

int inByte = 0;

void loop() {
  digitalWrite(LED, digitalRead(PROBE_PIN));   // turn the LED on|off
  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();
    if (inByte == 'i') {
      JTAG_Scan();
    }
    if (inByte == 'm') {
      Serial.println("Set Monitor mode");
    }
  }
  if (inByte == 'm') {
    pinMode(PROBE_PIN, OUTPUT);
    digitalWrite(PROBE_PIN, 0);
    JTAG_Any2Reset2SelectDR();
    JTAG_SetIR(0x005); // JTAG Instruction: SAMPLE/PRELOAD
    JTAG_GetDR(dr, 1456);
    digitalWrite(PROBE_PIN, 1);
    JTAG_SetIR(0x005); // JTAG Instruction: SAMPLE/PRELOAD
    JTAG_GetDR(dr2, 1456);
    pinMode(PROBE_PIN, INPUT);
    int j = 0;
    for (int i = 1; i < 1456; i++) {
      if ((getBit(dr, i) != getBit(dr2, i)) && (i != 1263)) { // 1263 - CLK1 for EP2C35F484
        //Serial.print(i);
        for (int k = 0; k < 4; k++) {
          Serial.write(pgm_read_byte_near(BSC + ( i/3 ) * 4 + k));
        }
        Serial.print(" ");
        j++;
      }
    }
    if (j != 0) Serial.println("");
  }
}
