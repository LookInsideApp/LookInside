# LookInside CLI Output Shapes

Use this reference when documenting the CLI, explaining fields, or choosing between text and JSON output.

## `list --format json`

The CLI returns an array of discovered targets.

```json
[
  {
    "appInfoIdentifier": 1774294178,
    "appName": "MiniTerm",
    "bundleIdentifier": "wiki.qaq.MiniTerm",
    "deviceDescription": "iPhone Air",
    "osDescription": "26.3.1",
    "port": 47164,
    "serverReadableVersion": "1.2.8",
    "serverVersion": 0,
    "targetID": "simulator:47164:1774294178",
    "transport": "simulator"
  }
]
```

Field notes:

- `targetID`: runtime-discovered opaque identifier used by `inspect`, `hierarchy`, and `export`
- `transport`: `simulator` or `usb`
- `port`: transport port used to connect to the embedded server
- `appInfoIdentifier`: per-run app identifier exposed by LookinServer

## `inspect --format json`

The CLI wraps target metadata with connection metadata.

```json
{
  "connectionState": "connected",
  "protocolVersion": 7,
  "target": {
    "appInfoIdentifier": 1774294178,
    "appName": "MiniTerm",
    "bundleIdentifier": "wiki.qaq.MiniTerm",
    "deviceDescription": "iPhone Air",
    "osDescription": "26.3.1",
    "port": 47164,
    "serverReadableVersion": "1.2.8",
    "serverVersion": 0,
    "targetID": "simulator:47164:1774294178",
    "transport": "simulator"
  }
}
```

## `hierarchy` tree output

Text mode prints one node per line using indentation to show nesting.

```text
- UIWindow#2 [keyWindow] frame={0, 0, 420, 912}
  - UITransitionView#11 frame={0, 0, 420, 912}
    - _UIMultiLayer#12 frame={0, 0, 420, 912}
      - UIDropShadowView#14 frame={0, 0, 420, 912}
        - UILayoutContainerView#16 frame={0, 0, 420, 912}
```

Rendering rules:

- `ClassName#oid` identifies the node
- `[keyWindow]` appears for the key window
- `hidden` appears for hidden nodes
- `alpha=<value>` appears when alpha is not `1`
- `frame={x, y, width, height}` is always included
- a quoted suffix appears when `customDisplayTitle` is present

## `hierarchy --format json`

JSON mode returns app metadata plus a recursive `displayItems` tree.

```json
{
  "app": {
    "appName": "MiniTerm",
    "bundleIdentifier": "wiki.qaq.MiniTerm",
    "deviceDescription": "iPhone Air",
    "deviceType": "0",
    "osDescription": "26.3.1",
    "osMainVersion": 26,
    "screenWidth": 420,
    "screenHeight": 912,
    "screenScale": 3,
    "serverReadableVersion": "1.2.8",
    "serverVersion": 0,
    "swiftEnabledInLookinServer": -1
  },
  "collapsedClassList": [],
  "colorAlias": {},
  "displayItems": [
    {
      "className": "UIWindow",
      "memoryAddress": "0x1045098b0",
      "oid": 2,
      "frame": { "x": 0, "y": 0, "width": 420, "height": 912 },
      "bounds": { "x": 0, "y": 0, "width": 420, "height": 912 },
      "alpha": 1,
      "isHidden": false,
      "representedAsKeyWindow": true,
      "customDisplayTitle": "",
      "children": []
    }
  ],
  "serverVersion": 7
}
```

Each display item includes:

- identity: `className`, `memoryAddress`, `oid`
- geometry: `frame`, `bounds`
- visibility: `alpha`, `isHidden`
- hierarchy metadata: `representedAsKeyWindow`, `customDisplayTitle`
- recursion: `children`

## `export`

`export --format json` writes the same payload shape as `hierarchy --format json`.

Archive output writes a serialized LookInside/Lookin document and must use one of these extensions:

- `.archive`
- `.lookin`
- `.lookinside`
