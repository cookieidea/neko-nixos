# 自定义包（configuration/pkgs 的聚合，供 flake 暴露为 packages.<system>）
{ pkgs, astral-bundle }:

import ../pkgs { inherit pkgs astral-bundle; }
