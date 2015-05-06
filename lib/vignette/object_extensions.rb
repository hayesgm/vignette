module ObjectExtensions

  # Extensions to the Array object
  module ArrayExtensions

    def crc
      Zlib.crc32(self.join)
    end

    # Test will select a random object from the Array
    def vignette(name=nil, expect_consistent_name: true)
      vignette_crc = self.crc().abs.to_s(16)

      vig = Vignette.vig

      test_name = if expect_consistent_name && name.present?
        name
      elsif vig[vignette_crc]
        vig[vignette_crc]['n']
      elsif name.present? # this logic looks weird, but this is if we don't expect consistent names *and* we don't have a name in v[]
        name
      else
        loc = caller_locations(1,1).first
        "(#{Vignette::strip_path(loc.absolute_path)}:#{loc.lineno})"
      end

      result = if Vignette.force_choice && self.include?(Vignette.force_choice)
        Vignette.force_choice
      elsif vig.has_key?(vignette_crc)
        vig[vignette_crc]['v']
      else
        # Store key into storage if not available
        new_value = self[Vignette::rand(length)]

        Vignette.set_vig( vig.merge(vignette_crc => { n: test_name, v: new_value, t: Time.now.to_i }) )

        new_value
      end

      return result
    end

  end

  module ActionControllerExtensions

    def self.included(controller)
      controller.prepend_around_filter(:with_vignettes)
    end

    private

    def with_vignettes
      # set repo based on what type of store we want
      repo = case Vignette.store
      when :session
        session
      when :cookies
        cookies
      when nil, :random
        Hash.new
      end

      force_choice = if Vignette.force_choice_param
        params[Vignette.force_choice_param]
      else
        nil
      end

      Vignette.with_repo(repo, force_choice) do
        yield
      end
    end

  end

end