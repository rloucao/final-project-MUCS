/*
 * ESP32 Smart Garden System - Integrated Sensors & Actuators
 * 
 * Components:
 * - DHT11 Temperature & Humidity Sensor
 * - LDR Light Sensor
 * - Water Pump (via Relay)
 * - RGB LED Status Indicator
 * 
 */

#include <DHT.h>
#include <WiFi.h>
#include <WebServer.h>
#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"
#include "AES.h"
#include "Crypto.h"

const char* ssid = "Vodafone-18E4A0";
const char* pwd = "hZ7qDeqy9Y";
//const char* ssid = "Galaxy21";
//const char* pwd = "mynet12345";

WebServer server(80);

// Pin Definitions (Your specific connections)
#define DHT_PIN         3     // DHT11 sensor
#define LIGHT_SENSOR_PIN 7    // LDR sensor
#define RELAY_PIN       2     // Water pump relay
#define RED_PIN         6     // RGB LED Red
#define GREEN_PIN       5     // RGB LED Green
#define BLUE_PIN        4     // RGB LED Blue

#define RF_FREQUENCY 868000000 
#define TX_OUTPUT_POWER 14     
#define LORA_BANDWIDTH 0       
#define LORA_SPREADING_FACTOR 7
#define LORA_CODINGRATE 1      
#define LORA_PREAMBLE_LENGTH 8
#define LORA_SYMBOL_TIMEOUT 5
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false

#define BUFFER_SIZE 16  // AES block size

// DHT11 Configuration
#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);

uint64_t MAC_ID;

SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

int counter = 0;
bool txDoneFlag = false;
bool receivedFlag = false;
const unsigned int receivedPayloadSize = 128;  
char receivedPayload[receivedPayloadSize]; 
char decryptedPayload[receivedPayloadSize]; // Buffer for decrypted data

// AES Encryption
byte key[16] = { 0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
                 0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81 };

AES128 aes;
byte cipherText[BUFFER_SIZE];
byte decryptText[BUFFER_SIZE];
byte plaintext[BUFFER_SIZE];

// System Variables
float temperature = 0;
float humidity = 0;
int lightLevel = 0;
bool pumpRunning = false;
unsigned long lastSensorRead = 0;
unsigned long lastPumpCycle = 0;
unsigned long pumpStartTime = 0;
unsigned long lastLEDChange = 0;
int currentLEDColor = 0; // For cycling colors

// Thresholds (adjust based on your needs)
const float TEMP_HIGH = 25.0;        // Lower threshold for testing
const float HUMIDITY_LOW = 50.0;     // Higher threshold for testing
const int LIGHT_LOW = 800;           // Dark threshold
const int LIGHT_HIGH = 2000;         // Bright threshold
const unsigned long PUMP_RUN_TIME = 5000;     // 5 seconds for testing
const unsigned long PUMP_INTERVAL = 15000;    // 15 seconds between cycles for testing
const unsigned long SENSOR_INTERVAL = 2000;   // 2 seconds between readings
const unsigned long LED_CYCLE_TIME = 1500;    // 1.5 seconds per color

//Function to encrypt the data to then be sent
void encryptData(const char *data, byte *encryptedData, int dataLength) {
  aes.setKey(key, sizeof(key));
  
  // Process data in 16-byte blocks
  int blocks = (dataLength + BUFFER_SIZE - 1) / BUFFER_SIZE; // Ceiling division
  
  for(int i = 0; i < blocks; i++) {
    memset(plaintext, 0, BUFFER_SIZE);
    int copyLength = min(BUFFER_SIZE, dataLength - (i * BUFFER_SIZE));
    memcpy(plaintext, data + (i * BUFFER_SIZE), copyLength);
    
    aes.encryptBlock(encryptedData + (i * BUFFER_SIZE), plaintext);
  }
}

