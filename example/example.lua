local docker = require 'code.docker'
local utils = require 'example.utils'

local d = docker.new('localhost', '/var/run/docker.sock', 'v1.38')

local creation_response, response_headers = d:create_container(nil, {
  Image = "alpine",
  Cmd = { "date" }
})

utils.block_print(creation_response)
utils.print_headers(response_headers)
