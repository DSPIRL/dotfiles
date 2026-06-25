hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0.0,
    accel_profile = "flat",

    touchpad = {
      natural_scroll = true,
    },
  },
})

hl.device({
  name = "tpps/2-elan-trackpoint",
  sensitivity = 0.0,
  accel_profile = "flat",
})

hl.device({
  name = "syna801a:00-06cb:cec6-touchpad",
  sensitivity = -0.0,
  accel_profile = "adaptive",
})
