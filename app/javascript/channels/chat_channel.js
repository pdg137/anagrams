import consumer from "channels/consumer"

export class ChatChannel {
    constructor(room) {
        this.channel = consumer.subscriptions.create(
            {channel: "ChatChannel", room: room },
            {
                connected() { },
                disconnected() { },
                received(message) {
                    if(this.listener) {
                        this.listener(message)
                    }
                }
            }
        )
    }

    say(message) {
        return this.channel.perform('say', {message: message})
    }

    setListener(callback) {
        this.channel.listener = callback
    }
}
