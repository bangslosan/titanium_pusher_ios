# pusher Module

## Description

This module allows you to tap into the [pusher](http://pusher.com)
service directly into your Titanium Mobile applications.

## Installation

Please follow the guide [here](http://wiki.appcelerator.org/display/tis/Using+Titanium+Modules).

## Changelog

Please see the [changelog file](changelog.html).

## Accessing the pusher Module

To access this module from JavaScript, you would do the following:

	var Pusher = require("com.pusher");

The Pusher variable is a reference to the Module object.	

**Please notice that besides the `Pusher.setup` call, you should just use the official Pusher JS
documentation, because it's plain better than this, and the API is almost compatible :)**

## Reference

### Pusher.setup(pusher_key, [{options}])

This should be the first function you should call on the module, and it will
configure the Pusher module with the appropriate credentials. It accepts a Pusher
key as the first argument, and an optional object with options.

- **key** [string, required]: The Pusher key credential for your application

- **options** [object, optional]: An object with advanced options:

    - **appID** [string, optional]: The Pusher appID. Only required if you want
      to send events from the client
    - **secret** [string, optional]: The Pusher secret. Only required if you want
      to send events from the client
    - **reconnectAutomatically** [boolean, optional]: Set to `false` if you don't
      want the module to automatically reconnect to the Pusher servers when
      the connection goes down. Default value is `true`
    - **reconnectDelay** [integer, optional]: The number of seconds this module will
      wait before it tries to reconnect with the Pusher servers. Default value is
      `5` seconds
    - **encrypted** [boolean, optional]: Configures a Pusher instance to only
      connect over encrypted (SSL) connections. An application that uses SSL
      should use this option to ensure connection traffic is encrypted. Default
      is `true`.
    - **auth** [object, optional]: The auth option lets you send additional
      information with the authentication request. The properties available on
      the `auth` option are as follows:
          - **headers** [object]: Provides the ability to pass additional HTTP
            Headers to the channel authentication endpoint when authenticating a
            channel
          - **params** [object]: Additional parameters to be sent when the
            channel authentication endpoint is called.

Example:

    Pusher.configure('pusher_key_deadbeef', {
      appID: 'your app ID',
      secret: 'your secret',
      reconnectAutomatically: true,
      reconnectDelay: 5,
      encrypted: true,
      auth: {
        headers: {
          CSRFToken: 'some_csrf_token'
        },
        params: {
          param1: 'value1',
          param2: 'value2'
        }
      }
    });

When you call this function, the module immediately tries to connect to Pusher.

### Pusher.connect()

Initiate the connection with the Pusher servers. Please notice that the 
connection doesn't become immediately ready! You should wait for the
"connected" event (see below) before you start subscribing and/or sending
messages to Pusher.

Example:

    Pusher.connect();

### Pusher.disconnect()

Manually disconnects from the Pusher server.

Example:

    Pusher.disconnect();

### Pusher.subscribe(channelName) \[returns a channel object\]

Subscribes to a channel. The first and only argument is a String, required,
and corresponds to the channel name you want to subscribe.

Example:

    var channel = Pusher.subscribe('test');

Please notice that this method returns a `Channel` object. For more 
information about that object see the [Channel documentation](channel.html).

Also, please notice that after this line, the client isn't immediately binded to
the channel. You must wait for the `pusher:subscription_succeeded` event on the channel
(more on that on the Channel documentation).

### Pusher.unsubscribe(channelName)

Unsubscribes from a channel. The first and only argument is a String, required,
and corresponds to the channel name you want to unsubscribe form.

### Pusher.bind('event', callback);

If you want to bind to an event, regardless of the channel, you should
use this function. You enter the event name as the first argument, and
a callback function on the second argument.

The event parameter passed on the callback function contains only the data
object sent on that message (the payload) already parsed and ready to use.

Example:

    Pusher.bind('testingevent', function(data) {
      Ti.API.warn("Received test event with payload " + data);
    });

Please notice that to stop receiving events on that callback, you should
use the `unbind` function.

### Pusher.unbind('event', callback)

Unbinds a specific callback from a previously binded event.

### Pusher.sendEvent(eventName, channelName, data)

Sends an event to a channel.

- **eventName** [string, required] is the name of the event to fire
- **channelName** [string, required] is the name of channel to send the event
- **data** [dictionary, required] is the payload you want to send with the message

Example:

    Pusher.sendEvent('eventname', 'test', {foo: 'bar', zbr: 123});

Please notice that, to use this method, you have to provide both the **appID**
and the **secret** on the configure function above.

### Pusher.bind_all(callback)

It is possible to bind to all events at either the global or channel level by using the method bind_all. This is used for debugging, but may have other utilities.

Example:

    Pusher.bind_all(function(name, data) {
      Ti.API.warn("Received event named " + name);
      Ti.API.warn("DATA: " + JSON.stringify(data));
    });

## Properties

### state

Returns the current connection state as a string.

## Events

### connected

Fired when the Pusher module successfully connects and handshakes with the
Pusher servers.

### disconnected

Fired when Pusher disconnects from the server. If `reconnectAutomatically` was
`true`, Pusher will automatically try to call the server again.

### connecting

### initialized

Fired when Pusher is in a configured state, ready to connect.

### bind_all

If you bind the event named `bind_all` you will automatically receive all
the events that your device receives, regardless of the event name or the
channel where it was fired. Useful for debugging purposes.

## Usage

Please see the `example/app.js` file included with this module.

## Author

Ruben Fonseca <fonseka@gmail.com>

