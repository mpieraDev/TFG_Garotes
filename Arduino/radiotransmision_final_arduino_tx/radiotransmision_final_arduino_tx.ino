#include <Arduino.h>
#include <printf.h>
#include <avr/dtostrf.h>
#include <SPI.h>
#include <RF24.h>
#include <ArduinoBLE.h>

#define NRF24_BUFSIZE 32    // Max. is 32 bytes
#define NRF24_CHANNEL 0x00  // 76
#define CRC16_POLY 0x1021   // Polynomial for CRC-16-CCITT
#define CRC16_INIT 0xFFFF   // Initial CRC value

//TIMEOUTS
#define AWAIT_TIMEOUT 2000ULL             // Handshake ACK reception.
#define CONNECTION_LOST_TIMEOUT 5000ULL  // Conection lost timeout
#define NOTIFY_INTERVAL 2000ULL
#define AWAIT_PKT_TIMEOUT 10ULL  // regular pkts
#define CALCULATE_INTERVAL 10000ULL

// Requests
// PUT REQUEST CMD'S HERE
#define HS_CMD 0xBA
#define HSACK_CMD 0x55
#define RQRS_CMD 0xBB
#define RQRSACK_CMD 0x11
#define CH_CMD 0xAA
#define CHACK_CMD 0x13
#define TC_CMD 0x1A
#define TCACK_CMD 0x3C

// BLE
#define SEND_SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define SEND_SERVICE_UUID_2 "92435095-cf7b-4b28-a1be-79f968e45ced"
#define RECIVE_SERVICE_UUID "723b1765-17dd-40c5-9e0d-a682174f7362"

#define BATTERYLIFE_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define PACKETLOSS_CHARACTERISTIC_UUID "02a486bf-cb21-4e5b-8568-d0c6396ee39a"
#define SPEED_CHARACTERISTIC_UUID "16c41f0f-15b3-4de9-a3de-f6ad2c9bd33f"
#define GPSERROR_CHARACTERISTIC_UUID "e4265390-1c58-4104-b343-b709c62ea0c5"
#define DEPTH_CHARACTERISTIC_UUID "52c6e51d-5039-4d3e-913b-168e4aab9aa5"
#define LATITUDE_CHARACTERISTIC_UUID "06edbb9a-8a14-464a-a45c-5074faa25500"
#define LONGITUDE_CHARACTERISTIC_UUID "d3b0e284-ed32-4d7c-a20e-c99413701d62"
#define ROTATION_CHARACTERISTIC_UUID "d70e084e-939a-48a7-ba7c-7e3ca1736553"
#define DATARATE_CHARACTERISTIC_UUID "8394fae8-6ab5-4a6a-9e91-7d3852a59e36"
#define ONCHANNELCHANGEDERROR_CHARACTERISTIC_UUID "4bd3198c-710a-405b-87c6-73e406c593fa"
#define DATAGATHERING_CHARACTERISTIC_UUID "212855ff-df2b-4658-b49c-c26a1af73c2e"
#define CHANNEL_CHARACTERISTIC_UUID "9d469b60-3923-4d6d-bf05-4e7eb15aaf97"
#define CONNECTION_CARACTERISTIC_UUID "666dc20d-e9d6-4cca-9f89-69706e97981e"
#define RM_CHARACTERISTIC_UUID "b345013c-78cd-44ff-ae59-054bc66cda1b"
#define LM_CHARACTERISTIC_UUID "a197ac09-efb1-4e6d-b378-3a04760aa767"

BLEService sendService(SEND_SERVICE_UUID);
BLEService sendService_2(SEND_SERVICE_UUID_2);
BLEService reciveService(RECIVE_SERVICE_UUID);

// BLE Characteristics - IMPORTANT: Adjust valueSize (third argument) based on your data type
// Common sizes: 1 byte for bool/byte, 2 bytes for int, 4 bytes for float/long, 20+ bytes for strings
BLECharacteristic depthCharacteristic(DEPTH_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 4);              // Example: 4 bytes for a float or long
BLECharacteristic batteryLifeCharacteristic(BATTERYLIFE_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 4);  // Example: 4 bytes for a float or int percentage
BLECharacteristic packetLossCharacteristic(PACKETLOSS_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 4);    // Example: 2 bytes for an int
BLECharacteristic speedCharacteristic(SPEED_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 4);              // Example: 4 bytes for a float
BLECharacteristic gpsErrorCharacteristic(GPSERROR_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 20);       // Example: 20 bytes for a string/char array

