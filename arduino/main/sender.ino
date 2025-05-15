#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"

#define RF_FREQUENCY 868000000 
#define TX_OUTPUT_POWER 14     
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

void OnTxTimeout(void) {
  // Radio.Sleep(); // Avoid putting radio to sleep on timeout for now
  Serial.println("TX Timeout Callback Fired!");
  factory_display.clear();
  factory_display.drawString(10, 20, "LoRa Sender");
  factory_display.drawString(10, 40, "Packet #: " + String(counter));
  factory_display.drawString(10, 50, "TX HARDWARE TIMEOUT");
  factory_display.display();
  // txDoneFlag remains false, the main loop's logic will handle it
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

  // Reset the radio before configuring
  pinMode(RST_LoRa, OUTPUT);
  digitalWrite(RST_LoRa, LOW);
  delay(50);
  digitalWrite(RST_LoRa, HIGH);
  delay(50);

  RadioEvents.TxDone = OnTxDone;
  RadioEvents.TxTimeout = OnTxTimeout;
  Radio.Init(&RadioEvents);

  Radio.SetChannel(RF_FREQUENCY);

  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_FIX_LENGTH_PAYLOAD_ON,
                    true, 0, 0, LORA_IQ_INVERSION_ON, 3000);

  Serial.println("LoRa initialized");
  
  // Print all settings to debug
  Serial.println("LoRa Sender configuration:");
  Serial.println("RF_FREQUENCY: " + String(RF_FREQUENCY));
  Serial.println("TX_OUTPUT_POWER: " + String(TX_OUTPUT_POWER));
  Serial.println("LORA_BANDWIDTH: " + String(LORA_BANDWIDTH));
  Serial.println("LORA_SPREADING_FACTOR: " + String(LORA_SPREADING_FACTOR));
}

/**
 * @brief Function to excute in a loop
 * 
 */
void loop() {
  Radio.IrqProcess(); // Process radio interrupts - VERY IMPORTANT

  char buffer[30];
  sprintf(buffer, "hello %d", counter);

  Serial.print("Attempting to send: ");
  Serial.println(buffer);

  // Clear display and show "Sending..."
  factory_display.clear();
  factory_display.drawString(10, 20, "LoRa Sender");
  factory_display.drawString(10, 40, "Packet #: " + String(counter));
  factory_display.drawString(10, 50, "Sending...");
  factory_display.display();

  Radio.Send((uint8_t *)buffer, strlen(buffer));

  unsigned long startTime = millis();
  bool softwareTimeoutOccurred = false;

  while (!txDoneFlag) {
    Radio.IrqProcess(); // Process radio interrupts while waiting
    delay(10); // Small delay to yield
    if (millis() - startTime > 3500) { // Slightly longer software timeout (e.g., 3.5 seconds)
      Serial.println("Software TX timeout in loop!");
      softwareTimeoutOccurred = true;
      break;
    }
  }

  if (txDoneFlag) {
    Serial.println("TX successful (txDoneFlag is true)");
    // Display already shows "Sending...", update to "Sent successfully"
    // Ensure display is cleared before showing final status for this packet
    factory_display.clear();
    factory_display.drawString(10, 20, "LoRa Sender");
    factory_display.drawString(10, 40, "Packet #: " + String(counter));
    factory_display.drawString(10, 50, "Sent successfully!");
    factory_display.display();
  } else {
    // txDoneFlag is false. This means OnTxDone was not called.
    // It could be due to softwareTimeoutOccurred or OnTxTimeout callback.
    Serial.println("TX failed (txDoneFlag is false)");
    if (!softwareTimeoutOccurred) {
        // If not a software timeout, it implies OnTxTimeout might have been called (which has its own display)
        // or some other issue. The display might still show "Sending..." or what OnTxTimeout set.
        // For safety, update display if OnTxTimeout didn't.
        // However, OnTxTimeout updates the display to "TX HARDWARE TIMEOUT".
        // So, if softwareTimeoutOccurred is false, we rely on OnTxTimeout's display.
        Serial.println("TX failed: Not a software timeout. Check for OnTxTimeout's hardware message.");
    } else {
        // This was a software timeout because txDoneFlag never became true
        factory_display.clear();
        factory_display.drawString(10, 20, "LoRa Sender");
        factory_display.drawString(10, 40, "Packet #: " + String(counter));
        factory_display.drawString(10, 50, "TX SW TIMEOUT"); // Explicitly show software timeout
        factory_display.display();
    }
  }

  txDoneFlag = false; // Reset for the next transmission
  counter++;

  Serial.println("Waiting 5 seconds before next send cycle...");
  unsigned long delayStartTime = millis();
  while(millis() - delayStartTime < 5000){
    Radio.IrqProcess(); // Keep processing IRQs during delay
    delay(10);
  }
}
