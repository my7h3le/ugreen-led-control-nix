# UGreen-LED NixOS Module

This flake provides the UGreen LED bin(s) & kernel module that I've packaged
for Nix, as well as a declarative NixOS module.

---

## Setup

### 01. Add flake input

Inside your flake.nix file, add the following to your inputs:

```nix
inputs.ugreen-led.url = "github:j-pap/UGreen-LED-Nix";
```

### 02. Set overlay

Add the input's overlay to your system:

```nix
nixpkgs.overlays = [ inputs.ugreen-led.overlays.default ];
```

### 03. Add i2c to your user's extra groups

```nix
users.users.<name>.extraGroups = [
  "i2c"
];
```

### 04. Enable module & set options

Besides the module enable, disk serials, and the network interface, all the values
below are the defaults. Feel free to set them as you please.

```nix
config.ugreen.leds = {
  enable = true;

  disk = {
    serials = [
      "serial1"
      "serial2"
      ...
    ];
    brightness = 255;
    colors = {
      health = "255 255 255"; # white
      unavail = "255 0 0"; # red
      standy = "0 0 255"; # blue
      smart = {
        enable = true;
        fail = "255 0 0"; # red
      };
      zpool = {
        enable = false;
        fail = "255 0 0" # red
      };
    };
  };

  network = {
    interface = "enp1s0";
    brightness = 255;
    colors = {
      normal = "255 165 0"; # orange
      link = {
        enable = false;
        m100 = "0 255 0"; # green
        g1000 = "0 0 255"; # blue
        g2500 = "255 255 0"; # yellow
        g10000 = "255 255 255"; # white
      };
      gateway = {
        enable = false;
        unreachable = "255 0 0"; # red
      };
    };
  };

  power = {
    brightness = 255;
    color = "255 255 255"; # white
  };
};
```

---

## Credits

[miskcoo](https://github.com/miskcoo) for creating the initial [LED Controller](https://github.com/miskcoo/ugreen_leds_controller).
