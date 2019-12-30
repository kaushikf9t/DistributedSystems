// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"

let channel = socket.channel("room:lobby", {}); // connect to chat "room"
let subscribed = [53]
channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.name || 'guest';    // get name from payload or set default
  li.innerHTML = '<font size="2"><b>' + name + '</b>: ' + payload.message + '</font>'; // set li contents
  li.className = 'row';
  ul.prepend(li);                    // append to list
  // console.log(payload.name);
  if(subscribed.includes(payload.name)) live.prepend(li);
});

channel.on('popusers', function (payload){
  console.log(payload.num_clients + '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
  let last = payload.num_clients;
  if (last) {
    var list = document.getElementById('projectSelectorDropdown');
    console.log(list);
    for (var i = last; i > 0; i--) {
      var li = document.createElement("li");  
      var link = document.createElement("a");           
      var text = document.createTextNode(i);
      link.appendChild(text);
      link.href = "#";
      li.appendChild(link);
      list.appendChild(li);
    }
  };
  
});

channel.join(); // join the channel.


let ul = document.getElementById('msg-list');        // list of messages.
let name = document.getElementById('name');          // name of message sender
let msg = document.getElementById('msg');            // message input field
let live = document.getElementById('live-feed');
let dd = document.getElementById('projectSelectorDropdown');
// "listen" for the [Enter] keypress event to send a message:
// msg.addEventListener('keypress', function (event) {
// 	if (name.value.length==0) {name.value = 'guest'};
//   if (event.keyCode == 13 && msg.value.length > 0) { // don't sent empty msg.
//     channel.push('shout', { // send the message to the server on "shout" channel
//       name: name.value,     // get value of "name" of person sending the message
//       message: msg.value    // get message text (value) from msg input field.
//     });
//     msg.value = '';         // reset the message input field for next message.
//   }
// });

// function liveView() {
//   console.log(dd.value+">>>>>>>>>>>>>>>>>>>>>>");
//   subscribed.push(dd.value);
// }
$(function(){
  $('.dropdown-menu li > a').click(function(e){
    // $('#datebox').val($(this).html());
    console.log('___________________kdkskdskskdk  '+$(this).html());
});
});


// dd.addEventListener('select', function (event) {
//   console.log("___________________kdkskdskskdk");
// });