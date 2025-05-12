#include "Arduino.h"
#include "WiFi.h"
#include "images.h"
#include "LoRaWan_APP.h"
#include <Wire.h>
#include "HT_SSD1306Wire.h"
#include "AES.h"
#include "Crypto.h"
#include <WiFiClientSecure.h>
#include <WebSocketsClient.h>

//Lora Radio Frequency settings
#define RF_FREQUENCY 868000000   // Hz
#define TX_OUTPUT_POWER 10       // dBm
#define LORA_BANDWIDTH 0         // [0: 125 kHz,
#define LORA_SPREADING_FACTOR 7  // [SF7..SF12]
#define LORA_CODINGRATE 1        // [1: 4/5,
#define LORA_PREAMBLE_LENGTH 8   // Same for Tx and Rx
#define LORA_SYMBOL_TIMEOUT 0    // Symbols
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false
#define RX_TIMEOUT_VALUE 1000
#define BUFFER_SIZE 30  // Define the payload size here
#define LORA_FREQUENCY 115200


//Wifi ssid and password (Put your WiFi credentials here please :D )
char *ssid = "Vodafone-18E4A0.5";
char *pwd = "hZ7qDeqy9Y";

IPAddress serverIP;
const char *host = "http://127.0.0.1";  
const int serverPort = 5000;

const char *client_host = "toBeDefined";
const int client_port = 5001;

WiFiClientSecure client;

SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

WebSocketsClient webSocket;

/**
 * @brief Send information to server
 * Sends request to http://127.0.0.1/receive
 * 
 */
void post_to_server(String data){

    if(client.connect(host, serverPort)){
        String url = host + "/sync_data?data=";
        String endpoint = String(url) +data;

         
        client.print(String("POST ") + endpoint + " HTTP/1.1\r\n" +
                      "Host: " + host + "\r\n" +
                      "Connection: close\r\n\r\n");

        while(client.connected() || client.available()){
            if(client.available()){
                String line = client.readStringUntil('\n');
                Serial.println("Res server: " + line);
            }
        }
        client.stop();
    }else{
        Serial.print("Couldn't connect to the server");
    }

}


void post_to_client(String data){
     if(client.connect(client_host, client_port)){
        String url = client_host + "/receive?data=";
        String endpoint = String(url) +data;

         
        client.print(String("POST ") + endpoint + " HTTP/1.1\r\n" +
                      "Host: " + host + "\r\n" +
                      "Connection: close\r\n\r\n");

        while(client.connected() || client.available()){
            if(client.available()){
                String line = client.readStringUntil('\n');
                Serial.println("Res server: " + line);
            }
        }
        client.stop();
    }else{
        Serial.print("Couldn't connect to the server");
    }
}

/**
 * @brief Set up WiFi connection, Server connection
 *  
 */
void setup(){

    client.setInsecure();
    Serial.begin(LORA_FREQUENCY);
    pinMode(7, INPUT);

    // Commence LoRa device initialization
    factory_display.intit();
    factory_display.clear();
    factory_display.display();
    logo();
    delay(300);
    factory_display.clear();

    // Commence WiFi connection
    WiFi.disconnect(true);
    delay(1000);
    WiFi.mode(WIFI_STA);
    WiFi.setAutoReconnect(true);

    // Commence brute force WiFi connection, max 10 attempts
    int attempt = 0;
    bool connect = false;

    packet = "Connecting to Wi-Fi";
    factory_display.clear();
    factory_display.drawString(15, 30, packet);
    factory_display.display();
    factory_display.clear();

    while( attempt < 10 || !connect ){
        Serial.println("Attempting to connect to WiFi...");
        WiFi.begin(ssid, pwd);
        delay(500);
        
        if(WiFi.status() == WL_CONNECTED){
            Serial.println("Connected to Wifi." + ssid);
            connect = true;
        }
        else{
            Serial.println("Failed to connect. Retrying..." + attempt++);
            delay(500);
        }
    }

    // TODO - Connect to flutter app
    if(connect){
        //Convert host url to IP (DNS), and establish connection
        if(!WiFi.hostByName(host,serverIP)){
            Serial.println("Failed to resolve host!");
            return;
        }
    }

    packet = "Receive to work!";
    factory_display.drawString(27, 30, packet);
    factory_display.display();
    pinMode(LED, OUTPUT);
    digitalWrite(LED, LOW);

    // Set up WebSocket connection
    //webSocket.begin(client_host, client_port, "/ws"); // Replace "/ws" with your WebSocket endpoint
    //webSocket.onEvent(webSocketEvent);
    //webSocket.setReconnectInterval(5000);
}


/**
 * @brief 
 */
void loop(){
    //webSocket.loop();
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_DISCONNECTED:
            Serial.println("Disconnected from WebSocket server");
            break;
        case WStype_CONNECTED:
            Serial.println("Connected to WebSocket server");
            break;
        case WStype_TEXT:
            Serial.printf("Received message: %s\n", payload);
            break;
    }
}

// Replace the HTTP POST function with this WebSocket send function
void send_to_flutter(String data) {
    if(webSocket.isConnected()) {
        webSocket.sendTXT(data);
        Serial.println("Data sent via WebSocket: " + data);
    } else {
        Serial.println("WebSocket not connected, cannot send data");
    }
}