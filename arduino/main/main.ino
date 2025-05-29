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



//Wifi ssid and password (Put your WiFi credentials here please :D )
// char *ssid = "Vodafone-18E4A0.5";
// char *pwd = "hZ7qDeqy9Y";

char *ssid = "Rodrigo's iPhone";
char *pwd = "20euroshora";

IPAddress serverIP;

//TODO - Deploy server
const char *server_hostname = "final-project-mucs.onrender.com"; // Changed from server_host with https://
const int https_server_port = 443; // Standard HTTPS port
// const int server_port = 5000; // This is the internal port on Render, not for client connection


//TODO - Deploy mobile app
const char *mobile_host = "toBeDefined";
const int mobile_port = 5001;

WiFiClientSecure server_client;
WiFiClientSecure mobile_client;


SSD1306Wire factory_display(0x3c, 500000, SDA_OLED, SCL_OLED, GEOMETRY_128_64, RST_OLED);

static RadioEvents_t RadioEvents;

int counter = 0;
bool txDoneFlag = false;

// ISRG Root X1 CA Certificate for letsencrypt.org / onrender.com
const char* server_root_ca = \\
"-----BEGIN CERTIFICATE-----\\n" \\
"MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw\\n" \\
"TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh\\n" \\
"cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4\\n" \\
"WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu\\n" \\
"ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY\\n" \\
"MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc\\n" \\
"h77ct984kIxuPOZXoHj3AntSoMixpvz4UbEYMOcollectionViewV180uGFGqw\\n" \\
"qPgcxQTTUav1s9smSk3AAAUIxHbkZ8jdk2MhhW6jEMsIP3ClLgmZ2YTRWXFDRzS\\n" \\
"S4E1LBB659iYcNHoMu2jXxtxUTKHEqLtaDQbfSW1SPc3dNBVY0jesDIEA0W42XR\\n" \\
"XegbAWV30JpDBhpKflB66FfETSoF53rowwfwgwtrpkDRLAcfxHcY2RFloLoCD1+\\n" \\
"Gxx3i0s7CO6DRo2hOq9N8gOAABGNLdLVeloPMU82fEVzSMq1zDZj+GgH8b8xBYu\\n" \\
"XgvGxPDBH23IkKyKqKWAYhTcwWM0PYcRk13WWJ/CWSAKqyGM3t2OmYL2vAi1G+z\\n" \\
"kSqGSQm/ngBLsJzUqCo5qXcF3arXGNvwPCOL0dnP2EDOWhG3S6uP2c1CV1q601n\\n" \\
"R7g0G6C9gAW2PoeG3A/sLH7pcSKLgJMuGQVwP1tY+m+nS5dY+2V93vG4424gV1R\\n" \\
"Ew68qDbFv2eQqgV+kxBNIY7p3AwEEAwIDIDQwGFYXG+xG2k3xLKF9aL0g2PFrlY\\n" \\
"1E7LpFyLTwgr7L21yHzP1BPAfRdeLpAKtH9W9fVPft4qKz1PMd7mKLLAdGmofnlD\\n" \\
"z9Wz2Y3jV2DsH3wGgULKzG2VAnz9TPzHeYj4o+30R25sD+EwGzQG/gQCCoGUV/gL\\n" \\
"e+Gg4H250gBkcTf33RPAkG5DNgD0zSkq6+jGfM3bf9xAfXSd9hAmN1uF5jIfxUU\\n" \\
"7P2hV0fA0fmcXUf9Rk2d1BvKq4w2F3hG2B/7AC4zYf4WAWbXn2hzM2LKeX0+gRg\\n" \\
"dIA0i0xQ1qGDqXhY2ePR7fchKDrSH+4XvQcgY/x000PNot/CjAL0JvLiWjGVEsM\\n" \\
"4y9kpsxY1E/FzCVg+/c0gQ1JZZ00zJ4iA5g9PcgEahvR4w17wD5/z6j0N9B9K07\\n" \\
"gYoff5u0R0FLkLdacq02GXHjGg4K0zZg4gGvLgM87xQ0uURSK3xZfyP6xGdQLM08\\n" \\
"HjHhLzL5Yt4Eewy0p62mZHAq3qMu0uupI8g+nAWvVhwZ0tV44W2LpygTjgZ7kjd\\n" \\
"dGO2m44E7xYvS5Yt4EHPHqGqcYvY57Q2U/S5MGe100jC0YN4ReY7fSg0pUHFZhp\\n" \\
"Our52g4BfMRKjP4kY+0SjT2gN3FyzYOhfW027aRe6zDEdFh233k8jY7Yj9pZf6D\\n" \\
"E6oXCi4hDVghyXfCaUVg6lJ7o1W2Y0iLdK91dwf64Gg3yMfGqR055fWggrXXg5K\\n" \\
"oI9h2uS1kDOuLZIXyv4LpPqaB7zWIIOdVRzihsLdYx2FGTCAE+G0wJ9LqB1lTId\\n" \\
"kX+7gDwi4qj8Hyk32WYE5uSffayCAHhP6xhAVmHjWENglr28bFvMPk2NhI/uPZa\\n" \\
"yv6w04XxrjQ4HlH4GjTFPzKz2T/57fDOEIwIqXY+rN2v8hA9nL22epk2bbES5n2\\n" \\
"2K/mTwTJ2aB1RHIxS6nDOuB3a4z12gB2Z8jLprM1gzLRMdxOBTL+vC0pwxzchNm\\n" \\
"W/YfPE/G5sY7f9PZmX9/z2ztgrPDsKDAuv9WVw0Jlyb1DJrZdpPMpLMcgI38nXG\\n" \\
"B85d/R4/Wv33G2sRCtbGrcqyzYPA/k9Wv141E6oLRgP2p0f++022OftwABzURtVE\\n" \\
"3lB1/sxwRh0Xy2zR/8/CcCYz00Tgq9sSDBjL4JzYQRJzJq+LDsXOz6hHj0YL74d\\n" \\
"J0VlE2mOugUQYV8Yl3gLpqfW+fxqAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAP\\n" \\
"BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnIWb10SzOqCFhLNaX0z6qPUDAN\\n" \\
"BgkqhGZIhvcNAQELBQADggIBAGqXJ32N2y0Q6SIB577aaAoKxwbb0ctqRjGLsF1L\\n" \\
"WjP8ldz7Gnwky7R2V_FCrpV7YBAg590aK94z2zKZpL0qL3n4cT6Y_vQG5_Y+u2zJ\\n" \\
"1T22NDxXeyG1iEZC7yXk3dM7eTWnaM3wP2SITYgXyPEBE65TrPy3L3zMmkUQDjnJ\\n" \\
"tGjbtHM0qX3Y3R82FknjF3D2z9c4V38u1x7uC3VqIWhcUMWqjNqw2fTuBfBqJDr2\\n" \\
"H4x6bRqGgM7fJ6zcgqh9HHKNWB5kcK9wRzGtJFy2cbus0VRwB7KNyEDPCErIUPp6\\n" \\
"iXh2OEIaKPSH9Ld7NlPReYf2cOvq2OwaT6WlW2kZ0lZXSOxLo27NQDq0OQ2nPE5b\\n" \\
"MhLqYRIlPmqS3rS6cGjX2xEZ2i+9VUJylmO9ZzYI1A1Q3tNMhVjR4hGZ4X98Aynq\\n" \\
"CGL1u7zYj5Y7UlHk1r0tTXsTSiRWMKLSKF43Xm34p2pAK24+JkOflETTIYPxY4j7\\n" \\
"iIqQkUbKqKSAK2h6gGNfQs901WnCgYVhbngNTOpoRVEPpgl4uIaqkP0YFXTL3uUv\\n" \\
"4r0jyT23yZk7z46a4hCHVVMguZz52aGa6U733c702GgL0QZNXArph07LTe2Z4BhQ\\n" \\
"vCBYGlNI61t3WhaBvR96PQ2ZJvjXl53FYSItD2j3hGptxtuP0nFwHcuP49ZvpP7M\\n" \\
"5qvAS546y3s+Qk7nOwI=\\n" \\
"-----END CERTIFICATE-----\\n";

