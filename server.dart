import 'dart:io';
import 'dart:convert';

final PORT = 8080;

void main()
{
  var wss = new WebSocketServer();
  var ws = new WebServer(wss);
}

class WebServer
{
  WebServer(wss)
  {
    File script = new File(Platform.script.toFilePath());
    String basePath = script.parent.path;

    HttpServer.bind('127.0.0.1', PORT)
      .then((HttpServer server){
        print('listening for connections on port $PORT');

        server.listen((HttpRequest request){
          String path = request.uri.toFilePath();
          String resultPath = path == '/' ? '/index.html' : path;
          print('file \"$resultPath\" requested');
          if(resultPath == '/ws'){
            WebSocketTransformer.upgrade(request).then((WebSocket websocket){
              wss.addClient(websocket);
            });
          } else {
            File file = new File('${basePath}/web${resultPath}');
            file.exists().then((bool found){
              if(found){
                String mimeType = 'text/html; charset=UTF-8';
                int lastDot = resultPath.lastIndexOf('.', resultPath.length - 1);
                if(lastDot != -1){
                  String extension = resultPath.substring(lastDot + 1);
                  switch(extension){
                    case 'html':
                      break;
                    case 'js':
                      mimeType = 'text/javascript';
                      break;
                    default:
                      break;
                  }
                }
                request.response.headers.set('Content-type', mimeType);
                file.openRead()
              .pipe(request.response)
              .catchError((e) => print('error $e sending file'));
              } else {
                print('404: $resultPath not found');
                request.response.statusCode = HttpStatus.NOT_FOUND;
                request.response.close();
              }
            });
          }
        });
      },
      onError: (err) => print('Error starting HTTP Server: $err'));
  }
}

class WebSocketServer
{
  Map<WebSocket, String> clients;
  WebSocketServer()
  {
    clients = new Map();
  }
  void addClient(socket)
  {
    print('added new client');
    socket
      .listen((message){
        //parse messages
        print('client send message: $message');
        if(message[0] == '/'){
          var command = message.split(' ');
          bool valid = true;
          switch(command[0]){
            case '/name':
              if(command.length == 2){
                if(clients.containsValue(command[1])){
                  print('Error: the name is in use! Try another one.');
                } else {
                  socket.add('SERVER: Your name has been set to ${command[1]}.');
                  clients[socket] = command[1];
                }
              } else {
                valid = false;
              }
              break;
            case '/help':
              if(command.length == 1){
                sendHelp(socket);
              } else {
                valid = false;
              }
              break;
          }
          if(!valid){
            socket.add('SERVER: Error: your command was invalid. Type /help to see all commands.');
          }
        } else {
          if(clients.containsKey(socket)){
            broadcastMessage(clients[socket], message);
          } else {
            socket.add('SERVER: Error: you do not have a registered nickname. Try using /name');
          }
        }
      });
  }
  void broadcastMessage(name, String message)
  {
    clients.forEach((s, n){
      s.add("$name: $message");
    });
  }
  void sendHelp(client)
  {
    client.add("COMMANDS:");
    client.add("/help : display all commands");
    client.add("/name <DisplayName> : sets display name");
  }
}
