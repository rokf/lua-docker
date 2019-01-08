local docker = require 'code.docker'
local utils = require 'example.utils'

local d = docker.new('localhost', '/var/run/docker.sock', 'v1.38')

local new_container_name = 'my_new_container'

assert(d:remove_container(new_container_name))

local containers = assert(d:list_containers({ all = 'true' }))

local container_ammount = 0
if containers.body ~= nil then
  container_ammount = #containers.body
end

print(string.format('The number of available containers is %d', container_ammount))

local creation_response = assert(d:create_container({
  name = new_container_name
}, {
  Image = "alpine",
  Cmd = { "echo", "hello" }
}))

utils.block_print(creation_response.body)

print('Received status code ' .. creation_response.status)

local inspection_results = assert(d:inspect_container(new_container_name, { size = 'true' }))

print('The ID of the container is ' .. inspection_results.body.Id)

local start_response = assert(d:start_container(new_container_name))

if start_response.status == 204 then
  print('Successfully started new container!')
end

assert(d:wait_for_container(new_container_name))

local logs_response = assert(d:get_container_logs(new_container_name, { stdout = 'true' }))

utils.block_print(logs_response.body)
