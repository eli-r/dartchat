import 'dart:io';

var PORT = 8080;

void main()
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
            websocket.listen(handleMessage);
          });
        } else {
          File file = new File('${basePath}${resultPath}');
          file.exists().then((bool found){
            if(found){
              file.openRead()
                  .pipe(request.response)
                  .catchError((e) => print('error $e sending file'));
            } else {
              request.response.statusCode = HttpStatus.NOT_FOUND;
              request.response.close();
            }
          });
        }
      });
    },
    onError: (err) => print('Error starting HTTP Server: $err'));
}

void handleMessage(message)
{
  print('received websocket message: $message');
}
