import * as Channels from "channels"

const room = $("#chat").data("room")
const chat_channel = new Channels.ChatChannel(room)
const chatOutput = $("#chat_output")
const statusOutput = $("#status_output")
const visibleLetters = $("#visible_letters")
const formedWords = $(".formed-words")

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
    if (typeof text !== "string" || text.length === 0) {
        return
    }

    statusOutput.val(text)
    statusOutput.scrollTop(statusOutput[0].scrollHeight)
    renderVisibleLetters(text)
    renderFormedWords(text)
}

function renderVisibleLetters(statusText) {
    if (!visibleLetters.length) {
        return
    }

    const firstLine = statusText.split("\n")[0] || ""
    const match = firstLine.match(/^Visible letters:\s*(.*)$/i)
    visibleLetters.empty()

    if (!match || match[1] === "" || match[1] === "(none)") {
        visibleLetters.text("None")
        return
    }

    match[1].trim().split(/\s+/).forEach((letter) => {
        if (letter) {
            visibleLetters.append($("<span/>", {
                class: "letter",
                text: letter
            }))
        }
    })

    if (visibleLetters.children().length === 0) {
        visibleLetters.text("None")
    }
}

function renderFormedWords(statusText) {
    formedWords.empty()

    statusText.split("\n").slice(2).filter(line => line.includes(": ")).forEach(line => {
        const [player, words] = line.split(": ")
        formedWords.append($("<h3/>").text(player))

        words.split(" ").forEach(word => {
            const formedWord = $("<span/>", { class: "formed-word" })
            word.split("").forEach(letter => {
                formedWord.append($("<span/>", { class: "letter", text: letter }))
            })
            formedWords.append(formedWord, " ")
        })
    })
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

function send_message(message) {
    if (!chat_channel.say(message)) {
        alert("failed to send message")
        return false
    }
    return true
}

function send_input(command) {
    const input = $("#chat_input")
    const message = command ? `${command} ${input.val()}` : input.val()
    if (!send_message(message)) return
    input.val("")
    input.focus()
}

$("#chat_say").click(() => send_input())
$("#chat_dict").click(() => send_input("/dict"))
$("#chat_flip").click(() => send_message("/flip"))
$("#chat_nick").click(() => send_input("/nick"))
$("#chat_help").click(() => send_message("/help"))
$("#status_toggle").click(function () {
    statusOutput.prop("hidden", !statusOutput.prop("hidden"))
    const expanded = !statusOutput.prop("hidden")
    $(this).text(expanded ? "▼" : "▶")
        .attr("aria-expanded", expanded)
        .attr("aria-label", expanded ? "Hide game status" : "Show game status")
})
$("#chat_input").keypress(function (e) {
    if (e.which == 13) {
        send_input()
        return false
    }
})

$("#chat_input").focus()
