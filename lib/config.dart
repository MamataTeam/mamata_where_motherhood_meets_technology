const String serverIP = "127.0.0.1";
const int serverPort = 8000;
const String serverProtocol = "http";

String get baseUrl => '$serverProtocol://$serverIP:$serverPort';
