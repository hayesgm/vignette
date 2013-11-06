require "vignette/version"
require "vignette/object_extensions"
require "vignette/filter"
require "vignette/vignette_errors"

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
  
  def self.tests(session=Vignette.session, cookies=Vignette.cookies)
    store = get_store(session, cookies)
    store && store[:v].present? ? JSON(store[:v]) : {}
  end
  
  def self.get_store(session=Vignette.session, cookies=Vignette.cookies)
    case Vignette.store
    when :cookies
      raise VignetteError::ConfigError, "Missing cookies configuration in Vignette.  Must access Vignette in controller within around_filter." if cookies.nil?
      Rails.logger.debug [ 'Vignette::vignette', 'Cookies Sampling', cookies ] if Vignette.logging
      cookies.signed
    when :session
      raise VignetteError::ConfigError, "Missing session configuration in Vignette.  Must access Vignette in controller within around_filter." if session.nil?
      Rails.logger.debug [ 'Vignette::vignette', 'Session Sampling', session ] if Vignette.logging
      session
    else
      Rails.logger.debug [ 'Vignette::vignette', 'Random Sampling' ] if Vignette.logging
      {} # This is an empty storage
    end
  end
  
end
