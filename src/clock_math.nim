## Pure clock calculations shared by the JS app and native Nim tests.

import std/math

const
  Tau* = PI * 2.0
  ParticleCount* = 60

type
  ClockTime* = object
    hours*, minutes*, seconds*: int
    smoothSeconds*, smoothMinutes*, smoothHours*: float

  Geometry* = object
    x*, y*, radius*: float

  Particle* = object
    x*, y*, vx*, vy*: float
    hue*, age*, life*: float

proc initClockTime*(hours, minutes, seconds, milliseconds: int): ClockTime =
  result.hours = hours
  result.minutes = minutes
  result.seconds = seconds
  result.smoothSeconds = seconds.float + milliseconds.float / 1000.0
  result.smoothMinutes = minutes.float + result.smoothSeconds / 60.0
  result.smoothHours = (hours mod 12).float + result.smoothMinutes / 60.0

proc twoDigits(value: int): string =
  if value < 10: "0" & $value
  else: $value

proc formatTime*(hours, minutes: int): string =
  twoDigits(hours) & ":" & twoDigits(minutes)

proc formatDate*(year, month, day, weekday: int): string =
  const weekdays = [
    "日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"
  ]
  let weekdayText = if weekday in 0..6: weekdays[weekday] else: ""
  $year & "年" & $month & "月" & $day & "日" & weekdayText

proc timeHue*(hours, minutes: int): float =
  (hours * 60 + minutes).float / 1440.0 * 360.0

proc shouldExplode*(lastMinute, currentMinute: int): bool =
  lastMinute >= 0 and lastMinute != currentMinute

proc clockGeometry*(width, height: float): Geometry =
  Geometry(
    x: width / 2.0,
    y: height / 2.0,
    radius: min(min(width * 0.42, height * 0.34), 214.0)
  )

proc advanceParticle*(particle: var Particle, elapsedMs: float) =
  let elapsedSeconds = elapsedMs / 1000.0
  particle.x += particle.vx * elapsedSeconds
  particle.y += particle.vy * elapsedSeconds
  particle.age += elapsedMs
