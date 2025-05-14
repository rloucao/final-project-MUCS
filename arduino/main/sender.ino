#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"

#define RF_FREQUENCY 868000000 
#define TX_OUTPUT_POWER 10     
#define LORA_BANDWIDTH 0       
#define LORA_SPREADING_FACTOR 7
#define LORA_CODINGRATE 1      
#define LORA_PREAMBLE_LENGTH 8
#define LORA_SYMBOL_TIMEOUT 5
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false

// OLED Display
SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

int counter = 0;
bool txDoneFlag = false;

/**
 * @brief Function called when the transmission is completed
 * 
 */
void OnTxDone(void) {
  Serial.println("TX done");
  txDoneFlag = true;
}


/**
 * @brief Hardware setup, aka main
 * 
 */
void setup() {
  Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE);  

  factory_display.init();
  factory_display.clear();
  factory_display.drawString(20, 30, "LoRa Sender");
  factory_display.display();
  delay(1000);

  Serial.begin(115200);
  delay(100);

  RadioEvents.TxDone = OnTxDone;
  Radio.Init(&RadioEvents);

  Radio.SetChannel(RF_FREQUENCY);

  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_FIX_LENGTH_PAYLOAD_ON,
                    true, 0, 0, LORA_IQ_INVERSION_ON, 3000);

  Serial.println("LoRa initialized");
}

/**
 * @brief Function to excute in a loop
 * 
 */
void loop() {
  char buffer[30];
  sprintf(buffer, "hello %d", counter);

  Radio.Send((uint8_t *)buffer, strlen(buffer));

  factory_display.clear();
  factory_display.drawString(10, 20, "LoRa Sender");
  factory_display.drawString(10, 40, "Packet #: " + String(counter));
  factory_display.display();


  Serial.print("Sending: ");
  factory_display.clear();
  factory_display.drawString(20, 30, buffer);
  factory_display.display();
  Serial.println(buffer);

  counter++;

  while (!txDoneFlag) {
    delay(10);
  }
  txDoneFlag = false;

  delay(5000); 
}
