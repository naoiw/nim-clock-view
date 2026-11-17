## Nim Clock — browser application compiled to JavaScript with `nim js`.
## No handwritten JavaScript clock logic is needed.

import std/[math, jsffi]
import clock_math

const
  Background = "#0b0f18"
  HalfPi = PI / 2.0

# Minimal browser bindings. These procs are emitted as direct JS expressions.
proc elementById(id: cstring): JsObject {.importjs: "document.getElementById(#)".}
proc context2d(canvas: JsObject): JsObject {.importjs: "#.getContext('2d')".}
proc isNull(value: JsObject): bool {.importjs: "(# == null)".}
proc jsDate(): JsObject {.importjs: "new Date()".}
proc jsHours(date: JsObject): int {.importjs: "#.getHours()".}
proc jsMinutes(date: JsObject): int {.importjs: "#.getMinutes()".}
proc jsSeconds(date: JsObject): int {.importjs: "#.getSeconds()".}
proc jsMilliseconds(date: JsObject): int {.importjs: "#.getMilliseconds()".}
proc jsYear(date: JsObject): int {.importjs: "#.getFullYear()".}
proc jsMonth(date: JsObject): int {.importjs: "#.getMonth()".}
proc jsDayOfMonth(date: JsObject): int {.importjs: "#.getDate()".}
proc jsWeekday(date: JsObject): int {.importjs: "#.getDay()".}
proc jsTime(date: JsObject): float {.importjs: "#.getTime()".}
proc viewportWidth(): float {.importjs: "window.innerWidth".}
proc viewportHeight(): float {.importjs: "window.innerHeight".}
proc devicePixelRatio(): float {.importjs: "(window.devicePixelRatio || 1)".}
proc setCssWidth(canvas: JsObject, value: cstring) {.importjs: "#.style.width = #".}
proc setCssHeight(canvas: JsObject, value: cstring) {.importjs: "#.style.height = #".}
proc setCanvasWidth(canvas: JsObject, value: int) {.importjs: "#.width = #".}
proc setCanvasHeight(canvas: JsObject, value: int) {.importjs: "#.height = #".}
proc setFillStyle(ctx: JsObject, color: cstring) {.importjs: "#.fillStyle = #".}
proc setStrokeStyle(ctx: JsObject, color: cstring) {.importjs: "#.strokeStyle = #".}
proc setLineWidth(ctx: JsObject, width: float) {.importjs: "#.lineWidth = #".}
proc setRoundCap(ctx: JsObject) {.importjs: "#.lineCap = 'round'".}
proc beginPath(ctx: JsObject) {.importjs: "#.beginPath()".}
proc arc(ctx: JsObject, x, y, radius, startAngle, endAngle: float) {.importjs: "#.arc(#, #, #, #, #)".}
proc fill(ctx: JsObject) {.importjs: "#.fill()".}
proc stroke(ctx: JsObject) {.importjs: "#.stroke()".}
proc fillRect(ctx: JsObject, x, y, width, height: float) {.importjs: "#.fillRect(#, #, #, #)".}
proc setTransform(ctx: JsObject, scale: float) {.importjs: "#.setTransform(#, 0, 0, #, 0, 0)".}
proc textContent(elem: JsObject): cstring {.importjs: "#.textContent".}
proc setTextContent(elem: JsObject, value: cstring) {.importjs: "#.textContent = #".}
proc randomFloat(): float {.importjs: "Math.random()".}
proc documentHidden(): bool {.importjs: "document.hidden".}
proc motionReduced(): bool {.importjs: "(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) || false".}
proc requestFrame(callback: proc(timestamp: float) {.closure.}): int {.importjs: "window.requestAnimationFrame(#)".}
proc cancelFrame(id: int) {.importjs: "window.cancelAnimationFrame(#)".}
proc addResizeListener(callback: proc() {.closure.}) {.importjs: "window.addEventListener('resize', #)".}
proc addVisibilityListener(callback: proc() {.closure.}) {.importjs: "document.addEventListener('visibilitychange', #)".}

var
  canvas, ctx, digitalLabel, dateLabel: JsObject
  viewportW = 1.0
  viewportH = 1.0
  particles: seq[Particle] = @[]
  lastMinute = -1
  lastFrame = -1.0
  frameId = -1

proc resizeCanvas() =
  viewportW = max(viewportWidth(), 1.0)
  viewportH = max(viewportHeight(), 1.0)
  let pixelRatio = min(max(devicePixelRatio(), 1.0), 2.0)
  setCssWidth(canvas, cstring($viewportW & "px"))
  setCssHeight(canvas, cstring($viewportH & "px"))
  setCanvasWidth(canvas, int(round(viewportW * pixelRatio)))
  setCanvasHeight(canvas, int(round(viewportH * pixelRatio)))
  setTransform(ctx, pixelRatio)
  setFillStyle(ctx, Background)
  fillRect(ctx, 0.0, 0.0, viewportW, viewportH)
  particles.setLen(0)

proc drawRing(x, y, radius, ratio: float, color: cstring, lineWidth: float) =
  if ratio <= 0.0:
    return
  beginPath(ctx)
  arc(ctx, x, y, radius, -HalfPi, Tau * ratio - HalfPi)
  setStrokeStyle(ctx, color)
  setLineWidth(ctx, lineWidth)
  setRoundCap(ctx)
  stroke(ctx)

