import { Controller } from "@hotwired/stimulus"

const AUTOSAVE_DELAY_MS = 2000
const WARN_BELOW_SECONDS = 5 * 60
const URGENT_BELOW_SECONDS = 60

const formatClock = (seconds) =>
  `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`

export default class extends Controller {
  static targets = ["editor", "output", "clock", "solvedCount", "solvedMark", "submit"]
  static values = {
    deadline: String,
    serverNow: String,
    saveUrl: String,
    submitUrl: String,
    position: Number,
    resultsUrl: String
  }

  connect() {
    this.editor = CodeMirror.fromTextArea(this.editorTarget, {
      mode: "ruby",
      lineNumbers: true,
      indentUnit: 2,
      tabSize: 2,
      lineWrapping: true,
      autofocus: true
    })
    this.editor.getWrapperElement().style.height = "460px"
    this.editor.on("change", () => this.scheduleSave())

    this.clockOffsetMs = Date.parse(this.serverNowValue) - Date.now()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
    clearTimeout(this.saveTimeout)
    this.save({ keepalive: true })
    this.editor.toTextArea()
  }

  tick() {
    const msLeft = Date.parse(this.deadlineValue) - (Date.now() + this.clockOffsetMs)
    const secondsLeft = Math.max(0, Math.ceil(msLeft / 1000))

    this.clockTarget.textContent = formatClock(secondsLeft)
    this.clockTarget.classList.toggle("text-red-600", secondsLeft < WARN_BELOW_SECONDS)
    this.clockTarget.classList.toggle("animate-pulse", secondsLeft < URGENT_BELOW_SECONDS)

    if (secondsLeft === 0) this.goToResults()
  }

  scheduleSave() {
    this.dirty = true
    clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => this.save(), AUTOSAVE_DELAY_MS)
  }

  async save({ keepalive = false } = {}) {
    if (!this.dirty) return
    this.dirty = false

    try {
      const response = await this.request(this.saveUrlValue, "PATCH", { code: this.editor.getValue() }, keepalive)
      if (response.status === 409) this.goToResults()
    } catch (error) {
      this.dirty = true
      console.error("Mock autosave failed:", error)
    }
  }

  async submit() {
    clearTimeout(this.saveTimeout)
    this.dirty = false
    this.submitTarget.disabled = true
    this.outputTarget.textContent = "Running tests..."

    try {
      const response = await this.request(this.submitUrlValue, "POST", {
        position: this.positionValue,
        code: this.editor.getValue()
      })
      const data = await response.json()

      if (response.status === 409) return this.goToResults()
      if (data.error) return this.renderError(data.error)

      this.renderOutput(data.output)
      this.solvedCountTarget.textContent = data.solved_count
      if (data.solved && this.hasSolvedMarkTarget) this.solvedMarkTarget.classList.remove("hidden")
      if (data.finished) this.goToResults()
    } catch (error) {
      this.renderError(error.message)
    } finally {
      this.submitTarget.disabled = false
    }
  }

  goToResults() {
    clearInterval(this.timer)
    window.location.href = this.resultsUrlValue
  }

  request(url, method, body, keepalive = false) {
    return fetch(url, {
      method,
      keepalive,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify(body)
    })
  }

  renderOutput(output) {
    const lines = Object.values(output).map(({ expected, output: actual, passed }) =>
      `Expected: ${expected}\nActual: ${actual}\nPassed: ${passed ? "✅" : "❌"}\n`
    )
    this.outputTarget.textContent = lines.join("\n") || "No output"
  }

  renderError(message) {
    this.outputTarget.textContent = `Error: ${message}`
  }
}