//Function to decrypt the received (encrypted) data
void decryptData(const byte *encryptedData, char *decryptedOutput, int dataLength) {
  aes.setKey(key, sizeof(key));
  
  // Process data in 16-byte blocks
  int blocks = (dataLength + BUFFER_SIZE - 1) / BUFFER_SIZE; // Ceiling division
  
  for(int i = 0; i < blocks; i++) {
    aes.decryptBlock(decryptText, encryptedData + (i * BUFFER_SIZE));
    
    int copyLength = min(BUFFER_SIZE, dataLength - (i * BUFFER_SIZE));
    memcpy(decryptedOutput + (i * BUFFER_SIZE), decryptText, copyLength);
  }
  
  // Null terminate the string
  decryptedOutput[dataLength] = '\0';
  
  // Remove padding characters (null bytes at the end)
  for(int i = dataLength - 1; i >= 0; i--) {
    if(decryptedOutput[i] == '\0') {
      continue;
    } else {
      decryptedOutput[i + 1] = '\0';
      break;
    }
  }
}

void handleCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(200, "text/plain", "");
}

void handleLEDOn() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  
  digitalWrite(LED_BUILTIN, HIGH);  
  server.send(200, "text/plain", "LED ON");
}

void handleLEDOff() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  
  digitalWrite(LED_BUILTIN, LOW);
  server.send(200, "text/plain", "LED OFF");
}

void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr) {
  receivedFlag = true;
  
  // Ensure we don't overflow the buffer
  size = min(size, (uint16_t)(receivedPayloadSize - 1));
  memcpy(receivedPayload, payload, size);
  
  // Decrypt the received data
  memset(decryptedPayload, 0, sizeof(decryptedPayload));
  decryptData((byte*)receivedPayload, decryptedPayload, size);

  Serial.printf("Received encrypted data from master, decrypted: %s | RSSI: %d | SNR: %d\n", decryptedPayload, rssi, snr);
  
  // Process the decrypted command
  processCommand(String(decryptedPayload));
}

void OnRxTimeout(void){
  Serial.println("RX Timeout");
}

void OnTxDone(void) {
  Serial.println("TX done");
  txDoneFlag = true;
}

void OnTxTimeout(void) {
  Serial.println("TX Timeout Callback Fired!");
  factory_display.clear();
  factory_display.drawString(10, 20, "LoRa Sender");
  factory_display.drawString(10, 40, "Packet #: " + String(counter));
  factory_display.drawString(10, 50, "TX TIMEOUT");
  factory_display.display();
  txDoneFlag = false; // Indicate failure
}

void processCommand(String command) {
  command.trim();
  command.toLowerCase();
  
  Serial.println("Processing command: " + command);
  
  if (command == "pump_on") {
    if (!pumpRunning) {
      startPump(millis());
      Serial.println("Remote pump activation received!");
    } else {
      Serial.println("Pump already running!");
    }
  }
  else if (command == "pump_off") {
    if (pumpRunning) {
      stopPump();
      Serial.println("Remote pump stop received!");
    } else {
      Serial.println("Pump already off!");
    }
  }
  else if (command == "status") {
    Serial.println("Status request received - sending sensor data");
    // This will be handled in the main loop to send sensor data
  }
  else if (command.startsWith("led_")) {
    if (command == "led_red") {
      setRGBColor(true, false, false);
      Serial.println("LED set to RED");
    }
    else if (command == "led_green") {
      setRGBColor(false, true, false);
      Serial.println("LED set to GREEN");
    }
    else if (command == "led_blue") {
      setRGBColor(false, false, true);
      Serial.println("LED set to BLUE");
    }
    else if (command == "led_off") {
      setRGBColor(false, false, false);
      Serial.println("LED turned OFF");
    }
  }
  else {
    Serial.println("Unknown command: " + command);
  }
}

