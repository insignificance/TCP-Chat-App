# TCP Chat App

[中文文档](README_zh-CN.md) | [English](README.md)

A robust and feature-rich TCP Chat Application built with Flutter. This app demonstrates core networking concepts by allowing users to communicate over a local network using TCP sockets. It features both Client and Server modes, device discovery, and message history.

![App Icon](assets/icon/app_icon.png)

## Features

*   **Dual Mode**: Operate as a **TCP Server** or a **TCP Client**.
*   **Device Discovery**: Automatically discover other devices on the local network running the app.
*   **Real-time Chat**: Send and receive text messages instantly.
*   **Message History**: Persist chat logs locally using SQLite.
*   **Connection Management**: View active connections and manage session states.
*   **Cross-Platform**: Runs on Android, iOS, and Desktop (macOS/Windows/Linux).

## Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.0.0 or higher recommended)
*   A device or emulator/simulator to run the app.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/tcp_chat_app.git
    cd tcp_chat_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## Usage

### Server Mode
1.  Navigate to the **Server** tab.
2.  Tap **Start Server**. The app will listen on a specific port (default: `4040`).
3.  Share your IP address with clients or let them discover you.
4.  Accept incoming connections and start chatting!

<img src="assets/screenshots/server_mode.png" width="300" />

### Client Mode
1.  Navigate to the **Client** tab.
2.  Enter the **Server IP** and **Port**, or use the **Discover** feature to find available servers.
3.  Tap **Connect**.
4.  Once connected, you can send messages to the server.

<img src="assets/screenshots/client_mode.png" width="300" />

### Device Discovery
1.  Go to the **Discovery** page.
2.  The app will scan the local network for other devices.
3.  Tap on a discovered device to auto-fill connection details.

## Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/)
*   **Language**: [Dart](https://dart.dev/)
*   **Networking**: `dart:io` (Socket, ServerSocket)
*   **Local Database**: `sqflite`
*   **State Management**: `Provider` / `setState` (Basic state management for simplicity)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
