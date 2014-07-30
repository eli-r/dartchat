import 'dart:html';

void main()
{
  var textBox = querySelector('#textentry');
  var log = querySelector('#log');

  var webSocket = new WebSocket('ws://${Uri.base.host}:${Uri.base.port}/ws');
  webSocket.onOpen.first.then((_){
    print('connected to server!');
    webSocket.onMessage.listen((e){
      print('received: ${e.data}');
      var newMessage = new SpanElement();
      newMessage.style.width = '100%';
      newMessage.style.display = 'block';
      newMessage.text = e.data;
      log.children.add(newMessage);
    });

    textBox.onChange.listen((e){
      webSocket.send(textBox.value);
      textBox.value = '';
    });
  });

}
