import * as Channels from "channels"

const room = $("#chat").data("room")
const chat_channel = new Channels.ChatChannel(room)
const chatOutput = $("#chat_output")
const chatInput = $("#chat_input")
const hiddenLettersOutput = $("#hidden_letters_output")
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

function updateGameDisplay(text) {
    if (typeof text !== "string" || text.length === 0) {
        return
    }

    hiddenLettersOutput.val(text.split("\n")[1].replace("Hidden letters: ", ""))
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
            visibleLetters.append($("<i/>", {
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
                formedWord.append($("<i/>", { class: "letter", text: letter }))
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
    updateGameDisplay(message.status)
    if (message.cookie) {
        setCookie(message.cookie.name, message.cookie.value)
    }
})

function send_message(message) {
    const sent = chat_channel.say(message)
    if (!sent) alert("failed to send message")
    chatInput.focus()
    return sent
}

function send_input(command) {
    const message = command ? `${command} ${chatInput.val()}` : chatInput.val()
    if (!send_message(message)) return
    chatInput.val("")
}

$("#chat_say").click(() => send_input())
$("#chat_dict").click(() => send_input("/dict"))
$("#chat_flip").click(() => send_message("/flip"))
$("#chat_nick").click(() => send_input("/nick"))
$("#chat_help").click(() => send_message("/help"))
$("#hidden_letters_toggle").click(function () {
    hiddenLettersOutput.prop("hidden", !hiddenLettersOutput.prop("hidden"))
    const expanded = !hiddenLettersOutput.prop("hidden")
    $(this).text(expanded ? "▼" : "▶")
        .attr("aria-expanded", expanded)
        .attr("aria-label", expanded ? "Hide hidden letters" : "Show hidden letters")
    chatInput.focus()
})
chatInput.keypress(function (e) {
    if (e.which == 13) {
        send_input()
        return false
    }
})

chatInput.focus()
