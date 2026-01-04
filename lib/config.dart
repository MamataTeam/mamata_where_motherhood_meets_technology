const String serverIP = "192.168.0.101";
const int serverPort = 8000;
const String serverProtocol = "http";

String get baseUrl => '$serverProtocol://$serverIP:$serverPort';
