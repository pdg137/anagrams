// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "jquery"
import {Hello} from "test/hello"
import "channels"

// make accessible in console
window.Hello = Hello
