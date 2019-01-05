package = "docker"

version = "scm"

source = {
  url = "git://github.com/rokf/lua-docker"
}

description = {
  summary = "Docker API wrapper",
  detailed = [[
    This module allows you to manage a Docker Engine
    by writing Lua code. You can do pretty much all
    the things you could do with the docker command-line
    tool.
  ]],
  homepage = "https://github.com/rokf/lua-docker",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "cjson",
  "basexx",
  "http"
}

build = {
  type = "builtin",
  modules = {
    docker = "code/docker.lua"
  }
}
