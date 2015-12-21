require_relative  'tor'
require 'sequel'

p "started #{DateTime.now.new_offset(3.0/24)}"

t=Tor.new
ip = t.get_current_ip_address #t.get_new_ip
p "current tor ip #{ip}"
