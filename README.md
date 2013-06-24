# Vignette

Vignette makes it dead simple to run reliable A/b tests in your Rails project.

## Examples

Vignette is as simple as sampling from an Array:

    @price = [5, 10, 15].vignette

We've also added a filter to HAML for testing:

    %h1
      :vignette
        Welcome to the Zoo.
        Come to see the Lions!
        Don't get caught by a lemur!

## Installation

Add this line to your application's Gemfile:

    gem 'vignette'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vignette

## Usage

Vignette was crafted to make A/b testing as simple as possible.  Simply run the `vignette` function on any Array and get the result from a A/b test.  Vignette will store this choice in session, a cookies or nowhere, based on how you configure Vignette.  For this to work, all calls to Vignette must be within the request cycle (within an around_filter in ActionController::Base).  Test are identified by a checksum of the Array, and thus, changing the Array will restart that test.
  
    # To store in session (default)
    Vignette.init(:session)

    # To use cookies
    Vignette.init(:cookies)

    # Or random sampling
    Vignette.init(:random)

Running tests:

    [ 1,2,3 ].vignette # Chooses an option and stores test as indicated above
    %w{one two three}.vignette # Same with strings

    # or in HAML

    :vignette
      Test one
      Test <strong>two</strong>
      Test #{three}

Finally, to store in analytics which tests were run, simple check

    Vignette.test -> { 'views/orders/new.html.haml:54d3c10a1b21' => 0 } # First choice was select for new.html.haml test

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
