const String serverIP = "192.168.1.10";
const int serverPort = 9000;
const String serverProtocol = "http";
String get baseUrl => '$serverProtocol://$serverIP:$serverPort';
