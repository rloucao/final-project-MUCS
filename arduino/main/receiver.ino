#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"

#define RF_FREQUENCY 868000000 // Frequência LoRa para a Europa
#define TX_OUTPUT_POWER 10     // dBm
#define LORA_BANDWIDTH 0       // 125 kHz
#define LORA_SPREADING_FACTOR 7
#define LORA_CODINGRATE 1      // 4/5
#define LORA_PREAMBLE_LENGTH 8
#define LORA_SYMBOL_TIMEOUT 5
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false

// Ecrã OLED: endereço I2C 0x3C e pinos definidos para a Heltec
SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

bool receivedFlag = false;
char receivedPayload[64]; 

void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr) {
  receivedFlag = true;
  memcpy(receivedPayload, payload, size);
  receivedPayload[size] = '\0'; 

  Serial.printf("Received: %s | RSSI: %d | SNR: %d\n", receivedPayload, rssi, snr);
}

void setup() {
  Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE); 

  
  factory_display.init();
  factory_display.clear();
  factory_display.drawString(20, 30, "LoRa Receiver");
  factory_display.display();
  delay(1000);

  Serial.begin(115200);
  delay(100);

  RadioEvents.RxDone = OnRxDone;
  Radio.Init(&RadioEvents);

  Radio.SetChannel(RF_FREQUENCY);

  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_FIX_LENGTH_PAYLOAD_ON,
                    true, 0, 0, LORA_IQ_INVERSION_ON, 3000);

  Serial.println("LoRa initialized");
}
void loop() {
    if (receivedFlag) {
        receivedFlag = false;

        factory_display.clear();
        factory_display.drawString(0, 20, "Received:");
        factory_display.drawString(0, 40, String(receivedPayload));
        factory_display.display();
    }

    delay(100);
}
