// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "jquery"
import {Hello} from "test/hello"
import * as Channels from "channels"

// make accessible in console
window.Hello = Hello
window.Channels = Channels

document.addEventListener('submit', (event) => {
    const form = event.target
    if (!(form instanceof HTMLFormElement)) {
        return
    }

    const submitter = event.submitter
    const confirmationMessage =
        form.dataset.turboConfirm ||
        (submitter instanceof HTMLElement ? submitter.dataset.turboConfirm : undefined)
    if (confirmationMessage && !window.confirm(confirmationMessage)) {
        event.preventDefault()
        event.stopImmediatePropagation()
    }
}, true)
