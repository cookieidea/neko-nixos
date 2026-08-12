{ pkgs }:

# pywalfox — native messaging host for the Pywalfox Firefox / Thunderbird extension.
# Upstream repo (https://github.com/Frewacom/pywalfox) is the *extension* source
# (TypeScript). The installable native host is published to PyPI as `pywalfox`,
# which is what we package here.
# Arch AUR: python-pywalfox
#
# After installing, run `pywalfox install` once to drop the native-messaging
# manifest into ~/.mozilla/native-messaging-hosts/. The Pywalfox add-on then
# picks up your pywal / wallust colors.
pkgs.python3Packages.buildPythonApplication {
  pname = "pywalfox";
  version = "2.9.0";
  format = "setuptools";   # 26.05 起必须显式声明 format（不再自动检测）；该 sdist 是经典 setup.py

  src = pkgs.fetchPypi {
    pname = "pywalfox";
    version = "2.9.0";
    sha256 = "sha256-ig3uT3rfp4YJMUkF8kXl2hu01/DRyuej2lbE4oTdNQE=";
  };

  # The native host has no Python runtime deps; at runtime it reads the
  # pywal/wallust color JSON written by your theming scripts.
  propagatedBuildInputs = [ ];
  doCheck = false;

  meta = {
    description = "Native app used alongside the Pywalfox browser extension";
    homepage    = "https://github.com/Frewacom/pywalfox";
    license     = "MIT";
    mainProgram = "pywalfox";
    platforms   = pkgs.lib.platforms.linux;
  };
}
