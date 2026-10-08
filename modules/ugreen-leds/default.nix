{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ugreen.leds;

  ugreen-led-kmod = config.boot.kernelPackages.callPackage ../../pkgs/ugreen-led-kmod { };

  kernelVersion = config.boot.kernelPackages.kernel.modDirVersion;

  kernelCheck = pkgs.writeShellScript "ugreen-kernel-check" ''
    running="$(${pkgs.coreutils}/bin/uname -r)"
    expected="${kernelVersion}"

    if [ "$running" != "$expected" ]; then
      echo "UGREEN LED services skipped:"
      echo "  running kernel:    $running"
      echo "  generation kernel: $expected"
      echo "  reboot required to activate the new kernel"
      exit 1
    fi

    exit 0
  '';
in
{
  options.ugreen.leds =
    let
      uint8 = lib.mkOptionType {
        name = "uint8";
        description = "An unsigned 8-bit integer (1–255).";
        check = n: lib.isInt n && n >= 1 && n <= 255;
        merge = lib.mergeOneOption;
      };
    in
    {
      enable = lib.mkEnableOption "UGreen LED controller module";

      cli.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to install and make the `ugreen_leds_cli` tool available.";
      };

      service.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to enable the systemd services for automatic disk, network, and
          power LED management. When enabled, the services use the led-ugreen
          kernel module to control the LEDs, and the ugreen_leds_cli cli tool
          can not be used concurrently.
        '';
      };

      disk = {
        serials = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "SN1"
            "SN2"
            "SN3"
            "SN4"
          ];
          description = "List of disk serial numbers, in order, starting from disk 1 - #.";
          example = [
            "S987F2K" # Disk 1
            "29SDVS3" # Disk 2
            "..."
          ];
        };

        brightness = lib.mkOption {
          type = uint8;
          default = 255;
          description = "The brightness of the disk LEDs, measured from 1 (dim) - 255 (full). The default is 255.";
          example = 128;
        };

        colors = {
          health = lib.mkOption {
            type = lib.types.str;
            default = "255 255 255";
            description = "The color of a healthy disk. The default color is white \"255 255 255\" in RGB.";
          };

          unavail = lib.mkOption {
            type = lib.types.str;
            default = "255 0 0";
            description = "The color of an unavailable disk. The default color is red \"255 0 0\" in RGB.";
          };

          standby = lib.mkOption {
            type = lib.types.str;
            default = "0 0 255";
            description = "The color of a disk in standby mode. The default color is blue \"0 0 255\" in RGB.";
          };

          smart = {
            enable =
              lib.mkEnableOption "Whether to enable checking the disk health via smartctl. The default is true."
              // {
                default = true;
              };

            fail = lib.mkOption {
              type = lib.types.str;
              default = "255 0 0";
              description = "The color of a disk with unhealthy smart info. The default color is red \"255 0 0\" in RGB.";
            };
          };

          zpool = {
            enable = lib.mkEnableOption "checking the zpool health. The default is false";

            fail = lib.mkOption {
              type = lib.types.str;
              default = "255 0 0";
              description = "The color of a failed zpool disk. The default color is red \"255 0 0\" in RGB.";
            };
          };
        };
      };

      network = {
        interface = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "The name of the network interface to monitor for controlling the network LED.";
          example = "enp2s0";
        };

        brightness = lib.mkOption {
          type = uint8;
          default = 255;
          description = "The brightness of the network LED, measured from 1 (dim) - 255 (full). The default is 255.";
          example = 128;
        };

        colors = {
          normal = lib.mkOption {
            type = lib.types.str;
            default = "255 165 0";
            description = "The color of the network LED under the normal state (when checking the link speed is disabled). The default color is orange \"255 165 0\" in RGB.";
          };

          link = {
            enable = lib.mkEnableOption "monitoring the link speed. The default is false";

            m100 = lib.mkOption {
              type = lib.types.str;
              default = "0 255 0";
              description = "The color of the network LED when using a link speed of 100. The default color is green \"0 255 0\" in RGB.";
            };

            g1000 = lib.mkOption {
              type = lib.types.str;
              default = "0 0 255";
              description = "The color of the network LED when using a link speed of 1000. The default color is blue \"0 0 255\" in RGB.";
            };

            g2500 = lib.mkOption {
              type = lib.types.str;
              default = "255 255 0";
              description = "The color of the network LED when using a link speed of 2500. The default color is yellow \"255 255 0\" in RGB.";
            };

            g10000 = lib.mkOption {
              type = lib.types.str;
              default = "255 255 255";
              description = "The color of the network LED when using a link speed of 10000. The default color is white \"255 255 255\" in RGB.";
            };
          };

          gateway = {
            enable = lib.mkEnableOption "monitoring the gateway connectivity. The default is false";

            unreachable = lib.mkOption {
              type = lib.types.str;
              default = "255 0 0";
              description = "The color of the network LED when unable to ping the gateway. The default color is red \"255 0 0\" in RGB.";
            };
          };
        };
      };

      power = {
        brightness = lib.mkOption {
          type = uint8;
          default = 255;
          description = "The brightness of the power LED, measured from 1 (dim) - 255 (full). The default is 255.";
          example = 128;
        };

        color = lib.mkOption {
          type = lib.types.str;
          default = "255 255 255";
          description = "The color of the power LED. The default color is white \"255 255 255\" in RGB.";
        };
      };
    };

  config = lib.mkIf (cfg.enable) {
    boot = {
      extraModulePackages = [
        ugreen-led-kmod
      ];
      kernelModules = [
        "led-ugreen"
        "ledtrig-netdev" # Network activity
        "ledtrig-oneshot" # Disk activity
      ];
    };

    hardware.i2c.enable = true;

    environment.etc."ugreen-leds.conf" = import ./ugreen-leds.conf.nix {
      inherit lib pkgs cfg;
    };
    environment.systemPackages =
      with pkgs;
      [
        i2c-tools
        smartmontools
      ]
      ++ lib.optional (cfg.cli.enable) ugreen-leds;

    systemd.services = {
      ugreen-diskiomon = {
        enable = true;
        unitConfig = {
          Description = "UGREEN LEDs daemon for monitoring diskio and blinking corresponding LEDs";
          After = [ "ugreen-probe-leds.service" ];
          Requires = [ "ugreen-probe-leds.service" ];
        };
        serviceConfig = {
          ExecCondition = kernelCheck;
          ExecStart = "${lib.getExe' pkgs.ugreen-leds "ugreen-diskiomon"}";
          StandardOutput = "journal";
        };
        wantedBy = [ "multi-user.target" ];
      };

      ugreen-netdevmon-multi = {
        enable = true;
        unitConfig = {
          Description = "UGREEN LEDs daemon for monitoring multiple network interfaces";
          After = [
            "ugreen-probe-leds.service"
            "network-online.target"
          ];
          Requires = [ "ugreen-probe-leds.service" ];
          Wants = [ "network-online.target" ];
        };
        serviceConfig = {
          ExecCondition = kernelCheck;
          ExecStart = "${lib.getExe' pkgs.ugreen-leds "ugreen-netdevmon-multi"}";
          Restart = "on-failure";
          RestartSec = "10s";
          StandardOutput = "journal";
        };
        wantedBy = [ "multi-user.target" ];
      };

      "ugreen-netdevmon@${cfg.network.interface}" = {
        enable = true;
        unitConfig = {
          Description = "UGREEN LEDs daemon for monitoring netio (of %i) and blinking corresponding LEDs";
          After = [ "ugreen-probe-leds.service" ];
          Requires = [ "ugreen-probe-leds.service" ];
        };
        serviceConfig = {
          ExecCondition = kernelCheck;
          ExecStart = "${lib.getExe' pkgs.ugreen-leds "ugreen-netdevmon"} %i";
          StandardOutput = "journal";
        };
        wantedBy = [ "multi-user.target" ];
      };

      ugreen-power-led = {
        enable = true;
        unitConfig = {
          Description = "UGREEN LEDs daemon for configuring power LED";
          After = [ "ugreen-probe-leds.service" ];
          Requires = [ "ugreen-probe-leds.service" ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecCondition = kernelCheck;
          ExecStart = "${lib.getExe' pkgs.ugreen-leds "ugreen-power-led"}";
          RemainAfterExit = true;
          StandardOutput = "journal";
        };
        wantedBy = [ "multi-user.target" ];
      };

      ugreen-probe-leds = {
        enable = true;
        unitConfig = {
          Description = "UGREEN LED initial hardware probing service";
          After = [ "systemd-modules-load.service" ];
          Requires = [ "systemd-modules-load.service" ];
        };
        serviceConfig = {
          Type = "oneshot";

          ExecCondition = kernelCheck;
          ExecStartPre = ''
            ${pkgs.kmod}/bin/modprobe \
              --dirname ${config.system.modulesTree} \
              --set-version ${kernelVersion} \
              led-ugreen
          '';
          ExecStart = "${lib.getExe' pkgs.ugreen-leds "ugreen-probe-leds"}";
          RemainAfterExit = true;
          StandardOutput = "journal";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };

    assertions = [
      {
        assertion = !(cfg.cli.enable && cfg.service.enable);
        message = ''
          The UGREEN LED systemd services and ugreen_leds_cli cannot be used at
          the same time because the CLI conflicts with the led-ugreen kernel
          module used by the services. Either set
          `config.ugreen.leds.cli.enable` or
          `config.ugreen.leds.service.enable`.

          See: https://github.com/miskcoo/ugreen_leds_controller/blob/f0fcd8192abdd92244aba9f6f0d10572f5561380/README.md?plain=1#L97-L99
        '';
      }
    ];
  };
}