BLECharacteristic latitudeCharacteristic(LATITUDE_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 20);                             // Example: 4 bytes for a float
BLECharacteristic longitudeCharacteristic(LONGITUDE_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 20);                           // Example: 4 bytes for a float
BLECharacteristic rotationCharacteristic(ROTATION_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 4);                             // Example: 4 bytes for a float or array of floats
BLECharacteristic datarateCharacteristic(DATARATE_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 4);                             // Example: 2 bytes for an int
BLECharacteristic OnChannelChangedErrorCharacteristic(ONCHANNELCHANGEDERROR_CHARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 30);  // Example: 30 bytes for error messages
BLECharacteristic connectionCharacteristic(CONNECTION_CARACTERISTIC_UUID, BLERead | BLEWrite | BLENotify, 30);                          // Example: 1 byte for boolean status

BLECharacteristic dataGatheringCharacteristic(DATAGATHERING_CHARACTERISTIC_UUID, BLERead | BLEWriteWithoutResponse, 20);  // Example: 20 bytes for aggregated data
BLECharacteristic channelCharacteristic(CHANNEL_CHARACTERISTIC_UUID, BLERead | BLEWriteWithoutResponse, 4);               // Example: 1 byte for channel number
BLECharacteristic LMCharacteristic(LM_CHARACTERISTIC_UUID, BLERead | BLEWriteWithoutResponse, 4);                         // Example: 4 bytes for a float/int
BLECharacteristic RMCharacteristic(RM_CHARACTERISTIC_UUID, BLERead | BLEWriteWithoutResponse, 4);                         // Example: 4 bytes for a float/int

// BLE END

typedef enum tx_state_t {
  TX_SEND_HANDSHAKE,
  TX_AWAIT_HANDSHAKE_ACK,
  TX_REQUEST_PKT,
  TX_AWAIT_PKT,
  TX_CHANNEL_HOOP_ADVERTISEMENT,
  TX_AWAIT_CHANNEL_HOOP_ACK,
  TX_TEST_CHANNEL_HSK,
  TX_TEST_CHANNEL_ACK,
  TX_REQUEST_ROTATION,
  TX_ERROR,
} tx_state_t;

/* Endpoint pinout settings */
#define CE_PIN 9    // CE pin for NRF24L01 (LNA enable)
#define CSN_PIN 10  // CSN pin for NRF24L01 (SPI chip select)
//#define SCK_PIN D8          // CSN pin for NRF24L01 (SPI chip select)
//#define MISO_PIN D9          // CSN pin for NRF24L01 (SPI chip select)
//#define MOSI_PIN D10          // CSN pin for NRF24L01 (SPI chip select)

//DATA VARIABLES
float depth = 0;
float lat = 41.370258;
float lon = 2.190636;
uint16_t rotation = 0;
float gps_error = 3.48588;
float speed = 0;
uint8_t battery_life = 0;
float datarate = 0;
int packet_loss = 0;  // IMPLEMEMENTAR CALCULO DE PACKET LOSS
float inputLM = 0;
float inputRM = 0;

bool advertise_connection_loss = true;
int isDataGatheringEnabled = false;
uint8_t channel = 0;
uint8_t base_channel = 0;
int pkt_count = 0;
int pkts_asked = 1;

// rf24 config
/* Global control variables: */
RF24 radio(CE_PIN, CSN_PIN);
uint8_t rf_buf[NRF24_BUFSIZE + 1];  // +1 for null-terminator
uint8_t addr[][6] = {
  "00001",  // Endpoint ESP32
  "00002",  // Endpoint Arduino Nano
};
rf24_pa_dbm_e pa_setting = RF24_PA_MIN;
rf24_datarate_e dr_setting = RF24_250KBPS;
rf24_crclength_e hw_crc = RF24_CRC_DISABLED;
bool auto_ack_enabled = false;

uint32_t connection_lost_timestamp = 0;
uint32_t pkt_timeout_timestamp = 0;
uint32_t channel_timeout_timestap = 0;
uint32_t notify_timestap = 0;
uint32_t calculate_timestap = 1000;

tx_state_t tx_state = TX_SEND_HANDSHAKE;
bool didChannelChange = false;

bool is_tx_endpoint = true;
bool is_rx_endpoint = false;
uint8_t addr_selector_txpipe = 1;
uint8_t addr_selector_rxpipe = 0;

