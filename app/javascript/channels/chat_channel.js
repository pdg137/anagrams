import consumer from "channels/consumer"

export const chat = consumer.subscriptions.create(
    {channel: "ChatChannel", room: "Test" },
    {
        connected() {
            // Called when the subscription is ready for use on the server
        },

        disconnected() {
            // Called when the subscription has been terminated by the server
        },

        received(message) {
            if(this.listener) {
                this.listener(message)
            }
        },

        say: function(message) {
            return this.perform('say', {message: message})
        },

        setListener: function(callback) {
            this.listener = callback
        },
    }
);
