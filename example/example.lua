local docker = require 'code.docker'
local cqueues = require 'cqueues'
local serpent = require 'serpent'

local cq = cqueues.new()

local d = docker.new('localhost', '/var/run/docker.sock', 'v1.38')

local function block_print(x)
  print(serpent.block(x, { comment = false }))
end

cq:wrap(function ()
  d:get_version()
  local containers = d:get_containers({size = 'true'})
  local first_id = containers[1].Id
  block_print(d:list_container_processes(first_id))
end)

assert(cq:loop())
