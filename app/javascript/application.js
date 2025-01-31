// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "jquery"
import {Hello} from "test/hello"

$(function() {
    let h = new Hello()
    h.hello()
})