void send_data(String data){

  if(server_client.connect(server_hostname, https_server_port)){ // Use hostname and HTTPS port
    Serial.println("Successfully connected to server (HTTPS)");
    factory_display.clear();
    factory_display.drawString(0, 0, "HTTPS Conn OK");
    factory_display.display();
    delay(200); // Short delay for display

    String request_path = "/receive_data?data=" + data;
    String request = String("GET ") + request_path + " HTTP/1.1\r\n" +
                     "Host: " + server_hostname + "\r\n" +
                     "Connection: close\r\n\r\n";

    Serial.print("Sending request: ");
    Serial.println(request);
    server_client.print(request);

    // Optional: Add a small delay to allow data to be sent
    //

    // Optional: Read server response for debugging
    // unsigned long timeout = millis();
    while (server_client.available() == 0) {
      if (millis() - timeout > 5000) { // 5 seconds timeout
        Serial.println(">>> Client Timeout waiting for response!");
        factory_display.drawString(0, 15, "Resp Timeout");
        factory_display.display();
        server_client.stop();
        return;
      }
    }
    Serial.println("Server response:");
    while(server_client.available()){
      String line = server_client.readStringUntil('\r');
      Serial.print(line);
    }
    Serial.println();
    factory_display.drawString(0, 15, "Resp Recvd");
    factory_display.display();
    delay(200);

    server_client.stop();
    Serial.println("Connection closed by client.");

    factory_display.clear(); // Clear previous messages
    factory_display.drawString(0, 15, "Data Sent to Server!");
    factory_display.display();
    delay(1000);
  } else {
    Serial.println("Failed to connect to server (HTTPS)");
    factory_display.clear();
    factory_display.drawString(0, 0, "HTTPS Conn Fail");
    factory_display.drawString(0, 15, server_hostname); // Display hostname
    factory_display.drawString(0, 30, String(https_server_port)); // Display port
    factory_display.display();
    delay(3000); // Longer delay to see the error
  }
}


/**
 * @brief Connect to server
 * 
 */
void connect_to_server() {
  // Use the correct hostname and HTTPS port
  if (!server_client.connect(server_hostname, https_server_port)) {
    Serial.println("Failed to connect to server (from connect_to_server func)");
    factory_display.clear();
  factory_display.drawString(20, 30, "Failed to connect to server");
  factory_display.display();

  delay(5000);
  
    return;
  }
  Serial.println("Connected to server (from connect_to_server func)");

   factory_display.clear();
  factory_display.drawString(20, 30, "Connected to server");
  factory_display.display();
  // server_client.stop(); // Consider if you want to keep connection open or close after check
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
  String data = "";
  // Implement WebSocket receive logic here
  return data;
}

/**
 * @brief Sends data to the WebSocket
 * 
 */

void send_data_to_websocket(String data) {
  // Implement WebSocket send logic here
  Serial.println("Sending data to WebSocket: " + data);
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