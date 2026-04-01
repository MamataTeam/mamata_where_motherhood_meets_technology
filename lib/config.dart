const String serverIP = "192.168.0.100";
const int serverPort = 8000;
const String serverProtocol = "http";

String get baseUrl => '$serverProtocol://$serverIP:$serverPort';

// Chatbot API (runs on port 5000)
String get chatbotUrl => '$serverProtocol://$serverIP:5000';
       
// Nepali Chatbot (port 5001)
const String nepaliChatbotUrl = '$serverProtocol://$serverIP:5001';