// Function prototypes:
// NUEVAS
// BLE server
void configureBleServer();
//tx
void readDataGatheringState();                               // falta implementar
void makeHandshakePkt(uint8_t *buf, const uint8_t len);      // falta implementar
bool decodeHandshakeACK(uint8_t *buf, const uint8_t len);    // falta implementar
void bleServerNotifyConnectionEstablished();                 // falta implementar
void makeRequestPkt(uint8_t *buf, const uint8_t len);        // falta implementar
bool decodeRequestedPkt(uint8_t *buf, const uint8_t len);    // falta implementar
void makeChannelHoopPkt(uint8_t *buf, const uint8_t len);    // falta implementar
bool decodeChannelHoopAck(uint8_t *buf, const uint8_t len);  // falta implementar
void ChangeChannel();                                        // falta implementar
void makeTestChannelPkt(uint8_t *buf, const uint8_t len);    // falta implementar
void ResetChannel();                                         // falta implementar
bool decodeTestChannelAck(uint8_t *buf, const uint8_t len);  // falta implementar
void isConnectionLossTX();                                   // falta implementar
void calculateDataRate();                                    // falta implementar
void calculatePktLoss();                                     // falta implementar
void awaitChannelHoop();                                     // falta implementar
void bleServerNoitfy();                                      // falta implementar
void pktsAskedControl();
void substractPktCount();
void addPktCount();
// ANTIGUAS
void resetRadio(bool power_reset = true);
uint16_t computeCRC16(const uint8_t *data, size_t length);
void initializeRadio();
void checkEngineInputs();
//

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  delay(500);
  printf_begin();
  randomSeed(analogRead(A0));
  delay(1000);
  initializeRadio();
  delay(1000);
  configureBleServer();
  delay(1000);
}

