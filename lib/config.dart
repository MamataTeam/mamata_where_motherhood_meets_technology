const String serverIP = "10.166.193.244";
const int serverPort = 8000;
const String serverProtocol = "http";

String get baseUrl => '$serverProtocol://$serverIP:$serverPort';
