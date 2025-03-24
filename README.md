# 🔌 Hardware-Software Communication Project

## 📝 Overview

This project demonstrates the integration between hardware and software components, creating a seamless communication system between physical devices and digital interfaces.

## 🎯 Motivation

- Create robust hardware-software communication channels
- Develop practical skills in IoT development
- Demonstrate the integration of multiple technology stacks
- Build a functional system that bridges the physical and digital worlds

## ✨ Features

- Real-time data transmission between hardware and software
- Interactive mobile application interface
- Secure API endpoints for device communication
- Responsive design for multiple device types

## 🛠️ Technologies Used

### Backend

- To be defined
- 💾 PostgreSQL - Data storage/User authentication - Supabase
- 🔄 RESTful API - Communication protocol

### Mobile

- 📱 Flutter - Cross-platform mobile application

### Hardware

- ⚡ Arduino - Microcontroller programming (.ino files) - LoRa ESP32
- 🔌 Sensors - Environmental and input data collection - Missing sensors
- 📶 Communication modules - WiFi/Serial connectivity - WiFi antena

## 📋 Prerequisites

- Python 3.8+
- Node.js 14+ and npm/yarn
- Arduino IDE
- Required hardware components (LoRa ESP32)

## 🚀 Installation and Setup

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/rloucao/final-project.git

# Navigate to the backend directory
cd final-project/backend

# Create a virtual environment
python -m venv venv

# Activate virtual environment
# On Windows
venv\Scripts\activate
# On macOS/Linux
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python run.py
```

### Frontend Setup

```bash
# Navigate to the frontend directory
cd final-project/frontend

# Install dependencies
npm install
# or
yarn install

# Start the Expo development server
expo start
```

### Hardware Setup

1. Open Arduino IDE
2. Load the .ino files from the arduino directory
3. Connect your Arduino board
4. Upload the code to your board
5. Connect the necessary sensors according to the circuit diagram

## 📖 Usage

### 🖥️ Local

1. Power on your hardware device
2. Ensure the backend server is running
3. Launch the mobile application
4. Follow the on-screen instructions to connect to your device
5. View real-time data and interact with your hardware

### 🌍 Online

🔧  Deployment not configured yet

## 📊 Project Structure

```
final-project/
├── backend/              # Flask server code
│   ├── .venv/            # Virtual enviroment 
│   ├── app/              # Webhooks, routes, database setup
│   ├── requirements.txt  # Python dependencies
│   └── run.py            # Main application file
│
├── mobile/               # React Native application
│   ├── app/              # Entry point
│   ├── assets/           # Static files
│   ├── components/       # Shared components used accros the mobile application
│   ├── constants/        # Constants varibles
│   ├── hooks/            # Shared hooks used accores the mobile application
│   ├── node_modules/     # Node modules
│   ├── scripts/          # Scripts to trigger backend
│   └── ...               # More files 
│
└── hardware/             # Arduino code
    └── main.ino          # Main Arduino sketch

```

