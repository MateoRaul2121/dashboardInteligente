#include <SoftwareSerial.h>
#include <Servo.h>
#include "DHT.h"

#define DHTPIN 7     // Pin donde está conectado el DHT11
#define DHTTYPE DHT11   // Definir el tipo de sensor DHT11

DHT dht(DHTPIN, DHTTYPE);

SoftwareSerial BTSerial(2, 3); // RX, TX

const int redPin = 9;
const int greenPin = 10;
const int bluePin = 11;
const int servoPin = 6; // Pin del servomotor

Servo doorServo; // Crear un objeto de la clase Servo

int currentRed = 255;
int currentGreen = 255;
int currentBlue = 255;
float currentIntensity = 1.0;

unsigned long previousMillis = 0;
const long interval = 5000; // Intervalo para enviar datos (5 segundos)

void setup() {
  pinMode(redPin, OUTPUT);
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin, OUTPUT);

  BTSerial.begin(9600);
  Serial.begin(9600); // For debugging

  dht.begin(); // Inicializar el sensor DHT

  // Inicializar el servomotor
  doorServo.attach(servoPin);

  // Apagar el LED al inicio
  analogWrite(redPin, 255);
  analogWrite(greenPin, 255);
  analogWrite(bluePin, 255);

  // Cerrar la puerta al inicio
  doorServo.write(0);
}

void loop() {
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    sendSensorData();
  }

  if (BTSerial.available() > 0) {
    String receivedString = BTSerial.readStringUntil('\n');
    Serial.println(receivedString); // For debugging
    if (receivedString.startsWith("T")) {
      int temperatureValue = receivedString.substring(1).toInt();
      setTemperature(temperatureValue);
      Serial.println("Temperatura ajustada");
    } else if (receivedString.startsWith("I")) {
      float intensityValue = receivedString.substring(1).toFloat() / 100.0;
      setIntensity(intensityValue);
      Serial.println("Intensidad ajustada");
    } else if (receivedString.startsWith("C")) {
      int commaIndex1 = receivedString.indexOf(',');
      int commaIndex2 = receivedString.lastIndexOf(',');
      int redValue = receivedString.substring(1, commaIndex1).toInt();
      int greenValue = receivedString.substring(commaIndex1 + 1, commaIndex2).toInt();
      int blueValue = receivedString.substring(commaIndex2 + 1).toInt();
      setColor(redValue, greenValue, blueValue);
      Serial.println("Color ajustado");
    } else if (receivedString == "ON") {
      setColor(255, 255, 255); // Blanco normal (valores altos para encender)
      Serial.println("LED Encendido");
    } else if (receivedString == "OFF") {
      setColor(0, 0, 0); // Apagado (valores bajos)
      Serial.println("LED Apagado");
    } else if (receivedString == "DOOR_OPEN") {
      doorServo.write(90); // Abrir la puerta
      Serial.println("Puerta abierta");
    } else if (receivedString == "DOOR_CLOSE") {
      doorServo.write(0); // Cerrar la puerta
      Serial.println("Puerta cerrada");
    } else if (receivedString == "GET_DATA") {
      sendSensorData();
    }
  }
}

void sendSensorData() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read from DHT sensor!");
    BTSerial.println("Failed to read from DHT sensor!");
  } else {
    String data = "T:" + String(temperature) + ",H:" + String(humidity);
    BTSerial.println(data);
    Serial.println(data); // For debugging
  }
}

void setTemperature(int temperature) {
  currentRed = map(temperature, 0, 100, 0, 255);
  currentGreen = map(temperature, 0, 100, 90, 255); // Ajustar según sea necesario
  currentBlue = map(temperature, 0, 100, 255, 0);
  applyIntensity();
}

void setIntensity(float intensity) {
  currentIntensity = intensity;
  applyIntensity();
}

void applyIntensity() {
  analogWrite(redPin, 255 - (currentRed * currentIntensity));
  analogWrite(greenPin, 255 - (currentGreen * currentIntensity));
  analogWrite(bluePin, 255 - (currentBlue * currentIntensity));
}

void setColor(int red, int green, int blue) {
  currentRed = red;
  currentGreen = green;
  currentBlue = blue;
  applyIntensity();
}