void init_LoRa_slave(){
  Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE);  

  MAC_ID = ESP.getEfuseMac();

  factory_display.init();
  factory_display.clear();
  factory_display.drawString(20, 30, "LoRa Slave");
  factory_display.display();
  delay(1000);

  // Reset the radio before configuring
  pinMode(RST_LoRa, OUTPUT);
  digitalWrite(RST_LoRa, LOW);
  delay(50);
  digitalWrite(RST_LoRa, HIGH);
  delay(50);

  RadioEvents.RxDone = OnRxDone;
  RadioEvents.RxTimeout = OnRxTimeout;
  RadioEvents.TxDone = OnTxDone;
  RadioEvents.TxTimeout = OnTxTimeout;
  Radio.Init(&RadioEvents);

  Radio.SetChannel(RF_FREQUENCY);

  // Configure RX settings
  Radio.SetRxConfig(MODEM_LORA, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                   LORA_CODINGRATE, 0, LORA_PREAMBLE_LENGTH,
                   LORA_SYMBOL_TIMEOUT, LORA_FIX_LENGTH_PAYLOAD_ON,
                   0, true, 0, 0, LORA_IQ_INVERSION_ON, true);

  // Configure TX settings
  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_FIX_LENGTH_PAYLOAD_ON,
                    true, 0, 0, LORA_IQ_INVERSION_ON, 3000);

  // Start in RX mode to listen for commands
  Radio.Rx(0);

  Serial.println("LoRa Slave initialized and listening for commands...");
  
  // Print configuration for debugging
  Serial.println("LoRa Slave configuration:");
  Serial.println("RF_FREQUENCY: " + String(RF_FREQUENCY));
  Serial.println("TX_OUTPUT_POWER: " + String(TX_OUTPUT_POWER));
  Serial.println("LORA_BANDWIDTH: " + String(LORA_BANDWIDTH));
  Serial.println("LORA_SPREADING_FACTOR: " + String(LORA_SPREADING_FACTOR));
  Serial.println("LORA_CODINGRATE: " + String(LORA_CODINGRATE));
  Serial.println("LORA_PREAMBLE_LENGTH: " + String(LORA_PREAMBLE_LENGTH));
}

void setup() {
  Serial.begin(115200); 

  init_LoRa_slave();

  // Initialize pins
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  
  Serial.println("=================================");
  Serial.println("ESP32 Smart Garden System v1.0");
  Serial.println("=================================");
  Serial.println("Components initialized:");
  Serial.println("- DHT11 (Temp/Humidity): GPIO3");
  Serial.println("- LDR (Light): GPIO7");
  Serial.println("- Water Pump Relay: GPIO2");
  Serial.println("- RGB LED: R=GPIO6, G=GPIO5, B=GPIO4");
  Serial.println();
  
  WiFi.begin(ssid, pwd);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected: " + WiFi.localIP().toString());
  Serial.println();
  dht.begin();
  analogSetAttenuation(ADC_11db);
  
  // Turn off pump initially
  digitalWrite(RELAY_PIN, LOW);

   // Handle CORS preflight requests
  server.on("/led/on", HTTP_OPTIONS, handleCORS);
  server.on("/led/off", HTTP_OPTIONS, handleCORS);
  
  server.on("/led/on",HTTP_GET, handleLEDOn);
  server.on("/led/off",HTTP_GET, handleLEDOff);

  server.begin();
  
  // Test RGB LED on startup
  testRGBLED();
  
  // Start pump immediately for testing
  Serial.println("🚰 STARTING PUMP FOR INITIAL TEST!");
  startPump(millis());
  
  Serial.println("System ready!");
  Serial.println();
  
  delay(1000);
}

/**
 @def Handle Master - Slave Communication, via LoRaWAN
*/
void handle_ms_communication(){
  Radio.IrqProcess();

  // Handle received commands
  if(receivedFlag) {
    receivedFlag = false;
    // Command processing is handled in OnRxDone callback
    
    // Return to RX mode to continue listening
    delay(100);
    Radio.Rx(0);
  }

  // Send sensor data periodically (every 10 seconds)
  static unsigned long lastSensorSend = 0;
  if(millis() - lastSensorSend >= 10000) {
    sendSensorData();
    lastSensorSend = millis();
  }
}

