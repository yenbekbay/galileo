<img src=".github/hero.png" alt="Galileo logo" height="70">

Galileo is an iOS app that enables you to learn interesting facts and discover amazing stories by reading hand-picked articles from Wikipedia.

<img src=".github/screenshots.jpg" width="520">

## Stack

Galileo iOS app is written in Objective-C using the MVVM architecture. It's built with [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), [AFNetworking](https://github.com/AFNetworking/AFNetworking), and [YapDatabase](https://github.com/yapstudios/YapDatabase).

Galileo backend is written in JavaScript / Node.JS. It's built with [LoopBack](https://loopback.io/) on top of a PostgreSQL database.

## Setup

1. Clone the repo:
```console
$ git clone https://github.com/yenbekbay/galileo
$ cd galileo
```

2. Install iOS app dependencies from [CocoaPods](http://cocoapods.org/#install):
```console
$ (cd ios && bundle install && pod install)
```

3. Install backend dependencies with [npm](https://www.npmjs.com/get-npm):
```console
$ (cd backend && npm install)
```

4. Update the database config in `backend/server/datasources.json` and start the server:
```console
$ node backend/server/server.js
```

5. Fetch featured articles from Wikipedia:
```console
$ node backend/bin/articles.js
```

6. Configure the secret values for the iOS app:
```console
$ cp ios/Galileo/Secrets-Example.h ios/Galileo/Secrets.h
$ open ios/Galileo/Secrets.h
# Paste your values
```

3. Open the Xcode workspace at `ios/Galileo.xcworkspace` and run the app.

## License

[MIT License](./LICENSE) © Ayan Yenbekbay
