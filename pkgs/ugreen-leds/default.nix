{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  smartmontools,
  pkgs,
  kmod,
  i2c-tools,
  which,
  dmidecode,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ugreen-leds";
  version = "0.3-unstable-2026-09-27";

  src = fetchFromGitHub {
    owner = "my7h3le";
    repo = "ugreen_leds_controller";
    rev = "36540c206f52f7f4cda21504f6391f22ddd903b6";
    hash = "sha256-EvWTNxln8j8P67xHTF2TaDNnYtzFB6wz69ROgffiOx8=";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    smartmontools
    kmod
    i2c-tools
    pkgs.gawk
    which
    dmidecode
  ];

  postPatch = ''
    substituteInPlace cli/Makefile \
      --replace-fail "-static" "-shared-libgcc"
    substituteInPlace scripts/ugreen-diskiomon \
      --replace-fail "/usr/sbin/smartctl" "${lib.getExe' smartmontools "smartctl"}"
  '';

  buildPhase = ''
    runHook preBuild

    make -C cli
    g++ -std=c++17 -O2 scripts/blink-disk.cpp -o scripts/ugreen-blink-disk
    g++ -std=c++17 -O2 scripts/check-standby.cpp -o scripts/ugreen-check-standby

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    chmod +x scripts/ugreen-power-led
    cp cli/ugreen_leds_cli $out/bin/ugreen_leds_cli
    cp -r scripts/ugreen-* $out/bin

    # Purge the following script files from bin directory
    rm $out/bin/ugreen-leds.conf
    # rm $out/bin/ugreen-probe-leds
    # rm $out/bin/ugreen-diskiomon

    # Wrap the script to ensure lsmod, modprobe, etc are available
    wrapProgram $out/bin/ugreen-diskiomon \
      --prefix PATH : ${
        lib.makeBinPath [
          kmod
          pkgs.gawk
          pkgs.flock
          which
          dmidecode
        ]
      }

    # Wrap the script to ensure lsmod, modprobe, and i2cdetect are available
    wrapProgram $out/bin/ugreen-probe-leds \
      --prefix PATH : ${
        lib.makeBinPath [
          kmod
          i2c-tools
        ]
      }

    # runHook postInstall
  '';

  meta = {
    description = "Binary for UGREEN's DX/DXP NAS Series LED controller";
    homepage = "https://github.com/miskcoo/ugreen_leds_controller";
    license = lib.licenses.mit;
    mainProgram = "ugreen_leds_cli";
    maintainers = with lib.maintainers; [ j-pap ];
    platforms = lib.platforms.linux;
  };
})