void sendSensorData() {
  char buffer[50];
  sprintf(buffer, "%.2f-%.2f-%d-%d", temperature, humidity, lightLevel, (int)MAC_ID);

  Serial.print("Sending encrypted sensor data: ");
  Serial.println(buffer);

  // Calculate encrypted data size (must be multiple of 16)
  int messageLength = strlen(buffer);
  int encryptedSize = ((messageLength + BUFFER_SIZE - 1) / BUFFER_SIZE) * BUFFER_SIZE;
  
  byte encryptedData[encryptedSize];
  memset(encryptedData, 0, encryptedSize);
  
  // Encrypt the message
  encryptData(buffer, encryptedData, messageLength);

  // Show sending status
  factory_display.clear();
  factory_display.drawString(10, 10, "LoRa Slave");
  factory_display.drawString(10, 25, "Packet #: " + String(counter));
  factory_display.drawString(10, 40, "Sending data...");
  factory_display.display();

  // Ensure radio is in standby before sending
  Radio.Standby();
  delay(10);
  
  // Send the encrypted message
  Radio.Send(encryptedData, encryptedSize);

  unsigned long startTime = millis();
  bool softwareTimeoutOccurred = false;

  // Wait for transmission to complete
  while (!txDoneFlag) {
    Radio.IrqProcess();
    delay(1);
    
    if (millis() - startTime > 4000) { // 4 second timeout
      Serial.println("Software TX timeout!");
      softwareTimeoutOccurred = true;
      break;
    }
  }

  // Display result
  factory_display.clear();
  factory_display.drawString(10, 10, "LoRa Slave");
  factory_display.drawString(10, 25, "Packet #: " + String(counter));
  
  if (txDoneFlag) {
    Serial.println("Encrypted sensor data sent successfully!");
    factory_display.drawString(10, 40, "Data sent!");
  } else {
    Serial.println("Failed to send sensor data!");
    if (softwareTimeoutOccurred) {
      factory_display.drawString(10, 40, "SW TIMEOUT");
    } else {
      factory_display.drawString(10, 40, "HW TIMEOUT");
    }
  }
  factory_display.display();

  // Reset flag for next transmission
  txDoneFlag = false;
  counter++;

  // Return to RX mode to listen for commands
  delay(100);
  Radio.Rx(0);
}

void loop() {
  server.handleClient();
  handle_ms_communication();
  
  unsigned long currentTime = millis();
  
  // Read sensors every 2 seconds
  if (currentTime - lastSensorRead >= SENSOR_INTERVAL) {
    readSensors();
    displaySensorData();
    lastSensorRead = currentTime;
  }
  
  // Cycle LED colors every 1.5 seconds
  if (currentTime - lastLEDChange >= LED_CYCLE_TIME) {
    cycleLEDColors();
    lastLEDChange = currentTime;
  }
  
  // Handle automatic watering
  handleWatering(currentTime);
  
  delay(100); // Small delay for system stability
}

void readSensors() {
  // Read DHT11
  humidity = dht.readHumidity();
  temperature = dht.readTemperature();
  
  // Read LDR
  lightLevel = analogRead(LIGHT_SENSOR_PIN);
  
  // Validate DHT readings
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Error: Failed to read from DHT11 sensor!");
    humidity = -1;
    temperature = -1;
  }
}

void displaySensorData() {
  Serial.println("=== Sensor Readings ===");
  
  // Temperature and Humidity
  if (temperature != -1 && humidity != -1) {
    Serial.print("Temperature: ");
    Serial.print(temperature, 1);
    Serial.print("°C (Threshold: ");
    Serial.print(TEMP_HIGH);
    Serial.println("°C)");
    
    Serial.print("Humidity: ");
    Serial.print(humidity, 1);
    Serial.print("% (Threshold: ");
    Serial.print(HUMIDITY_LOW);
    Serial.println("%)");
    
    // Heat index
    float heatIndex = dht.computeHeatIndex(temperature, humidity, false);
    Serial.print("Heat Index: ");
    Serial.print(heatIndex, 1);
    Serial.println("°C");
  } else {
    Serial.println("Temperature: ERROR");
    Serial.println("Humidity: ERROR");
  }
  
  // Light Level
  Serial.print("Light Level: ");
  Serial.print(lightLevel);
  Serial.print(" => ");
  
  if (lightLevel < 40) {
    Serial.println("Dark");
  } else if (lightLevel < LIGHT_LOW) {
    Serial.println("Dim");
  } else if (lightLevel < LIGHT_HIGH) {
    Serial.println("Light");
  } else if (lightLevel < 3200) {
    Serial.println("Bright");
  } else {
    Serial.println("Very Bright");
  }
  
  // Pump Status
  Serial.print("Water Pump: ");
  Serial.println(pumpRunning ? "RUNNING" : "OFF");
  
  // Current LED Color
  Serial.print("Current LED: ");
  switch(currentLEDColor) {
    case 0: Serial.println("RED"); break;
    case 1: Serial.println("GREEN"); break;
    case 2: Serial.println("BLUE"); break;
    case 3: Serial.println("YELLOW"); break;
    case 4: Serial.println("PURPLE"); break;
    case 5: Serial.println("CYAN"); break;
    case 6: Serial.println("WHITE"); break;
    case 7: Serial.println("OFF"); break;
  }
  
  Serial.println("========================");
  Serial.println();
}

