# frozen_string_literal: true

require_relative "tucue/version"

module Tucue
  class Error < StandardError; end
end

require_relative "tucue/player"
require_relative "tucue/marker"
require_relative "tucue/ui"
