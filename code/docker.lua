local client = require 'http.client'
local headers = require 'http.headers'
local util = require 'http.util'

local cjson = require 'cjson'
local basexx = require 'basexx'

local perform_request = function (instance, method, endpoint, query, authority, body)
  local connection = client.connect {
    host = instance.host,
    path = instance.path,
    version = 1.1,
    sendname = true,
    port = 80,
    tls = false
  }

  local stream = connection:new_stream()

  -- prepare headers

  local h = headers.new()

  h:append(':method', method)

  h:append(':authority', '')

  h:append(':path', string.format(
    '/%s%s%s',
    instance.version,
    endpoint,
    query and '?' .. util.dict_to_query(query) or ''
  ))

  h:append('content-type', body and 'application/json' or 'text/plain')
  h:append('user-agent', 'lua-docker')

  if authority then
    local json_authority = cjson.encode(authority)
    local base64_encoded_authority = basexx.to_base64(json_authority)
    h:append('X-Registry-Auth', base64_encoded_authority)
  end

  local encoded_body

  if body then
    encoded_body = cjson.encode(body)
    h:append('content-length', tostring(#encoded_body))
  end

  -- write data to stream

  local end_after_headers = true

  if body then end_after_headers = false end

  stream:write_headers(h, end_after_headers)

  if body then
    stream:write_body_from_string(encoded_body)
  end

  -- read response

  local response_headers = stream:get_headers()

  local response_body = stream:get_body_as_string()

  return response_body and cjson.decode(response_body) or nil, response_headers
end

return {
  new = function (host, path, version)
    local d = {
      host = host or 'localhost',
      path = path or '/var/run/docker.sock',
      version = version or 'v1.38',

      get_version = function (self)
        return perform_request(self, 'GET', '/version')
      end,

      list_containers = function (self, query)
        return perform_request(self, 'GET', '/containers/json', query)
      end,

      create_container = function (self, query, body)
        return perform_request(self, 'POST', '/containers/create', query, nil, body)
      end,

      inspect_container = function (self, id, query)
        return perform_request(self, 'GET', '/containers/' .. id .. '/json', query)
      end,

      list_container_processes = function (self, id, query)
        return perform_request(self, 'GET', '/containers/' .. id .. '/top', query)
      end,

      list_images = function (self, query)
        return perform_request(self, 'GET', '/images/json', query)
      end,

      tag_image = function (self, name_or_id, query)
        return perform_request(self, 'POST', '/images/' .. name_or_id .. '/tag', query)
      end,
    }

    return d
  end
}
