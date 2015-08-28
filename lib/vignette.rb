require "active_support/core_ext/module/attribute_accessors"
require "action_controller"

require "vignette/version"
require "vignette/object_extensions"
require "vignette/filter"

module Vignette

  module Errors
    class VignetteStandardError < StandardError; end
    class ConfigError < VignetteStandardError; end
    class TemplateRequiresNameError < VignetteStandardError; end
  end

  # Module Attributes, please set via `init()`
  mattr_accessor :logging
  mattr_accessor :store
  mattr_accessor :force_choice_param

  # Initialization Code

  # Defaults
  Vignette.store = :session
  Vignette.logging = false
  Vignette.force_choice_param = nil

  # We're going to include ArrayExtensions
  ActionController::Base.send(:include, ObjectExtensions::ActionControllerExtensions)
  Array.send(:include, ObjectExtensions::ArrayExtensions)

  # Member Functions

  # Set any initializers
  def self.init(opts={})
    opts.each do |k,v|
      Vignette.send("#{k}=", v)
    end
  end

  # Sets the current repo to be used to get and store tests for this thread
  def self.set_repo(repo, force_choice=nil)
    Thread.current[:vignette_repo] = repo
    Thread.current[:vignette_force_choice] = force_choice
  end

  # Clears the current repo on this thread
  def self.clear_repo
    set_repo(nil, nil)
  end

  # Performs block with repo set to `repo` for this thread
  # Force choice will be automatically selected if given
  def self.with_repo(repo, force_choice=nil)
    begin
      Vignette.set_repo(repo, force_choice)

      yield
    ensure
      Vignette.clear_repo
    end
  end

  # Is Vignette active for this thread (i.e. do we have a repo?)
  def self.active?
    !Thread.current[:vignette_repo].nil?
  end

  # Get the repo for this thread
  def self.repo
    raise Errors::ConfigError.new("Repo not active, please call Vignette.set_repo before using Vignette (or use around_filter in Rails)") if !active?

    Thread.current[:vignette_repo]
  end

  # Get the force_choice for this thread
  def self.force_choice
    raise Errors::ConfigError.new("Repo not active, please call Vignette.set_repo before using Vignette (or use around_filter in Rails)") if !active?

    Thread.current[:vignette_force_choice]
  end

  # From the repo (default whatever is set for the thread), grab Vignettes' repo and unpack
  def self.vig(repo=nil)
    repo ||= Vignette.repo # allow using existing

    repo && repo[:v].present? ? JSON(repo[:v]) : {}
  end

  # For this repo, store an update Vig
  def self.set_vig(vig)
    repo[:v] = vig.to_json
  end

  # Pull all the tests for this current repo
  def self.tests(vig=nil)
    vig ||= Vignette.vig

    name_values = vig.values.map { |v| [ v['n'], [ v['t'], v['v'] ] ] }.group_by { |el| el[0] }

    arr = name_values.map { |k,v| [ k.to_s.to_sym, v.sort { |a,b| b[1][0] <=> a[1][0] }.first[1][1] ] }

    Hash[arr]
  end

  private

  def self.strip_path(filename)
    if defined?(Rails) && Rails && Rails.respond_to?(:root)
      filename.gsub(Regexp.new("#{Rails.root}[/]?"), '')
    else
      filename.split('/')[-1]
    end
  end
  
  def self.rand(length)
    Kernel.rand(length)
  end
end
