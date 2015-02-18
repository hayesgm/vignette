# Vignette

Vignette makes it dead simple to run reliable A/b tests in your Rails project.

## Examples

Vignette is as simple as sampling from an Array:

    @price = [5, 10, 15].vignette

We've also added a filter to HAML for running quick A/b tests:

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

Vignette was crafted to make A/b testing as simple as possible.  Simply run the `vignette` function on any Array and get the result from a A/b test.  Vignette will store this choice in session, a cookies or nowhere, based on how you configure Vignette.  If you're in the request cycle (within an around_filter), Vignette will grab `session` or `cookies` for you.  Otherwise, you'll need to specify where to store the result (if you want it consistent for the end-user).  Vignette `tests` are identified by a checksum of the Array, and thus, changing the Array results in a new `test`.
  
    # To store in session (default)
    Vignette.init(store: :session)

    # To use cookies
    Vignette.init(store: :cookies)

    # Or random sampling [no persistence]
    Vignette.init(store: :random)

    # Other options
    Vignette.init(logging: true) # add debug logging

### Running a Vignette test in your application:

    [ 1,2,3 ].vignette # Chooses an option and stores test as indicated above
    %w{one two three}.vignette # Same with strings

    # or in HAML

    :vignette
      Test one
      Test <strong>two</strong>
      Test #{three}

The choices for these tests are exposed through the `Vignette.test` method:

    Vignette.test -> { '(app/views/users/new.html.haml:35)' => 'Test one' } # First choice was select for new.html.haml test line 35

You may store these values as properties in your analytics system.

## Naming Tests

Vignette tests can also be specifically named, e.g:

    @cat_name = ["Chairman Meow", "Katy Purry"].vignette(:cat_names)


or from HAML:

    %div
      :vignette_dog_names
        Wooferson
        T-Bone

This will lead to `Vignette.tests` to include: `{ "cat_names" => "Chairman Meow" }` and `{ "dog_names" => "Wooferson" }`, respectively.  Note, due to limitations in HAML, you must use a filter that starts with `vignette_` and uses only letters, numbers and underscores (`\w+`).

Without a name, Vignettes will try to name themselves based on the name of the falling calling them, e.g. `(app/models/user.rb:25)` or `(app/views/users/new.html.haml:22)`

## Caveats

Tests are stored in your store object based on the original input.  If you change the input of the test (regardless of the name), a new test will be created.  Thus [1,2,3].vignette(:numbers) and [2,3,4].vignette(:numbers) will always be considered unique tests.  New tests will overwrite old tests with the same name in `Vignette.tests`.  This is by design so that you can update the test, have new results, but keep the same test name in your analytics system.

Note, you must use arrays that will not change between runs.  Thus, `[Date.today, 1.days.ago].vignette` will end up creating separate tests every time this code is run.  We use a `Zlib.crc32` check to check for uniqueness of an array.  Instead, this should be `[0,1].vignette.days.ago`.

If you choose to store your `tests` in `cookies`, then the chosen result will be stored in a cookie sent to the user's browser.  Thus, be careful not to store any secret information in a test.

For unnamed tests, the system will try to determine the name from the line in the file (e.g. `(app/models/user.rb:50)`).  When it does this, it will keep the name the same so long as the underlying array has the same crc32 code.  That is, even if that vignette moves off of line 50, the test will keep the same "name" until the choices of the test change.  This is a trade-off to allow un-named vignettes to be easily understood in an analytics system without having to name each one unless you would like to.

When using `session` or `cookie` store, this code is not thread-safe.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Ensure test cases are passing (`bundle exec rspec`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
