#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "HT_SSD1306Wire.h"
#include <WiFiClientSecure.h>

#define RF_FREQUENCY 868000000  // Frequência LoRa para a Europa
#define TX_OUTPUT_POWER 10      // dBm
#define LORA_BANDWIDTH 0        // 125 kHz
#define LORA_SPREADING_FACTOR 7
#define LORA_CODINGRATE 1  // 4/5
#define LORA_PREAMBLE_LENGTH 8
#define LORA_SYMBOL_TIMEOUT 5
#define LORA_FIX_LENGTH_PAYLOAD_ON false
#define LORA_IQ_INVERSION_ON false



//Wifi ssid and password (Put your WiFi credentials here please :D )
char *ssid = "Vodafone-18E4A0.5";
char *pwd = "hZ7qDeqy9Y";

IPAddress serverIP;

//TODO - Deploy server
const char *server_host = "http://127.0.0.1";
const int server_port = 5000;


//TODO - Deploy mobile app
const char *mobile_host = "toBeDefined";
const int mobile_port = 5001;

WiFiClientSecure server_client;
WiFiClientSecure mobile_client;


SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

int counter = 0;
bool txDoneFlag = false;

/**
 * @brief Connect to server
 * 
 */
void connect_to_server() {
  if (!server_client.connect(server_host, server_port)) {
    Serial.println("Failed to connect to server");
    return;
  }
  Serial.println("Connected to server");
}

/**
 * @brief Connect to client
 * 
 */
void connect_to_client(){
  if (!mobile_client.connect(mobile_host, mobile_port)) {
    Serial.println("Failed to connect to client");
    return;
  }
  Serial.println("Connected to client");
}


/**
 * @brief Set up WiFi connection
 * Connect to server
 * Connect to mobile app
 *  
 */
void setup() {
   Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE);  // Inicializa Heltec

  // Inicializa o display
  factory_display.init();
  factory_display.clear();
  factory_display.drawString(20, 30, "LoRa Sender");
  factory_display.display();
  delay(1000);

  // Inicializa Serial
  Serial.begin(115200);
  delay(100);

  // Regista callbacks de rádio
  RadioEvents.TxDone = OnTxDone;
  Radio.Init(&RadioEvents);

  // Configura o canal
  Radio.SetChannel(RF_FREQUENCY);

  // Configura transmissão LoRa
  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, LORA_BANDWIDTH,
                    LORA_SPREADING_FACTOR, LORA_CODINGRATE,
                    LORA_PREAMBLE_LENGTH, LORA_FIX_LENGTH_PAYLOAD_ON,
                    true, 0, 0, LORA_IQ_INVERSION_ON, 3000);


  connect_to_server();
  connect_to_client();

  Serial.println("LoRa initialized");
}


/**
 * @brief 
 */
void loop() {
  //webSocket.loop();
}
