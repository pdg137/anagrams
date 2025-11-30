import * as Channels from "channels"

const room = $("#chat").data("room")
const chat_channel = new Channels.ChatChannel(room)
const chatOutput = $("#chat_output")
const statusOutput = $("#status_output")

function normalizeMessage(data) {
    if (typeof data === "object" && data !== null) {
        return {
            chat: data.chat || "",
            status: data.status || ""
        }
    }
    return { chat: data || "", status: "" }
}

function appendToChatBox(text) {
    if (text) {
        const currentValue = chatOutput.val() || ""
        chatOutput.val(currentValue + text + "\r\n")
        chatOutput.scrollTop(chatOutput[0].scrollHeight)
    }
}

function updateStatusBox(text) {
    if (text) {
        statusOutput.val(text)
        statusOutput.scrollTop(statusOutput[0].scrollHeight)
    }
}

chat_channel.setListener(function(data) {
    const message = normalizeMessage(data)
    appendToChatBox(message.chat)
    updateStatusBox(message.status)
})

function say_click() {
    if(!chat_channel.say($("#chat_input").val()))
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