void loop() {

  BLE.poll();
  onDataGatheringCharacteristicWrite();

  switch (tx_state) {

    case TX_SEND_HANDSHAKE:
      Serial.println(F("TX_SEND_HANDSHAKE"));
     //Serial.println(radio.getChannel());

      radio.flush_tx();
      makeHandshakePkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        tx_state = TX_AWAIT_HANDSHAKE_ACK;
        radio.startListening();
        pkt_timeout_timestamp = millis();
      } else {
        tx_state = TX_ERROR;
      }

      break;

    case TX_AWAIT_HANDSHAKE_ACK:

      if (radio.available()) {
        Serial.println(F("cmd recived"));
        radio.read(rf_buf, NRF24_BUFSIZE);
        if (decodeHandshakeACK(rf_buf, NRF24_BUFSIZE)) {
          tx_state = TX_REQUEST_PKT;
          connection_lost_timestamp = millis();
          radio.stopListening();
          bleServerNotifyConnectionEstablished();
        } else {
          tx_state = TX_SEND_HANDSHAKE;
          radio.stopListening();
        }
      } else {
        if (millis() - pkt_timeout_timestamp > AWAIT_TIMEOUT) {
          tx_state = TX_SEND_HANDSHAKE;
          radio.stopListening();
          Serial.println(F("TX_AWAIT_HANDSHAKE_TIMEOUT"));
        }
      }

      break;

    case TX_REQUEST_PKT:
      Serial.println(F("TX_REQUEST_PKT"));

      radio.flush_tx();
      makeRequestPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        tx_state = TX_AWAIT_PKT;
        radio.startListening();
        pkt_timeout_timestamp = millis();
        pktsAskedControl();
      } else {
        tx_state = TX_ERROR;
      }

      break;

    case TX_AWAIT_PKT:

      if (radio.available()) {
        radio.read(rf_buf, NRF24_BUFSIZE);
        if (decodeRequestedPkt(rf_buf, NRF24_BUFSIZE)) {
          Serial.println(F("DECODE REQUEST SUCCESFUL"));
          tx_state = TX_REQUEST_PKT;
          connection_lost_timestamp = millis();
          radio.stopListening();
          addPktCount();
        } else {
          Serial.println(F("DECODE REQUEST FAILED"));
          tx_state = TX_REQUEST_PKT;
          radio.stopListening();
          substractPktCount();
        }
      } else {
        if (millis() - pkt_timeout_timestamp > AWAIT_PKT_TIMEOUT) {
          tx_state = TX_REQUEST_PKT;
          radio.stopListening();
          Serial.println(F("TX_AWAIT_TIMEOUT"));
          substractPktCount();
        }
      }

      break;

    case TX_CHANNEL_HOOP_ADVERTISEMENT:
      Serial.println(F("TX_CHANNEL_HOOP_ADVERTISEMENT"));

      radio.flush_tx();
      makeChannelHoopPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        tx_state = TX_AWAIT_CHANNEL_HOOP_ACK;
        radio.startListening();
        pkt_timeout_timestamp = millis();
      } else {
        tx_state = TX_ERROR;
        OnChannelChangedErrorCharacteristic.writeValue("error 202");
      }

      break;

    case TX_AWAIT_CHANNEL_HOOP_ACK:
      Serial.println(F("TX_AWAIT_CHANNEL_HOOP_ACK"));

      if (radio.available()) {
        radio.read(rf_buf, NRF24_BUFSIZE);
        if (decodeChannelHoopAck(rf_buf, NRF24_BUFSIZE)) {
          tx_state = TX_TEST_CHANNEL_HSK;
          connection_lost_timestamp = millis();
          radio.stopListening();
          ChangeChannel();
        } else {
          tx_state = TX_REQUEST_PKT;
          radio.stopListening();
          OnChannelChangedErrorCharacteristic.writeValue("error 203");
        }
      } else {
        if (millis() - pkt_timeout_timestamp > AWAIT_TIMEOUT) {
          tx_state = TX_REQUEST_PKT;
          radio.stopListening();
          OnChannelChangedErrorCharacteristic.writeValue("error 206");
        }
      }

      break;

    case TX_TEST_CHANNEL_HSK:
      Serial.println(F("TX_TEST_CHANNEL_HSK"));

      radio.flush_tx();
      makeTestChannelPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        tx_state = TX_TEST_CHANNEL_ACK;
        radio.startListening();
        pkt_timeout_timestamp = millis();
      } else {
        tx_state = TX_ERROR;
        OnChannelChangedErrorCharacteristic.writeValue("error 204");
        ResetChannel();
      }

      break;

    case TX_TEST_CHANNEL_ACK:
      Serial.println(F("TX_TEST_CHANNEL_ACK"));

      if (radio.available()) {
        radio.read(rf_buf, NRF24_BUFSIZE);
        if (decodeTestChannelAck(rf_buf, NRF24_BUFSIZE)) {
          tx_state = TX_REQUEST_PKT;
          connection_lost_timestamp = millis();
          radio.stopListening();
          OnChannelChangedErrorCharacteristic.writeValue("channel change succesful");
        } else {
          tx_state = TX_REQUEST_PKT;
          radio.stopListening();
          OnChannelChangedErrorCharacteristic.writeValue("error 205");
          ResetChannel();
        }
      } else {
        if (millis() - pkt_timeout_timestamp > AWAIT_TIMEOUT) {
          tx_state = TX_REQUEST_PKT;
          radio.stopListening();
          OnChannelChangedErrorCharacteristic.writeValue("error 207");
          ResetChannel();
        }
      }

      break;

    case TX_ERROR:
      Serial.println(F("TX_ERROR"));

      // Error handling.
      Serial.println(F("=== UNEXPECTED ERROR detected. Printing radio config:"));
      radio.printPrettyDetails();
      /* Current version doesn't change anything here for now, but it could be a nice feature to 
          reset the radio (radio.powerDown + radioPowerUp) and to re-initialise the library with
          radio.begin() + all the preconfigured options.
        */
      resetRadio();
      radio.stopListening();
      tx_state = TX_SEND_HANDSHAKE;

      break;
  }

  isConnectionLossTX();
  calculateDataRate();
  calculatePktLoss();
  onChannelCharacteristicWrite();
  onLMCharacteristicWrite();
  onRMCharacteristicWrite();
  bleServerNoitfy();
}
// Put function definitions here: ///////////////////////////////////////////////////////////////

// BLE SERVER FUNCTIONS ////////////////////////////////////////////////////////////

