/**
- This is the file that handles:
 - Communication with the App
 - Communication with the server
 - Communication with the LoRa (only receiving)
*/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <HT_SSD1306Wire.h>
#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"
#include <WebServer.h>

const char* ssid = "Vodafone-18E4A0";
const char* pwd = "hZ7qDeqy9Y";
#define LORA_FREQUENCY 868000000  
#define TX_OUTPUT_POWER 14     
#define LORA_BANDWIDTH 0       
#define LORA_SPREADING_FACTOR 7
#define LORA_CODINGRATE 1      
#define LORA_PREAMBLE_LENGTH 8
#define LORA_SYMBOL_TIMEOUT 5
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false

IPAddress serverIP;
const char *host = "https://final-project-mucs.onrender.com";  
WiFiClientSecure client;

SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

bool receivedFlag = false;
const unsigned int receivedPayloadSize = 128;  
char receivedPayload[receivedPayloadSize]; 
unsigned long lastStatusUpdate = 0;
unsigned long packetCount = 0;
int counter = 0;
bool txDoneFlag = false;
bool LED_ON = false;

WebServer server(80);

void display_message(int posX, int posY, String message, int t = 1000){
  factory_display.clear();
  factory_display.drawString(posX, posY, message);
  factory_display.display();
  if(t > 0) delay(t);
}

void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr) {
  receivedFlag = true;
  packetCount++;
  
  // Ensure we don't overflow the buffer
  size = min(size, (uint16_t)(receivedPayloadSize - 1));
  memcpy(receivedPayload, payload, size);
  receivedPayload[size] = '\0'; 

  LED_ON = !LED_ON;
  digitalWrite(LED_BUILTIN, LED_ON ? HIGH : LOW);

  Serial.printf("Received: %s | RSSI: %d | SNR: %d\n", receivedPayload, rssi, snr);
  
  // Update display immediately
  factory_display.clear();
  factory_display.drawString(0, 0, "LoRa Master");
  factory_display.drawString(0, 20, "Received:");
  factory_display.drawString(0, 40, String(receivedPayload));
  factory_display.drawString(0, 55, "RSSI:" + String(rssi));
  factory_display.display();
}

void OnRxTimeout(void){
  Serial.println("RX Timeout");
  // Don't put radio to sleep on timeout, just continue listening
  // The radio will automatically continue in RX mode
}

void OnTxDone(void) {
  Serial.println("TX done");
  txDoneFlag = true;
}

void OnTxTimeout(void) {
  Serial.println("TX Timeout Callback Fired!");
  txDoneFlag = false; // Indicate failure
}

void send_message_to_client(int status_code, String message){
  server.send(status_code, "text/plain" , message);
}

void send_message_to_slave(){
  if (!server.hasArg("msg")) {
    display_message(20, 40, "Missing message");
    server.send(400, "text/plain", "Missing ?msg= parameter");
    return;
  }

  String message = server.arg("msg");
  display_message(20, 40 , "Attempting to send: " + message);

  // Switch to TX mode
  Radio.Standby();
  
  char converted_message[receivedPayloadSize];
  message.toCharArray(converted_message, receivedPayloadSize);

  Radio.Send((uint8_t *)converted_message, message.length());
  unsigned long startTime = millis();
  bool softwareTimeoutOccurred = false;

  while (!txDoneFlag) {
    Radio.IrqProcess();
    delay(10);
    if (millis() - startTime > 3500) {
      Serial.println("Software TX timeout in loop!");
      softwareTimeoutOccurred = true;
      break;
    }
  }

  if(txDoneFlag){
    display_message(20, 40, "Sent successfully");
    server.send(200, "text/plain", "Message sent successfully");
  }
  else{
    display_message(20, 40, "TX Failed");
    server.send(500, "text/plain", "Failed to send message");
  }
  
  txDoneFlag = false;
  
  // Switch back to RX mode
  delay(100);
  Radio.Rx(0);
}

void send_sensor_data_to_server(){
  HTTPClient http;
  String data = String(receivedPayload);

  client.setInsecure(); 
  String path = String(host) + "/send_sensor_data?data=" + data;
  
  Serial.println("Sending to server: " + data);

  http.begin(client, path);
  http.addHeader("Content-Type", "application/json");

  int res_code = http.POST("");
  if(res_code > 0){
    String res = http.getString();
    Serial.println("Server response: " + res);
  }else{
    Serial.println("Error sending to server: " + String(res_code));
  }
  http.end();
}

void handleCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(200, "text/plain", "");
}

void handle_LED(){
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  
  LED_ON = !LED_ON;
  digitalWrite(LED_BUILTIN, LED_ON ? HIGH : LOW);
  send_message_to_client(200, LED_ON ? "LED is on" : "LED is off");
}

void wifi_connect(){
    WiFi.begin(ssid, pwd);
    while(WiFi.status() != WL_CONNECTED){
        delay(500);
        Serial.print(".");
    }

    Serial.println("\nWiFi connected: " + WiFi.localIP().toString());
    factory_display.clear();
    factory_display.drawString(20, 20, "Connected to WiFi");
    factory_display.drawString(20, 40, WiFi.localIP().toString());
    factory_display.display();
    delay(2000);
}

void set_up_server(){
  server.on("/led", HTTP_OPTIONS, handleCORS);
  server.on("/led",HTTP_GET, handle_LED);
  server.on("/slave",HTTP_GET, send_message_to_slave);
  server.begin();
  Serial.println("HTTP server started");
}

void init_lora(){
  Serial.begin(115200);
    
  factory_display.init();
  factory_display.clear();
  factory_display.drawString(20, 20, "LoRa Master");
  factory_display.drawString(20, 40, "Starting...");
  factory_display.display();
  delay(1000);

  Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE);

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // Reset LoRa module
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

  Radio.SetChannel(LORA_FREQUENCY);
  
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

  // Start in RX mode
  Radio.Rx(0);
  
  Serial.println("LoRa Master initialized and listening...");

  wifi_connect();
  set_up_server();

  display_message(20, 40, "Master Ready - Listening", 2000);
}

void setup() {
  init_lora();
}

void loop() {
  // Handle HTTP requests
  server.handleClient();

  // Process LoRa interrupts
  Radio.IrqProcess();

  // Handle received LoRa messages
  if(receivedFlag){
    receivedFlag = false;
    
    Serial.println("Processing received message: " + String(receivedPayload));
    
    // Send to server
    send_sensor_data_to_server();
    
    // Small delay before returning to RX mode
    delay(100);
    
    // Ensure we're back in RX mode
    Radio.Rx(0);
  }

  // Status update every 10 seconds
  static unsigned long lastHeartBeat = 0;
  if(millis() - lastHeartBeat > 10000){
    lastHeartBeat = millis();
    
    if(!receivedFlag) { // Only update display if not currently processing a message
      factory_display.clear();
      factory_display.drawString(0, 0, "LoRa Master");
      factory_display.drawString(0, 20, "Listening...");
      factory_display.drawString(0, 40, "Packets: " + String(packetCount));
      factory_display.drawString(0, 55, "IP: " + WiFi.localIP().toString());
      factory_display.display();
    }
    
    Serial.println("Still listening... Packets received: " + String(packetCount));
  }
}