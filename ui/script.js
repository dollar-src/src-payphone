let callActive = false
let callTimer = 0
let timerInterval = null
let contacts = []
let services = []
let callAnswered = false
let lastUpdateTime = 0
let isEndingCall = false
let isPhoneAvailable = true
let callCost = 25
let currentLocale = "en"
let locales = {}

function GetParentResourceName() {
  return "src-payphone"
}

window.addEventListener("message", (event) => {
  const data = event.data

  switch (data.action) {
    case "setLocale":
      currentLocale = data.locale || "en"
      locales = data.locales || {}
      updateAllLocaleTexts()
      break
    case "setCallCost":
      callCost = data.cost
      updateCallCostDisplay()
      break
    case "setServices":
      setServices(data.services)
      break
    case "showCallStatus":
      currentLocale = data.locale || currentLocale
      locales = data.locales || locales
      updateAllLocaleTexts()
      showCallStatus(data)
      break
    case "hideCallStatus":
      hideCallStatus()
      break
    case "showInputDialog":
      currentLocale = data.locale || currentLocale
      locales = data.locales || locales
      callCost = data.callCost || callCost
      updateAllLocaleTexts()
      showInputDialog()
      break
    case "hideInputDialog":
      hideInputDialog()
      break
    case "showNotification":
      showNotification(data.message, data.type)
      break
    case "updateTimer":
      if (callAnswered && data.time > 0) {
        lastUpdateTime = Date.now()
      }
      break
    case "setContacts":
      setContacts(data.contacts)
      break
    case "callEnded":
      handleCallEnded()
      break
  }
})

function _(key, ...args) {
  const locale = locales[currentLocale] || locales["en"] || {}
  let text = locale[key] || key

  if (args.length > 0) {
    args.forEach((arg, index) => {
      text = text.replace(`%s`, arg)
    })
  }

  return text
}

function updateAllLocaleTexts() {
  document.querySelectorAll("[data-locale]").forEach((element) => {
    const key = element.getAttribute("data-locale")

    if (key === "call") {
      element.textContent = _("call", callCost)
    } else if (key === "call_cost_notice") {
      element.textContent = _("call_cost_notice", callCost)
    } else if (key === "next_payment") {
    } else {
      element.textContent = _(key)
    }
  })

  // Update the call button text
  updateCallCostDisplay()
}

function updateCallCostDisplay() {
  const callBtn = document.getElementById("call-btn")
  if (callBtn) {
    const callBtnText = callBtn.querySelector('[data-locale="call"]')
    if (callBtnText) {
      callBtnText.textContent = _("call", callCost)
    }
  }

  const costNotice = document.querySelector(".call-cost-notice span")
  if (costNotice) {
    costNotice.textContent = _("call_cost_notice", callCost)
  }
}

function handleCallEnded() {
  // playSound("call_end.mp3")
  showNotification(_("call_ended"), "info")

  const statusTextEl = document.getElementById("call-status-text")
  const statusBadgeEl = document.getElementById("call-status-badge")

  statusTextEl.textContent = _("ended")
  statusBadgeEl.classList.remove("status-calling", "status-connected", "pulse")
  statusBadgeEl.classList.add("status-ended")

  setTimeout(() => {
    hideCallStatus()
    callActive = false
    callAnswered = false
    sendToGame("endCall")
  }, 1000)
}

function setContacts(contactList) {
  contacts = contactList || []
  populateContactDropdown()
}

function populateContactDropdown() {
  const contactSelect = document.getElementById("contact-select")
  contactSelect.innerHTML = ""

  contacts.sort((a, b) => {
    if (a.favourite !== b.favourite) {
      return b.favourite - a.favourite
    }

    const aName = `${a.firstname} ${a.lastname}`.trim()
    const bName = `${b.firstname} ${a.lastname}`.trim()
    return aName.localeCompare(bName)
  })

  contacts.forEach((contact) => {
    const displayName = `${contact.firstname} ${contact.lastname}`.trim()
    const favoritePrefix = contact.favourite ? "★ " : ""

    const option = document.createElement("option")
    option.value = contact.contact_phone_number
    option.textContent = `${favoritePrefix}${displayName} (${contact.contact_phone_number})`
    contactSelect.appendChild(option)
  })

  const optimalSize = Math.min(5, contacts.length)
  contactSelect.size = optimalSize > 0 ? optimalSize : 5
}

function showCallStatus(data) {
  const callStatusUI = document.getElementById("call-status")
  const phoneNumberEl = document.getElementById("phone-number")
  const statusTextEl = document.getElementById("call-status-text")
  const statusBadgeEl = document.getElementById("call-status-badge")
  const timerEl = document.getElementById("call-timer")
  const paymentEl = document.getElementById("payment-display")
  const nextPaymentEl = document.getElementById("next-payment")

  phoneNumberEl.textContent = data.number || "000-000"

  const wasAnswered = callAnswered
  callAnswered = data.answered

  if (data.answered) {
    if (!wasAnswered && callAnswered) {
      // playSound("call_connected.mp3")
    }

    statusTextEl.textContent = _("connected")
    statusBadgeEl.classList.remove("status-calling", "status-ended", "pulse")
    statusBadgeEl.classList.add("status-connected")
    paymentEl.style.display = "flex"
    nextPaymentEl.textContent = data.timeUntilNextPayment || "30"

    if (!wasAnswered && callAnswered) {
      callTimer = 0
      lastUpdateTime = Date.now()
      updateTimer(0)
      startTimer()
    }
  } else {
    statusTextEl.textContent = _("calling")
    statusBadgeEl.classList.remove("status-connected", "status-ended")
    statusBadgeEl.classList.add("status-calling", "pulse")
    paymentEl.style.display = "none"

    callTimer = 0
    updateTimer(0)
  }

  callStatusUI.style.display = "block"
  callActive = true
  lastUpdateTime = Date.now()
}