void configureBleServer() {
  // Inicializa BLE y establece el nombre local del dispositivo
  if (!BLE.begin()) {
    Serial.println("Error al inicializar BLE!");
    while (1)
      ;
  }

  BLE.setLocalName("FLUTTERAPP");

  // Añadir características a sus respectivos servicios
  // Servicio de envío (sendService)
  sendService.addCharacteristic(depthCharacteristic);
  sendService.addCharacteristic(batteryLifeCharacteristic);
  sendService.addCharacteristic(packetLossCharacteristic);
  sendService.addCharacteristic(speedCharacteristic);
  sendService.addCharacteristic(gpsErrorCharacteristic);

  // Servicio de envío 2 (sendService_2)
  sendService_2.addCharacteristic(latitudeCharacteristic);
  sendService_2.addCharacteristic(longitudeCharacteristic);
  sendService_2.addCharacteristic(rotationCharacteristic);
  sendService_2.addCharacteristic(datarateCharacteristic);
  sendService_2.addCharacteristic(OnChannelChangedErrorCharacteristic);
  sendService_2.addCharacteristic(connectionCharacteristic);  // Esta característica también está en sendService_2

  // Servicio de recepción (reciveService)
  reciveService.addCharacteristic(dataGatheringCharacteristic);
  reciveService.addCharacteristic(channelCharacteristic);
  reciveService.addCharacteristic(LMCharacteristic);
  reciveService.addCharacteristic(RMCharacteristic);

  // Establecer los valores iniciales de las características
  // Para características de lectura/notificación, se pueden actualizar en cualquier momento.
  /*depthCharacteristic.writeValue(String(depth).c_str());
  batteryLifeCharacteristic.writeValue(String(battery_life).c_str());
  packetLossCharacteristic.writeValue(String(packet_loss).c_str());
  speedCharacteristic.writeValue(String(speed).c_str());
  gpsErrorCharacteristic.writeValue(String(gps_error).c_str());
  latitudeCharacteristic.writeValue(String(lat).c_str());
  longitudeCharacteristic.writeValue(String(lon).c_str());
  rotationCharacteristic.writeValue(String(rotation).c_str());
  datarateCharacteristic.writeValue(String(datarate).c_str());
  OnChannelChangedErrorCharacteristic.writeValue("error"); // Valor inicial "error"
  connectionCharacteristic.writeValue("not connected"); // Valor inicial "not connected"*/

  // Para características de escritura, establecer el valor inicial si es necesario.
  // Nota: Para booleanos o enteros pequeños, es mejor enviar el valor binario directamente.
  // Aquí se mantiene la conversión a String para ser consistente con el original.
  dataGatheringCharacteristic.writeValue(String(isDataGatheringEnabled).c_str());
  channelCharacteristic.writeValue(String(channel).c_str());
  LMCharacteristic.writeValue(String(inputLM).c_str());
  RMCharacteristic.writeValue(String(inputRM).c_str());

  // Asignar los manejadores de eventos de conexión/desconexión
  /*BLE.setEventHandler(BLEConnected, onBleConnected);*/
  BLE.setEventHandler(BLEDisconnected, onBleDisconnected);

  // Configurar la publicidad (advertising)
  // Añadir los UUIDs de los servicios que se anunciarán
  //BLE.setAdvertisedServiceUuid(sendService.uuid());
  //BLE.setAdvertisedServiceUuid(sendService_2.uuid());
  //BLE.setAdvertisedServiceUuid(reciveService.uuid());

  /*BLEAdvertisingData advData;
  advData.setAdvertisedService(sendService);
  advData.setAdvertisedService(sendService_2);
  advData.setAdvertisedService(reciveService);

  // Iniciar la publicidad
  BLE.setAdvertisingData(advData);*/

    // Añadir servicios al BLE
  BLE.addService(sendService);
  BLE.addService(sendService_2);
  BLE.addService(reciveService);

  BLE.advertise();

  Serial.println("Servidor BLE configurado y publicitando!");
  Serial.println("Ahora puedes conectarte desde tu teléfono.");
}  // revisar  // Falta acabar

void onBleDisconnected(BLEDevice central) {
  Serial.println("Disconnected from central!");
  BLE.advertise(); // Start advertising again!
  Serial.println("Started advertising again...");
}


// TX FUNCTIONS ////////////////////////////////////////////////////////////////////

void onDataGatheringCharacteristicWrite() {
  if (dataGatheringCharacteristic.written()) {
    Serial.print("Escrito en DataGatheringCharacteristic: ");
    // Leer el valor de la característica.
    // Si esperas un entero, puedes leerlo así:
    if (dataGatheringCharacteristic.valueLength() == 1) {  // Asumiendo que es un solo byte para un booleano/int pequeño
      isDataGatheringEnabled = dataGatheringCharacteristic.value()[0];
      Serial.println(isDataGatheringEnabled ? "true" : "false");
    } else {
      // Si esperas una cadena, puedes leerla así:
      String value = "";
      for (int i = 0; i < dataGatheringCharacteristic.valueLength(); i++) {
        value += (char)dataGatheringCharacteristic.value()[i];
      }
      //Serial.println(value);
      // Aquí podrías parsear la cadena a un entero si es necesario
      (value == "true") ? isDataGatheringEnabled = true : isDataGatheringEnabled = false;
      Serial.print("isDataGatheringEnabled: ");
      Serial.println(isDataGatheringEnabled);
    }
    // Implementa tu lógica aquí para manejar el cambio de estado de recolección de datos
  }
}

