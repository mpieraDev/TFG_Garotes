#include <Arduino.h>
#include <printf.h>
#include <SPI.h>
#include <RF24.h>


#define NRF24_BUFSIZE 32    // Max. is 32 bytes
#define NRF24_CHANNEL 0x00  // 76
#define CRC16_POLY 0x1021   // Polynomial for CRC-16-CCITT
#define CRC16_INIT 0xFFFF   // Initial CRC value

//TIMEOUTS
#define AWAIT_TIMEOUT 2000ULL             // Handshake ACK reception.
#define CONNECTION_LOST_TIMEOUT 20000ULL  // Conection lost timeout
#define CHANNEL_TIMEOUT 3000ULL
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

typedef enum rx_state_t {
  RX_AWAIT_REQUEST,
  RX_AWAIT_TEST_CHANNEL,
  RX_SEND_REQUESTED_DATA,
  RX_SEND_HANDSHAKE_ACK,
  RX_SEND_CHANNEL_HOOP_ACK,
  RX_SEND_TEST_CHANNEL_ACK,
  RX_ERROR
} rx_state_t;

/* Endpoint pinout settings */
#define LED 3      // LED indicator
#define CE_PIN 7   // CE pin for NRF24L01 (LNA enable)
#define CSN_PIN 8  // CSN pin for NRF24L01 (SPI chip select)
#define IRQ_PIN 2  // IRQ pin for NRF24L01


//DATA VARIABLES
float depth = 13.35796;
float lat = 42.19075;
float lon = 5.98940;
uint16_t rotation = 201;
float gps_error = 6.76465;
float speed = 1.9853576;
uint8_t battery_life = 10;
float datarate = 7;
int packet_loss = 8;  // IMPLEMEMENTAR CALCULO DE PACKET LOSS
float inputLM = 0;
float inputRM = 0;

uint8_t channel = 0;
uint8_t base_channel = 0;
bool didChannelChange = false;
uint8_t requestExitCode;

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
uint32_t calculate_timestap = 1;

rx_state_t rx_state = RX_AWAIT_REQUEST;

bool is_tx_endpoint = false;
bool is_rx_endpoint = true;
uint8_t addr_selector_txpipe = 0;
uint8_t addr_selector_rxpipe = 1;

// Function prototypes:
// NUEVAS
//rx
bool decodeRequest(uint8_t *buf, const uint8_t len);         //falta implementar
void ChannelTimeout();                                       //falta implementar
bool decodeTestChannelPkt(uint8_t *buf, const uint8_t len);  // falta implementar
void ChangeChannel();
void ResetChannel();
void makeRequestedPkt(uint8_t *buf, const uint8_t len);       // falta implementar
void makeHandshakeAckPkt(uint8_t *buf, const uint8_t len);    // falta implementar
void makeChannelHoopAckPkt(uint8_t *buf, const uint8_t len);  // falta implementar
void makeTestChannelAckPkt(uint8_t *buf, const uint8_t len);  // falta implementar
void isConnectionLossRX();                                    // falta implementar

// ANTIGUAS
void resetRadio(bool power_reset = true);
uint16_t computeCRC16(const uint8_t *data, size_t length);
void initializeRadio();
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
}

