// Initialization

var Pusher = require('com.pusher');
Pusher.log = function(message) {
  Ti.API.log("------------------- " + message);
}

Pusher.channel_auth_endpoint = "http://floating-garden-8662.herokuapp.com/presence_auth";

Pusher.setup('437c8bf5d9d5529460e9', {
  appID: '1305',                   // CHANGEME
  secret: '0750515631c6e8300b03',  // CHANGEME
  reconnectAutomaticaly: true
});

Pusher.connection.bind('status_change', function(status) {
  Ti.API.log("-- " + status.previous + " -- " + status.current);
});

var navigationWindow = Ti.UI.createWindow();

var window = Ti.UI.createWindow({
	backgroundColor:'white',
  title: 'Pusher'
});

var nav = Ti.UI.iPhone.createNavigationGroup({
  window: window
});
navigationWindow.add(nav);
navigationWindow.open();

// Handlers
var handleConnected = function() {
  connect_button.enabled = false;
  add_message_button.enabled = true;

  Pusher.bind('connected', function() {
    Ti.API.warn("PUSHER CONNECTED");
    connect_button.title = 'Disconnect';
    connect_button.enabled = true;

    // Connect to channel
    window.channel = Pusher.subscribe('presence-test');

    // Bind to all events on this channel
    window.channel.bind('bind_all', handleEvent);

    // When we subscribe the channel
    window.channel.bind('pusher:subscription_succeeded', function() {
      Ti.API.log("SUBSCRIPTION SUCCEEDED");

      // This only works because it's a presence channel. Otherwise an error would
      // be thrown.
      Ti.API.log("MEMBER COUNT IS " + window.channel.members.count);
      window.channel.members.each(function(member) {
        Ti.API.log("--------- " + JSON.stringify(member));
      });

      var member = window.channel.members.getMember("1");
      Ti.API.log("------- MEMBER 1 IS " + JSON.stringify(member));

      Ti.API.log("-------- ME ---> " + JSON.stringify(window.channel.members.me));

      // You can trigger events from the client side on private and presence channels
      window.channel.trigger("TTTTTT", { foo: 'bar' });
    });

    window.channel.bind('pusher:subscription_error', function(status) {
      Ti.API.log("SUBSCRIPTION FAILED " + status);
    });

    // Bind to a specific event on this channel
    window.channel.bind('alert', handleAlertEvent);

    window.channel.unbind('bind_all', handleEvent);
  });
  Pusher.connect();
};

var handleDisconnected = function() {
  connect_button.title = 'Connect';
  add_message_button.enabled = false;

  if(window.channel) {
    window.channel.unbind('bind_all', handleEvent);
    window.channel.unbind('alert', handleAlertEvent);
  }

  Pusher.disconnect();
}

var handleEvent = function(data) {
  var label = Ti.UI.createLabel({
    text: JSON.stringify(data),
    top: 3,
    left: 10,
    height: '20',
    font: {fontSize: 20}
  });

  var tableViewRow = Ti.UI.createTableViewRow({});
  tableViewRow.add(label);

  tableview.appendRow(tableViewRow, {animated:true});
};

var handleAlertEvent = function(data) {
  alert(JSON.stringify(data));
}

var connect_button = Ti.UI.createButton({
  title: 'Connect'
});
connect_button.addEventListener('click', function(e) {
  if(connect_button.title == 'Connect')
    handleConnected();
  else
    handleDisconnected();
});
window.leftNavButton = connect_button;

var add_message_button = Ti.UI.createButton({
  title: 'Add',
  enabled: false
});
add_message_button.addEventListener('click', function(e) {
  var new_window = Ti.UI.createWindow({
    url: 'channel.js',
    backgroundColor: 'white',
    title: 'Send event to channel'
  });
  new_window.pusher = Pusher;
  nav.open(new_window, {animated:true});
});
window.rightNavButton = add_message_button;

var tableview = Ti.UI.createTableView({
  data: [],
  headerTitle: 'Send events to the test channel'
});
window.add(tableview);

