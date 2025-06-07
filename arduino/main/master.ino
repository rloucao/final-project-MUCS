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
#include "AES.h"
#include "Crypto.h"

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

#define BUFFER_SIZE 16  
#define HEARTBEAT_INTERVAL 7200000UL

IPAddress serverIP;
const char *host = "https://final-project-mucs.onrender.com";  
WiFiClientSecure client;

SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

bool receivedFlag = false;
const unsigned int receivedPayloadSize = 128;  
char receivedPayload[receivedPayloadSize]; 
char decryptedPayload[receivedPayloadSize];
unsigned long lastStatusUpdate = 0;
unsigned long packetCount = 0;
int counter = 0;
bool txDoneFlag = false;
bool LED_ON = false;

WebServer server(80);

byte key[16] = { 0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
                 0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81 };

AES128 aes;
byte cipherText[BUFFER_SIZE];
byte decryptText[BUFFER_SIZE];
byte plaintext[BUFFER_SIZE];


void send_heartbeat_ping(){
  if (heartbeatInProgress) {
    Serial.println("Heartbeat already in progress, skipping...");
    return;
  }
  
  heartbeatInProgress = true;
  
  const char* heartbeatMsg = "HEARTBEAT";
  Serial.println("Sending heartbeat ping to slaves...");
  
  Radio.Standby();
  delay(50);
  
  int messageLength = strlen(heartbeatMsg);
  int encryptedSize = ((messageLength + BUFFER_SIZE - 1) / BUFFER_SIZE) * BUFFER_SIZE;
  
  byte encryptedData[encryptedSize];
  memset(encryptedData, 0, encryptedSize);
  
  encryptData(heartbeatMsg, encryptedData, messageLength);
  
  Radio.Send(encryptedData, encryptedSize);
  
  unsigned long startTime = millis();
  txDoneFlag = false;
  
  while (!txDoneFlag) {
    Radio.IrqProcess();
    delay(10);
    if (millis() - startTime > 3000) {
      Serial.println("Heartbeat TX timeout!");
      break;
    }
  }
  
  if (txDoneFlag) {
    Serial.println("Heartbeat sent successfully");
  } else {
    Serial.println("Failed to send heartbeat");
  }
  
  txDoneFlag = false;
  heartbeatInProgress = false;
  
  delay(100);
  Radio.Rx(0);
}

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

void decryptData(const byte *encryptedData, char *decryptedOutput, int dataLength) {
  aes.setKey(key, sizeof(key));
  
  int blocks = (dataLength + BUFFER_SIZE - 1) / BUFFER_SIZE; 

  for(int i = 0; i < blocks; i++) {
    aes.decryptBlock(decryptText, encryptedData + (i * BUFFER_SIZE));
    
    int copyLength = min(BUFFER_SIZE, dataLength - (i * BUFFER_SIZE));
    memcpy(decryptedOutput + (i * BUFFER_SIZE), decryptText, copyLength);
  }
  
  decryptedOutput[dataLength] = '\0';
  
  for(int i = dataLength - 1; i >= 0; i--) {
    if(decryptedOutput[i] == '\0') {
      continue;
    } else {
      decryptedOutput[i + 1] = '\0';
      break;
    }
  }
}

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
  
  // Decrypt the received data
  memset(decryptedPayload, 0, sizeof(decryptedPayload));
  decryptData((byte*)receivedPayload, decryptedPayload, size);

  LED_ON = !LED_ON;
  digitalWrite(LED_BUILTIN, LED_ON ? HIGH : LOW);

  Serial.printf("Received encrypted data, decrypted: %s | RSSI: %d | SNR: %d\n", decryptedPayload, rssi, snr);
  
  // Update display with decrypted message
  factory_display.clear();
  factory_display.drawString(0, 0, "LoRa Master");
  factory_display.drawString(0, 20, "Received:");
  factory_display.drawString(0, 40, String(decryptedPayload));
  factory_display.drawString(0, 55, "RSSI:" + String(rssi));
  factory_display.display();


  Serial.println("Data received through LoRaWAN");
  Serial.println(String(decryptedPayload));
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
  txDoneFlag = false; 
}

void send_message_to_client(int status_code, String message){
  server.send(status_code, "text/plain" , message);
}

void send_message_to_slave(){

  display_message(20, 40 , "Fetching new sensor results");


  Radio.Standby();
  String message = "sensor_data";
  int messageLength = message.length();
  int encryptedSize = ((messageLength + BUFFER_SIZE - 1) / BUFFER_SIZE) * BUFFER_SIZE;
  
  byte encryptedData[encryptedSize];
  memset(encryptedData, 0, encryptedSize);
  
  encryptData(message.c_str(), encryptedData, messageLength);
  
  Serial.println("Sending encrypted message, original: " + message);

  Radio.Send(encryptedData, encryptedSize);
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
  // Use decrypted payload for server communication
  String data = String(decryptedPayload);

  
  char buffer[50];
  int messageLength = strlen(buffer);
  int encryptedSize = ((messageLength + BUFFER_SIZE - 1) / BUFFER_SIZE) * BUFFER_SIZE;
  
  byte encryptedData[encryptedSize];
  memset(encryptedData, 0, encryptedSize);
  
  // Encrypt the message
  encryptData(buffer, encryptedData, messageLength);

  client.setInsecure(); 
  String path = String(host) + "/send_sensor_data?data=" + encryptedData;
  
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
  server.on("/slave", HTTP_GET, send_message_to_slave);
  server.begin();
  Serial.println("HTTP server started");
}

void init_lora(){
  Serial.begin(74880);
    
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
  server.handleClient();

  Radio.IrqProcess();

  if(receivedFlag){
    receivedFlag = false;
    
    Serial.println("Processing received message: " + String(decryptedPayload));
    
    delay(10000);
    send_sensor_data_to_server();
    
    delay(100);
    
    Radio.Rx(0);
  }

  if(millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    lastHeartbeat = millis();
    send_heartbeat_ping();
  }


  static unsigned long lastHeartBeat = 0;
  if(millis() - lastHeartBeat > 10000){
    lastHeartBeat = millis();
    hearbeat_ping();
    if(!receivedFlag) { 
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