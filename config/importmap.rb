# Pin npm packages by running ./bin/importmap

pin "application"

pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.js"
pin "test/hello"
pin "game/chat"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
