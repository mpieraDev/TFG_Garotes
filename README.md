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

---

# Installation

This project contains two main parts: a **Flutter app** and an **Arduino firmware**.

## Flutter Part

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


## Arduino Part

### Microcontroller used

* **Arduino Nano RP2040 Connect**

### Setup in Arduino IDE

1. Open **Arduino IDE**.
2. Add support for **Arduino Nano RP2040 Connect** via the Board Manager.
3. Install the required libraries (depending on the firmware, such as **WiFiNINA**, **ArduinoBLE**, etc.).

With this, you can compile and upload the firmware to the Arduino so it communicates with the Flutter app via Bluetooth.

