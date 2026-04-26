// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"
import "config"
import "channels"
import { CableCar } from "mrujs/plugins"
import mrujs from "mrujs"
import consumer from "channels/consumer"

mrujs.start({
  plugins: [
    new CableCar(CableReady)
  ]
})

// Make ActionCable consumer available globally for inline scripts
window.App = {
  cable: consumer
}
