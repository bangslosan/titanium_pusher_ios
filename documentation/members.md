# Members

## Description

This class encapsulates the members of a presence channel.

## Reference

### Members.each(callback)

The members.each function is used to iterate the members who are subscribed to
the presence channel. The method takes a single function parameter which is
called for each member that is subscribed to the presence channel. The function
will be pass a member object representing each subscribed member.

Example:

    var members = channel.members;
    members.each(function(member) {
      Ti.API.log("member info " + member.info);
    });

### Members.getMember(userId)

This method can be used to get a member with a specified userId (string).

### Members.me

This property gets the id and info for the current presence user.

## Properties

### count \[readonly\]

A property with a value that indicates how many members are subscribed to the presence channel.

