#include "Arduino.h"
#include "LoRaWan_APP.h"
#include "WiFi.h"
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



const char* ssid = "Vodafone-18E4A0";
const char* pwd = "hZ7qDeqy9Y";


IPAddress serverIP;

const char *server_hostname = "final-project-mucs.onrender.com"; // Changed from server_host with https://
const int https_server_port = 443; // Standard HTTPS port
// const int server_port = 5000; // This is the internal port on Render, not for client connection


const char *mobile_host = "toBeDefined";
const int mobile_port = 5001;

WiFiClientSecure server_client;
WiFiClientSecure mobile_client;


SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

int counter = 0;
bool txDoneFlag = false;


void send_data(String data){

}


/**
 * @brief Connect to server
 * 
 */
void connect_to_server() {
 
}

/**
 * @brief Connect to client
 * 
 */
void connect_to_client(){
 
}


/**
 * @brief Connects to a WebSocket to communicate with the mobile app
 * 
 */
void connect_to_websocket(){

}

/**
 * @brief Receives data from the WebSocket
 * 
 */
String receive_data_from_websocket() {

}

/**
 * @brief Sends data to the WebSocket
 * 
 */

void send_data_to_websocket(String data) {
  // Implement WebSocket send logic here
  
}


void OnTxDone(void)
{
  Serial.print("TX done......");
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
  factory_display.drawString(20, 30, "Initializing...");
  factory_display.display();
  delay(1000);

  // Inicializa Serial
  Serial.begin(115200);
  while (!Serial); // Wait for serial to connect (for some boards)
  delay(100);
  Serial.println("Serial Initialized");

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


  factory_display.clear();
  factory_display.drawString(0, 15, "Connecting to WiFi...");
  factory_display.display();
  Serial.println("Disconnecting WiFi first...");
  WiFi.disconnect(true);
  delay(1000);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  Serial.print("Attempting to connect to SSID: ");
  Serial.println(ssid);
  WiFi.begin(ssid, pwd);

  int wifi_retries = 0;
  const int max_wifi_retries = 30; // Try for 15 seconds (30 * 0.5s)
  while (WiFi.status() != WL_CONNECTED && wifi_retries < max_wifi_retries) {
    delay(500);
    Serial.print(".");
    factory_display.clear();
    factory_display.drawString(0, 15, "Connecting WiFi (" + String(wifi_retries) + ")");
    factory_display.display();
    wifi_retries++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED){
    factory_display.clear();
    factory_display.drawString(0, 0, "WiFi Connected!");
    factory_display.drawString(0, 15, "IP:");
    factory_display.drawString(0, 30, WiFi.localIP().toString());
    factory_display.display();
    Serial.println("WiFi connected.");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    // Set CA Certificate for WiFiClientSecure
    // This is crucial for HTTPS connections to verify the server's identity.
    Serial.println("Setting CA Root certificate for server_client...");
    server_client.setCACert(server_root_ca);
    // For some ESP32 cores or if issues persist, you might need to explore:
    // server_client.setInsecure(); // Bypasses certificate validation (UNSAFE for production)
    // or other specific methods like setTrustAnchors for your ESP32 board's SSL library.

    // Attempt to connect to the server (this function also uses the global server_client)
    connect_to_server(); 

  } else {
    factory_display.clear();
    factory_display.drawString(0, 15, "WiFi Connection Failed");
    factory_display.display();
    Serial.println("WiFi connection failed after " + String(max_wifi_retries) + " retries.");
    // Cannot proceed to server connection if WiFi is down
  }

  delay(1000); // General delay before LoRa init message.
  
  //connect_to_client(); // Still commented out

  Serial.println("LoRa and network setup phase complete.");
}


/**
 * @brief Function to excute in a loop
 */
void loop() {
  send_data("penis"); 
  delay(1000);
  
}