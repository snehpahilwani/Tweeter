// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("server:twtr", {})

// let chatInput         = document.querySelector("#chat-input")
// let messagesContainer = document.querySelector("#messages")

channel.join()
.receive("ok", resp => { console.log("Joined successfully", resp) })
.receive("error", resp => { console.log("Unable to join", resp) })

if(document.getElementById("btn_login")){
  let userName = document.querySelector("#txt_userName")
  let pass = document.querySelector("#txt_pass")
  document.getElementById("btn_login").onclick = function(){
  channel.push("login", {userName: userName.value, pass: pass.value})
};
}

if(document.getElementById("btn_signup")){
  let userName = document.querySelector("#txt_userName")
  let pass = document.querySelector("#txt_pass")
  console.log(userName)
  console.log(pass)
  document.getElementById("btn_signup").onclick = function(){
  channel.push("signup", {userName: userName.value, pass: pass.value})
};
}

if(document.getElementById("btn_tweet")){
  //let userName = document.querySelector("#txt_userName")
  let tweet = document.querySelector("#txt_tweet")
  let tweetedlabel = document.querySelector("#tweeted")
  let link = window.location.href
  let userName = link.split("/")[link.split("/").length-1]
  document.getElementById("btn_tweet").onclick = function(){
    tweetedlabel.innerHTML = "Tweeted!"
    channel.push("tweet", {userName: userName, tweet: tweet.value})
};
}

if(document.getElementById("btn_retweet")){
  let link = window.location.href
  let userName = link.split("/")[link.split("/").length-1]
  let retweetID = document.querySelector("#txt_retweet")
  document.getElementById("btn_retweet").onclick = function(){
    channel.push("retweet", {userName: userName, retweetID: parseInt(retweetID.value)})
};
}


if(document.getElementById("btn_follow")){
  let link = window.location.href
  let userName = link.split("/")[link.split("/").length-1]
  let user_to_follow = document.querySelector("#txt_follow")
  document.getElementById("btn_follow").onclick = function(){
    channel.push("follow", {userName: userName, user_to_follow: user_to_follow.value})
};
}


if(document.getElementById("btn_query")){
  let link = window.location.href
  let userName = link.split("/")[link.split("/").length-1]
  
  let hashOrMention = document.querySelector("#txt_query")
  document.getElementById("btn_query").onclick = function(){
    let divArea = document.querySelector('#query');
    divArea.innerHTML = "";
    channel.push("query", {userName: userName, hashOrMention: hashOrMention.value})
};
}

$(document).ready(function() {
  let link = window.location.href
  let length = link.split("/").length
  if(length>1){
    let userName = link.split("/")[link.split("/").length-1];
    let greetuser = document.querySelector("#username");
    greetuser.innerHTML = "Hey " + userName + "!";
    channel.push("updateSocket", {userName: userName});
    channel.push("updateFeed", {userName: userName});
  }
  
});

channel.on("login_success", payload => {
  alert(`${payload.body}`)
  window.location.href = "/user/" + `${payload.userName}`
})

channel.on("follow_status", payload => {
  alert(`${payload.status}`)
})


channel.on("login_failure", payload => {
  alert(`${payload.body}`)
})


channel.on("signup_success", payload => {
  alert(`${payload.body}`)
})


channel.on("signup_failure", payload => {
  alert(`${payload.body}`)
})

channel.on("queryList", payload => {
  let divlist = $('#query');
  // let divArea = document.querySelector('#query');
  // divArea.value = "";
  let queries = payload.queryList
  // console.log(`${payload.queryList}`)
  // alert(`${payload.queryList[0]}`)
  // var queries = `${payload.queryList}`;
  for(var i = 0; i< queries.length; i++){
    console.log(`${payload.queryList[i].desc}`);
    divlist.prepend(`${payload.queryList[i].tweetID} -- ${payload.queryList[i].userName}: ${payload.queryList[i].desc} <br>`);
  }
  divlist.scrollTop;
  //console.log(payload)
  
})

channel.on("updateFeed", payload => {
  let divlist = $('#feed');

  let queries = payload.queryList
  // console.log(`${payload.queryList}`)
  // alert(`${payload.queryList[0]}`)
  // var queries = `${payload.queryList}`;
  for(var i = 0; i< queries.length; i++){
    console.log(`${payload.queryList[i].desc}`);
    divlist.prepend(`${payload.queryList[i].tweetID} -- ${payload.queryList[i].userName}: ${payload.queryList[i].desc} <br>`);
  }
  divlist.scrollTop;
  //console.log(payload)
  
})


channel.on("getTweet", payload => {
  let divlist = $('#feed');
  console.log(payload);
  //let queries = payload.tweet
  // console.log(`${payload.queryList}`)
  // alert(`${payload.queryList[0]}`)
  // var queries = `${payload.queryList}`;

  divlist.prepend(`${payload.tweet.tweetID} -- ${payload.tweet.userName}: ${payload.tweet.desc} <br>`);
  
  divlist.scrollTop;
  //console.log(payload)
})
// chatInput.addEventListener("keypress", event => {
//   if(event.keyCode === 13){
//     channel.push("new_msg", {body: chatInput.value})
//     chatInput.value = ""
//   }
// })

// channel.on("new_msg", payload => {
//   let messageItem = document.createElement("li");
//   messageItem.innerText = `[${Date()}] ${payload.body}`
//   messagesContainer.appendChild(messageItem)
// })

export default socket
