const COLLAPSED_ROW_COUNT = 1
const OVERLAY_CLASSES = ["absolute", "left-0", "right-0", "top-0", "z-30", "rounded-md", "border", "border-slate-200", "bg-white", "p-2", "shadow-lg"]

function collapsedHeightFor(chipsElement, chipElements) {
  const rowGap = parseFloat(getComputedStyle(chipsElement).rowGap) || 0
  const chipHeight = chipElements[0].offsetHeight

  return chipHeight * COLLAPSED_ROW_COUNT + rowGap * (COLLAPSED_ROW_COUNT - 1)
}

function hiddenChipCountFor(chipsElement, chipElements, collapsedHeight) {
  const containerTop = chipsElement.getBoundingClientRect().top

  return chipElements.filter((chipElement) => {
    return chipElement.getBoundingClientRect().top - containerTop >= collapsedHeight
  }).length
}

export function applyChipOverflow(panelElement, chipsElement, toggleElement, expanded) {
  const chipElements = Array.from(chipsElement.children)

  panelElement.classList.remove(...OVERLAY_CLASSES)
  chipsElement.style.height = ""

  if (chipElements.length === 0) {
    toggleElement.classList.add("hidden")
    return
  }

  const collapsedHeight = collapsedHeightFor(chipsElement, chipElements)
  const hiddenChipCount = hiddenChipCountFor(chipsElement, chipElements, collapsedHeight)
  const overflowing = hiddenChipCount > 0

  if (expanded && overflowing) {
    panelElement.classList.add(...OVERLAY_CLASSES)
  } else if (overflowing) {
    chipsElement.style.height = `${collapsedHeight}px`
  }

  if (overflowing) {
    toggleElement.classList.remove("hidden")
  } else {
    toggleElement.classList.add("hidden")
  }

  toggleElement.textContent = expanded && overflowing ? "⌃ Show less" : `⌄ +${hiddenChipCount} more`
}

export function observeChipOverflow(chipsElement, onWidthChanged) {
  let observedWidth = null

  const observer = new ResizeObserver((entries) => {
    const width = entries[0].contentRect.width
    if (width === observedWidth) return

    observedWidth = width
    onWidthChanged()
  })

  observer.observe(chipsElement)
  return observer
}