void loop() {
  // put your main code here, to run repeatedly:

  switch (rx_state) {

    case RX_AWAIT_REQUEST:
      //Serial.println(F("RX_AWAIT_REQUEST"));

      if (radio.available()) {
        radio.read(rf_buf, NRF24_BUFSIZE);
        if (decodeRequest(rf_buf, NRF24_BUFSIZE)) {
          didChannelChange = false;
          switch (requestExitCode) {
            case HS_CMD:

              rx_state = RX_SEND_HANDSHAKE_ACK;
              Serial.println(F("HS_CMD RECIVED"));
              break;

            case RQRS_CMD:

              rx_state = RX_SEND_REQUESTED_DATA;
              Serial.println(F("RQRS_CMD RECIVED"));
              break;

            case CH_CMD:

              rx_state = RX_SEND_CHANNEL_HOOP_ACK;
              Serial.println(F("CH_CMD RECIVED"));
              break;
          }
          connection_lost_timestamp = millis();
          radio.stopListening();
        } else {
          Serial.println(F("INVALID PKT RECIVED"));
          didChannelChange = false;
        }
      } else {
        ChannelTimeout();
      }

      break;

    case RX_AWAIT_TEST_CHANNEL:
      Serial.println(F("RX_AWAIT_TEST_CHANNEL"));

      if (radio.available()) {
        radio.read(rf_buf, NRF24_BUFSIZE);
        if (decodeTestChannelPkt(rf_buf, NRF24_BUFSIZE)) {
          rx_state = RX_SEND_TEST_CHANNEL_ACK;
          connection_lost_timestamp = millis();
          radio.stopListening();
        } else {
          rx_state = RX_AWAIT_REQUEST;
          ResetChannel();
        }
      } else {
        if (millis() - pkt_timeout_timestamp > AWAIT_PKT_TIMEOUT) {
          rx_state = RX_AWAIT_REQUEST;
          ResetChannel();
        }
      }

      break;

    case RX_SEND_REQUESTED_DATA:
      Serial.println(F("RX_SEND_REQUESTED_DATA"));

      radio.flush_tx();
      makeRequestedPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        rx_state = RX_AWAIT_REQUEST;
        radio.startListening();
        //pkt_timeout_timestamp = millis(); // MIRAR SI HAY QUE QUITARLO EN EL FLOWCHART
      } else {
        rx_state = RX_ERROR;
      }

      break;

    case RX_SEND_HANDSHAKE_ACK:
      delay(10);
      Serial.println(F("RX_SEND_HANDSHAKE_ACK"));

      radio.flush_tx();
      makeHandshakeAckPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        rx_state = RX_AWAIT_REQUEST;
        radio.startListening();
      } else {
        rx_state = RX_ERROR;
      }

      break;

    case RX_SEND_CHANNEL_HOOP_ACK:
      Serial.println(F("RX_SEND_CHANNEL_HOOP_ACK"));

      radio.flush_tx();
      makeChannelHoopAckPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        ChangeChannel();
        rx_state = RX_AWAIT_TEST_CHANNEL;
        radio.startListening();
        pkt_timeout_timestamp = millis();
      } else {
        rx_state = RX_ERROR;
      }

      break;

    case RX_SEND_TEST_CHANNEL_ACK:
      Serial.println(F("RX_SEND_TEST_CHANNEL_ACK"));

      radio.flush_tx();
      makeTestChannelAckPkt(rf_buf, NRF24_BUFSIZE);

      if (radio.write(rf_buf, NRF24_BUFSIZE)) {
        ChangeChannel();
        rx_state = RX_AWAIT_REQUEST;
        radio.startListening();
        didChannelChange = true;
      } else {
        rx_state = RX_ERROR;
        ResetChannel();
      }

      break;

    case RX_ERROR:
      Serial.println(F("RX_ERROR"));

      // Error handling.
      Serial.println(F("=== UNEXPECTED ERROR detected. Printing radio config:"));
      radio.printPrettyDetails();
      /* Current version doesn't change anything here for now, but it could be a nice feature to 
          reset the radio (radio.powerDown + radioPowerUp) and to re-initialise the library with
          radio.begin() + all the preconfigured options.
        */
      //resetRadio();
      radio.startListening();
      rx_state = RX_AWAIT_REQUEST;

      break;
  }

  isConnectionLossRX();
}
// Put function definitions here: ///////////////////////////////////////////////////////////////

// RX FUNCTIONS ////////////////////////////////////////////////////////////////////

bool decodeRequest(uint8_t *buf, const uint8_t len) {

  uint16_t crc = computeCRC16(buf, len - 2);
  uint8_t crc_msb = (crc >> 8) & 0xFF;
  uint8_t crc_lsb = (crc >> 0) & 0xFF;

  if (buf[len - 2] == crc_msb && buf[len - 1] == crc_lsb) {
    switch (buf[0]) {

      case HS_CMD:

        requestExitCode = buf[0];
        return true;
        break;

      case RQRS_CMD:

        requestExitCode = buf[0];

        memcpy(&inputLM, buf + 1, 4);
        memcpy(&inputRM, buf + 5, 4);

        Serial.print("LM: ");
        Serial.println(inputLM, 8);
        Serial.print("RM: ");
        Serial.println(inputRM, 8);

        return true;
        break;

      case CH_CMD:

        requestExitCode = buf[0];
        channel = buf[1];
        return true;
        break;

      default:

        return false;
        break;
    }
  }

  return false;

}  //revisar

