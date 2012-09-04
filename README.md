# Pusher Titanium Mobile Module for iOS

This is the Pusher module for Titanium Mobile applications on iOS.

Please check the documentation folder for instructions on how to use it.

You should also download the latest version of the module and follow
the instructions here to install http://wiki.appcelerator.org/display/tis/Using+Titanium+Modules

## Building

Before you can build the module, you have to install the Pods from Podfile 
(powered by Cocoapods). To do that, open the terminal inside the project
and enter:

$ sudo gem install cocoapods
$ pod install

This will create a new directory `Pods` inside your project, with all the
project dependencies.

Then, assuming you have the latest Titanium Mobile, Xcode (currently 4.4) and
the iOS SDK (currently 5.0), you can build simply by entering

$ ./build.py

You can also run the included example app by entering,

$ titanium run

# Upgrading from version <1.0

The main difference to the old versions was a complete rewrite of the module, to be as much compatible
as possible with the JavaScript Pusher API. Because of that, we've changed some things:

- you should stop using `addEventListener` and `removeEventListener`. It will simply not work anymore!
- All the callbacks receive the data directly (like the JS API) and not an object with some Titanium
  garbage. Example:

        // old
        channel.addEventListener('event', function(event) {
          alert("DATA IS " + event.data);
        });

        // new
        channel.bind('event', function(data) {
          alert("DATA IS " + data);
        });

# Differences between this module's API and the Pusher Javascript API

The main difference when you want to port your code is initialization and global configuration.

### Javascript code

        Pusher.channel_auth_endpoint = 'http://....';

        var pusher = new Pusher(applicationKey, options);
        pusher.subscribe(...)

### Titanium Code

        var pusher = require('com.0x82.pusher');
        pusher.channel_auth_endpoint = 'http://.....';
        pusher.setup(applicationKey, options);

        pusher.subscribe(...)

Other than this, this module should have 100% compatibility with the Javascript counterpart!

