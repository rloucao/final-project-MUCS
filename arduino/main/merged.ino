#include <WiFi.h>
#include <WebServer.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"
#include "Arduino.h"


const char* ssid = "Vodafone-18E4A0";
const char* pwd  = "hZ7qDeqy9Y";

// -----------------------------------------------------------------------------
// 3) WEBSERVER (CWC.ino) + HTTP CLIENT (CWS.ino) SETUP
// -----------------------------------------------------------------------------

// --- WebServer on port 80 (CWC.ino) ---
WebServer server(80);

// LED routes:
void handleLEDOn() {
  digitalWrite(LED_BUILTIN, LOW);   // on ESP32, LOW usually turns the onboard LED on
  server.send(200, "text/plain", "LED ON");
}
void handleLEDOff() {
  digitalWrite(LED_BUILTIN, HIGH);  // and HIGH turns it off
  server.send(200, "text/plain", "LED OFF");
}
void handleRoot() {
  // Simple HTML page with two links/buttons to toggle LED
  String html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>ESP32 Control</title></head><body>"
                "<h1>ESP32 LED Control</h1>"
                "<p><a href=\"/on\"><button style=\"padding:10px 20px;\">Turn LED ON</button></a></p>"
                "<p><a href=\"/off\"><button style=\"padding:10px 20px;\">Turn LED OFF</button></a></p>"
                "</body></html>";
  server.send(200, "text/html", html);
}

// --- HTTP Client (CWS.ino) ---
// This will POST a single string ("Hello from ESP32!") to a remote host.
IPAddress serverIP;                  // (not strictly used below, but kept for reference)
const char *host = "https://final-project-mucs.onrender.com";
WiFiClientSecure client;

// Helper function to send sensor (or debug) data via HTTPS POST
void sendSensorData(const String &data) {
  HTTPClient http;
  http.begin(client, host);
  // Use JSON body for example; adjust as needed
  http.addHeader("Content-Type", "application/json");
  String jsonPayload = "{\"msg\":\"" + data + "\"}";
  int httpCode = http.POST(jsonPayload);

  if (httpCode > 0) {
    Serial.printf("HTTP POST → code: %d\n", httpCode);
    String payload = http.getString();
    Serial.println("Response payload: " + payload);
  } else {
    Serial.printf("HTTP POST failed, error: %s\n", http.errorToString(httpCode).c_str());
  }
  http.end();
}

// -----------------------------------------------------------------------------
// 4) LoRa RECEIVER (receiver.ino) SETUP
// -----------------------------------------------------------------------------

// LoRa parameters (match sender settings)
#define RF_FREQUENCY           868000000
#define TX_OUTPUT_POWER        14
#define LORA_BANDWIDTH         0
#define LORA_SPREADING_FACTOR  7
#define LORA_CODINGRATE        1
#define LORA_PREAMBLE_LENGTH   8
#define LORA_SYMBOL_TIMEOUT    5
#define LORA_FIX_LENGTH_PAYLOAD_ON  false
#define LORA_IQ_INVERSION_ON   false

// OLED display (SSD1306) on I²C
SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

// A buffer for incoming LoRa packet
static uint8_t buffer[256];
static int packetCount = 0;
static unsigned long lastStatusUpdate = 0;
static bool    receiving       = false;

// This callback is invoked by the LoRa stack when a full packet is received
void onReceiveCSV(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr) {
  packetCount++;
  // Convert payload bytes to a String (assume UTF-8 or ASCII)
  String receivedText;
  for (uint16_t i = 0; i < size; i++) {
    receivedText += (char)payload[i];
  }

  // Clear and redraw the OLED
  factory_display.clear();
  factory_display.setTextAlignment(TEXT_ALIGN_LEFT);
  factory_display.setFont(ArialMT_Plain_10);
  factory_display.drawString(0, 0, "PACKET #" + String(packetCount));
  factory_display.drawString(0, 12, "RSSI: " + String(rssi));
  factory_display.drawString(0, 24, "SNR:  " + String(snr));
  factory_display.drawString(0, 36, "MSG:  " + receivedText);
  factory_display.display();

  Serial.printf("Packet #%d received  RSSI: %d  SNR: %d  MSG: %s\n",
                packetCount, rssi, snr, receivedText.c_str());

  // After processing one packet, put radio back to sleep and then to Rx
  receiving = false;
}

// -----------------------------------------------------------------------------
// 5) GLOBAL SETUP()   (combined from all three)
// -----------------------------------------------------------------------------

void setup() {
  // SERIAL(all) @ 115200
  Serial.begin(115200);
  delay(1000);
  Serial.println();
  Serial.println(">>> Starting combined main.ino ...");

  // -------------------------
  // A) WiFi Connection (both WebServer & HTTP client)
  // -------------------------
  WiFi.begin(ssid, pwd);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("WiFi connected! IP: " + WiFi.localIP().toString());

  // If you want to send one HTTP payload at startup:
  sendSensorData("Hello from ESP32!");

  // -------------------------
  // B) Configure WebServer routes
  // (CWC.ino functionality)
  // -------------------------
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH); // default off
  server.on("/", handleRoot);
  server.on("/on", handleLEDOn);
  server.on("/off", handleLEDOff);
  server.begin();
  Serial.println("WebServer started, listening on port 80");

  // -------------------------
  // C) LoRa Receiver & OLED (receiver.ino functionality)
  // -------------------------
  // Initialize the display
  factory_display.init();
  factory_display.clear();
  factory_display.display();

  // Initialize LoRa radio
  Radio.Init();
  Radio.SetChannel(RF_FREQUENCY);
  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_SYMBOL_TIMEOUT,
                    LORA_FIX_LENGTH_PAYLOAD_ON, true, 0, 0,
                    LORA_IQ_INVERSION_ON, 3000);
  Radio.SetRxConfig(MODEM_LORA, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                    LORA_CODINGRATE, 0, LORA_PREAMBLE_LENGTH,
                    LORA_SYMBOL_TIMEOUT, LORA_FIX_LENGTH_PAYLOAD_ON, true, 0,
                    0, LORA_IQ_INVERSION_ON, true);
  Radio.SetMaxPayloadLength(255);
  Radio.Rx(0);  // Start listening (continuous mode)
  receiving = true;
  lastStatusUpdate = millis();

  Serial.println("LoRa receiver initialized and listening...");
}

// -----------------------------------------------------------------------------
// 6) GLOBAL LOOP()   (combined from all three)
// -----------------------------------------------------------------------------

void loop() {
  // -------------------------
  // A) Handle incoming HTTP requests
  // (CWC.ino WebServer)
  // -------------------------
  server.handleClient();

  // -------------------------
  // B) LoRa packet handling
  // -------------------------
  // The LoRa stack uses interrupts; just poll the IRQ handler here:
  if (!receiving) {
    // If not yet set to Rx, put radio back to Rx
    Radio.Sleep();
    delay(50);
    Radio.Rx(0);
    receiving = true;
    lastStatusUpdate = millis();
    Serial.println("Re-armed LoRa Rx");
  }

  // Always process IRQ in every iteration
  Radio.IrqProcess();

  // Periodic status update (every 5 seconds) if still waiting
  if (receiving && (millis() - lastStatusUpdate > 5000)) {
    Serial.println("Still listening... Packets: " + String(packetCount));
    lastStatusUpdate = millis();
  }

  // (No additional code from CWS loop, since it was empty)
  delay(10);  // small sleep to avoid hogging CPU
}
