local docker = require 'code.docker'
local utils = require 'example.utils'

local d = docker.new('localhost', '/var/run/docker.sock', 'v1.38')

-- argument order:
-- method: string
-- endpoint: string
-- query: table
-- authority: table
-- body: table

local version_response = assert(d:custom('GET', '/version'))

utils.block_print(version_response.body)