void ChannelTimeout() {

  if (didChannelChange) {
    if (millis() - channel_timeout_timestap > CHANNEL_TIMEOUT) {
      ResetChannel();
    }
  }

}  //revisar

bool decodeTestChannelPkt(uint8_t *buf, const uint8_t len) {

  uint16_t crc = computeCRC16(buf, len - 2);
  uint8_t crc_msb = (crc >> 8) & 0xFF;
  uint8_t crc_lsb = (crc >> 0) & 0xFF;

  if (buf[len - 2] == crc_msb && buf[len - 1] == crc_lsb) {
    if (buf[0] == TC_CMD) {

      return true;

    } else {

      return false;
    }
  } else {

    return false;
  }

}  // REVISAR

void makeRequestedPkt(uint8_t *buf, const uint8_t len) {

  uint8_t depth_buffer[4];
  uint8_t lat_buffer[4];
  uint8_t lon_buffer[4];
  uint8_t speed_buffer[4];
  uint8_t gps_error_buffer[4];

  memcpy(depth_buffer, &depth, sizeof(depth_buffer));
  memcpy(lat_buffer, &lat, sizeof(lat_buffer));
  memcpy(lon_buffer, &lon, sizeof(lon_buffer));
  memcpy(speed_buffer, &speed, sizeof(speed_buffer));
  memcpy(gps_error_buffer, &gps_error, sizeof(gps_error_buffer));

  buf[0] = RQRSACK_CMD;

  buf[1] = depth_buffer[0];
  buf[2] = depth_buffer[1];
  buf[3] = depth_buffer[2];
  buf[4] = depth_buffer[3];
  buf[5] = lat_buffer[0];
  buf[6] = lat_buffer[1];
  buf[7] = lat_buffer[2];
  buf[8] = lat_buffer[3];
  buf[9] = lon_buffer[0];
  buf[10] = lon_buffer[1];
  buf[11] = lon_buffer[2];
  buf[12] = lon_buffer[3];
  buf[13] = (rotation >> 8) & 0xFF;
  buf[14] = rotation & 0xFF;
  buf[15] = speed_buffer[0];
  buf[16] = speed_buffer[1];
  buf[17] = speed_buffer[2];
  buf[18] = speed_buffer[3];
  buf[19] = gps_error_buffer[0];
  buf[20] = gps_error_buffer[1];
  buf[21] = gps_error_buffer[2];
  buf[22] = gps_error_buffer[3];
  buf[23] = battery_life & 0xFF;

  for (int i = 24; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // REVISAR, TEN EN CUENTA LAS VARIABLES, FLOAT UINT ETC

void makeHandshakeAckPkt(uint8_t *buf, const uint8_t len) {

  buf[0] = HSACK_CMD;

  for (int i = 1; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar

void makeChannelHoopAckPkt(uint8_t *buf, const uint8_t len) {

  buf[0] = CHACK_CMD;

  for (int i = 1; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar

void makeTestChannelAckPkt(uint8_t *buf, const uint8_t len) {

  buf[0] = TCACK_CMD;

  for (int i = 1; i < len - 2; i++) {
    buf[i] = random(0, 255);
  }

  uint16_t crc_rndpkt = computeCRC16(buf, len - 2);
  buf[len - 2] = (crc_rndpkt >> 8) & 0xFF;
  buf[len - 1] = (crc_rndpkt >> 0) & 0xFF;

}  // revisar

void isConnectionLossRX() {

  if (millis() - connection_lost_timestamp > CONNECTION_LOST_TIMEOUT) {

    resetRadio();
    radio.startListening();
    rx_state = RX_AWAIT_REQUEST;
    connection_lost_timestamp = millis();

    // Parar motores
    inputLM = 0;
    inputRM = 0;

    Serial.println(F("disocnected"));
  }

}  // revisar

void ChangeChannel() {

  radio.setChannel(channel);
  channel_timeout_timestap = millis();

}  // revisar

void ResetChannel() {

  radio.setChannel(base_channel);
  didChannelChange = false;

}  // revisar

//OLD FUNCTIONS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
  //radio.openWritingPipe(TX_ADDRESS);
  /*Serial.print("send adress: ");
  Serial.println(addr[addr_selector_txpipe]);*/
  radio.openReadingPipe(1, addr[addr_selector_rxpipe]);
  //radio.openReadingPipe(1, RX_ADDRESS);
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