{
  lib,
  pkgs,
  cfg,
  ...
}:
{
  enable = true;
  mode = "0644";
  text = ''
    # configuration file for ugreen-diskiomon and ugreen-netdevmon
    # it should be put in /etc/ugreen-leds.conf

    # =========== parameters of disk activities monitoring =========== 

    # The method of mapping disks to LEDs: ata, hctl, serial
    #      ata: default, also used in UGOS
    #           $> ls -ahl /sys/block | grep ata[0-9] --color
    #           * you should check whether it will change after reboot
    #
    #     hctl: mapping by HCTL, 
    #           $> lsblk -S -x hctl -o hctl,serial,name 
    #           it will fail in some devices if you have USB disks inserted, but works well otherwise
    #           * you should check whether it will change after reboot
    #           ** see https://github.com/miskcoo/ugreen_dx4600_leds_controller/issues/14
    #
    #   serial: suggested, mapping by serial
    #           this method requires the user to check the disks' serial numbers
    #           and fill the DISK_SERIAL array below (see the comments therein).
    MAPPING_METHOD=ata

    # The path of the compiled diskio monitor (OPTIONAL) 
    BLINK_MON_PATH=${lib.getExe' pkgs.ugreen-leds "ugreen-blink-disk"}

    # The path of the compiled standby monitor (OPTIONAL) 
    STANDBY_MON_PATH=${lib.getExe' pkgs.ugreen-leds "ugreen-check-standby"}

    # The sleep time between disk standby checks (default: 1 seconds)
    STANDBY_CHECK_INTERVAL=1

    # Invert LED behavior for all LEDs - disk and network (default: 0)
    # 0 = dark when inactive, light on activity (normal behavior)
    # 1 = light when inactive, dark on activity (inverted behavior)
    LED_INVERT=${lib.toString (if cfg.lightWhenInactive then 1 else 0)}

    # The serial numbers of disks (used only when MAPPING_METHOD=serial)
    # You need to record them before inserting to your NAS, and the corresponding disk slots.
    # If you have 4 disks, with serial numbers: SN1 SN2 SN3 SN4, 
    # then the config below leads to the following mapping:
    #    SN1 -- disk1
    #    SN2 -- disk2
    #    SN3 -- disk3
    #    SN4 -- disk4
    DISK_SERIAL="${lib.strings.concatStringsSep " " cfg.disk.serials}"

    # The sleep time between two disk activities checks (default: 0.1 seconds)
    LED_REFRESH_INTERVAL=0.1

    # brightness of disk LEDs, taking value from 1 to 255 (default: 255)
    BRIGHTNESS_DISK_LEDS="${toString cfg.disk.brightness}"

    # color of a healthy disk (default: 255 255 255) - white
    COLOR_DISK_HEALTH="${cfg.disk.colors.health}"

    # color of an unavailable disk (default: 255 0 0) - red
    COLOR_DISK_UNAVAIL="${cfg.disk.colors.unavail}"

    # color of a disk in standby mode (default: 0 0 255) - blue
    COLOR_DISK_STANDBY="${cfg.disk.colors.standby}"

    # color of a failed zpool device (default: 255 0 0) - red
    COLOR_ZPOOL_FAIL="${cfg.disk.colors.zpool.fail}"

    # color of a device with unhealthy smart info (default: 255 0 0) - red
    COLOR_SMART_FAIL="${cfg.disk.colors.smart.fail}"

    # Check the disk health by smartctl (default: true)
    CHECK_SMART=${lib.boolToString cfg.disk.colors.smart.enable}

    # The sleep time between two smart checks (default: 360 seconds)
    CHECK_SMART_INTERVAL=360

    # Check the zpool health (default: false)
    CHECK_ZPOOL=${lib.boolToString cfg.disk.colors.zpool.enable}

    # The sleep time between two zpool checks (default: 5 seconds)
    CHECK_ZPOOL_INTERVAL=5

    # The sleep time between two disk online checks (default: 5 seconds) 
    CHECK_DISK_ONLINE_INTERVAL=5


    # =========== parameters of network activities monitoring ===========

    # Blink the netdev light when sending data (default: 1)
    NETDEV_BLINK_TX=1

    # Blink the netdev light when receiving data (default: 1)
    NETDEV_BLINK_RX=1

    # A cycle of netdev blinking (default: 200 milliseconds)
    NETDEV_BLINK_INTERVAL=200

    # color of the netdev under the normal state (for CHECK_LINK_SPEED=false) (default: 255 165 0) - orange
    COLOR_NETDEV_NORMAL="${cfg.network.colors.normal}"

    # The sleep time between two netdev connectivity / link speed monitoring (default: 60 seconds)
    CHECK_NETDEV_INTERVAL=60

    # Monitor the gateway connectivity (default: false)
    CHECK_GATEWAY_CONNECTIVITY=${lib.boolToString cfg.network.colors.gateway.enable}

    # Monitor the link speed (default: false)
    CHECK_LINK_SPEED=${lib.boolToString cfg.network.colors.link.enable}

    # brightness of the netdev LED, taking value from 1 to 255 (default: 255)
    BRIGHTNESS_NETDEV_LED="${toString cfg.network.brightness}"

    # color of the netdev under different link speeds (for CHECK_LINK_SPEED=true)
    COLOR_NETDEV_LINK_100="${cfg.network.colors.link.m100}"
    COLOR_NETDEV_LINK_1000="${cfg.network.colors.link.g1000}"
    COLOR_NETDEV_LINK_2500="${cfg.network.colors.link.g2500}"
    COLOR_NETDEV_LINK_10000="${cfg.network.colors.link.g10000}"

    # Monitor the link speed and calculate the color for the current link speed (default: false)
    CHECK_LINK_SPEED_DYNAMIC=false

    # The color to use for the lowest specified speed (default: 255 0 0) - red
    CHECK_LINK_SPEED_DYNAMIC_COLOR_LOW="255 0 0"
    # The color to use for the highest specified speed (default: 0 255 0) - green
    CHECK_LINK_SPEED_DYNAMIC_COLOR_HIGH="0 255 0"
    # The speed at which the low color should be shown (default: 0)
    CHECK_LINK_SPEED_DYNAMIC_SPEED_LOW=0
    # The speed at which the high color should be shown (default: 10000)
    CHECK_LINK_SPEED_DYNAMIC_SPEED_HIGH=10000

    # color of the netdev when unable to ping the gateway
    COLOR_NETDEV_GATEWAY_UNREACHABLE="${cfg.network.colors.gateway.unreachable}"

    # =========== parameters for power LED =========== 

    # Blink settings for the power LED
    # * none: no blinking (default)
    # * breath <delay_on> <delay_off>: breathing blink
    # * blink <delay_on> <delay_off>: blinking
    BLINK_TYPE_POWER="none"

    # brighness of the power LED (default: 255)
    BRIGHTNESS_POWER=${toString cfg.power.brightness}

    # color of the power LED (default: 255 255 255) - white
    COLOR_POWER="${cfg.power.color}"
  '';
}
