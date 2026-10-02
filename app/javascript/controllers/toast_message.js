const TOAST_MARKER = "data-toast-message"

export function announce(message) {
  document.querySelector(`[${TOAST_MARKER}]`)?.remove()

  const toast = document.createElement("div")
  toast.setAttribute(TOAST_MARKER, "")
  toast.dataset.controller = "toast"
  toast.className = "fixed bottom-6 right-6 z-50 flex max-w-sm items-start gap-3 rounded-md bg-slate-900 px-4 py-3 text-sm text-white shadow-lg"

  const text = document.createElement("p")
  text.className = "flex-1"
  text.textContent = message
  toast.appendChild(text)

  document.body.appendChild(toast)
}
