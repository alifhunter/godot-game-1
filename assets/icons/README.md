# STOCKBOT icon set

22 outline SVGs from Tabler Icons, used in the STOCKBOT trade window.

## Usage in Godot 4

Copy this folder into `res://icons/` and let Godot's built-in SVG importer
handle them. Recommended import setting:

    image scale = 2.0

so the icons stay crisp at the small UI sizes (11–18 px).

In code:

    @onready var add_icon := preload("res://icons/plus.svg")

## Where each icon is used

| File                | Used for                                  |
|---------------------|-------------------------------------------|
| minus.svg           | Window minimize, zoom out, decrement      |
| x.svg               | Window close                              |
| calendar-event.svg  | Day badge                                 |
| layout-dashboard.svg| Nav: dashboard                            |
| chart-candle.svg    | Nav: trade · chart-type: candle           |
| briefcase-2.svg     | Nav: portfolio                            |
| help-circle.svg     | Nav: help                                 |
| search.svg          | Stock list search field                   |
| plus.svg            | Add to watchlist, zoom in, increment      |
| check.svg           | Selected-stock indicator                  |
| line.svg            | Chart-type: line                          |
| lock.svg            | Locked indicator chip                     |
| pointer.svg         | Tool: select                              |
| line-dashed.svg     | Tool: horizontal line                     |
| trending-up.svg     | Tool: trend line                          |
| pencil.svg          | Tool: free draw                           |
| trash.svg           | Tool: delete drawing                      |
| eraser.svg          | Tool: clear all                           |
| dots.svg            | More menu                                 |
| chevron-up.svg      | Quantity stepper increment                |
| chevron-down.svg    | Quantity stepper decrement                |
| shopping-cart.svg   | Submit order button                       |

## License

Tabler Icons — MIT License. See `LICENSE.txt`.
