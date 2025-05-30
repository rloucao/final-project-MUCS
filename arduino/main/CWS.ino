#include <WiFi.h>
#include <WebServer.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

const char* ssid = "Vodafone-18E4A0";
const char* pwd = "hZ7qDeqy9Y";


WebServer server(80);
IPAddress serverIP;
const char *host = "https://final-project-mucs.onrender.com";  
WiFiClientSecure client;


void sendSensorData(String data) {
  HTTPClient http;
  String serverPath = "https://final-project-mucs.onrender.com/send_sensor_data?data=" + data;

  http.begin(serverPath);
  http.addHeader("Content-Type", "application/json");

  int httpResponseCode = http.POST("");  

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Server response:");
    Serial.println(response);  // This should print {"success": true}
  } else {
    Serial.print("Error on sending POST: ");
    Serial.println(httpResponseCode);
  }

  http.end();
}



void sendInformationToServer(String data){
if(client.connect(host, 443)){
    String url = String("https://") + host + "/send_sensor_data";
    String postData = "data=" + data;

    client.print(String("POST ") + endpoint + " HTTP/1.1\r\n" +
                      "Host: " + host + "\r\n" +
                      "Connection: close\r\n\r\n");


    client.stop();
    }
}


void setup(){
    Serial.begin(115200);

    WiFi.begin(ssid, pwd);
    while(WiFi.status() != WL_CONNECTED){
        delay(500);
        Serial.print(".");
    }

    Serial.println("\nWiFi connected: " + WiFi.localIP().toString());

    // server.on("/send_sensor_data", HTTP_POST, []() {
    //     String data = server.arg("data");
    //     sendInformationToServer(data);
    //     server.send(200, "text/plain", "Data sent to server: " + data);
    // });
    sendSensorData("Hello from ESP32!");

}

void loop(){
    //server.handleClient();
}