void cycleLEDColors() {
  switch(currentLEDColor) {
    case 0: // Red
      setRGBColor(true, false, false);
      break;
    case 1: // Green
      setRGBColor(false, true, false);
      break;
    case 2: // Blue
      setRGBColor(false, false, true);
      break;
    case 3: // Yellow
      setRGBColor(true, true, false);
      break;
    case 4: // Purple
      setRGBColor(true, false, true);
      break;
    case 5: // Cyan
      setRGBColor(false, true, true);
      break;
    case 6: // White
      setRGBColor(true, true, true);
      break;
    case 7: // Off
      setRGBColor(false, false, false);
      break;
  }
  
  currentLEDColor = (currentLEDColor + 1) % 8; // Cycle through 0-7
}

void handleWatering(unsigned long currentTime) {
  // Check if pump should be running
  if (pumpRunning) {
    // Stop pump after run time
    if (currentTime - pumpStartTime >= PUMP_RUN_TIME) {
      stopPump();
      lastPumpCycle = currentTime;
    }
  } else {
    // Check if we should start watering
    bool shouldWater = false;
    
    // Automatic watering conditions (lowered thresholds for testing)
    if (humidity != -1 && temperature != -1) {
      // Water if humidity is low OR temperature is high
      if (humidity < HUMIDITY_LOW || temperature > TEMP_HIGH) {
        // Only water if enough time has passed since last cycle
        if (currentTime - lastPumpCycle >= PUMP_INTERVAL) {
          shouldWater = true;
        }
      }
    }
    
    // Also trigger watering periodically for testing
    if (currentTime - lastPumpCycle >= 30000) { // Every 30 seconds for demo
      shouldWater = true;
    }
    
    if (shouldWater) {
      startPump(currentTime);
    }
  }
}

void startPump(unsigned long currentTime) {
  digitalWrite(RELAY_PIN, HIGH);
  pumpRunning = true;
  pumpStartTime = currentTime;
  
  Serial.println("🚰 STARTING WATER PUMP!");
  Serial.print("Reason: ");
  if (humidity != -1 && humidity < HUMIDITY_LOW) Serial.print("Low humidity (" + String(humidity) + "%) ");
  if (temperature != -1 && temperature > TEMP_HIGH) Serial.print("High temperature (" + String(temperature) + "°C) ");
  if (millis() - lastPumpCycle >= 30000) Serial.print("Periodic test cycle ");
  Serial.println();
}

void stopPump() {
  digitalWrite(RELAY_PIN, LOW);
  pumpRunning = false;
  
  Serial.println("🛑 STOPPING WATER PUMP");
  Serial.println("Watering cycle complete");
}

void setRGBColor(bool red, bool green, bool blue) {
  // For common anode RGB LED: LOW = ON, HIGH = OFF
  // For common cathode RGB LED: HIGH = ON, LOW = OFF
  // Assuming common cathode based on your previous code
  digitalWrite(RED_PIN, red ? HIGH : LOW);
  digitalWrite(GREEN_PIN, green ? HIGH : LOW);
  digitalWrite(BLUE_PIN, blue ? HIGH : LOW);
}

// RGB LED test function during startup
void testRGBLED() {
  Serial.println("Testing RGB LED on startup...");
  
  Serial.println("Red");
  setRGBColor(true, false, false);
  delay(800);
  
  Serial.println("Green");
  setRGBColor(false, true, false);
  delay(800);
  
  Serial.println("Blue");
  setRGBColor(false, false, true);
  delay(800);
  
  Serial.println("Yellow");
  setRGBColor(true, true, false);
  delay(800);
  
  Serial.println("Purple");
  setRGBColor(true, false, true);
  delay(800);
  
  Serial.println("Cyan");
  setRGBColor(false, true, true);
  delay(800);
  
  Serial.println("White");
  setRGBColor(true, true, true);
  delay(800);
  
  Serial.println("Off");
  setRGBColor(false, false, false);
  delay(500);
  
  Serial.println("RGB LED startup test complete!");
  Serial.println();
}

// Function to manually trigger watering via serial
void manualWatering() {
  if (!pumpRunning) {
    startPump(millis());
    Serial.println("Manual watering triggered!");
  } else {
    Serial.println("Pump already running!");
  }
}