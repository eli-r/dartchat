build:
	mkdir temp
	dart2js client.dart -o temp/client.dart.js
	cp temp/client.dart.js .
	cp temp/client.dart.js.map .
	rm -rf temp
