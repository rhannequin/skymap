# Themes

A theme gives the colors and the font of the map. See the
[Themes section of the README](../README.md#themes) for the built-in themes and
how to change one.

## Required colors

Each color is a string SVG accepts, such as `"#ffeedd"` or `"gold"`, and
`"none"` leaves something out.

The required colors are `background` (the square behind the sky, which the
cardinal directions are written on), `sky`, `horizon`, `star`,
`constellation_line`, `boundary`, `ecliptic`, `planet`, `sun`, `moon`,
`moon_shadow` (with its `moon_shadow_opacity`, between 0 and 1),
`constellation_name`, `star_name`, `planet_name` and `label` (the cardinal
directions). `font` is the font family of every text.

## Optional colors

Some colors are optional. When you leave one out, it takes the color of
another one, and follows it if you change that one:

| Optional color | Falls back to        |
| -------------- | -------------------- |
| `grid`         | `boundary`           |
| `scale`        | `star_name`          |
| `field_circle` | `planet`             |
| `deep_sky`     | `constellation_name` |

`grid` is the color of `Skymap::Layers::Grid`, `scale` the color of the bar and
the label of `Skymap::Layers::Scale`, and `field_circle` the color of the
circles and the labels of `Skymap::Layers::FieldCircles`, and `deep_sky` the
color of the symbols and the labels of `Skymap::Layers::DeepSkyObjects`.

## Building a theme from scratch

`Skymap::Theme.new` takes all the required colors, and the optional ones if you
want them:

```ruby
theme = Skymap::Theme.new(
  background: "#fdf6e3",
  sky: "#fdf6e3",
  horizon: "#586e75",
  star: "#073642",
  constellation_line: "#93a1a1",
  boundary: "#d3cbb7",
  ecliptic: "#b58900",
  planet: "#cb4b16",
  sun: "#b58900",
  moon: "#eee8d5",
  moon_shadow: "#586e75",
  moon_shadow_opacity: 0.4,
  constellation_name: "#268bd2",
  star_name: "#657b83",
  planet_name: "#cb4b16",
  label: "#586e75",
  font: "serif"
)

theme.grid # => "#d3cbb7", the color of the boundaries
```

## What a theme holds

`theme.grid` gives the color that is drawn, but `to_h`, `inspect`, `==` and
pattern matching work on what was set, so an unset optional color is `nil`
there. That way `Skymap::Theme.new(**theme.to_h)` builds a theme that still
follows its fallback. It also means that two themes that draw the same are equal
only if they set the same colors.
