# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `traceroute` gem.
# Please instead update this file by running `bin/tapioca gem traceroute`.

# source://traceroute/lib/traceroute.rb#4
class Traceroute
  # @return [Traceroute] a new instance of Traceroute
  #
  # source://traceroute/lib/traceroute.rb#15
  def initialize(app); end

  # source://traceroute/lib/traceroute.rb#81
  def collect_routes(routes); end

  # source://traceroute/lib/traceroute.rb#53
  def defined_action_methods; end

  # source://traceroute/lib/traceroute.rb#35
  def load_everything!; end

  # source://traceroute/lib/traceroute.rb#63
  def routed_actions; end

  # source://traceroute/lib/traceroute.rb#77
  def routes; end

  # source://traceroute/lib/traceroute.rb#49
  def unreachable_action_methods; end

  # source://traceroute/lib/traceroute.rb#45
  def unused_routes; end
end

# source://traceroute/lib/traceroute.rb#9
class Traceroute::Railtie < ::Rails::Railtie; end

# source://traceroute/lib/traceroute.rb#5
Traceroute::VERSION = T.let(T.unsafe(nil), String)

# source://traceroute/lib/traceroute.rb#7
Traceroute::WILDCARD_ROUTES = T.let(T.unsafe(nil), Regexp)
