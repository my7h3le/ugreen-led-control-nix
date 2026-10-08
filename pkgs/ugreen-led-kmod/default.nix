{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ugreen-led-kmod";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "miskcoo";
    repo = "ugreen_leds_controller";
    rev = "0c4b19d397306bd96f69dd838c463db5781f95ea";
    hash = "sha256-33ZQ8wMEiOHIo0/88wIWq9my6N0bDK8GczJlajzWTlM=";
  };
  sourceRoot = "${finalAttrs.src.name}/kmod";

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  installPhase = ''
    runHook preInstall

    install -D led-ugreen.ko -t $out/lib/modules/${kernel.modDirVersion}/extra

    runHook postInstall
  '';

  meta = {
    description = "Kernel module for UGREEN's DX/DXP NAS Series LED controller";
    homepage = "https://github.com/miskcoo/ugreen_leds_controller";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ j-pap ];
    platforms = lib.platforms.linux;
  };
})
