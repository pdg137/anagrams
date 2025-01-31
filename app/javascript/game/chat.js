import * as Channels from "channels"

Channels.chat.setListener(function(data) {
    $("#chat_output").append(data+"\r\n")
})

function say_click() {
    if(!Channels.chat.say($("#chat_input").val()))
    {
        alert("failed to send message")
        return
    }
    $("#chat_input").val("")
    $("#chat_input").focus()
}

$("#chat_say").click(say_click)
$("#chat_input").keypress(function (e) {
    if (e.which == 13) {
        say_click()
        return false
    }
})

$("#chat_input").focus()
