#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"

#define RF_FREQUENCY 868000000  
#define TX_OUTPUT_POWER 14     // Match sender's power level
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

bool receivedFlag = false;
char receivedPayload[64]; 
unsigned long lastStatusUpdate = 0;
unsigned long packetCount = 0;

void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr) {
  receivedFlag = true;
  packetCount++;
  memcpy(receivedPayload, payload, size);
  receivedPayload[size] = '\0'; 

  Serial.printf("Received: %s | RSSI: %d | SNR: %d\n", receivedPayload, rssi, snr);
}


void OnRxTimeout(void)
{
  Radio.Sleep();
  Serial.print("RX Timeout......");
  factory_display.clear();
  factory_display.drawString(10, 50, "RX Timeout");
  factory_display.display();
}


void setup() {
  Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE); 

  factory_display.init();
  factory_display.clear();
  factory_display.drawString(20, 20, "LoRa Receiver");
  factory_display.drawString(20, 40, "Starting...");
  factory_display.display();
  delay(1000);

  Serial.begin(115200);
  delay(100);

  // Reset the radio before configuring
  pinMode(RST_LoRa, OUTPUT);
  digitalWrite(RST_LoRa, LOW);
  delay(50);
  digitalWrite(RST_LoRa, HIGH);
  delay(50);

  RadioEvents.RxDone = OnRxDone;
  RadioEvents.RxTimeout = OnRxTimeout;
  Radio.Init(&RadioEvents);

  Radio.SetChannel(RF_FREQUENCY);

  // Replace TX config with RX config
  Radio.SetRxConfig(MODEM_LORA, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                   LORA_CODINGRATE, 0, LORA_PREAMBLE_LENGTH,
                   LORA_SYMBOL_TIMEOUT, LORA_FIX_LENGTH_PAYLOAD_ON,
                   0, true, 0, 0, LORA_IQ_INVERSION_ON, true);
  
  // Print configuration for debugging
  Serial.println("LoRa Receiver configuration:");
  Serial.println("RF_FREQUENCY: " + String(RF_FREQUENCY));
  Serial.println("LORA_BANDWIDTH: " + String(LORA_BANDWIDTH));
  Serial.println("LORA_SPREADING_FACTOR: " + String(LORA_SPREADING_FACTOR));
  
  Radio.Rx(0);
  Serial.println("LoRa initialized");
  
  factory_display.clear();
  factory_display.drawString(20, 20, "LoRa Receiver");
  factory_display.drawString(20, 40, "Listening...");
  factory_display.display();
  
  lastStatusUpdate = millis();
}

/**
 * @brief Function to excute in a loop
 * 
 */
void loop() {
  Radio.IrqProcess(); // Process radio interrupts - VERY IMPORTANT

  // Don't call Rx(0) repeatedly - only start receiving again after processing a packet
  if (receivedFlag) {
    receivedFlag = false;

    factory_display.clear();
    factory_display.drawString(0, 0, "LoRa Receiver");
    factory_display.drawString(0, 20, "Received:");
    factory_display.drawString(0, 40, String(receivedPayload));
    factory_display.drawString(0, 50, "Packets: " + String(packetCount));
    factory_display.display();
    
    // Only sleep briefly, then go back to RX mode
    Radio.Sleep();
    delay(100);
    
    // Resume receiving after processing the packet
    Radio.Rx(0);
    Serial.println("Back to RX mode after packet");
  }

  // Show status every 3 seconds and restart RX
  if (millis() - lastStatusUpdate > 3000) {
    Radio.IrqProcess(); // Also process radio interrupts here
    factory_display.clear();
    factory_display.drawString(0, 0, "LoRa Receiver");
    factory_display.drawString(0, 20, "Listening...");
    factory_display.drawString(0, 40, "Packets: " + String(packetCount));
    factory_display.display();
    
    // Every few seconds, reset the receiver state
    Radio.Sleep();
    delay(50);
    Radio.Rx(0);
    
    Serial.println("Still listening... Packets: " + String(packetCount));
    lastStatusUpdate = millis();
  }

  Radio.IrqProcess(); // And here, to be safe during the small delay
  delay(10); // Short delay to prevent CPU hogging
}
