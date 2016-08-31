require 'spf/logger'
require 'spf/version'

# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true