function hideCallStatus() {
  const callStatusUI = document.getElementById("call-status")
  callStatusUI.style.display = "none"

  callActive = false
  callAnswered = false

  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

function startTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
  }

  let lastTime = Date.now()

  function updateCallTimer() {
    const now = Date.now()
    const elapsed = now - lastTime

    if (callActive && callAnswered) {
      if (now - lastUpdateTime > 5000) {
        handleCallEnded()
        return
      }

      if (elapsed >= 1000) {
        callTimer += 1
        updateTimer(callTimer)
        lastTime = now
      }

      requestAnimationFrame(updateCallTimer)
    }
  }

  requestAnimationFrame(updateCallTimer)
}

function updateTimer(time) {
  const minutes = Math.floor(time / 60)
  const seconds = time % 60
  const formattedTime = `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`

  document.getElementById("call-timer").textContent = formattedTime
}

function setServices(serviceList) {
  services = serviceList || []
  setTimeout(() => {
    populateQuickDialButtons()
  }, 100)
}

function populateQuickDialButtons() {
  const quickDialContainer = document.querySelector(".quick-dial-buttons")
  if (!quickDialContainer) {
    return
  }

  quickDialContainer.innerHTML = ""

  const quickDialSection = document.querySelector(".quick-dial-section")
  if (quickDialSection) {
    quickDialSection.style.display = services.length > 0 ? "block" : "none"

    if (services.length === 0) {
      return
    }
  }

  services.forEach((service) => {
    const button = document.createElement("button")
    button.className = "quick-dial-btn"
    button.setAttribute("data-company", service.name)

    button.innerHTML = `
      <i class="${service.icon}"></i>
      <span>${service.label} (${service.number})</span>
    `

    button.addEventListener("click", () => {
      // playSound("call_start.mp3")
      sendToGame("callCompany", { company: service.name })
      hideInputDialog()
    })

    quickDialContainer.appendChild(button)
  })
}

function showInputDialog() {
  const inputDialog = document.getElementById("input-dialog")
  const phoneInput = document.getElementById("phone-input")
  const contactSelect = document.getElementById("contact-select")

  sendToGame("getContacts")

  phoneInput.value = ""
  contactSelect.value = ""

  populateQuickDialButtons()
  updateCallCostDisplay()
  updateAllLocaleTexts()

  inputDialog.style.display = "block"
  // playSound("menu_open.mp3")

  setTimeout(() => {
    phoneInput.focus()
  }, 100)

  document.getElementById("call-btn").onclick = () => {
    const number = phoneInput.value.trim()
    if (number) {
      // playSound("call_start.mp3")
      sendToGame("inputSubmit", { number: number })
      hideInputDialog()
    } else {
      showNotification(_("enter_valid_number"), "error")
      phoneInput.focus()
    }
  }

  document.getElementById("cancel-btn").onclick = () => {
    // playSound("menu_close.mp3")
    sendToGame("inputCancel")
    hideInputDialog()
  }

  contactSelect.onchange = () => {
    if (contactSelect.value) {
      phoneInput.value = contactSelect.value
      // playSound("menu_select.mp3")
    }
  }

  phoneInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      document.getElementById("call-btn").click()
    }
  })
}

function hideInputDialog() {
  const inputDialog = document.getElementById("input-dialog")
  inputDialog.style.display = "none"
}

function showNotification(message, type = "info") {
  const notification = document.getElementById("notification")
  const messageEl = document.getElementById("notification-message")

  notification.classList.remove("success", "error", "info")

  if (type === "success") {
    notification.classList.add("success")
  } else if (type === "error") {
    notification.classList.add("error")
  } else {
    notification.classList.add("info")
  }

  messageEl.textContent = message
  notification.classList.add("show")
  // playSound(`notification_${type}.mp3`)

  setTimeout(() => {
    notification.classList.remove("show")
  }, 3000)
}

function playSound(soundFile) {
  sendToGame("playSound", { sound: soundFile })
}

function sendToGame(action, data = {}) {
  const resourceName = GetParentResourceName()
  fetch(`https://${resourceName}/${action}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  })
}

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    if (document.getElementById("input-dialog").style.display === "block") {
      document.getElementById("cancel-btn").click()
    }
    sendToGame("escapePressed")
  } else if (e.key === "Backspace") {
    if (document.getElementById("call-status").style.display === "block") {
      sendToGame("backspacePressed")
    }
  }
})

function requestServices() {
  sendToGame("getServices")
}

document.addEventListener("DOMContentLoaded", () => {
  requestServices()
})

function EndCall() {
  if (!callActive || isEndingCall) return

  isEndingCall = true
  isPhoneAvailable = false

  sendToGame("endCall")
  handleCallEnded()

  setTimeout(() => {
    ResetAllStates()
  }, 1500)
}

function ResetAllStates() {
  callActive = false
  callTimer = 0
  timerInterval = null
  callAnswered = false
  lastUpdateTime = 0
  isEndingCall = false
  isPhoneAvailable = true
}
