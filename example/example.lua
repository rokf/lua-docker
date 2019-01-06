local docker = require 'code.docker'
local utils = require 'example.utils'

local d = docker.new('localhost', '/var/run/docker.sock', 'v1.38')

local new_container_name = 'my_new_container'

d:remove_container(new_container_name)

local containers = d:list_containers({ all = 'true' })

local container_ammount = 0

if containers ~= nil then
  container_ammount = #containers
end

print(string.format('The number of available containers is %d', container_ammount))

local creation_response, response_headers = d:create_container({
  name = new_container_name
}, {
  Image = "alpine",
  Cmd = { "echo", "hello" }
})

utils.block_print(creation_response)

print('Received status code ' .. response_headers:get(':status'))

local inspection_info = d:inspect_container(new_container_name, { size = 'true' })

print('The ID of the container is ' .. inspection_info.Id)

local _, start_headers = d:start_container(new_container_name)

if start_headers:get(':status') == '204' then
  print('Successfully started new container!')
end

d:wait_for_container(new_container_name)

local logs = d:get_container_logs(new_container_name, { stdout = 'true' })

utils.block_print(logs)
