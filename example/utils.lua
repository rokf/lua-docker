local serpent = require 'serpent'

return {
  block_print = function (x)
    print(serpent.block(x, { comment = false }))
  end,
  print_headers = function (h)
    for key, value in h:each() do
      print(key, value)
    end
  end
}
