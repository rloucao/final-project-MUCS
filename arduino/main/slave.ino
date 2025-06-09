/*
 * ESP32 Smart Garden System - Integrated Sensors & Actuators
 * Updated for NoxGhost's pin configuration
 *
 * Components:
 * - DHT11 Temperature & Humidity Sensor
 * - LDR Light Sensor
 * - Water Pump (via Relay)
 * - RGB LED Status Indicator
 *
 * Author: NoxGhost
 * Date: 2025-06-05
 */

#include <DHT.h>
#include <WiFi.h>
#include <WebServer.h>
#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"


//const char* ssid = "Vodafone-18E4A0";
//const char* pwd = "hZ7qDeqy9Y";
const char* ssid = "Galaxy21";
const char* pwd = "mynet12345";

WebServer server(80);

// Pin Definitions (Your specific connections)
#define DHT_PIN         3     // DHT11 sensor
#define LIGHT_SENSOR_PIN 7    // LDR sensor
#define RELAY_PIN       2     // Water pump relay
#define RED_PIN         4     // RGB LED Red
#define GREEN_PIN       5     // RGB LED Green
#define BLUE_PIN        6    // RGB LED Blue

#define RF_FREQUENCY 868000000
#define TX_OUTPUT_POWER 14
#define LORA_BANDWIDTH 0
#define LORA_SPREADING_FACTOR 7
#define LORA_CODINGRATE 1
#define LORA_PREAMBLE_LENGTH 8
#define LORA_SYMBOL_TIMEOUT 5
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false






// DHT11 Configuration
#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);


SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

int counter = 0;
bool txDoneFlag = false;


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
const float TEMP_HIGH = 29.0;        // Lower threshold for testing
const float HUMIDITY_LOW =70.0;     // Higher threshold for testing
const int LIGHT_LOW = 800;           // Dark threshold
const int LIGHT_HIGH = 2000;         // Bright threshold
const unsigned long PUMP_RUN_TIME = 2000;     // 5 seconds for testing
const unsigned long PUMP_INTERVAL = 1000;    // 15 seconds between cycles for testing (TODO)
const unsigned long SENSOR_INTERVAL = 2000;   // 2 seconds between readings
const unsigned long LED_CYCLE_TIME = 1500;    // 1.5 seconds per color



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

void handle_Pump() {

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "Content-Type");

    unsigned long currentTime = millis();

    startPump(currentTime);
    delay(2000);
    stopPump();
    server.send(200, "text/plain", "Pump ran");
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

void init_LoRa_slave(){
    Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE);

    factory_display.init();
    factory_display.clear();
    factory_display.drawString(20, 30, "LoRa Sender");
    factory_display.display();
    delay(1000);

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

    Serial.println("LoRa Sender initialized");

    // Print configuration for debugging
    Serial.println("LoRa Sender configuration:");
    Serial.println("RF_FREQUENCY: " + String(RF_FREQUENCY));
    Serial.println("TX_OUTPUT_POWER: " + String(TX_OUTPUT_POWER));
    Serial.println("LORA_BANDWIDTH: " + String(LORA_BANDWIDTH));
    Serial.println("LORA_SPREADING_FACTOR: " + String(LORA_SPREADING_FACTOR));
    Serial.println("LORA_CODINGRATE: " + String(LORA_CODINGRATE));
    Serial.println("LORA_PREAMBLE_LENGTH: " + String(LORA_PREAMBLE_LENGTH));

    server.on("/led", HTTP_OPTIONS, handleCORS);
    server.on("/led",HTTP_GET, handle_Pump);
    Serial.println("HTTP server started");

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


    server.on("/led/on",HTTP_GET, handleLEDOn);
    server.on("/led/off",HTTP_GET, handleLEDOff);
    server.begin();


    // Test RGB LED on startup
    testRGBLED();

    Serial.println("System ready!");
    Serial.println();

    delay(1000);


}