void makeHandshakePkt(uint8_t *buf, const uint8_t len) {

  buf[0] = HS_CMD;

  for (int i = 1; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar

bool decodeHandshakeACK(uint8_t *buf, const uint8_t len) {

  uint16_t crc = computeCRC16(buf, len - 2);
  uint8_t crc_msb = (crc >> 8) & 0xFF;
  uint8_t crc_lsb = (crc >> 0) & 0xFF;

  if (buf[len - 2] == crc_msb && buf[len - 1] == crc_lsb) {
    if (buf[0] == HSACK_CMD) {

      return true;

    } else {

      return false;
    }
  } else {

    return false;
  }

}  // revisar

void bleServerNotifyConnectionEstablished() {
  // En ArduinoBLE, simplemente escribe el nuevo valor.
  // Si la característica tiene la propiedad BLENotify, se enviará una notificación.
  connectionCharacteristic.writeValue("connected");
  Serial.println("Notificación de conexión establecida enviada.");
  advertise_connection_loss = true;
}  // revisar

void makeRequestPkt(uint8_t *buf, const uint8_t len) {

  buf[0] = RQRS_CMD;

  uint8_t LM_buffer[4];
  uint8_t RM_buffer[4];

  memcpy(LM_buffer, &inputLM, sizeof(LM_buffer));
  memcpy(RM_buffer, &inputRM, sizeof(RM_buffer));

  buf[1] = LM_buffer[0];
  buf[2] = LM_buffer[1];
  buf[3] = LM_buffer[2];
  buf[4] = LM_buffer[3];
  buf[5] = RM_buffer[0];
  buf[6] = RM_buffer[1];
  buf[7] = RM_buffer[2];
  buf[8] = RM_buffer[3];

  for (int i = 9; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar como enviar un float

bool decodeRequestedPkt(uint8_t *buf, const uint8_t len) {

  uint16_t crc = computeCRC16(buf, len - 2);
  uint8_t crc_msb = (crc >> 8) & 0xFF;
  uint8_t crc_lsb = (crc >> 0) & 0xFF;

  if (buf[len - 2] == crc_msb && buf[len - 1] == crc_lsb) {
    if (buf[0] == RQRSACK_CMD) {

      memcpy(&depth, buf + 1, 4);
      memcpy(&lat, buf + 5, 4);
      memcpy(&lon, buf + 9, 4);
      memcpy(&speed, buf + 15, 4);
      memcpy(&gps_error, buf + 19, 4);
      rotation = ((uint16_t)buf[13] << 8) + buf[14];
      battery_life = buf[23];

      Serial.print("Depth: ");
      Serial.println(depth, 8);
      Serial.print("lat: ");
      Serial.println(lat, 8);
      Serial.print("lon: ");
      Serial.println(lon, 8);
      Serial.print("Speed: ");
      Serial.println(speed, 8);
      Serial.print("GPS: ");
      Serial.println(gps_error, 8);
      Serial.print("Rotation: ");
      Serial.println(rotation);
      Serial.print("Battery Life: ");
      Serial.println(battery_life);

      return true;

    } else {

      return false;
    }
  } else {

    return false;
  }

}  // revisar

void makeChannelHoopPkt(uint8_t *buf, const uint8_t len) {

  buf[0] = CH_CMD;
  buf[1] = channel;

  for (int i = 2; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar

bool decodeChannelHoopAck(uint8_t *buf, const uint8_t len) {

  uint16_t crc = computeCRC16(buf, len - 2);
  uint8_t crc_msb = (crc >> 8) & 0xFF;
  uint8_t crc_lsb = (crc >> 0) & 0xFF;

  if (buf[len - 2] == crc_msb && buf[len - 1] == crc_lsb) {
    if (buf[0] == CHACK_CMD) {

      return true;

    } else {

      return false;
    }
  } else {

    return false;
  }

}  // revisar

void ChangeChannel() {

  radio.setChannel(channel);
  channel_timeout_timestap = millis();

}  // revisar

void makeTestChannelPkt(uint8_t *buf, const uint8_t len) {

  buf[0] = TC_CMD;

  for (int i = 1; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar

void ResetChannel() {

  radio.setChannel(base_channel);
  didChannelChange = false;

}  // revisar

void bleServerNoitfy() {

  if (millis() - notify_timestap > NOTIFY_INTERVAL) {
    //Serial.println("notify");
    notify_timestap = millis();
    /*lat += 0.00009;
    lon += 0.00009;
    battery_life++;
    packet_loss++;
    speed++;
    gps_error++;
    rotation++;
    datarate++;*/

    //Serial.println(String("not connected"));
    //Serial.println(String(12324144));

    char charBuffer[20];

    batteryLifeCharacteristic.writeValue(String(battery_life).c_str());
    packetLossCharacteristic.writeValue(String(packet_loss).c_str());
    speedCharacteristic.writeValue(String(speed).c_str());
    gpsErrorCharacteristic.writeValue(String(gps_error).c_str());
    dtostrf(lat, 0, 6, charBuffer);
    //Serial.println(String(charBuffer));
    latitudeCharacteristic.writeValue(charBuffer);
    dtostrf(lon, 0, 6, charBuffer);
    //Serial.println(String(charBuffer));
    longitudeCharacteristic.writeValue(charBuffer);
    rotationCharacteristic.writeValue(String(rotation).c_str());
    datarateCharacteristic.writeValue(String(datarate).c_str());

    if (isDataGatheringEnabled) {
      senDepth();
      depthCharacteristic.writeValue(String(depth).c_str());
    }
  }
} // revisar

bool decodeTestChannelAck(uint8_t *buf, const uint8_t len) {

  uint16_t crc = computeCRC16(buf, len - 2);
  uint8_t crc_msb = (crc >> 8) & 0xFF;
  uint8_t crc_lsb = (crc >> 0) & 0xFF;

  if (buf[len - 2] == crc_msb && buf[len - 1] == crc_lsb) {
    if (buf[0] == TCACK_CMD) {

      return true;

    } else {

      return false;
    }
  } else {

    return false;
  }

}  // revisar

void isConnectionLossTX() {

  if (millis() - connection_lost_timestamp > CONNECTION_LOST_TIMEOUT) {

    speed = 0;
    depth = 0;
    datarate = 0;
    packet_loss = 100;

    resetRadio();
    radio.stopListening();
    tx_state = TX_SEND_HANDSHAKE;
    connection_lost_timestamp = millis();
    if (advertise_connection_loss) {
      connectionCharacteristic.writeValue("disconected");
      Serial.println("Notificación de conexión perdida enviada.");
      advertise_connection_loss = false;
    }
  }

}  // revisar

void pktsAskedControl() {
  if (pkts_asked == 99) {
    pkts_asked++;
    calculate_timestap = millis();
  } else if (pkts_asked < 99) {
    pkts_asked++;
    //Serial.print("pkts asked: ");
    //Serial.println(pkts_asked);
  }
}

void addPktCount() {
  if (pkt_count < 100) {
    pkt_count++;
  }
}

void substractPktCount() {
  if (pkt_count > 0) {
    pkt_count--;
  }
}

void calculateDataRate() {

  datarate = ((pkt_count * NRF24_BUFSIZE) * 0.001 / (calculate_timestap / 1000));

}  // REVISAR EL PKT COUNT Y LOS MILLIS PARA QUE SE CALCULE EN INTERVALOS DE 20 SEGUNDOS

void calculatePktLoss() {
  packet_loss = ((pkts_asked - pkt_count) / pkts_asked) * 100;

}  // IMPLEMENTAR PKT COUNT Y PKTS ASKED EN EL LOOP

void onChannelCharacteristicWrite() {
  uint8_t actualChannel;

  if (channelCharacteristic.written()) {
    Serial.print("Escrito en ChannelCharacteristic: ");
    // Leer el valor de la característica.
    // Similar al anterior, adapta según el tipo de dato que esperes.
    if (channelCharacteristic.valueLength() == 1) {  // Asumiendo un solo byte para el canal
      actualChannel = channelCharacteristic.value()[0];
      Serial.println(actualChannel);
    } else {
      String value = "";
      for (int i = 0; i < channelCharacteristic.valueLength(); i++) {
        value += (char)channelCharacteristic.value()[i];
      }
      Serial.println(value);
      actualChannel = value.toInt();
    }
    // Implementa tu lógica aquí para manejar el cambio de canal
    if (actualChannel != channel) {
      channel = actualChannel;
      tx_state = TX_CHANNEL_HOOP_ADVERTISEMENT;
    }
  }
}

void onLMCharacteristicWrite() {
  if (LMCharacteristic.written()) {
    Serial.print("Escrito en LMCharacteristic: ");
    if (LMCharacteristic.valueLength() == 1) {
      inputLM = LMCharacteristic.value()[0];
      Serial.println(inputLM);
    } else {
      String value = "";
      for (int i = 0; i < LMCharacteristic.valueLength(); i++) {
        value += (char)LMCharacteristic.value()[i];
      }
      Serial.println(value);
      inputLM = value.toFloat();
    }
  }
}

void onRMCharacteristicWrite() {
  if (RMCharacteristic.written()) {
    Serial.print("Escrito en RMCharacteristic: ");
    if (RMCharacteristic.valueLength() == 1) {
      inputRM = RMCharacteristic.value()[0];
      Serial.println(inputRM);
    } else {
      String value = "";
      for (int i = 0; i < RMCharacteristic.valueLength(); i++) {
        value += (char)RMCharacteristic.value()[i];
      }
      Serial.println(value);
      inputRM = value.toFloat();
    }
  }
}

// GLOBAL FUNCTIONS /////////////////////////////////////////////////////////////////////////////////

void initializeRadio() {

  if (!radio.begin()) {
    while (true) {
      Serial.println(F("=== NRF24L01 initialization failed."));
      delay(1000);
    }
  }
  Serial.println(F("=== NRF24L01 initialization OK."));
  if (radio.isPVariant()) {
    Serial.println(F("=== NRF24L01+ detected."));
  } else {
    Serial.println(F("=== NRF24L01 detected."));
  }
  if (radio.isChipConnected()) {
    Serial.println(F("=== NRF24L01 chip connected."));
  } else {
    Serial.println(F("=== NRF24L01 chip NOT connected."));
  }

  const uint8_t TX_ADDRESS[6] = "NODE1";
  const uint8_t RX_ADDRESS[6] = "NODE2";

  radio.setPALevel(pa_setting);
  radio.setChannel(NRF24_CHANNEL);
  radio.setDataRate(dr_setting);
  radio.setCRCLength(hw_crc);
  radio.setPayloadSize(NRF24_BUFSIZE);
  radio.setAutoAck(auto_ack_enabled);
  radio.openWritingPipe(addr[addr_selector_txpipe]);
  //radio.openWritingPipe(RX_ADDRESS);
  /*Serial.print("send adress: ");
  Serial.println(addr[addr_selector_txpipe]);*/
  radio.openReadingPipe(1, addr[addr_selector_rxpipe]);
  //radio.openReadingPipe(1, TX_ADDRESS);
  /*Serial.print("send adress: ");
  Serial.println(addr[addr_selector_rxpipe]);*/

  if (is_rx_endpoint) {
    radio.startListening();  // Put radio in RX mode.
  } else {
    radio.stopListening();  // Put radio in TX mode.
  }
}

void resetRadio(bool power_reset) {
  Serial.println(F("=== Resetting nRF24L01 radio..."));

  if (power_reset) {
    // Power down and up
    radio.powerDown();
    delay(100);
    radio.powerUp();
  }

  // Reinitialize the radio
  if (!radio.begin()) {
    Serial.println(F("=== NRF24L01 initialization failed."));
    while (true) {
      delay(1000);  // Halt execution if initialization fails
    }
  }

  // Reapply configurations
  radio.setPALevel(pa_setting);
  radio.setChannel(NRF24_CHANNEL);
  radio.setDataRate(dr_setting);
  radio.setCRCLength(hw_crc);
  radio.setPayloadSize(NRF24_BUFSIZE);
  radio.setAutoAck(auto_ack_enabled);
  radio.openWritingPipe(addr[addr_selector_txpipe]);
  radio.openReadingPipe(1, addr[addr_selector_rxpipe]);

  // Flush buffers
  radio.flush_tx();
  radio.flush_rx();

  Serial.println(F("=== nRF24L01 radio reset complete."));
}

uint16_t computeCRC16(const uint8_t *data, size_t length) {
  uint16_t crc = CRC16_INIT;

  for (size_t i = 0; i < length; i++) {
    crc ^= (data[i] << 8);
    for (uint8_t j = 0; j < 8; j++) {
      if (crc & 0x8000U) {
        crc = (crc << 1) ^ CRC16_POLY;
      } else {
        crc <<= 1;
      }
    }
  }
  return crc;
}

void printRequestedpkt(uint8_t *buf, const uint8_t len) {
  Serial.print("pkt: ");
  for (int i = 0; i < len; i++) {
    Serial.print(String(buf[i], HEX) + ",");
  }
  Serial.println();
}

void changeRotation() {
  if (rotation < 360) {
    rotation++;
  } else {
    rotation = 0;
  }
}

float angle = 0;  

void senDepth() {
  const int amplitude = 7;  // Mitad de la amplitud (14 / 2)
  const int offset = 7;     // Para que oscile entre 0 y 14
  const float step = 0.1;   // Incremento del ángulo
  float sineValue = sin(angle);             // Valor entre -1 y 1
  depth = int(sineValue * amplitude + offset);  // Escalar a 0-14
  Serial.print("depth: ");
  Serial.println(depth);

  angle += step;
  if (angle >= TWO_PI) {
    angle -= TWO_PI;  // Para evitar desbordamiento
  }
}