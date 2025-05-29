#include <WiFi.h>
#include <WebServer.h>

const char* ssid = "Vodafone-18E4A0";
const char* pwd = "hZ7qDeqy9Y";


WebServer server(80);

void handleLEDOn() {
  digitalWrite(LED_BUILTIN, LOW);  // Acende LED (inverso em ESP32)
  server.send(200, "text/plain", "LED ON");
}

void handleLEDOff() {
  digitalWrite(LED_BUILTIN, HIGH);
  server.send(200, "text/plain", "LED OFF");
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected: " + WiFi.localIP().toString());

  server.on("/led/on", handleLEDOn);
  server.on("/led/off", handleLEDOff);
  server.begin();
}

void loop() {
  server.handleClient();
}