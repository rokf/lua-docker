local client = require 'http.client'
local headers = require 'http.headers'
local util = require 'http.util'

local cjson = require 'cjson'
local basexx = require 'basexx'

local handle_response_body = function (body)
  if type(body) == 'string' then
    if string.match(body, '[[{]') then
      return cjson.decode(body)
    end
    return body
  else
    return nil
  end
end

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

  return handle_response_body(response_body), response_headers
end

local loop_through_entity_endpoints = function (endpoint_data, group, target_table)
  for k, v in pairs(endpoint_data) do
    target_table[k] = function (self, name_or_id, query, authority, body)
      return perform_request(
        self, v.method,
        string.format(
          '/%s/%s%s', group, name_or_id,
          v.endpoint and ('/' .. v.endpoint) or ''
        ),
        query,
        authority,
        body
      )
    end
  end
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

      update_container = function (self, name_or_id, body)
        return perform_request(
          self, 'POST',
          string.format('/containers/%s/%s', name_or_id, 'update'),
          nil, nil, body
        )
      end,

      delete_stopped_containers = function (self, query)
        return perform_request(self, 'POST', '/containers/prune', query)
      end,

      -- @todo missing endpoints:
      -- export_container
      -- get_container_stats
      -- attach_to_container
      -- attach_to_container_ws
      -- extract_archive_to_container_dir

      list_images = function (self, query)
        return perform_request(self, 'GET', '/images/json', query)
      end,

      delete_builder_cache = function (self)
        return perform_request(self, 'POST', '/build/prune')
      end,

      create_image = function (self, query, auth, body)
        return perform_request(self, 'POST', '/images/create', query, auth, body)
      end,

      search_image = function (self, query)
        return perform_request(self, 'GET', '/images/search', query)
      end,

      delete_unused_images = function (self, query)
        return perform_request(self, 'POST', '/images/prune', query)
      end,

      create_image_from_container = function (self, query, body)
        return perform_request(self, 'POST', '/commit', query, nil, body)
      end,

      -- @todo missing endpoints:
      -- build_image
      -- export_image
      -- export_images
      -- import_images

      list_networks = function (self, query)
        return perform_request(self, 'GET', '/networks', query)
      end,

      create_network = function (self, body)
        return perform_request(self, 'POST', '/networks/create', nil, nil, body)
      end,

      delete_unused_networks = function (self, query)
        return perform_request(self, 'POST', '/networks/prune', query)
      end,

      list_volumes = function (self, query)
        return perform_request(self, 'GET', '/volumes', query)
      end,

      create_volume = function (self, body)
        return perform_request(self, 'POST', '/volumes/create', nil, nil, body)
      end,

      delete_unused_volumes = function (self, query)
        return perform_request(self, 'POST', '/volumes/prune', query)
      end,
    }

    loop_through_entity_endpoints({
      ['list_container_processes'] = { method = 'GET', endpoint = 'top' },
      ['inspect_container'] = { method = 'GET', endpoint = 'json' },
      ['get_container_logs'] = { method = 'GET', endpoint = 'logs' },
      ['get_container_fs_changes'] = { method = 'GET', endpoint = 'changes' },
      ['resize_container_tty'] = { method = 'POST', endpoint = 'resize' },
      ['start_container'] = { method = 'POST', endpoint = 'start' },
      ['stop_container'] = { method = 'POST', endpoint = 'stop' },
      ['restart_container'] = { method = 'POST', endpoint = 'restart' },
      ['kill_container'] = { method = 'POST', endpoint = 'kill' },
      ['rename_container'] = { method = 'POST', endpoint = 'rename' },
      ['pause_container'] = { method = 'POST', endpoint = 'pause' },
      ['resume_container'] = { method = 'POST', endpoint = 'unpause' },
      ['wait_for_container'] = { method = 'POST', endpoint = 'wait' },
      ['remove_container'] = { method = 'DELETE' },
      ['get_container_resource_info'] = { method = 'HEAD', endpoint = 'archive' },
      ['get_container_resource_archive'] = { method = 'GET', endpoint = 'archive' },
    }, 'containers', d)

    loop_through_entity_endpoints({
      ['inspect_image'] = { method = 'GET', endpoint = 'json' },
      ['get_image_history'] = { method = 'GET', endpoint = 'history' },
      ['push_image'] = { method = 'POST', endpoint = 'push' },
      ['tag_image'] = { method = 'POST', endpoint = 'tag' },
      ['remove_image'] = { method = 'DELETE' },
    }, 'images', d)

    loop_through_entity_endpoints({
      ['inspect_network'] = { method = 'GET' },
      ['remove_network'] = { method = 'DELETE' },
      ['connect_container_to_network'] = { method = 'POST', endpoint = 'connect' },
      ['disconnect_container_from_network'] = { method = 'POST', endpoint = 'disconnect' },
    }, 'networks', d)

    loop_through_entity_endpoints({
      ['inspect_volume'] = { method = 'GET' },
      ['remove_volume'] = { method = 'DELETE' },
    }, 'volumes', d)

    return d
  end
}
