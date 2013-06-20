module VignetteError
  class VignetteStandardError < StandardError; end
  class ConfigError < VignetteStandardError; end
end