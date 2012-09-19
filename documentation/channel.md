# Channel

## Description

This class encapsulates the behaviour on a subscribed message.

## Reference

### channel.unsubscribe()

Unsubscribes from the channel. After this you should not receive any more
event on this channel.

Example:

    channel.unsubscribe();

### channel.trigger(eventName, data)

Sends an event to this channel.

- **eventName** [string, required] is the name of the event to fire
- **data** [dictionary, required] is the payload you want to send with the message

Example:

    channel.trigger('eventname', {foo: 'bar', zbr: 123});

Please notice that, to use this method, the channel type must be Private or Presence. Public channels
will not accept messages.

### channel.bind(eventName, callback)

Binds to an event on this channel. You should enter the event name as the first
argument, and a callback function on the second argument.

The callback receives a single argument with the payload of the message.

Example:

    channel.bind('testingevent', function(data) {
      Ti.API.warn("RECEIVED EVENT DATA: " + data);
    });

Please notice that to stop receiving events on that callback, you should
use the `unbind` function.

### channel.bind_all(callback)

It is possible to bind to all events at either the global or channel level by
using the method bind_all. This is used for debugging, but may have other
utilities.

Example:

    channel.bind_all(function(name, data) {
      Ti.API.warn("Received event named " + name);
      Ti.API.warn("DATA: " + JSON.stringify(data));
    });


## Properties

### members

Returns a reference to the members object, if this is a presence channel. For more information see
the [members](members.html) documentation.

## Events

### bind_all

If you bind the event named 'bind_all' you will automatically receive all
the events that your device receives **on this channel**, regardless of the event name.
Useful for debugging purposes.

## Example

See the `example/app.js` provided with this module.

