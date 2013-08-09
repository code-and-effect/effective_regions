require "effective_regions/engine"
require "effective_regions/version"

module EffectiveRegions
  def self.setup
    yield self
  end

end
