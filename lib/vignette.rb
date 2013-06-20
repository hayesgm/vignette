require "vignette/version"
require "vignette/object_extensions"
require "vignette/filter"

module Vignette
  # Your code goes here...
  mattr_accessor :logging
  mattr_accessor :store
  mattr_accessor :request, :session, :cookies

  # Initialization Code

  # Defaults
  Vignette.store = :session
  Vignette.logging = false
  
  # We're going to include ArrayExtensions
  ActionController::Base.send(:include, ObjectExtensions::ActionControllerExtensions)
  Array.send(:include, ObjectExtensions::ArrayExtensions)

  # Member Functions
  
  def self.init(opts={})
    opts = {
      store: nil,
      logging: nil
    }.with_indifferent_access.merge(opts)

    Vignette.store = opts[:store]
  end
  
  # Settings for configuations
  def self.request_config(request, session, cookies)
    Vignette.request = request
    Vignette.session = session
    Vignette.cookies = cookies
  end

  def self.clear_request
    Vignette.request = Vignette.session = Vignette.cookies = nil # clear items
  end

  def self.tests
    Vignette.request[:vignette] ||= {}
    Vignette.request[:vignette][:tests] ||= {}
    Vignette.request[:vignette][:tests]
  end
  
end
