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
#define TX_OUTPUT_POWER 14     // Match sender's power level
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
const unsigned int receivedPayloadSize = 128;  // Fixed: "unsisnght" -> "unsigned"
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
  delay(t);
}

void OnRxDone(uint8_t *payload, uint16_t size, int16_t rssi, int8_t snr) {
  receivedFlag = true;
  packetCount++;
  memcpy(receivedPayload, payload, size);
  receivedPayload[size] = '\0'; 


  Serial.printf("Received: %s | RSSI: %d | SNR: %d\n", receivedPayload, rssi, snr);
  display_message(20,40, "Received: "+ String(receivedPayload), 0);
}

void OnRxTimeout(void){
  Radio.Sleep();
  display_message(20,40, "RX Timeout" ,0);
}

void OnTxDone(void) {
  display_message(20, 40, "TX done" , 0);
  txDoneFlag = true;
}

void OnTxTimeout(void) {
  display_message(10, 20, "TX Timeout Callback Fired!", 0);
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

  Radio.IrqProcess();

  // Fixed: Correct declaration and usage
  char converted_message[receivedPayloadSize];
  message.toCharArray(converted_message, receivedPayloadSize);

  // Fixed: Use converted_message instead of message, and correct length
  Radio.Send((uint8_t *)converted_message, message.length());
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

  if(txDoneFlag){
    display_message(20, 40, "Sent successfully");
  }
  else{
    display_message(20, 40, "txDoneFlag is false");
    if(!softwareTimeoutOccurred){
      display_message(20, 40, "Not a software timeout", 2000);
      display_message(20, 40, "Check OnTxTimeout");
    }
    else{
      display_message(20, 40, "TX SW Timeout");
    }
  }
  txDoneFlag = false;
}


//Not necessary
void receive_message_from_slave(){
  Radio.IrqProcess();

  if (receivedFlag) {
    receivedFlag = false;

    display_message(20, 20, "Received: ");
    display_message(20, 40, String(receivedPayload));
    
    
    Radio.Sleep();
    delay(100);
    

    Radio.Rx(0);
    Serial.println("Back to RX mode after packet");
  }

  
  if (millis() - lastStatusUpdate > 3000) {
    Radio.IrqProcess(); 

    display_message(20,40 ,"received: ");
    display_message(20,40 , String(receivedPayload));  // Fixed: Added missing parameter
    factory_display.clear();
    factory_display.drawString(0, 0, "LoRa Receiver");
    factory_display.drawString(0, 20, "Listening...");
    factory_display.drawString(0, 40, "Packets: " + String(packetCount));
    factory_display.display();
    
    Radio.Sleep();
    delay(50);
    Radio.Rx(0);
    
    Serial.println("Still listening... Packets: " + String(packetCount));
    lastStatusUpdate = millis();
  }
}


void send_sensor_data_to_server(){
  HTTPClient http;
  String data = String(receivedPayload);

  //Was missing the CTA certificate
  client.setInsecure(); 

  // Fixed: Proper string concatenation
  String path = String(host) + "/send_sensor_data?data=" + data;
  display_message(20, 40, "Attempting to send data");
  display_message(20, 40, data);

  http.begin(client, path);
  http.addHeader("Content-Type", "application/json");

  int res_code = http.POST(""); //No need to add parameter as the value is already passed in the URL
  if(res_code){
    String res = http.getString();
    display_message(20, 40, res);
  }else{
    display_message(20, 40, "Error on sending message to server" + String(res_code));
  }
  http.end();
}


void handle_LED(){
  LED_ON = !LED_ON;
  digitalWrite(LED_BUILTIN, LED_ON ? HIGH : LOW);
  send_message_to_client(200, LED_ON ? "LED is on" : "LED is off");  // Fixed: "LEF" -> "LED"
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

}

void set_up_server(){
  server.on("/led", handle_LED);
  server.on("/slave", send_message_to_slave);
  server.begin();
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
  delay(50);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(50);

  RadioEvents.RxDone = OnRxDone;
  RadioEvents.RxTimeout = OnRxTimeout;
  RadioEvents.TxDone = OnTxDone;
  RadioEvents.TxTimeout = OnTxTimeout;
  Radio.Init(&RadioEvents);

  Radio.SetChannel(LORA_FREQUENCY);
  Radio.SetRxConfig(MODEM_LORA, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                   LORA_CODINGRATE, 0, LORA_PREAMBLE_LENGTH,
                   LORA_SYMBOL_TIMEOUT, LORA_FIX_LENGTH_PAYLOAD_ON,
                   0, true, 0, 0, LORA_IQ_INVERSION_ON, true);
  Radio.Rx(0);
  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_FIX_LENGTH_PAYLOAD_ON,
                    true, 0, 0, LORA_IQ_INVERSION_ON, 3000);


  wifi_connect();

  set_up_server();

  display_message(20, 40, "Master Is Ready" , 3000);
}


void setup() {
  init_lora();
}

void waiting_request(){
  static unsigned long lastHeartBeat = 0;
  if(millis() - lastHeartBeat > 10000){
    lastHeartBeat = millis();
    display_message(20,40, "Waiting for requests...");  // Fixed: "Watting" -> "Waiting"
  }

}

void loop() {
 server.handleClient();

  Radio.IrqProcess();

  if(receivedFlag){
    receivedFlag = false;

    display_message(20, 40, "Received: ", 2000);
    display_message(20, 40, String(receivedPayload));

    send_sensor_data_to_server();

    Radio.Sleep();
    delay(50);
    Radio.Rx(0);
  }

  waiting_request();

}