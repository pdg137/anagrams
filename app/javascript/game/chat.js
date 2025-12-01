import * as Channels from "channels"

const room = $("#chat").data("room")
const chat_channel = new Channels.ChatChannel(room)
const chatOutput = $("#chat_output")
const statusOutput = $("#status_output")

const COOKIE_MAX_AGE = 60 * 60 * 24 * 365 // 1 year

function normalizeMessage(data) {
    if (typeof data === "object" && data !== null) {
        return {
            chat: data.chat || "",
            status: data.status || "",
            cookie: data.cookie || null
        }
    }
    return { chat: data || "", status: "", cookie: null }
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

function setCookie(name, value) {
    if (!name || value === undefined || value === null) {
        return
    }
    document.cookie = `${name}=${encodeURIComponent(value)}; path=/; max-age=${COOKIE_MAX_AGE}`
}

chat_channel.setListener(function(data) {
    const message = normalizeMessage(data)
    appendToChatBox(message.chat)
    updateStatusBox(message.status)
    if (message.cookie) {
        setCookie(message.cookie.name, message.cookie.value)
    }
})

function say_click() {
    const input = $("#chat_input")
    const message = input.val()
    if(!chat_channel.say(message))
    {
        alert("failed to send message")
        return
    }
    input.val("")
    input.focus()
}

$("#chat_say").click(say_click)
$("#chat_input").keypress(function (e) {
    if (e.which == 13) {
        say_click()
        return false
    }
})

$("#chat_input").focus()
