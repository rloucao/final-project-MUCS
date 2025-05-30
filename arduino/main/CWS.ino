#include <WiFi.h>
#include <WebServer.h>
#include <WiFiClientSecure.h>

const char* ssid = "Vodafone-18E4A0";
const char* pwd = "hZ7qDeqy9Y";


Webserver server(81);
IPAddress serverIP;
const char *host = "https://final-project-mucs.onrender.com";  
WiFiClientSecure client;

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
    sendInformationToServer("Hello from ESP32!");

}

void loop(){
    server.handleClient();
}