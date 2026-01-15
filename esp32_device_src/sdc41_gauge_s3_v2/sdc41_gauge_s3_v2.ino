#include <TFT_eSPI.h>
#include <SPI.h>
#include <Wire.h>
#include <SensirionI2cScd4x.h>

// ArduinoBLE
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// =================================================
// SCD4 WARM UP TIME
// =================================================
#define WARMUP_TIME 60

// =================================================
// BATTERY PIN DEFINITIONS
// =================================================
#define BAT_EN  15        // 🔋 Battery / Power enable pin

// =================================================
// LILYGO T-DISPLAY S3 PIN DEFINITIONS
// =================================================
#define TFT_BL   38        // Backlight pin (MUST be enabled)

// I2C pins (physically available on the board)
#define I2C_SDA  43        // IO43
#define I2C_SCL  44        // IO44

// =================================================
// SCREEN
// =================================================
#define SCREEN_W 320
#define SCREEN_H 170

// =================================================
// BLUETOOTH
// =================================================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer *pServer;
BLEService *pService;
BLECharacteristic *pCharacteristic;

// =================================================
// OBJECTS
// =================================================
TFT_eSPI tft = TFT_eSPI();
SensirionI2cScd4x scd4x;

// =================================================
// GAUGE GEOMETRY
// =================================================
int centerX   = SCREEN_W / 2;   // 160
int centerY   = 100;
int radius    = 70;
int thickness = 14;

int lastValue = -1;

// =================================================
// COLOUR LOGIC
// =================================================
uint16_t getColor(int value) {
  if (value < 800)  return tft.color565(0, 255, 0);     // Green
  if (value < 1500) return tft.color565(255, 255, 0);   // Yellow
  return tft.color565(255, 80, 0);                      // Red
}

// =================================================
// STATUS TEXT
// =================================================
String getStatusText(int value) {
  if (value < 800)  return "NORMAL";
  if (value < 1500) return "ELEVATED CO2";
  return "COMBUSTION LEAK!";
}

// =================================================
// DRAW SPLASH SCREEN
// =================================================
void drawSplashScreen() {
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(3);
  tft.drawString("eBlockTest.com", 10, 75);
}

// =================================================
// DRAW SCD41 WARM-UP INFO SCREEN
// =================================================
void drawWarmUpMsg(int timeElapsed) {
  tft.fillRect(100, 40, 200, 60, TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(2);
  tft.drawString("SENSOR WARMING UP", 10, 10);
  tft.drawString("TIME LEFT: " + String(WARMUP_TIME - timeElapsed) + "s", 10, 40);
  tft.setTextSize(1);
  tft.drawString("During this time readings may be unstable", 10, 70);
  tft.drawString("CO2 values can drift or spike", 10, 90);
  tft.drawString("Temperature and Humidity also stabilises", 10, 110);
  tft.drawString("Do not trust readings in the first minute", 10, 130);
}

// =================================================
// DRAW GAUGE
// =================================================
void drawGauge(int value) {

  const int startAngle = -160;
  const int endAngle   = 160;

  if (value != lastValue) {
    tft.fillCircle(centerX, centerY, radius + 6, TFT_BLACK);
  }

  // ----- STATUS BAR -----
  uint16_t statusColor = getColor(value);
  tft.fillRect(0, 0, SCREEN_W, 22, TFT_BLACK);
  tft.setTextDatum(MC_DATUM);
  tft.setTextColor(statusColor, TFT_BLACK);
  tft.setTextSize(2);
  tft.drawString(getStatusText(value), SCREEN_W / 2, 11);

  // ----- BACKGROUND ARC -----
  for (int i = startAngle; i < endAngle; i++) {
    float a = i * DEG_TO_RAD;
    tft.drawLine(
      centerX + cos(a) * (radius - thickness),
      centerY + sin(a) * (radius - thickness),
      centerX + cos(a) * radius,
      centerY + sin(a) * radius,
      tft.color565(60, 60, 60)
    );
  }

  // ----- VALUE ARC -----
  int limit = map(value, 0, 5000, startAngle, endAngle);
  for (int i = startAngle; i < limit; i++) {
    float a = i * DEG_TO_RAD;
    tft.drawLine(
      centerX + cos(a) * (radius - thickness),
      centerY + sin(a) * (radius - thickness),
      centerX + cos(a) * radius,
      centerY + sin(a) * radius,
      statusColor
    );
  }

  // ----- CO2 VALUE -----
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(3);
  tft.drawString(String(value), centerX, centerY - 6);

  tft.setTextSize(1);
  tft.drawString("CO2 ppm", centerX, centerY + 28);

  lastValue = value;
}

class pServerCallbacks: public BLEServerCallbacks {
  void onDisconnect(BLEServer* pServer) {
    Serial.println("Client Disconnected");
    pServer->startAdvertising();
  }
};

// =================================================
// SETUP
// =================================================
void setup() {

  // 🔋 BATTERY ENABLE (IMPORTANT)
  pinMode(BAT_EN, OUTPUT);
  digitalWrite(BAT_EN, HIGH);

  // ----- BACKLIGHT -----
  pinMode(TFT_BL, OUTPUT);
  digitalWrite(TFT_BL, HIGH);

  // ----- SERIAL -----
  Serial.begin(115200);
  delay(1000);
  Serial.println("BOOT OK");

  // ----- DISPLAY -----
  tft.init();
  tft.setRotation(1);
  tft.fillScreen(TFT_BLACK);

  // ----- SPLASH SCREEN -----
  drawSplashScreen();
  delay(5000);
  tft.fillScreen(TFT_BLACK);
  drawWarmUpMsg(0);

  // ----- I2C -----
  Wire.begin(I2C_SDA, I2C_SCL);
  Serial.println("I2C started on SDA=43, SCL=44");

  // ----- SENSOR -----
  scd4x.begin(Wire, 0x62);
  scd4x.stopPeriodicMeasurement();
  delay(50);
  scd4x.startPeriodicMeasurement();

  Serial.println("SCD4x warming up...");

  // ----- SCD41 WARM UP -----
  for (int i = 0; i < WARMUP_TIME; i++) {
    delay(1000);
    drawWarmUpMsg(i);
  }

  // ----- BLUETOOTH -----
  BLEDevice::init("Radiator King BLE");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new pServerCallbacks()); ///////////////////
  pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE
  );

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  tft.fillScreen(TFT_BLACK);
}

// =================================================
// LOOP
// =================================================
void loop() {

  static int displayValue = 400;

  uint16_t co2 = 0;
  float temperature = 0;
  float humidity = 0;

  uint16_t error = scd4x.readMeasurement(co2, temperature, humidity);

  // No new data OR warming up
  if (error == 527 || co2 == 0) {
    drawGauge(displayValue);
    delay(500);
    return;
  }

  // Sensor error
  if (error) {
    Serial.print("Sensor error: ");
    Serial.println(error);
    delay(500);
    return;
  }

  // Valid data
  displayValue = co2;

  Serial.print("CO2: ");
  Serial.print(co2);
  Serial.print(" ppm | Temp: ");
  Serial.print(temperature);
  Serial.print(" C | Hum: ");
  Serial.println(humidity);

  drawGauge(displayValue);
  delay(300);

  // Data received via BLE
  std::string value = pCharacteristic->getValue();

  // Display BLE in Serial
  if(strcmp(value.c_str(), "") != 0)
  {
    Serial.println(value.c_str());

    String message = String(displayValue);

    pCharacteristic->setValue(message.c_str());
    pCharacteristic->notify();
  }

  pCharacteristic->setValue("");
  delay(2000);

}