proc drawFace(time: ClockTime, geometry: Geometry, reduced: bool) =
  if reduced:
    setFillStyle(ctx, Background)
  else:
    setFillStyle(ctx, "rgba(11, 15, 24, 0.28)")
  fillRect(ctx, 0.0, 0.0, viewportW, viewportH)

  let r = geometry.radius
  let hourRadius = r * 0.65
  let minuteRadius = r * 0.83
  let secondRadius = r
  for ringRadius in [hourRadius, minuteRadius, secondRadius]:
    drawRing(geometry.x, geometry.y, ringRadius, 1.0,
      "rgba(235, 240, 255, 0.085)", max(2.0, r * 0.016))

  let hue = timeHue(time.hours, time.minutes)
  drawRing(geometry.x, geometry.y, hourRadius, time.smoothHours / 12.0,
    cstring("hsl(" & $hue & ", 86%, 68%)"), max(5.0, r * 0.040))
  drawRing(geometry.x, geometry.y, minuteRadius, time.smoothMinutes / 60.0,
    "rgba(229, 237, 250, 0.88)", max(4.0, r * 0.027))
  let secondsProgress = if reduced: time.seconds.float / 60.0
                        else: time.smoothSeconds / 60.0
  drawRing(geometry.x, geometry.y, secondRadius, secondsProgress,
    "rgba(158, 188, 220, 0.78)", max(2.0, r * 0.014))

  setFillStyle(ctx, "rgba(219, 232, 250, 0.65)")
  for i in 0 ..< time.seconds:
    let angle = Tau * i.float / 60.0 - HalfPi
    beginPath(ctx)
    arc(ctx,
      geometry.x + cos(angle) * r * 1.11,
      geometry.y + sin(angle) * r * 1.11,
      max(1.0, r * 0.009), 0.0, Tau)
    fill(ctx)

proc spawnParticles(geometry: Geometry, hue: float) =
  for i in 0 ..< ParticleCount:
    let angle = Tau * i.float / ParticleCount.float - HalfPi +
      (randomFloat() - 0.5) * 0.28
    let speed = 55.0 + randomFloat() * 115.0
    particles.add Particle(
      x: geometry.x + cos(angle) * geometry.radius * 1.11,
      y: geometry.y + sin(angle) * geometry.radius * 1.11,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      hue: hue,
      age: 0.0,
      life: 650.0 + randomFloat() * 550.0
    )

proc drawParticle(particle: Particle, radius: float) =
  let opacity = max(0.0, 1.0 - particle.age / particle.life)
  setFillStyle(ctx, cstring("hsla(" & $particle.hue &
    ", 88%, 72%, " & $opacity & ")"))
  beginPath(ctx)
  arc(ctx, particle.x, particle.y, max(1.5, radius * 0.012), 0.0, Tau)
  fill(ctx)

proc animate(timestamp: float) =
  let date = jsDate()
  let time = initClockTime(jsHours(date), jsMinutes(date),
    jsSeconds(date), jsMilliseconds(date))
  let minuteKey = int(floor(jsTime(date) / 60000.0))

  let timeText = formatTime(time.hours, time.minutes)
  let dateText = formatDate(jsYear(date), jsMonth(date) + 1,
    jsDayOfMonth(date), jsWeekday(date))
  if $textContent(digitalLabel) != timeText:
    setTextContent(digitalLabel, cstring(timeText))
  if $textContent(dateLabel) != dateText:
    setTextContent(dateLabel, cstring(dateText))

  let elapsed = if lastFrame >= 0.0:
                  min(50.0, max(0.0, timestamp - lastFrame))
                else:
                  16.0
  lastFrame = timestamp

  let reduced = motionReduced()
  let geometry = clockGeometry(viewportW, viewportH)
  drawFace(time, geometry, reduced)

  if reduced:
    particles.setLen(0)
  else:
    if shouldExplode(lastMinute, minuteKey):
      spawnParticles(geometry, timeHue(time.hours, time.minutes))

    var active: seq[Particle] = @[]
    for particle in particles.mitems:
      advanceParticle(particle, elapsed)
      if particle.age < particle.life:
        drawParticle(particle, geometry.radius)
        active.add particle
    particles = active

  lastMinute = minuteKey
  frameId = requestFrame(animate)

proc onVisibilityChange() =
  if documentHidden():
    if frameId >= 0:
      cancelFrame(frameId)
      frameId = -1
    lastFrame = -1.0
  elif frameId < 0:
    frameId = requestFrame(animate)

proc run() =
  canvas = elementById("clock-canvas")
  if isNull(canvas):
    return
  ctx = context2d(canvas)
  if isNull(ctx):
    return
  digitalLabel = elementById("digital-time")
  dateLabel = elementById("date-text")
  if isNull(digitalLabel) or isNull(dateLabel):
    return

  resizeCanvas()
  addResizeListener(proc() = resizeCanvas())
  addVisibilityListener(proc() = onVisibilityChange())
  frameId = requestFrame(animate)

run()