void handle_ms_communication(){
    Radio.IrqProcess();

    char buffer[30];
    sprintf(buffer, "hello %d", counter);

    Serial.print("Attempting to send: ");
    Serial.println(buffer);

    // Show sending status
    factory_display.clear();
    factory_display.drawString(10, 10, "LoRa Sender");
    factory_display.drawString(10, 25, "Packet #: " + String(counter));
    factory_display.drawString(10, 40, "Msg: " + String(buffer));
    factory_display.drawString(10, 55, "Sending...");
    factory_display.display();

    // Ensure radio is in standby before sending
    Radio.Standby();
    delay(10);

    // Send the message
    Radio.Send((uint8_t *)buffer, strlen(buffer));

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
    factory_display.drawString(10, 10, "LoRa Sender");
    factory_display.drawString(10, 25, "Packet #: " + String(counter));
    factory_display.drawString(10, 40, "Msg: " + String(buffer));

    if (txDoneFlag) {
        Serial.println("TX successful!");
        factory_display.drawString(10, 55, "SUCCESS!");
    } else {
        Serial.println("TX failed!");
        if (softwareTimeoutOccurred) {
            factory_display.drawString(10, 55, "SW TIMEOUT");
        } else {
            factory_display.drawString(10, 55, "HW TIMEOUT");
        }
    }
    factory_display.display();

    // Reset flag for next transmission
    txDoneFlag = false;
    counter++;

    // Wait before next transmission
    Serial.println("Waiting 5 seconds before next transmission...");
    unsigned long delayStart = millis();
    while(millis() - delayStart < 2000) {
        Radio.IrqProcess();
        delay(10);
    }
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

    // Update LED based on environmental conditions
    updateLEDStatus();

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

void updateLEDStatus() {
    // Get current environmental conditions
    bool isDark = lightLevel < LIGHT_LOW;
    bool isBright = lightLevel >= LIGHT_HIGH;
    bool isHighTemp = temperature > TEMP_HIGH;

    // Static variables for LED effects
    static bool blinkState = false;
    static unsigned long lastBlinkTime = 0;
    static int pulseStage = 0;
    static bool pulseDirection = true;

    unsigned long currentTime = millis();

    // Case 1: Dark and high temperature - Blinking yellow
    if (isDark && isHighTemp) {
        // Blink yellow (500ms interval)
        if (currentTime - lastBlinkTime >= 50) {
            blinkState = !blinkState;
            lastBlinkTime = currentTime;

            if (blinkState) {
                // Yellow ON (RED + GREEN)
                digitalWrite(RED_PIN, LOW);
                digitalWrite(GREEN_PIN, LOW);
                digitalWrite(BLUE_PIN, HIGH);
                currentLEDColor = 3; // YELLOW
            } else {
                // OFF
                digitalWrite(RED_PIN, HIGH);
                digitalWrite(GREEN_PIN, HIGH);
                digitalWrite(BLUE_PIN, HIGH);
                currentLEDColor = 7; // OFF
            }
        }
    }
        // Case 2: Dark conditions only - Solid yellow
    else if (isDark && !isHighTemp) {
        // Solid yellow
        digitalWrite(RED_PIN, LOW);
        digitalWrite(GREEN_PIN, LOW);
        digitalWrite(BLUE_PIN, HIGH);
        currentLEDColor = 3; // YELLOW
    }
        // Case 3: Bright and high temperature - Alternating red and yellow
    else if (isBright && isHighTemp) {
        // Alternate between red and yellow (every 200ms)
        if (currentTime - lastBlinkTime >= 100) {
            lastBlinkTime = currentTime;
            blinkState = !blinkState;

            if (blinkState) {
                // Yellow (RED + GREEN on, BLUE off)
                digitalWrite(RED_PIN, LOW);
                digitalWrite(GREEN_PIN, LOW);
                digitalWrite(BLUE_PIN, HIGH);
                currentLEDColor = 3; // YELLOW
            } else {
                // Red (RED on, GREEN + BLUE off)
                digitalWrite(RED_PIN, LOW);
                digitalWrite(GREEN_PIN, HIGH);
                digitalWrite(BLUE_PIN, HIGH);
                currentLEDColor = 0; // RED
            }
        }
    }
        // Case 4: Bright and normal temperature - Solid green
    else if (isBright && !isHighTemp) {
        // Solid green
        digitalWrite(RED_PIN, HIGH);
        digitalWrite(GREEN_PIN, LOW);
        digitalWrite(BLUE_PIN, HIGH);
        currentLEDColor = 1; // GREEN
    }
        // Default fallback
    else {
        // Turn off LED
        digitalWrite(RED_PIN, HIGH);
        digitalWrite(GREEN_PIN, HIGH);
        digitalWrite(BLUE_PIN, HIGH);
        currentLEDColor = 7; // OFF
    }
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
            if (humidity < HUMIDITY_LOW) {
                // Only water if enough time has passed since last cycle
                if (currentTime - lastPumpCycle >= PUMP_INTERVAL) {
                    shouldWater = true;
                }
            }
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
    if (humidity != -1 && humidity < HUMIDITY_LOW) Serial.print("Low humidity (" + String(humidity) + "%) ");
    //if (temperature != -1 && temperature > TEMP_HIGH) Serial.print("High temperature (" + String(temperature) + "°C) ");
    //if (millis() - lastPumpCycle >= 30000) Serial.print("Periodic test cycle ");
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
    // Assuming common cathode based on your previous code
    digitalWrite(RED_PIN, red ? LOW : HIGH);
    digitalWrite(GREEN_PIN, green ? LOW : HIGH);
    digitalWrite(BLUE_PIN, blue ? LOW : HIGH);
}

// RGB LED test function during startup
void testRGBLED() {
    Serial.println("Testing RGB LED on startup...");

    Serial.println("Red");
    setRGBColor(true, false, false);
    delay(800);


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