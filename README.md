# TFG_Garotes

The project is situated within **Garotes**, an initiative by *Spascat* to generate bathymetric maps in hard-to-reach coastal areas using satellite-derived bathymetry algorithms.  
To calibrate them, a small amount of real bathymetric data is needed. The challenge was that the company did not have its own method to collect this data autonomously, economically, and efficiently.


### The solution
We designed a complete, accessible, and scalable system for collecting real bathymetric data in complex environments, minimizing costs and resources.  
This is a marine surface vehicle controlled via radio, with integrated sonar and controllable from a mobile device application developed specifically for the project.


### System components
The developed system consists of three main components:

- **Marine surface drone**: a radio-controlled vehicle equipped with sonar, responsible for data collection.  
- **Intermediate communication module**: links the vehicle with the mobile device using a custom long-range radiofrequency protocol and Bluetooth Low Energy (BLE).  
- **Mobile application**: from which the operator can control the drone, view telemetry, and access the collected data, all in real time.
  

### Capabilities
The system enables operation in hard-to-reach areas with a range greater than **1 km** and an autonomy of **6 hours**.  
Its electronic infrastructure is optimized to reduce investment, offering an efficient and economical alternative to conventional bathymetric methods.

**LinkedIn Post:** https://www.linkedin.com/feed/update/urn:li:activity:7356992431638126592/

# Installation

This project contains two main parts: a **Flutter app** and an **Arduino firmware**.

## Flutter App

### 1. Install Flutter

If you don’t have Flutter installed:

1. Download Flutter from the official website: [Flutter Installation](https://docs.flutter.dev/get-started/install)
2. Add Flutter to your system `PATH`.
3. Verify installation:

   ```bash
   flutter --version
   flutter doctor
   ```

   Make sure all checks from `flutter doctor` pass.

### 2. Clone the repository

```bash
git clone https://github.com/mpieraDev/TFG_Garotes.git
cd TFG_Garotes/Flutter/demo_app
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the app

>  **Important:** the app uses **Bluetooth to connect to the Arduino**, so it **will not work on emulators**. You must run it on a **real mobile device**.

Run:

```bash
flutter run
```

### 5. Compatibility

* **iOS**: not tested yet.
* **Android**: tested on real devices.


## Arduino 

### Microcontroller used

The system uses two **Arduino Nano RP2040 Connect** boards with different roles:

- **Tx (Transmitter / Ground Station)**: located on the ground, this module connects to the mobile device via **Bluetooth Low Energy (BLE)**.  
  It sends requests to the drone asking for specific data packets.  

- **Rx (Receiver / Drone)**: located on the marine drone, this module listens to the requests from the Tx on the ground and responds by sending back the requested data packets.  

This architecture allows the mobile device to communicate indirectly with the drone through the Tx module on the ground, ensuring long-range operation while still using BLE for the mobile app connection.


### Librerías necesarias

####  Comunes (Tx y Rx)
- **Arduino core** (incluye `Arduino.h`) → ya viene con el IDE.  
- **printf.h** → no es una librería externa, viene como utilitario en algunos ejemplos de RF24, normalmente se incluye junto con la librería RF24.  
- **SPI** → librería estándar, ya incluida con Arduino.  
- **RF24** → esta sí tienes que instalarla desde el Library Manager:  
  - Autor: **TMRh20**  
  - Nombre: **RF24** (para módulos nRF24L01).  

#### Solo en Tx
- **avr/dtostrf.h** → viene con el core AVR, no necesitas instalar nada.  
- **ArduinoBLE** → sí hay que instalarla desde el Library Manager:  
  - Autor: **Arduino**  
  - Nombre: **ArduinoBLE**.  


### ⚙️ Setup in Arduino IDE

1. **Install Arduino IDE**  
   - Download from the official website: [Arduino IDE](https://www.arduino.cc/en/software).  
   - Make sure it is correctly installed and that you can open it without issues.

2. **Add support for Arduino Nano RP2040 Connect**  
   - Open Arduino IDE → *Tools* → *Board* → *Boards Manager...*  
   - Search for **Arduino Mbed OS RP2040 Boards** and install it.  
   - After installation, select **Arduino Nano RP2040 Connect** as your board.

3. **Install the required libraries**  
   From the *Library Manager* (Sketch → Include Library → Manage Libraries...), install:  
   - **RF24** (by TMRh20) → for the nRF24L01 radio modules.  
   - **ArduinoBLE** (by Arduino) → for Bluetooth communication (used in the Tx unit).  
   - Standard libraries like **SPI** are already included.

4. **Compile the firmware**  
   - Open the provided `.ino` file (for Tx or Rx).  
   - Click the **✓ Verify** button in Arduino IDE to compile and confirm there are no errors.

5. **Upload the firmware**  
   - Connect your **Arduino Nano RP2040 Connect** via USB.  
   - Select the correct port under *Tools → Port*.  
   - Click **→ Upload** to flash the firmware to the board.

6. **Hardware requirements**  
   - You need **two nRF24L01 antennas (minimum)**:  
     - One connected to the **Tx (ground station)**.  
     - One connected to the **Rx (drone)**.  
   - These modules handle the long-range radio communication between drone and ground.

7. **Wiring diagram reference**  
   You can refer to the wiring diagram provided by the RF24 library’s documentation to see how to connect the nRF24L01 modules:  
   [RF24 Wiring Diagram — RF24 Library Documentation](https://nrf24.github.io/RF24/)  


