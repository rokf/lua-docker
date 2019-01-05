local client = require 'http.client'
local headers = require 'http.headers'
local util = require 'http.util'

local cjson = require 'cjson'
local basexx = require 'basexx'

local perform_request = function (instance, method, endpoint, query, authority, body)
  local connection = client.connect {
    host = instance.host,
    path = instance.path
  }

  assert(connection:connect())

  local stream = connection:new_stream()

  local h = headers.new()
  h:append(':method', method)
  h:append(':authority', '') -- ?
  h:append(':path', string.format(
    '/%s%s%s',
    instance.version,
    endpoint,
    query and '?' .. util.dict_to_query(query) or ''
  ))
  h:append('Content-Type', body and 'application/json' or 'text/plain')

  if authority then
    local json_authority = cjson.encode(authority)
    local base64_encoded_authority = basexx.to_base64(json_authority)
    h:append('X-Registry-Auth', base64_encoded_authority)
  end

  stream:write_headers(h, body and false or true)

  if body then
    stream:write_body_from_string(cjson.encode(body))
  end

  -- @todo handle errors
  stream:get_headers()

  local response = stream:get_body_as_string()

  return cjson.decode(response)
end

local get_version = function (self)
  return perform_request(self, 'GET', '/version')
end

local get_containers = function (self, query)
  return perform_request(self, 'GET', '/containers/json', query)
end

local create_container = function (self, query, body)
  return perform_request(self, 'POST', '/containers/create', query, nil, body)
end

local inspect_container = function (self, id, query)
  return perform_request(self, 'GET', '/containers/' .. id .. '/json', query)
end

local list_container_processes = function (self, id, query)
  return perform_request(self, 'GET', '/containers/' .. id .. '/top', query)
end

return {
  new = function (host, path, version)
    local d = {
      host = host or 'localhost',
      path = path or '/var/run/docker.sock',
      version = version or 'v1.38',
    }

    d.get_version = get_version
    d.get_containers = get_containers
    d.create_container = create_container
    d.inspect_container = inspect_container
    d.list_container_processes = list_container_processes

    return d
  end
}
